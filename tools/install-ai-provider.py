#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import os
import sys
import tempfile
from pathlib import Path
from typing import Any


THINKING_OPTIONS = {
    "thinking": {
        "type": "enabled",
        "budgetTokens": 8192,
    }
}
TEXT_IMAGE_MODALITIES = {
    "input": ["text", "image"],
    "output": ["text"],
}
KNOWN_OPENCODE_MODELS: dict[str, dict[str, Any]] = {
    "qwen3.7-max": {
        "name": "Qwen3.7 Max",
        "options": THINKING_OPTIONS,
    },
    "qwen3.7-plus": {
        "name": "Qwen3.7 Plus",
        "modalities": TEXT_IMAGE_MODALITIES,
        "options": THINKING_OPTIONS,
    },
    "qwen3.6-plus": {
        "name": "Qwen3.6 Plus",
        "modalities": TEXT_IMAGE_MODALITIES,
        "options": THINKING_OPTIONS,
    },
    "qwen3.6-flash": {
        "name": "Qwen3.6 Flash",
        "modalities": TEXT_IMAGE_MODALITIES,
        "options": THINKING_OPTIONS,
    },
    "deepseek-v4-pro": {
        "name": "DeepSeek V4 Pro",
    },
    "deepseek-v4-flash": {
        "name": "DeepSeek V4 Flash",
    },
    "deepseek-v3.2": {
        "name": "DeepSeek V3.2",
    },
    "kimi-k2.7-code": {
        "name": "Kimi K2.7 Code",
        "modalities": TEXT_IMAGE_MODALITIES,
        "options": THINKING_OPTIONS,
    },
    "kimi-k2.6": {
        "name": "Kimi K2.6",
        "modalities": TEXT_IMAGE_MODALITIES,
        "options": THINKING_OPTIONS,
    },
    "kimi-k2.5": {
        "name": "Kimi K2.5",
        "modalities": TEXT_IMAGE_MODALITIES,
        "options": THINKING_OPTIONS,
    },
    "glm-5.2": {
        "name": "GLM-5.2",
        "options": THINKING_OPTIONS,
    },
    "glm-5.1": {
        "name": "GLM-5.1",
        "options": THINKING_OPTIONS,
    },
    "glm-5": {
        "name": "GLM-5",
        "options": THINKING_OPTIONS,
    },
    "MiniMax-M2.5": {
        "name": "MiniMax M2.5",
    },
}


def providers_path() -> Path:
    root = Path(__file__).resolve().parents[1]
    secrets_dir = Path(os.environ.get("SECRETS_DIR", root / ".secrets")).expanduser()
    return secrets_dir / "ai-providers.json"


def load_providers(path: Path) -> dict[str, dict[str, Any]]:
    if not path.exists():
        raise ValueError(f"missing providers file: {path}")

    with path.open("r", encoding="utf-8") as fh:
        data = json.load(fh)
    if not isinstance(data, list):
        raise ValueError(f"providers file must be a JSON array: {path}")

    providers: dict[str, dict[str, Any]] = {}
    for index, item in enumerate(data):
        if not isinstance(item, dict):
            raise ValueError(f"provider entry #{index + 1} must be an object: {path}")

        name = item.get("name")
        endpoint = item.get("endpoint")
        api_key = item.get("apiKey")
        models = item.get("models")

        if not isinstance(name, str) or not name:
            raise ValueError(f"provider entry #{index + 1} must have a non-empty string name")
        if name in providers:
            raise ValueError(f"duplicate provider name: {name}")
        if not isinstance(endpoint, str) or not endpoint:
            raise ValueError(f"provider {name} must have a non-empty string endpoint")
        if not isinstance(api_key, str) or not api_key:
            raise ValueError(f"provider {name} must have a non-empty string apiKey")
        if not isinstance(models, list) or not models:
            raise ValueError(f"provider {name} must have a non-empty models array")
        if any(not isinstance(model, str) or not model for model in models):
            raise ValueError(f"provider {name} models must be non-empty strings")
        if len(set(models)) != len(models):
            raise ValueError(f"provider {name} models must not contain duplicates")

        providers[name] = {
            "name": name,
            "endpoint": endpoint,
            "apiKey": api_key,
            "models": models,
        }

    return providers


def atomic_write_json(path: Path, data: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile("w", encoding="utf-8", dir=path.parent, delete=False) as tmp:
        json.dump(data, tmp, ensure_ascii=False, indent=2)
        tmp.write("\n")
        tmp_path = Path(tmp.name)
    os.chmod(tmp_path, 0o600)
    tmp_path.replace(path)


def command_claude(args: argparse.Namespace) -> int:
    provider = load_providers(providers_path()).get(args.provider)
    if provider is None:
        raise ValueError(f"unknown provider: {args.provider}")
    if args.model not in provider["models"]:
        raise ValueError(f"model is not configured for provider {args.provider}: {args.model}")

    settings = {
        "env": {
            "ANTHROPIC_AUTH_TOKEN": provider["apiKey"],
            "ANTHROPIC_BASE_URL": provider["endpoint"],
            "ANTHROPIC_DEFAULT_HAIKU_MODEL": args.model,
            "ANTHROPIC_DEFAULT_OPUS_MODEL": args.model,
            "ANTHROPIC_DEFAULT_SONNET_MODEL": args.model,
            "ANTHROPIC_MODEL": args.model,
        },
        "skipDangerousModePermissionPrompt": True,
    }
    target = Path.home() / ".claude" / "settings.json"
    atomic_write_json(target, settings)
    print(f"installed: {target}")
    return 0


def command_opencode(args: argparse.Namespace) -> int:
    provider = load_providers(providers_path()).get(args.provider)
    if provider is None:
        raise ValueError(f"unknown provider: {args.provider}")

    models = {
        model: KNOWN_OPENCODE_MODELS.get(model, {"name": model})
        for model in provider["models"]
    }
    config = {
        "$schema": "https://opencode.ai/config.json",
        "provider": {
            provider["name"]: {
                "npm": "@ai-sdk/anthropic",
                "name": "Alibaba Cloud Model Studio",
                "options": {
                    "baseURL": provider["endpoint"].rstrip("/") + "/v1",
                    "apiKey": provider["apiKey"],
                },
                "models": models,
            }
        },
    }
    target = Path.home() / ".config" / "opencode" / "opencode.json"
    atomic_write_json(target, config)
    print(f"installed: {target}")
    return 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Install AI provider config for local CLI tools.")
    subparsers = parser.add_subparsers(dest="command", required=True)

    claude_parser = subparsers.add_parser("claude", help="Install Claude Code settings")
    claude_parser.add_argument("provider", help="Provider name from ai-providers.json")
    claude_parser.add_argument("model", help="Model id from the provider models array")
    claude_parser.set_defaults(func=command_claude)

    opencode_parser = subparsers.add_parser("opencode", help="Install opencode config")
    opencode_parser.add_argument("provider", help="Provider name from ai-providers.json")
    opencode_parser.set_defaults(func=command_opencode)

    return parser.parse_args()


def main() -> int:
    try:
        args = parse_args()
        return args.func(args)
    except (OSError, json.JSONDecodeError, ValueError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
