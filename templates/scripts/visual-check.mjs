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
