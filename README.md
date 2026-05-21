# Storybook-First with Figma

> **An installable BMad customization module that turns any Atomic-Design + Figma project into a pixel-perfect, design-driven dev pipeline.**

![Workflow diagram — Read Figma → Reuse Check → Build → Validate → Sync to Canvas](article/workflow-diagram.svg)

This repository ships a complete, opinionated dev workflow as a drop-in package:

- A **Dev Operating Manual** that the BMad dev agent loads as foundational context
- A **`bmad-dev-story` customization** (`_bmad/custom/bmad-dev-story.toml`) that enforces the workflow
- A **Figma MCP** registration (`.mcp.json`)
- A **Playwright + Figma REST** visual validation script (`scripts/visual-check.mjs`)
- The **sprint scaffolding**: five base stories (Bootstrap → Atoms Discovery → Molecules → Organisms → Screen) plus a per-atom story template generated at runtime

After install, the project's BMad dev agent follows the same five-step loop on every UI story:

**READ FIGMA → REUSE CHECK → BUILD → VALIDATE → SYNC TO CANVAS**

…gated by an automated screenshot diff between Storybook and Figma that can't be eyeballed away.

---

## Read the article first

The full story — why this workflow exists, how the five steps fit together, why we adopted only one of Figma's four MCP skills — is in [`article/storybook-first-with-figma.pdf`](article/storybook-first-with-figma.pdf) (also browseable as [Markdown](article/storybook-first-with-figma.md)).

---

## Requirements

| Tool | Minimum | Why |
|---|---|---|
| [BMad](https://docs.bmad-method.org) | core + `bmm` module | Provides `bmad-dev-story` and sprint orchestration |
| [Claude Code](https://claude.com/claude-code) | latest | MCP client for Figma |
| Node | 20+ | For `scripts/visual-check.mjs` |
| pnpm | 9+ | npm works too — substitute commands |
| Figma | account + file + personal access token | Token needed for the REST image export inside `visual:check` |

### Figma file prerequisites

The workflow only works as well as the Figma file lets it. The dev agent fishes for what's there — it can't invent structure that doesn't exist. For the workflow to be effective, your Figma file should have:

- **Variables** for colors, spacing, radii, typography (or at minimum published Styles)
- **Atomic-design organization** — distinct frames named or grouped as Atoms / Molecules / Organisms / Screen
- **Components with variant sets** for every reusable piece

If those are missing the workflow can still run, but tokens get derived from raw values and the discovery story may HALT. See the **"What your Figma file needs to have"** section in [`article/storybook-first-with-figma.pdf`](article/storybook-first-with-figma.pdf) for what happens in each degraded scenario.

---

## Install

### One-liner

```bash
REPO=https://github.com/keith-sarate/story-book-first-with-figma.git
git clone --depth 1 "$REPO" /tmp/sb-figma
/tmp/sb-figma/install.sh /path/to/your/project \
  --file-key  <FIGMA_FILE_KEY> \
  --file-name <figma-file-slug> \
  --atoms     <NODE_ID> \
  --molecules <NODE_ID> \
  --organisms <NODE_ID> \
  --screen    <NODE_ID>
```

Replace the `<FIGMA_FILE_KEY>` and `<NODE_ID>` placeholders below with your project's values.

### Interactive (recommended for the first run)

```bash
REPO=https://github.com/keith-sarate/story-book-first-with-figma.git
git clone --depth 1 "$REPO" /tmp/sb-figma
/tmp/sb-figma/install.sh /path/to/your/project
```

Prompts for every value, shows a summary, asks for confirmation, then writes files and prints next steps.

### As a git submodule (recommended for teams)

```bash
cd /path/to/your/project
REPO=https://github.com/keith-sarate/story-book-first-with-figma.git
git submodule add "$REPO" vendor/sb-figma
vendor/sb-figma/install.sh .
```

Pins the module to a known revision; update later with `git submodule update --remote`.

---

## After install — five things to do

The installer prints these too; here they are for reference:

1. In Claude Code, run `/mcp` and approve the `figma` server.
2. `cp .env.example .env` in the target project and paste your Figma personal access token (mint one at [figma.com/settings](https://www.figma.com/settings) → Personal access tokens).
3. Install Playwright in the target project (the dev agent will do this on first run if you skip):
   ```bash
   pnpm i -D playwright @playwright/test dotenv
   pnpm exec playwright install chromium
   ```
4. Add to the target's `package.json` scripts:
   ```json
   "scripts": { "visual:check": "node scripts/visual-check.mjs" }
   ```
5. In Claude Code:
   ```
   > dev the next story
   ```
   That picks up `1-1-bootstrap-and-tokens.md`, sets up Vite + React + TS + Tailwind + Storybook 8, extracts your design tokens from Figma, verifies the visual-check pipeline end-to-end, and yields back.

From there, every subsequent `dev the next story` builds one atom, one molecule, one organism — each isolated in Storybook, each validated against Figma, each pushed back to canvas. The last story composes the organisms into the full screen.

---

## What gets installed

```
<target>/
├── .mcp.json                                       # Figma MCP server
├── .env.example                                    # FIGMA_TOKEN, FIGMA_FILE_KEY
├── .gitignore                                      # appended with .env, _visual-checks/, etc.
├── docs/workflows/
│   ├── storybook-first-with-figma.md               # the operating manual
│   └── storybook-first-with-figma.svg              # the workflow diagram
├── scripts/visual-check.mjs                        # Playwright + Figma REST
├── _bmad/custom/bmad-dev-story.toml                # persistent_facts injection
└── _bmad-output/implementation-artifacts/
    ├── README.md
    ├── sprint-status.yaml
    ├── 1-1-bootstrap-and-tokens.md
    ├── 1-2-0-atoms-discovery.md
    ├── _atom-story-template.md
    ├── 1-3-molecules.md
    ├── 1-4-organisms.md
    └── 1-5-screen.md
```

The installer never modifies BMad core or module files. It only writes to `_bmad/custom/`, `_bmad-output/`, and project-level paths.

### These stories are scaffolding, not a sprint plan

The files under `_bmad-output/implementation-artifacts/` are **examples** of what a story shaped by this workflow looks like. The real flow in BMad isn't "run the shipped stories in order." It's:

1. A PM or architect picks up a requirement and runs `bmad-create-story` (or an equivalent skill). The story lands in the sprint with **a Figma reference link** in its `References` section pointing at the source frame.
2. The dev agent picks up that story and executes the 5-step loop against the Figma link — *Read Figma → Reuse Check → Build → Validate → Sync to Canvas* — bound by the `persistent_facts` in `_bmad/custom/bmad-dev-story.toml`.

The shipped stories show **what shape a story needs** for the dev agent to execute against this workflow: a clear scope (one component or layer), a Figma node-id in `References`, Acceptance Criteria that tie back to Figma variants, and Tasks that match the 5-step loop.

**What this module is not:**

- A sprint planner. Stories come from your own `bmad-create-story` runs, driven by PM and architect agents working from PRDs, epics, and design specs. The dev agent **executes** stories; it doesn't author them.
- A one-size-fits-all sprint plan. A single `1-3-molecules.md` that builds every molecule is fine for a demo with four molecules — it gets unwieldy past six or seven. For larger projects, apply the **discovery pattern** from `1-2-0-atoms-discovery.md` to molecules and organisms too: one story for discovery, N stories for implementation, one story for bulk sync.

**What this module is:**

An **execution discipline layer**. The 5-step loop, the visual-check gate, the token-only rule, the Atomic-Design enforcement, the canvas round-trip — all loaded as `persistent_facts` so every `bmad-dev-story` run is bound by them, regardless of who authored the story. That is where the module earns its keep.


---

## Installer flags

| Flag | Effect |
|---|---|
| `--file-key KEY` | Figma file key (the path segment after `/design/`) |
| `--file-name NAME` | Slug after the file key in URLs (display only) |
| `--atoms ID` | Atoms frame node-id, `N:NNN` form (e.g. `4:581`) |
| `--molecules ID` | Molecules frame node-id |
| `--organisms ID` | Organisms frame node-id |
| `--screen ID` | Full-screen frame node-id |
| `-y, --yes` | Non-interactive — fail on missing values rather than prompt |
| `-n, --dry-run` | Show what would happen, write nothing |
| `-f, --force` | Overwrite existing files (default: skip with warning) |
| `-h, --help` | Print full usage |

---

## Repository layout

```
storybook-first-with-figma/         (this repo)
├── README.md                       you are here
├── LICENSE                         MIT
├── CHANGELOG.md                    release notes
├── install.sh                      the installer
├── module.yaml                     declarative manifest (for future bmad-module-installer)
├── templates/                      every file the installer drops into a target project
│   ├── _bmad/custom/…
│   ├── _bmad-output/implementation-artifacts/…
│   ├── docs/workflows/…
│   ├── scripts/visual-check.mjs
│   └── dotfiles/                   .mcp.json, .env.example, .gitignore.append
├── article/
│   ├── storybook-first-with-figma.pdf
│   ├── storybook-first-with-figma.md
│   ├── workflow-diagram.svg
│   └── article.css
└── docs/
    └── adoption-guide.md           reference-style playbook (the dev-facing companion to the article)
```

---

## Documentation

| Where | What |
|---|---|
| [`article/storybook-first-with-figma.pdf`](article/storybook-first-with-figma.pdf) | The article — narrative explanation of the workflow, with the diagram, install steps, and design rationale |
| [`docs/adoption-guide.md`](docs/adoption-guide.md) | Reference playbook for porting the workflow by hand or extending it |
| [`templates/docs/workflows/storybook-first-with-figma.md`](templates/docs/workflows/storybook-first-with-figma.md) | The Dev Operating Manual that gets installed into target projects |

---

## Uninstall

The module installs ordinary files, so there's no automated uninstall:

```bash
cd /path/to/your/project
rm -rf docs/workflows/storybook-first-with-figma.{md,svg}
rm _bmad/custom/bmad-dev-story.toml
rm -rf _bmad-output/implementation-artifacts/{README.md,sprint-status.yaml,1-*.md,_atom-story-template.md}
rm scripts/visual-check.mjs .mcp.json .env.example
# Then manually remove the appended block in .gitignore (between the two `# ---` markers)
```

---

## Versioning

See [`CHANGELOG.md`](CHANGELOG.md). The module follows [semver](https://semver.org/): breaking changes bump major, new install steps or new template files bump minor, bug fixes and tweaks bump patch.

---

## Acknowledgements

- The "Sync to Canvas" step (#5) is adopted from Figma's [Workflow lab: Code to canvas](https://help.figma.com/hc/en-us/articles/40219873508247-Workflow-lab-Code-to-canvas).
- Built on top of [BMad](https://docs.bmad-method.org) — sprint orchestration, story format, dev agent.
- Validation loop inspired by internal CSpire pixel-perfect protocol.

---

## License

[MIT](LICENSE) — use, modify, redistribute. Pull requests welcome.
