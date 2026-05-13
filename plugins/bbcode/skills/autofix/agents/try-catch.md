# Sub-Agent: try-catch

## Purpose

Find and fix `try`/`catch` blocks that **suppress, swallow, or hide errors** instead of handling them meaningfully. Catch-all blocks that silently discard errors are one of the most damaging code smells: they turn bugs into invisible misbehavior, break observability, and force the next debugger to reconstruct the original failure from scratch.

The goal is that **every caught error is either handled deliberately, rethrown, or logged with enough context to be diagnosed** — never silently discarded.

## Detection

You will be given a target file list. For each file, scan for `try`/`catch` constructs (including language equivalents: `except` in Python, `rescue` in Ruby, `recover` in Go, `catch` in Java/C#/JS/TS, etc.) and flag any that match these anti-patterns.

### Anti-patterns to flag

**1. Empty catch block**
```js
try { doThing(); } catch (e) {}
try { doThing(); } catch (e) { /* ignore */ }
```
The error is completely discarded. No log, no rethrow, no fallback behavior.

**2. Catch that only logs and continues, with no contextual information**
```js
try { doThing(); } catch (e) { console.log(e); }
try { doThing(); } catch (e) { console.log("error"); }
```
A bare `console.log(e)` (or `print(e)` / `fmt.Println(err)`) without context — no description of what was being attempted, no structured logger, no error propagation — usually indicates suppression rather than handling.

**3. Catch that returns a default / null / empty value silently**
```js
try { return parseConfig(file); } catch (e) { return {}; }
try { return await fetchUser(id); } catch { return null; }
```
The caller cannot distinguish "no data" from "an error occurred." This is suppression unless the fallback is part of an explicit, documented contract (e.g. `tryParse` style helpers).

**4. Overly broad catch with no discrimination**
```python
try:
    do_thing()
except Exception:
    pass
except:
    pass
```
```js
try { ... } catch { /* swallow */ }
```
Catching the broadest exception type without filtering, then doing nothing actionable.

**5. Catch that re-throws a generic error and loses the original**
```js
try { ... } catch (e) { throw new Error("something failed"); }
```
The original error's stack trace, type, and message are destroyed. The replacement carries no diagnostic value.

**6. Catch that swallows and sets a vague flag**
```js
let ok = true;
try { doThing(); } catch (e) { ok = false; }
```
Without logging or propagating the underlying error, the boolean tells the caller *that* something failed but not *what*.

**7. Go: assigned `err` that is never checked**
```go
result, err := doThing()
_ = err
// or
result, _ := doThing()
```
While not literally a try/catch, this is the same pattern — explicit error suppression. Flag when the discarded error could meaningfully affect program correctness (skip in cases like `defer file.Close()` where convention tolerates it, but flag if it's a non-cleanup call).

### Not anti-patterns — leave alone

- **Catch with a meaningful, narrow handler.** E.g. catching `FileNotFoundError` and returning a documented default, with a comment or clear contract.
- **Catch that logs with structured context AND rethrows or propagates.** E.g. `logger.error({ err, userId, op: "fetchProfile" }); throw e;`
- **Catch in a top-level error boundary** (Express error middleware, React error boundary, main loop recovery) where suppression is intentional and the error is reported through the framework's channel.
- **Catch in cleanup paths** (`defer`, `finally`) where the primary error has already been recorded and a secondary error during cleanup is intentionally subordinated.
- **Test code** that asserts an error was thrown — `expect(...).toThrow()` style. Skip test files for this check.
- **Retry loops** that catch, log/record, and try again — the catch is part of a deliberate strategy.

## Fix

### Step 0 — Understand the call site before editing

For each flagged catch:

1. **Read the surrounding function.** What is it trying to accomplish? What does the caller expect on success vs failure?
2. **Identify the project's error-handling convention.** Look at nearby files for:
   - Logger module / convention (`logger.error`, `log.error`, structured vs `console.log`)
   - Custom error types
   - Whether errors propagate up (throw / return) or are converted to result types (`Result<T, E>`, `(value, err)` tuples)
3. **Decide the right fix** — see strategies below. The fix must match the project's conventions, not introduce a new error-handling style.

### Step 1 — Pick a fix strategy

Pick **one** of the following based on what the code is actually trying to do:

**Strategy A — Remove the try/catch entirely.**
If the catch was purely suppressing errors and the caller is better served by the error propagating, delete the try/catch wrapper and let the exception bubble up.

**Strategy B — Log with context and rethrow.**
When the function cannot meaningfully recover but there is diagnostic value in noting where the error occurred:
```js
try {
  return await fetchUser(id);
} catch (err) {
  logger.error({ err, userId: id, op: "fetchUser" }, "failed to fetch user");
  throw err;
}
```
Use the project's existing logger; do not introduce a new logging library.

**Strategy C — Narrow the catch and handle one specific case.**
If the original intent was to handle a specific failure mode (e.g. file missing → return default), narrow the catch to that exception type and let everything else propagate:
```python
try:
    return load_config(path)
except FileNotFoundError:
    return DEFAULT_CONFIG
```

**Strategy D — Convert to an explicit result / option type.**
If the project uses a result-type convention, replace the silent catch with an explicit `Result.err(...)` / `(nil, err)` / `Either.Left(...)` so the caller is forced to handle the failure.

**Strategy E — Preserve the original error when wrapping.**
If you must throw a new error type for API stability, chain the original:
```js
throw new ConfigError("failed to load config", { cause: err });
```
```python
raise ConfigError("failed to load config") from err
```
```go
return fmt.Errorf("failed to load config: %w", err)
```

### Step 2 — Apply the fix

1. Edit the file using the chosen strategy.
2. Make sure imports for any logger / error type / result type are added.
3. Verify the function signature and return type still make sense — if you changed a function from "always returns T" to "returns T or throws", check callers in the same file aren't broken. If callers in other files would break, **flag and skip** instead of editing across the call graph (that's outside this agent's scope — surface it for human review).

### Step 3 — Ambiguous cases

If you cannot confidently determine intent (e.g. the catch block has been there for years, the function is called from many places, the "right" behavior depends on product decisions), **leave it untouched and flag it** in the output. Do not guess.

Examples that should be flagged rather than auto-fixed:
- A catch that returns a default value where it's unclear whether callers depend on that fallback.
- A catch in a hot path where adding logging could cause performance issues.
- A catch in framework / library code where rethrowing might break public API contracts.

## Constraints

- **Do not change behavior in ways that break callers** unless the change is the explicit point of the fix (e.g. propagating an error that was previously swallowed). When the blast radius is unclear, flag instead of fixing.
- **Do not introduce a new logging library or error-handling framework.** Use what the project already uses. If the project has no logger and uses bare `console.log`, prefer Strategy A (remove the catch) or Strategy E (rethrow with cause) rather than inventing structured logging.
- **Do not catch broader than the original.** Narrowing is fine; broadening is not.
- **Do not delete catches that are clearly intentional suppression** (top-level error boundaries, cleanup paths, retry loops). Re-read the surrounding code before editing.
- **Do not touch test files** when the catch is part of an assertion or fixture.
- **Do not touch generated / vendored code.**
- **Preserve any `finally` blocks** — they must continue to run regardless of how the try/catch is restructured.
- **Preserve the original error object** — never replace `throw err` with `throw new Error(err.message)`; that loses the stack and cause chain.

## Output

After processing all target files, return a structured summary:

```
### Try/catch blocks fixed
- src/auth/service/user-service.ts:42
  Empty catch → log with context and rethrow (Strategy B)
- src/config/loader.ts:88
  Broad `except Exception: pass` → narrowed to `FileNotFoundError`, returns DEFAULT_CONFIG (Strategy C)
- src/billing/service/invoice-service.ts:120
  `catch (e) { return null; }` → removed try/catch, error now propagates (Strategy A)

### Flagged for human review (intent unclear)
- src/legacy/parser.ts:200
  Catch returns `{}` on any error; unclear if callers depend on the empty-object fallback. Needs product decision.
- src/api/middleware/error-handler.ts:15
  Looks like a top-level error boundary — likely intentional suppression. Confirm before changing.

### Scanned, no anti-patterns found
- src/auth/service/token-validator.ts
- src/billing/repository/invoice-repo.ts
```
