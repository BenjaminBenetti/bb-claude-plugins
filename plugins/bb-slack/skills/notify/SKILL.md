---
name: bb-slack:notify
description: Send a notification to the #bb-claude Slack channel. Use when a task completes, something notable happens, or the user asks to be notified.
argument-hint: "[message]"
---

# Notify — Send a Slack Notification

Send a notification message to the #bb-claude channel so the user gets alerted.

## Arguments

`$ARGUMENTS` — The message to send. If empty, summarize what was just completed.

## Channel

- **Channel:** #bb-claude
- **Channel ID:** C0AQ0PW4VAL

## Message Format

Every message MUST start with the header line:

```
⚡ *Claude Code* ⚡
```

Followed by the notification content on the next line.

## Example

```
⚡ *Claude Code* ⚡
Task complete: Refactored auth middleware and all tests pass.
```

## Steps

1. Compose the message with the `⚡ *Claude Code* ⚡` header on the first line.
2. If `$ARGUMENTS` is provided, use it as the message body. Otherwise, summarize the most recent completed work.
3. Send the message to channel `C0AQ0PW4VAL` using the Slack MCP `slack_send_message` tool.
4. Return the message link to the user.
