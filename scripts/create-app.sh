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
  <string>1.2.1</string>
  <key>CFBundleVersion</key>
  <string>1.2.1</string>
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

# Copy launcher script
cp "$ROOT_DIR/scripts/launcher.sh" "$APP_DIR/Contents/MacOS/CodexNowLauncher"
chmod +x "$APP_DIR/Contents/MacOS/CodexNowLauncher"

mkdir -p "$HOME/.local/bin"
cat > "$HOME/.local/bin/codex-now" <<'SH'
#!/bin/bash
exec "$HOME/Applications/Codex Now.app/Contents/MacOS/CodexNowLauncher" "$@"
SH
chmod +x "$HOME/.local/bin/codex-now"

echo "Created: $APP_DIR"
echo "Created: $HOME/.local/bin/codex-now"
