# Story 1.5: Full Screen — Assemble organisms into the final page

Status: ready-for-dev

## Story

As a **demo presenter**,
I want **the full screen from the Figma "Tela completa" frame assembled as a page that composes existing organisms (no new visual primitives)**,
so that **the demo lands the punchline: Atomic Design built bottom-up produces the final screen as a thin composition**.

## Acceptance Criteria

1. The full screen from Figma frame `4:1015` (file `7vcHVM7siztlW4xId0ClVZ`) is implemented at `src/pages/HomePage.tsx` (or whichever name reflects the Figma frame title).
2. The page composes only organisms (and atoms/molecules where genuinely standalone, e.g. spacing utilities). It introduces zero new visual primitives.
3. A Storybook story `src/pages/HomePage.stories.tsx` renders the full screen as a "Page" story (`parameters: { layout: 'fullscreen' }`), with realistic mock data composed from each organism's `*.mock.ts`.
4. The page also renders standalone at `/` (or another route) via the running Vite app — `npm run dev` shows the full screen.
5. The page is responsive at the breakpoints Figma documents (or a sensible default: mobile / tablet / desktop).
6. `/prototype-to-figma` syncs the built page to a Figma page named `Built / Screen`. A side-by-side diff with `4:1015` is captured and noted in `Completion Notes List`.
7. A11y: zero critical violations on the page story.
7b. **Visual Validation Loop passed for the page** at the mobile / tablet / desktop breakpoints documented in Figma: `pnpm visual:check` produced `actual.png` + `expected.png` per breakpoint, the Visual Checklist was walked, drift fixed and re-validated until clean. Outcomes per breakpoint recorded in `Completion Notes List`.
8. The demo can be presented end-to-end:
   - Open Storybook → click through Atoms → Molecules → Organisms → Page
   - Open the live Vite app → see the final screen
   - Open Figma → switch between original frames and `Built /...` pages to show parity

## Tasks / Subtasks

- [ ] **Task 1: Read the full screen from Figma** (AC: #1, #2)
  - [ ] Use Figma MCP to read node `4:1015`
  - [ ] Identify which organisms make up the page and in what order
  - [ ] Verify all required organisms exist in `src/components/organisms/`; HALT if any are missing
- [ ] **Task 2: Assemble the page** (AC: #1–#3)
  - [ ] Create `src/pages/HomePage.tsx` composing organisms in the layout shown in Figma
  - [ ] Wire up mock data from each organism's `*.mock.ts`
  - [ ] Create `src/pages/HomePage.stories.tsx` (`layout: 'fullscreen'`)
- [ ] **Task 3: Wire to live route** (AC: #4)
  - [ ] Update `App.tsx` (or add a tiny router) so `/` renders `HomePage`
  - [ ] Verify `npm run dev` shows the full screen
- [ ] **Task 4: Responsive check** (AC: #5)
  - [ ] Test at mobile / tablet / desktop breakpoints in Storybook viewport addon and in the live app
  - [ ] Fix any layout breaks; defer non-Figma-documented breakpoints to a follow-up rather than guessing
- [ ] **Task 4b: Visual Validation Loop per breakpoint** (AC: #7b)
  - [ ] For each Figma-documented breakpoint: `pnpm visual:check --story <pageStoryId> --figma-node <breakpoint-node-id> --out screen/<breakpoint>`
        (the screen-level `visual:check` may need a `--viewport <w>x<h>` flag — add it to `scripts/visual-check.mjs` if missing)
  - [ ] Read both PNGs, walk the Visual Checklist, fix drift, re-validate. Record outcome per breakpoint in `Completion Notes List`.
- [ ] **Task 5: Sync back to Figma** (AC: #6)
  - [ ] `/prototype-to-figma` targeting page `Built / Screen`
  - [ ] Capture a screenshot of the side-by-side diff (in `Completion Notes List` or `docs/`)
- [ ] **Task 6: A11y pass** (AC: #7)
- [ ] **Task 7: Final verification gate** (AC: #8)
  - [ ] Walk the demo path top-to-bottom: Storybook atoms → molecules → organisms → page → live app → Figma `Built /...` pages
  - [ ] Update `Status:` to `done`
  - [ ] Update epic/retrospective notes if the project has them

## Dev Notes

- **No new components in this story.** If you find yourself writing a `<div>` with non-trivial visual rules, that's a missed organism — surface it back and defer rather than absorbing it here.
- **Mock data composition** is the trick to a clean page: assemble props from each organism's mock module so the page itself stays declarative.
- The **demo narrative** is the most important deliverable: the page should look right, but more importantly, the audience should *see* that nothing was built twice.

### Project Structure Notes

```
src/
├── pages/
│   ├── HomePage.tsx
│   └── HomePage.stories.tsx
└── App.tsx                  ← renders HomePage at /
```

### References

- [Full screen frame in Figma](https://www.figma.com/design/7vcHVM7siztlW4xId0ClVZ/story-book-fisrt-demo?node-id=4-1015)
- [Source: docs/workflows/storybook-first-with-figma.md#Per-Component Loop]
- Predecessor: Story 1.4 (`1-4-organisms.md`)

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References


