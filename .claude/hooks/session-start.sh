#!/bin/bash
# Installs the agent-browser CLI at session start so Claude can open and screenshot pages.
set -euo pipefail

# Only needed in Claude Code on the web (fresh container each session).
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

if ! command -v agent-browser >/dev/null 2>&1; then
  npm install -g agent-browser >/dev/null 2>&1
fi

# The web container blocks Chrome downloads; use its preinstalled Chromium instead.
if [ -x /opt/pw-browsers/chromium ] && [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo "export AGENT_BROWSER_EXECUTABLE_PATH=/opt/pw-browsers/chromium" >> "$CLAUDE_ENV_FILE"
fi
