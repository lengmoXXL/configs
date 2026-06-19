import { spawn } from "node:child_process";
import { closeSync, existsSync, mkdirSync, openSync, readFileSync, realpathSync, statSync } from "node:fs";
import type { Server } from "node:http";
import { homedir } from "node:os";
import { basename, extname, join, resolve } from "node:path";
import { createHash } from "node:crypto";
import { setTimeout as sleep } from "node:timers/promises";
import express from "express";
import GithubMarkdownCss from "github-markdown-css/github-markdown-dark.css";
import { Marked, type RendererThis, type Tokens } from "marked";
import MarkdownPageCss from "./markdown_page.css";
import {
  detectVaultRoot,
  isMarkdownOxideAvailable,
  resolveDefinitions,
  shutdownAll,
} from "./lsp.js";

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

function encodeFsPath(absPath: string): string {
  return absPath
    .split("/")
    .filter(Boolean)
    .map((part) => encodeURIComponent(part))
    .join("/");
}

function parseWikiInner(inner: string): { target: string; alias: string | null; heading: string | null } {
  const pipeIdx = inner.indexOf("|");
  let main = inner;
  let alias: string | null = null;
  if (pipeIdx >= 0) {
    main = inner.slice(0, pipeIdx);
    alias = inner.slice(pipeIdx + 1).trim();
  }
  const hashIdx = main.indexOf("#");
  let target = main;
  let heading: string | null = null;
  if (hashIdx >= 0) {
    target = main.slice(0, hashIdx);
    heading = main.slice(hashIdx + 1).trim() || null;
  }
  return { target: target.trim(), alias, heading };
}

function gfmSlug(text: string): string {
  return text
    .toLowerCase()
    .replace(/[^\p{L}\p{N}\s-]/gu, "")
    .replace(/\s+/g, "-");
}

function renderHeading(this: RendererThis, { tokens, depth }: Tokens.Heading): string {
  const html = this.parser.parseInline(tokens);
  const id = gfmSlug(html.replace(/<[^>]+>/g, ""));
  return `<h${depth} id="${id}">${html}</h${depth}>\n`;
}

function renderWikiLink(inner: string, resolutions: Map<string, string | null>): string {
  const { target, alias, heading } = parseWikiInner(inner);
  if (target === "") return `[[${inner}]]`;
  const base = target.split("/").pop() ?? target;
  const display = alias ?? base.replace(/\.md$/i, "");
  const resolved = resolutions.get(target);
  if (resolved === undefined) return `[[${inner}]]`;
  if (resolved === null) {
    return `<span class="broken-link" title="unresolved: ${escapeHtml(target)}">${escapeHtml(display)}</span>`;
  }
  const anchor = heading ? `#${gfmSlug(heading)}` : "";
  return `<a href="${FS_PREFIX}${encodeFsPath(resolved)}${anchor}">${escapeHtml(display)}</a>`;
}

function scanWikiTargets(
  source: string,
): { target: string; position: { line: number; character: number } }[] {
  const seen = new Map<string, { line: number; character: number }>();
  const lines = source.split(/\r?\n/);
  const re = /\[\[([^\[\]]+?)\]\]/g;
  let inFence = false;
  let fenceChar = "";
  for (let lineNo = 0; lineNo < lines.length; lineNo += 1) {
    const line = lines[lineNo];
    const fenceMatch = /^\s{0,3}(`{3,}|~{3,})/.exec(line);
    if (fenceMatch) {
      const ch = fenceMatch[1][0];
      if (!inFence) {
        inFence = true;
        fenceChar = ch;
      } else if (ch === fenceChar) {
        inFence = false;
        fenceChar = "";
      }
      continue;
    }
    if (inFence) continue;
    re.lastIndex = 0;
    let match: RegExpExecArray | null;
    while ((match = re.exec(line)) !== null) {
      const { target } = parseWikiInner(match[1]);
      if (target && !seen.has(target)) {
        seen.set(target, { line: lineNo, character: match.index + 2 });
      }
    }
  }
  return [...seen].map(([target, position]) => ({ target, position }));
}

function buildWikiExtension(resolutions: Map<string, string | null>) {
  return {
    name: "wikilink",
    level: "inline" as const,
    start(src: string) {
      const idx = src.indexOf("[[");
      return idx === -1 ? undefined : idx;
    },
    tokenizer(src: string) {
      const match = /^\[\[([^\[\]]+?)\]\]/.exec(src);
      if (!match) return undefined;
      return { type: "wikilink", raw: match[0], inner: match[1], tokens: [] };
    },
    renderer(token: { inner: string }) {
      return renderWikiLink(token.inner, resolutions);
    },
  };
}

function parseMarkdownPlain(source: string): string {
  const instance = new Marked({ gfm: true });
  instance.use({ renderer: { heading: renderHeading } });
  return instance.parse(source, { async: false }) as string;
}

function parseMarkdownWithWiki(source: string, resolutions: Map<string, string | null>): string {
  const instance = new Marked({ gfm: true });
  instance.use({
    extensions: [buildWikiExtension(resolutions)],
    renderer: { heading: renderHeading },
  });
  return instance.parse(source, { async: false }) as string;
}

async function renderMarkdownDocument(
  path: string,
  source: string,
  rawHref: string,
): Promise<string> {
  const frontmatter = source.match(/^---\r?\n(?:[\s\S]*?)\r?\n---(?:\r?\n|$)/);
  const bodySource = frontmatter ? source.slice(frontmatter[0].length).trimStart() : source;

  let warning: string | null = null;
  let bodyHtml: string;

  const available = isMarkdownOxideAvailable();
  const vaultRoot = detectVaultRoot(path);
  if (available && vaultRoot) {
    const targets = scanWikiTargets(source);
    if (targets.length === 0) {
      bodyHtml = parseMarkdownPlain(bodySource);
    } else {
      const outcome = await resolveDefinitions({ root: vaultRoot, docPath: path, text: source, targets });
      if (outcome.status === "ok") {
        bodyHtml = parseMarkdownWithWiki(bodySource, outcome.map);
      } else {
        bodyHtml = parseMarkdownPlain(bodySource);
        warning = "markdown-oxide resolution failed; wiki links shown as plain text";
      }
    }
  } else {
    bodyHtml = parseMarkdownPlain(bodySource);
    if (!available) warning = "markdown-oxide is not installed; wiki links shown as plain text";
  }

  const frontmatterHtml = frontmatter
    ? `<pre><code class="language-yaml">${escapeHtml(frontmatter[0].trimEnd())}</code></pre>\n`
    : "";
  const warningHtml = warning ? `<div class="md-warning">${escapeHtml(warning)}</div>` : "";

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
  ${warningHtml}
  <article class="markdown-body">${frontmatterHtml}${bodyHtml}</article>
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
    setTimeout(() => server.close(() => {
      void shutdownAll().finally(() => process.exit(0));
    }), 10);
  });

  app.use(async (req, res) => {
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
        const html = await renderMarkdownDocument(path, source, rawUrl.pathname + rawUrl.search);
        res.type("text/html; charset=utf-8").send(html);
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

  const encodedPath = encodeFsPath(path);
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
