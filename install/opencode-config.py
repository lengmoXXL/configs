#!/usr/bin/env python3
"""Install opencode config to ~/.config/opencode/opencode.json.

UPDATE=1 时按需更新：未安装则跳过，内容一致则不写入。
"""

import json
import os
import sys
from pathlib import Path

UPDATE = os.environ.get("UPDATE") == "1"


def main() -> int:
    try:
        root = Path(__file__).resolve().parents[1]
        source = root / "configs" / "opencode" / "opencode.json"
        secrets_dir = Path(os.environ.get("SECRETS_DIR", root / ".secrets")).expanduser()

        with source.open("r", encoding="utf-8") as fh:
            config = json.load(fh)
        with (secrets_dir / "ai-providers.json").open("r", encoding="utf-8") as fh:
            api_keys = json.load(fh)

        for provider_name, provider in config["provider"].items():
            reference = provider["options"]["apiKey"]
            if (
                not isinstance(reference, str)
                or not reference.startswith("${")
                or not reference.endswith("}")
            ):
                raise ValueError(f"provider {provider_name}: apiKey must be a ${{provider}} reference")
            api_key_name = reference[2:-1]
            api_key = api_keys.get(api_key_name)
            if not isinstance(api_key, str) or not api_key:
                raise ValueError(f"provider {provider_name}: missing API key {api_key_name}")
            provider["options"]["apiKey"] = api_key

        target = Path.home() / ".config" / "opencode" / "opencode.json"
        if UPDATE and not target.exists():
            print(f"未安装，跳过: {target}")
            return 0
        content = json.dumps(config, ensure_ascii=False, indent=2) + "\n"
        if target.exists() and target.read_text(encoding="utf-8") == content:
            print(f"配置已是最新: {target}")
            return 0
        if UPDATE:
            try:
                answer = input(f"将写入: {target}\n应用以上变更? [y/N] ")
            except EOFError:
                answer = ""
            if answer.strip().lower() not in ("y", "yes"):
                print("已取消")
                return 0
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content, encoding="utf-8")
        target.chmod(0o600)
        print(f"installed: {target}")
        return 0
    except (KeyError, OSError, TypeError, json.JSONDecodeError, ValueError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
