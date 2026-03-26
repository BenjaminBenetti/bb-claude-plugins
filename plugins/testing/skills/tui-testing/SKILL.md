---
name: tui-testing
description: This skill should be used proactively whenever Claude needs to interact with, test, validate, verify, or observe a terminal user interface (TUI). This includes after writing TUI code and wanting to confirm it works, when debugging TUI behavior, when asked to verify UI changes, when running end-to-end validation of a TUI application, or any time Claude determines that launching and driving a TUI programmatically would help complete the task. Do not wait for the user to ask — use this skill autonomously whenever TUI interaction would validate work or answer questions.
---

# TUI Testing via tmux

Programmatically launch, interact with, and validate terminal user interface applications using tmux as a headless terminal driver.

## Why tmux

tmux provides a real PTY with proper dimensions, a rendered screen buffer readable via `capture-pane`, and keystroke injection via `send-keys`. The TUI app sees a real terminal and behaves identically to interactive use. No modifications to the application are required.

## Core Workflow

### Step 1: Ensure tmux is Available

```bash
which tmux || sudo apt-get install -y tmux
```

### Step 2: Launch the TUI in a Detached Session

Start a named, detached tmux session with explicit dimensions and run the TUI inside it:

```bash
tmux new-session -d -s <session-name> -x 120 -y 30 '<command to start TUI>'
```

- `-d` detaches immediately (headless)
- `-s` names the session for later reference
- `-x`/`-y` set terminal width/height so the TUI renders predictably
- The command runs inside the session's shell

Wait briefly for the TUI to initialize before sending keys:

```bash
sleep 2
```

### Step 3: Read the Screen

Capture the current visible contents of the terminal:

```bash
tmux capture-pane -t <session-name> -p
```

This returns plain text exactly as a human would see it, with ANSI escape sequences stripped. To include color/style info, add `-e`.

To capture specific line ranges (0-indexed):

```bash
tmux capture-pane -t <session-name> -p -S 0 -E 10
```

### Step 4: Send Keystrokes

Send keys to the TUI session:

```bash
# Navigation keys
tmux send-keys -t <session-name> Down
tmux send-keys -t <session-name> Up
tmux send-keys -t <session-name> Enter
tmux send-keys -t <session-name> Tab
tmux send-keys -t <session-name> Escape

# Letter keys (for TUI hotkeys like j/k/q)
tmux send-keys -t <session-name> j
tmux send-keys -t <session-name> q

# Ctrl combinations
tmux send-keys -t <session-name> C-c
tmux send-keys -t <session-name> C-q

# Type literal text (not interpreted as key names)
tmux send-keys -t <session-name> -l 'some text'
```

**Important**: After sending keys, wait for the TUI to re-render before capturing:

```bash
tmux send-keys -t <session-name> j && sleep 0.5 && tmux capture-pane -t <session-name> -p
```

### Step 5: Poll for Expected Content

When waiting for async operations (loading screens, background tasks):

```bash
for i in $(seq 1 30); do
  output=$(tmux capture-pane -t <session-name> -p)
  if echo "$output" | grep -q "expected text"; then
    echo "Found it"
    break
  fi
  sleep 0.5
done
```

### Step 6: Clean Up

```bash
tmux kill-session -t <session-name>
```

## Interaction Pattern

The general pattern for any TUI interaction is:

1. **Capture** the screen to understand current state
2. **Decide** which key to send based on what is displayed
3. **Send** the key
4. **Wait** briefly (0.3-1s) for re-render
5. **Capture** again to verify the result
6. **Repeat** until the goal is achieved

Always read the screen before and after actions. Do not blindly send sequences of keys without verifying intermediate state.

## Tips and Gotchas

- **Timing**: TUIs need time to render. Always sleep 0.3-1s between send and capture. For heavy operations (compilation, network), poll in a loop.
- **Key name collisions**: `tmux send-keys Enter` sends the Enter key. To type the literal word "Enter", use `tmux send-keys -l 'Enter'`.
- **Session naming**: Use unique session names to avoid collisions. Clean up sessions when done.
- **Terminal size matters**: Some TUIs render differently at different sizes. Match the expected terminal dimensions with `-x` and `-y`.
- **Nested tmux**: If the TUI itself uses tmux internally (e.g., opens a tmux session inside a container), the inner tmux session is independent. Target the outer session for TUI-level interaction, or use `docker exec` to interact with the inner session.
- **Alt screen**: Most TUIs (bubbletea, etc.) use the alternate screen buffer. `capture-pane` handles this correctly.
- **Resize**: Test different sizes with `tmux resize-window -t <session-name> -x <w> -y <h>`.
