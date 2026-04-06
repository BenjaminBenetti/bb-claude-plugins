---
name: gh:pr-dashboard
description: Show a dashboard of actionable PRs you've authored. Use when the user wants to see their open PRs, check PR status, review their PR pipeline, or find PRs that need attention.
argument-hint: "[org or org/repo]"
---

# PR Dashboard — Actionable PR Overview

Show all open PRs you've authored that need your attention, grouped by repo and status.

## Arguments

`$ARGUMENTS` — Optional org name or `org/repo` to filter results. If omitted, show PRs across all repos.

## Step 1: Fetch Open PRs

Search for all open PRs authored by the current user:

```
gh search prs --author=@me --state=open --limit 100 --json repository,number,title,url,updatedAt,isDraft
```

If `$ARGUMENTS` is provided:
- If it contains a `/` (e.g. `acme/api`), add `--repo=<value>`
- Otherwise treat it as an org and add `--owner=<value>`

If no PRs are found, report that and stop.

## Step 2: Enrich with Status Details

For each PR, fetch detailed status:

```
gh pr view <number> -R <owner/repo> --json number,title,url,reviewDecision,statusCheckRollup,mergeable,isDraft,reviews
```

Classify each PR into one or more of these statuses based on the response:

- **Draft** — `isDraft` is `true`
- **Ready to Merge** — `reviewDecision` is `APPROVED`, all status checks pass, and `mergeable` is `MERGEABLE`
- **Changes Requested** — `reviewDecision` is `CHANGES_REQUESTED`, or there are unresolved review threads
- **Failing CI** — any item in `statusCheckRollup` has `conclusion` of `FAILURE`, `TIMED_OUT`, or `ACTION_REQUIRED`
- **Merge Conflicts** — `mergeable` is `CONFLICTING`

Assign each PR a **primary status** using this priority (highest first): Changes Requested > Failing CI > Merge Conflicts > Ready to Merge > Draft. If a PR has secondary issues, note them inline.

Skip PRs that don't match any of the five statuses above (e.g., still awaiting review with CI green and no conflicts).

## Step 3: Present the Dashboard

Print the dashboard grouped by repository, then by status category within each repo.

Format:

```
# PR Dashboard — 8 actionable PRs

## acme/api (3)

### Ready to Merge
 1. #201 — "feature/cache Add response caching" — approved by @alice, @bob — all checks passing

### Changes Requested
 2. #195 — "fix/auth-flow Fix token refresh race condition" — @carol requested changes (2 unresolved)

### Failing CI
 3. #210 — "chore/deps Bump dependencies" — 2 checks failing: `lint`, `test-integration`

## acme/web (3)

### Changes Requested
 4. #87 — "feature/dashboard Add analytics dashboard" — @dave requested changes (5 unresolved) — also has merge conflicts

### Merge Conflicts
 5. #82 — "fix/nav Fix mobile nav overflow" — needs rebase

### Draft
 6. #91 — "feature/settings User settings page" — draft
```

Only show status categories that have PRs in them. Omit empty categories.

## Rules

- Use `gh` CLI for all GitHub interactions.
- Skip PRs that have no actionable status (e.g., review pending with no issues, CI still running with no failures).
- If a PR has multiple issues, show it once under the highest-priority status and note secondary issues inline.
- Status priority order: Changes Requested > Failing CI > Merge Conflicts > Ready to Merge > Draft.
- Keep the output scannable — one line per PR, no extra detail.
- If API rate limits are hit, warn the user and show partial results.
- Do not prompt for follow-up actions. Just present the dashboard and stop.
