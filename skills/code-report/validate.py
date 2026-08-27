#!/usr/bin/env python3
"""校验 code-report 里的代码块引用。

用法: validate.py <report.md>
caption 形如 `path:start-end` 或 `path:line`（反引号包裹，位于块上方）。
带语言标注的 fenced block 缺 caption、或 caption 目标文件不存在/行号越界
时，逐条列出并退出码 1。
"""
import os
import re
import sys

CAPTION = re.compile(r"`([^`\s]+):(\d+)(?:-(\d+))?`")
FENCE = re.compile(r"^\s*(`{3,}|~{3,})\s*(\S*)")


def caption_above(lines, idx):
    for prev in reversed(lines[:idx]):
        if prev.strip():
            return CAPTION.search(prev)
    return None


def main():
    if len(sys.argv) != 2:
        sys.exit("usage: validate.py <report.md>")
    report = sys.argv[1]
    base = os.path.dirname(os.path.abspath(report))
    problems = []
    with open(report, encoding="utf-8") as f:
        lines = f.read().splitlines()

    in_block = False
    for i, line in enumerate(lines):
        fence = FENCE.match(line)
        if fence:
            if not in_block and fence.group(2) and not caption_above(lines, i):
                problems.append((i + 1, "代码块缺少 caption"))
            in_block = not in_block
            continue
        if in_block:
            continue
        for path, start, end in CAPTION.findall(line):
            if "://" in path:
                continue
            start, end = int(start), int(end or start)
            full = os.path.join(base, path)
            if not os.path.isfile(full):
                problems.append((i + 1, f"目标不存在: {path}"))
                continue
            with open(full, encoding="utf-8", errors="replace") as f:
                total = sum(1 for _ in f)
            if start > end or end > total:
                problems.append(
                    (i + 1, f"行号越界: {path}:{start}-{end} (文件共 {total} 行)")
                )

    for line_no, msg in problems:
        print(f"{report}:{line_no}: {msg}")
    if problems:
        sys.exit(1)
    print(f"OK: 全部代码块引用有效 ({report})")


if __name__ == "__main__":
    main()
