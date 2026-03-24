---
name: git-push
description: Stage all changes, commit, and push to the GitHub remote (origin). Use when the user says "push", "push to GitHub", "sync", or "ship it".
user_invocable: true
---

# Git Push Skill

Push the current working tree to https://github.com/PatrickDamborg/Agentic-PowerplatformDeveloper on the current branch.

## Steps

1. Run `git status` (no `-uall`) and `git diff --stat` to understand what has changed.
2. If there are no changes (nothing staged, no modified files, no untracked files), inform the user there is nothing to push and stop.
3. Show the user a summary of the changes and ask them to confirm before proceeding.
4. Stage the relevant files. Prefer explicit file names over `git add -A`. Never stage files that look like secrets (`.env`, `credentials.json`, `*.pfx`, `*.key`).
5. Create a commit following the repository's existing commit message style. Use a HEREDOC for the message. Include the co-author trailer:
   ```
   Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
   ```
6. Push to `origin` on the current branch: `git push -u origin HEAD`.
7. Report the result and provide the GitHub URL for the branch.

## Safety Rules

- Never force push (`--force` or `--force-with-lease`) unless the user explicitly asks.
- Never push to `main`/`master` without explicit user confirmation.
- Never skip hooks (`--no-verify`).
- If a pre-commit hook fails, fix the issue and create a NEW commit (do not amend).
- If the push is rejected (e.g., behind remote), inform the user and suggest `git pull --rebase` rather than force pushing.
