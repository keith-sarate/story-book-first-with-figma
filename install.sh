#!/usr/bin/env bash
# Storybook-First with Figma — module installer
# Installs the workflow manual, BMad dev-story customization, Figma MCP config,
# and visual-check script into a target project. Also wires package.json,
# copies .env.example → .env (token left empty — agent guides user at first run),
# and installs Playwright + dotenv.
#
# Two ways to run:
#   1. Clone the repo, then run ./install.sh /target/path
#   2. One-liner from inside your project root (no clone needed):
#        bash <(curl -fsSL https://raw.githubusercontent.com/keith-sarate/story-book-first-with-figma/main/install.sh)
#      The script detects it is running standalone and fetches its own templates.

set -euo pipefail

REPO_URL="https://github.com/keith-sarate/story-book-first-with-figma.git"

# ─── Locate package root (where this script lives) ─────────────────────────
# If the script is invoked from a real path with a sibling templates/ folder,
# use that. Otherwise (curl|bash, process substitution, no templates/ next to
# the script), clone the repo to a temp dir so we have templates/ available.

if [ -n "${BASH_SOURCE[0]:-}" ] \
   && [ -f "${BASH_SOURCE[0]}" ] \
   && [ -d "$(dirname "${BASH_SOURCE[0]}")/templates" ]; then
  PKG_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
  echo "▸ Standalone run — fetching module from ${REPO_URL}..." >&2
  PKG_ROOT="$(mktemp -d -t sb-figma-XXXXXX)"
  trap "rm -rf '${PKG_ROOT}'" EXIT INT TERM
  if ! git clone --depth 1 --quiet "${REPO_URL}" "${PKG_ROOT}" >/dev/null 2>&1; then
    echo "✗ Failed to clone ${REPO_URL}" >&2
    exit 1
  fi
fi
TEMPLATES="${PKG_ROOT}/templates"

# ─── Defaults ──────────────────────────────────────────────────────────────
TARGET=""
FIGMA_FILE_KEY=""
PM=""                  # package manager: pnpm | yarn | npm | bun (auto-detected)
MODE="bmad"            # bmad = BMad-compatible (default) | skill = Claude Code skill (no BMad)
INSTALL_DEPS=1         # 1 = auto-install playwright + dotenv; --no-install-deps to skip
WRITE_PKG_SCRIPT=1     # 1 = add scripts.visual:check to package.json; --no-package-json to skip
COPY_DOTENV=1          # 1 = create .env from .env.example; --no-dotenv to skip
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

  Drops the BMad workflow customization, Figma MCP wiring, and visual-check
  script into a target project. By default it also: copies .env.example to
  .env (with the file key prefilled, FIGMA_TOKEN left empty), adds the
  visual:check script to package.json, and installs Playwright + dotenv via
  the detected package manager.

  The Figma token is NOT requested here — the dev agent's preflight check
  guides the user to set it the first time a UI story is run.

${BOLD}Usage:${RESET}
  install.sh [TARGET_DIR] [options]

${BOLD}Options:${RESET}
  --mode bmad|skill     Install flavor (default: bmad)
                          bmad  → drops _bmad/custom/bmad-dev-story.toml; runs via /bmad-dev-story
                          skill → drops .claude/skills/storybook-figma/SKILL.md; runs via /storybook-figma
  --file-key KEY        Figma file key (the part after /design/)
  --pm pnpm|yarn|npm|bun   Force package manager (default: auto-detect via lockfile)
  --no-install-deps     Skip installing Playwright + dotenv
  --no-package-json     Skip adding scripts.visual:check to package.json
  --no-dotenv           Skip creating .env from .env.example
  -y, --yes             Non-interactive (use defaults / fail on missing)
  -n, --dry-run         Print actions; don't write
  -f, --force           Overwrite existing files (default: skip with warning)
  -h, --help            This help

${BOLD}Examples:${RESET}
  install.sh ./my-project --file-key 7vcHVM7siztlW4xId0ClVZ
  install.sh ./my-project     # interactive — will prompt for the file key

  # Standalone Claude Code skill (no BMad dependency):
  install.sh ./my-project --mode skill --file-key KEY

  # CI / scripting — everything inline, no prompts:
  install.sh ./my-project -y --file-key KEY --pm pnpm

EOF
}

# ─── Parse args ────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    -y|--yes) NON_INTERACTIVE=1; shift ;;
    -n|--dry-run) DRY_RUN=1; shift ;;
    -f|--force) FORCE=1; shift ;;
    --mode) MODE="$2"; shift 2 ;;
    --file-key) FIGMA_FILE_KEY="$2"; shift 2 ;;
    --pm) PM="$2"; shift 2 ;;
    --no-install-deps) INSTALL_DEPS=0; shift ;;
    --no-package-json) WRITE_PKG_SCRIPT=0; shift ;;
    --no-dotenv) COPY_DOTENV=0; shift ;;
    --) shift; break ;;
    -*) die "Unknown option: $1" ;;
    *)
      if [ -z "$TARGET" ]; then TARGET="$1"; else die "Unexpected argument: $1"; fi
      shift ;;
  esac
done

case "$MODE" in
  bmad|skill) ;;
  *) die "Invalid --mode: $MODE (expected 'bmad' or 'skill')" ;;
esac

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

prompt FIGMA_FILE_KEY "Figma file key (after /design/ in URL)"

# ─── Detect package manager + package.json presence ───────────────────────
detect_pm() {
  if [ -n "$PM" ]; then return; fi
  if   [ -f "$TARGET/pnpm-lock.yaml" ];   then PM="pnpm"
  elif [ -f "$TARGET/yarn.lock" ];        then PM="yarn"
  elif [ -f "$TARGET/bun.lockb" ];        then PM="bun"
  elif [ -f "$TARGET/package-lock.json" ]; then PM="npm"
  fi
}
detect_pm

HAS_PKG_JSON=0
[ -f "$TARGET/package.json" ] && HAS_PKG_JSON=1

# ─── Summary + confirm ─────────────────────────────────────────────────────
fmt_pm()  { [ -n "$PM" ] && echo "$PM" || echo "(no lockfile detected)"; }
fmt_pkg() { [ "$HAS_PKG_JSON" -eq 1 ] && echo "found" || echo "not found"; }
fmt_deps() {
  if [ "$INSTALL_DEPS" -eq 0 ]; then echo "skipped (--no-install-deps)"
  elif [ "$HAS_PKG_JSON" -eq 0 ]; then echo "skipped (no package.json)"
  elif [ -z "$PM" ]; then echo "skipped (no package manager detected — pass --pm to force)"
  else echo "yes via $PM"
  fi
}
fmt_pkg_script() {
  if [ "$WRITE_PKG_SCRIPT" -eq 0 ]; then echo "skipped (--no-package-json)"
  elif [ "$HAS_PKG_JSON" -eq 0 ]; then echo "skipped (no package.json)"
  else echo "yes"
  fi
}
fmt_dotenv() {
  if [ "$COPY_DOTENV" -eq 0 ]; then echo "skipped (--no-dotenv)"
  else echo "yes (FIGMA_TOKEN left empty — agent guides user to fill it at first run)"
  fi
}

fmt_mode() {
  if [ "$MODE" = "skill" ]; then echo "skill (Claude Code skill — no BMad needed)"
  else echo "bmad (BMad-compatible — default)"
  fi
}

cat <<EOF

${BOLD}Will install with these values:${RESET}
  ${DIM}mode                =${RESET} $(fmt_mode)
  ${DIM}FIGMA_FILE_KEY      =${RESET} ${FIGMA_FILE_KEY}
  ${DIM}package manager     =${RESET} $(fmt_pm)
  ${DIM}package.json        =${RESET} $(fmt_pkg)
  ${DIM}add visual:check    =${RESET} $(fmt_pkg_script)
  ${DIM}create .env         =${RESET} $(fmt_dotenv)
  ${DIM}install deps        =${RESET} $(fmt_deps)

EOF

if [ "$NON_INTERACTIVE" -eq 0 ]; then
  read -r -p "Proceed? [Y/n] " confirm
  case "${confirm:-Y}" in
    [Nn]*) die "Aborted." ;;
  esac
fi

# ─── File ops ──────────────────────────────────────────────────────────────
write_file() {
  local src="$1" dest="$2" mode="${3:-0644}"
  local dest_dir; dest_dir="$(dirname "$dest")"
  if [ -e "$dest" ] && [ "$FORCE" -eq 0 ]; then
    warn "Skip (exists): $dest  — pass --force to overwrite"
    return
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    printf "  ${DIM}would write${RESET} %s\n" "$dest"; return
  fi
  mkdir -p "$dest_dir"
  sed -e "s|__FIGMA_FILE_KEY__|${FIGMA_FILE_KEY}|g" "$src" > "$dest"
  chmod "$mode" "$dest"
  ok "Wrote $dest"
}

copy_binary() {
  local src="$1" dest="$2"
  if [ -e "$dest" ] && [ "$FORCE" -eq 0 ]; then
    warn "Skip (exists): $dest  — pass --force to overwrite"; return
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    printf "  ${DIM}would copy${RESET}  %s\n" "$dest"; return
  fi
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  ok "Wrote $dest"
}

append_file() {
  local src="$1" dest="$2"
  if [ "$DRY_RUN" -eq 1 ]; then
    printf "  ${DIM}would append${RESET} %s\n" "$dest"; return
  fi
  mkdir -p "$(dirname "$dest")"
  local marker="--- Storybook-First with Figma module ---"
  if [ -f "$dest" ] && grep -qF -- "$marker" "$dest" 2>/dev/null; then
    warn "Already appended to $dest — skipping"; return
  fi
  cat "$src" >> "$dest"
  ok "Appended to $dest"
}

copy_dotenv() {
  if [ "$COPY_DOTENV" -eq 0 ]; then return; fi
  local src="${TARGET}/.env.example" dest="${TARGET}/.env"
  if [ "$DRY_RUN" -eq 1 ]; then
    printf "  ${DIM}would copy${RESET}  .env.example → .env (mode 0600, FIGMA_TOKEN empty)\n"; return
  fi
  if [ ! -f "$src" ]; then
    warn ".env.example not present — skip .env creation"; return
  fi
  if [ -e "$dest" ] && [ "$FORCE" -eq 0 ]; then
    warn "Skip (exists): $dest  — pass --force to overwrite"; return
  fi
  cp "$src" "$dest"
  chmod 0600 "$dest"
  ok "Created $dest (mode 0600 — fill FIGMA_TOKEN before first run)"
}

update_package_json() {
  local pkg_file="${TARGET}/package.json"
  if [ "$WRITE_PKG_SCRIPT" -eq 0 ]; then return; fi
  if [ "$HAS_PKG_JSON" -eq 0 ]; then
    warn "No package.json — skip scripts.visual:check (add manually after \`npm init\`: \"visual:check\": \"node scripts/visual-check.mjs\")"
    return
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    printf "  ${DIM}would update${RESET} %s (add scripts.visual:check)\n" "$pkg_file"
    return
  fi
  if ! command -v node >/dev/null 2>&1; then
    warn "node not on PATH — skip package.json update (add scripts.visual:check manually)"
    return
  fi
  PKG_PATH="$pkg_file" node -e '
    const fs = require("fs");
    const file = process.env.PKG_PATH;
    const raw = fs.readFileSync(file, "utf8");
    const obj = JSON.parse(raw);
    obj.scripts = obj.scripts || {};
    const desired = "node scripts/visual-check.mjs";
    if (obj.scripts["visual:check"] && obj.scripts["visual:check"] !== desired) {
      console.error("  ! package.json already has a different visual:check (" + obj.scripts["visual:check"] + ") — leaving it");
      process.exit(0);
    }
    if (obj.scripts["visual:check"] === desired) {
      console.error("  · scripts.visual:check already set — no change");
      process.exit(0);
    }
    obj.scripts["visual:check"] = desired;
    const m = raw.match(/^( +)/m);
    const indent = m ? m[1].length : 2;
    fs.writeFileSync(file, JSON.stringify(obj, null, indent) + (raw.endsWith("\n") ? "\n" : ""));
    console.error("  + Added scripts.visual:check to package.json");
  '
}

install_deps() {
  if [ "$INSTALL_DEPS" -eq 0 ]; then return; fi
  if [ "$HAS_PKG_JSON" -eq 0 ]; then
    warn "No package.json — skip dep install. After \`npm init\`, run: <pm> add -D playwright @playwright/test dotenv && <pm> exec playwright install chromium"
    return
  fi
  if [ -z "$PM" ]; then
    warn "No package manager detected — skip dep install. Pass --pm pnpm|yarn|npm|bun to force, or run manually."
    return
  fi
  if ! command -v "$PM" >/dev/null 2>&1; then
    warn "$PM not on PATH — skip dep install. Install $PM or pass --pm <other>."
    return
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    printf "  ${DIM}would run${RESET} %s add -D playwright @playwright/test dotenv\n" "$PM"
    printf "  ${DIM}would run${RESET} %s exec playwright install chromium\n" "$PM"
    return
  fi
  log "Installing Playwright + dotenv via ${BOLD}${PM}${RESET} (this can take a minute — Chromium download is ~150 MB)…"
  case "$PM" in
    pnpm) (cd "$TARGET" && pnpm i -D playwright @playwright/test dotenv && pnpm exec playwright install chromium) ;;
    yarn) (cd "$TARGET" && yarn add -D playwright @playwright/test dotenv && yarn exec playwright install chromium) ;;
    npm)  (cd "$TARGET" && npm  i -D playwright @playwright/test dotenv && npx  playwright install chromium) ;;
    bun)  (cd "$TARGET" && bun  add -d playwright @playwright/test dotenv && bunx playwright install chromium) ;;
    *) warn "Unknown PM: $PM — skip dep install"; return ;;
  esac
  ok "Playwright + dotenv installed"
}

log "Installing files…"
write_file  "${TEMPLATES}/docs/workflows/storybook-first-with-figma.md"  "${TARGET}/docs/workflows/storybook-first-with-figma.md"
copy_binary "${TEMPLATES}/docs/workflows/storybook-first-with-figma.svg" "${TARGET}/docs/workflows/storybook-first-with-figma.svg"
if [ "$MODE" = "skill" ]; then
  write_file "${TEMPLATES}/skill/storybook-figma/SKILL.md"               "${TARGET}/.claude/skills/storybook-figma/SKILL.md"
else
  write_file "${TEMPLATES}/_bmad/custom/bmad-dev-story.toml"             "${TARGET}/_bmad/custom/bmad-dev-story.toml"
fi
write_file  "${TEMPLATES}/scripts/visual-check.mjs"                      "${TARGET}/scripts/visual-check.mjs" "0755"
write_file  "${TEMPLATES}/dotfiles/mcp.json"                             "${TARGET}/.mcp.json"
write_file  "${TEMPLATES}/dotfiles/env.example"                          "${TARGET}/.env.example"
append_file "${TEMPLATES}/dotfiles/gitignore.append"                     "${TARGET}/.gitignore"

copy_dotenv
update_package_json
install_deps

# ─── Post-install summary ──────────────────────────────────────────────────
DOTENV_STATUS="$([ "$COPY_DOTENV" -eq 1 ] && echo "ready" || echo "PENDING")"
DEPS_STATUS="$([ "$INSTALL_DEPS" -eq 1 ] && [ "$HAS_PKG_JSON" -eq 1 ] && [ -n "$PM" ] && echo "ready" || echo "PENDING")"
SCRIPT_STATUS="$([ "$WRITE_PKG_SCRIPT" -eq 1 ] && [ "$HAS_PKG_JSON" -eq 1 ] && echo "ready" || echo "PENDING")"

cat <<EOF

${GREEN}${BOLD}✓ Module installed.${RESET}

${BOLD}Status:${RESET}
  • Figma MCP registered in .mcp.json                       ${GREEN}ready${RESET} (needs /mcp approval)
  • .env created from .env.example                          $([ "$DOTENV_STATUS" = "ready" ] && printf "${GREEN}ready${RESET} (FIGMA_TOKEN empty — fill before first run)" || printf "${YELLOW}skipped${RESET}")
  • Playwright + dotenv installed                           $([ "$DEPS_STATUS" = "ready" ] && printf "${GREEN}ready${RESET}" || printf "${YELLOW}PENDING — install manually${RESET}")
  • package.json scripts.visual:check                       $([ "$SCRIPT_STATUS" = "ready" ] && printf "${GREEN}ready${RESET}" || printf "${YELLOW}PENDING — add manually${RESET}")

${BOLD}One thing you have to do now:${RESET}
  • Open ${CYAN}.env${RESET} and paste a Figma personal access token in ${BOLD}FIGMA_TOKEN${RESET}
    (mint one at https://www.figma.com/settings → Personal access tokens).

${BOLD}On first $([ "$MODE" = "skill" ] && printf "${CYAN}/storybook-figma${RESET}${BOLD}" || printf "${CYAN}/bmad-dev-story${RESET}${BOLD}") run, the agent will guide you through anything else missing${RESET}
${BOLD}(approve Figma MCP via /mcp, etc) — you don't need to remember the rest.${RESET}
EOF

if [ "$DEPS_STATUS" != "ready" ]; then
  cat <<EOF

${BOLD}Skipped (do manually):${RESET}
  • Install Playwright + dotenv:
      ${DIM}pnpm i -D playwright @playwright/test dotenv${RESET}
      ${DIM}pnpm exec playwright install chromium${RESET}
EOF
fi
if [ "$SCRIPT_STATUS" != "ready" ]; then
  cat <<EOF
  • Add to ${CYAN}package.json${RESET} ${BOLD}scripts${RESET}:
      ${DIM}"visual:check": "node scripts/visual-check.mjs"${RESET}
EOF
fi

if [ "$MODE" = "skill" ]; then
  cat <<EOF

${BOLD}Then:${RESET}
  In Claude Code, paste a Figma node URL and invoke
  ${CYAN}/storybook-figma <figma-url>${RESET} — the skill handles preflight, decomposition,
  bottom-up build, and visual validation in a single conversation. No story file needed.

${BOLD}Docs:${RESET}
  • Manual: docs/workflows/storybook-first-with-figma.md
  • Skill:  .claude/skills/storybook-figma/SKILL.md

EOF
else
  cat <<EOF

${BOLD}Then:${RESET}
  Author UI stories with a Figma link in References, then invoke
  ${CYAN}/bmad-dev-story${RESET} against each story.

${BOLD}Docs:${RESET}
  • Manual: docs/workflows/storybook-first-with-figma.md

EOF
fi
