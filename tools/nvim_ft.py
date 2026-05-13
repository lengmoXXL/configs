#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path


CONFIG_FILE_NAME = "filetypes.json"


def data_dir() -> Path:
    xdg_data_home = os.environ.get("XDG_DATA_HOME")
    if xdg_data_home:
        return Path(xdg_data_home).expanduser() / "nvim"
    return Path.home() / ".local" / "share" / "nvim"


def config_path() -> Path:
    return data_dir() / CONFIG_FILE_NAME


def git_root(start: Path) -> Path:
    current = start.expanduser().resolve()
    if current.is_file():
        current = current.parent
    result = subprocess.run(
        ["git", "-C", str(current), "rev-parse", "--show-toplevel"],
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        raise ValueError(f"not inside a git repository: {current}")
    return Path(result.stdout.strip()).resolve()


def git_url(project_root: Path) -> str:
    result = subprocess.run(
        ["git", "-C", str(project_root), "config", "--get", "remote.origin.url"],
        check=False,
        capture_output=True,
        text=True,
    )
    url = result.stdout.strip()
    if result.returncode != 0 or not url:
        raise ValueError(f"git remote.origin.url is not configured: {project_root}")
    return url


def project_root_from_args(args: argparse.Namespace, file_path: str | None = None) -> Path:
    if args.project:
        return git_root(Path(args.project))
    if file_path:
        path = Path(file_path).expanduser()
        if path.is_absolute():
            return git_root(path)
    return git_root(Path.cwd())


def load_config(path: Path) -> dict[str, dict[str, str]]:
    if not path.exists():
        return {}
    with path.open("r", encoding="utf-8") as fh:
        config = json.load(fh)
    if not isinstance(config, dict):
        raise ValueError(f"config must be a JSON object: {path}")
    projects = config.get("projects", config)
    if not isinstance(projects, dict):
        raise ValueError(f"config must map git URLs to filetype maps: {path}")
    normalized: dict[str, dict[str, str]] = {}
    for url, files in projects.items():
        if not isinstance(url, str) or not isinstance(files, dict):
            raise ValueError(f"config must map git URLs to filetype maps: {path}")
        normalized[url] = {}
        for file, filetype in files.items():
            if not isinstance(file, str) or not isinstance(filetype, str):
                raise ValueError(f"config entries must be string file-to-filetype pairs: {path}")
            normalized[url][file] = filetype
    return normalized


def save_config(path: Path, config: dict[str, dict[str, str]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(config, ensure_ascii=False, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def relative_file(project_root: Path, file_path: str) -> str:
    path = Path(file_path).expanduser()
    if path.is_absolute():
        candidates = [path.resolve()]
    else:
        candidates = []
        for candidate in ((Path.cwd() / path).resolve(), (project_root / path).resolve()):
            if candidate not in candidates:
                candidates.append(candidate)

    for candidate in candidates:
        try:
            return candidate.relative_to(project_root).as_posix()
        except ValueError:
            pass
    raise ValueError(f"file must be inside project root: {candidates[0]}")


def command_set(args: argparse.Namespace) -> int:
    project_root = project_root_from_args(args, args.file)
    url = git_url(project_root)
    path = config_path()
    config = load_config(path)
    rel_path = relative_file(project_root, args.file)
    config.setdefault(url, {})[rel_path] = args.filetype
    save_config(path, config)
    print(f"{url}: {rel_path} -> {args.filetype}")
    print(f"updated {path}")
    return 0


def command_unset(args: argparse.Namespace) -> int:
    project_root = project_root_from_args(args, args.file)
    url = git_url(project_root)
    path = config_path()
    config = load_config(path)
    rel_path = relative_file(project_root, args.file)
    files = config.get(url, {})
    removed = files.pop(rel_path, None)
    if not files:
        config.pop(url, None)
    save_config(path, config)
    if removed is None:
        print(f"no entry for {url}: {rel_path}")
    else:
        print(f"removed {url}: {rel_path}")
    return 0


def command_list(args: argparse.Namespace) -> int:
    project_root = project_root_from_args(args)
    url = git_url(project_root)
    config = load_config(config_path())
    files = config.get(url, {})
    if not files:
        print("no filetype entries")
        return 0
    print(url)
    for file, filetype in sorted(files.items()):
        print(f"{file} -> {filetype}")
    return 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Persist Neovim filetype overrides keyed by git remote URL.")
    parser.add_argument("--project", help="Project directory, default is nearest git root from cwd")

    subparsers = parser.add_subparsers(dest="command", required=True)

    set_parser = subparsers.add_parser("set", help="Set a filetype for a project file")
    set_parser.add_argument("file")
    set_parser.add_argument("filetype")
    set_parser.set_defaults(func=command_set)

    unset_parser = subparsers.add_parser("unset", help="Remove a filetype override for a project file")
    unset_parser.add_argument("file")
    unset_parser.set_defaults(func=command_unset)

    list_parser = subparsers.add_parser("list", help="List project filetype overrides")
    list_parser.set_defaults(func=command_list)

    return parser.parse_args()


def main() -> int:
    try:
        args = parse_args()
        return args.func(args)
    except ValueError as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
