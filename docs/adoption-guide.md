# Adoption Guide — Bringing "Storybook-First with Figma" to a New Project

This is the **portable** version of what we built here. Drop these pieces into a fresh project (BMad-equipped or about-to-be) and you'll have:

- A dev agent that **reads from Figma via MCP** before writing any UI code
- A **per-component build loop** that enforces Atomic Design + token discipline
- An **automated visual validation gate** (Playwright screenshot ↔ Figma REST export)
- A **canvas round-trip** that pushes built components back to Figma for design parity diff

The whole thing is BMad-compatible but **not BMad out-of-the-box** — about half is custom. This guide makes the line explicit. The installer drops the workflow and tooling into your project; **stories themselves are authored per project** by your PM (via `bmad-create-story` from a PRD, with a Figma link in References).

---

## What's stock BMad vs what we built

| Piece | Stock BMad | Custom in this project |
|---|---|---|
| `bmad-create-story`, `bmad-dev-story`, `bmad-sprint-planning`, `bmad-code-review`, `bmad-help` skills | ✅ Provided by `bmm` module | — |
| Sprint-status driven story flow (`sprint-status.yaml` + "dev the next story") | ✅ | — |
| Story file template (`# Story X.Y`, ACs, Tasks, Dev Notes, References) | ✅ | — |
| `customize.toml` override surface for `bmad-dev-story` | ✅ Skill ships an empty surface; we filled it | — |
| Skill customization at `_bmad/custom/<skill>.toml` (team scope) | ✅ Infrastructure | We added our own |
| `docs/workflows/storybook-first-with-figma.md` (Dev Operating Manual + SVG diagram) | — | **Custom** |
| Figma MCP server registered in `.mcp.json` | — | **Custom** |
| `scripts/visual-check.mjs` (Playwright screenshot + Figma REST PNG) | — | **Custom** |
| Step 0 recursive decomposition + bottom-up build plan for brownfield projects | — | **Custom** |
| Visual Validation Loop as a verification gate in every story | — | **Custom** |
| `/prototype-to-figma` round-trip into a `Built / <Layer>` page | — | **Pattern we adopted from Figma's article** |

Translation: **BMad gives you the orchestration** (story files, sprint status, dev agent). **We added the UI-development discipline** (Figma MCP, visual check, per-component granularity, round-trip).

---

## Prerequisites in the Figma file

The workflow's value is bounded by the Figma file's structure. The dev agent reads via the MCP, but the MCP only returns what's actually there. For the workflow to be effective, the Figma file must have:

- **Variables** (or at minimum published Styles) for colors, spacing, radii, typography
- **Atomic-design organization** — distinct frames named or grouped as Atoms / Molecules / Organisms / Screen
- **Components with variant sets** covering all states and configurations

In degraded scenarios the workflow can still run — tokens get derived from inline values, the agent flags missing structure — but quality drops. If the Figma file is essentially a single screen mockup with detached strokes, run a Figma cleanup pass before starting the sprint. The article ([`article/storybook-first-with-figma.pdf`](article/storybook-first-with-figma.pdf)) has a full "What your Figma file needs to have" section covering the degraded cases.

## Prerequisites in the target project

Before you start porting, the target project needs:

1. **BMad installed** with at least the `bmm` module (provides `bmad-dev-story` and friends). Run `bmad-bmb-setup` or install from your team's BMad installer. After install, `_bmad/_config/bmad-help.csv` should exist.
2. **Claude Code** with MCP support.
3. A **Figma file** with components organized in the Atomic layers you intend to use (frames named `Atoms`, `Molecules`, `Organisms`, plus a target screen — or your own naming, just note the node-ids).
4. A **Figma personal access token** ([figma.com/settings → Personal access tokens](https://www.figma.com/settings)). Needed for `pnpm visual:check` to call the REST image export.
5. **Node 20+** and **pnpm 9+** (npm works too — substitute commands).

Optional but recommended: a `docs/` folder already in place, and the project's CLAUDE.md set up.

---

## The 5 things to drop in (in order)

> **The installer (`install.sh` at the repo root) automates everything in this section.** Read on if you want to understand what gets installed, port the workflow by hand into a context the installer can't reach, or extend the module. Otherwise: `git clone <this repo> && ./install.sh /path/to/project --file-key ...` and skip ahead to "Per-project customization points."

### 1. The Dev Operating Manual + diagram

Copy these two files from `templates/docs/workflows/` to the target's `docs/workflows/`:

- `docs/workflows/storybook-first-with-figma.md`
- `docs/workflows/storybook-first-with-figma.svg`

If the new project uses a different stack (e.g. Next.js instead of Vite, CSS-in-JS instead of Tailwind), edit the **"Tooling Stack"** table and rewrite the **"How it runs"** section of the Visual Validation Loop to match.

> The SVG is generic — it doesn't reference any specific Figma file. Leave it alone unless you change step names.

### 2. The `bmad-dev-story` customization

Copy `_bmad/custom/bmad-dev-story.toml` into the target project's `_bmad/custom/bmad-dev-story.toml`.

This is **the most important single file** — it's what makes the workflow manual *load as foundational context every time the dev agent runs*. The `persistent_facts` array is what enforces:

- "All UI work follows Atomic Design"
- "Tokens are the single source of truth"
- "Every component ships with a Storybook story"
- "Visual Validation Loop is mandatory before done"
- "When `actual.png` and `expected.png` disagree, Figma values win"
- "If Figma MCP is unreachable, HALT"

**Edit before committing:** keep these rules generic. If the target project uses different conventions (no Tailwind, no CVA, etc.), rephrase the rules accordingly. The file path on line 9 (`docs/workflows/storybook-first-with-figma.md`) should stay correct if you copied the manual to the same location.

### 3. Figma MCP registration

Create `.mcp.json` at the project root:

```json
{
  "mcpServers": {
    "figma": {
      "type": "http",
      "url": "https://mcp.figma.com/mcp"
    }
  }
}
```

In Claude Code, run `/mcp` and approve the `figma` server. The OAuth flow opens in a browser the first time. Once approved, `mcp__figma__*` tools become available to the dev agent.

> **Heads up:** in some Claude Code permission modes the agent itself can't write `.mcp.json` because it changes agent config. Create it yourself, or include it as a manual step in your Story 1.1.

### 4. The visual check script + env

The script lives at `templates/scripts/visual-check.mjs` and is copied to `scripts/visual-check.mjs` in the target. It depends on:

```bash
pnpm i -D playwright @playwright/test dotenv
pnpm exec playwright install chromium
```

Add this to `package.json`:

```json
"scripts": {
  "visual:check": "node scripts/visual-check.mjs"
}
```

Create `.env.example`:

```
FIGMA_TOKEN=
FIGMA_FILE_KEY=<your-figma-file-key>
```

And `.gitignore` additions:

```
.env
_visual-checks/
playwright-report/
test-results/
```

Tell each developer who'll run the loop to copy `.env.example` to `.env` and fill in their personal Figma token.

### 5. Verify it loads

In the target project, open Claude Code and run a UI story you've authored (with a Figma link in References):

```
> /bmad-dev-story path/to/your/story.md
```

The dev agent should, in its first response:

1. Greet, load config
2. Load persistent_facts — confirm the manual at `docs/workflows/storybook-first-with-figma.md` is read into context
3. Classify the story as UI (because of the Figma link) and announce: *"Classified as UI story — Storybook-First workflow active"*
4. Run Step 0 (refine the story, decompose recursively, produce a bottom-up build plan)

If it doesn't reference the manual in its first response or skips the classification line, your customize.toml isn't being picked up — check `_bmad/custom/bmad-dev-story.toml` is at the right path and the `[workflow]` block is structured correctly.

---

## Per-project customization points

These are the levers you'll touch most often when adapting:

### Tech stack

The manual and the customize.toml are written around **Vite + React + TS + Tailwind + Storybook 8**. To change:

- **Bundler:** Swap Vite tasks in Story 1.1 for Next.js / Remix / Rspack init. Storybook integration adapts naturally.
- **Styling:** Replace Tailwind references with CVA + CSS Modules / vanilla-extract / styled-components. The Visual Checklist stays identical — only the *how to fix drift* changes.
- **Stories format:** Storybook 8 + CSF3 is assumed. If you're on Ladle or Histoire, swap the script template's `iframe.html?id=` URL pattern.

### Token strategy

We assume **tokens live in `src/tokens/tokens.ts`** and are consumed via Tailwind theme extension. Alternatives that work without changing the workflow:

- CSS variables in `:root` + a Tailwind `@theme` block
- Style Dictionary build pipeline
- Figma Variables → JSON via Figma REST → token file (skips the manual extraction)

Whichever you pick, the **rule** in customize.toml stays: *no hex/px hardcodes*.

### Visual check approach

`scripts/visual-check.mjs` is a ~70-line Playwright + Figma REST script. Alternatives:

- **Chromatic** — managed visual regression. Drop the Figma comparison side; Chromatic compares baseline-to-baseline, not design-to-impl.
- **Percy** — same idea as Chromatic.
- **Figma MCP `get_image`** — replace the REST fetch with the MCP tool. Slightly tighter integration, but less reproducible outside Claude sessions.

We chose Playwright + REST because (a) deterministic, (b) runs in CI without MCP, (c) the agent reads PNGs directly and walks the checklist.

### Figma round-trip

Step 5 (Sync to Canvas) uses `/prototype-to-figma`, a Figma MCP skill. This is **optional** — it's the bit that gives the demo its punchline ("look, the built code is now next to the original design"). If your team doesn't care about the round-trip, drop the task from each story and the corresponding line in customize.toml.

---

## How to extend the pattern

### Adding a new validation gate (e.g. visual regression baseline)

Inside `_bmad/custom/bmad-dev-story.toml`, add a new entry to `persistent_facts`:

```toml
"Every component MUST have a Chromatic baseline accepted before the story is marked done."
```

Then add a task to the relevant story templates referencing your Chromatic project.

### Adding a new layer (e.g. Templates between Organisms and Pages)

1. Update folder convention: `src/components/templates/`
2. Update the `persistent_facts` rule in `_bmad/custom/bmad-dev-story.toml` about layering to include the new layer (e.g. `screen ← templates ← organisms ← ...`)
3. Update the Dev Operating Manual sections that enumerate layers (TL;DR step 2, Verification Gate) to mention the new layer

### Driving multiple Figma files

If a project has more than one Figma file (e.g. mobile + web), either:

- Keep one workflow doc and reference multiple files in the "Figma File Reference" table, OR
- Split into `storybook-first-with-figma-mobile.md` + `storybook-first-with-figma-web.md`, and have the customize.toml load whichever applies (via two separate per-skill customizations if you split sprints)

---

## File reference (what each file the installer drops does)

```
docs/workflows/
├── storybook-first-with-figma.md   ← Dev Operating Manual: 5-step loop, checklist, rules
└── storybook-first-with-figma.svg  ← Visual workflow diagram (embedded at top of manual)

_bmad/custom/
└── bmad-dev-story.toml             ← Customization: injects the manual as persistent_facts

scripts/
└── visual-check.mjs                ← Playwright screenshot ↔ Figma REST PNG

.mcp.json                            ← Figma MCP server registration
.env.example                         ← FIGMA_TOKEN, FIGMA_FILE_KEY scaffold
.gitignore                           ← appended: .env, _visual-checks/, Playwright/Storybook outputs
```

Per-project artifacts the **target team owns** (not shipped by this module):

```
_bmad-output/implementation-artifacts/   ← Stories authored by your PM via bmad-create-story
src/tokens/tokens.ts                     ← Tokens extracted from Figma Variables on first run
src/components/{atoms,molecules,organisms,...}/   ← Atomic-Design folder structure
```

---

## Troubleshooting

### "The dev agent didn't load the workflow manual"

- Verify `_bmad/custom/bmad-dev-story.toml` exists at exactly that path
- Verify the `[workflow]` block and `persistent_facts` array are correctly formatted TOML
- Re-run the resolver: `python3 _bmad/scripts/resolve_customization.py --skill _bmad/skills/bmad-dev-story --key workflow` should show your `persistent_facts` entries in the output

### "Figma MCP tools don't appear after `/mcp`"

- Confirm `.mcp.json` is at the project root, not in a subfolder
- The first connection requires interactive OAuth — Claude Code will open the browser
- If on a remote/headless setup, follow Figma's desktop MCP install instructions instead of remote

### "`pnpm visual:check` fails with 403 from Figma"

- The `FIGMA_TOKEN` is wrong or expired. Mint a new one at figma.com/settings.
- The token's scope doesn't include the file. Personal tokens cover all files you can view — make sure your account has at least view access to the design file.

### "Playwright can't launch Chromium"

- Run `pnpm exec playwright install chromium`
- On Linux, you may also need system deps: `pnpm exec playwright install-deps chromium`
- On the project's Ubuntu 26.04 setup we use `channel: 'chrome'` instead — see `docs/README.md` for details.

### "The dev agent writes hex colors anyway"

The persistent_facts say "tokens are the source of truth" but a sufficiently confused dev pass can ignore that. If it happens:

1. Update the offending story's `Completion Notes List` with what the agent did
2. Strengthen the relevant `persistent_facts` entry — e.g. add `Hardcoded hex/px is grounds for rejecting the entire story.`
3. Re-run `bmad-create-story:validate` against the story before re-dev

---

## TL;DR — install in one command

If you read no further, this is what running `install.sh` does for you automatically:

```bash
# From inside your project root (VS Code's integrated terminal is fine):
bash <(curl -fsSL https://raw.githubusercontent.com/keith-sarate/story-book-first-with-figma/main/install.sh)
# Prompts for FIGMA_FILE_KEY, drops 7 files into the current directory.
# Review the diff in VS Code's Source Control panel.

# Then in Claude Code (VS Code extension):
> /mcp                   # approve the figma server
> /bmad-dev-story        # invoke against a story file authored by your PM
```

Manual port (if you'd rather not use the installer):

```bash
# In the target project root:
mkdir -p docs/workflows _bmad/custom scripts

# Copy these files from this module's templates/ verbatim
# (substitute FIGMA_FILE_KEY in .env.example with your file key):
#   templates/docs/workflows/storybook-first-with-figma.md         → docs/workflows/
#   templates/docs/workflows/storybook-first-with-figma.svg        → docs/workflows/
#   templates/_bmad/custom/bmad-dev-story.toml                     → _bmad/custom/
#   templates/scripts/visual-check.mjs                             → scripts/
#   templates/dotfiles/mcp.json                                    → .mcp.json
#   templates/dotfiles/env.example                                 → .env.example
#   templates/dotfiles/gitignore.append                            → append to .gitignore
```

Everything else in this guide is *why* — read it when something breaks or when you want to extend.
