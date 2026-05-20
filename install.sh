#!/usr/bin/env bash
# Storybook-First with Figma — module installer
# Installs the workflow manual, BMad dev-story customization, Figma MCP config,
# visual-check script, and sprint scaffolding into a target project.

set -euo pipefail

# ─── Locate package root (where this script lives) ─────────────────────────
PKG_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES="${PKG_ROOT}/templates"

# ─── Defaults ──────────────────────────────────────────────────────────────
TARGET=""
FIGMA_FILE_KEY=""
FIGMA_FILE_NAME=""
NODE_ID_ATOMS=""
NODE_ID_MOLECULES=""
NODE_ID_ORGANISMS=""
NODE_ID_SCREEN=""
NON_INTERACTIVE=0
DRY_RUN=0
FORCE=0

# ─── ANSI helpers ──────────────────────────────────────────────────────────
if [ -t 1 ]; then
  BOLD='\033[1m'; DIM='\033[2m'; GREEN='\033[32m'; YELLOW='\033[33m'
  RED='\033[31m'; CYAN='\033[36m'; RESET='\033[0m'
else
  BOLD=''; DIM=''; GREEN=''; YELLOW=''; RED=''; CYAN=''; RESET=''
fi

log()  { printf "${CYAN}▸${RESET} %s\n" "$*"; }
ok()   { printf "${GREEN}✓${RESET} %s\n" "$*"; }
warn() { printf "${YELLOW}!${RESET} %s\n" "$*" >&2; }
die()  { printf "${RED}✗${RESET} %s\n" "$*" >&2; exit 1; }

# ─── Usage ─────────────────────────────────────────────────────────────────
usage() {
  cat <<EOF
${BOLD}Storybook-First with Figma — installer${RESET}

  Drops the BMad workflow customization, Figma MCP wiring, visual-check
  script, and sprint scaffolding into a target project.

${BOLD}Usage:${RESET}
  install.sh [TARGET_DIR] [options]

${BOLD}Options:${RESET}
  --file-key KEY        Figma file key (the part after /design/)
  --file-name NAME      Slugified file name (kebab-case in URLs)
  --atoms ID            Node-id of the Atoms frame (e.g. 4:581)
  --molecules ID        Node-id of the Molecules frame
  --organisms ID        Node-id of the Organisms frame
  --screen ID           Node-id of the full-screen frame
  -y, --yes             Non-interactive (use defaults / fail on missing)
  -n, --dry-run         Print actions; don't write
  -f, --force           Overwrite existing files (default: skip with warning)
  -h, --help            This help

${BOLD}Examples:${RESET}
  install.sh ./my-project \\
    --file-key 7vcHVM7siztlW4xId0ClVZ \\
    --atoms 4:581 --molecules 4:726 \\
    --organisms 4:850 --screen 4:1015

  install.sh ./my-project     # interactive — will prompt for each value

EOF
}

# ─── Parse args ────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    -y|--yes) NON_INTERACTIVE=1; shift ;;
    -n|--dry-run) DRY_RUN=1; shift ;;
    -f|--force) FORCE=1; shift ;;
    --file-key) FIGMA_FILE_KEY="$2"; shift 2 ;;
    --file-name) FIGMA_FILE_NAME="$2"; shift 2 ;;
    --atoms) NODE_ID_ATOMS="$2"; shift 2 ;;
    --molecules) NODE_ID_MOLECULES="$2"; shift 2 ;;
    --organisms) NODE_ID_ORGANISMS="$2"; shift 2 ;;
    --screen) NODE_ID_SCREEN="$2"; shift 2 ;;
    --) shift; break ;;
    -*) die "Unknown option: $1" ;;
    *)
      if [ -z "$TARGET" ]; then TARGET="$1"; else die "Unexpected argument: $1"; fi
      shift ;;
  esac
done

# ─── Resolve target dir ────────────────────────────────────────────────────
if [ -z "$TARGET" ]; then
  if [ "$NON_INTERACTIVE" -eq 1 ]; then die "Target directory is required in non-interactive mode."; fi
  read -r -p "Target project directory [.]: " TARGET
  TARGET="${TARGET:-.}"
fi
TARGET="$(cd "$TARGET" 2>/dev/null && pwd || true)"
[ -n "$TARGET" ] && [ -d "$TARGET" ] || die "Target directory does not exist: $TARGET"

log "Target: ${BOLD}${TARGET}${RESET}"

# ─── Prompt for missing values ─────────────────────────────────────────────
prompt() {
  local var_name="$1" prompt_text="$2" default_value="${3:-}" cur_value
  cur_value="$(eval "echo \"\${$var_name}\"")"
  if [ -n "$cur_value" ]; then return; fi
  if [ "$NON_INTERACTIVE" -eq 1 ]; then
    if [ -n "$default_value" ]; then eval "$var_name=\"$default_value\""; return; fi
    die "Missing required value: $var_name (use --$(echo "$var_name" | tr '[:upper:]_' '[:lower:]-'))"
  fi
  if [ -n "$default_value" ]; then
    read -r -p "$prompt_text [$default_value]: " input
    eval "$var_name=\"\${input:-$default_value}\""
  else
    while [ -z "$cur_value" ]; do
      read -r -p "$prompt_text: " input
      cur_value="$input"
    done
    eval "$var_name=\"$cur_value\""
  fi
}

prompt FIGMA_FILE_KEY    "Figma file key (after /design/ in URL)"
prompt FIGMA_FILE_NAME   "Figma file slug (kebab-case in URL)" "your-figma-file"
prompt NODE_ID_ATOMS     "Atoms node-id (e.g. 4:581)"
prompt NODE_ID_MOLECULES "Molecules node-id"
prompt NODE_ID_ORGANISMS "Organisms node-id"
prompt NODE_ID_SCREEN    "Screen node-id"

# ─── Derived URL-form node-ids (colon → dash) ──────────────────────────────
NODE_ATOMS_URL="${NODE_ID_ATOMS//:/-}"
NODE_MOLECULES_URL="${NODE_ID_MOLECULES//:/-}"
NODE_ORGANISMS_URL="${NODE_ID_ORGANISMS//:/-}"
NODE_SCREEN_URL="${NODE_ID_SCREEN//:/-}"

# ─── Summary + confirm ─────────────────────────────────────────────────────
cat <<EOF

${BOLD}Will install with these values:${RESET}
  ${DIM}FIGMA_FILE_KEY    =${RESET} ${FIGMA_FILE_KEY}
  ${DIM}FIGMA_FILE_NAME   =${RESET} ${FIGMA_FILE_NAME}
  ${DIM}NODE_ID_ATOMS     =${RESET} ${NODE_ID_ATOMS}  (URL form: ${NODE_ATOMS_URL})
  ${DIM}NODE_ID_MOLECULES =${RESET} ${NODE_ID_MOLECULES}  (URL form: ${NODE_MOLECULES_URL})
  ${DIM}NODE_ID_ORGANISMS =${RESET} ${NODE_ID_ORGANISMS}  (URL form: ${NODE_ORGANISMS_URL})
  ${DIM}NODE_ID_SCREEN    =${RESET} ${NODE_ID_SCREEN}  (URL form: ${NODE_SCREEN_URL})

EOF

if [ "$NON_INTERACTIVE" -eq 0 ]; then
  read -r -p "Proceed? [Y/n] " confirm
  case "${confirm:-Y}" in
    [Nn]*) die "Aborted." ;;
  esac
fi

# ─── Copy + substitute ─────────────────────────────────────────────────────
write_file() {
  local src="$1" dest="$2" mode="${3:-0644}"
  local dest_dir
  dest_dir="$(dirname "$dest")"
  if [ -e "$dest" ] && [ "$FORCE" -eq 0 ]; then
    warn "Skip (exists): $dest  — pass --force to overwrite"
    return
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    printf "  ${DIM}would write${RESET} %s\n" "$dest"
    return
  fi
  mkdir -p "$dest_dir"
  # Read source, substitute placeholders, write to destination
  sed \
    -e "s|7vcHVM7siztlW4xId0ClVZ|${FIGMA_FILE_KEY}|g" \
    -e "s|story-book-fisrt-demo|${FIGMA_FILE_NAME}|g" \
    -e "s|node-id=4-581|node-id=${NODE_ATOMS_URL}|g" \
    -e "s|node-id=4-726|node-id=${NODE_MOLECULES_URL}|g" \
    -e "s|node-id=4-850|node-id=${NODE_ORGANISMS_URL}|g" \
    -e "s|node-id=4-1015|node-id=${NODE_SCREEN_URL}|g" \
    -e "s|\\b4:581\\b|${NODE_ID_ATOMS}|g" \
    -e "s|\\b4:726\\b|${NODE_ID_MOLECULES}|g" \
    -e "s|\\b4:850\\b|${NODE_ID_ORGANISMS}|g" \
    -e "s|\\b4:1015\\b|${NODE_ID_SCREEN}|g" \
    -e "s|__FIGMA_FILE_KEY__|${FIGMA_FILE_KEY}|g" \
    "$src" > "$dest"
  chmod "$mode" "$dest"
  ok "Wrote $dest"
}

copy_binary() {
  local src="$1" dest="$2"
  if [ -e "$dest" ] && [ "$FORCE" -eq 0 ]; then
    warn "Skip (exists): $dest  — pass --force to overwrite"
    return
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    printf "  ${DIM}would copy${RESET}  %s\n" "$dest"
    return
  fi
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  ok "Wrote $dest"
}

append_file() {
  local src="$1" dest="$2"
  if [ "$DRY_RUN" -eq 1 ]; then
    printf "  ${DIM}would append${RESET} %s\n" "$dest"
    return
  fi
  mkdir -p "$(dirname "$dest")"
  # Idempotency: only append if our marker isn't already there
  local marker="--- Storybook-First with Figma module ---"
  if [ -f "$dest" ] && grep -qF "$marker" "$dest" 2>/dev/null; then
    warn "Already appended to $dest — skipping"
    return
  fi
  cat "$src" >> "$dest"
  ok "Appended to $dest"
}

log "Installing files…"
write_file  "${TEMPLATES}/docs/workflows/storybook-first-with-figma.md"          "${TARGET}/docs/workflows/storybook-first-with-figma.md"
copy_binary "${TEMPLATES}/docs/workflows/storybook-first-with-figma.svg"         "${TARGET}/docs/workflows/storybook-first-with-figma.svg"
write_file  "${TEMPLATES}/_bmad/custom/bmad-dev-story.toml"                      "${TARGET}/_bmad/custom/bmad-dev-story.toml"
write_file  "${TEMPLATES}/_bmad-output/implementation-artifacts/README.md"       "${TARGET}/_bmad-output/implementation-artifacts/README.md"
write_file  "${TEMPLATES}/_bmad-output/implementation-artifacts/sprint-status.yaml" "${TARGET}/_bmad-output/implementation-artifacts/sprint-status.yaml"
write_file  "${TEMPLATES}/_bmad-output/implementation-artifacts/1-1-bootstrap-and-tokens.md" "${TARGET}/_bmad-output/implementation-artifacts/1-1-bootstrap-and-tokens.md"
write_file  "${TEMPLATES}/_bmad-output/implementation-artifacts/1-2-0-atoms-discovery.md"    "${TARGET}/_bmad-output/implementation-artifacts/1-2-0-atoms-discovery.md"
write_file  "${TEMPLATES}/_bmad-output/implementation-artifacts/_atom-story-template.md"     "${TARGET}/_bmad-output/implementation-artifacts/_atom-story-template.md"
write_file  "${TEMPLATES}/_bmad-output/implementation-artifacts/1-3-molecules.md"            "${TARGET}/_bmad-output/implementation-artifacts/1-3-molecules.md"
write_file  "${TEMPLATES}/_bmad-output/implementation-artifacts/1-4-organisms.md"            "${TARGET}/_bmad-output/implementation-artifacts/1-4-organisms.md"
write_file  "${TEMPLATES}/_bmad-output/implementation-artifacts/1-5-screen.md"               "${TARGET}/_bmad-output/implementation-artifacts/1-5-screen.md"
write_file  "${TEMPLATES}/scripts/visual-check.mjs"                              "${TARGET}/scripts/visual-check.mjs" "0755"
write_file  "${TEMPLATES}/dotfiles/mcp.json"                                     "${TARGET}/.mcp.json"
write_file  "${TEMPLATES}/dotfiles/env.example"                                  "${TARGET}/.env.example"
append_file "${TEMPLATES}/dotfiles/gitignore.append"                             "${TARGET}/.gitignore"

# ─── Post-install summary ──────────────────────────────────────────────────
cat <<EOF

${GREEN}${BOLD}✓ Module installed.${RESET}

${BOLD}Next steps:${RESET}
  1. In Claude Code, run ${CYAN}/mcp${RESET} and approve the ${BOLD}figma${RESET} server.
  2. Copy ${CYAN}.env.example${RESET} to ${CYAN}.env${RESET} and set ${BOLD}FIGMA_TOKEN${RESET}
     (mint one at https://www.figma.com/settings → Personal access tokens).
  3. Install runtime deps (the dev agent will guide on first run, or do it now):
       ${DIM}pnpm i -D playwright @playwright/test dotenv${RESET}
       ${DIM}pnpm exec playwright install chromium${RESET}
  4. Add this to your ${CYAN}package.json${RESET} ${BOLD}scripts${RESET}:
       ${DIM}"visual:check": "node scripts/visual-check.mjs"${RESET}
  5. Start the sprint:
       ${DIM}> dev the next story${RESET}    (in Claude Code, picks up Story 1.1)

${BOLD}Docs:${RESET}
  • Manual:  docs/workflows/storybook-first-with-figma.md
  • Sprint:  _bmad-output/implementation-artifacts/README.md

EOF
