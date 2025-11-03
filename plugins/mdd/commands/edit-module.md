# Edit Existing Module

You will edit an existing module following Module Driven Development (MDD) principles.

## Task

Use the `module-developer` agent to edit the module: **$ARGUMENTS**

The agent will:
1. Read the existing module's README.md to understand its current functionality
2. Read the implementation and interface code
3. Understand what needs to be changed
4. Update the module while maintaining backward compatibility (or document breaking changes)
5. Update tests to reflect changes
6. Update README.md documentation

## Module Discovery

First, locate the module in the codebase:
- Search for directories or files matching the module name
- Look for README.md files that describe the module
- If the module cannot be found, ask the user for the module location

## Expected Changes

Ask the user what changes are needed:
- What functionality should be added/removed/modified?
- Are breaking changes acceptable?
- Are there specific interface changes required?

## Backward Compatibility

When editing modules, prioritize backward compatibility:
- Maintain existing function signatures when possible
- Add new optional parameters instead of changing required ones
- Deprecate old APIs rather than removing them immediately
- Clearly document any breaking changes in README.md

## Expected Deliverables

The agent should update:
- Implementation code
- Interface/exports
- Unit tests (update existing, add new)
- README.md documentation to reflect all changes

Ensure the edited module maintains consistency with the project's conventions and
continues to integrate well with other modules.
