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

### Over-Defensive Guards

Flag newly added checks that only protect against caller misuse or impossible states when the surrounding contract should already guarantee the invariant.

#### Example: Go Nil Receiver Check

```go
func (s *Store) Save(ctx context.Context, item Item) error {
	if s == nil {
		return errors.New("nil store")
	}
	return s.db.Save(ctx, item)
}
```

If valid calls require a non-nil receiver, the caller should guarantee that precondition. Prefer removing the guard:

```go
func (s *Store) Save(ctx context.Context, item Item) error {
	return s.db.Save(ctx, item)
}
```

### Compatibility Logic

Flag newly added compatibility branches, fallbacks, shims, legacy paths, version checks, platform checks, aliases, migrations, or tolerance for old formats unless they are clearly part of the user's requested behavior.

Do not invent compatibility support from general caution, possible old data, existing consumers, platform differences, dependency versions, or unknown deployments. If the diff adds compatibility logic, verify that the user asked for that compatibility before accepting it.

#### Example: Unrequested Legacy Format

```go
if cfg.Endpoint == "" && cfg.LegacyURL != "" {
	cfg.Endpoint = cfg.LegacyURL
}
```

If the requested behavior only uses `Endpoint`, the legacy field support is unnecessary unless the user asked to preserve old config files. Prefer removing the compatibility path.

## Output

Report findings only. If there are none, say so.

Use this format for each finding:

```text
<file>:<line>
判断：<specific changed part> 不必要
原因：<why this changed part does not need to exist>
```

Keep reasons specific to the diff. Avoid general style essays.
