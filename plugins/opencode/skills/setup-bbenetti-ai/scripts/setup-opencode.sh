#!/bin/sh
# Point opencode at the Strata server on ai.bbenetti.ca.
# Usage:  sh setup-opencode.sh                  (prompts for the API key)
#         STRATA_API_KEY=... sh setup-opencode.sh   (no prompt, e.g. in a Dockerfile)
#         STRATA_URL=http://10.0.0.130:8080/v1 sh setup-opencode.sh   (if the name doesn't resolve;
#           containers running on ai itself: http://172.17.0.1:8080/v1)
set -e
URL="${STRATA_URL:-http://ai.bbenetti.ca:8080/v1}"
DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
KEY="$STRATA_API_KEY"
if [ -z "$KEY" ]; then
  printf "Strata API key: "; stty -echo 2>/dev/null || true; read -r KEY; stty echo 2>/dev/null || true; echo
fi
[ -n "$KEY" ] || { echo "no key given" >&2; exit 1; }

# Check the server and key before writing anything (skipped if curl is missing).
if command -v curl >/dev/null 2>&1; then
  code=$(curl -s -o /dev/null -m 10 -w '%{http_code}' -H "Authorization: Bearer $KEY" "$URL/models" || true)
  case "$code" in
    200) echo "Strata reachable, key accepted" ;;
    401) echo "Strata reachable, but the key was rejected; nothing written" >&2; exit 1 ;;
    *)   echo "could not reach $URL (HTTP $code); try STRATA_URL=http://10.0.0.130:8080/v1; nothing written" >&2; exit 1 ;;
  esac
fi

mkdir -p "$DIR"
(umask 077; printf '%s\n' "$KEY" > "$DIR/strata-api-key")
[ -f "$DIR/opencode.json" ] && cp "$DIR/opencode.json" "$DIR/opencode.json.bak-$(date +%Y%m%d-%H%M%S)"

cat > "$DIR/opencode.json" <<EOF
{
  "\$schema": "https://opencode.ai/config.json",
  "provider": {
    "strata": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Strata (ai.bbenetti.ca)",
      "options": { "baseURL": "$URL", "apiKey": "{file:$DIR/strata-api-key}", "timeout": 900000 },
      "models": {
        "qwen3.8-flash-next": {
          "id": "qwen3.8-flash-next-unsloth-ud-iq4_xs", "name": "Qwen3.8-Flash-Next (Strata)",
          "tool_call": true, "reasoning": true,
          "limit": { "context": 262144, "output": 8192 }, "options": { "reasoningEffort": "medium" }
        },
        "qwen3.8-flash-next-fast": {
          "id": "qwen3.8-flash-next-unsloth-ud-iq4_xs", "name": "Qwen3.8-Flash-Next, no thinking (Strata)",
          "tool_call": true, "reasoning": false,
          "limit": { "context": 262144, "output": 4096 }, "options": { "reasoningEffort": "none" }
        }
      }
    }
  },
  "model": "strata/qwen3.8-flash-next",
  "small_model": "strata/qwen3.8-flash-next-fast"
}
EOF
echo "wrote $DIR/opencode.json -> $URL"
