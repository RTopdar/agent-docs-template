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
#   curl -fsSL <raw-url>/install.sh | bash -s -- --force        # overwrite existing files
set -euo pipefail

REPO="RTopdar/agent-docs-template"   # TODO: set to your actual GitHub owner/repo
BRANCH="master"
CAVEMAN=false
FORCE=false

for arg in "$@"; do
  case "$arg" in
    --caveman) CAVEMAN=true ;;
    --force) FORCE=true ;;
  esac
done

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

echo "Fetching template from ${REPO}@${BRANCH}..."
if command -v npx >/dev/null 2>&1; then
  npx --yes giget@2 "gh:${REPO}#${BRANCH}" "$TMPDIR" --force
else
  git clone --depth 1 --branch "$BRANCH" "https://github.com/${REPO}.git" "$TMPDIR"
  rm -rf "$TMPDIR/.git"
fi

# Copy everything except install.sh itself and the caveman config (handled below).
# By default, never clobber files already in the target directory — pass --force to overwrite.
if [ "$FORCE" = true ]; then
  echo "--force set: existing files in $(pwd) may be overwritten."
  rsync -a --exclude 'install.sh' --exclude '.caveman.json' "$TMPDIR"/ ./
else
  rsync -a --ignore-existing --exclude 'install.sh' --exclude '.caveman.json' "$TMPDIR"/ ./
  echo "Note: existing files were left untouched (pass --force to overwrite)."
fi

if [ "$CAVEMAN" = true ]; then
  echo
  echo "--caveman requested. This will:"
  echo "  1. Register the third-party plugin marketplace github.com/JuliusBrussee/caveman"
  echo "  2. Install its 'caveman' plugin globally via the claude CLI"
  echo "     (caveman rewrites agent responses into a terse, token-saving style)"
  echo "  3. Drop .caveman.json in this directory"
  if command -v claude >/dev/null 2>&1; then
    claude plugin marketplace add JuliusBrussee/caveman
    claude plugin install caveman@caveman
  else
    echo "Warning: 'claude' CLI not found — skipping plugin install. Run manually:"
    echo "  claude plugin marketplace add JuliusBrussee/caveman"
    echo "  claude plugin install caveman@caveman"
  fi
  if [ "$FORCE" = true ] || [ ! -f ./.caveman.json ]; then
    cp "$TMPDIR/.caveman.json" ./.caveman.json
    echo "Added .caveman.json"
  else
    echo ".caveman.json already exists — left untouched (pass --force to overwrite)."
  fi
else
  echo "Skipping caveman plugin (pass --caveman to install it)."
fi

echo "Done. Scaffolded: CLAUDE.md, AGENTS.md, .claude/agents/, doc/, IMPLEMENTATION_PLAN.md${CAVEMAN:+, .caveman.json}"
echo "Next: fill in {{PROJECT_NAME}} placeholders and start documenting modules under doc/feature/."
