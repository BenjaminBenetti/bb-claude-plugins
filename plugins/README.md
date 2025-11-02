# Claude Code Plugins

This directory contains specialized plugins that extend Claude Code's functionality for various development workflows. Plugins provide custom commands and specialized agents tailored for specific tasks in the software development lifecycle.

## What Are Plugins?

Plugins in Claude Code are modular extensions that provide:
- **Slash Commands**: Quick commands you can invoke with `/command-name` syntax
- **Specialized Agents**: Expert agents with focused capabilities and tool access
- **Custom Workflows**: Pre-configured processes for common development tasks

## Setup Guide

This repository serves as a **Claude Code Plugin Marketplace** hosted on GitHub. Users can add this marketplace to their Claude Code installation and install plugins directly.

### For Plugin Users

#### Step 1: Add This Marketplace to Claude Code

In Claude Code, run the following command to add this marketplace:

```bash
/plugin marketplace add awaremd/ai-sdlc
```

#### Step 2: Browse Available Plugins

View all plugins from this marketplace:

```bash
/plugin
```

This opens an interactive menu showing all available plugins with descriptions.

#### Step 3: Install Plugins

Install via the interactive menu or install a specific plugin from this marketplace:

```bash
/plugin install <plugin-name>@<marketplace-name>
```

**Example:**
```bash
/plugin install jira@awaremd
/plugin install taskmaster@awaremd
/plugin install generic-code@awaremd
```

After installation, restart Claude Code to use the new plugin.

#### Step 4: Manage Plugins

- **List marketplaces**: `/plugin marketplace list`
- **Enable plugin**: `/plugin enable <plugin-name>`
- **Disable plugin**: `/plugin disable <plugin-name>`
- **Uninstall plugin**: `/plugin uninstall <plugin-name>`

### For Team Deployment (Automatic Installation)

Teams can configure automatic plugin installation by adding marketplace and plugin specifications to `.claude/settings.json` in your project repository:

```json
{
  "extraKnownMarketplaces": [
    {
      "source": "github",
      "repo": "awaremd/ai-sdlc"
    }
  ],
  "plugins": [
    "jira@awaremd",
    "taskmaster@awaremd",
    "generic-code@awaremd"
  ]
}
```

When team members open the project and trust the folder, plugins install automatically.

### For Marketplace Maintainers

This repository includes a `.claude-plugin/marketplace.json` file at the repository root that configures it as a Claude Code marketplace.

#### Marketplace Configuration File

The existing `.claude-plugin/marketplace.json` is already configured with all available plugins. The structure follows this format:

```json
{
  "name": "awaremd",
  "owner": {
    "name": "AwareMd"
  },
  "plugins": [
    {
      "name": "generic-code",
      "source": "./ai-agents/claude/plugins/generic-code",
      "description": "Generic slash commands and agents for completing development related tasks"
    },
    {
      "name": "github",
      "source": "./ai-agents/claude/plugins/github",
      "description": "Plugin for interacting with GitHub"
    },
    {
      "name": "jira",
      "source": "./ai-agents/claude/plugins/jira",
      "description": "Slash commands for interacting with Jira."
    },
    {
      "name": "plan",
      "source": "./ai-agents/claude/plugins/plan",
      "description": "Slash commands and agents to help you plan and execute work."
    },
    {
      "name": "taskmaster",
      "source": "./ai-agents/claude/plugins/taskmaster",
      "description": "Taskmaster workflow plugin, use for multi stage multi agent coding tasks."
    }
  ]
}
```

**To add a new plugin to the marketplace**, add an entry to the `plugins` array with the required `name`, `source`, and optional `description`.

**Required Fields:**
- `name`: Kebab-case marketplace identifier
- `owner`: Maintainer information with `name` and `email`
- `plugins`: Array of plugin entries

**Plugin Entry Fields:**
- `name` (required): Plugin identifier
- `source` (required): Relative path to plugin directory or file
- `description` (optional): Brief plugin description
- `version` (optional): Plugin version
- `category` (optional): Plugin category for organization

**Plugin Source Options:**
- **Relative path**: `"./ai-agents/claude/plugins/jira"`
- **GitHub repo**: `{"source": "github", "repo": "owner/plugin-repo"}`
- **Git URL**: `{"source": "url", "url": "https://git-host.com/team/plugin.git"}`

#### Plugin Directory Structure

Each plugin must be structured correctly at the plugin root:

```
plugin-name/
├── plugin.json               # Plugin metadata (current structure)
├── .mcp.json                 # MCP server config (optional)
├── commands/                 # Slash commands (optional)
│   └── command-name.md
├── agents/                   # Custom agents (optional)
│   └── agent-name.md
├── skills/                   # Agent skills (optional)
└── hooks/                    # Event handlers (optional)
```

**Note:** This marketplace uses `plugin.json` at the root. The official Claude Code structure uses `.claude-plugin/plugin.json`, which is also supported.

### Using Plugin Commands

Plugin commands are invoked using slash syntax in Claude Code:

```bash
/command-name <arguments>
```

Example:
```bash
/new-ticket Create a bug for login timeout issue
```

### Using Plugin Agents

Specialized agents are invoked via the Task tool in Claude Code. Refer to individual agent files for specific usage instructions.

## Available Plugins

### jira

JIRA ticket integration and automation.

**Commands:**
- `/new-ticket` - Create new JIRA tickets with proper field configuration including team assignment, sprint selection, and status

**Key Features:**
- Automatically sets ticket type, status, sprint, and team
- Finds appropriate team IDs from existing tickets
- Adds tickets to current sprint based on assignee patterns

---

### plan

Planning and session management for development work.

**Commands:**
- `/write` - Create detailed implementation plans from request files (saved to `/plan/` directory)
- `/run` - Execute a previously created plan
- `/read-session` - Read current planning session state
- `/write-session` - Write/update planning session
- `/review-implementation` - Review implementation against original plan

**Key Features:**
- Research-driven planning (code analysis + web research)
- Step-by-step task lists with file modification details
- Session persistence for multi-stage planning

---

### taskmaster

Task coordination and sub-agent orchestration for complex work.

**Commands:**
- `/run` - Orchestrates multiple specialized sub-agents to complete complex tasks

**Key Features:**
- Delegates work to the most specialized agent for each task
- Runs multiple agents in parallel when possible
- Follows iterative workflow: research → architecture → implementation → review
- Enforces code reviews after any file changes
- Coordinates frontend and backend experts when needed

**Workflow:**
1. Identify the change
2. Assign research agent (for library/framework info)
3. Assign architect agent (for implementation planning)
4. Assign code expert agent(s) (for implementation)
5. Assign review agents (structure, maintainability)
6. Iterate until all issues resolved
7. Write unit tests if code changed

---

### generic-code

Collection of specialized code agents for development tasks.

**Agents:**

#### playwright-mcp-operator
Browser automation specialist using Playwright MCP.

**Capabilities:**
- Navigate websites and interact with elements
- Fill forms, click buttons, extract data
- Take screenshots and capture evidence
- Handle dynamic content and waits
- Verify UI state and content

**Model:** Haiku
**Use Case:** UI testing, web scraping, browser-based verification

---

#### feature-architect
Expert software architect specializing in Domain-Driven Design (DDD).

**Capabilities:**
- Analyze existing codebases and identify architectural patterns
- Design new features using DDD principles (bounded contexts, entities, value objects)
- Create detailed implementation plans specifying files to add/modify/remove
- Recommend directory structures following domain boundaries

**Model:** Opus
**Use Case:** Planning new features or significant functionality changes

---

#### research-specialist
Comprehensive research agent for libraries, frameworks, and packages.

**Capabilities:**
- Research software libraries across multiple ecosystems
- Analyze features, performance, compatibility, and security
- Compare alternatives with pros/cons
- Evaluate maintenance status and community health
- Provide integration patterns and best practices

**Model:** Default
**Use Case:** Library selection, technology evaluation, dependency research

---

#### code-structure-reviewer
Specialized reviewer focused on file organization and DDD structure.

**Capabilities:**
- Enforce "one class/interface/enum per file" rule
- Validate domain boundaries and bounded contexts
- Recommend directory structures following DDD patterns
- Ensure proper separation of domain logic and infrastructure

**Model:** Default
**Use Case:** Code organization review, structural refactoring

---

#### code-maintainability-reviewer
Senior architect expert in maintainability and design principles.

**Capabilities:**
- Analyze code readability and clarity
- Identify DRY violations and code duplication
- Evaluate SOLID principles (Single Responsibility, Open/Closed, etc.)
- Assess coupling, cohesion, and extensibility
- Provide actionable refactoring recommendations

**Model:** Default
**Use Case:** Code quality review, maintainability assessment

---

### github

GitHub integration for repository management.

**Status:** Plugin structure present, commands/agents to be implemented.

---

## Plugin Development

### Creating a New Plugin

1. **Create plugin directory**: `ai-agents/claude/plugins/{plugin-name}/`

2. **Create plugin metadata**: Add `plugin.json` in your plugin root directory:
```json
{
  "name": "plugin-name",
  "description": "Brief description",
  "version": "1.0.0",
  "author": {
    "name": "Your Name"
  }
}
```

**Note:** The official Claude Code plugin structure uses `.claude-plugin/plugin.json`, but this marketplace currently uses `plugin.json` at the plugin root for backward compatibility.

3. **Add plugin components** (all optional):
   - `commands/` - Slash command definitions (`.md` files)
   - `agents/` - Specialized agent definitions (`.md` files with frontmatter)
   - `skills/` - Agent skills (`.md` files)
   - `hooks/` - Event handlers

4. **Register in marketplace**: Add your plugin to `.claude-plugin/marketplace.json`:
```json
{
  "name": "your-plugin",
  "source": "./ai-agents/claude/plugins/your-plugin",
  "description": "What your plugin does"
}
```

**Important:** Component directories (commands/, agents/, skills/, hooks/) and `plugin.json` are all at the plugin root in this marketplace's current structure.

### Agent Frontmatter Format

Agents should include YAML frontmatter:

```yaml
---
name: agent-name
description: When to use this agent
tools: List, Of, Tools, Available
model: opus|sonnet|haiku
color: color-name
---
```

## Best Practices

### When to Use Plugins vs Core Workflows

- **Use Plugins** for:
  - Specialized, reusable commands
  - Expert agents with focused capabilities
  - Integration with external services (JIRA, GitHub)

- **Use Core SDLC Workflows** (`prompts/sdlc/`) for:
  - Complete ticket-to-implementation workflows
  - Multi-phase development processes
  - Structured testing and validation

### Plugin Command Naming

- Use clear, action-oriented names
- Keep names short and memorable
- Use hyphens for multi-word commands

### Agent Design

- Give agents focused, specific expertise
- Limit tool access to what's necessary
- Choose appropriate model based on task complexity:
  - **Opus**: Complex reasoning, architecture decisions
  - **Sonnet**: Balanced tasks, code implementation
  - **Haiku**: Simple, fast operations, browser automation

## Integration with MCP Servers

Plugins can leverage MCP (Model Context Protocol) servers:

- **Atlassian MCP**: JIRA ticket access (`jira` plugin)
- **Playwright MCP**: Browser automation (`playwright-mcp-operator` agent)
- **dbhub MCP**: Database access (configured in `.mcp.json`)

See `.mcp.json` files in plugin directories for specific configurations.

## Related Documentation

- [Main README](../../../README.md) - Overall framework documentation
- [SDLC Workflows](../../../prompts/sdlc/README.md) - Complete development workflows
- [CLAUDE.md](../../../CLAUDE.md) - Claude Code guidance for this repository
