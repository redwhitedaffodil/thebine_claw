#!/usr/bin/env bash
# =============================================================================
# OpenClaw × Google Antigravity — Patch Script (Linux/Ubuntu)
# For use with openclaw-session.yml (ubuntu-latest)
#
# OpenClaw is installed via: npm install -g openclaw
# with NPM_CONFIG_PREFIX=$HOME/.npm-global
# so the installation lives at: $HOME/.npm-global/lib/node_modules/openclaw
#
# Run after every `npm update -g openclaw` to reapply all fixes.
# Usage: bash patch.sh [--dry-run]
# =============================================================================

set -euo pipefail

# Detect OpenClaw installation directory
# Priority: custom dir > npm global prefix > pnpm global > npm default
if [[ -n "${NPM_CONFIG_PREFIX:-}" && -d "$NPM_CONFIG_PREFIX/lib/node_modules/openclaw" ]]; then
    OPENCLAW_DIR="$NPM_CONFIG_PREFIX/lib/node_modules/openclaw"
elif [[ -d "$HOME/.npm-global/lib/node_modules/openclaw" ]]; then
    OPENCLAW_DIR="$HOME/.npm-global/lib/node_modules/openclaw"
elif [[ -d "$HOME/apps/openclaw" ]]; then
    OPENCLAW_DIR="$HOME/apps/openclaw"
elif command -v pnpm &>/dev/null && pnpm root -g &>/dev/null 2>&1; then
    OPENCLAW_DIR="$(pnpm root -g)/openclaw"
elif command -v npm &>/dev/null; then
    OPENCLAW_DIR="$(npm root -g)/openclaw"
else
    echo -e "\033[0;31m[✗]\033[0m Cannot find OpenClaw installation"
    exit 1
fi

if [[ ! -d "$OPENCLAW_DIR" ]]; then
    echo -e "\033[0;31m[✗]\033[0m OpenClaw directory does not exist: $OPENCLAW_DIR"
    exit 1
fi

# Detect pi-ai location — pnpm uses flat .pnpm structure with version hashes
PI_AI_DIR=$(find "$OPENCLAW_DIR/node_modules" -name "google-gemini-cli.js" -path "*/providers/*" 2>/dev/null | head -1 | sed 's|/dist/providers/google-gemini-cli.js||')
if [[ -z "$PI_AI_DIR" ]]; then
    echo -e "\033[0;31m[✗]\033[0m Cannot find @mariozechner/pi-ai in $OPENCLAW_DIR"
    exit 1
fi
DIST="$OPENCLAW_DIR/dist"
ANTIGRAVITY_VERSION="1.18.4"
PLATFORM="linux/amd64"

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

log()  { echo -e "${GREEN}[✓]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
fail() { echo -e "${RED}[✗]${NC} $*"; exit 1; }

patch_file() {
    local file="$1" from="$2" to="$3" desc="$4"
    if ! grep -qF "$from" "$file"; then
        if grep -qF "$to" "$file"; then
            warn "$desc — already patched, skipping"
        else
            warn "$desc — pattern not found in $(basename $file), may need manual update"
        fi
        return
    fi
    if $DRY_RUN; then
        log "[DRY RUN] Would patch: $desc"
        return
    fi
    cp "$file" "$file.prepatch.bak"
    python3 -c "
import sys
with open('$file', 'r') as f:
    content = f.read()
patched = content.replace($(printf '%s' "$from" | python3 -c "import sys; print(repr(sys.stdin.read()))"), $(printf '%s' "$to" | python3 -c "import sys; print(repr(sys.stdin.read()))"))
if patched == content:
    sys.exit(1)
with open('$file', 'w') as f:
    f.write(patched)
"
    log "$desc"
}

# =============================================================================
echo ""
echo "OpenClaw Antigravity Patch (Linux)"
echo "OpenClaw dir: $OPENCLAW_DIR"
echo "pi-ai dir:    $PI_AI_DIR"
$DRY_RUN && echo -e "${YELLOW}DRY RUN MODE — no files will be modified${NC}"
echo ""

# =============================================================================
# 1. google-gemini-cli.js — version, platform
# =============================================================================
GEMINI_CLI="$PI_AI_DIR/dist/providers/google-gemini-cli.js"
[[ -f "$GEMINI_CLI" ]] || fail "Not found: $GEMINI_CLI"

# Version: regex match any semver DEFAULT_ANTIGRAVITY_VERSION
if grep -qP 'const DEFAULT_ANTIGRAVITY_VERSION = "'"$ANTIGRAVITY_VERSION"'"' "$GEMINI_CLI"; then
    warn "google-gemini-cli: version already $ANTIGRAVITY_VERSION, skipping"
elif grep -qP 'const DEFAULT_ANTIGRAVITY_VERSION = "\d+\.\d+\.\d+"' "$GEMINI_CLI"; then
    if $DRY_RUN; then
        log "[DRY RUN] Would patch: google-gemini-cli version → $ANTIGRAVITY_VERSION"
    else
        CURRENT_VER=$(grep -oP 'const DEFAULT_ANTIGRAVITY_VERSION = "\K\d+\.\d+\.\d+' "$GEMINI_CLI")
        cp "$GEMINI_CLI" "$GEMINI_CLI.prepatch.bak"
        sed -i "s/const DEFAULT_ANTIGRAVITY_VERSION = \"[0-9]*\.[0-9]*\.[0-9]*\"/const DEFAULT_ANTIGRAVITY_VERSION = \"$ANTIGRAVITY_VERSION\"/" "$GEMINI_CLI"
        log "google-gemini-cli: version $CURRENT_VER → $ANTIGRAVITY_VERSION"
    fi
else
    warn "google-gemini-cli: DEFAULT_ANTIGRAVITY_VERSION pattern not found, may need manual update"
fi

# Platform: regex match any platform string after antigravity/${version}
if grep -qF 'antigravity/${version} '"$PLATFORM" "$GEMINI_CLI"; then
    warn "google-gemini-cli: platform already $PLATFORM, skipping"
elif grep -qP 'antigravity/\$\{version\} [a-z]+/[a-z0-9]+' "$GEMINI_CLI"; then
    if $DRY_RUN; then
        log "[DRY RUN] Would patch: google-gemini-cli platform → $PLATFORM"
    else
        CURRENT_PLAT=$(grep -oP 'antigravity/\$\{version\} \K[a-z]+/[a-z0-9]+' "$GEMINI_CLI")
        cp "$GEMINI_CLI" "$GEMINI_CLI.prepatch.bak"
        # Use precise pattern: platform is like darwin/arm64, linux/amd64, windows/amd64
        sed -i "s|antigravity/\${version} [a-z]*/[a-z0-9]*|antigravity/\${version} $PLATFORM|" "$GEMINI_CLI"
        log "google-gemini-cli: platform $CURRENT_PLAT → $PLATFORM"
    fi
else
    warn "google-gemini-cli: platform pattern not found, may need manual update"
fi

# NOTE: endpoint left as daily-cloudcode-pa.sandbox.googleapis.com (the working default)
# Previously we patched this to cloudcode-pa or daily-cloudcode-pa, but the sandbox
# endpoint is what the mjs fix scripts used when things were working.

# =============================================================================
# 2. models.generated.js — add new models
# =============================================================================
MODELS_JS="$PI_AI_DIR/dist/models.generated.js"
[[ -f "$MODELS_JS" ]] || fail "Not found: $MODELS_JS"

if grep -q '"gemini-3.1-pro-high"' "$MODELS_JS"; then
    warn "models.generated.js — new models already present, skipping"
else
    if $DRY_RUN; then
        log "[DRY RUN] Would add new models to models.generated.js"
    else
        cp "$MODELS_JS" "$MODELS_JS.prepatch.bak"
        MODELS_JS="$MODELS_JS" python3 << 'PYEOF'
import os
path = os.environ['MODELS_JS']

with open(path, 'r') as f:
    content = f.read()

new_models = '''        "gemini-3.1-pro-high": {
            id: "gemini-3.1-pro-high",
            name: "Gemini 3.1 Pro High",
            api: "google-gemini-cli",
            provider: "google-antigravity",
            baseUrl: "https://daily-cloudcode-pa.sandbox.googleapis.com",
            reasoning: true,
            input: ["text", "image"],
            cost: { input: 5, output: 25, cacheRead: 0.5, cacheWrite: 6.25 },
            contextWindow: 1000000,
            maxTokens: 65535,
        },
        "claude-sonnet-4-6-thinking": {
            id: "claude-sonnet-4-6-thinking",
            name: "Claude Sonnet 4.6 Thinking",
            api: "google-gemini-cli",
            provider: "google-antigravity",
            baseUrl: "https://daily-cloudcode-pa.sandbox.googleapis.com",
            reasoning: true,
            input: ["text", "image"],
            cost: { input: 3, output: 15, cacheRead: 0.3, cacheWrite: 3.75 },
            contextWindow: 114000,
            maxTokens: 64000,
        },
        "gpt-oss-120b-medium": {
            id: "gpt-oss-120b-medium",
            name: "GPT OSS 120B Medium",
            api: "google-gemini-cli",
            provider: "google-antigravity",
            baseUrl: "https://daily-cloudcode-pa.sandbox.googleapis.com",
            reasoning: false,
            input: ["text", "image"],
            cost: { input: 3, output: 15, cacheRead: 0.3, cacheWrite: 3.75 },
            contextWindow: 1000000,
            maxTokens: 65536,
        },
'''

content = content.replace('"google-antigravity": {\n', '"google-antigravity": {\n' + new_models, 1)

# NOTE: sandbox endpoint (daily-cloudcode-pa.sandbox.googleapis.com) is left as-is
# for existing models — this is the working endpoint.

with open(path, 'w') as f:
    f.write(content)

print("OK")
PYEOF
        log "models.generated.js — added new models (sandbox endpoint preserved)"
    fi
fi

# =============================================================================
# 3. dist files — endpoint + isAnthropicProvider fix
# =============================================================================

# Find all relevant dist files dynamically (hash in filename changes per version)
PI_EMBEDDED_FILES=$(find "$DIST" -maxdepth 1 -name "pi-embedded-*.js" ! -name "pi-embedded-helpers-*" ! -name "*.bak")
REPLY_FILES=$(find "$DIST" -maxdepth 1 -name "reply-*.js" ! -name "reply-prefix-*" ! -name "*.bak")
PLUGIN_REPLY=$(find "$DIST/plugin-sdk" -maxdepth 1 -name "reply-*.js" ! -name "reply-prefix-*" ! -name "*.bak" 2>/dev/null || true)
SUBAGENT=$(find "$DIST" -maxdepth 1 -name "subagent-registry-*.js" ! -name "*.bak")

ALL_DIST_FILES="$PI_EMBEDDED_FILES $REPLY_FILES $PLUGIN_REPLY $SUBAGENT"

for f in $ALL_DIST_FILES; do
    [[ -f "$f" ]] || continue
    name=$(basename "$f")

    patch_file "$f" \
        'options?.modelProvider?.toLowerCase().includes("google-antigravity")' \
        'false' \
        "$name: isAnthropicProvider — remove google-antigravity"
done

# =============================================================================
# 4. openclaw.json — ensure correct models in allowlist, remove deprecated ones
# =============================================================================
OPENCLAW_JSON="$HOME/.openclaw/openclaw.json"

if [[ -f "$OPENCLAW_JSON" ]]; then
    if $DRY_RUN; then
        log "[DRY RUN] Would update $OPENCLAW_JSON allowlist"
    else
        python3 << PYEOF
import json

path = "$OPENCLAW_JSON"
with open(path) as f:
    config = json.load(f)

models_to_keep = [
    "google-antigravity/gemini-3.1-pro-high",
    "google-antigravity/claude-sonnet-4-6-thinking",
    "google-antigravity/gpt-oss-120b-medium",
]

existing = config.get("agents", {}).get("defaults", {}).get("models", {})

# Remove deprecated google-antigravity models not in the keep list
removed = 0
deprecated_keys = [k for k in list(existing.keys()) if k.startswith("google-antigravity/") and k not in models_to_keep]
for key in deprecated_keys:
    del existing[key]
    print(f"  removed deprecated model: {key}")
    removed += 1

# Add models that should be present
added = 0
for m in models_to_keep:
    if m not in existing:
        existing[m] = {}
        added += 1

config.setdefault("agents", {}).setdefault("defaults", {})["models"] = existing

with open(path, "w") as f:
    json.dump(config, f, indent=2)

print(f"openclaw.json allowlist updated (added {added}, removed {removed} deprecated)")
PYEOF
        log "openclaw.json allowlist updated"
    fi
else
    warn "~/.openclaw/openclaw.json not found — skipping allowlist update"
fi

# =============================================================================
# 5. models.json — ensure file exists
# =============================================================================
MODELS_JSON="$HOME/.openclaw/agents/main/agent/models.json"

if [[ ! -f "$MODELS_JSON" ]]; then
    if $DRY_RUN; then
        log "[DRY RUN] Would create $MODELS_JSON"
    else
        mkdir -p "$(dirname "$MODELS_JSON")"
        cat > "$MODELS_JSON" << 'EOF'
{
  "providers": {
    "google-antigravity": {
      "modelOverrides": {
        "gemini-3.1-pro-high": {},
        "claude-sonnet-4-6-thinking": {},
        "gpt-oss-120b-medium": {}
      }
    }
  }
}
EOF
        log "models.json created"
    fi
else
    log "models.json already exists, skipping"
fi

# =============================================================================
# 6. Validate patched JS files parse correctly
# =============================================================================
echo ""
echo "Validating patched files..."

VALIDATION_FAILED=false

GEMINI_CLI_CHECK="$PI_AI_DIR/dist/providers/google-gemini-cli.js"
MODELS_GEN_CHECK="$PI_AI_DIR/dist/models.generated.js"

for jsfile in "$GEMINI_CLI_CHECK" "$MODELS_GEN_CHECK"; do
    [[ -f "$jsfile" ]] || continue
    jsname=$(basename "$jsfile")

    # Detect ESM (import/export at start of file)
    if head -5 "$jsfile" | grep -qP '^\s*(import |export )'; then
        # ESM: pipe to node --check --input-type=module
        if node --check --input-type=module < "$jsfile" 2>/dev/null; then
            log "Validation OK: $jsname"
        else
            echo -e "${RED}[✗]${NC} Validation FAILED: $jsname"
            node --check --input-type=module < "$jsfile" 2>&1 | head -5
            VALIDATION_FAILED=true
        fi
    else
        if node --check "$jsfile" 2>/dev/null; then
            log "Validation OK: $jsname"
        else
            echo -e "${RED}[✗]${NC} Validation FAILED: $jsname"
            node --check "$jsfile" 2>&1 | head -5
            VALIDATION_FAILED=true
        fi
    fi
done

if $VALIDATION_FAILED; then
    echo ""
    echo -e "${RED}[✗] One or more patched files have syntax errors! OpenClaw may crash on startup.${NC}"
    echo -e "${YELLOW}    Check the .prepatch.bak files to restore originals.${NC}"
    echo ""
    exit 1
fi

# =============================================================================
echo ""
echo -e "${GREEN}Patch complete.${NC} Restart OpenClaw to apply changes."
echo ""
