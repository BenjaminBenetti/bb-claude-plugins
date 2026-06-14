---
name: bbcode:cosmos-workflow-01
description: End-to-end workflow for building out a ticket — write code, open a PR, watch it for CI, code review, and QA, then address feedback, push fixes, and converse with QA via /qa-manager comments. Use when the user wants to take a ticket through the full Cosmos PR review loop, drive a PR to green, or process reviewer/QA feedback on an open PR.
argument-hint: "[ticket id or description | PR number]"
---

# Cosmos Workflow 01 — Drive a Ticket Through the Full PR Review Loop

Take a ticket from code to a fully-approved PR by cycling through three review signals — **CI**, **code reviewer**, and **QA** — addressing everything they surface and pushing fixes. CI runs on every push, but **both reviewers are label-gated**: the **code reviewer** runs only when `ready-for-review` is present (set on open), and **QA** runs only when `ready-for-qa` is present (set after CI passes). You reach out to QA directly (a PR comment starting with `/qa-manager`) only when something needs clarifying.

This is a **loop**, not a one-shot. You repeat the watch → label → wait-for-QA → address → push cycle until CI is green, the code reviewer has approved, and QA has signed off. Because both reviewers are label-gated, each iteration you re-apply `ready-for-review` after pushing and `ready-for-qa` once CI goes green, so each reviewer re-runs against the latest commit.

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
- **Apply the `ready-for-review` label.** Like QA, the **code reviewer is gated on a label** — it won't run unless `ready-for-review` is present. Apply it on initial open so the reviewer picks up the PR. (Omit it only if you deliberately want to hold off the code reviewer, e.g. opening a draft you're not ready to have reviewed.)

```bash
git push -u origin $(git branch --show-current)
gh pr create --title "<title>" --body "<body>" --label "<component-labels>,ready-for-review"
```

Record the PR number and URL — you'll poll it in the next step.

## Step 4 — Watch for CI and Code Review

Poll the PR for two signals: **CI** (runs on every push) and the **code reviewer** (gated on the `ready-for-review` label — set on initial open in Step 3, and re-applied after each push in Step 8). QA is **not** in this step — it doesn't run until you set the `ready-for-qa` label (Step 5), so there's nothing to wait for yet.

The two signals here:

1. **CI** — status checks on the PR.
2. **Code reviewer** — the automated/assigned code-review feedback. If no review ever lands, confirm the `ready-for-review` label is present — without it the reviewer won't run.

Poll with:

```bash
gh pr view <number> --json number,state,reviewDecision,statusCheckRollup,reviews,comments,mergeable
gh pr checks <number>
```

Interpret each signal:

- **CI** — every item in `statusCheckRollup` has a terminal `conclusion`. Green = all `SUCCESS`/`NEUTRAL`/`SKIPPED`; otherwise note which checks failed (`FAILURE`, `TIMED_OUT`, `ACTION_REQUIRED`, `CANCELLED`).
- **Code reviewer** — a review has landed (`reviews` contains a verdict). `APPROVED`, `CHANGES_REQUESTED`, or `COMMENTED` with inline findings.

While either signal is still pending, keep polling on a sensible cadence rather than busy-waiting. If running under `/loop`, let it re-invoke you; otherwise sleep between polls. If a signal stalls for an unreasonable time, surface that to the user instead of blocking forever.

- If **CI is green**, continue to Step 5 to mark the PR ready for QA (even if the reviewer requested changes — you'll batch all feedback in Step 7).
- If **CI failed**, skip the label and jump to Step 7 to fix the failures, then push and re-watch.

## Step 5 — Mark the PR Ready for QA

Once **CI is fully green** — every item in `statusCheckRollup` has a terminal `SUCCESS`/`NEUTRAL`/`SKIPPED` conclusion — add the `ready-for-qa` label to the PR. **This is what triggers the QA pass**, so it must happen before you wait on QA:

```bash
gh pr edit <number> --add-label "ready-for-qa"
```

- Apply the label **only after all CI checks have passed** — never while any check is still running, failed, or required. The label signals that the change is build-clean and ready for the QA pass.
- On later loop iterations the label may already be present from a previous round. The label event is what triggers QA, so to kick off QA on the **new** commit, remove and re-add it:

  ```bash
  gh pr edit <number> --remove-label "ready-for-qa" --add-label "ready-for-qa"
  ```

- If CI is **not** green, do not add the label — go straight to Step 7 to address the failures, then push and re-watch. The label gets applied on a later iteration once CI passes.

## Step 6 — Wait for QA

Now that the `ready-for-qa` label has triggered the QA pass, poll until QA has reported:

```bash
gh pr view <number> --json number,state,reviews,comments,statusCheckRollup
```

- **QA** — QA has posted its result (a review or comment from the QA actor/bot, or a QA status check).

Keep polling on a sensible cadence while QA is pending. If QA stalls for an unreasonable time after the label was applied, surface that to the user rather than blocking forever.

**Once QA has reported, proceed to Step 7.** If everything is clean — CI green, reviewer approved, QA signed off — the loop is done: report success and stop.

## Step 7 — Address the Issues

Collect every actionable item across all three signals into one list, then work through it:

- **CI failures** — read the failing job logs (`gh run view <run-id> --log-failed`), reproduce locally if possible, and fix the root cause.
- **Code-reviewer findings** — apply the requested changes. If you disagree with a finding, note why (raise it on the PR) rather than silently ignoring it.
- **QA findings** — reproduce the reported behavior, fix it, and confirm the fix against the QA repro steps.

Group related fixes so the follow-up commits stay coherent. Don't paper over a failure just to make a check pass — fix the underlying problem.

## Step 8 — Push the Fixes

Commit the fixes with clear messages tying them to the feedback they resolve, and push:

```bash
git push
```

Pushing updates the PR and re-triggers CI. Neither reviewer runs on its own, though — both are label-gated:

- **Code reviewer** — re-apply `ready-for-review` so it re-reviews the new commit:

  ```bash
  gh pr edit <number> --remove-label "ready-for-review" --add-label "ready-for-review"
  ```

- **QA** — don't trigger it yet; it only kicks off when you re-apply `ready-for-qa` after CI goes green again (Step 5/6).

Then go back to watching CI and code review (Step 4).

## Step 9 — Loop

Return to **Step 4** and watch CI and code review again. Once CI goes green, re-apply the `ready-for-qa` label (Step 5) and wait for QA (Step 6). Repeat the watch → address → push cycle until:

- CI is fully green,
- the code reviewer has approved, and
- QA has signed off.

Then report the final PR state and stop.

## Talking to QA (only when you need to clarify)

You do **not** talk to QA as part of the normal loop — QA re-runs when you re-apply the `ready-for-qa` label after CI passes (Step 5/6), so a pushed fix gets re-tested that way. Reach out only when you need a human-in-the-loop exchange that pushing code and re-labeling can't resolve:

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
- **Both reviewers are label-gated.** The code reviewer runs only with `ready-for-review` (apply on initial open, Step 3); QA runs only with `ready-for-qa` (apply after CI passes, Step 5). Without the label, that reviewer never runs.
- Re-apply `ready-for-review` (remove + add) after each push so the reviewer re-reviews the new commit.
- Add `ready-for-qa` **only after all CI checks have passed** — never before. Re-apply it (remove + add) each loop iteration once CI goes green to re-run QA on the latest commit.
- Collect feedback across CI, code review, and QA before addressing it, so follow-up commits stay coherent.
- Never commit ticket work or fixes directly to the default branch.
- Fix root causes, not symptoms — don't disable checks or skip tests to force green.
- Don't talk to QA just to ask for a re-test — re-applying the label after CI passes is what re-runs it.
- To message QA, post a PR comment whose body starts with `/qa-manager` (via `gh pr comment`) — it's a comment prefix, not a slash command. Use it only to clarify or push back, and only when pushing code won't resolve the question.
- If a fix is contentious, push back transparently with a `/qa-manager` PR comment rather than silently dropping the feedback.
- Use the `gh` CLI for all GitHub interactions.
- If a signal stalls indefinitely, surface it to the user rather than polling forever.
