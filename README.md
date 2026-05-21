# Storybook-First with Figma

> An installable BMad customization module for pixel-perfect Atomic Design from Figma.

![Workflow diagram — Read Figma → Reuse Check → Build → Validate → Sync to Canvas](article/workflow-diagram.svg)

After install, every UI story your team points the BMad dev agent at follows the same loop: **Read Figma → Reuse Check → Build → Validate → Sync to Canvas** — gated by an automated screenshot diff against Figma that can't be eyeballed away.

📄 **Read the article** ([PDF](article/storybook-first-with-figma.pdf) · [Markdown](article/storybook-first-with-figma.md)) for the *why* and *how it works*.

---

## Requirements

- [BMad](https://docs.bmad-method.org) + `bmm` module (provides `bmad-dev-story`)
- [Claude Code](https://claude.com/claude-code) — the VS Code extension is the assumed runtime; the workflow is driven by slash commands like `/bmad-dev-story`
- Node 20+, pnpm 9+
- A Figma file (must have **Variables**, **atomic-design frames**, and **Components with variant sets** — see the [article](article/storybook-first-with-figma.pdf) for the full prerequisites and degraded-case behaviour)
- A Figma **personal access token** for the visual-check REST call ([figma.com/settings](https://www.figma.com/settings))

---

## Install

**From inside your project root** (a terminal in VS Code is fine — files land directly in your working tree and show up in your Source Control panel):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/keith-sarate/story-book-first-with-figma/main/install.sh)
```

The script fetches its templates, prompts for your Figma file key, drops 7 files into the current directory, copies `.env.example` to `.env`, adds `visual:check` to your `package.json` scripts, installs Playwright + dotenv via your detected package manager, and prints next steps. Review the diff in VS Code, commit when you're happy.

> Want full control? Pass `--no-install-deps`, `--no-package-json`, and/or `--no-dotenv` to opt out of the auto-wiring steps. The Figma token is **never** asked for at install — the dev agent prompts you in-context the first time you run a UI story.

### Other install modes

```bash
# Non-interactive (CI / scripting) — pass the file key inline
bash <(curl -fsSL https://raw.githubusercontent.com/keith-sarate/story-book-first-with-figma/main/install.sh) \
  . -y --file-key KEY

# Or clone first, then run locally (offline, airgapped, or to inspect before running)
REPO=https://github.com/keith-sarate/story-book-first-with-figma.git
git clone --depth 1 "$REPO" /tmp/sb-figma
/tmp/sb-figma/install.sh /path/to/your/project

# Or pin to a revision via git submodule
git submodule add "$REPO" vendor/sb-figma
vendor/sb-figma/install.sh .
```

Run `./install.sh --help` for the full flag list.

---

## After install — 1 manual step

The installer auto-wires the package.json script, installs Playwright + dotenv, and creates `.env` from `.env.example` (with your file key prefilled). The only thing you have to do yourself:

- **Open `.env` and paste a Figma personal access token in `FIGMA_TOKEN`** ([mint one here](https://www.figma.com/settings) → Personal access tokens).

Then run a story:

- In Claude Code, invoke `/bmad-dev-story` against the story you want to run. The agent runs a **preflight check** — if Figma MCP isn't approved yet, or any other piece is missing, it HALTs with the exact remediation step (e.g. *"Open Claude Code → /mcp → approve `figma`, then re-run"*). Once preflight passes, it executes Step 0 (refinement + recursive build plan), confirms with you if many components will be created, then runs the 5-step loop bottom-up.

---

## What lands in the target

```
<target>/
├── .mcp.json                                            # Figma MCP server
├── .env.example                                         # FIGMA_TOKEN, FIGMA_FILE_KEY
├── .gitignore                                           # appended
├── docs/workflows/storybook-first-with-figma.{md,svg}   # operating manual + diagram
├── scripts/visual-check.mjs                             # Playwright + Figma REST
└── _bmad/custom/bmad-dev-story.toml                     # persistent_facts injection
```

The installer never modifies BMad core or module files — only `_bmad/custom/` and project-level paths.

> **Stories are not shipped.** This module configures the dev agent's workflow; your PM authors stories from a PRD via `bmad-create-story` and includes a Figma link in the References section. The dev agent picks each story up and Step 0 takes care of refinement and recursive decomposition.

---

## Repository layout

```
storybook-first-with-figma/
├── README.md                you are here
├── article/                 narrative (PDF + Markdown + diagram)
├── docs/adoption-guide.md   reference playbook for porting by hand or extending
├── install.sh               the installer
├── module.yaml              declarative manifest
└── templates/               every file the installer drops into a target project
```

---

[CHANGELOG](CHANGELOG.md) · [Adoption Guide](docs/adoption-guide.md) · [Article (PDF)](article/storybook-first-with-figma.pdf) · [License: MIT](LICENSE)
