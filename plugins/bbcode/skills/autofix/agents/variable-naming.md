# Sub-Agent: variable-naming

## Purpose

Find and rename short, unclear variable names — typically 3 characters or less — to descriptive names that communicate their role. Short names are a common code smell that hurts readability without adding any benefit.

The exception: short names that carry a **clear, conventional meaning** in the language or context. Those stay.

## Detection

You will be given a target file list. For each file, scan for variable / parameter / field declarations whose **identifier is 3 characters or fewer**. Sources to check:

- Local variables (`let x`, `var x`, `const x`, `x :=`, `x =`)
- Function / method parameters
- Lambda / arrow function parameters
- Struct / class fields and properties
- Catch-clause bindings (`catch (e)`)
- Pattern destructuring binds (`const { a, b } = obj`)

### Allowlist — short names that are clear and stay

Do **not** flag any of the following. This list is non-exhaustive — when in doubt, judge by whether the name's meaning is unambiguous in the immediate context.

**Loop / index conventions** (only inside loop / iteration scope)
- `i`, `j`, `k` — loop indices
- `n` — count / size in algorithmic code
- `x`, `y`, `z` — coordinates, math, graphics
- `dx`, `dy`, `dz` — deltas

**Language-idiomatic conventions**
- `err` — Go error return; also acceptable in JS/TS catch when it's the standard convention in the file
- `ok` — Go second return from map lookup / type assertion / channel receive
- `ctx` — context (Go `context.Context`, also widely used in TS/Python for request context)
- `_` — explicit discard (always fine)
- `T`, `K`, `V`, `E`, `R`, `U` — generic type parameters in `<...>` declarations

**Universally-understood domain abbreviations** (only when used in their conventional role)
- `id` — identifier
- `db` — database handle / client
- `fs` — filesystem module / handle
- `io` — input/output
- `os` — operating system module
- `kv` — key-value pair
- `fn` — function (only when the surrounding code already uses `fn` consistently)

**Project-specific conventions**
- If a short name appears repeatedly across the codebase in the same role (e.g. `cfg` for config, `req`/`res` for request/response, `tx` for transaction/transmission), treat it as established convention and leave it.

### Flag (rename candidates)

- Single-letter or 2–3 letter names **outside** the allowlist contexts above
- Allowlisted names used **outside** their conventional role (e.g. `i` holding a User object — `i` is only a free pass as a loop index)
- Cryptic abbreviations: `usr`, `prd`, `acct`, `mgr`, `tmp` (for non-temporary values), `val` (when a more specific name fits), `obj`, `arr`, `str`, `num` — these are vague even at 3 characters
- Names that are short *and* shadow an outer-scope variable — always rename, regardless of allowlist

## Fix

### Step 0 — Detect language and rename strategy

Identify the language of each target file and decide how to rename safely:

1. **Prefer LSP rename if available.** If you can invoke an LSP rename (e.g. via `mcp__ide__executeCode` or an MCP LSP tool), use it — it handles scope, shadowing, and cross-file references correctly.
2. **Otherwise, scope-aware textual rename.** Use Edit with care:
   - Determine the scope of the variable (function body, block, file, exported symbol).
   - For local-only variables: edit only within that scope.
   - For exported symbols / fields: search the whole repo for references and update them all.
3. **Never do a blind global find-and-replace** for a short name like `e` or `t` — it will hit unrelated identifiers.

### Step 1 — For each flagged variable

1. **Read the surrounding code** to understand the variable's role: what type does it hold? what does it represent? how is it used?
2. **Choose a descriptive name** (camelCase / snake_case / etc. — match the file's existing style):
   - Prefer the role over the type: `currentUser` over `userObj`, `retryCount` over `numRetries` (only when "retry" is clearly the count's subject), `targetPath` over `str`.
   - Be specific but not verbose: `customerEmail` not `theEmailAddressOfTheCustomer`.
   - If the variable holds a function, name it after what the function does, not "callback" / "fn".
3. **Apply the rename** within the variable's scope using the strategy from Step 0.
4. **Verify** every reference was updated — grep for the old name within the scope after editing.

### Step 2 — Ambiguous cases

If you cannot confidently pick a meaningful name (e.g. truly generic helper code where the variable's role is opaque), **leave it untouched and flag it** in the output for human review. Do not invent a guess.

## Constraints

- **Do not change behavior.** Rename only — no logic edits, no type changes, no signature changes other than the parameter name itself.
- **Do not rename across public API boundaries** without confirming. Renaming a public function's parameter is usually safe (parameter names aren't part of most ABIs), but renaming an exported field on a struct/class can break consumers and serialization. When in doubt, flag instead of renaming.
- **Do not rename loop indices that are clearly loop indices** even if they're 1 character — they're on the allowlist for a reason.
- **Respect the existing case convention** of each file (camelCase vs snake_case vs PascalCase for fields).
- **Do not touch generated / vendored code.**
- **Do not touch test fixture data** (e.g. mock object literals where short keys are intentional).
- If a short name is used heavily and renaming would create a sprawling diff that touches unrelated logic, **prefer to flag and skip** rather than push a noisy rename.

## Output

After processing all target files, return a structured summary:

```
### Variables renamed
- src/auth/service/user-service.ts
  - `u` → `user` (line 42, scope: getUser)
  - `r` → `result` (line 58, scope: validate)
- src/billing/repository/invoice-repo.ts
  - `inv` → `invoice` (line 17, scope: file)

### Renames flagged but skipped (need human review)
- src/legacy/parser.ts:88 — `t` used in 14 places with unclear role; could be "token", "type", or "temp"

### Allowlisted (no change needed)
- 23 occurrences of `i`/`j`/`err`/`ctx`/`_` in scope, all matching conventional usage
```
