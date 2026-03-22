# Keys & Secrets Setup Guide

This guide lists every key/secret needed for theninerd. Setup takes about 5 minutes.

---

## Quick Start: 3 Secrets

You only need to set **3 GitHub Secrets** to get theninerd running:

| Secret | How to get it |
|--------|--------------|
| `GH_PAT` | GitHub Classic PAT with `repo` + `workflow` scopes |
| `NVIDIA_API_KEY` | Free key from [build.nvidia.com](https://build.nvidia.com) |
| `TELEGRAM_BOT_TOKEN` | From [@BotFather](https://t.me/BotFather) on Telegram |

Everything else (API keys, webhook secrets, `.env` file, Docker agent credentials) is **auto-generated at runtime** by the GitHub Actions workflows.

---

## Step 1: Create the Keys

### 1. GH_PAT (GitHub Personal Access Token)

**How to create:**
1. Go to https://github.com/settings/tokens
2. Click **"Tokens (classic)"**
3. Click **"Generate new token (classic)"**
4. Name: `theninerd`
5. Scopes: **`repo`** and **`workflow`**
6. Click **"Generate token"**
7. Copy the token (starts with `ghp_`)

### 2. NVIDIA_API_KEY

**How to create:**
1. Go to https://build.nvidia.com
2. Sign up / sign in
3. Pick any model, click **"Get API Key"**
4. Copy the key (starts with `nvapi-`)

### 3. TELEGRAM_BOT_TOKEN

**How to create:**
1. Open Telegram and message **@BotFather**
2. Send `/newbot`
3. Follow the prompts to name your bot
4. Copy the token (format: `123456789:ABCdefGHI...`)

---

## Step 2: Set GitHub Secrets

Go to your repo > **Settings > Secrets and variables > Actions > Secrets** and create:

| Secret | Value | Required |
|--------|-------|----------|
| `GH_PAT` | Your GitHub Classic PAT (`ghp_...`) | Yes |
| `NVIDIA_API_KEY` | Your NVIDIA NIM key (`nvapi-...`) | Yes |
| `TELEGRAM_BOT_TOKEN` | Your Telegram bot token | Yes |
| `TELEGRAM_CHAT_ID` | Your Telegram chat ID (see below) | After first run |
| `LLM_SECRETS` | Base64 JSON of agent-accessible keys | No |

---

## Step 3: Get Your Telegram Chat ID

After setting the 3 required secrets and triggering the event handler:

1. Message **@userinfobot** on Telegram — it replies with your user/chat ID
2. Or message your bot with any text, check the event handler logs for the chat ID
3. Set `TELEGRAM_CHAT_ID` as a GitHub Secret with that number
4. Re-trigger the event handler workflow

---

## Step 4: Set Repository Variables (Optional)

Go to your repo > **Settings > Secrets and variables > Actions > Variables**:

| Variable | Value | Default |
|----------|-------|---------|
| `IMAGE_URL` | `ghcr.io/youruser/theninerd` | `stephengpope/thepopebot:latest` |
| `AUTO_MERGE` | `true` or `false` | Enabled |
| `ALLOWED_PATHS` | Path prefixes (e.g., `/logs` or `/`) | `/logs` |
| `MODEL` | NVIDIA model ID for the agent | `moonshotai/kimi-k2.5` |

---

## How It Works

The workflows auto-generate everything from your 3 secrets:

- **`event-handler.yml`** builds the `.env` file at runtime:
  - `API_KEY` — derived deterministically from `GH_PAT`
  - `GH_WEBHOOK_SECRET` — derived deterministically from `GH_PAT`
  - `TELEGRAM_WEBHOOK_SECRET` — derived deterministically from `GH_PAT`
  - `GH_OWNER` / `GH_REPO` — extracted from `github.repository`

- **`run-job.yml`** builds the `SECRETS` JSON at runtime:
  - `{"GH_TOKEN":"...","NVIDIA_API_KEY":"..."}` — base64-encoded inline

- **`update-event-handler.yml`** derives `GH_WEBHOOK_SECRET` from `GH_PAT` to authenticate with the event handler

No base64 encoding. No composite secrets. No `.env` file to manage.

---

## Checklist

- [ ] Create GitHub Classic PAT with `repo` + `workflow` scopes
- [ ] Get NVIDIA API key from [build.nvidia.com](https://build.nvidia.com)
- [ ] Create Telegram bot via @BotFather
- [ ] Set 3 GitHub Secrets: `GH_PAT`, `NVIDIA_API_KEY`, `TELEGRAM_BOT_TOKEN`
- [ ] Trigger event handler workflow (push to main or manual dispatch)
- [ ] Get your Telegram chat ID and set `TELEGRAM_CHAT_ID` secret
- [ ] (Optional) Set `IMAGE_URL` variable to build your own Docker image
