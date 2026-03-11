#!/bin/bash

TARGET_DIR="${1:-}"
LAST_DIR_FILE="$HOME/.codex-now-last-dir"
TERMINAL_CONFIG_FILE="$HOME/.codex-now-terminal"

# Build PATH without sourcing rc files (avoids hangs on nvm/conda init)
export PATH="$HOME/.local/bin:$HOME/.npm-global/bin:$HOME/.npm/bin:$HOME/Library/pnpm:$HOME/.cargo/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

# Load nvm if available (non-interactive)
if [ -s "$HOME/.nvm/nvm.sh" ]; then
  export NVM_DIR="$HOME/.nvm"
  \. "$NVM_DIR/nvm.sh" --no-use >/dev/null 2>&1 || true
fi

# Resolve target directory
if [ -z "$TARGET_DIR" ]; then
  TARGET_DIR=$(osascript \
    -e 'tell application "Finder"' \
    -e 'try' \
    -e 'set p to POSIX path of (target of front window as alias)' \
    -e 'on error' \
    -e 'set p to ""' \
    -e 'end try' \
    -e 'end tell' \
    -e 'return p' 2>/dev/null || true)
fi

if [ -z "$TARGET_DIR" ] && [ -f "$LAST_DIR_FILE" ]; then
  TARGET_DIR=$(cat "$LAST_DIR_FILE")
fi

[ -z "$TARGET_DIR" ] && TARGET_DIR="$HOME"

if [ ! -d "$TARGET_DIR" ]; then
  osascript -e "display alert \"Codex Now\" message \"Directory not found: $TARGET_DIR\""
  exit 1
fi

# Find codex binary
find_codex() {
  command -v codex 2>/dev/null && return
  # Check all nvm node versions
  for p in "$HOME/.nvm/versions/node"/*/bin/codex; do
    [ -x "$p" ] && echo "$p" && return
  done
  [ -x "$HOME/.local/bin/codex" ]      && echo "$HOME/.local/bin/codex"      && return
  [ -x "$HOME/.npm-global/bin/codex" ] && echo "$HOME/.npm-global/bin/codex" && return
  # Check npm global prefix dynamically
  if command -v npm >/dev/null 2>&1; then
    NPM_BIN="$(npm config get prefix 2>/dev/null)/bin/codex"
    [ -x "$NPM_BIN" ] && echo "$NPM_BIN" && return
  fi
  echo ""
}

# Detect preferred terminal
detect_terminal() {
  local term="Terminal"
  if [ -f "$TERMINAL_CONFIG_FILE" ]; then
    local pref
    pref=$(tr -d '\r\n' < "$TERMINAL_CONFIG_FILE")
    case "$pref" in
      iTerm|iTerm2) [ -d "/Applications/iTerm.app" ]  && term="iTerm"   ;;
      Warp)         [ -d "/Applications/Warp.app" ]   && term="Warp"    ;;
    esac
  else
    [ -d "/Applications/iTerm.app" ]   && term="iTerm"
    [ -d "/Applications/iTerm 2.app" ] && term="iTerm 2"
    [ -d "/Applications/Warp.app" ]    && term="Warp"
  fi
  echo "$term"
}

# Launch terminal with a command string directly (no temp files = no lock issues)
launch_terminal() {
  local cmd="$1"
  local term
  term=$(detect_terminal)

  case "$term" in
    iTerm|"iTerm 2")
      osascript \
        -e "tell application \"$term\"" \
        -e "  activate" \
        -e "  create window with default profile" \
        -e "  tell current session of current window" \
        -e "    write text \"$cmd\"" \
        -e "  end tell" \
        -e "end tell"
      ;;
    Warp)
      osascript \
        -e 'tell application "Warp"' \
        -e '  activate' \
        -e '  tell application "System Events"' \
        -e '    keystroke "t" using {command down}' \
        -e '    delay 0.2' \
        -e "    keystroke \"$cmd\"" \
        -e '    keystroke return' \
        -e '  end tell' \
        -e 'end tell'
      ;;
    *)
      osascript \
        -e 'tell application "Terminal"' \
        -e '  activate' \
        -e "  do script \"$cmd\"" \
        -e 'end tell'
      ;;
  esac
}

CODEX_PATH=$(find_codex)
echo "$TARGET_DIR" > "$LAST_DIR_FILE"

# ── No codex: offer to install ────────────────────────────────────────────────
if [ -z "$CODEX_PATH" ]; then
  NPM_PATH=$(command -v npm 2>/dev/null || true)

  if [ -z "$NPM_PATH" ]; then
    osascript -e 'display alert "Node.js Not Found" message "Codex CLI requires Node.js.\n\nPlease install Node.js from https://nodejs.org then relaunch Codex Now."'
    exit 1
  fi

  ANSWER=$(osascript \
    -e 'display dialog "Codex CLI is not installed.\n\nWould you like to install it now via npm?" buttons {"Cancel", "Install"} default button "Install" with title "Codex Now"' \
    -e 'button returned of result' 2>/dev/null || echo "Cancel")

  [ "$ANSWER" != "Install" ] && exit 0

  # Install to ~/.npm-global to avoid /usr/local permission issues
  CMD="mkdir -p \$HOME/.npm-global && npm config set prefix \$HOME/.npm-global && $NPM_PATH install -g @openai/codex && export PATH=\$HOME/.npm-global/bin:\$PATH && echo '' && echo '========================================' && echo '  Install complete! Starting Codex...' && echo '========================================' && echo '' && codex"
  launch_terminal "$CMD"
  exit 0
fi

# ── Codex found: check login then launch ──────────────────────────────────────
CMD="cd $(printf '%q' "$TARGET_DIR") && if $CODEX_PATH login status 2>&1 | grep -q 'Not logged in'; then echo '' && echo '========================================' && echo '  Codex Now - Login Required' && echo '  Browser will open for OpenAI login.' && echo '========================================' && echo '' && $CODEX_PATH login && echo '' && echo '========================================' && echo '  Login complete! Starting Codex...' && echo '========================================' && echo ''; fi && $CODEX_PATH"

launch_terminal "$CMD"
