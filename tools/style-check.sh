#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    echo "Usage: style-check [prompt]"
    exit 0
fi

if ! command -v codex >/dev/null 2>&1; then
    echo "Error: codex is required" >&2
    exit 1
fi

repo_root="$(git rev-parse --show-toplevel)"
result_file="$(mktemp)"
trap 'rm -f "$result_file"' EXIT

cd "$repo_root"

if [[ "$#" -gt 0 ]]; then
    review_request="$*"
else
    review_request="Review the current uncommitted changes. Report findings only. If there are none, say so."
fi

{
    printf '%s\n\n' '$style-check'
    printf 'Do not modify files. Do not run shell commands. Inspect only the provided repository snapshot and return the review result.\n\n'
    printf 'Review contract: this wrapper must invoke Codex with model_reasoning_effort="xhigh".\n\n'
    printf '%s\n\n' "$review_request"
    printf 'Repository: %s\n\n' "$repo_root"
    printf '```text\n'
    echo "## git status --short"
    git status --short

    echo
    echo "## git diff --cached"
    git diff --no-ext-diff --cached

    echo
    echo "## git diff"
    git diff --no-ext-diff

    echo
    echo "## untracked files"
    while IFS= read -r -d '' path; do
        echo
        echo "### ${path}"
        git diff --no-ext-diff --no-index -- /dev/null "$path" || true
    done < <(git ls-files --others --exclude-standard -z)

    printf '\n```\n'
} | codex --ask-for-approval never exec \
        -c 'model_reasoning_effort="xhigh"' \
        --ephemeral \
        --output-last-message "$result_file" \
        - >/dev/null

cat "$result_file"
