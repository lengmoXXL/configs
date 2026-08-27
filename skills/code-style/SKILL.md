---
name: code-style
description: Minimalist style review for code, scripts, configuration, and documentation. Use when asked to check code or doc style, review whether changes are necessary, enforce minimal implementation, or inspect changed files for unnecessary helpers, structure, control flow, comments, abstraction, compatibility logic, redundant sections, restated content, or unrequested documentation.
---

# Code Style

Use this skill to review code and documentation changes for necessity; docs
are reviewed as code. Every function, option, helper, abstraction, comment,
file, dependency, section, paragraph, and sentence must earn its place.

## Scope

Confirm the review range before checking.

- If the user names a range, use it: uncommitted changes, a base commit, a base
  branch, or one commit.
- If no range is named, review uncommitted changes.
- Use repository tools to inspect the exact diff before judging. Review the
  changes together with the parts they relate to: existing code or prose a
  change duplicates, calls, alters, restates, contradicts, or makes outdated.
- Apply every check to the full review range, including pre-existing code or
  prose in it, not only to lines a diff adds.

## Checks

### Minimal Implementation

For each part in the review range, decide whether it must exist and whether it can be part
of another existing entity instead. A small amount of duplication is acceptable;
flag helpers and abstractions that carry no meaningful abstraction of their own,
even when they have multiple call sites.

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

### Self-Explanatory Code Over Comments

Flag comments that restate what the code already says: narrating the
next line, translating a well-named identifier into prose, or labeling an
obvious block. Prefer renaming or restructuring the code so it explains itself.
A comment earns its place only when it says what code cannot: why a non-obvious
decision was made, a workaround for an external quirk, or an invisible
constraint.

#### Example: Narrating Comment

```go
// check whether the user exists
if _, ok := users[id]; !ok {
	return ErrUserNotFound
}
```

The comment duplicates the condition in prose. Delete it; the code already says
what it does. The same applies to doc comments that merely repeat the signature:

```go
// GetUserByID returns the user with the given ID.
func GetUserByID(id string) (*User, error) {
```

### Over-Defensive Guards

Flag checks that only protect against caller misuse or impossible
states when the surrounding contract should already guarantee the invariant.

#### Example: Go Nil Receiver Check

```go
func (s *Store) Save(ctx context.Context, item Item) error {
	if s == nil {
		return errors.New("nil store")
	}
	return s.db.Save(ctx, item)
}
```

If valid calls require a non-nil receiver, the caller should guarantee that
precondition. Prefer removing the guard:

```go
func (s *Store) Save(ctx context.Context, item Item) error {
	return s.db.Save(ctx, item)
}
```

### Fast Entropy Reduction

Structure each function so every step eliminates uncertainty as early as
possible. A necessary check should dispatch its failure branch immediately
(early return/throw), keeping the remaining path at the top indentation level.
Flag implementations that defer error handling or nest the happy path, forcing
the reader to hold unresolved branches in mind.

This applies only to checks that must exist; it never justifies adding new
guards (see Over-Defensive Guards).

#### Example: Deferred Error Branch

```go
func loadConfig(path string) (*Config, error) {
	data, err := os.ReadFile(path)
	if err == nil {
		var cfg Config
		if err := json.Unmarshal(data, &cfg); err == nil {
			return &cfg, nil
		} else {
			return nil, err
		}
	} else {
		return nil, err
	}
}
```

Every error branch is known at the check site but resolved later, and the
success path sinks two levels deep. Resolve each branch the moment it is known:

```go
func loadConfig(path string) (*Config, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	var cfg Config
	if err := json.Unmarshal(data, &cfg); err != nil {
		return nil, err
	}
	return &cfg, nil
}
```

### Compatibility Logic

Flag compatibility branches, fallbacks, shims, legacy paths, version
checks, platform checks, aliases, migrations, or tolerance for old formats
unless they are clearly part of the user's requested behavior.

Do not invent compatibility support from general caution, possible old data,
existing consumers, platform differences, dependency versions, or unknown
deployments. If the reviewed range contains compatibility logic, verify that the user asked
for that compatibility before accepting it.

#### Example: Unrequested Legacy Format

```go
if cfg.Endpoint == "" && cfg.LegacyURL != "" {
	cfg.Endpoint = cfg.LegacyURL
}
```

If the requested behavior only uses `Endpoint`, the legacy field support is
unnecessary unless the user asked to preserve old config files. Prefer removing
the compatibility path.

### Unrequested Documentation

Flag documentation in the reviewed range that the user did not request: doc
files, README sections, usage guides, or tutorial paragraphs.
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
