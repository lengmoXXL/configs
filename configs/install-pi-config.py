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
        target.mkdir(parents=True, exist_ok=True)
        if models is not None:
            (target / "models.json").write_text(
                json.dumps(models, ensure_ascii=False, indent=2) + "\n",
                encoding="utf-8",
            )
            (target / "models.json").chmod(0o600)
        if auth is not None:
            (target / "auth.json").write_text(
                json.dumps(auth, ensure_ascii=False, indent=2) + "\n",
                encoding="utf-8",
            )
            (target / "auth.json").chmod(0o600)
        shutil.copy2(source / "settings.json", target / "settings.json")
        shutil.copy2(source / "pi-plan-mode.json", target / "pi-plan-mode.json")
        shutil.copytree(source / "themes", target / "themes", dirs_exist_ok=True)
        ext_target = target / "extensions"
        ext_target.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source / "pi-footer.json", ext_target / "pi-footer.json")
        print(f"installed: {target}")
        return 0
    except (KeyError, OSError, TypeError, json.JSONDecodeError, ValueError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
