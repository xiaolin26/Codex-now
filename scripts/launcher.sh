#!/bin/bash
set -euo pipefail

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
  for p in "$HOME/.nvm/versions/node"/*/bin/codex; do
    [ -x "$p" ] && echo "$p" && return
  done
  [ -x "$HOME/.local/bin/codex" ]     && echo "$HOME/.local/bin/codex"     && return
  [ -x "$HOME/.npm-global/bin/codex" ] && echo "$HOME/.npm-global/bin/codex" && return
  echo ""
}

# Detect preferred terminal
detect_terminal() {
  local term="Terminal"
  if [ -f "$TERMINAL_CONFIG_FILE" ]; then
    local pref
    pref=$(tr -d '\r\n' < "$TERMINAL_CONFIG_FILE")
    case "$pref" in
      iTerm|iTerm2)
        [ -d "/Applications/iTerm.app" ]   && term="iTerm"   ;;
      Warp)
        [ -d "/Applications/Warp.app" ]    && term="Warp"    ;;
    esac
  else
    if [ -d "/Applications/iTerm.app" ]; then
      term="iTerm"
    elif [ -d "/Applications/iTerm 2.app" ]; then
      term="iTerm 2"
    elif [ -d "/Applications/Warp.app" ]; then
      term="Warp"
    fi
  fi
  echo "$term"
}

# Open terminal and run a script file
open_terminal() {
  local script_path="$1"
  local term
  term=$(detect_terminal)

  case "$term" in
    iTerm|"iTerm 2")
      osascript \
        -e "tell application \"$term\"" \
        -e "  activate" \
        -e "  create window with default profile" \
        -e "  tell current session of current window" \
        -e "    write text \"bash $script_path\"" \
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
        -e "    keystroke \"bash $script_path\"" \
        -e '    keystroke return' \
        -e '  end tell' \
        -e 'end tell'
      ;;
    *)
      osascript \
        -e 'tell application "Terminal"' \
        -e '  activate' \
        -e "  do script \"bash $script_path\"" \
        -e 'end tell'
      ;;
  esac
}

CODEX_PATH=$(find_codex)

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

  echo "$TARGET_DIR" > "$LAST_DIR_FILE"

  TMP=$(mktemp -t codex-install).sh
  {
    echo "#!/bin/bash"
    echo "export PATH=\"$HOME/.local/bin:$HOME/.npm-global/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin\""
    printf 'cd %q\n' "$TARGET_DIR"
    echo 'echo ""'
    echo 'echo "========================================"'
    echo 'echo "  Codex Now - Installing Codex CLI..."'
    echo 'echo "  Please wait, this may take a minute."'
    echo 'echo "========================================"'
    echo 'echo ""'
    # Install to ~/.npm-global to avoid permission issues with /usr/local
    echo "mkdir -p \"$HOME/.npm-global\""
    echo "npm config set prefix \"$HOME/.npm-global\""
    echo "$NPM_PATH install -g @openai/codex"
    echo 'echo ""'
    echo 'echo "========================================"'
    echo 'echo "  Install complete! Starting Codex..."'
    echo 'echo "========================================"'
    echo 'echo ""'
    echo "export PATH=\"$HOME/.npm-global/bin:\$PATH\""
    echo 'exec codex'
  } > "$TMP"
  chmod +x "$TMP"

  open_terminal "$TMP"
  exit 0
fi

# ── Codex found: check login then launch ──────────────────────────────────────
echo "$TARGET_DIR" > "$LAST_DIR_FILE"

TMP=$(mktemp -t codex-launch).sh
{
  echo "#!/bin/bash"
  echo "export PATH=\"$HOME/.local/bin:$HOME/.npm-global/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin\""
  printf 'cd %q\n' "$TARGET_DIR"
  echo "if $CODEX_PATH login status 2>&1 | grep -q 'Not logged in'; then"
  echo '  echo ""'
  echo '  echo "========================================"'
  echo '  echo "  Codex Now - Login Required"'
  echo '  echo "  Browser will open for OpenAI login."'
  echo '  echo "========================================"'
  echo '  echo ""'
  echo "  $CODEX_PATH login"
  echo '  echo ""'
  echo '  echo "========================================"'
  echo '  echo "  Login complete! Starting Codex..."'
  echo '  echo "========================================"'
  echo '  echo ""'
  echo 'fi'
  echo "exec $CODEX_PATH"
} > "$TMP"
chmod +x "$TMP"

open_terminal "$TMP"
