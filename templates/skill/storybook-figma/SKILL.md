---
name: storybook-figma
description: |
  Build a pixel-perfect React component (or full atomic-design tree) directly
  from a Figma node, with automated visual validation and optional sync-back
  to the Figma canvas. Use when the user provides a Figma link and wants to
  implement what is in it as code — no story file or sprint required.
  Trigger keywords: "figma", "build this component", "implement this design",
  "replicate this frame".
---

# Storybook-First with Figma — Skill

> **Standalone (no-BMad) version.** Replaces the `bmad-dev-story` customization with a single-shot skill: the user passes a Figma link and this skill runs the entire flow (preflight → decomposition → bottom-up build → visual diff → optional sync-back) in one conversation.
>
> The long-form workflow doc lives at [`docs/workflows/storybook-first-with-figma.md`](../../../docs/workflows/storybook-first-with-figma.md) in the project — load it as the canonical reference when this skill is active.

## Input

Expect ONE of these from the user, in order of preference:

1. A Figma node URL in the form `https://www.figma.com/design/<fileKey>/<name>?node-id=<nodeId>` (or `/file/`, legacy).
2. A `fileKey` + `node-id` pair stated explicitly.
3. The phrase "use the file key from `.env`" + a `node-id`.

If none of these are present, HALT and ask:

> Paste the Figma node URL you want me to implement (right-click the frame → Copy link), or give me a fileKey + node-id pair.

Parse the URL: `fileKey` is the segment after `/design/` or `/file/`; `node-id` is the `node-id=` query param (URL-decoded — `:` may appear as `%3A`).

## Preflight (run FIRST, before anything else)

Verify in order, HALT on the first failure with the exact remediation message:

1. **Figma MCP tools available.** Probe via `mcp__figma__get_code` against the parsed node-id.
   - On failure: *"Figma MCP not connected — open Claude Code → /mcp → approve `figma`, then re-run this skill."*
2. **`.env` exists at project root with non-empty `FIGMA_TOKEN`.**
   - On failure: *"FIGMA_TOKEN missing — open `.env` (or `cp .env.example .env` if it does not exist) and paste a personal access token from https://www.figma.com/settings → Personal access tokens, then re-run this skill."*
3. **`.env` has `FIGMA_FILE_KEY` set** (or the URL contained one).
   - On failure: *"FIGMA_FILE_KEY missing — set it in `.env` to the file key from your Figma URL."*
4. **`scripts/visual-check.mjs` exists.**
   - On failure: *"visual-check.mjs missing — re-run the module installer (install.sh)."*
5. **Playwright runtime present** (`node_modules/playwright` exists OR `<pm> exec playwright --version` exits 0).
   - On failure: *"Playwright not installed — run `pnpm i -D playwright @playwright/test dotenv && pnpm exec playwright install chromium` (or your project's package manager equivalent)."*
6. **`package.json` has `scripts.visual:check`** set to `node scripts/visual-check.mjs`.
   - On failure: *"Missing npm script — add `\"visual:check\": \"node scripts/visual-check.mjs\"` to package.json scripts."*
7. **Storybook present** — check for `.storybook/main.*` (js/ts/cjs/mjs) OR any `@storybook/*` entry in `package.json` dependencies.
   - On failure: *"Storybook not set up — run `pnpm dlx storybook@latest init` (or your framework's equivalent), commit the generated `.storybook/` folder, then re-run this skill."*

Each HALT message IS the remediation — never invent a fallback that bypasses any check, and never silently downgrade to manual eyeballing.

## Step 0 — Decompose and produce a build plan

Once preflight passes:

1. **Resolve the Figma reference.** Call `mcp__figma__get_code` (and `get_variable_defs`) against the node-id. Verify the node resolves. If not, HALT and ask the user to re-share the link.
2. **Classify the target.** Decide whether the node is an atom, molecule, organism, or screen — based on what it composes and where it sits in the design system. State the classification verbatim in your first response so the user can correct it before implementation begins.
3. **Decompose recursively.** If the target is anything but a leaf atom, walk every visual primitive it composes and identify the lower-layer component each one maps to. Recurse all the way down to atoms. The output is a *dependency tree* with the target at the root and atoms at the leaves.
4. **Run a Reuse Check on every node of the tree** (target + every dependency):
   - **REUSE** — exists at `src/components/<layer>/<Name>/` and matches Figma → import it, no work.
   - **EXTEND** — exists, but a variant the target needs is missing → mark for extension.
   - **UPDATE** — exists but conflicts with Figma (design moved) → HALT and ask the user before proceeding.
   - **OFF-LAYER** (brownfield case) — exists somewhere in the codebase but NOT under the atomic structure (e.g., a flat `src/components/Button.tsx` with no `atoms/` parent). HALT and ask the user: refactor into the proper layer, reuse as-is, or build a parallel atomic version.
   - **CREATE** — does not exist → mark for creation at the correct layer folder.
5. **Produce a bottom-up build plan** as a numbered list in the chat. Each step spells out the component name, the layer folder, the Figma node-id it derives from, the variants/states to cover, and the `pnpm visual:check` command for each variant.
6. **Surface the plan to the user** before starting if more than three components will be created. List the components, their layers, and their order; ask for confirmation. This prevents a "build one badge" request silently expanding into twenty components without anyone noticing.
7. **Detect explicit scope errors.** If the user's stated scope is itself a discovery-shaped request — e.g., "build all the molecules", "implement the entire icon library" — HALT and surface that this should be split (one pass for discovery, N passes for implementation, one for bulk sync).

Only after the plan is confirmed does the per-component loop below begin. Each entry in the build plan executes the loop independently — atoms first, then their consumers, finally the target — and each one passes through visual validation and (optionally) Figma sync-back before the next starts.

## Storybook dev server lifecycle

BEFORE the first `pnpm visual:check` call in any per-component loop, verify the Storybook dev server is reachable at `http://localhost:6006/iframe.html` (probe via `curl -s -o /dev/null -w '%{http_code}' --max-time 3 http://localhost:6006/iframe.html` or equivalent fetch).

If not reachable: start it in the BACKGROUND using the Bash tool with `run_in_background: true` and the project's storybook script (commonly `pnpm storybook` — fall back to `npm run storybook` / `yarn storybook` / `bun storybook` based on the lockfile detected during preflight). Poll `http://localhost:6006/iframe.html` every 2 seconds with a 60-second cap until HTTP 200; on cap, HALT with the captured Storybook startup logs (common causes: port 6006 in use, framework-specific build error, missing `.storybook/main.*`).

Do NOT kill the server at the end of the skill — leave it running so subsequent invocations reuse the same instance.

## Per-component loop (apply to every entry in the build plan)

```
Figma MCP read node → identify variants → derive props + states
   → write component + Tailwind classes (tokens only)
   → write .stories.tsx (Default + one story per variant)
   → ensure Storybook dev server is up (see above)
   → Visual Validation Loop — MANDATORY, screenshot + checklist
   → (optional) /prototype-to-figma push to "Built / <Layer>" page
   → diff vs original frame, fix any drift
   → next component
```

## Visual Validation Loop (MANDATORY per component)

Manual eyeball checks are not acceptance criteria. Every component MUST pass the visual validation loop before being marked done. For each variant:

```bash
pnpm visual:check --story <storybook-story-id> --figma-node <node-id> --out <component>/<variant>
```

The script saves both PNGs under `_visual-checks/<out>/{actual,expected}.png`. Then:

1. Read both PNGs (you are multimodal — load them as images).
2. Walk the Visual Checklist in [`docs/workflows/storybook-first-with-figma.md`](../../../docs/workflows/storybook-first-with-figma.md#visual-checklist-run-for-every-story-of-every-component) — Color / Typography / Box / States / Affordances / Responsive.
3. Any failure enters a fix loop: identify the failing property → look up the exact value in Figma (via `get_variable_defs` or `get_code`) → adjust Tailwind class or token → re-render → re-screenshot → re-check.

**Source-of-truth rule.** When `actual.png` and `expected.png` disagree, Figma values and design tokens are the source of truth — never measure pixels off either PNG by eye. Resolve via `get_variable_defs` / `get_code` and the project's `src/tokens/tokens.ts`.

If a value in Figma has no corresponding token in `src/tokens/tokens.ts`, HALT and surface back — silent ad-hoc additions to the token set are a defect.

## Hard rules (non-negotiable)

- **Atomic Design layering.** Atoms in `src/components/atoms/<Name>/`, molecules in `molecules/`, organisms in `organisms/`. Lower layers built before higher layers; higher layers MUST import existing lower-layer components, not duplicate them.
- **Tokens only.** Design tokens (color, spacing, radius, typography) live in `src/tokens/tokens.ts` and `tailwind.config.ts` and are the single source of truth. Hardcoded hex/px values are a defect.
- **One Storybook story per variant.** Every component ships with a `.stories.tsx` covering Default plus one story per Figma-documented variant or state.
- **Recursive build mandate.** Every atom belongs in `src/components/atoms/<Name>/`, every molecule in `src/components/molecules/<Name>/`, etc., regardless of whether it was discovered as a dependency of a larger target or as the user's explicit request — never build a lower-layer primitive inline inside a higher-layer file.
- **Figma file structure expected.** Published Variables for design tokens, atomic-design frames (Atoms/Molecules/Organisms/Screen), and Components with complete variant sets. If any of these are missing at runtime, surface the gap to the user — do not silently invent structure or token names.

## Verification gate (HALT if any fails)

Before reporting any component done:

- [ ] Component renders without console errors in Storybook
- [ ] All Figma-documented variants have a corresponding story
- [ ] No hardcoded color/spacing values — tokens only
- [ ] **Visual Validation Loop run for every variant, every checklist item ticked**
- [ ] (Optional) `prototype-to-figma` round-trip placed the built version on canvas
- [ ] A11y addon shows zero critical violations
- [ ] Component imports only from layers below it

## When Figma MCP is not available mid-run

If `https://mcp.figma.com/mcp` becomes unreachable after preflight passed (auth expired, network dropped):

1. **HALT before coding** — do not invent visuals.
2. Ask the user to either (a) re-authenticate the Figma MCP, or (b) provide PNG exports + token values for the referenced node.
3. Once unblocked, resume from "Figma MCP read node" above.

## Reverse-sync naming convention

When pushing built results back via `/prototype-to-figma`, use these page names:

- `Built / Atoms`
- `Built / Molecules`
- `Built / Organisms`
- `Built / Screen`

This keeps the original design frames pristine while creating a visual diff lane.

## What this skill does NOT do

- It does not write a BMad story file. There is no `bmad-create-story`, no `sprint-status.yaml`, no PM-authored AC. The Figma link IS the input.
- It does not install Storybook, Playwright, or the Figma MCP — preflight HALTs with the install instruction if any is missing.
- It does not modify `tailwind.config.ts` or `src/tokens/tokens.ts` silently — if a Figma value has no matching token, it surfaces the gap.
