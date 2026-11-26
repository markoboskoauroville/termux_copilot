# termux_copilot

> **One-command GitHub Copilot CLI installer for Termux (Android)**
> Model: **MAI Code 2** — Microsoft AI, latest

---

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/markoboskoauroville/termux_copilot/main/install.sh | bash
```

That's it. The installer will:

1. ✅ Check & install dependencies (`gh`, `curl`, `glibc-runner`)
2. ✅ Download **GitHub Copilot CLI v1.0.116** (linux-arm64 via glibc)
3. ✅ Create global `copilot` command (available system-wide in Termux)
4. ✅ Create **case-insensitive aliases** — `copilot`, `Copilot`, `COPILOT` all work
5. ✅ Authenticate with your GitHub account
6. ✅ Guide you through Copilot OAuth activation

---

## After Install — Activate Copilot

```bash
copilot login
```

Go to **https://github.com/login/device** → enter the shown code → Authorize.
*(Requires a GitHub Copilot subscription — Free, Pro, or Business)*

---

## Usage

```bash
copilot                          # Start interactive chat (MAI Code 2)
Copilot                          # Same — case insensitive
COPILOT                          # Same — case insensitive

copilot -p "how do I rebase in git?"          # Quick one-shot prompt
copilot -p "explain ls -la | grep drwx"       # Explain a command
copilot --model mai-code-2-flash -p "..."     # Use Flash model (faster)

copilot login                    # Authenticate with GitHub Copilot
copilot config                   # View/change settings
copilot sessions                 # View saved sessions
copilot memories                 # Manage Copilot's memory of you
copilot update                   # Update Copilot CLI to latest version
copilot help                     # Full help
```

---

## Models

| Model ID | Description |
|---|---|
| `mai-code-2` | **MAI Code 2** — Microsoft AI, latest, deep reasoning (default) |
| `mai-code-2-flash` | **MAI Code 2 Flash** — fast & lightweight |

Switch mid-session with `--model`:
```bash
copilot --model mai-code-2-flash -p "quick question"
```

---

## Options

```bash
bash install.sh                          # Standard install
bash install.sh --token /path/token.txt  # Provide GitHub PAT from file
bash install.sh --uninstall              # Remove everything
```

---

## Requirements

- **Termux** on Android (arm64 / aarch64)
- **GitHub account** with a Copilot subscription
- Internet connection

---

## Uninstall

```bash
bash install.sh --uninstall
# or
curl -fsSL https://raw.githubusercontent.com/markoboskoauroville/termux_copilot/main/install.sh | bash -s -- --uninstall
```

---

## What Gets Installed

| Path | Purpose |
|---|---|
| `/usr/bin/copilot` | Global command script |
| `/usr/bin/Copilot` | Symlink (case alias) |
| `/usr/bin/COPILOT` | Symlink (case alias) |
| `~/.local/share/gh/copilot/copilot-cli-new` | Copilot CLI v1.0.116 binary |
| `~/.copilot/` | Copilot config & auth tokens |

---

## Author

**markoboskoauroville** — [github.com/markoboskoauroville](https://github.com/markoboskoauroville)

---

## License

MIT
