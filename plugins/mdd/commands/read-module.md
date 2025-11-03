# Read Module Into Context

You will read an existing module into the AI context to understand its functionality and API.

## Task

Read and analyze the module: **$ARGUMENTS**

## Module Discovery

First, locate the module in the codebase:
- Search for directories or files matching the module name
- Look for README.md files that describe the module
- Check common module locations (e.g., /lib, /modules, /src/modules, /packages)
- If multiple matches are found, ask the user to clarify which module to read
- If the module cannot be found, ask the user for the module location

## What to Read

For the module, read in this order:

1. **README.md** - Start here to understand:
   - Module purpose and overview
   - API surface and key functions
   - Usage examples
   - Configuration options

2. **Interface/Export files** - Read the public API:
   - Main index file or entry point
   - Type definitions
   - Exported functions, classes, and constants

3. **Implementation files** - Read key implementation details:
   - Core functionality
   - Important algorithms or business logic
   - Dependencies on other modules

4. **Tests** - Review tests to understand:
   - Expected behavior
   - Edge cases
   - Usage patterns

## Summary

After reading the module, notify the user and wait for further instructions.

## Usage in Conversation

Once the module is read into context, you can:
- Answer questions about how the module works
- Suggest how to use the module for specific tasks
- Identify if this module can solve a problem the user is working on
- Help integrate this module with other code
- Edit the module
