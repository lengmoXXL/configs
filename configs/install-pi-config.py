#!/usr/bin/env python3
"""Install Pi Agent provider config (~/.pi/agent/models.json + settings.json).

Usage:
  ./install-pi-config.py [settings] [provider] [alias]  # default: sync settings only
  ./install-pi-config.py models [provider]              # install models.json only
  ./install-pi-config.py all [provider] [alias]        # sync both
  ./install-pi-config.py theme [name]                  # install a Pi theme

Subcommand selects the sync target. `provider`/`alias` are optional and picked
interactively when omitted. `alias` is a key in models.json (the provider's
models object maps it to the provider-recognized model id that becomes the Pi
model `id` and defaultModel); it is not needed for the `models` target.

The `theme` subcommand copies a theme JSON from configs/pi/themes/ to
~/.pi/agent/themes/. `name` is optional and picked interactively when omitted.
"""

from __future__ import annotations

import argparse
import json
import shutil
import sys
from pathlib import Path
from typing import Any

import _ai_provider as ai

PI_ANTHROPIC_COMPAT = {
    "supportsEagerToolInputStreaming": False,
    "supportsLongCacheRetention": False,
    "supportsCacheControlOnTools": False,
}


def pi_model_config(model_id: str, entry: dict[str, Any]) -> dict[str, Any]:
    config: dict[str, Any] = {"id": model_id, "name": entry["name"]}
    inputs = ai.input_modalities(entry)
    if inputs is not None:
        config["input"] = inputs
    if entry.get("reasoning") is True:
        config["reasoning"] = True
    context_window = entry.get("contextWindow")
    if isinstance(context_window, int) and not isinstance(context_window, bool) and context_window > 0:
        config["contextWindow"] = context_window
    return config


def models_provider_entry(provider: dict[str, Any]) -> dict[str, Any]:
    catalog = ai.load_models_catalog(ai.models_catalog_path())
    return {
        "name": provider["name"],
        "baseUrl": provider["endpoint"].rstrip("/"),
        "api": "anthropic-messages",
        "apiKey": provider["apiKey"],
        "compat": PI_ANTHROPIC_COMPAT,
        "models": [
            pi_model_config(provider_id, ai.resolve_model(catalog, item_alias))
            for item_alias, provider_id in provider["models"].items()
        ],
    }


def install_models(provider: dict[str, Any]) -> int:
    target = Path.home() / ".pi" / "agent" / "models.json"
    models_config = ai.load_json_object(target)
    providers = models_config.get("providers")
    if providers is None:
        providers = {}
    if not isinstance(providers, dict):
        raise ValueError(f"Pi models providers must be an object: {target}")
    providers[provider["name"]] = models_provider_entry(provider)
    models_config["providers"] = providers
    ai.atomic_write_json(target, models_config)
    print(f"installed: {target}")
    return 0


def themes_source_dir() -> Path:
    return Path(__file__).resolve().parent / "pi" / "themes"


def list_themes() -> list[str]:
    source = themes_source_dir()
    if not source.is_dir():
        return []
    return sorted(
        p.stem for p in source.glob("*.json")
        if p.is_file() and not p.name.startswith(".")
    )


def install_theme(name: str) -> int:
    source = themes_source_dir() / f"{name}.json"
    if not source.is_file():
        raise ValueError(f"theme not found: {name}")

    target_dir = Path.home() / ".pi" / "agent" / "themes"
    target_dir.mkdir(parents=True, exist_ok=True)
    target = target_dir / f"{name}.json"

    shutil.copy2(source, target)
    print(f"installed: {target}")
    return 0


def install_settings(provider: dict[str, Any], alias: str) -> int:
    target = Path.home() / ".pi" / "agent" / "settings.json"
    settings = ai.load_json_object(target)
    settings["defaultProvider"] = provider["name"]
    settings["defaultModel"] = provider["models"][alias]
    ai.atomic_write_json(target, settings)
    print(f"installed: {target}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Install Pi Agent provider config.")
    sub = parser.add_subparsers(dest="target")

    settings_p = sub.add_parser("settings", help="Sync settings.json only (default)")
    settings_p.add_argument("provider", nargs="?", help="Provider name from ai-providers.json")
    settings_p.add_argument(
        "alias", nargs="?", help="Default model alias (key in models.json)"
    )

    models_p = sub.add_parser("models", help="Install models.json only")
    models_p.add_argument("provider", nargs="?", help="Provider name from ai-providers.json")

    all_p = sub.add_parser("all", help="Sync both settings.json and models.json")
    all_p.add_argument("provider", nargs="?", help="Provider name from ai-providers.json")
    all_p.add_argument(
        "alias", nargs="?", help="Default model alias (key in models.json)"
    )

    theme_p = sub.add_parser("theme", help="Install a Pi theme")
    theme_p.add_argument(
        "name", nargs="?", help="Theme name"
    )

    args = parser.parse_args()

    try:
        target = args.target or "settings"
        if target == "theme":
            themes = list_themes()
            if not themes:
                raise ValueError(f"no themes found in {themes_source_dir()}")
            name = args.name or ai.choose("theme", themes)
            return install_theme(name)

        providers = ai.load_providers(ai.providers_path())
        provider_name = getattr(args, "provider", None) or ai.choose("provider", list(providers))
        provider = providers.get(provider_name)
        if provider is None:
            raise ValueError(f"unknown provider: {provider_name}")

        if target == "models":
            return install_models(provider)

        alias = getattr(args, "alias", None) or ai.choose("model", list(provider["models"]))
        if alias not in provider["models"]:
            raise ValueError(
                f"model alias is not configured for provider {provider_name}: {alias}"
            )
        if target == "settings":
            return install_settings(provider, alias)
        install_models(provider)
        return install_settings(provider, alias)
    except (OSError, json.JSONDecodeError, ValueError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
