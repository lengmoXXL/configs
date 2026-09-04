#!/usr/bin/env python3
"""Install opencode config: official providers + keys from .secrets/ai-providers.json.

密钥写入 opencode 官方 auth 文件 ~/.local/share/opencode/auth.json；
provider 全部用官方注册表（models.dev），不做自定义 provider 配置。
UPDATE=1 时未安装跳过，变更前确认。
"""

import json
import os
import sys
from pathlib import Path

UPDATE = os.environ.get("UPDATE") == "1"

# ai-providers.json key -> opencode 官方 provider id
PROVIDER_KEYS = {
    "zai": "zai-coding-plan",
    "deepseek": "deepseek",
    "kimi": "kimi-for-coding",
}


def main() -> int:
    try:
        root = Path(__file__).resolve().parents[1]
        secrets_dir = Path(os.environ.get("SECRETS_DIR", root / ".secrets")).expanduser()

        with (secrets_dir / "ai-providers.json").open("r", encoding="utf-8") as fh:
            api_keys = json.load(fh)

        auth_path = Path.home() / ".local" / "share" / "opencode" / "auth.json"
        config_path = Path.home() / ".config" / "opencode" / "opencode.json"
        if UPDATE and not auth_path.exists() and not config_path.exists():
            print(f"未安装，跳过: {config_path}")
            return 0

        auth = {}
        if auth_path.exists():
            with auth_path.open("r", encoding="utf-8") as fh:
                auth = json.load(fh)
        changed = False
        for key_name, provider_id in PROVIDER_KEYS.items():
            api_key = api_keys.get(key_name)
            if not isinstance(api_key, str) or not api_key:
                print(f"跳过 {provider_id}: ai-providers.json 缺少 key {key_name}")
                continue
            entry = {"type": "api", "key": api_key}
            if auth.get(provider_id) != entry:
                auth[provider_id] = entry
                changed = True

        config = {"$schema": "https://opencode.ai/config.json"}
        config_content = json.dumps(config, ensure_ascii=False, indent=2) + "\n"
        config_changed = not (
            config_path.exists()
            and config_path.read_text(encoding="utf-8") == config_content
        )

        if not changed and not config_changed:
            print("已是最新: opencode 配置与密钥")
            return 0

        if UPDATE:
            try:
                answer = input("将更新 opencode auth/配置，继续? [y/N] ")
            except EOFError:
                answer = ""
            if answer.strip().lower() not in ("y", "yes"):
                print("已取消")
                return 0

        if changed:
            auth_path.parent.mkdir(parents=True, exist_ok=True)
            auth_path.write_text(
                json.dumps(auth, ensure_ascii=False, indent=2) + "\n",
                encoding="utf-8",
            )
            auth_path.chmod(0o600)
            print(f"写入: {auth_path}")
        if config_changed:
            config_path.parent.mkdir(parents=True, exist_ok=True)
            config_path.write_text(config_content, encoding="utf-8")
            config_path.chmod(0o600)
            print(f"写入: {config_path}")
        return 0
    except (KeyError, OSError, TypeError, json.JSONDecodeError, ValueError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
