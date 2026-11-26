# How to Login to GitHub Copilot — Fine-Grained Token

> **The problem in one line**: your stored token starts with `ghp_` (Classic PAT).  
> Copilot rejects it. You need a token that starts with `github_pat_` (Fine-Grained PAT).

---

## One-Command Fix (no prompts, no pressing anything)

Once you have your fine-grained token, run this single line — replace the token value:

```bash
gh auth logout --hostname github.com; echo "github_pat_YOUR_TOKEN_HERE" | gh auth login --with-token --hostname github.com --git-protocol https && copilot
```

That's it. No menus, no pressing 3, no interactive prompts.

---

## Step 1 — Create the Fine-Grained Token on GitHub

1. Go to → **https://github.com/settings/personal-access-tokens/new**
2. Fill in:
   - **Token name**: `copilot-termux`
   - **Expiration**: 90 days (or No expiration)
3. Under **Account permissions** → **GitHub Copilot** → **Read-only**
4. Click **Generate token**
5. Copy it — GitHub shows it **only once**. It looks like:
   `github_pat_11ABCDE...`

---

## Step 2 — Apply the Token (Full Non-Interactive Command)

```bash
gh auth logout --hostname github.com
echo "github_pat_YOUR_TOKEN_HERE" | gh auth login --with-token --hostname github.com --git-protocol https
gh auth status
copilot
```

**Why `--with-token` and `echo`?** — it feeds the token via stdin so `gh` never opens an interactive menu. No number selection needed.

---

## Why the Old Token Stopped Working

| Token Format | Type | Copilot |
|---|---|---|
| `ghp_...` | Classic PAT | ❌ Rejected |
| `gho_...` | OAuth App Token | ❌ Rejected |
| `github_pat_...` | Fine-Grained PAT | ✅ Works |

GitHub's Copilot API **requires fine-grained tokens** because they carry specific `copilot` permission scopes that classic tokens cannot express.

---

## Where the Token Lives

| Location | What it is |
|---|---|
| `~/.config/gh/hosts.yml` | What `gh` and Copilot CLI read |
| `$GITHUB_TOKEN` | Env var override (AI tools inject this — fix hosts.yml and it fixes this too) |

---

## If You Want Browser Login Instead (also no interactive prompts)

```bash
gh auth logout --hostname github.com
gh auth login --web --hostname github.com --git-protocol https
```

Browser opens → approve → switch back to Termux → Enter → `copilot`

---

## Useful Links

- Create token: https://github.com/settings/personal-access-tokens/new
- Manage tokens: https://github.com/settings/tokens
- Copilot CLI docs: https://docs.github.com/copilot/how-tos/copilot-cli
- This repo: https://github.com/markoboskoauroville/termux_copilot

---

*termux_copilot · markoboskoauroville · November 2026*
