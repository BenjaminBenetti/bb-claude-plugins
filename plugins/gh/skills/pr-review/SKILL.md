---
name: pr-review
description: Review and interactively address PR comments. Use when the user wants to review PR feedback, go through PR comments, or address reviewer requests on a pull request.
argument-hint: "[pr-number]"
---

# PR Review - Interactive Comment Worklist

Review and address PR comments interactively. Comments are grouped by category and presented as a worklist that shrinks as you resolve each item.

## Arguments

`$ARGUMENTS` — Optional PR number or URL. If omitted, use the current branch's open PR.

## Step 1: Fetch PR Comments

Use `gh` to retrieve all review comments and issue comments on the PR.

```
gh pr view <pr> --json number,title,url,reviews,comments
gh api repos/{owner}/{repo}/pulls/{number}/comments
gh api repos/{owner}/{repo}/issues/{number}/comments
```

Collect every comment that represents feedback, a question, or a requested change. Ignore bot comments and CI status messages. Note which comments are part of a review thread vs standalone.

## Step 2: Categorize Comments

Group every comment into one of these categories (use your judgement — add or rename categories if the comments warrant it):

- **Code Changes Requested** — reviewer wants specific code modifications
- **Questions / Clarifications** — reviewer is asking a question or needs context
- **Nits / Style** — minor style, naming, or formatting suggestions
- **Architecture / Design** — higher-level design concerns
- **Documentation** — requests for docs, comments, or changelog updates
- **Positive Feedback** — praise, approvals, or acknowledgements (show these but mark as already resolved)

For each comment, capture:
- The reviewer's GitHub username
- The file and line (if it's an inline comment)
- A short summary of what they're asking for
- The `gh` API identifiers needed to reply or resolve it later

## Step 3: Present the Worklist

Print the categorized worklist in this format:

```
## PR #123 — "Add caching layer" — 12 comments

### Code Changes Requested (4)
 - [ ] @alice `src/cache.ts:42` — Use LRU eviction instead of FIFO
 - [ ] @bob `src/cache.ts:87` — Handle cache miss error case
 - [ ] @alice `src/index.ts:15` — Remove unused import
 - [ ] @bob `src/cache.ts:102` — Add TTL option to config

### Questions / Clarifications (2)
 - [ ] @carol `src/cache.ts:30` — Why not use Redis here?
 - [ ] @carol — (general comment) Whats the expected memory footprint?

### Nits / Style (1)
 - [ ] @alice `src/cache.ts:55` — Rename `d` to `data`

### Positive Feedback (1)
 - [x] @bob — Great test coverage!
```

## Step 4: Interactive Resolution Loop

Wait for the user to tell you what to do. They might say things like:

- "Fix the LRU eviction one" → make the code change, then reply to the comment on GitHub confirming the fix
- "Reply to Carol's Redis question saying we want to avoid the infra dependency" → post the reply via `gh api`
- "Dismiss the rename nit, I prefer short names in that scope" → reply explaining the reasoning
- "Do all the code changes" → batch fix them all

After completing each action:
1. Mark the addressed items as done `[x]`
2. Reprint the **remaining** worklist (omit fully-cleared categories)
3. If all items are resolved, print a summary and suggest the user re-request review

## Rules

- Always use `gh` CLI or `gh api` for GitHub interactions — never ask the user to go to the browser.
- When making code fixes, read the relevant file first to understand context before editing.
- When replying to comments, keep replies concise and professional.
- If a comment is ambiguous, ask the user what they'd like to do rather than guessing.
- Track the worklist state throughout the conversation — never lose track of which items remain.
