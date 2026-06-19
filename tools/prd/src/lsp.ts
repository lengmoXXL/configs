import { spawn, spawnSync, type ChildProcess } from "node:child_process";
import { existsSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { StreamMessageReader, StreamMessageWriter } from "vscode-jsonrpc/node";
import {
  CancellationTokenSource,
  DidChangeTextDocumentNotification,
  DidOpenTextDocumentNotification,
  DefinitionRequest,
  ExitNotification,
  InitializeRequest,
  InitializedNotification,
  ShutdownRequest,
  createProtocolConnection,
  type Definition,
  type DefinitionLink,
  type Location,
  type ProtocolConnection,
} from "vscode-languageserver-protocol";

const SERVER_BIN = "markdown-oxide";
const ROOT_MARKERS = [".git", ".obsidian", ".moxide.toml"];
const DEFINITION_TIMEOUT_MS = 3000;
const INIT_TIMEOUT_MS = 5000;
const WARMUP_MS = 600;

export type Position = { line: number; character: number };

export type ResolveOutcome =
  | { status: "ok"; map: Map<string, string | null> }
  | { status: "error" };

type ClientEntry = {
  conn: ProtocolConnection;
  proc: ChildProcess;
  opened: Map<string, { version: number; text: string }>;
};

const pool = new Map<string, ClientEntry>();
let availability: boolean | null = null;

const sleep = (ms: number): Promise<void> => new Promise((resolve) => setTimeout(resolve, ms));

function withTimeout<T>(promise: Promise<T>, ms: number): Promise<T> {
  return new Promise<T>((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error("timeout")), ms);
    promise.then(
      (value) => {
        clearTimeout(timer);
        resolve(value);
      },
      (error: unknown) => {
        clearTimeout(timer);
        reject(error);
      },
    );
  });
}

export function isMarkdownOxideAvailable(): boolean {
  if (availability !== null) return availability;
  try {
    const res = spawnSync(SERVER_BIN, ["--version"], { encoding: "utf-8" });
    availability = res.status === 0 && res.stdout.trim().length > 0;
  } catch {
    availability = false;
  }
  return availability;
}

export function detectVaultRoot(filePath: string): string | null {
  let dir = dirname(filePath);
  for (;;) {
    for (const marker of ROOT_MARKERS) {
      if (existsSync(join(dir, marker))) return dir;
    }
    const parent = dirname(dir);
    if (parent === dir) return null;
    dir = parent;
  }
}

async function getClient(root: string): Promise<ClientEntry> {
  const existing = pool.get(root);
  if (existing) return existing;

  const proc = spawn(SERVER_BIN, [], { cwd: root, stdio: ["pipe", "pipe", "inherit"] });
  proc.on("error", () => {
    pool.delete(root);
    availability = false;
  });
  proc.on("exit", () => {
    pool.delete(root);
  });
  const conn = createProtocolConnection(
    new StreamMessageReader(proc.stdout!),
    new StreamMessageWriter(proc.stdin!),
  );
  conn.listen();

  const rootUri = pathToFileURL(root + "/").href;
  await withTimeout(
    conn.sendRequest(InitializeRequest.type, {
      processId: process.pid,
      rootUri,
      capabilities: {},
      workspaceFolders: [{ uri: rootUri, name: "vault" }],
    }),
    INIT_TIMEOUT_MS,
  );
  conn.sendNotification(InitializedNotification.type, {});
  await sleep(WARMUP_MS);

  const entry: ClientEntry = { conn, proc, opened: new Map() };
  pool.set(root, entry);
  return entry;
}

function syncDocument(entry: ClientEntry, uri: string, text: string): boolean {
  const prev = entry.opened.get(uri);
  if (!prev) {
    entry.conn.sendNotification(DidOpenTextDocumentNotification.type, {
      textDocument: { uri, languageId: "markdown", version: 1, text },
    });
    entry.opened.set(uri, { version: 1, text });
    return true;
  }
  if (prev.text !== text) {
    const version = prev.version + 1;
    entry.conn.sendNotification(DidChangeTextDocumentNotification.type, {
      textDocument: { uri, version },
      contentChanges: [{ text }],
    });
    entry.opened.set(uri, { version, text });
    return true;
  }
  return false;
}

async function definitionWithTimeout(
  conn: ProtocolConnection,
  params: { textDocument: { uri: string }; position: Position },
): Promise<string | null> {
  const source = new CancellationTokenSource();
  const timer = setTimeout(() => source.cancel(), DEFINITION_TIMEOUT_MS);
  try {
    const result = await conn.sendRequest(DefinitionRequest.type, params, source.token);
    return extractTargetUri(result);
  } catch {
    return null;
  } finally {
    clearTimeout(timer);
    source.dispose();
  }
}

function extractTargetUri(def: Definition | DefinitionLink[] | null | undefined): string | null {
  let uri: string | null = null;
  if (Array.isArray(def)) {
    if (def.length === 0) return null;
    const first = def[0] as Location | DefinitionLink;
    uri = (first as Location).uri ?? (first as DefinitionLink).targetUri ?? null;
  } else if (def) {
    uri = (def as Location).uri ?? null;
  }
  return uri ? fileURLToPath(uri) : null;
}

export async function resolveDefinitions(params: {
  root: string;
  docPath: string;
  text: string;
  targets: { target: string; position: Position }[];
}): Promise<ResolveOutcome> {
  const { root, docPath, text, targets } = params;
  let entry: ClientEntry;
  try {
    entry = await getClient(root);
  } catch {
    availability = false;
    return { status: "error" };
  }

  const docUri = pathToFileURL(docPath).href;
  let synced = false;
  try {
    synced = syncDocument(entry, docUri, text);
  } catch {
    return { status: "error" };
  }
  if (synced) await sleep(WARMUP_MS);

  const map = new Map<string, string | null>();
  await Promise.all(
    targets.map(async ({ target, position }) => {
      const resolved = await definitionWithTimeout(entry.conn, {
        textDocument: { uri: docUri },
        position,
      });
      map.set(target, resolved);
    }),
  );
  return { status: "ok", map };
}

export async function shutdownAll(): Promise<void> {
  const entries = [...pool.values()];
  pool.clear();
  await Promise.all(
    entries.map(async (entry) => {
      try {
        await entry.conn.sendRequest(ShutdownRequest.type);
        entry.conn.sendNotification(ExitNotification.type);
      } catch {}
      try {
        entry.proc.kill();
      } catch {}
    }),
  );
}
