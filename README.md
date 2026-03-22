# theninerd

**Autonomous AI agent powered by NVIDIA API + GitHub Actions + Telegram.**

---

## How It Works

```
┌───────────────────────────────────────────────────────────────────────┐
│                                                                       │
│  ┌─────────────────┐         ┌─────────────────┐                     │
│  │  Event Handler  │ ──1──►  │     GitHub      │                     │
│  │  (creates job)  │         │ (job/* branch)  │                     │
│  └────────▲────────┘         └────────┬────────┘                     │
│           │                           │                              │
│           │                           2 (triggers run-job.yml)       │
│           │                           │                              │
│           │                           ▼                              │
│           │                  ┌─────────────────┐                     │
│           │                  │  Docker Agent   │                     │
│           │                  │  (runs Pi, PRs) │                     │
│           │                  └────────┬────────┘                     │
│           │                           │                              │
│           │                           3 (creates PR)                 │
│           │                           │                              │
│           │                           ▼                              │
│           │                  ┌─────────────────┐                     │
│           │                  │     GitHub      │                     │
│           │                  │   (PR opened)   │                     │
│           │                  └────────┬────────┘                     │
│           │                           │                              │
│           │                           4a (auto-merge.yml)            │
│           │                           4b (update-event-handler.yml)  │
│           │                           │                              │
│           5 (Telegram notification)   │                              │
│           └───────────────────────────┘                              │
│                                                                       │
└───────────────────────────────────────────────────────────────────────┘
```

You talk to your bot on Telegram (or hit a webhook). The Event Handler creates a job branch. GitHub Actions spins up a Docker container with the Pi coding agent. The agent does the work, commits the results, and opens a PR. Auto-merge handles the rest. You get a Telegram notification when it's done.

---

## Requirements

- **NVIDIA API Key** (free tier at [build.nvidia.com](https://build.nvidia.com))
- **GitHub Classic PAT** with `repo` + `workflow` scopes
- **Telegram Bot Token** (from [@BotFather](https://t.me/BotFather))

---

## Setup

1. Fork this repository
2. Enable GitHub Actions in the **Actions** tab
3. Set 3 GitHub Secrets: `GH_PAT`, `NVIDIA_API_KEY`, `TELEGRAM_BOT_TOKEN` (see [KEYS_SETUP.md](KEYS_SETUP.md))
4. Push to `main` — the Event Handler starts automatically via Cloudflare Tunnel
5. Get your Telegram chat ID and set `TELEGRAM_CHAT_ID` secret
6. Message your bot

---

## Docs

| Document | Description |
|----------|-------------|
| [Keys Setup](KEYS_SETUP.md) | Every key needed, how to create it, where to put it |
| [Architecture](docs/ARCHITECTURE.md) | Two-layer design, file structure, API endpoints, GitHub Actions, Docker agent |
| [Configuration](docs/CONFIGURATION.md) | Environment variables, GitHub secrets, repo variables, Telegram setup |
| [Customization](docs/CUSTOMIZATION.md) | Personality, skills, operating system files, security details |
| [Auto-Merge](docs/AUTO_MERGE.md) | Auto-merge controls, ALLOWED_PATHS configuration |
| [How to Use Pi](docs/HOW_TO_USE_PI.md) | Guide to the Pi coding agent |
| [Security](docs/SECURITY_TODO.md) | Security hardening plan |
