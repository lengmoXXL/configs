---
name: doc-style
description: Minimalist style review for documentation, markdown, and prose. Use when asked to check documentation style, review whether doc changes are necessary, or inspect changed markdown files for redundant sections, restated content, or unrequested documentation.
---

# Doc Style

Use this skill to review documentation changes for necessity. Every section,
paragraph, and sentence must earn its place.

## Scope

Confirm the review range before checking.

- If the user names a range, use it: uncommitted changes, a base commit, a base
  branch, or one commit.
- If no range is named, review uncommitted changes.
- Use repository tools to inspect the exact diff before judging. Review the
  changes together with the parts they relate to: existing prose a change
  restates, contradicts, or makes outdated.

## Checks

### One Intent Per Paragraph

Every paragraph has exactly one primary intent. State that intent and stop;
anything beyond it is excess. The reverse also holds: each intent is primarily
described in at most one place. Flag content beyond the intent (delete it),
paragraphs that mix two intents (split them), and one intent described primarily
in multiple places (merge them). Typical excess: restating what the code, the
UI, or an adjacent sentence already says, and pointers the reader did not ask
for.

#### Example: Restating the Code

```markdown
## install.sh

This script installs the tool. Run it to install the tool.
```

The heading already says what the file is; the sentences add nothing. Delete
them, or replace them with information the reader cannot see: prerequisites,
side effects, or non-obvious options.

### Unrequested Documentation

Flag newly added documentation the user did not request: doc files, README
sections, usage guides, or tutorial paragraphs added alongside a code change.
Documentation is a change like any other; do not invent it from general caution.

## Output

Report findings only. If there are none, say so.

Use this format for each finding:

```text
<file>:<line>
判断：<specific part> 不必要
原因：<why this part does not need to exist>
```

Keep reasons specific to the reviewed range. Avoid general style essays.
