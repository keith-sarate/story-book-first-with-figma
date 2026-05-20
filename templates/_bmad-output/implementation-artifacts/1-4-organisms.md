# Story 1.4: Organisms — Compose molecules and atoms into organisms

Status: ready-for-dev

## Story

As a **demo presenter**,
I want **every organism in the Figma "Organisms" frame implemented by composing molecules and atoms**,
so that **the screen story (1.5) becomes a thin orchestration layer over already-tested pieces**.

## Acceptance Criteria

1. Every organism in the Figma frame `4:850` (file `7vcHVM7siztlW4xId0ClVZ`) is implemented under `src/components/organisms/<Organism>/`.
2. Organisms compose only molecules and atoms — no organism re-implements visual primitives.
3. Each organism has `<Organism>.tsx` + `<Organism>.stories.tsx` + `index.ts`.
4. Stories cover `Default` + variants/states present in Figma + at least one story with realistic mock data (e.g. a populated `Header` with logo + nav links + user menu).
5. No hardcoded visual tokens — only Tailwind utilities backed by `tokens.ts` and atom/molecule composition.
6. `/prototype-to-figma` syncs the built organisms to a Figma page named `Built / Organisms`. Drift documented.
7. A11y: zero critical violations per organism.
8. **Visual Validation Loop passed for every story of every organism**: `pnpm visual:check` produced `actual.png` + `expected.png` per story, the Visual Checklist was walked, drift fixed and re-validated until clean. Outcomes summarized per organism in `Completion Notes List`.

## Tasks / Subtasks

- [ ] **Task 1: Enumerate organisms from Figma** (AC: #1)
  - [ ] Read node `4:850` via Figma MCP
  - [ ] List each organism + the molecules and atoms it composes
  - [ ] Verify all required molecules/atoms exist; HALT if missing
- [ ] **Task 2: Implement each organism** (AC: #1–#5)
  - For each organism:
    - [ ] Create `src/components/organisms/<Organism>/<Organism>.tsx`
    - [ ] Build `<Organism>.stories.tsx` with `Default` + state/variant stories + at least one mock-data story
    - [ ] Visually verify in Storybook
    - [ ] Tick the checkbox before moving on
- [ ] **Task 3: A11y pass** (AC: #7)
  - [ ] Resolve all critical a11y violations
- [ ] **Task 3b: Visual Validation Loop per organism** (AC: #8)
  - [ ] For each organism and each of its stories: `pnpm visual:check --story <storyId> --figma-node <variant-node-id> --out organisms/<organism-kebab>/<variant>`
  - [ ] Read both PNGs, walk the Visual Checklist, fix drift, re-validate. Record outcome in `Completion Notes List`.
- [ ] **Task 4: Sync back to Figma** (AC: #6)
  - [ ] `/prototype-to-figma` → page `Built / Organisms`
  - [ ] Diff vs original `Organisms` frame; document drift
- [ ] **Task 5: Verification gate**
  - [ ] Organisms compose molecules/atoms only (verify via imports)
  - [ ] All render without errors
  - [ ] `Built / Organisms` page exists in Figma
  - [ ] Update `Status:` to `done`

## Dev Notes

- **Mock data lives next to the story file** — e.g. `Header.mock.ts` exporting `defaultHeaderProps` — so the screen story (1.5) can reuse the same realistic data.
- If an organism needs an atom or molecule that doesn't exist, HALT and surface back rather than inventing inline.
- Stories should be the most useful documentation an engineer or designer ever sees of this organism. Add `parameters.docs.description.story` blocks where context matters.

### Project Structure Notes

```
src/components/organisms/
├── Header/
│   ├── index.ts
│   ├── Header.tsx
│   ├── Header.mock.ts
│   └── Header.stories.tsx
└── ... (one folder per organism)
```

### References

- [Organisms frame in Figma](https://www.figma.com/design/7vcHVM7siztlW4xId0ClVZ/story-book-fisrt-demo?node-id=4-850)
- [Source: docs/workflows/storybook-first-with-figma.md#Per-Component Loop]
- Predecessor: Story 1.3 (`1-3-molecules.md`)

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References


