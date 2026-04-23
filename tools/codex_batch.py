#!/usr/bin/env python3

from __future__ import annotations

import argparse
import hashlib
import json
import queue
import re
import selectors
import subprocess
import sys
import tempfile
import threading
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


STATE_VERSION = 1
TEMPLATE_VAR_PATTERN = re.compile(r"\{([A-Za-z_][A-Za-z0-9_]*|\.)\}")
DEFAULT_OUTPUT_PREVIEW_CHARS = 240
PRINT_LOCK = threading.Lock()


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def single_line(text: str) -> str:
    flattened = " ".join(text.split()) or "(empty)"
    if len(flattened) <= DEFAULT_OUTPUT_PREVIEW_CHARS:
        return flattened
    return flattened[: DEFAULT_OUTPUT_PREVIEW_CHARS - 12].rstrip() + "<truncated>"


def log_line(text: str) -> None:
    with PRINT_LOCK:
        print(text, file=sys.stderr, flush=True)

def canonical_json(value: Any) -> str:
    return json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":"))


def display_value(value: Any) -> str:
    if isinstance(value, str):
        return value
    return json.dumps(value, ensure_ascii=False, indent=2)


def item_key(value: Any, source_index: int) -> str:
    payload = f"{source_index}:{canonical_json(value)}"
    return hashlib.sha256(payload.encode("utf-8")).hexdigest()[:16]


def sha256_text(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def default_result_path(input_path: Path) -> Path:
    if input_path.suffix:
        return input_path.with_suffix(".result.md")
    return input_path.with_name(f"{input_path.name}.result.md")


def default_state_path(input_path: Path) -> Path:
    if input_path.suffix:
        return input_path.with_suffix(".state.json")
    return input_path.with_name(f"{input_path.name}.state.json")


def atomic_write_text(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile("w", encoding="utf-8", dir=path.parent, delete=False) as tmp:
        tmp.write(content)
        tmp_path = Path(tmp.name)
    tmp_path.replace(path)


def atomic_write_json(path: Path, data: dict[str, Any]) -> None:
    atomic_write_text(path, json.dumps(data, ensure_ascii=False, indent=2) + "\n")


def render_template(template: str, value: Any) -> str:
    variables: dict[str, str] = {
        "input": display_value(value),
        ".": display_value(value),
    }
    if isinstance(value, dict):
        for key, field_value in value.items():
            if isinstance(key, str) and re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", key):
                variables[key] = display_value(field_value)

    missing_keys: set[str] = set()

    def replace_var(match: re.Match[str]) -> str:
        name = match.group(1)
        if name in variables:
            return variables[name]
        missing_keys.add(name)
        return match.group(0)

    rendered = TEMPLATE_VAR_PATTERN.sub(replace_var, template)
    if missing_keys:
        raise ValueError(f"template references undefined variables: {', '.join(sorted(missing_keys))}")
    return rendered


def block_for_result(item_number: int, result_text: str) -> str:
    output_body = result_text.rstrip() or "(empty)"
    return "\n".join(
        [
            f"## Item {item_number}",
            "",
            output_body,
            "",
        ]
    )


def write_result_file(path: Path, blocks: list[str]) -> None:
    content = ""
    if blocks:
        content = "\n---\n\n".join(block.rstrip() for block in blocks) + "\n"
    atomic_write_text(path, content)


def load_json_file(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as fh:
        return json.load(fh)


def load_state(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {
            "version": STATE_VERSION,
            "completed": [],
        }
    with path.open("r", encoding="utf-8") as fh:
        data = json.load(fh)
    if not isinstance(data, dict):
        raise ValueError(f"state file is not an object: {path}")
    data.setdefault("version", STATE_VERSION)
    data.setdefault("completed", [])
    return data


def build_items(data: Any) -> list[dict[str, Any]]:
    if isinstance(data, list):
        items = data
    else:
        items = [data]

    built: list[dict[str, Any]] = []
    for index, value in enumerate(items):
        built.append(
            {
                "value": value,
                "item_key": item_key(value, source_index=index),
            }
        )
    return built


def ordered_records(records: list[dict[str, Any]], current_items: list[dict[str, Any]]) -> list[dict[str, Any]]:
    position = {item["item_key"]: idx for idx, item in enumerate(current_items)}
    return sorted(records, key=lambda record: (position.get(record["item_key"], 10**9), record.get("completed_at", "")))


def refresh_completed_records(records: list[dict[str, Any]], current_items: list[dict[str, Any]]) -> list[dict[str, Any]]:
    current_by_key = {item["item_key"]: item for item in current_items}
    refreshed: list[dict[str, Any]] = []
    for record in ordered_records(records, current_items):
        updated = dict(record)
        current = current_by_key.get(record["item_key"])
        if current is not None:
            updated["value"] = current["value"]
        updated["result_markdown"] = block_for_result(
            item_number=len(refreshed) + 1,
            result_text=updated.get("result_text", ""),
        )
        refreshed.append(updated)
    return refreshed


def log_codex_event(event: dict[str, Any], slot_index: int) -> None:
    event_type = event.get("type")
    if event_type in {"item.started", "item.completed"}:
        item = event.get("item")
        if not isinstance(item, dict):
            return

        item_type = item.get("type")
        if item_type == "agent_message" and event_type == "item.completed":
            text = str(item.get("text", "")).strip()
            if text:
                log_line(f"[Worker {slot_index + 1}] {single_line(text)}")
            return

        if item_type == "command_execution":
            return

        return

    if event_type == "error":
        return

    if event_type == "turn.completed":
        return


def stream_codex(prompt: str, workdir: Path, output_file: Path, slot_index: int) -> int:
    cmd = [
        "codex",
        "exec",
        "--skip-git-repo-check",
        "--json",
        "--color",
        "never",
        "--output-last-message",
        str(output_file),
        "-",
    ]
    process = subprocess.Popen(
        cmd,
        cwd=str(workdir),
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        bufsize=1,
    )

    selector = selectors.DefaultSelector()
    assert process.stdin is not None
    assert process.stdout is not None
    assert process.stderr is not None
    process.stdin.write(prompt)
    process.stdin.close()
    selector.register(process.stdout, selectors.EVENT_READ, "stdout")
    selector.register(process.stderr, selectors.EVENT_READ, "stderr")

    while selector.get_map():
        for key, _ in selector.select():
            line = key.fileobj.readline()
            if line == "":
                selector.unregister(key.fileobj)
                continue
            payload = line.rstrip("\n")
            if key.data == "stdout":
                try:
                    event = json.loads(payload)
                except json.JSONDecodeError:
                    continue
                else:
                    log_codex_event(event, slot_index=slot_index)

    return process.wait()


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Batch-run prompts from a JSON file through Codex with resumable state."
    )
    parser.add_argument("input_json", help="输入 JSON 文件路径")
    parser.add_argument("template_md", help="提示词模板 Markdown 文件路径，支持 {input} / {.}")
    parser.add_argument(
        "--output",
        help="结果 Markdown 文件路径，默认是 <input>.result.md",
    )
    parser.add_argument(
        "--state",
        help="状态 JSON 文件路径，默认是 <input>.state.json",
    )
    parser.add_argument(
        "--stale",
        choices=["keep", "purge"],
        default="keep",
        help="旧 state 里存在、但新输入里不存在的 item 如何处理",
    )
    parser.add_argument(
        "--cd",
        default=".",
        help="codex exec 的工作目录，默认当前目录",
    )
    parser.add_argument(
        "--jobs",
        type=int,
        default=1,
        help="同时运行的 codex 数量，默认 1",
    )
    return parser.parse_args()


def upsert_completed_record(state: dict[str, Any], record: dict[str, Any]) -> None:
    for index, existing in enumerate(state["completed"]):
        if existing["item_key"] == record["item_key"]:
            state["completed"][index] = record
            return
    state["completed"].append(record)


def rewrite_outputs_from_state(state: dict[str, Any], items: list[dict[str, Any]], result_path: Path, state_path: Path) -> None:
    state["completed"] = refresh_completed_records(state["completed"], items)
    blocks = [record["result_markdown"] for record in ordered_records(state["completed"], items)]
    write_result_file(result_path, blocks)
    atomic_write_json(state_path, state)


def process_item(
    item: dict[str, Any],
    item_number: int,
    total_items: int,
    template: str,
    workdir: Path,
    state: dict[str, Any],
    items: list[dict[str, Any]],
    result_path: Path,
    state_path: Path,
    state_lock: threading.Lock,
    slot_index: int,
) -> int:
    prompt = render_template(template, item["value"])
    log_line(f"[Worker {slot_index + 1}] Start item {item_number}/{total_items}")

    with tempfile.NamedTemporaryFile("w+", encoding="utf-8", delete=False, suffix=".md") as tmp_output:
        tmp_output_path = Path(tmp_output.name)

    try:
        return_code = stream_codex(
            prompt=prompt,
            workdir=workdir,
            output_file=tmp_output_path,
            slot_index=slot_index,
        )
        result_text = tmp_output_path.read_text(encoding="utf-8") if tmp_output_path.exists() else ""
    finally:
        tmp_output_path.unlink(missing_ok=True)

    if return_code != 0:
        log_line(f"Error: Item {item_number} exited with code {return_code}")
        return return_code

    record = {
        "item_key": item["item_key"],
        "value": item["value"],
        "result_text": result_text,
        "result_markdown": block_for_result(item_number=item_number, result_text=result_text),
        "completed_at": now_iso(),
    }
    with state_lock:
        upsert_completed_record(state, record)
        state["last_completed_at"] = record["completed_at"]
        rewrite_outputs_from_state(state, items, result_path, state_path)
    return 0


def run_batch(args: argparse.Namespace) -> int:
    if args.jobs < 1:
        raise ValueError("--jobs must be >= 1")
    input_path = Path(args.input_json).expanduser().resolve()
    template_path = Path(args.template_md).expanduser().resolve()
    result_path = Path(args.output).expanduser().resolve() if args.output else default_result_path(input_path)
    state_path = Path(args.state).expanduser().resolve() if args.state else default_state_path(input_path)
    workdir = Path(args.cd).expanduser().resolve()

    source_data = load_json_file(input_path)
    template = template_path.read_text(encoding="utf-8")
    template_digest = sha256_text(template)
    items = build_items(source_data)
    current_keys = {item["item_key"] for item in items}

    state_exists = state_path.exists()
    state = load_state(state_path)
    previous_template_digest = state.get("template_digest")
    state["version"] = STATE_VERSION
    state["input_file"] = str(input_path)
    state["template_file"] = str(template_path)
    state["template_digest"] = template_digest
    state["result_file"] = str(result_path)
    state["workdir"] = str(workdir)
    state["last_started_at"] = now_iso()
    state["current_item_keys"] = [item["item_key"] for item in items]
    state["input_digest"] = hashlib.sha256(canonical_json(source_data).encode("utf-8")).hexdigest()

    if state_exists and previous_template_digest != template_digest and state["completed"]:
        state["completed"] = []
        state.pop("last_completed_at", None)
        state.pop("last_finished_at", None)
        write_result_file(result_path, [])

    stale_records = [record for record in state["completed"] if record["item_key"] not in current_keys]
    if stale_records:
        if args.stale == "purge":
            state["completed"] = [record for record in state["completed"] if record["item_key"] in current_keys]
            state["completed"] = refresh_completed_records(state["completed"], items)
            kept_blocks = [record["result_markdown"] for record in ordered_records(state["completed"], items)]
            write_result_file(result_path, kept_blocks)
            if state["completed"]:
                state["last_completed_at"] = state["completed"][-1]["completed_at"]
            else:
                state.pop("last_completed_at", None)

    if state_exists and state["completed"]:
        rewrite_outputs_from_state(state, items, result_path, state_path)
    elif state_exists and result_path.exists():
        write_result_file(result_path, [])

    atomic_write_json(state_path, state)

    done_keys = {record["item_key"] for record in state["completed"] if record["item_key"] in current_keys}
    pending_items = [
        (index + 1, item)
        for index, item in enumerate(items)
        if item["item_key"] not in done_keys
    ]
    if not pending_items:
        state["last_finished_at"] = now_iso()
        atomic_write_json(state_path, state)
        return 0

    job_count = min(args.jobs, len(pending_items))
    log_line(f"Starting batch with {job_count} worker(s)")
    task_queue: queue.Queue[tuple[int, dict[str, Any]] | None] = queue.Queue()
    state_lock = threading.Lock()
    error_lock = threading.Lock()
    abort_event = threading.Event()
    first_error = {"code": 0}

    for item_number, item in pending_items:
        task_queue.put((item_number, item))
    for _ in range(job_count):
        task_queue.put(None)

    def worker(slot_index: int) -> None:
        while True:
            task = task_queue.get()
            try:
                if task is None:
                    return
                if abort_event.is_set():
                    continue
                item_number, item = task
                try:
                    return_code = process_item(
                        item=item,
                        item_number=item_number,
                        total_items=len(items),
                        template=template,
                        workdir=workdir,
                        state=state,
                        items=items,
                        result_path=result_path,
                        state_path=state_path,
                        state_lock=state_lock,
                        slot_index=slot_index,
                    )
                except Exception as exc:
                    with error_lock:
                        if first_error["code"] == 0:
                            first_error["code"] = 1
                    log_line(f"Error: Item {item_number} failed: {exc}")
                    abort_event.set()
                    continue
                if return_code != 0:
                    with error_lock:
                        if first_error["code"] == 0:
                            first_error["code"] = return_code
                    abort_event.set()
            finally:
                task_queue.task_done()

    threads = [
        threading.Thread(target=worker, args=(slot_index,), daemon=True)
        for slot_index in range(job_count)
    ]
    for thread in threads:
        thread.start()
    task_queue.join()
    for thread in threads:
        thread.join()

    if first_error["code"] != 0:
        return first_error["code"]

    state["last_finished_at"] = now_iso()
    atomic_write_json(state_path, state)
    return 0

def main() -> int:
    args = parse_args()
    return run_batch(args)

if __name__ == "__main__":
    raise SystemExit(main())
