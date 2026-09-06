#!/usr/bin/env bash
# Scaffolds this repo's agent-docs template (CLAUDE.md, AGENTS.md, .claude/agents/,
# doc/, IMPLEMENTATION_PLAN.md) into the current directory. Never overwrites files
# that already exist unless --force is passed.
#
# With --caveman, this script ALSO registers a third-party Claude Code plugin
# marketplace (github.com/JuliusBrussee/caveman) and installs its "caveman" plugin
# globally via the `claude` CLI, and drops a `.caveman.json` config file. This is
# unrelated to scaffolding and changes global Claude Code plugin state — omit
# --caveman if you don't want that.
#
# Review this script before piping it into bash, as with any install-from-curl:
#   curl -fsSL <raw-url>/install.sh -o install.sh && less install.sh && bash install.sh
#
# Usage:
#   curl -fsSL <raw-url>/install.sh | bash
#   curl -fsSL <raw-url>/install.sh | bash -s -- --caveman
#   curl -fsSL <raw-url>/install.sh | bash -s -- --force          # overwrite existing files
#   curl -fsSL <raw-url>/install.sh | bash -s -- --name "My App"  # skip the name prompt
set -euo pipefail

REPO="RTopdar/agent-docs-template"
BRANCH="master"
CAVEMAN=false
FORCE=false
PROJECT_NAME=""

for arg in "$@"; do
  case "$arg" in
    --caveman) CAVEMAN=true ;;
    --force) FORCE=true ;;
    --name=*) PROJECT_NAME="${arg#--name=}" ;;
  esac
done
# support `--name "value"` as two args
prev=""
for arg in "$@"; do
  if [ "$prev" = "--name" ]; then PROJECT_NAME="$arg"; fi
  prev="$arg"
done

# ---- presentation -----------------------------------------------------------
if [ -t 1 ] && command -v tput >/dev/null 2>&1 && [ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]; then
  BOLD="$(tput bold)"; DIM="$(tput dim)"; RESET="$(tput sgr0)"
  CYAN="$(tput setaf 6)"; GREEN="$(tput setaf 2)"; YELLOW="$(tput setaf 3)"; MAGENTA="$(tput setaf 5)"
else
  BOLD=""; DIM=""; RESET=""; CYAN=""; GREEN=""; YELLOW=""; MAGENTA=""
fi

banner() {
  printf '%s\n' "${MAGENTA}${BOLD}"
  cat <<'ART'
   ┌─────────────────────────────────────┐
   │        agent-docs-template           │
   │  AGENTS.md · CLAUDE.md · OKF docs     │
   └─────────────────────────────────────┘
ART
  printf '%s\n' "${RESET}"
}

step()  { printf '%s→%s %s\n' "${CYAN}${BOLD}" "${RESET}" "$1"; }
ok()    { printf '%s✓%s %s\n' "${GREEN}${BOLD}" "${RESET}" "$1"; }
warn()  { printf '%s!%s %s\n' "${YELLOW}${BOLD}" "${RESET}" "$1"; }
note()  { printf '%s%s%s\n' "${DIM}" "$1" "${RESET}"; }

banner

# ---- interactive project name prompt ---------------------------------------
# stdin is the piped script when run via `curl | bash`, so read the prompt from
# the controlling terminal instead. Falls back to a default if no tty is
# reachable (e.g. CI) or --name was passed.
if [ -z "$PROJECT_NAME" ]; then
  if [ -r /dev/tty ]; then
    printf '%s?%s Project name %s(used to fill {{PROJECT_NAME}} in the scaffolded docs)%s: ' \
      "${CYAN}${BOLD}" "${RESET}" "${DIM}" "${RESET}"
    read -r PROJECT_NAME < /dev/tty || true
  fi
fi
if [ -z "$PROJECT_NAME" ]; then
  PROJECT_NAME="$(basename "$(pwd)")"
  note "No tty / no name given — using current directory name: ${PROJECT_NAME}"
fi

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

step "Fetching template from ${REPO}@${BRANCH}..."
if command -v npx >/dev/null 2>&1; then
  npx --yes giget@2 "gh:${REPO}#${BRANCH}" "$TMPDIR" --force >/dev/null
else
  git clone --depth 1 --branch "$BRANCH" "https://github.com/${REPO}.git" "$TMPDIR" >/dev/null 2>&1
  rm -rf "$TMPDIR/.git"
fi
ok "Template fetched"

# Fill in the project name across every text file in the fetched template.
find "$TMPDIR" -type f -name '*.md' -exec sed -i.bak "s/{{PROJECT_NAME}}/${PROJECT_NAME//\//\\/}/g" {} \; \
  -exec rm -f {}.bak \;

# Copy everything except install.sh itself and the caveman config (handled below).
# By default, never clobber files already in the target directory — pass --force to overwrite.
step "Scaffolding files into $(pwd)..."
if [ "$FORCE" = true ]; then
  warn "--force set: existing files in $(pwd) may be overwritten."
  rsync -a --exclude 'install.sh' --exclude '.caveman.json' "$TMPDIR"/ ./
else
  rsync -a --ignore-existing --exclude 'install.sh' --exclude '.caveman.json' "$TMPDIR"/ ./
  note "Existing files were left untouched (pass --force to overwrite)."
fi
ok "Files scaffolded"

if [ "$CAVEMAN" = true ]; then
  echo
  step "--caveman requested. This will:"
  note "  1. Register the third-party plugin marketplace github.com/JuliusBrussee/caveman"
  note "  2. Install its 'caveman' plugin globally via the claude CLI"
  note "     (caveman rewrites agent responses into a terse, token-saving style)"
  note "  3. Drop .caveman.json in this directory"
  if command -v claude >/dev/null 2>&1; then
    claude plugin marketplace add JuliusBrussee/caveman
    claude plugin install caveman@caveman
    ok "caveman plugin installed"
  else
    warn "'claude' CLI not found — skipping plugin install. Run manually:"
    note "  claude plugin marketplace add JuliusBrussee/caveman"
    note "  claude plugin install caveman@caveman"
  fi
  if [ "$FORCE" = true ] || [ ! -f ./.caveman.json ]; then
    cp "$TMPDIR/.caveman.json" ./.caveman.json
    ok "Added .caveman.json"
  else
    note ".caveman.json already exists — left untouched (pass --force to overwrite)."
  fi
else
  note "Skipping caveman plugin (pass --caveman to install it)."
fi

SCAFFOLDED_LIST="CLAUDE.md, AGENTS.md, .claude/agents/, doc/, IMPLEMENTATION_PLAN.md"
if [ "$CAVEMAN" = true ]; then SCAFFOLDED_LIST="${SCAFFOLDED_LIST}, .caveman.json"; fi

echo
printf '%s%s%s %s\n' "${GREEN}${BOLD}" "Done." "${RESET}" "Scaffolded for ${BOLD}${PROJECT_NAME}${RESET}:"
note "  ${SCAFFOLDED_LIST}"
step "Next: fill in IMPLEMENTATION_PLAN.md and start documenting modules under doc/feature/."
