# Codex Now

[![Release](https://img.shields.io/github/v/release/xiaolin26/Codex-now)](https://github.com/xiaolin26/Codex-now/releases)
[![Platform](https://img.shields.io/badge/platform-macOS-black)](https://github.com/xiaolin26/Codex-now)
[![License](https://img.shields.io/github/license/xiaolin26/Codex-now)](https://github.com/xiaolin26/Codex-now/blob/main/LICENSE)

Launch `codex` in the current Finder folder with one click on macOS.

`Codex Now` is a lightweight macOS launcher for people who want to open the Codex CLI from Finder without manually `cd`-ing in Terminal first.

## What It Does

- Reads the current Finder folder when available
- Falls back to the last folder you opened
- Falls back to `$HOME` if no folder is available
- Opens `codex` in Terminal, iTerm, or Warp
- Installs as a local app in `~/Applications`

## Use Cases

- Open Codex from the folder you are already browsing in Finder
- Start coding faster without manual terminal navigation
- Keep a simple app-style entrypoint for the Codex CLI

## Requirements

- macOS
- `codex` CLI installed
- `codex` available in `PATH`, or at one of these paths:
  - `$HOME/.local/bin/codex`
  - `$HOME/.nvm/versions/node/v18.20.0/bin/codex`

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/xiaolin26/Codex-now/main/install.sh | bash
```

## Download

- Release page: `https://github.com/xiaolin26/Codex-now/releases`
- Latest macOS package: `Codex-Now-v1.0.0-macos.zip`
- SHA-256 checksum is published alongside the zip asset in the same release
- Direct release link: `https://github.com/xiaolin26/Codex-now/releases/tag/v1.0.0`

## Local Install

```bash
git clone https://github.com/xiaolin26/Codex-now.git
cd Codex-now
bash install.sh
```

## Installed Files

The installer creates:

- `~/Applications/Codex Now.app`
- `~/.local/bin/codex-now`

## How It Works

When you launch `Codex Now`:

1. It tries to read the current Finder window path
2. If Finder is unavailable, it uses `~/.codex-now-last-dir`
3. If that file is missing, it uses `$HOME`
4. It detects your preferred terminal
5. It launches `codex` in that directory

## Terminal Preference

You can optionally create `~/.codex-now-terminal` with one of these values:

- `Terminal`
- `iTerm`
- `iTerm2`
- `Warp`

If the file is missing, `Codex Now` auto-detects available terminals.

## Project Files

- `install.sh`: install entrypoint
- `scripts/create-app.sh`: builds the `.app` bundle
- `assets/AppIcon.icns`: app icon
- `releases/v1.0.0.md`: release notes draft

## Security

- This repo does not require any API key, token, or secret
- The project only launches your locally installed `codex` CLI
- The last opened directory is stored locally in `~/.codex-now-last-dir`
- No personal machine state is committed into the repository

## Acknowledgements

- Inspired by `claude-code-now`: `https://github.com/orange2ai/claude-code-now`
- Thanks to 橘子老师 for the original idea and reference implementation

## Screenshots

Repository screenshot placeholders live in `assets/screenshots/`.

Suggested screenshots for the GitHub page:

- Finder right before launching `Codex Now`
- `Codex Now.app` in `~/Applications`
- Terminal opening directly into the selected folder

See `assets/screenshots/README.md` for a concrete capture checklist.

## 中文说明

`Codex Now` 是一个 macOS 小工具，用来从 Finder 当前目录一键打开 `codex`。

适合你已经装好了 Codex CLI，但不想每次都先手动打开终端、再 `cd` 到目标目录的场景。

安装后会生成：

- `~/Applications/Codex Now.app`
- `~/.local/bin/codex-now`

下载地址：

- Releases: `https://github.com/xiaolin26/Codex-now/releases`
- 当前版本：`v1.0.0`
- 直达页面：`https://github.com/xiaolin26/Codex-now/releases/tag/v1.0.0`

鸣谢：

- 参考项目：`https://github.com/orange2ai/claude-code-now`
- 感谢橘子老师提供原始思路和参考实现
