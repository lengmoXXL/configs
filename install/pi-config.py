#!/usr/bin/env python3
"""Install Pi config from configs/pi to ~/.pi/agent.

UPDATE=1 时按需更新：未安装（~/.pi/agent 不存在）则跳过；先列出变更
（写入/删除）并确认，再应用。
"""

import filecmp
import json
import os
import shutil
import sys
from pathlib import Path

UPDATE = os.environ.get("UPDATE") == "1"

# 每项: ("write", 目标, 内容, mode) 或 ("copy", 源, 目标) 或 ("delete", 目标)
plan = []


def plan_write(path: Path, content: str, mode: int = None) -> None:
    if path.exists() and path.read_text(encoding="utf-8") == content:
        return
    plan.append(("write", path, content, mode))


def plan_dir(src: Path, dest: Path) -> None:
    dest.mkdir(parents=True, exist_ok=True)
    src_files = {p.relative_to(src) for p in src.rglob("*") if p.is_file()}
    for rel in sorted(src_files):
        source_file, dest_file = src / rel, dest / rel
        if not dest_file.exists() or not filecmp.cmp(source_file, dest_file, shallow=False):
            plan.append(("copy", source_file, dest_file))
    for path in sorted((p for p in dest.rglob("*") if p.is_file()), reverse=True):
        if path.relative_to(dest) not in src_files:
            plan.append(("delete", path, dest))


def apply_plan() -> None:
    for item in plan:
        action = item[0]
        if action == "write":
            _, path, content, mode = item
            path.write_text(content, encoding="utf-8")
            if mode is not None:
                path.chmod(mode)
            print(f"写入: {path}")
        elif action == "copy":
            _, source_file, dest_file = item
            dest_file.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source_file, dest_file)
            print(f"写入: {dest_file}")
        else:
            _, path, dest_root = item
            path.unlink()
            print(f"删除: {path}")
            parent = path.parent
            while parent != dest_root and parent.exists() and not any(parent.iterdir()):
                parent.rmdir()
                parent = parent.parent


def main() -> int:
    try:
        root = Path(__file__).resolve().parents[1]
        source = root / "configs" / "pi"
        secrets_dir = Path(os.environ.get("SECRETS_DIR", root / ".secrets")).expanduser()

        with (secrets_dir / "ai-providers.json").open("r", encoding="utf-8") as fh:
            api_keys = json.load(fh)

        def resolve(reference: str, owner: str) -> str:
            if (
                not isinstance(reference, str)
                or not reference.startswith("${")
                or not reference.endswith("}")
            ):
                raise ValueError(f"{owner}: apiKey must be a ${{provider}} reference")
            api_key = api_keys.get(reference[2:-1])
            if not isinstance(api_key, str) or not api_key:
                raise ValueError(f"{owner}: missing API key {reference[2:-1]}")
            return api_key

        models_path = source / "models.json"
        models = None
        if models_path.exists():
            with models_path.open("r", encoding="utf-8") as fh:
                models = json.load(fh)

        auth_path = source / "auth.json"
        auth = None
        if auth_path.exists():
            with auth_path.open("r", encoding="utf-8") as fh:
                auth = json.load(fh)
            for auth_name, entry in auth.items():
                entry["key"] = resolve(entry["key"], f"auth {auth_name}")

        target = Path.home() / ".pi" / "agent"
        if UPDATE and not target.exists():
            print(f"未安装，跳过: {target}")
            return 0
        target.mkdir(parents=True, exist_ok=True)
        if models is not None:
            plan_write(
                target / "models.json",
                json.dumps(models, ensure_ascii=False, indent=2) + "\n",
                mode=0o600,
            )
        if auth is not None:
            plan_write(
                target / "auth.json",
                json.dumps(auth, ensure_ascii=False, indent=2) + "\n",
                mode=0o600,
            )
        for name in ("settings.json", "pi-plan-mode.json"):
            plan_write(
                target / name,
                (source / name).read_text(encoding="utf-8"),
            )
        plan_dir(source / "themes", target / "themes")
        plan_dir(source / "agents", target / "agents")
        ext_target = target / "extensions"
        ext_target.mkdir(parents=True, exist_ok=True)
        plan_write(
            ext_target / "pi-footer.json",
            (source / "pi-footer.json").read_text(encoding="utf-8"),
        )

        if not plan:
            print(f"已是最新: {target}")
            return 0
        for item in plan:
            if item[0] == "write":
                print(f"将写入: {item[1]}")
            elif item[0] == "copy":
                print(f"将写入: {item[2]}")
            else:
                print(f"将删除: {item[1]}")
        if UPDATE:
            try:
                answer = input("应用以上变更? [y/N] ")
            except EOFError:
                answer = ""
            if answer.strip().lower() not in ("y", "yes"):
                print("已取消")
                return 0
        apply_plan()
        print(f"installed: {target}")
        return 0
    except (KeyError, OSError, TypeError, json.JSONDecodeError, ValueError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
