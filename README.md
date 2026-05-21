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

The script fetches its templates, prompts for your Figma file key and four Atomic-Design node-ids (Atoms / Molecules / Organisms / Screen), drops 15 files into the current directory, and prints next steps. Review the diff in VS Code, commit when you're happy.

### Other install modes

```bash
# Non-interactive (CI / scripting) — pass values inline
bash <(curl -fsSL https://raw.githubusercontent.com/keith-sarate/story-book-first-with-figma/main/install.sh) \
  . -y --file-key KEY --atoms 4:581 --molecules 4:726 --organisms 4:850 --screen 4:1015

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

## After install — 5 steps

1. **Authenticate Figma MCP.** In Claude Code (VS Code extension), invoke `/mcp` and approve the `figma` server.
2. **Set your Figma token.** `cp .env.example .env` and paste a personal access token.
3. **Install Playwright** (skip if your project already has it):
   ```bash
   pnpm i -D playwright @playwright/test dotenv
   pnpm exec playwright install chromium
   ```
4. **Wire the npm script.** Add to `package.json`:
   ```json
   "scripts": { "visual:check": "node scripts/visual-check.mjs" }
   ```
5. **Run a story.** In Claude Code, invoke `/bmad-dev-story` with the path to the story you want to run. The agent reads it, executes Step 0 (refinement + recursive build plan), confirms with you if many components will be created, then runs the 5-step loop bottom-up.

---

## What lands in the target

```
<target>/
├── .mcp.json                                       # Figma MCP server
├── .env.example                                    # FIGMA_TOKEN, FIGMA_FILE_KEY
├── .gitignore                                      # appended
├── docs/workflows/storybook-first-with-figma.{md,svg}   # operating manual + diagram
├── scripts/visual-check.mjs                        # Playwright + Figma REST
├── _bmad/custom/bmad-dev-story.toml                # persistent_facts injection
└── _bmad-output/implementation-artifacts/          # 8 example story files
```

The installer never modifies BMad core or module files — only `_bmad/custom/`, `_bmad-output/`, and project-level paths.

> **The shipped stories are scaffolding, not a sprint plan.** They're examples of what a story shaped for this workflow looks like. In real use, your PM authors stories from a PRD via `bmad-create-story` and includes a Figma link in the References section. The dev agent picks those up the same way — Step 0 takes care of refinement and decomposition.

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
