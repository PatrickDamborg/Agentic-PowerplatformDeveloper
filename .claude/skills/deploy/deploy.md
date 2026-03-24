---
name: deploy
description: Run the deploy script to stage, commit, and push all changes to GitHub (https://github.com/PatrickDamborg/Agentic-PowerplatformDeveloper). Use when the user says "deploy", "ship", "push changes", or "sync to GitHub".
user_invocable: true
---

# Deploy Skill

Runs `scripts/deploy.ps1` to deploy the current working tree to GitHub.

## Usage

When the user invokes `/deploy`, follow these steps:

1. Run `git status --short` and show the user what will be deployed.
2. Ask the user for a commit message (or offer to use a default timestamp-based one).
3. Confirm the target branch — default is the current branch. Warn if it is `main` or `master` and get explicit confirmation.
4. Run the deploy script:
   ```
   pwsh scripts/deploy.ps1 -CommitMessage "<message>" -Branch "<branch>"
   ```
   If `pwsh` is not available, fall back to `powershell.exe scripts/deploy.ps1`.
5. Report the result: commit SHA, branch, and GitHub URL.

## Safety

- Never deploy without showing the user the changes first.
- Never deploy to `main`/`master` without explicit confirmation.
- The script automatically skips secret files (`.env`, `.pfx`, `.key`, `credentials.json`, `.pem`).
- If the push fails, suggest `git pull --rebase` — never force push.
