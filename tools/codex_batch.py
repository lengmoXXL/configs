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
from typing import Any, TextIO, cast


STATE_VERSION = 3

TEMPLATE_VAR_PATTERN = re.compile(r"\{([A-Za-z_][A-Za-z0-9_]*|\.)\}")
OUTPUT_BLOCK_PATTERN = re.compile(r"(?ms)^[ \t]*```output[ \t]*\n(?P<body>.*?)\n[ \t]*```[ \t]*(?:\n|$)")
DEFAULT_OUTPUT_PREVIEW_CHARS = 240
DEFAULT_OUTPUT_DIR_SUFFIX = ".codex-batch"
DEFAULT_MODEL = "default"
DEFAULT_REASONING_EFFORT = "medium"
DEFAULT_SANDBOX_MODE = "workspace-write"
DEFAULT_APPROVAL_POLICY = "never"
OUTPUT_FIELD_SPEC_KEYS = {"description", "enums", "enum"}
RESULT_FILE_NAME = "result.json"
STATE_FILE_NAME = "state.json"
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


def atomic_write_text(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile("w", encoding="utf-8", dir=path.parent, delete=False) as tmp:
        tmp.write(content)
        tmp_path = Path(tmp.name)
    tmp_path.replace(path)


def atomic_write_json(path: Path, data: Any) -> None:
    atomic_write_text(path, json.dumps(data, ensure_ascii=False, indent=2) + "\n")


def load_task(path: Path) -> tuple[str, dict[str, Any], str]:
    task_text = path.read_text(encoding="utf-8")
    matches = list(OUTPUT_BLOCK_PATTERN.finditer(task_text))
    if len(matches) != 1:
        raise ValueError(f"task Markdown must contain exactly one ```output code block: {path}")

    output_block = matches[0]
    try:
        output_spec = json.loads(output_block.group("body"))
    except json.JSONDecodeError as exc:
        raise ValueError(f"```output block must contain valid JSON: {path}: {exc}") from exc
    if not isinstance(output_spec, dict):
        raise ValueError(f"```output block must contain a JSON object: {path}")

    prompt_template = (task_text[: output_block.start()] + task_text[output_block.end() :]).strip()
    if not prompt_template:
        raise ValueError(f"task Markdown prompt is empty after removing ```output block: {path}")
    task_digest = hashlib.sha256(task_text.encode("utf-8")).hexdigest()
    return prompt_template, output_spec, task_digest


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


def render_output_spec(spec: Any, value: Any) -> Any:
    if isinstance(spec, dict):
        return {key: render_output_spec(field_spec, value) for key, field_spec in spec.items()}
    if isinstance(spec, list):
        return [render_output_spec(item_spec, value) for item_spec in spec]
    if isinstance(spec, str):
        return render_template(spec, value)
    return spec


def json_type_name(value: Any) -> str:
    if isinstance(value, bool):
        return "boolean"
    if isinstance(value, int) and not isinstance(value, bool):
        return "integer"
    if isinstance(value, float):
        return "number"
    if value is None:
        return "null"
    return "string"


def is_output_field_spec(spec: Any) -> bool:
    return isinstance(spec, dict) and bool(OUTPUT_FIELD_SPEC_KEYS & set(spec))


def enum_type_names(values: list[Any]) -> list[str]:
    return sorted({json_type_name(value) for value in values})


def output_node_schema(spec: Any, path: str) -> dict[str, Any]:
    if is_output_field_spec(spec):
        schema: dict[str, Any] = {}
        description = spec.get("description")
        enum_values = spec.get("enums", spec.get("enum"))
        if isinstance(description, str) and description:
            schema["description"] = description
        if isinstance(enum_values, list):
            schema["enum"] = enum_values
            type_names = enum_type_names(enum_values)
            if len(type_names) == 1:
                schema["type"] = type_names[0]
            elif type_names:
                schema["type"] = type_names
        else:
            schema["type"] = "string"
        return schema

    if isinstance(spec, dict):
        properties: dict[str, Any] = {}
        required: list[str] = []
        for key, child_spec in spec.items():
            if not isinstance(key, str) or not key:
                raise ValueError(f"output field name must be a non-empty string: {path}")
            properties[key] = output_node_schema(child_spec, f"{path}.{key}")
            required.append(key)
        return {
            "type": "object",
            "additionalProperties": False,
            "properties": properties,
            "required": required,
        }

    if isinstance(spec, list):
        if len(spec) != 1:
            raise ValueError(f"output array spec must contain exactly one item: {path}")
        return {
            "type": "array",
            "items": output_node_schema(spec[0], f"{path}[]"),
        }

    if isinstance(spec, str):
        return {
            "type": "string",
            "description": spec,
        }

    if spec is None:
        return {
            "type": ["string", "null"],
        }

    return {
        "type": json_type_name(spec),
    }


def output_schema(output_spec: dict[str, Any]) -> dict[str, Any]:
    schema = output_node_schema(output_spec, "output")
    schema["$schema"] = "https://json-schema.org/draft/2020-12/schema"
    return schema


def output_description_lines(spec: Any, prefix: str = "") -> list[str]:
    if is_output_field_spec(spec):
        description = spec.get("description")
        enum_values = spec.get("enums", spec.get("enum"))
        details: list[str] = []
        if isinstance(description, str) and description:
            details.append(description)
        if isinstance(enum_values, list):
            details.append("enum: " + ", ".join(json.dumps(value, ensure_ascii=False) for value in enum_values))
        if not details:
            details.append("string")
        return [f"- {prefix}: {'; '.join(details)}"] if prefix else []

    if isinstance(spec, dict):
        lines: list[str] = []
        for key, value in spec.items():
            field_path = f"{prefix}.{key}" if prefix else key
            if is_output_field_spec(value):
                lines.extend(output_description_lines(value, field_path))
                continue
            if isinstance(value, str):
                lines.append(f"- {field_path}: {value}")
            elif isinstance(value, list):
                lines.append(f"- {field_path}: array")
            elif isinstance(value, dict):
                lines.append(f"- {field_path}: object")
            else:
                lines.append(f"- {field_path}: {json_type_name(value)}")
            lines.extend(output_description_lines(value, field_path))
        return lines
    if isinstance(spec, list) and spec:
        return output_description_lines(spec[0], f"{prefix}[]")
    return []


def build_prompt(prompt_template: str, value: Any, output_spec: dict[str, Any], schema: dict[str, Any]) -> str:
    prompt_body = render_template(prompt_template, value).strip()
    descriptions = "\n".join(output_description_lines(output_spec))
    schema_text = json.dumps(schema, ensure_ascii=False, indent=2)
    output_spec_text = json.dumps(output_spec, ensure_ascii=False, indent=2)
    output_instructions = "\n".join(
        [
            "<output_instructions>",
            "Return only a JSON object that matches the JSON Schema below.",
            "The batch runner will merge each item response into result.json.",
            "Do not include Markdown, code fences, or explanatory text in your final response.",
            "String leaves in the output spec are descriptions of the fields to produce.",
            "",
            "<output_spec>",
            output_spec_text,
            "</output_spec>",
            "",
            "<fields>",
            descriptions,
            "</fields>",
            "",
            "<json_schema>",
            schema_text,
            "</json_schema>",
            "</output_instructions>",
        ]
    )
    return f"{prompt_body}\n\n{output_instructions}\n"


def parse_result_value(result_text: str) -> dict[str, Any]:
    if not result_text.strip():
        raise ValueError("codex output is empty")
    try:
        result_value = json.loads(result_text)
    except json.JSONDecodeError as exc:
        raise ValueError(f"codex output is not valid JSON: {exc}") from exc
    if not isinstance(result_value, dict):
        raise ValueError("codex output must be a JSON object")
    return result_value


def write_result_file(path: Path, records: list[dict[str, Any]], items: list[dict[str, Any]]) -> None:
    results: list[dict[str, Any]] = []
    for record in ordered_records(records, items):
        result_value = record.get("result_value")
        if not isinstance(result_value, dict):
            result_value = parse_result_value(str(record.get("result_text", "")))
        results.append(result_value)
    atomic_write_json(path, results)


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
        item_key_payload = f"{index}:{canonical_json(value)}"
        built.append(
            {
                "value": value,
                "item_key": hashlib.sha256(item_key_payload.encode("utf-8")).hexdigest()[:16],
            }
        )
    return built


def ordered_records(records: list[dict[str, Any]], current_items: list[dict[str, Any]]) -> list[dict[str, Any]]:
    position = {item["item_key"]: idx for idx, item in enumerate(current_items)}
    return sorted(records, key=lambda record: (position.get(record["item_key"], 10**9), record.get("completed_at", "")))


def refresh_completed_records(
    records: list[dict[str, Any]],
    current_items: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    current_by_key = {item["item_key"]: item for item in current_items}
    refreshed: list[dict[str, Any]] = []
    for record in ordered_records(records, current_items):
        updated = dict(record)
        current = current_by_key.get(record["item_key"])
        if current is not None:
            updated["value"] = current["value"]
        result_value = updated.get("result_value")
        if not isinstance(result_value, dict):
            result_value = parse_result_value(str(updated.get("result_text", "")))
        updated["result_value"] = result_value
        updated["result_json"] = result_value
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


def stream_codex(
    prompt: str,
    workdir: Path,
    output_file: Path,
    output_schema_file: Path,
    slot_index: int,
    model: str,
) -> int:
    cmd = [
        "codex",
        "exec",
        "--skip-git-repo-check",
        "--sandbox",
        DEFAULT_SANDBOX_MODE,
        "-c",
        f'approval_policy="{DEFAULT_APPROVAL_POLICY}"',
        "-c",
        f'model_reasoning_effort="{DEFAULT_REASONING_EFFORT}"',
        "--json",
        "--color",
        "never",
        "--output-last-message",
        str(output_file),
        "--output-schema",
        str(output_schema_file),
        "-",
    ]
    if model != DEFAULT_MODEL:
        cmd[3:3] = ["--model", model]
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
            line = cast(TextIO, key.fileobj).readline()
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
    parser.add_argument("task_md", help="任务 Markdown 文件路径，移除 ```output 代码块后作为提示词，支持 {input} / {.}")
    parser.add_argument(
        "--output",
        help="输出目录，默认是 <input>.codex-batch",
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
    parser.add_argument(
        "--model",
        default=DEFAULT_MODEL,
        help=f"codex exec 使用的模型，默认 {DEFAULT_MODEL}",
    )
    return parser.parse_args()


def rewrite_outputs_from_state(
    state: dict[str, Any],
    items: list[dict[str, Any]],
    result_path: Path,
    state_path: Path,
) -> None:
    state["completed"] = refresh_completed_records(state["completed"], items)
    write_result_file(result_path, state["completed"], items)
    atomic_write_json(state_path, state)


def process_item(
    item: dict[str, Any],
    item_number: int,
    total_items: int,
    prompt_template: str,
    output_spec_template: dict[str, Any],
    workdir: Path,
    state: dict[str, Any],
    items: list[dict[str, Any]],
    result_path: Path,
    state_path: Path,
    state_lock: threading.Lock,
    slot_index: int,
    model: str,
) -> int:
    output_spec = render_output_spec(output_spec_template, item["value"])
    schema = output_schema(output_spec)
    prompt = build_prompt(prompt_template, item["value"], output_spec, schema)
    log_line(f"[Worker {slot_index + 1}] Start item {item_number}/{total_items}")

    with tempfile.NamedTemporaryFile("w", encoding="utf-8", delete=False, suffix=".json") as tmp_schema:
        json.dump(schema, tmp_schema, ensure_ascii=False, indent=2)
        tmp_schema.write("\n")
        tmp_schema_path = Path(tmp_schema.name)

    with tempfile.NamedTemporaryFile("w+", encoding="utf-8", delete=False, suffix=".json") as tmp_output:
        tmp_output_path = Path(tmp_output.name)

    try:
        return_code = stream_codex(
            prompt=prompt,
            workdir=workdir,
            output_file=tmp_output_path,
            output_schema_file=tmp_schema_path,
            slot_index=slot_index,
            model=model,
        )
        result_text = tmp_output_path.read_text(encoding="utf-8") if tmp_output_path.exists() else ""
    finally:
        tmp_schema_path.unlink(missing_ok=True)
        tmp_output_path.unlink(missing_ok=True)

    if return_code != 0:
        log_line(f"Error: Item {item_number} exited with code {return_code}")
        return return_code

    result_value = parse_result_value(result_text)
    record = {
        "item_key": item["item_key"],
        "value": item["value"],
        "result_text": result_text,
        "result_value": result_value,
        "result_json": result_value,
        "completed_at": now_iso(),
    }
    with state_lock:
        for index, existing in enumerate(state["completed"]):
            if existing["item_key"] == record["item_key"]:
                state["completed"][index] = record
                break
        else:
            state["completed"].append(record)
        state["last_completed_at"] = record["completed_at"]
        rewrite_outputs_from_state(state, items, result_path, state_path)
    return 0


def run_batch(args: argparse.Namespace) -> int:
    if args.jobs < 1:
        raise ValueError("--jobs must be >= 1")
    input_path = Path(args.input_json).expanduser().resolve()
    task_path = Path(args.task_md).expanduser().resolve()
    if args.output:
        output_dir = Path(args.output).expanduser().resolve()
    elif input_path.suffix:
        output_dir = input_path.with_suffix(DEFAULT_OUTPUT_DIR_SUFFIX)
    else:
        output_dir = input_path.with_name(f"{input_path.name}{DEFAULT_OUTPUT_DIR_SUFFIX}")
    if output_dir.exists() and not output_dir.is_dir():
        raise ValueError(f"--output must be a directory: {output_dir}")
    result_path = output_dir / RESULT_FILE_NAME
    state_path = output_dir / STATE_FILE_NAME
    workdir = Path(args.cd).expanduser().resolve()

    with input_path.open("r", encoding="utf-8") as fh:
        source_data = json.load(fh)
    prompt_template, output_spec, task_digest = load_task(task_path)
    items = build_items(source_data)
    current_keys = {item["item_key"] for item in items}

    state_exists = state_path.exists()
    state = load_state(state_path)
    previous_state_version = state.get("version")
    previous_task_digest = state.get("task_digest")
    state["version"] = STATE_VERSION
    state["input_file"] = str(input_path)
    state["task_file"] = str(task_path)
    state["task_digest"] = task_digest
    state["output_dir"] = str(output_dir)
    state["result_file"] = str(result_path)
    state["workdir"] = str(workdir)
    state["model"] = args.model
    state["sandbox_mode"] = DEFAULT_SANDBOX_MODE
    state["approval_policy"] = DEFAULT_APPROVAL_POLICY
    state["last_started_at"] = now_iso()
    state["current_item_keys"] = [item["item_key"] for item in items]
    state["input_digest"] = hashlib.sha256(canonical_json(source_data).encode("utf-8")).hexdigest()

    if state_exists and (
        previous_state_version != STATE_VERSION or previous_task_digest != task_digest
    ) and state["completed"]:
        state["completed"] = []
        state.pop("last_completed_at", None)
        state.pop("last_finished_at", None)
        write_result_file(result_path, [], items)

    stale_records = [record for record in state["completed"] if record["item_key"] not in current_keys]
    if stale_records:
        if args.stale == "purge":
            state["completed"] = [record for record in state["completed"] if record["item_key"] in current_keys]
            state["completed"] = refresh_completed_records(state["completed"], items)
            write_result_file(result_path, state["completed"], items)
            if state["completed"]:
                state["last_completed_at"] = state["completed"][-1]["completed_at"]
            else:
                state.pop("last_completed_at", None)

    if state_exists and state["completed"]:
        rewrite_outputs_from_state(state, items, result_path, state_path)
    else:
        write_result_file(result_path, [], items)

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
                        prompt_template=prompt_template,
                        output_spec_template=output_spec,
                        workdir=workdir,
                        state=state,
                        items=items,
                        result_path=result_path,
                        state_path=state_path,
                        state_lock=state_lock,
                        slot_index=slot_index,
                        model=args.model,
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
