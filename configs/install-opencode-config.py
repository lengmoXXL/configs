#!/usr/bin/env python3
"""Install opencode provider config (~/.config/opencode/opencode.json).

Usage:
  ./install-opencode-config.py [provider]    # provider optional; interactive if omitted
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

import _ai_provider as ai

THINKING_OPTIONS = {
    "thinking": {
        "type": "enabled",
        "budgetTokens": 8192,
    }
}


def opencode_model_config(entry: dict[str, Any]) -> dict[str, Any]:
    config: dict[str, Any] = {"name": entry["name"]}
    inputs = ai.input_modalities(entry)
    if inputs is not None:
        config["modalities"] = {"input": inputs, "output": ["text"]}
    if entry.get("reasoning") is True:
        config["options"] = THINKING_OPTIONS
    return config


def install_opencode(provider: dict[str, Any]) -> int:
    catalog_path = ai.models_catalog_path()
    catalog = ai.load_models_catalog(catalog_path)

    models: dict[str, dict[str, Any]] = {}
    for alias, provider_id in provider["models"].items():
        entry = ai.resolve_model(catalog, alias, catalog_path)
        models[provider_id] = opencode_model_config(entry)

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
    ai.atomic_write_json(target, config)
    print(f"installed: {target}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Install opencode provider config.")
    parser.add_argument("provider", nargs="?", help="Provider name from ai-providers.json")
    args = parser.parse_args()

    try:
        providers = ai.load_providers(ai.providers_path())
        provider_name = args.provider or ai.choose("provider", list(providers))
        provider = providers.get(provider_name)
        if provider is None:
            raise ValueError(f"unknown provider: {provider_name}")
        return install_opencode(provider)
    except (OSError, json.JSONDecodeError, ValueError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
