#!/data/data/com.termux/files/usr/bin/bash
# ================================================================
#  termux_copilot — install.sh
#  One-command GitHub Copilot CLI installer for Termux (Android)
#  Repo:    https://github.com/markoboskoauroville/termux_copilot
#  Model:   MAI Code 2 (mai-code-2) — Microsoft AI, latest
#  Binary:  github/copilot-cli v1.0.116 (linux-arm64 via glibc)
#  Author:  markoboskoauroville
# ================================================================
#
#  USAGE:
#    curl -fsSL https://raw.githubusercontent.com/markoboskoauroville/termux_copilot/main/install.sh | bash
#    — or —
#    bash install.sh
#    bash install.sh --token /path/to/token.txt
#    bash install.sh --uninstall
#
# ================================================================

set -euo pipefail

# ── Version & URLs ─────────────────────────────────────────────
COPILOT_VERSION="v1.0.116"
COPILOT_URL="https://github.com/github/copilot-cli/releases/download/${COPILOT_VERSION}/copilot-linux-arm64.tar.gz"
COPILOT_OLD_URL="https://github.com/github/gh-copilot/releases/download/v1.2.0/android-arm64"
RAW_BASE="https://raw.githubusercontent.com/markoboskoauroville/termux_copilot/main"

# ── Install paths ──────────────────────────────────────────────
PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
BIN_DIR="$PREFIX/bin"
COPILOT_DIR="$HOME/.local/share/gh/copilot"
COPILOT_BIN="$COPILOT_DIR/copilot-cli-new"
COPILOT_FALLBACK="$COPILOT_DIR/copilot-cli-android"
TOKEN_FILE_DEFAULT="/storage/emulated/0/Download/API/___github_token.txt"

# ── Colors ──────────────────────────────────────────────────────
R='\033[0m'
BOLD='\033[1m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
RED='\033[0;31m'
DIM='\033[2m'

# ── Helpers ─────────────────────────────────────────────────────
info()    { echo -e "${CYAN}  ➜  ${R}$*"; }
success() { echo -e "${GREEN}  ✓  ${R}$*"; }
warn()    { echo -e "${YELLOW}  ⚠  ${R}$*"; }
error()   { echo -e "${RED}  ✗  ${R}$*" >&2; }
step()    { echo -e "\n${MAGENTA}${BOLD}[$1]${R} $2"; }
hr()      { echo -e "${DIM}────────────────────────────────────────────${R}"; }

banner() {
  echo
  echo -e "${MAGENTA}${BOLD}"
  echo "  ╔══════════════════════════════════════════════╗"
  echo "  ║   🤖  termux_copilot  Installer             ║"
  echo "  ║   GitHub Copilot CLI  ·  MAI Code 2         ║"
  echo "  ║   github.com/markoboskoauroville             ║"
  echo "  ╚══════════════════════════════════════════════╝"
  echo -e "${R}"
}

# ── Parse args ──────────────────────────────────────────────────
TOKEN_FILE="$TOKEN_FILE_DEFAULT"
UNINSTALL=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --token) TOKEN_FILE="$2"; shift 2 ;;
    --uninstall|-u) UNINSTALL=true; shift ;;
    --help|-h)
      echo "Usage: bash install.sh [--token <path>] [--uninstall]"
      echo "  --token <path>   Path to file containing GitHub PAT (optional)"
      echo "  --uninstall      Remove copilot command and binaries"
      exit 0 ;;
    *) shift ;;
  esac
done

# ── Uninstall ───────────────────────────────────────────────────
uninstall() {
  banner
  echo -e "${YELLOW}Uninstalling termux_copilot...${R}"
  rm -f "$BIN_DIR/copilot" "$BIN_DIR/Copilot" "$BIN_DIR/COPILOT"
  rm -rf "$COPILOT_DIR"
  success "All copilot files removed."
  echo -e "${DIM}  gh CLI and glibc were not removed (they may be used by other tools).${R}"
  exit 0
}

$UNINSTALL && uninstall

# ── Main install ─────────────────────────────────────────────────
banner
hr

# ── Step 1: Check architecture ───────────────────────────────────
step "1/7" "Checking device architecture"
ARCH=$(uname -m)
OS=$(uname -s)
info "OS: $OS | Arch: $ARCH"
if [[ "$ARCH" != "aarch64" && "$ARCH" != "arm64" ]]; then
  warn "This installer is optimised for arm64/aarch64 (Android). Your arch: $ARCH"
  warn "Continuing anyway — things may not work."
fi
success "Architecture OK"

# ── Step 2: Ensure pkg dependencies ──────────────────────────────
step "2/7" "Checking Termux packages (gh, curl, glibc)"

need_pkg() {
  if ! command -v "$1" &>/dev/null; then
    info "Installing $1..."
    pkg install -y "$2" 2>/dev/null || apt-get install -y "$2" 2>/dev/null || {
      error "Could not install $2. Run: pkg install $2"
      exit 1
    }
    success "$1 installed"
  else
    success "$1 already installed ($(command -v "$1"))"
  fi
}

need_pkg curl curl
need_pkg gh gh

# Check glibc (needed to run linux-arm64 binary)
if ! command -v glibc-runner &>/dev/null; then
  info "Installing glibc (needed for Copilot CLI linux binary)..."
  # Add glibc repo if not present
  if ! grep -q "glibc" /etc/apt/sources.list.d/*.list 2>/dev/null; then
    curl -fsSL https://its-pointless.github.io/setup-pointless-repo.sh | bash 2>/dev/null || true
    pkg update -y 2>/dev/null || true
  fi
  pkg install -y glibc-runner 2>/dev/null || {
    warn "Could not install glibc-runner. Will use android-arm64 fallback binary."
    USE_FALLBACK=true
  }
else
  success "glibc-runner already installed"
  USE_FALLBACK=false
fi

USE_FALLBACK=${USE_FALLBACK:-false}

# ── Step 3: Download Copilot CLI binary ───────────────────────────
step "3/7" "Downloading GitHub Copilot CLI $COPILOT_VERSION"
mkdir -p "$COPILOT_DIR"

if [ "$USE_FALLBACK" = "false" ] && command -v glibc-runner &>/dev/null; then
  # Preferred: linux-arm64 via glibc-runner
  TGZ="$COPILOT_DIR/copilot-linux-arm64.tar.gz"
  if [ ! -f "$COPILOT_BIN" ]; then
    info "Downloading linux-arm64 binary (${COPILOT_VERSION})..."
    curl -L --progress-bar "$COPILOT_URL" -o "$TGZ"
    info "Extracting..."
    tar -xzf "$TGZ" -C "$COPILOT_DIR/"
    mv "$COPILOT_DIR/copilot" "$COPILOT_BIN"
    chmod +x "$COPILOT_BIN"
    rm -f "$TGZ"
    success "Copilot CLI $COPILOT_VERSION downloaded (linux-arm64 via glibc)"
  else
    success "Copilot CLI binary already exists, skipping download"
  fi
  LAUNCH_CMD="glibc-runner $COPILOT_BIN"
else
  # Fallback: android-arm64 (older v1.2.0, deprecated but works natively)
  if [ ! -f "$COPILOT_FALLBACK" ]; then
    info "Downloading android-arm64 fallback binary (v1.2.0)..."
    curl -L --progress-bar "$COPILOT_OLD_URL" -o "$COPILOT_FALLBACK"
    chmod +x "$COPILOT_FALLBACK"
    success "Copilot CLI v1.2.0 downloaded (android-arm64 fallback)"
  else
    success "Fallback binary already exists, skipping download"
  fi
  LAUNCH_CMD="$COPILOT_FALLBACK"
fi

# ── Step 4: GitHub authentication ────────────────────────────────
step "4/7" "GitHub authentication"

if [ -f "$TOKEN_FILE" ]; then
  info "Found token file: $TOKEN_FILE"
  _T="$(cat "$TOKEN_FILE" | tr -d '[:space:]')"
  echo "$_T" | gh auth login --with-token 2>/dev/null && \
    success "Logged in via token file" || \
    warn "Token login failed — you may need to run: gh auth login"
  unset _T
elif gh auth status &>/dev/null; then
  success "Already logged in to GitHub ($(gh api user --jq .login 2>/dev/null || echo 'user'))"
else
  warn "Not logged in to GitHub."
  info "Starting gh auth login (follow the prompts)..."
  gh auth login --hostname github.com --git-protocol https --web 2>/dev/null || \
  gh auth login --hostname github.com --git-protocol https 2>/dev/null || {
    warn "Could not auto-login. Run manually: gh auth login"
  }
fi

# ── Step 5: Write global copilot command ──────────────────────────
step "5/7" "Installing global 'copilot' command"

# Escape the LAUNCH_CMD for embedding in the script
LAUNCH_CMD_ESCAPED="$LAUNCH_CMD"

cat > "$BIN_DIR/copilot" << SCRIPT
#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  copilot — Global GitHub Copilot CLI for Termux
#  Installed by: termux_copilot installer
#  Binary:  github/copilot-cli ${COPILOT_VERSION} (linux-arm64 via glibc)
#  Model:   MAI Code 2 (mai-code-2) — Microsoft AI, latest
# ============================================================

COPILOT_BIN="${COPILOT_BIN}"
COPILOT_FALLBACK="${COPILOT_FALLBACK}"
TOKEN_FILE="${TOKEN_FILE}"
RESET='\\\033[0m'; BOLD='\\\033[1m'; CYAN='\\\033[0;36m'
GREEN='\\\033[0;32m'; MAGENTA='\\\033[0;35m'; RED='\\\033[0;31m'; DIM='\\\033[2m'

banner() {
  echo -e "\${MAGENTA}\${BOLD}"
  echo "  ╔══════════════════════════════════════════╗"
  echo "  ║  🤖  GitHub Copilot CLI  ·  ${COPILOT_VERSION}    ║"
  echo "  ║  Model: MAI Code 2  ·  Termux / Android  ║"
  echo "  ╚══════════════════════════════════════════╝"
  echo -e "\${RESET}"
}

load_token() {
  if [ -f "\$TOKEN_FILE" ]; then
    _T="\$(cat "\$TOKEN_FILE" | tr -d '[:space:]')"
    export GITHUB_TOKEN="\$_T"
    unset _T
  elif gh auth status &>/dev/null; then
    export GITHUB_TOKEN="\$(gh auth token 2>/dev/null)"
  else
    echo -e "\${RED}✗ No GitHub token found. Run: gh auth login\${RESET}" >&2
    exit 1
  fi
}

ensure_binary() {
  if [ ! -x "\$COPILOT_BIN" ] && [ ! -x "\$COPILOT_FALLBACK" ]; then
    echo -e "\${CYAN}⬇  Re-downloading Copilot CLI...${RESET}"
    curl -fsSL https://raw.githubusercontent.com/markoboskoauroville/termux_copilot/main/install.sh | bash
    exit \$?
  fi
}

run() {
  load_token
  export GH_COPILOT_MODEL="mai-code-2"
  if [ -x "\$COPILOT_BIN" ] && command -v glibc-runner &>/dev/null; then
    exec glibc-runner "\$COPILOT_BIN" --model mai-code-2 "\$@"
  elif [ -x "\$COPILOT_FALLBACK" ]; then
    exec "\$COPILOT_FALLBACK" "\$@"
  else
    exec gh copilot -- "\$@"
  fi
}

show_help() {
  banner
  cat << 'EOF'
USAGE
  copilot / Copilot / COPILOT    (all work — case insensitive)
  copilot                        → Interactive Copilot chat (MAI Code 2)
  copilot -p "<prompt>"          → One-shot non-interactive prompt
  copilot --model mai-code-2-flash -p "<prompt>"  → Flash model
  copilot login                  → Authenticate with GitHub Copilot
  copilot config                 → View/change settings
  copilot sessions               → View saved sessions
  copilot memories               → Manage Copilot memory
  copilot update                 → Update Copilot CLI binary
  copilot help                   → Full help

EXAMPLES
  copilot
  copilot -p "how do I rebase in git?"
  copilot -p "suggest a command to find large files"
  Copilot -p "explain what ls -la | grep drwx does"
  COPILOT --model mai-code-2-flash -p "quick bash question"

MODEL
  Default:  mai-code-2        (MAI Code 2 — deep reasoning)
  Alt:      mai-code-2-flash  (MAI Code 2 Flash — fast)

REINSTALL
  curl -fsSL https://raw.githubusercontent.com/markoboskoauroville/termux_copilot/main/install.sh | bash
EOF
}

ensure_binary

case "\${1:-}" in
  "help"|"-h") show_help ;;
  "")
    banner
    echo -e "\${DIM}Starting interactive Copilot chat with MAI Code 2...${RESET}"
    echo -e "\${DIM}Type /help inside chat, Ctrl+C to exit${RESET}"
    echo
    run
    ;;
  *) run "\$@" ;;
esac
SCRIPT

chmod +x "$BIN_DIR/copilot"
success "Global 'copilot' command installed at $BIN_DIR/copilot"

# ── Step 6: Case-insensitive aliases ──────────────────────────────
step "6/7" "Creating case-insensitive aliases (Copilot, COPILOT)"
ln -sf "$BIN_DIR/copilot" "$BIN_DIR/Copilot"
ln -sf "$BIN_DIR/copilot" "$BIN_DIR/COPILOT"
success "Copilot → copilot (symlink created)"
success "COPILOT → copilot (symlink created)"

# ── Step 7: Copilot OAuth login ───────────────────────────────────
step "7/7" "Activating GitHub Copilot (device code login)"
echo
echo -e "${CYAN}  To complete setup, Copilot needs its own OAuth token.${R}"
echo -e "${CYAN}  This is separate from your GitHub PAT.${R}"
echo
echo -e "${YELLOW}  Run this command to finish:${R}"
echo
echo -e "  ${BOLD}  copilot login${R}"
echo
echo -e "${DIM}  It will show a code — go to https://github.com/login/device${R}"
echo -e "${DIM}  Enter the code and click Authorize. Done!${R}"
echo

# ── Summary ───────────────────────────────────────────────────────
hr
echo
echo -e "${GREEN}${BOLD}  🎉 Installation complete!${R}"
echo
echo -e "  Commands available:"
echo -e "  ${CYAN}copilot${R}  /  ${CYAN}Copilot${R}  /  ${CYAN}COPILOT${R}"
echo
echo -e "  Binary:  ${DIM}${COPILOT_BIN}${R}"
echo -e "  Script:  ${DIM}${BIN_DIR}/copilot${R}"
echo -e "  Version: ${DIM}GitHub Copilot CLI ${COPILOT_VERSION}${R}"
echo -e "  Model:   ${DIM}MAI Code 2 (mai-code-2)${R}"
echo
echo -e "${YELLOW}  Next step: run ${BOLD}copilot login${R}${YELLOW} to activate AI features${R}"
echo
hr
