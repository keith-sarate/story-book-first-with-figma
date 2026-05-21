# Changelog

All notable changes to the `storybook-first-with-figma` module are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project adheres to [semver](https://semver.org/).

## [0.3.0] — 2026-05-21

### Added
- **Skill install mode (`--mode skill`)** — a standalone Claude Code skill (`.claude/skills/storybook-figma/SKILL.md`) that runs the entire workflow (preflight → decomposition → bottom-up build → visual validation → optional sync-back) from a single Figma URL, with no BMad, story file, or sprint dependency. The user invokes `/storybook-figma <figma-url>` instead of `/bmad-dev-story <story>`. Same workflow rules as BMad mode, surfaced as skill instructions instead of `persistent_facts`.
- Installer `--mode bmad|skill` flag (default: `bmad`) — BMad mode stays the default and behaves identically to 0.2.0; skill mode skips `_bmad/custom/bmad-dev-story.toml` and drops the skill file instead. All shared artifacts (workflow manual, visual-check script, `.mcp.json`, `.env.example`) are installed in both modes.
- `templates/skill/storybook-figma/SKILL.md` — the skill source, with frontmatter `name`/`description` tuned for the Claude Code skill auto-trigger.

### Changed
- Installer summary, post-install instructions, and "next steps" message now branch on `--mode` (mention `/storybook-figma` vs `/bmad-dev-story`).
- README documents the two modes side-by-side; BMad remains the default for backwards-compatible installs.

## [0.2.0] — 2026-05-21

### Added
- Installer auto-wires the target project: copies `.env.example` → `.env` (file key prefilled, token left empty), adds `scripts.visual:check` to `package.json` (preserving indentation), and installs `playwright`, `@playwright/test`, `dotenv` + Chromium via the detected package manager (`pnpm` / `yarn` / `npm` / `bun`). Each step is opt-out via `--no-dotenv`, `--no-package-json`, `--no-install-deps`. Lockfile detection picks the package manager; `--pm` forces it.
- Preflight checklist baked into `bmad-dev-story.toml` — the dev agent now verifies (1) Figma MCP reachable, (2) `FIGMA_TOKEN` non-empty in `.env`, (3) `scripts/visual-check.mjs` present, (4) Playwright installed, (5) `package.json` `scripts.visual:check` set, (6) Storybook installed in the project (`.storybook/main.*` or `@storybook/*` in package.json) — BEFORE Step 0 runs. Each failure HALTs with the exact one-line remediation so users don't have to remember the manual setup steps.
- Storybook lifecycle rule — agent now auto-starts `pnpm storybook` (or `npm`/`yarn`/`bun` equivalent) in the background before the first `pnpm visual:check` call, polls `:6006/iframe.html` until ready (60s cap), and leaves the server running for subsequent stories. Storybook installation itself is not auto-installed (its `init` is too project-specific) — the preflight HALTs with a clear instruction instead.
- `visual-check.mjs` does its own Storybook reachability fetch (3s timeout) before launching Playwright, so the failure mode is a clear *"Storybook not reachable"* message with the fix instead of a generic Playwright navigation timeout.

### Removed
- Bundled demo sprint scaffolding (`_bmad-output/implementation-artifacts/` — 8 files: bootstrap/atoms-discovery/molecules/organisms/screen stories, atom story template, sprint-status.yaml, README). Stories are now per-project artifacts authored by the target team's PM via `bmad-create-story`; the module only ships the workflow and tooling.
- `NODE_ID_ATOMS` / `NODE_ID_MOLECULES` / `NODE_ID_ORGANISMS` / `NODE_ID_SCREEN` and `FIGMA_FILE_NAME` variables/flags from `install.sh` and `module.yaml` (they only existed to substitute placeholders in the demo stories).
- Hardcoded "Figma File Reference" table from the Dev Operating Manual — `FIGMA_FILE_KEY` lives in `.env`; per-story node-ids live in story References.

### Changed
- Installer now drops 7 files (was 15) and prompts only for `FIGMA_FILE_KEY`. The Figma personal access token is never requested at install — the agent's preflight check guides the user to set it at first run.
- Post-install summary reduced from 5 manual steps to 1 (paste the Figma token into `.env`).

## [0.1.0] — 2026-05-20

### Added
- Five-step Dev Operating Manual (`templates/docs/workflows/storybook-first-with-figma.md`) with embedded SVG diagram
- `bmad-dev-story` customization (`templates/_bmad/custom/bmad-dev-story.toml`) that loads the manual as `persistent_facts`
- Figma MCP registration template (`.mcp.json`)
- Visual validation script (`templates/scripts/visual-check.mjs`) — Playwright screenshot ↔ Figma REST PNG
- Five base sprint stories: bootstrap, atoms-discovery, molecules, organisms, screen
- Atom story template stamped out at runtime by the discovery story
- `install.sh` with interactive prompts, flags, dry-run, force, and `.gitignore` idempotency
- Declarative `module.yaml` manifest (consumable by a future `bmad-module-installer`)
- Article (PDF + Markdown) explaining the workflow and how to adopt it
- `docs/adoption-guide.md` — reference-style playbook for porting the workflow by hand

[0.3.0]: https://github.com/keith-sarate/story-book-first-with-figma/releases/tag/v0.3.0
[0.2.0]: https://github.com/keith-sarate/story-book-first-with-figma/releases/tag/v0.2.0
[0.1.0]: https://github.com/keith-sarate/story-book-first-with-figma/releases/tag/v0.1.0
