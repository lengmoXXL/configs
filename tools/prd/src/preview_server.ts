import { spawn } from "node:child_process";
import { closeSync, existsSync, mkdirSync, openSync, readFileSync, realpathSync, statSync } from "node:fs";
import type { Server } from "node:http";
import { homedir } from "node:os";
import { basename, extname, join, resolve } from "node:path";
import { createHash } from "node:crypto";
import { setTimeout as sleep } from "node:timers/promises";
import express, { type Request, type Response } from "express";
import GithubMarkdownCss from "github-markdown-css/github-markdown-dark.css";
import { marked } from "marked";
import MarkdownPageCss from "./markdown_page.css";

const APP_NAME = "prd";
const DEFAULT_HOST = "127.0.0.1";
const DEFAULT_PORT = 7000;
const FS_PREFIX = "/@fs/";

type Health = {
  app: string;
  pid: number;
  script_hash: string;
};

function scriptPath(): string {
  return realpathSync(process.argv[1]);
}

async function requestText(url: string, method: string, timeoutMs: number): Promise<{ status: number; body: string } | null> {
  try {
    const response = await fetch(url, { method, signal: AbortSignal.timeout(timeoutMs) });
    return { status: response.status, body: await response.text() };
  } catch {
    return null;
  }
}

async function readHealth(): Promise<Health | null> {
  const response = await requestText(`http://${DEFAULT_HOST}:${DEFAULT_PORT}/_preview/health`, "GET", 400);
  if (!response || response.status !== 200) return null;

  try {
    const data = JSON.parse(response.body) as Partial<Health>;
    if (data.app === APP_NAME && typeof data.pid === "number" && typeof data.script_hash === "string") {
      return { app: data.app, pid: data.pid, script_hash: data.script_hash };
    }
  } catch {
    return null;
  }
  return null;
}

async function stopServer(): Promise<void> {
  await requestText(`http://${DEFAULT_HOST}:${DEFAULT_PORT}/_preview/stop`, "POST", 800);
  for (let i = 0; i < 30; i += 1) {
    if (!(await readHealth())) return;
    await sleep(100);
  }

  const health = await readHealth();
  if (!health || health.pid <= 0) return;
  try {
    process.kill(health.pid, "SIGTERM");
  } catch {
    return;
  }
}

async function startServer(hash: string): Promise<void> {
  const dir = process.env.XDG_RUNTIME_DIR
    ? join(process.env.XDG_RUNTIME_DIR, APP_NAME)
    : join(homedir(), ".cache", APP_NAME);
  mkdirSync(dir, { mode: 0o700, recursive: true });
  const logPath = join(dir, "server.log");
  const logFd = openSync(logPath, "a");
  const child = spawn(process.execPath, [scriptPath(), "--serve", "--script-hash", hash], {
    cwd: "/",
    detached: true,
    stdio: ["ignore", logFd, logFd],
  });
  closeSync(logFd);
  child.unref();

  for (let i = 0; i < 40; i += 1) {
    const health = await readHealth();
    if (health?.script_hash === hash) return;
    if (child.exitCode !== null) break;
    await sleep(100);
  }

  const lines = existsSync(logPath) ? readFileSync(logPath, "utf-8").split(/\r?\n/).filter(Boolean).slice(-8) : [];
  throw new Error(`failed to start ${APP_NAME} server on ${DEFAULT_HOST}:${DEFAULT_PORT}${lines.length ? `\n${lines.join("\n")}` : ""}`);
}

async function ensureServer(): Promise<void> {
  const hash = createHash("sha256").update(readFileSync(scriptPath())).digest("hex");
  const health = await readHealth();
  if (health?.script_hash === hash) return;

  if (health) {
    console.error(`${APP_NAME}: server script changed, restarting ${DEFAULT_HOST}:${DEFAULT_PORT}`);
    await stopServer();
  }

  if (!(await readHealth())) {
    console.error(`${APP_NAME}: starting server on ${DEFAULT_HOST}:${DEFAULT_PORT}`);
    await startServer(hash);
  }
}

function escapeHtml(value: string): string {
  return value
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

function renderMarkdownDocument(path: string, source: string, rawHref: string): string {
  const frontmatter = source.match(/^---\r?\n(?:[\s\S]*?)\r?\n---(?:\r?\n|$)/);
  const body = frontmatter
    ? `<pre><code class="language-yaml">${escapeHtml(frontmatter[0].trimEnd())}</code></pre>\n${marked.parse(source.slice(frontmatter[0].length).trimStart(), { async: false, gfm: true }) as string}`
    : (marked.parse(source, { async: false, gfm: true }) as string);

  return `<!doctype html>
<html lang="en">
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${escapeHtml(basename(path))}</title>
<style>${GithubMarkdownCss}
${MarkdownPageCss}</style>
<body>
<main class="shell">
  <div class="top">
    <div class="path">${escapeHtml(path)}</div>
    <a class="raw" href="${escapeHtml(rawHref)}">Raw</a>
  </div>
  <article class="markdown-body">${body}</article>
</main>
</body>
</html>`;
}

function startHttpServer(hash: string): void {
  const app = express();
  let server: Server;

  app.get("/_preview/health", (_req, res) => {
    res.json({ app: APP_NAME, pid: process.pid, script_hash: hash });
  });

  app.post("/_preview/stop", (_req, res) => {
    res.type("text/plain; charset=utf-8").send("stopping\n");
    setTimeout(() => server.close(() => process.exit(0)), 10);
  });

  app.use((req, res) => {
    if (req.method !== "GET" && req.method !== "HEAD") {
      res.status(405).type("text/plain; charset=utf-8").send("method not allowed\n");
      return;
    }

    if (!req.path.startsWith(FS_PREFIX)) {
      res.status(404).type("text/plain; charset=utf-8").send("path not found\n");
      return;
    }

    try {
      const url = new URL(req.originalUrl, `http://${req.headers.host ?? "localhost"}`);
      const path = resolve("/", decodeURIComponent(url.pathname.slice(FS_PREFIX.length)));
      const stat = statSync(path);

      if (!stat.isFile()) {
        res.status(404).type("text/plain; charset=utf-8").send("path not found\n");
        return;
      }

      if ([".md", ".markdown"].includes(extname(path).toLowerCase())) {
        const source = readFileSync(path, "utf-8");
        if (url.searchParams.get("raw") === "1") {
          res.type("text/plain; charset=utf-8").send(source);
          return;
        }

        const rawUrl = new URL(url.toString());
        rawUrl.search = "raw=1";
        res.type("text/html; charset=utf-8").send(renderMarkdownDocument(path, source, rawUrl.pathname + rawUrl.search));
        return;
      }

      res.sendFile(path);
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code === "ENOENT") {
        res.status(404).type("text/plain; charset=utf-8").send("path not found\n");
        return;
      }
      console.error(error);
      res.status(500).type("text/plain; charset=utf-8").send("preview render failed\n");
    }
  });

  server = app.listen(DEFAULT_PORT, DEFAULT_HOST, () => {
    console.error(`${APP_NAME}: serving on http://${DEFAULT_HOST}:${DEFAULT_PORT}/`);
  });
}

async function main(argv: string[]): Promise<number> {
  if (argv[0] === "--serve") {
    startHttpServer(argv[2]);
    return 0;
  }

  if (argv.length !== 1) throw new Error("usage: prd <file>");
  await ensureServer();
  const path = resolve(argv[0]);
  if (!existsSync(path)) throw new Error(`path does not exist: ${argv[0]}`);
  if (!statSync(path).isFile()) throw new Error(`path is not a file: ${argv[0]}`);

  const encodedPath = path
    .split("/")
    .filter(Boolean)
    .map((part) => encodeURIComponent(part))
    .join("/");
  console.log(`http://${DEFAULT_HOST}:${DEFAULT_PORT}${FS_PREFIX}${encodedPath}`);
  return 0;
}

main(process.argv.slice(2)).then(
  (code) => {
    process.exitCode = code;
  },
  (error: unknown) => {
    console.error(`${APP_NAME}: error: ${error instanceof Error ? error.message : String(error)}`);
    process.exitCode = 1;
  },
);
