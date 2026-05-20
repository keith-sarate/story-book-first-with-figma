# Story 1.1: Project Bootstrap, Figma MCP & Design Tokens

Status: ready-for-dev

<!-- Run with: bmad-dev-story (or "dev this story _bmad-output/implementation-artifacts/1-1-bootstrap-and-tokens.md") -->

## Story

As a **demo presenter showcasing Atomic Design + Storybook + Figma**,
I want **a working Vite + React + TS + Tailwind + Storybook 8 project with the Figma MCP server connected and design tokens extracted from the Figma file**,
so that **every subsequent story (atoms → molecules → organisms → screen) can read directly from Figma and consume the same tokens**.

## Acceptance Criteria

1. A Vite + React + TypeScript project boots successfully at the repo root (or `app/` subfolder if cleaner), with `npm run dev` opening the app and `npm run build` producing a production bundle.
2. Tailwind CSS is installed and wired into Vite; `tailwind.config.ts` exists and is consumed at runtime (a sample utility class proves it).
3. Storybook 8 (`@storybook/react-vite`) runs via `npm run storybook` and shows the default Welcome story.
4. Storybook is configured with the **a11y** and **interactions** addons enabled.
5. The Figma MCP server is registered in `.mcp.json` at the project root pointing to `https://mcp.figma.com/mcp` (type `http`), and `claude mcp list` (or equivalent) shows it as configured.
6. Design tokens (colors, spacing, radii, typography, shadows) are extracted from the Figma file `7vcHVM7siztlW4xId0ClVZ` — specifically from the Atoms frame (`node-id=4-581`) and any shared styles/variables — into `src/tokens/tokens.ts` (or `.json`), and Tailwind's theme in `tailwind.config.ts` consumes them via `extend`.
7. A short README section under `docs/` documents how to run dev, storybook, and build, plus how to authenticate Figma MCP on first use.
8. **Playwright is installed as a devDep, and `scripts/visual-check.mjs` exists** — it takes `--story <id> --figma-node <node-id> --out <dir>` and writes `_visual-checks/<dir>/actual.png` (Storybook screenshot at 2x) and `_visual-checks/<dir>/expected.png` (Figma REST export at 2x). The npm script `pnpm visual:check` (or `npm run visual:check`) wires it.
9. `.env.example` documents the required `FIGMA_TOKEN` and `FIGMA_FILE_KEY=7vcHVM7siztlW4xId0ClVZ`. `.env` is gitignored. `_visual-checks/` is gitignored.
10. No atoms/molecules/organisms are implemented yet — this story is infrastructure only.

## Tasks / Subtasks

- [ ] **Task 1: Scaffold Vite + React + TS** (AC: #1)
  - [ ] Run `npm create vite@latest . -- --template react-ts` (or in `app/` if you prefer a subfolder — pick one and stick with it)
  - [ ] Install deps and verify `npm run dev` + `npm run build`
  - [ ] Add `.gitignore` entries for `node_modules`, `dist`, `storybook-static`
- [ ] **Task 2: Install and wire Tailwind CSS** (AC: #2)
  - [ ] Install `tailwindcss postcss autoprefixer` and run `npx tailwindcss init -p`
  - [ ] Create `src/index.css` with `@tailwind base; @tailwind components; @tailwind utilities;` and import it from `main.tsx`
  - [ ] Set `content` globs in `tailwind.config.ts` to cover `src/**/*.{ts,tsx}` and `.storybook/**/*`
  - [ ] Prove it with one utility class on the default page
- [ ] **Task 3: Install Storybook 8 (react-vite)** (AC: #3, #4)
  - [ ] Run `npx storybook@latest init --type react`
  - [ ] Add addons: `@storybook/addon-a11y`, `@storybook/addon-interactions`
  - [ ] Import the Tailwind CSS file in `.storybook/preview.ts` so all stories have Tailwind available
  - [ ] Verify `npm run storybook` boots
- [ ] **Task 4: Register the Figma MCP server** (AC: #5)
  - [ ] Create `.mcp.json` at the project root with content:
    ```json
    {
      "mcpServers": {
        "figma": { "type": "http", "url": "https://mcp.figma.com/mcp" }
      }
    }
    ```
  - [ ] Ask the user to run the auth flow in Claude Code (`/mcp` then approve `figma`)
  - [ ] Confirm MCP tools (`mcp__figma__*`) appear in the tool list before proceeding to Task 5
- [ ] **Task 5: Extract design tokens from Figma** (AC: #6)
  - [ ] Use Figma MCP to fetch the Atoms frame node `4:581` from file `7vcHVM7siztlW4xId0ClVZ`
  - [ ] Also fetch the file's published variables/styles if available (colors, text styles, effect styles)
  - [ ] Write `src/tokens/tokens.ts` exporting typed objects: `colors`, `spacing`, `radii`, `typography`, `shadows`
  - [ ] Wire them into `tailwind.config.ts` under `theme.extend`
  - [ ] Add `src/tokens/tokens.stories.mdx` (or `.mdx`) documenting the token swatches in Storybook
- [ ] **Task 6: Install Playwright + create visual-check script** (AC: #8, #9)
  - [ ] Install devDeps: `npm i -D playwright @playwright/test dotenv`
  - [ ] Run `npx playwright install chromium`  (deviation: Ubuntu 26.04 has no Playwright Chromium prebuilt; script defaults to system Google Chrome via `channel: 'chrome'`. See docs/README.md and `PLAYWRIGHT_CHANNEL` env.)
  - [ ] Create `scripts/visual-check.mjs` (template below in Dev Notes); make it executable and ESM
  - [ ] Add npm script `"visual:check": "node scripts/visual-check.mjs"` to `package.json`
  - [ ] Create `.env.example` with `FIGMA_TOKEN=` and `FIGMA_FILE_KEY=7vcHVM7siztlW4xId0ClVZ`
  - [ ] Add `.env`, `_visual-checks/`, `playwright-report/`, `test-results/` to `.gitignore`
  - [ ] Smoke test: with Storybook running, run `pnpm visual:check -- --story tokens-panel--default --figma-node 4:581 --out _smoke` and verify both PNGs are produced.
- [ ] **Task 7: Document setup** (AC: #7)
  - [ ] Append a "Getting Started" section to `docs/README.md` (create if absent): dev/build/storybook commands + Figma MCP auth steps + `FIGMA_TOKEN` setup (how to mint a personal access token at figma.com/settings) + how to run `pnpm visual:check`
- [ ] **Task 8: Verification gate**
  - [ ] `pnpm dev` works
  - [ ] `pnpm build` works
  - [ ] `pnpm storybook` shows the Tokens story with real values pulled from Figma
  - [ ] `.mcp.json` exists and Figma MCP is authenticated
  - [ ] `pnpm visual:check` smoke run produced both PNGs
  - [ ] Update `Status:` to `review` at the top of this file

## Dev Notes

This story is the foundation for stories 1.2–1.5. **No UI components yet** — only the rails.

- **Atomic Design rule starts here, not later:** the folder structure must reflect it from day one. Create empty placeholder folders: `src/components/atoms/`, `src/components/molecules/`, `src/components/organisms/`, `src/pages/`.
- **Tokens are the bridge between Figma and code.** Every subsequent story will consume them. Get this right and the rest is mechanical.
- **Figma MCP setup is gated on user action** — Claude Code requires interactive OAuth approval. Do not skip Task 4's confirmation step; subsequent stories assume MCP is live.
- See the project-wide operating manual at `docs/workflows/storybook-first-with-figma.md` for the per-component loop you'll repeat in stories 1.2–1.5.

### Project Structure Notes

Recommended layout (create what's missing):

```
.
├── .mcp.json                       ← Task 4
├── .storybook/
│   ├── main.ts
│   └── preview.ts                  ← import '../src/index.css'
├── scripts/
│   └── visual-check.mjs            ← Task 6
├── .env.example                    ← Task 6 (FIGMA_TOKEN, FIGMA_FILE_KEY)
├── docs/
│   ├── README.md                   ← Task 7
│   └── workflows/
│       └── storybook-first-with-figma.md ← already created
├── src/
│   ├── index.css
│   ├── main.tsx
│   ├── App.tsx
│   ├── tokens/
│   │   ├── tokens.ts               ← Task 5
│   │   └── tokens.stories.mdx
│   └── components/
│       ├── atoms/                  (empty for now)
│       ├── molecules/              (empty for now)
│       └── organisms/              (empty for now)
├── tailwind.config.ts
├── postcss.config.js
└── vite.config.ts
```

### Template for `scripts/visual-check.mjs`

```javascript
#!/usr/bin/env node
// Visual validation: screenshot the Storybook story at 2x DPR and fetch the
// Figma node render at 2x. Saves both to _visual-checks/<out>/.
// Usage: node scripts/visual-check.mjs --story <storyId> --figma-node <nodeId> --out <dirname>

import { chromium } from 'playwright';
import { mkdir, writeFile } from 'node:fs/promises';
import { resolve, join } from 'node:path';
import { parseArgs } from 'node:util';
import 'dotenv/config';

const { values } = parseArgs({
  options: {
    story: { type: 'string' },
    'figma-node': { type: 'string' },
    out: { type: 'string' },
    'storybook-url': { type: 'string', default: 'http://localhost:6006' },
  },
});

if (!values.story || !values['figma-node'] || !values.out) {
  console.error('Usage: visual-check --story <storyId> --figma-node <nodeId> --out <dir>');
  process.exit(1);
}

const { FIGMA_TOKEN, FIGMA_FILE_KEY } = process.env;
if (!FIGMA_TOKEN || !FIGMA_FILE_KEY) {
  console.error('Set FIGMA_TOKEN and FIGMA_FILE_KEY in .env (see .env.example)');
  process.exit(1);
}

const outDir = resolve('_visual-checks', values.out);
await mkdir(outDir, { recursive: true });

// 1) Storybook screenshot via Playwright at 2x DPR
const browser = await chromium.launch();
const ctx = await browser.newContext({ deviceScaleFactor: 2 });
const page = await ctx.newPage();
const url = `${values['storybook-url']}/iframe.html?id=${values.story}&viewMode=story`;
await page.goto(url, { waitUntil: 'networkidle' });
await page.waitForLoadState('networkidle');
// Wait for fonts and any animations to settle
await page.evaluate(() => document.fonts.ready);
await page.waitForTimeout(300);
const actualPath = join(outDir, 'actual.png');
const root = page.locator('#storybook-root, #root');
await root.screenshot({ path: actualPath, omitBackground: false });
await browser.close();

// 2) Figma render via REST API
const figmaUrl = new URL(`https://api.figma.com/v1/images/${FIGMA_FILE_KEY}`);
figmaUrl.searchParams.set('ids', values['figma-node']);
figmaUrl.searchParams.set('scale', '2');
figmaUrl.searchParams.set('format', 'png');
const res = await fetch(figmaUrl, { headers: { 'X-Figma-Token': FIGMA_TOKEN } });
if (!res.ok) {
  console.error(`Figma API ${res.status}: ${await res.text()}`);
  process.exit(2);
}
const { images, err } = await res.json();
if (err) { console.error(`Figma error: ${err}`); process.exit(2); }
const cdnUrl = images[values['figma-node']];
if (!cdnUrl) { console.error(`No image returned for node ${values['figma-node']}`); process.exit(2); }
const png = Buffer.from(await (await fetch(cdnUrl)).arrayBuffer());
const expectedPath = join(outDir, 'expected.png');
await writeFile(expectedPath, png);

console.log(JSON.stringify({ actual: actualPath, expected: expectedPath }, null, 2));
```

### References

- [Storybook-First with Figma workflow manual](../../docs/workflows/storybook-first-with-figma.md)
- [Atoms frame in Figma](https://www.figma.com/design/7vcHVM7siztlW4xId0ClVZ/story-book-fisrt-demo?node-id=4-581)
- Source: [docs/workflows/storybook-first-with-figma.md#Figma File Reference]
- Source: [docs/workflows/storybook-first-with-figma.md#Visual Validation Loop]
- Figma personal access token: https://help.figma.com/hc/en-us/articles/8085703771159-Manage-personal-access-tokens

## Dev Agent Record

### Agent Model Used

claude-opus-4-7 (Opus 4.7, 1M context)

### Debug Log References



### Completion Notes List



### File List



### Change Log


