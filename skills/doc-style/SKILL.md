---
name: doc-style
description: Minimalist style review for documentation, markdown, and prose. Use when asked to check documentation style, review whether doc changes are necessary, or inspect changed markdown files for redundant sections, restated content, unrequested documentation, or inconsistent wording.
---

# Doc Style

Use this skill to review documentation changes for necessity. Every section, paragraph, sentence, and example must earn
its place.

## Scope

Confirm the review range before checking.

- If the user names a range, use it: uncommitted changes, a base commit, a base branch, or one commit.
- If no range is named, review uncommitted changes.
- Use repository tools to inspect the exact diff before judging.

## Checks

### Minimal Documentation

Every paragraph serves one intent. State that intent and stop; anything beyond it is excess. Flag sentences that restate
what the reader already knows from the code, the UI, or an adjacent sentence, and pointers the reader did not ask for. A
short doc that says less is better than a long doc that says more than its intent.

#### Example: Restating the Code

```markdown
## install.sh

This script installs the tool. Run it to install the tool.
```

The heading already says what the file is; the sentences add nothing. Delete them, or replace them with information the
reader cannot see: prerequisites, side effects, or non-obvious options.

### Unrequested Documentation

Flag newly added doc files, README sections, usage guides, or tutorial paragraphs when the user only asked for a code
change. Documentation is a change like any other; do not invent it from general caution. If the diff adds docs, verify
that the user asked for documentation before accepting it.

### Examples Must Add Information

Flag examples whose output or behavior is already obvious from the surrounding text, the command name, or a previous
example. Keep an example only when it shows a non-obvious combination, an edge case, or output the reader cannot
predict.

### Consistent Wording and Structure

Flag terminology drift within the changed doc: the same concept named two ways, inconsistent capitalization of product
names, or mixed heading levels for parallel content. Keep flagging strict: only report inconsistencies introduced or
left behind by the diff, not pre-existing ones outside the review range.

## Output

Report findings only. If there are none, say so.

Use this format for each finding:

```text
<file>:<line>
判断：<specific changed part> 不必要
原因：<why this changed part does not need to exist>
```

Keep reasons specific to the diff. Avoid general style essays.
