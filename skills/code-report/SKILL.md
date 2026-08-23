---
name: code-report
description: Analyze a codebase or module and produce a markdown report whose code references are clickable links. Use when asked to analyze code, explain a codebase, document a module, or generate a code analysis report with file/line links.
---

# Code Report

Produce a markdown report that explains code, where every claim links to the
exact code it describes.

## Scope

Confirm before writing:

- Range: whole repo, a module, or specific files.
- Audience and depth: onboarding overview vs. deep mechanism analysis.
- Output path and filename: no fixed convention; use the user's path if given,
  otherwise pick a name that fits the report topic.

## Process

1. Map the territory first: directory layout, entry points, build/config files.
   Then read the key files. Do not write from filenames or guesses.
2. Build the dependency and call relationships that matter for the chosen scope.
   Skip anything that does not serve the report's purpose.
3. Structure for the scope: overview → module/architecture breakdown → core
   flows → notable implementation details → risks or caveats. Drop sections
   that have nothing to say; do not pad.

## Link rules

Follow them strictly:

- Every claim about code cites it: `[src/server.ts:42](src/server.ts#L42)`.
  Ranges use `#L42-L58`.
- Link text always includes path and line, so readers know the location without
  clicking.
- Links are relative to the report file's location, so they work on GitHub and
  in standard markdown viewers.
- Read the file before citing it; line numbers must be exact at writing time.
- Line anchors drift when code changes — if the codebase is moving, note the
  commit or date in the report header.

## Output

- One markdown file: one-paragraph summary first, then the sections.
- Write the report in the user's language.
- Keep every line within 80 characters while writing; wrap prose manually
  instead of relying on post-formatting.
- After writing, run `dprint fmt <report>` to verify the wrapping. If it
  splits a link or inline code span across lines, shorten the link text or
  move long targets into reference-style definitions instead.
- Then run the bundled `validate.py <report>` (path relative to the skill
  directory) and fix any missing link targets it reports.
- When done, report the output path.
