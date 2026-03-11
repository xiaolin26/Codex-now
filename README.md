# Codex Now

Launch `codex` in the current Finder folder with one click on macOS.

`Codex Now` is a tiny launcher app that opens Terminal, iTerm, or Warp and runs the `codex` CLI in the selected directory.

## Features

- Open `codex` from Finder's current folder
- Fallback to the last opened folder, then `$HOME`
- Auto-detect Terminal, iTerm, or Warp
- Install as a local `.app` under `~/Applications`

## Requirements

- macOS
- `codex` CLI installed and available in `PATH`, or located at one of:
  - `$HOME/.local/bin/codex`
  - `$HOME/.nvm/versions/node/v18.20.0/bin/codex`

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/xiaolin26/Codex-now/main/install.sh | bash
```

If you are installing from a local checkout:

```bash
bash install.sh
```

## How It Works

The installer creates:

- `~/Applications/Codex Now.app`
- `~/.local/bin/codex-now`

When launched, the app:

1. Tries to use the current Finder window path
2. Falls back to the last opened directory
3. Falls back to `$HOME`
4. Opens your preferred terminal and runs `codex`

## Files

- `install.sh`: install entrypoint
- `scripts/create-app.sh`: builds the local `.app` launcher

## Notes

- No API keys, tokens, or secrets are required by this project itself.
- The app stores the last opened path in `~/.codex-now-last-dir`.
- You can optionally store the terminal preference in `~/.codex-now-terminal` with one of:
  - `Terminal`
  - `iTerm`
  - `iTerm2`
  - `Warp`
