---
name: bbcode:cosmos-workflow-01
description: End-to-end workflow for building out a ticket — write code, open a PR, watch it for CI, code review, and QA, then address feedback, push fixes, and converse with QA via /qa-manager comments. Use when the user wants to take a ticket through the full Cosmos PR review loop, drive a PR to green, or process reviewer/QA feedback on an open PR.
argument-hint: "[ticket id or description | PR number]"
---

# Cosmos Workflow 01 — Drive a Ticket Through the Full PR Review Loop

Take a ticket from code to a fully-approved PR by cycling through three review signals — **CI**, **code reviewer**, and **QA** — addressing everything they surface and pushing fixes. QA re-runs automatically on each push, so you only reach out to it directly (a PR comment starting with `/qa-manager`) when something needs clarifying.

This is a **loop**, not a one-shot. You repeat the watch → address → push cycle until CI is green, the code reviewer has approved, and QA has signed off. QA re-runs automatically on every commit, so pushing fixes is enough to get re-reviewed — you only talk to QA directly when you need to clarify something.

## Arguments

`$ARGUMENTS` — Optional. One of:
- A **ticket id or description** — start from scratch: write the code, then open the PR.
- A **PR number / URL** — an existing PR is already open; skip to the watch loop.
- **Omitted** — infer the target from the current branch and any open PR for it.

## Step 1 — Establish the Work

Determine where in the workflow you're starting:

```bash
git branch --show-current
gh pr view --json number,url,state 2>/dev/null
```

- If a PR already exists for this branch (or `$ARGUMENTS` names one), record its number and **go to Step 4**.
- Otherwise, you're starting from a ticket. Continue to Step 2.

## Step 2 — Work on the Code

Implement the ticket on a feature branch.

- If you're on `main` (or the repo's default branch), create a branch first — never commit ticket work to the default branch.
- Make focused commits as you go. Keep the working tree clean before opening the PR.
- Run the project's tests/build locally if it's cheap to do so — catching failures here is faster than waiting on CI.

## Step 3 — Open the PR

Open a pull request for the branch. Follow the repo's PR conventions (see the `gh:pr-create` skill if installed):

- Title starts with the branch name, followed by a concise description.
- Body has a short **Summary** of what changed and why. No test plan.
- Apply labels that match the system components touched (check `gh label list` first).

```bash
git push -u origin $(git branch --show-current)
gh pr create --title "<title>" --body "<body>" --label "<labels>"
```

Record the PR number and URL — you'll poll it in the next step.

## Step 4 — Watch the PR for All Three Signals

Poll the PR until **all three** review signals have reported. Do not act on a partial picture — wait until each signal has either finished or clearly stalled, then address everything together in one pass.

The three signals:

1. **CI** — status checks on the PR.
2. **Code reviewer** — the automated/assigned code-review feedback.
3. **QA** — the QA pass and any QA comments.

Poll with:

```bash
gh pr view <number> --json number,state,reviewDecision,statusCheckRollup,reviews,comments,mergeable
gh pr checks <number>
```

Interpret each signal:

- **CI** — every item in `statusCheckRollup` has a terminal `conclusion`. Green = all `SUCCESS`/`NEUTRAL`/`SKIPPED`; otherwise note which checks failed (`FAILURE`, `TIMED_OUT`, `ACTION_REQUIRED`, `CANCELLED`).
- **Code reviewer** — a review has landed (`reviews` contains a verdict). `APPROVED`, `CHANGES_REQUESTED`, or `COMMENTED` with inline findings.
- **QA** — QA has posted its result (a review or comment from the QA actor/bot, or a QA status check).

While any signal is still pending, keep polling on a sensible cadence rather than busy-waiting. If running under `/loop`, let it re-invoke you; otherwise sleep between polls. If a signal stalls for an unreasonable time, surface that to the user instead of blocking forever.

**Only proceed to Step 5 once all three signals have reported.** If everything is clean — CI green, reviewer approved, QA signed off — the loop is done: report success and stop.

## Step 5 — Address the Issues

Collect every actionable item across all three signals into one list, then work through it:

- **CI failures** — read the failing job logs (`gh run view <run-id> --log-failed`), reproduce locally if possible, and fix the root cause.
- **Code-reviewer findings** — apply the requested changes. If you disagree with a finding, note why (raise it on the PR) rather than silently ignoring it.
- **QA findings** — reproduce the reported behavior, fix it, and confirm the fix against the QA repro steps.

Group related fixes so the follow-up commits stay coherent. Don't paper over a failure just to make a check pass — fix the underlying problem.

## Step 6 — Push the Fixes

Commit the fixes with clear messages tying them to the feedback they resolve, and push:

```bash
git push
```

Pushing updates the PR, which re-triggers CI and re-requests code review. **QA also re-runs automatically on the new commit** — you don't need to ask it to re-test. Pushing the fix is enough; just go back to watching.

## Step 7 — Loop

Return to **Step 4** and watch again. Repeat the watch → address → push cycle until:

- CI is fully green,
- the code reviewer has approved, and
- QA has signed off.

Then report the final PR state and stop.

## Talking to QA (only when you need to clarify)

You do **not** talk to QA as part of the normal loop — QA re-triggers on every commit, so a pushed fix gets re-tested automatically. Reach out only when you need a human-in-the-loop exchange that pushing code can't resolve:

- A QA finding's repro steps are ambiguous and you can't reproduce it.
- You believe a finding is incorrect and want to push back (with reasoning).
- You need QA to confirm expected behavior before you can decide how to fix.

To reach QA, **post a comment on the PR whose body starts with `/qa-manager`** followed by your message. `/qa-manager` is not a slash command — it's a magic prefix on a normal PR comment that routes the message to QA:

```bash
gh pr comment <number> --body "/qa-manager <your message>"
```

Keep messages concise and actionable. If you're just fixing what QA reported, skip this entirely and let the next commit speak for itself.

## Rules

- It's a **loop** — never declare done after a single pass. Done means all three signals are simultaneously satisfied.
- **Wait for all three signals** before addressing issues. Acting on a partial picture wastes a CI/review cycle.
- Never commit ticket work or fixes directly to the default branch.
- Fix root causes, not symptoms — don't disable checks or skip tests to force green.
- QA re-runs automatically on every commit — don't talk to QA just to ask for a re-test; pushing the fix is enough.
- To message QA, post a PR comment whose body starts with `/qa-manager` (via `gh pr comment`) — it's a comment prefix, not a slash command. Use it only to clarify or push back, and only when pushing code won't resolve the question.
- If a fix is contentious, push back transparently with a `/qa-manager` PR comment rather than silently dropping the feedback.
- Use the `gh` CLI for all GitHub interactions.
- If a signal stalls indefinitely, surface it to the user rather than polling forever.
