# Story 1.3: Molecules — Compose atoms into molecules

Status: ready-for-dev

## Story

As a **demo presenter**,
I want **every molecule in the Figma "Molecules" frame implemented by composing existing atoms (no atom is re-implemented)**,
so that **the audience sees Atomic Design's reuse principle in action: small things compose into bigger things**.

## Acceptance Criteria

1. Every molecule present in the Figma frame `4:726` (file `7vcHVM7siztlW4xId0ClVZ`) is implemented under `src/components/molecules/<Molecule>/`.
2. Each molecule is built **strictly by composing atoms** from `src/components/atoms/`. If a needed atom doesn't exist, HALT and surface it back to the user — do not invent it here.
3. Each molecule ships with `<Molecule>.tsx` + `<Molecule>.stories.tsx` + `index.ts`, following the same pattern as atoms.
4. Stories cover `Default` + one story per Figma-documented variant or state.
5. No hardcoded visual values — molecules consume tokens (via atoms, or directly via Tailwind utilities for layout-only concerns like flex/grid/gap).
6. After all molecules are built, `prototype-to-figma` syncs them to a Figma page named `Built / Molecules`. Diff vs original; drift documented in `Completion Notes List`.
7. A11y: each molecule story has zero critical violations.
8. **Visual Validation Loop passed for every story of every molecule**: `pnpm visual:check` produced `actual.png` + `expected.png` per story, the Visual Checklist was walked, drift fixed and re-validated until clean. Outcomes summarized per molecule in `Completion Notes List`.

## Tasks / Subtasks

- [ ] **Task 1: Enumerate molecules from Figma** (AC: #1)
  - [ ] Use Figma MCP to read node `4:726`
  - [ ] List every distinct molecule + the atoms it composes
  - [ ] For each molecule, verify the required atoms exist in `src/components/atoms/`; if any are missing, HALT
- [ ] **Task 2: Implement each molecule** (AC: #1–#5)
  - For each molecule from Task 1:
    - [ ] Create `src/components/molecules/<Molecule>/<Molecule>.tsx` composing existing atoms
    - [ ] Write `<Molecule>.stories.tsx` with `Default` + variant stories
    - [ ] Verify in Storybook
    - [ ] Tick the checkbox before moving on
- [ ] **Task 3: A11y pass** (AC: #7)
  - [ ] Resolve all critical a11y violations on each molecule story
- [ ] **Task 3b: Visual Validation Loop per molecule** (AC: #8)
  - [ ] For each molecule and each of its stories: `pnpm visual:check --story <storyId> --figma-node <variant-node-id> --out molecules/<molecule-kebab>/<variant>`
  - [ ] Read both PNGs, walk the Visual Checklist, fix drift, re-validate. Record outcome in `Completion Notes List`.
- [ ] **Task 4: Sync back to Figma** (AC: #6)
  - [ ] Run `/prototype-to-figma` against Storybook URL, target page `Built / Molecules`
  - [ ] Side-by-side diff vs original `Molecules` frame
  - [ ] Note drift; fix unintentional drift
- [ ] **Task 5: Verification gate**
  - [ ] No molecule directly re-implements atom-level visuals
  - [ ] All molecules render without errors
  - [ ] `Built / Molecules` page exists in Figma
  - [ ] Update `Status:` to `done`

## Dev Notes

- **Composition rule:** a molecule = atoms + minimal layout glue. If a molecule needs visual primitives that don't exist as atoms, that's a signal to extend Story 1.2 — do not patch it inside the molecule.
- **Naming mirrors Figma.** If Figma calls it `SearchField`, the React component is `SearchField`.
- Storybook stories should illustrate the molecule's *use cases*, not just its variants — e.g. `FormFieldWithError`, `FormFieldDisabled`.

### Project Structure Notes

```
src/components/molecules/
├── SearchField/
│   ├── index.ts
│   ├── SearchField.tsx           ← imports Input + Button from atoms
│   └── SearchField.stories.tsx
└── ... (one folder per molecule)
```

### References

- [Molecules frame in Figma](https://www.figma.com/design/7vcHVM7siztlW4xId0ClVZ/story-book-fisrt-demo?node-id=4-726)
- [Source: docs/workflows/storybook-first-with-figma.md#Per-Component Loop]
- Predecessor: Story 1.2 (`1-2-atoms.md`) — atoms MUST be done

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References


