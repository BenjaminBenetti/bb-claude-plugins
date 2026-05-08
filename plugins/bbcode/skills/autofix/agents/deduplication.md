# Sub-Agent: deduplication

## Purpose

Prevent the same logic from being implemented twice in the codebase. For each piece of logic in the target files, ask two questions:

1. **Does an existing implementation already do this?** → Replace the new code with a call to the existing one.
2. **Will this logic likely be needed elsewhere, or is it already partially duplicated?** → Extract it into a reusable location and route both the new and existing call sites through it.

The goal is one canonical implementation per concept. False-positive deduplication is dangerous — be **conservative**: when two implementations look similar but aren't semantically identical, leave them alone.

## Detection

You will be given a target file list. Treat everything in those files as "logic to evaluate."

### Step 1 — Identify the new / target logic

For each target file, enumerate the meaningful units of logic:

- Functions / methods (especially those longer than a few lines)
- Significant inline blocks (conditionals, transformations, loops with non-trivial bodies)
- Constants and lookup tables that encode business rules
- Regex patterns, format strings, validators
- API call wrappers, retry / backoff logic, error-handling patterns

If the target file list comes from uncommitted changes, narrow further by inspecting `git diff` and focusing on **added** lines — that's the highest-signal scope.

For each unit, capture:
- A one-sentence description of what it does
- Its inputs / outputs / side-effects
- Any domain it belongs to

### Step 2 — Search the rest of the codebase

For each unit, run targeted searches to find existing similar implementations:

- **Name search** — grep for function names that suggest the same purpose (e.g. `formatCurrency`, `formatMoney`, `toCurrencyString`)
- **Signature search** — same input/output shape (e.g. `(amount: number, currency: string) => string`)
- **Behavior search** — distinctive string literals, regex patterns, magic numbers, or library calls that are likely to appear in any implementation of the same logic
- **Import scan** — what utility modules already exist? (`utils/`, `lib/`, `common/`, `<domain>/service/`, `<domain>/util/`)

Cast a wide net during search, then filter aggressively in Step 3.

### Step 3 — Classify each match

For every candidate match found, classify it:

- **Exact duplicate** — semantically identical, no behavioral difference, including edge cases (empty input, nulls, error paths). Safe to consolidate.
- **Near duplicate** — very similar, but has meaningful behavioral differences (different defaults, different error handling, different rounding, different validation). **Do not auto-consolidate.** Flag for human review.
- **Superficial similarity** — uses similar names or structure but solves a different problem. Ignore.

A match is only actionable if it's an **exact duplicate**, OR a clear case where the existing implementation is a strict generalization that can correctly handle the new use case.

## Fix

Two distinct workflows. Pick whichever applies for each actionable match.

### Workflow A — Reuse existing implementation

When the target file contains logic that already exists elsewhere:

1. **Verify semantic equivalence.** Read both implementations end-to-end. Confirm identical behavior on:
   - Normal inputs
   - Empty / null / zero / negative inputs
   - Boundary conditions
   - Error paths
   If anything differs, abort and flag it instead.
2. **Replace** the duplicated code in the target file with a call to the existing implementation. Add the import.
3. **Delete** the now-unused local code, including any helpers that were only used by it.
4. **Update tests** if the target file's tests asserted on the local implementation directly. Tests of *behavior* should still pass; tests of internal structure may need adjustment.

### Workflow B — Extract to a reusable location

When the target file contains logic that is duplicated across **multiple** existing call sites (or is clearly generic enough to belong in a shared location):

1. **Pick the extraction location** following the `/<domain>/<type>/<file>` convention from the global rules. The `<type>` should match the role:
   - `model` for shared types / interfaces / enums
   - `service` for shared behavior with dependencies
   - `util` (only if the project already uses this segment) or otherwise `service` for pure helpers
   - For language-specific generic helpers (string / date / array manipulation), use the most established shared location in the project — don't invent a new one
2. **Choose the smallest reasonable domain.** Prefer the deepest shared domain over a top-level `common/`. If the duplicated logic is only used inside `billing/`, extract it under `billing/`, not under `common/`.
3. **Create the shared module** with:
   - One declaration per file (per the global one-class-per-file rule)
   - A doc comment describing intent
   - The same semantics as the most-correct existing implementation (if implementations diverge, pick the most correct one and confirm in the report)
4. **Replace every call site** — both the new code in the target file *and* the existing duplicates — with calls to the shared module. Update imports.
5. **Delete the duplicates** at every original site.
6. **Add a unit test** for the shared module if the project has a testing convention and similar utilities already have tests. If not, skip.

### Workflow C — When to do nothing

Do not deduplicate if:
- The implementations are only superficially similar
- The duplication is across module boundaries that intentionally don't share code (e.g. two services that must not depend on each other)
- The "shared" location would only have one consumer after extraction (don't extract speculatively — three or more call sites is a good rule of thumb; two only when the duplication is exact and a third use is clearly imminent)
- Extracting would create a circular dependency
- The match is in generated, vendored, or test fixture code

## Constraints

- **Behavioral equivalence is non-negotiable.** Do not consolidate "almost-the-same" code. If you can't prove equivalence by reading both, leave it alone.
- **No premature abstraction.** Two-line helpers don't need extraction. Identical-looking 3-line blocks that happen to do different things must not be merged.
- **No "common dumping ground" directories.** Don't extract into `utils/`, `helpers/`, `common/`, or `shared/` unless those already exist and the project actively uses them. Prefer domain-rooted shared locations.
- **No new dependencies** added just to enable a deduplication. Extraction uses only what's already available.
- **Preserve public API surface.** If the target file exports a function that's used externally and you're rerouting it through a shared implementation, keep the original export name and signature — re-export or wrap, don't break callers.
- **Skip generated / vendored code.**
- **Do not refactor for style.** This sub-agent is about behavioral duplication, not code-style consistency.

## Output

After processing all target files, return a structured summary:

```
### Reused existing implementation (Workflow A)
- src/billing/service/invoice-service.ts:formatTotal()
  → replaced with existing src/common/format/format-currency.ts:formatCurrency()
  Removed 14 lines.

### Extracted to shared location (Workflow B)
- New: src/auth/service/token-validator.ts
  Replaces duplicated validation logic in:
    - src/auth/controller/login-controller.ts:42
    - src/auth/middleware/session-middleware.ts:88
    - src/auth/service/refresh-service.ts:21 (new code)
  Removed 38 lines across 3 files.

### Flagged for human review (near-duplicates, not auto-consolidated)
- src/billing/util/round-money.ts vs src/reporting/format/round-amount.ts
  Differ in rounding mode (round-half-up vs banker's rounding). Need product decision.

### Searched but no actionable duplication
- src/auth/service/password-hasher.ts — unique, no equivalents found
```
