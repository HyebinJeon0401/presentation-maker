#!/bin/bash
# Installs the tools Claude needs to build and visually check slides in Claude Code on the web.
set -euo pipefail

# Only needed in Claude Code on the web (fresh container each session).
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

# Browser automation (screenshots of HTML output).
if ! command -v agent-browser >/dev/null 2>&1; then
  npm install -g agent-browser >/dev/null 2>&1
fi

# PPT generation (pptxgenjs) and text/validation helpers used by the pptx skill.
if [ ! -d "$(npm root -g)/pptxgenjs" ]; then
  npm install -g pptxgenjs >/dev/null 2>&1
fi
if ! python3 -c "import markitdown, PIL, defusedxml, lxml" >/dev/null 2>&1; then
  pip install -q "markitdown[pptx]" Pillow defusedxml lxml >/dev/null 2>&1
fi

# PPT -> PDF -> image rendering for visual QA, plus Korean fonts with bold weights.
if ! dpkg -s libreoffice-impress poppler-utils fonts-nanum >/dev/null 2>&1; then
  apt-get update -q >/dev/null 2>&1 || true
  apt-get install -y -q --no-install-recommends libreoffice-impress poppler-utils fonts-nanum >/dev/null 2>&1
fi

# Decks use Malgun Gothic (ships with Windows Office); preview it with NanumGothic.
mkdir -p "$HOME/.config/fontconfig"
cat > "$HOME/.config/fontconfig/fonts.conf" <<'EOF'
<?xml version="1.0"?><!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <match target="pattern">
    <test name="family"><string>Malgun Gothic</string></test>
    <edit name="family" mode="assign" binding="strong"><string>NanumGothic</string></edit>
  </match>
  <match target="pattern">
    <test name="family"><string>맑은 고딕</string></test>
    <edit name="family" mode="assign" binding="strong"><string>NanumGothic</string></edit>
  </match>
</fontconfig>
EOF
fc-cache -f >/dev/null 2>&1 || true

if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  # The web container blocks Chrome downloads; use its preinstalled Chromium instead.
  if [ -x /opt/pw-browsers/chromium ]; then
    echo "export AGENT_BROWSER_EXECUTABLE_PATH=/opt/pw-browsers/chromium" >> "$CLAUDE_ENV_FILE"
  fi
  # Let `require('pptxgenjs')` resolve the global install from any directory.
  echo "export NODE_PATH=$(npm root -g)" >> "$CLAUDE_ENV_FILE"
fi
