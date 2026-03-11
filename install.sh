#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "$ROOT_DIR/scripts/create-app.sh"

echo
echo "Install complete."
echo "App: $HOME/Applications/Codex Now.app"
echo "CLI: $HOME/.local/bin/codex-now"
