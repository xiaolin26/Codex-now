#!/bin/bash
set -euo pipefail

APP_DIR="$HOME/Applications/Codex Now.app"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ICON_SOURCE=""

mkdir -p "$HOME/Applications"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"

if [ -f "$ROOT_DIR/assets/AppIcon.icns" ]; then
  ICON_SOURCE="$ROOT_DIR/assets/AppIcon.icns"
elif [ -f "/Applications/Claude Code Now.app/Contents/Resources/AppIcon.icns" ]; then
  ICON_SOURCE="/Applications/Claude Code Now.app/Contents/Resources/AppIcon.icns"
elif [ -f "$HOME/Applications/Codex Now.app/Contents/Resources/AppIcon.icns" ]; then
  ICON_SOURCE="$HOME/Applications/Codex Now.app/Contents/Resources/AppIcon.icns"
fi

if [ -n "$ICON_SOURCE" ]; then
  cp "$ICON_SOURCE" "$APP_DIR/Contents/Resources/AppIcon.icns"
fi

cat > "$APP_DIR/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDisplayName</key>
  <string>Codex Now</string>
  <key>CFBundleExecutable</key>
  <string>CodexNowLauncher</string>
  <key>CFBundleIdentifier</key>
  <string>com.codexnow.launcher</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleName</key>
  <string>Codex Now</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0.0</string>
  <key>CFBundleVersion</key>
  <string>1.0.0</string>
  <key>LSMinimumSystemVersion</key>
  <string>10.13</string>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>CFBundleDocumentTypes</key>
  <array>
    <dict>
      <key>CFBundleTypeRole</key>
      <string>Viewer</string>
      <key>LSItemContentTypes</key>
      <array>
        <string>public.folder</string>
      </array>
    </dict>
  </array>
</dict>
</plist>
PLIST

cat > "$APP_DIR/Contents/MacOS/CodexNowLauncher" <<'SH'
#!/bin/bash
set -euo pipefail

TARGET_DIR="${1:-}"
LAST_DIR_FILE="$HOME/.codex-now-last-dir"
TERMINAL_CONFIG_FILE="$HOME/.codex-now-terminal"

[ -f "$HOME/.zshrc" ] && source "$HOME/.zshrc" >/dev/null 2>&1 || true
[ -f "$HOME/.bashrc" ] && source "$HOME/.bashrc" >/dev/null 2>&1 || true
[ -f "$HOME/.bash_profile" ] && source "$HOME/.bash_profile" >/dev/null 2>&1 || true

export PATH="$HOME/.local/bin:$HOME/.npm-global/bin:$HOME/.npm/bin:$HOME/Library/pnpm:$HOME/.cargo/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

if [ -z "$TARGET_DIR" ]; then
  TARGET_DIR=$(osascript -e 'tell application "Finder"' -e 'try' -e 'set p to POSIX path of (target of front window as alias)' -e 'on error' -e 'set p to ""' -e 'end try' -e 'end tell' -e 'return p' 2>/dev/null || true)
fi

if [ -z "$TARGET_DIR" ] && [ -f "$LAST_DIR_FILE" ]; then
  TARGET_DIR=$(cat "$LAST_DIR_FILE")
fi

if [ -z "$TARGET_DIR" ]; then
  TARGET_DIR="$HOME"
fi

if [ ! -d "$TARGET_DIR" ]; then
  osascript -e "display alert \"Codex Now\" message \"Directory not found: $TARGET_DIR\""
  exit 1
fi

CODEX_PATH=""
if command -v codex >/dev/null 2>&1; then
  CODEX_PATH=$(command -v codex)
elif [ -x "$HOME/.nvm/versions/node/v18.20.0/bin/codex" ]; then
  CODEX_PATH="$HOME/.nvm/versions/node/v18.20.0/bin/codex"
elif [ -x "$HOME/.local/bin/codex" ]; then
  CODEX_PATH="$HOME/.local/bin/codex"
fi

if [ -z "$CODEX_PATH" ]; then
  osascript -e 'display alert "Codex CLI Not Found" message "Could not find the codex command in PATH."'
  exit 1
fi

echo "$TARGET_DIR" > "$LAST_DIR_FILE"

launch_terminal() {
  local terminal_app="$1"
  case "$terminal_app" in
    "iTerm"|"iTerm 2")
      osascript <<EOF
tell application "$terminal_app"
  activate
  create window with default profile
  tell current session of current window
    write text "cd " & quoted form of "$TARGET_DIR" & " && $CODEX_PATH"
  end tell
end tell
EOF
      ;;
    "Warp")
      osascript <<EOF
tell application "Warp"
  activate
  tell application "System Events"
    keystroke "t" using {command down}
    delay 0.2
    keystroke "cd " & quoted form of "$TARGET_DIR" & " && $CODEX_PATH"
    keystroke return
  end tell
end tell
EOF
      ;;
    *)
      osascript <<EOF
tell application "Terminal"
  activate
  do script "cd " & quoted form of "$TARGET_DIR" & " && $CODEX_PATH"
end tell
EOF
      ;;
  esac
}

TERMINAL_TO_USE="Terminal"
if [ -f "$TERMINAL_CONFIG_FILE" ]; then
  pref=$(tr -d '\r\n' < "$TERMINAL_CONFIG_FILE")
  if [ "$pref" = "iTerm2" ] || [ "$pref" = "iTerm" ]; then
    if [ -d "/Applications/iTerm.app" ]; then
      TERMINAL_TO_USE="iTerm"
    elif [ -d "/Applications/iTerm 2.app" ]; then
      TERMINAL_TO_USE="iTerm 2"
    fi
  elif [ "$pref" = "Warp" ] && [ -d "/Applications/Warp.app" ]; then
    TERMINAL_TO_USE="Warp"
  fi
else
  if [ -d "/Applications/iTerm.app" ]; then
    TERMINAL_TO_USE="iTerm"
  elif [ -d "/Applications/iTerm 2.app" ]; then
    TERMINAL_TO_USE="iTerm 2"
  elif [ -d "/Applications/Warp.app" ]; then
    TERMINAL_TO_USE="Warp"
  fi
fi

launch_terminal "$TERMINAL_TO_USE"
SH

chmod +x "$APP_DIR/Contents/MacOS/CodexNowLauncher"

mkdir -p "$HOME/.local/bin"
cat > "$HOME/.local/bin/codex-now" <<'SH'
#!/bin/bash
exec "$HOME/Applications/Codex Now.app/Contents/MacOS/CodexNowLauncher" "$@"
SH
chmod +x "$HOME/.local/bin/codex-now"

echo "Created: $APP_DIR"
echo "Created: $HOME/.local/bin/codex-now"
