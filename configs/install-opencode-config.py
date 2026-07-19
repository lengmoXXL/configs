#!/usr/bin/env python3
"""Install opencode config to ~/.config/opencode/opencode.json."""

import json
import os
import sys
from pathlib import Path


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
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(
            json.dumps(config, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        target.chmod(0o600)
        print(f"installed: {target}")
        return 0
    except (KeyError, OSError, TypeError, json.JSONDecodeError, ValueError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
