# Storybook-First with Figma

> An installable module for pixel-perfect Atomic Design from Figma — works as a BMad customization or as a standalone Claude Code skill.

**Authored by Keith Sarate** ([keith.sarate@objectedge.com](mailto:keith.sarate@objectedge.com)) · Object Edge

![Workflow diagram — Read Figma → Reuse Check → Build → Validate → Sync to Canvas](article/workflow-diagram.svg)

After install, every UI work item follows the same loop: **Read Figma → Reuse Check → Build → Validate → Sync to Canvas** — gated by an automated screenshot diff against Figma that can't be eyeballed away.

📄 **Read the article** ([PDF](article/storybook-first-with-figma.pdf) · [Markdown](article/storybook-first-with-figma.md)) for the *why* and *how it works*.

---

## Two install modes

| Mode | Trigger | Input | Best for |
|---|---|---|---|
| **`bmad`** (default) | `/bmad-dev-story <story-file>` | A BMad story file with a Figma link in References | Teams already using BMad + sprint planning |
| **`skill`** | `/storybook-figma <figma-url>` | A Figma node URL — no story file, no sprint | Teams that want the workflow without adopting BMad |

Both modes ship the same workflow manual, visual-check script, Figma MCP wiring, and `.env` scaffolding. They differ only in **how the agent is triggered**: BMad mode injects the workflow as `persistent_facts` for the `bmad-dev-story` agent; skill mode drops a self-contained Claude Code skill that the user invokes with a Figma URL.

## Requirements

- [Claude Code](https://claude.com/claude-code) — the VS Code extension is the assumed runtime
- Node 20+, pnpm 9+ (npm/yarn/bun work too)
- A Figma file (must have **Variables**, **atomic-design frames**, and **Components with variant sets** — see the [article](article/storybook-first-with-figma.pdf) for the full prerequisites and degraded-case behaviour)
- A Figma **personal access token** for the visual-check REST call ([figma.com/settings](https://www.figma.com/settings))
- **BMad mode only:** [BMad](https://docs.bmad-method.org) + `bmm` module (provides `bmad-dev-story`)

---

## Install

**From inside your project root** (a terminal in VS Code is fine — files land directly in your working tree and show up in your Source Control panel):

```bash
# BMad mode (default) — drops _bmad/custom/bmad-dev-story.toml
bash <(curl -fsSL https://raw.githubusercontent.com/objectedge/storybook-first-with-figma/main/install.sh)

# Skill mode — drops .claude/skills/storybook-figma/SKILL.md (no BMad needed)
bash <(curl -fsSL https://raw.githubusercontent.com/objectedge/storybook-first-with-figma/main/install.sh) . --mode skill
```

The script fetches its templates, prompts for your Figma file key, drops 7 files into the current directory, copies `.env.example` to `.env`, adds `visual:check` to your `package.json` scripts, installs Playwright + dotenv via your detected package manager, and prints next steps. Review the diff in VS Code, commit when you're happy.

> Want full control? Pass `--no-install-deps`, `--no-package-json`, and/or `--no-dotenv` to opt out of the auto-wiring steps. The Figma token is **never** asked for at install — the agent prompts you in-context the first time you trigger a UI build.

### Other install modes

```bash
# Non-interactive (CI / scripting) — pass the file key inline
bash <(curl -fsSL https://raw.githubusercontent.com/objectedge/storybook-first-with-figma/main/install.sh) \
  . -y --file-key KEY

# Or clone first, then run locally (offline, airgapped, or to inspect before running)
REPO=https://github.com/objectedge/storybook-first-with-figma.git
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

Then trigger a run:

- **BMad mode:** in Claude Code, invoke `/bmad-dev-story` against a story file (your PM authors it via `bmad-create-story` with a Figma link in References).
- **Skill mode:** in Claude Code, paste a Figma node URL and invoke `/storybook-figma <figma-url>`.

Either way, the agent runs a **preflight check** — if Figma MCP isn't approved yet, or any other piece is missing, it HALTs with the exact remediation step (e.g. *"Open Claude Code → /mcp → approve `figma`, then re-run"*). Once preflight passes, it executes Step 0 (refinement + recursive build plan), confirms with you if many components will be created, then runs the 5-step loop bottom-up.

---

## What lands in the target

Shared by both modes:

```
<target>/
├── .mcp.json                                            # Figma MCP server
├── .env.example                                         # FIGMA_TOKEN, FIGMA_FILE_KEY
├── .gitignore                                           # appended
├── docs/workflows/storybook-first-with-figma.{md,svg}   # operating manual + diagram
└── scripts/visual-check.mjs                             # Playwright + Figma REST
```

Mode-specific:

```
# BMad mode (default)
└── _bmad/custom/bmad-dev-story.toml                     # persistent_facts injection

# Skill mode (--mode skill)
└── .claude/skills/storybook-figma/SKILL.md              # Claude Code skill
```

The installer never modifies BMad core or module files — only `_bmad/custom/` (BMad mode), `.claude/skills/` (skill mode), and project-level paths.

> **Stories are not shipped.** In BMad mode the PM authors stories from a PRD via `bmad-create-story` and includes a Figma link in References — the dev agent picks each story up and Step 0 takes care of refinement and recursive decomposition. In skill mode the Figma link IS the input — no story file needed.

---

## Repository layout

```
storybook-first-with-figma/
├── README.md                you are here
├── article/                 narrative (PDF + Markdown + diagram)
├── docs/adoption-guide.md   reference playbook for porting by hand or extending
├── install.sh               the installer (supports --mode bmad|skill)
├── module.yaml              declarative manifest
├── scripts/build-pdfs.sh    rebuild article + presentation PDFs from .md sources
└── templates/               every file the installer drops into a target project
    ├── _bmad/               BMad-mode customization (default)
    ├── skill/               Skill-mode SKILL.md (--mode skill)
    ├── docs/                workflow manual + diagram (shared)
    ├── scripts/             visual-check.mjs (shared)
    └── dotfiles/            .mcp.json, .env.example, .gitignore append (shared)
```

### Rebuilding the PDFs

After editing `article/storybook-first-with-figma.md` or `article/presentation.md`:

```bash
scripts/build-pdfs.sh                  # both
scripts/build-pdfs.sh article          # long-form only
scripts/build-pdfs.sh presentation     # slide deck only
scripts/build-pdfs.sh clean            # delete generated PDFs
```

Tooling (`md-to-pdf` + `@marp-team/marp-cli`) is fetched on demand via `npx`; first run needs network access, subsequent runs use the npm cache.

---

[CHANGELOG](CHANGELOG.md) · [Adoption Guide](docs/adoption-guide.md) · [Article (PDF)](article/storybook-first-with-figma.pdf) · [License: MIT](LICENSE)

© 2026 Object Edge · Authored by Keith Sarate
