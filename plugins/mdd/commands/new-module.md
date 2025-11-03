# Create New Module

You will create a new module following Module Driven Development (MDD) principles.

## Task

Use the `module-developer` agent to create a new module named: **$ARGUMENTS**

The agent will:
1. Analyze the module requirements based on the name and any additional context
2. Design a clean interface for the module
3. Implement the module functionality
4. Create comprehensive documentation in README.md
5. Write tests for the module

## Module Requirements

If the module name alone doesn't provide enough context, ask the user:
- What should this module do?
- What is the expected input/output?
- Are there any specific requirements or constraints?
- Where should the module be located in the project?

## Expected Deliverables

The agent should create:
- Implementation code with a clean, exported interface
- Unit tests
- README.md with:
  - Overview section
  - Getting Started section with examples
  - API Reference section

Ensure the module follows the project's existing conventions and integrates well
with other modules in the codebase.
