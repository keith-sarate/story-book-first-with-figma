# Story 1.2.0: Atoms Discovery — Read Figma and scaffold one story per atom

Status: ready-for-dev

<!--
  This story does NOT implement any UI. It reads the Atoms frame in Figma and
  generates one ready-for-dev story file per atom found, so the demo can build
  them one at a time live.
-->

## Story

As a **demo presenter who wants to show atoms appearing in Storybook one by one**,
I want **the dev agent to read the Figma Atoms frame and scaffold a per-atom story file (plus a final sync story) into `_bmad-output/implementation-artifacts/`**,
so that **each subsequent `dev the next story` call builds exactly one atom — a clean demo beat**.

## Acceptance Criteria

1. The Figma MCP server is reachable; if not, HALT with a clear message before any file is written.
2. The dev reads node `4:581` (file `7vcHVM7siztlW4xId0ClVZ`) and produces an ordered list of distinct atoms found, with: display name, node-id, kebab-case slug, and a short one-line description per atom.
3. The ordered list is written to `Completion Notes List` in this file for traceability.
4. For each atom (in the order from AC #2), a story file is created at:
   `_bmad-output/implementation-artifacts/1-2-<n>-<atom-kebab>.md`
   where `<n>` is 1-based.
   Each file is generated from `_atom-story-template.md` with placeholders filled:
   `{{n}}`, `{{AtomName}}`, `{{atom-kebab}}`, `{{atom_node_id}}`, `{{atom_figma_url}}`.
5. A final bulk-sync story is created at:
   `_bmad-output/implementation-artifacts/1-2-99-atoms-sync.md`
   containing the tasks to run `/prototype-to-figma` against the live Storybook URL, target page `Built / Atoms`, and to diff each atom side-by-side with the original frame.
6. `sprint-status.yaml` is updated:
   - This story (`1-2-0-atoms-discovery`) flips to `done`
   - One entry per generated atom story is appended with `status: ready-for-dev`, in order
   - `1-2-99-atoms-sync` is appended with `status: ready-for-dev` and `depends_on` listing every per-atom key
   - The existing `1-3-molecules` entry's `depends_on` is updated from `[1-2-atoms]` to `[1-2-99-atoms-sync]`
7. No React/CSS code is written in this story. UI implementation begins in the per-atom stories generated here.

## Tasks / Subtasks

- [ ] **Task 1: Verify Figma MCP** (AC: #1)
  - [ ] Confirm `mcp__figma__*` tools are available
  - [ ] If not, HALT and ask the user to authenticate via `/mcp`
- [ ] **Task 2: Enumerate atoms** (AC: #2, #3)
  - [ ] Read node `4:581` of file `7vcHVM7siztlW4xId0ClVZ`
  - [ ] For each child that is a distinct atom (component, variant set, or stand-alone reusable primitive), capture:
    - Display name (PascalCase, matching Figma)
    - kebab-case slug (e.g. `Button` → `button`, `IconButton` → `icon-button`)
    - node-id (full `<file>?node-id=...` URL too)
    - One-line description (Figma component description or your best summary)
  - [ ] Ignore decorative duplicates and non-component frames
  - [ ] Write the ordered list into `Completion Notes List` below
  - [ ] Pause and present the list to the user for confirmation before Task 3 (this prevents creating throwaway story files)
- [ ] **Task 3: Generate per-atom story files** (AC: #4)
  - [ ] Load template `_atom-story-template.md`
  - [ ] For each atom (in confirmed order), write `1-2-<n>-<atom-kebab>.md` with placeholders replaced
- [ ] **Task 4: Generate atoms-sync story** (AC: #5)
  - [ ] Write `1-2-99-atoms-sync.md` (skeleton below in Dev Notes — adapt to actual atom count)
- [ ] **Task 5: Update sprint-status.yaml** (AC: #6)
  - [ ] Flip this story to `done`
  - [ ] Append per-atom entries in order, each with `status: ready-for-dev` and `depends_on: [1-1-bootstrap-and-tokens]`
  - [ ] Append `1-2-99-atoms-sync` with `depends_on` listing every per-atom key
  - [ ] Update `1-3-molecules.depends_on` to `[1-2-99-atoms-sync]`
- [ ] **Task 6: Report**
  - [ ] Print to the user: "Discovery done — N atom stories ready. Next: `dev the next story`."

## Dev Notes

### Skeleton for `1-2-99-atoms-sync.md`

```markdown
# Story 1.2.99: Atoms — Bulk sync to Figma

Status: ready-for-dev

## Story

As a demo presenter, I want every implemented atom pushed back to the Figma
file on a `Built / Atoms` page, so the audience sees design-to-code parity round-trip.

## Acceptance Criteria

1. Storybook is running locally (Storybook URL captured).
2. `/prototype-to-figma` is invoked against the Storybook URL targeting page `Built / Atoms` in file `7vcHVM7siztlW4xId0ClVZ`.
3. Each atom appears on the `Built / Atoms` page in Figma.
4. A side-by-side comparison vs the original `Atoms` frame is captured; any drift > intentional is fixed and re-synced.
5. Sprint-status entry for `1-2-99-atoms-sync` flips to `done`.

## Tasks / Subtasks

- [ ] Boot Storybook (`npm run storybook`) and capture the URL
- [ ] Invoke `/prototype-to-figma` → page `Built / Atoms`
- [ ] Open Figma and diff each atom vs the source `Atoms` frame
- [ ] Fix any unintentional drift and re-sync
- [ ] Mark done

## References

- [Atoms frame](https://www.figma.com/design/7vcHVM7siztlW4xId0ClVZ/story-book-fisrt-demo?node-id=4-581)
- [Source: docs/workflows/storybook-first-with-figma.md#Reverse-sync naming convention]
```

### sprint-status.yaml append shape (per atom)

```yaml
  1-2-<n>-<atom-kebab>:
    status: ready-for-dev
    title: "Atom — <AtomName>"
    file: 1-2-<n>-<atom-kebab>.md
    depends_on: [1-1-bootstrap-and-tokens]
```

### Why discovery is a separate story

- We don't know the atom count or names without reading Figma.
- Generating files mid-implementation pollutes commits; doing it as its own story keeps the demo crisp ("Step: discovery. Step: build atom 1. Step: build atom 2...").
- The pause-for-confirmation in Task 2 lets you trim the list before N story files exist.

### References

- [Atoms frame in Figma](https://www.figma.com/design/7vcHVM7siztlW4xId0ClVZ/story-book-fisrt-demo?node-id=4-581)
- [Template](_atom-story-template.md)
- [Source: docs/workflows/storybook-first-with-figma.md#Figma File Reference]

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References



### File List

