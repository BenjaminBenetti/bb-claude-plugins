# Claude Code Plugins

A Claude Code Plugin Marketplace providing specialized development workflows, agents, and commands.

## Quick Start

Add this marketplace to Claude Code:

```bash
/plugin marketplace add BenjaminBenetti/bb-claude-plugins
```

Install plugins:

```bash
/plugin install generic-code@bb-claude-plugins
/plugin install plan@bb-claude-plugins
/plugin install taskmaster@bb-claude-plugins
```

## Available Plugins

- **generic-code** - Specialized agents for code review, architecture, research, and browser automation
- **plan** - Planning and session management commands (`/write`, `/run`, `/review-implementation`)
- **taskmaster** - Multi-agent orchestration for complex development tasks (`/run`)
- **github** - GitHub integration (minimal implementation)

See [plugins/README.md](plugins/README.md) for detailed documentation.

## Team Setup

Add to `.claude/settings.json` for automatic installation:

```json
{
  "extraKnownMarketplaces": [
    {
      "source": "github",
      "repo": "BenjaminBenetti/bb-claude-plugins"
    }
  ],
  "plugins": [
    "generic-code@bb-claude-plugins",
    "plan@bb-claude-plugins",
    "taskmaster@bb-claude-plugins"
  ]
}
```
