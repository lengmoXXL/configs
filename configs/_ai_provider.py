"""Shared helpers for install-opencode-config / install-pi-config.

Loads .secrets/ai-providers.json (provider list with apiKey/endpoint) and
configs/agents/models.json (model parameter catalog). Provider `models`
maps an alias (key in models.json) to the provider-recognized model id.
"""

from __future__ import annotations

import json
import os
import tempfile
from pathlib import Path
from typing import Any


def _repo_root() -> Path:
    return Path(__file__).resolve().parents[1]


def providers_path() -> Path:
    secrets_dir = Path(os.environ.get("SECRETS_DIR", _repo_root() / ".secrets")).expanduser()
    return secrets_dir / "ai-providers.json"


def models_catalog_path() -> Path:
    return Path(
        os.environ.get("AI_MODELS_PATH", _repo_root() / "configs" / "agents" / "models.json")
    ).expanduser()


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
        if not isinstance(models, dict) or not models:
            raise ValueError(f"provider {name} must have a non-empty models object")
        if any(not isinstance(k, str) or not k for k in models):
            raise ValueError(f"provider {name} models keys must be non-empty strings")
        if any(not isinstance(v, str) or not v for v in models.values()):
            raise ValueError(f"provider {name} models values must be non-empty strings")
        if len(set(models.values())) != len(models):
            raise ValueError(
                f"provider {name} models values must not contain duplicate provider model ids"
            )

        providers[name] = {
            "name": name,
            "endpoint": endpoint,
            "apiKey": api_key,
            "models": models,
        }

    return providers


def load_models_catalog(path: Path) -> dict[str, dict[str, Any]]:
    if not path.exists():
        raise ValueError(f"missing models catalog: {path}")

    with path.open("r", encoding="utf-8") as fh:
        data = json.load(fh)
    if not isinstance(data, dict):
        raise ValueError(f"models catalog must be a JSON object: {path}")

    catalog: dict[str, dict[str, Any]] = {}
    for alias, entry in data.items():
        if not isinstance(alias, str) or not alias:
            raise ValueError(f"models catalog alias must be a non-empty string: {path}")
        if not isinstance(entry, dict):
            raise ValueError(f"models catalog entry for {alias} must be an object: {path}")
        name = entry.get("name")
        if not isinstance(name, str) or not name:
            raise ValueError(f"models catalog entry {alias} must have a non-empty string name: {path}")
        context_window = entry.get("contextWindow")
        if context_window is not None and (
            not isinstance(context_window, int) or isinstance(context_window, bool) or context_window <= 0
        ):
            raise ValueError(
                f"models catalog entry {alias} contextWindow must be a positive integer: {path}"
            )
        catalog[alias] = entry
    return catalog


def resolve_model(catalog: dict[str, dict[str, Any]], alias: str) -> dict[str, Any]:
    entry = catalog.get(alias)
    if entry is None:
        raise ValueError(f"model alias not found in catalog: {alias}")
    return entry


def load_json_object(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    with path.open("r", encoding="utf-8") as fh:
        data = json.load(fh)
    if not isinstance(data, dict):
        raise ValueError(f"JSON file must contain an object: {path}")
    return data


def atomic_write_json(path: Path, data: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile("w", encoding="utf-8", dir=path.parent, delete=False) as tmp:
        json.dump(data, tmp, ensure_ascii=False, indent=2)
        tmp.write("\n")
        tmp_path = Path(tmp.name)
    os.chmod(tmp_path, 0o600)
    tmp_path.replace(path)


def input_modalities(entry: dict[str, Any]) -> list[str] | None:
    inputs = entry.get("input")
    if isinstance(inputs, list) and all(isinstance(item, str) for item in inputs):
        return inputs
    return None


def choose(label: str, options: list[str]) -> str:
    print(label)
    for index, option in enumerate(options, start=1):
        print(f"  {index}. {option}")
    while True:
        answer = input(f"Select {label} [1]: ").strip()
        if not answer:
            return options[0]
        if answer.isdigit():
            index = int(answer)
            if 1 <= index <= len(options):
                return options[index - 1]
        if answer in options:
            return answer
        print("Invalid selection.")
