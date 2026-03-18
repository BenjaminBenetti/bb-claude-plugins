---
name: gh:pr-create
description: Create a pull request from the current branch. Use when the user wants to open a PR, create a pull request, or push their branch up for review.
argument-hint: "[base-branch]"
---

# PR Create — Smart Pull Request Creation

Create a well-titled, labeled pull request from the current branch.

## Arguments

`$ARGUMENTS` — Optional base branch (defaults to `main`).

## Step 1: Gather Context

Run these commands to understand what's being submitted:

```
git branch --show-current
git log main..HEAD --oneline
git diff main...HEAD --stat
git diff main...HEAD
```

Read the branch name, commit history, and full diff carefully. Understand what system components were modified and the nature of the changes.

## Step 2: Build the PR Title

The title **MUST** start with the branch name followed by a concise description of the changes.

Format: `<branch-name> <short description>`

Examples:
- `feature/auth-refresh Add token refresh flow with silent retry`
- `fix/null-cart Handle null cart edge case in checkout`
- `chore/deps-update Bump React to v19 and fix breaking changes`

Keep the description part under ~60 characters. Focus on what changed and why, not how.

## Step 3: Write the PR Body

Write a **Summary** section with 2-10 bullet points covering:
- What changed and why
- Any notable decisions or trade-offs
- Breaking changes or migration notes (if applicable)

Do NOT include a test plan section. Keep it concise — reviewers can read the diff.

## Step 4: Smart Labels

Determine labels based on the **system components** touched in the diff. Look at the directories and files modified to infer which part of the system is affected.

Common label patterns (adapt to the repo's actual structure):
- `frontend` — UI components, styles, client-side code
- `backend` — API routes, server logic, middleware
- `database` — Migrations, schema changes, queries
- `infra` — CI/CD, Docker, deployment configs, IaC
- `auth` — Authentication/authorization related
- `api` — API contracts, endpoints, OpenAPI specs
- `docs` — Documentation changes
- `config` — Configuration, env vars, feature flags
- `testing` — Test files, test utilities

Also add a **type** label:
- `feature` — New functionality
- `bugfix` — Bug fix
- `chore` — Maintenance, deps, refactoring
- `hotfix` — Urgent production fix

Before applying labels, check what labels actually exist on the repo:
```
gh label list
```

Only use labels that exist. If a good label doesn't exist, create it:
```
gh label create <name> --color <hex> --description "<description>"
```

## Step 5: Push and Create the PR

```
git push -u origin $(git branch --show-current)
```

Then create the PR:
```
gh pr create --title "<title>" --body "<body>" --label "<label1>,<label2>"
```

Print the PR URL when done.

## Rules

- The PR title MUST start with the branch name. No exceptions.
- Never include a test plan in the body.
- Always check existing repo labels before applying them.
- If there are uncommitted changes, warn the user and ask if they want to commit first — do not commit automatically.
- If the branch is already up to date with remote, skip the push.
- Use `gh` CLI for all GitHub interactions.
