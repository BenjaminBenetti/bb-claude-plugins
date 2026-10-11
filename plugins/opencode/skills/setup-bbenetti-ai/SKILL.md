---
name: setup-bbenetti-ai
description: Configure opencode on this machine (or container) to use Ben's self-hosted Strata LLM server on ai.bbenetti.ca (Qwen3.8-Flash-Next, OpenAI-compatible API, 256K context). Use when the user asks to set up, connect or point opencode at their AI server, Strata, ai.bbenetti.ca, or "the AI computer".
---

# Set up opencode for the bbenetti AI server

Point opencode at the Strata server on `ai.bbenetti.ca`. The bundled script `scripts/setup-opencode.sh` (relative to this skill's base directory) does all the work:

- checks the server is reachable and the API key is accepted, and writes nothing if either fails;
- saves the key to `~/.config/opencode/strata-api-key` (mode 600);
- writes `~/.config/opencode/opencode.json` with provider `strata` and two models: `strata/qwen3.8-flash-next` (default, thinking: medium) and `strata/qwen3.8-flash-next-fast` (no thinking, used for titles). An existing `opencode.json` is **replaced**, after a timestamped backup next to it.

It honours `XDG_CONFIG_HOME`, and needs only `sh` (plus `curl` for the reachability and key check).

## Steps

### 1. Check what is there

- `ls -la "${XDG_CONFIG_HOME:-$HOME/.config}/opencode/"`. If an `opencode.json` exists and holds anything beyond an earlier Strata setup (other providers, MCP servers, agents), tell the user it will be replaced and that the backup keeps the old one, and get their go-ahead first.
- opencode itself does not have to be installed for the config to be written. Do not install it unless the user asks.

### 2. Get the API key without exposing it

The key is a secret: never print it, echo it, write it into the conversation, or put it anywhere but the script's environment. Pick the first that applies:

1. `STRATA_API_KEY` is already set in the environment: use it.
2. This machine can SSH to the server without a password. Test with `ssh -o BatchMode=yes -o ConnectTimeout=5 root@ai.bbenetti.ca true`. If that works, read the key straight into the script's environment, in a single command (step 4).
3. Otherwise, ask the user to run the script themselves so the key is typed into a hidden prompt, never into the chat: `! sh <base directory>/scripts/setup-opencode.sh`. Then go to step 5.

The script's own prompt cannot be used from a tool call (no terminal), so in cases 1 and 2 always pass the key through `STRATA_API_KEY`.

### 3. Pick the address

Default: `http://ai.bbenetti.ca:8080/v1`. The name resolves only through Ben's LAN DNS (pfSense), and the firewall admits only `10.0.0.0/24`. Set `STRATA_URL` when needed:

| Where opencode runs | `STRATA_URL` |
| --- | --- |
| Ben's LAN (default) | (leave unset) |
| A container or host that can't resolve the name | `http://10.0.0.130:8080/v1` |
| A Docker container running on `ai` itself | `http://172.17.0.1:8080/v1` |

### 4. Run the script

Case 1 (key in the environment):

```bash
sh <base directory>/scripts/setup-opencode.sh
```

Case 2 (key over SSH, never printed):

```bash
STRATA_API_KEY="$(ssh -o BatchMode=yes root@ai.bbenetti.ca cat /root/strata-api-key.txt)" sh <base directory>/scripts/setup-opencode.sh
```

Prefix `STRATA_URL=...` from step 3 if needed. Read the output:

- `Strata reachable, key accepted` then `wrote ... opencode.json`: done.
- `key was rejected; nothing written`: wrong key. Ask the user for the right one (the server keeps it in `/root/strata-api-key.txt` on `ai`).
- `could not reach ... (HTTP 000)`: wrong address or not on the LAN. Try the next row of the table in step 3, or report it.

### 5. Verify

If opencode is installed (often `~/.opencode/bin/opencode`, which may not be on `PATH` in a non-interactive shell), run one request from a scratch directory:

```bash
opencode run -m strata/qwen3.8-flash-next-fast "Reply with exactly: config works"
```

The reply should be `config works`. On opencode v2 with a background service, add `--standalone` if the service was started before the config changed.

### 6. Report

Tell the user the config path, the address used, the two model names, where the backup went (if one was made), and the verify result. If verifying failed or was skipped, say so.

## Server facts

- Strata (github.com/Niko1221/Strata) on `ai.bbenetti.ca` (10.0.0.130), port 8080, behind an API key.
- OpenAI API: `/v1/chat/completions`, Anthropic API: `/v1/messages`, Responses API: `/v1/responses`. The model name in requests is ignored.
- Context 262,144 tokens. Strata answers one request at a time, so long jobs from several clients queue.
- Health check without a key: `curl http://ai.bbenetti.ca:8080/health`.
