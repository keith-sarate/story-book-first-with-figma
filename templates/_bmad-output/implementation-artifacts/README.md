# Demo Sprint — Storybook + Atomic Design + Figma

5 stories that build up from atoms to a full screen, each driven by the Figma source file and the [Storybook-First with Figma workflow](../../docs/workflows/storybook-first-with-figma.md).

## How to run the demo

Run each story **in a fresh Claude Code window** (keeps context tight and the demo narrative crisp):

```bash
# In a fresh window:
> dev this story _bmad-output/implementation-artifacts/1-1-bootstrap-and-tokens.md
```

Or, since `sprint-status.yaml` is in place, just say:

```bash
> dev the next story
```

…and `bmad-dev-story` picks up the first `ready-for-dev` story automatically.

## Run order

| # | Story | What it produces | Figma node |
|---|-------|------------------|------------|
| 1.1 | [Bootstrap + Tokens](1-1-bootstrap-and-tokens.md) | Vite + React + TS + Tailwind + Storybook 8 + Figma MCP wired + tokens extracted | `4:581` (for tokens only) |
| 1.2.0 | [Atoms Discovery](1-2-0-atoms-discovery.md) | Reads Figma and **scaffolds one story file per atom** + a final atoms-sync story | `4:581` |
| 1.2.n | `1-2-<n>-<atom>.md` (generated) | **One atom** = component + story in Storybook. Demo beat: build it live. | one node per atom |
| 1.2.99 | `1-2-99-atoms-sync.md` (generated) | Bulk push all atoms to Figma page `Built / Atoms` and diff | `4:581` |
| 1.3 | [Molecules](1-3-molecules.md) | Molecules composing atoms — no atom re-invented | `4:726` |
| 1.4 | [Organisms](1-4-organisms.md) | Organisms composing molecules + atoms | `4:850` |
| 1.5 | [Full Screen](1-5-screen.md) | Page composing organisms — the punchline | `4:1015` |

**Why atoms are split:** so each `dev the next story` call builds exactly **one atom** — a clean demo beat where the audience sees that atom land in Storybook in 5–10 minutes. Story 1.2.0 reads Figma, lists the atoms, pauses for your confirmation, then generates the per-atom story files. You can do the same split for molecules/organisms later if needed — just ask.

## Per-story workflow (handled by bmad-dev-story + the workflow manual)

Every story follows the same loop, baked into the dev agent via `_bmad/custom/bmad-dev-story.toml`:

```
Figma MCP read node → derive props + variants
  → build component(s) + Tailwind classes (tokens only)
  → write .stories.tsx (Default + one per variant)
  → verify in Storybook (visual + a11y)
  → Visual Validation Loop: pnpm visual:check → side-by-side PNGs → checklist → fix drift → re-check
  → /prototype-to-figma push to "Built / <Layer>" page in Figma
  → final diff vs original frame
```

**Visual Validation Loop** is what makes "done" mean *pixel-correct*, not *looks-right*. After the component renders, the dev runs `pnpm visual:check` which produces:
- `_visual-checks/<component>/<variant>/actual.png` — Playwright screenshot of the Storybook story at 2x DPR
- `_visual-checks/<component>/<variant>/expected.png` — Figma REST export of the node at 2x

The dev then reads both PNGs (Claude is multimodal) and walks the Visual Checklist in [docs/workflows/storybook-first-with-figma.md](../../docs/workflows/storybook-first-with-figma.md#visual-validation-loop): colors, fonts, spacing, radius, shadows, opacity, gradients, states, cursor, truncation, responsive. Each failing item enters a fix loop. The component isn't marked done until every item ticks.

If the Figma MCP isn't authenticated when a story starts, or `FIGMA_TOKEN` is missing for `visual:check`, the dev agent HALTs — that's by design, so visuals are never invented.

## Prerequisites before Story 1.1

- Claude Code with MCP support
- A Figma account with view access to file `7vcHVM7siztlW4xId0ClVZ`
- A Figma **personal access token** (created at https://www.figma.com/settings → Personal access tokens) — used by `pnpm visual:check` for the REST image export
- Node 20+ and npm

## What this demo proves

- Atomic Design + Storybook produces a real, reusable component library — not a one-off page
- Figma-driven development with the MCP keeps code and design in lockstep
- Every layer is provable in isolation (Storybook) AND in composition (the final page)
