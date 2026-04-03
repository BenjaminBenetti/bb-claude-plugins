# Global Instructions

## SOLID Principles

All code must follow SOLID principles:

- **Single Responsibility**: Every module, class, and function should have one reason to change.
- **Open/Closed**: Code should be open for extension but closed for modification. Favor composition and interfaces over editing existing implementations.
- **Liskov Substitution**: Subtypes must be substitutable for their base types without altering correctness.
- **Interface Segregation**: Prefer small, focused interfaces over large ones. No client should be forced to depend on methods it does not use.
- **Dependency Inversion**: Depend on abstractions, not concretions. High-level modules should not import from low-level modules; both should depend on interfaces.

When writing or modifying code, actively apply these principles. If a change would violate SOLID, refactor to preserve it.

## File Structure

Organize code using the pattern `/<domain>/<type>/<file>`:

- **domain**: The business domain or feature area (e.g., `user`, `auth`, `billing`, `fleet`)
- **type**: The kind of component (e.g., `service`, `model`, `controller`, `repository`, `handler`)
- **file**: Any descriptive name

Examples:
- `/user/service/user-service.ts`
- `/auth/model/user-identity-entity.ts`
- `/billing/repository/invoices.ts`

**Exception**: In languages that require all module/package files to live in the same folder (e.g., Go), skip the `<type>` level and use `/<domain>/<file>` instead.

When creating new files, always place them according to this structure. When refactoring, migrate misplaced files to match.

## Comments

All methods must have documentation comments using the language's standard format:

- **Java**: Javadoc (`/** ... */`)
- **JavaScript/TypeScript**: JSDoc (`/** ... */`)
- **Go**: Godoc (comment directly above the function)
- **Python**: Docstrings (`"""..."""`)
- **Rust**: Doc comments (`///`)
- **C#**: XML doc comments (`/// <summary>`)

When writing or modifying methods, always include or update the doc comment.

### Section Comments

Use section comments to visually separate logical regions of a class (e.g., public methods, private methods, getters/setters, constants, fields). Format:

```
// ===========================================
// Section Name
// ===========================================
```

Adapt the comment prefix to the language (`//`, `#`, etc.).
