---
name: bbcode:autofix
description: Autofix common code-quality issues by running a pipeline of focused sub-agents (one-class-per-file, etc.). Use when the user wants to clean up code smells, normalize file structure, or run autofix on a set of files.
argument-hint: "[files-or-glob | description of target]"
---

# Autofix — Run Common Code-Quality Fixers

Apply a pipeline of focused sub-agents to detect and fix common code-quality issues in a target set of files. Each sub-agent in `agents/` owns one specific issue class.

## Arguments

`$ARGUMENTS` — Optional. Either a list of files / globs, or a natural-language description of which files to target (e.g. `src/**/*.ts`, `the auth module`, `everything I changed since main`). If omitted, target all **uncommitted** files in the working tree.

## Step 1 — Determine Target Files

Two branches:

### Branch A: No argument

Inspect uncommitted files in the working tree:

```bash
git status --porcelain
```

Build the target list from:
- Modified files (`M`, ` M`)
- Added files (`A`, `??`)
- Renamed files (`R` — use the new path)

Skip:
- Deleted files
- Files outside the repo
- Anything matching `.gitignore` patterns the working tree happens to surface

### Branch B: Argument provided

Interpret `$ARGUMENTS` as the targeting instruction:
- If it looks like a file path or glob → expand it directly (use `git ls-files` or globbing)
- If it looks like a natural-language description → resolve it to a concrete file list (ask the user to confirm if ambiguous)


## Step 2 — Discover Sub-Agents

List every `*.md` file in `agents/` (relative to this skill). Each file is a sub-agent specification: its body is the prompt, its filename is its identifier.

Each sub-agent file follows this shape:
- A **Purpose** section — what issue it fixes
- A **Detection** section — how it identifies affected files
- A **Fix** section — what changes it makes
- A **Constraints** section — what it must not touch

## Step 3 — Run the Sub-Agent Loop

For each sub-agent file in `agents/`:

1. **Spawn** a sub-agent via the `Agent` tool with `subagent_type: "general-purpose"`.
2. **Prompt** it with:
   - The **full content of the sub-agent's `.md` file** as instructions
   - The **resolved target file list** from Step 1
   - An explicit instruction to apply changes directly (Edit/Write), not just report
3. **Wait** for the sub-agent to complete and capture its summary.
4. **Report** back to the user: which files the sub-agent touched and a one-line summary of changes.

Run sub-agents **sequentially**, not in parallel — later fixers may depend on the structure produced by earlier ones (e.g. once `single-class-per-file` has split a file, naming/import fixers can run on the result).

## Step 4 — Final Summary

After all sub-agents complete, print:

```
## Autofix Summary

Target: <N files>
Sub-agents run: <N>

### <sub-agent-name>
- Files touched: <list>
- Changes: <one-line summary>

### <sub-agent-name>
- ...

Run tests / typecheck before committing.
```

## Rules

- **Never commit** — autofix only edits the working tree. The user reviews and commits.
- **Never run destructive git commands** (reset, clean, checkout --) to "reset" between sub-agents. The pipeline is additive.
- If a sub-agent fails or reports it cannot safely fix something, surface that in the summary and continue with the next sub-agent — do not abort the whole pipeline.
- Always use repo-root-relative paths in reports.
- If the target file list is empty, say so and exit; do not invent files.
