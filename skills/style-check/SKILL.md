---
name: style-check
description: Minimalist style review for code, documentation, configuration, scripts, and other text artifacts. Use when asked to check style, review whether changes are necessary, enforce minimal implementation, or inspect changed files for unnecessary helpers, structure, wording, abstraction, or documentation.
---

# Style Check

Use this skill to review changes for necessity. Treat code and documents the same way: every function, paragraph, option, helper, abstraction, comment, file, and dependency must earn its place.

## Scope

Confirm the review range before checking.

- If the user names a range, use it: uncommitted changes, a base commit, a base branch, or one commit.
- If no range is named, review uncommitted changes.
- Use repository tools to inspect the exact diff before judging.

## Checks

### Minimal Implementation

For each changed part, decide whether it must exist and whether it can be part of another existing entity instead.

#### Example: Single-Use Helper

```go
func putIfMissing(values map[string]string, key string, value string) {
	if _, ok := values[key]; !ok {
		values[key] = value
	}
}

putIfMissing(values, key, value)
```

This helper is usually unnecessary when it has one local call site. Inline it:

```go
if _, ok := values[key]; !ok {
	values[key] = value
}
```

## Output

Report findings only. If there are none, say so.

Use this format for each finding:

```text
<file>:<line>
判断：<specific changed part> 不必要
原因：<why this changed part does not need to exist>
```

Keep reasons specific to the diff. Avoid general style essays.
