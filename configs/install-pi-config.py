#!/usr/bin/env python3
"""Install Pi config from configs/pi to ~/.pi/agent."""

import json
import os
import shutil
import sys
from pathlib import Path


def main() -> int:
    try:
        root = Path(__file__).resolve().parents[1]
        source = root / "configs" / "pi"
        secrets_dir = Path(os.environ.get("SECRETS_DIR", root / ".secrets")).expanduser()

        with (source / "models.json").open("r", encoding="utf-8") as fh:
            models = json.load(fh)
        with (secrets_dir / "ai-providers.json").open("r", encoding="utf-8") as fh:
            api_keys = json.load(fh)

        for provider_name, provider in models["providers"].items():
            reference = provider["apiKey"]
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
            provider["apiKey"] = api_key

        target = Path.home() / ".pi" / "agent"
        target.mkdir(parents=True, exist_ok=True)
        (target / "models.json").write_text(
            json.dumps(models, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        (target / "models.json").chmod(0o600)
        shutil.copy2(source / "settings.json", target / "settings.json")
        shutil.copytree(source / "themes", target / "themes", dirs_exist_ok=True)
        print(f"installed: {target}")
        return 0
    except (KeyError, OSError, TypeError, json.JSONDecodeError, ValueError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
