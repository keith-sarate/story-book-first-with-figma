# Changelog

All notable changes to the `storybook-first-with-figma` module are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project adheres to [semver](https://semver.org/).

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

[0.1.0]: https://github.com/keith-sarate/story-book-first-with-figma/releases/tag/v0.1.0
