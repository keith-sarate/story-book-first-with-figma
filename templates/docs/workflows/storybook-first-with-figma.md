# Storybook-First with Figma (Dev Operating Manual)

![Workflow diagram — Read Figma → Reuse Check → Build → Validate → Sync to Canvas](storybook-first-with-figma.svg)

> **Inspired by** Figma's [Workflow lab: Code to canvas](https://help.figma.com/hc/en-us/articles/40219873508247-Workflow-lab-Code-to-canvas) (which is Step 5 of our flow), with **READ FIGMA → REUSE CHECK → BUILD → VALIDATE** added in front so the trip is bidirectional.
>
> **Loaded as a persistent fact by `bmad-dev-story` for every dev run in this project.**
> Whenever the dev agent implements a UI story, it MUST follow this workflow.

## Figma file requirements (read this first)

The workflow reads Figma via MCP and writes back via Figma round-trip. Both halves assume the file is structured for atomic design and uses Figma's first-class semantic features:

- **Variables** for colors, spacing, radii, typography — read by `get_variable_defs` and become entries in `src/tokens/tokens.ts`. Without them, tokens are derived from inline values and lose their semantic names.
- **Atomic frames** — frames named (or grouped under) Atoms, Molecules, Organisms, and the target Screen. Each UI story references the Figma node-id of its target via the link in References; missing layers cause Step 0's decomposition to HALT.
- **Components with variants** — each reusable piece is a proper Figma Component with a complete variant set covering states and configurations.

If any of these are missing when the dev agent encounters them at runtime, the agent MUST surface the gap to the user — never silently invent structure or token names. Run a Figma cleanup pass with the design team before starting the sprint; it is consistently cheaper than asking the agent to invent structure that doesn't exist.

## TL;DR for the dev agent

For every UI component or screen story:

1. **Read Figma first** — use the Figma MCP server (`https://mcp.figma.com/mcp`) to fetch the exact node referenced in the story's Acceptance Criteria (`fileKey` + `node-id`). Never invent visuals; extract them.
2. **Reuse before creating** — if an earlier story already produced an atom/molecule/organism, import it. Atomic Design is non-negotiable here: molecules use atoms, organisms use molecules, screens use organisms.
3. **One Storybook story per component** — every component shipped MUST have a `.stories.tsx` file with at least: `Default`, plus a story per documented variant/state in Figma.
4. **Sync back to canvas to verify** — after the component renders correctly in Storybook, run `prototype-to-figma` (or `figma-generate-design`) against the Storybook URL to push the built component back to a "Built" page in the Figma file. Visually compare against the original frame. This is the verification gate.
5. **Tokens stay in code** — design tokens (colors, spacing, radii, typography) extracted from Figma Variables are the single source of truth (typically in `src/tokens/tokens.ts` and surfaced via `tailwind.config.ts`). Components consume tokens; do not hardcode hex/px.

## Tooling Stack

| Layer | Tool | Notes |
|---|---|---|
| Build | Vite + React + TypeScript | Strict mode on |
| Styling | Tailwind CSS | Tokens injected via `tailwind.config.ts` |
| Stories | Storybook 8 (React-Vite) | A11y addon + Interactions addon enabled |
| Figma bridge | Figma MCP (remote) | Endpoint: `https://mcp.figma.com/mcp` |
| Skills | `/prototype-to-figma`, `/figma-generate-design`, `/figma-generate-library`, `/figma-use` | Pre-installed once Figma MCP is connected |

## Figma File Reference

The Figma `fileKey` lives in `.env` as `FIGMA_FILE_KEY` (used by `pnpm visual:check`). Each UI story carries its target's `node-id` in its References section — the dev agent reads the link with the Figma MCP during Step 0. Maintain an internal table of the file's Atoms / Molecules / Organisms / Screen frame node-ids if it helps PMs author stories.

## Step 0 — Refine the incoming story (run ONCE per story, before the loop)

In real projects the dev agent does not author stories — a PM or architect creates them via `bmad-create-story` from a PRD or epic. What lands in the sprint is typically:

- A title and `As a / I want / So that`
- Acceptance Criteria scoped to user-facing behavior
- A **Figma reference link** in `References`
- Generic Tasks (often: "implement the component", "review")

That story is necessary but not sufficient. The dev agent MUST refine it before starting implementation. In particular: **when this module is adopted into a brownfield project, the first stories will frequently target deep composites (an organism, a screen) when no atoms exist in `src/components/atoms/` yet.** The refinement step handles this by decomposing recursively and producing a bottom-up build plan — not by HALTing on missing dependencies.

The refinement actions:

1. **Resolve the Figma link.** Pull `fileKey` and `node-id` from the link in References. Verify the node resolves via Figma MCP (`get_code`). If not, HALT and ask the user.

2. **Classify the target.** Decide whether the Figma node represents an atom, molecule, organism, or screen — based on what it composes and where it sits in the design system. Persist the classification in the story's Dev Notes.

3. **Decompose recursively.** If the target is anything but a leaf atom, walk every visual primitive it composes and identify the lower-layer component each one maps to. Recurse all the way down to atoms. The output is a *dependency tree* with the target at the root and atoms at the leaves.

4. **Run a Reuse Check on every node of the tree** (target + every dependency):
   - **REUSE** — exists at `src/components/<layer>/<Name>/` and matches Figma → import it, no work.
   - **EXTEND** — exists, but a variant the story needs is missing → mark for extension.
   - **UPDATE** — exists but conflicts with Figma (design moved) → HALT and ask the user before proceeding.
   - **OFF-LAYER** (brownfield case) — exists somewhere in the codebase but NOT under the atomic structure (e.g., a flat `src/components/Button.tsx` with no `atoms/` parent). HALT and ask the user: refactor into the proper layer, reuse as-is, or build a parallel atomic version. Do not decide silently.
   - **CREATE** — does not exist → mark for creation at the correct layer folder (`src/components/atoms/...`, `molecules/...`, etc.).

5. **Produce a bottom-up build plan.** Rewrite the story's Tasks to schedule one execution of the 5-step loop per CREATE or EXTEND, in dependency order (atoms first, then their consumers, finally the target). Each task spells out the component name, the layer folder, the Figma node-id it derives from, the variants/states to cover, and the `pnpm visual:check` command for each variant.

6. **Strengthen the Acceptance Criteria** so they reference the Visual Validation Loop, the no-hardcoded-tokens rule, the Storybook-story-per-variant requirement, and the layer-correctness rule (atoms in `atoms/`, molecules in `molecules/`, etc.).

7. **Surface the build plan to the user** if more than three components will be created. List the components, their layers, and their order; ask for confirmation before persisting. This prevents a "build one badge" story silently expanding into twenty components without anyone noticing.

8. **Detect explicit scope errors.** If the story's stated scope is itself a discovery-shaped statement — e.g., "build all the molecules", "implement the entire icon library" — HALT and surface that this should be split via the discovery pattern (one story for discovery, N stories for implementation, one for bulk sync). This is different from the recursive build above: here the problem is the story's framing, not the dependency tree.

9. **Persist the edits** to the story file before starting implementation. The refined version is the artifact of record.

Only after the story is refined does the per-component loop below begin. Each task from the build plan executes the loop independently — atoms first, then their consumers, finally the target — and each one passes through visual validation and Figma sync-back before the next starts.

## Per-Component Loop (apply to every component in every story)

```
Figma MCP read node → identify variants → derive props + states
   → write component + Tailwind classes (tokens only)
   → write .stories.tsx (Default + one story per variant)
   → run Storybook, manual eyeball check
   → Visual Validation Loop (see next section) — MANDATORY, screenshot + checklist
   → prototype-to-figma push to "Built / <Layer>" page in same Figma file
   → diff vs original frame, fix any drift
   → mark task done
```

## Visual Validation Loop (MANDATORY per component)

Manual eyeball checks are not acceptance criteria. Every component MUST pass the visual validation loop **before being marked done**. This is what catches the "looks right but isn't" defects (font weight 600 instead of 700, border-radius falling back to a Tailwind default, opacity guessed for the disabled state).

### How it runs

For each component (and for each meaningful story of that component), run:

```bash
pnpm visual:check --story <storybook-story-id> --figma-node <node-id> --out <component>/<variant>
```

The `visual:check` script (installed at [scripts/visual-check.mjs](../../scripts/visual-check.mjs)) does:

1. Boots a headless Chromium via Playwright at 2x device pixel ratio
2. Navigates to `http://localhost:6006/iframe.html?id=<storyId>&viewMode=story`
3. Waits for the story to be fully rendered (no animation, fonts loaded)
4. Screenshots the story canvas → `_visual-checks/<out>/actual.png`
5. Calls the Figma REST API (`GET /v1/images/<file>?ids=<node>&scale=2&format=png`) using `FIGMA_TOKEN`
6. Downloads the Figma render → `_visual-checks/<out>/expected.png`
7. Prints both absolute paths

The dev agent then **reads both PNGs** (Claude is multimodal) and runs them through the **Visual Checklist** below. Any item that fails enters a fix loop: identify the failing property → look up the exact value in Figma (via Figma MCP `get_variable_defs` or `get_code`) → adjust Tailwind class or token → re-render → re-screenshot → re-check.

### Visual Checklist (run for every story of every component)

For each item: ✅ matches Figma / ❌ drift → note + fix.

**Color**
- [ ] Background color (including alpha)
- [ ] Text color
- [ ] Icon color (read the icon node's own fill, not the parent's)
- [ ] Border color
- [ ] Each gradient stop (and the gradient angle)

**Typography**
- [ ] Font family (full name, not the substitute the OS rendered)
- [ ] Font weight (400/500/600/700 are easy to mis-read by eye)
- [ ] Font size (px or rem matching the token)
- [ ] Line-height
- [ ] Letter-spacing (especially negative tracking on display sizes)

**Box**
- [ ] Width / height where Figma fixes them
- [ ] Padding (each side, not just symmetric)
- [ ] Gap (flex/grid)
- [ ] Border-radius (each corner if Figma uses individual radii)
- [ ] Border width (each side if `individualStrokeWeights` differ)
- [ ] Shadow (offset x/y, blur, spread, color, alpha — per layer if multi-shadow)
- [ ] Opacity

**States** (one story per state)
- [ ] Default
- [ ] Hover
- [ ] Active / pressed
- [ ] Focus (visible focus ring matches Figma's focus variant if present)
- [ ] Disabled (use the design system's disabled color — do NOT guess `opacity-50`)
- [ ] Loading / skeleton (if Figma documents it)
- [ ] Error / invalid (if Figma documents it)

**Affordances**
- [ ] `cursor-pointer` on interactive elements; `cursor-not-allowed` on disabled
- [ ] Text truncation matches Figma (ellipsis, line clamp, or full-bleed)

**Responsive**
- [ ] At each breakpoint Figma documents, the component still matches its Figma counterpart

### Source-of-truth rule

When `actual.png` and `expected.png` disagree, the design tokens and Figma values are the source of truth — **never** measure pixels off either PNG by eye. Resolve via:

- `get_variable_defs` on the component's node-id (tokens)
- `get_code` on the component's node-id (Figma's own CSS approximation, sanity-check only)
- The `src/tokens/tokens.ts` file in this repo

If a value in Figma has no corresponding token in `src/tokens/tokens.ts`, HALT and surface back — silent ad-hoc additions to the token set are a defect.

### When to keep the screenshots

`_visual-checks/` is `.gitignore`d by default. Keep the folder around for the duration of a story's dev pass; clear it once the story is `done`. The verification artifacts (which match, which drifted, what was fixed) go into `Completion Notes List` of the story file as text, not as committed PNGs.

## Verification Gate (HALT if any fails)

- [ ] Component renders without console errors in Storybook
- [ ] All Figma-documented variants have a corresponding story
- [ ] No hardcoded color/spacing values — tokens only
- [ ] **Visual Validation Loop run for every story, every checklist item ticked**
- [ ] `prototype-to-figma` round-trip placed the built version on canvas
- [ ] A11y addon shows zero critical violations
- [ ] Component imports only from layers below it (atoms ← nothing UI; molecules ← atoms; organisms ← molecules/atoms; screen ← organisms)

## When Figma MCP is not available

If `https://mcp.figma.com/mcp` is not reachable (auth not done, offline, etc.):

1. **HALT before coding** — do not invent visuals.
2. Ask the user to either (a) authenticate the Figma MCP, or (b) provide PNG exports + token values for the referenced node.
3. Once unblocked, resume from "Figma MCP read node" above.

## Reverse-sync naming convention

Use these page names in the Figma file when pushing built results back:

- `Built / Atoms`
- `Built / Molecules`
- `Built / Organisms`
- `Built / Screen`

This keeps the original design frames pristine while creating a visual diff lane.
