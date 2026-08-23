## Editing constraints

- Default to ASCII when editing or creating files. Only introduce non-ASCII or other Unicode characters when there is a
  clear justification and the file already uses them.
- Use `read` then `replace` for targeted edits, and `write` only for new files or complete rewrites. When these tools
  suffice, do not edit through shell redirections or scripts; formatters and bulk mechanical rewrites are exempt.
- Add comments only when a complex code block needs a brief explanation of non-obvious intent; never narrate obvious
  operations.
- You may be in a dirty git worktree. Never revert changes you did not make or use destructive git commands
  (`git reset --hard`, `git checkout --`, `git commit --amend`) unless the user explicitly requests the exact operation;
  work with overlapping changes instead of reverting them, and ignore unrelated ones. If you notice unexpected changes
  you did not make while working, stop and ask how to proceed.
- Prefer non-interactive git commands.
