#!/usr/bin/env python3
"""校验 code-report 里的相对代码链接：目标文件必须存在。

用法: validate.py <report.md>
检查普通链接 [text](path#L42) 和引用式定义 [text]: path，
跳过 http(s) 等外部链接和页内锚点。有缺失时逐条列出并退出码 1。
"""
import os
import re
import sys
from urllib.parse import unquote

INLINE_LINK = re.compile(r"\[[^\]]*\]\(([^)\s]+)(?:\s+\"[^\"]*\")?\)")
REF_DEF = re.compile(r"^\[[^\]]+\]:\s*(\S+)")


def main():
    if len(sys.argv) != 2:
        sys.exit("usage: validate.py <report.md>")
    report = sys.argv[1]
    base = os.path.dirname(os.path.abspath(report))
    missing = []
    with open(report, encoding="utf-8") as f:
        for lineno, line in enumerate(f, 1):
            targets = INLINE_LINK.findall(line)
            m = REF_DEF.match(line.strip())
            if m:
                targets.append(m.group(1))
            for target in targets:
                if "://" in target or target.startswith(("#", "mailto:")):
                    continue
                path = unquote(target.split("#", 1)[0])
                if path and not os.path.exists(os.path.join(base, path)):
                    missing.append((lineno, target))
    for lineno, target in missing:
        print(f"{report}:{lineno}: 目标不存在: {target}")
    if missing:
        sys.exit(1)
    print(f"OK: 全部链接目标存在 ({report})")


if __name__ == "__main__":
    main()
