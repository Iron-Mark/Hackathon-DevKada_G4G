const fs = require('node:fs');
const crypto = require('node:crypto');
const path = require('node:path');
const { chromium } = require('playwright');
const { expect, test } = require('@playwright/test');

const ORIGIN = 'http://127.0.0.1:5173';
const SCAN_PATH = '/#/home?tab=scan';
const VIEWPORT = { width: 390, height: 844 };
const VIEWPORT_TAG = `${VIEWPORT.width}x${VIEWPORT.height}`;
const ARTIFACT_ROOT = path.join(
  __dirname,
  'qa-artifact',
  'camera-permission-state',
  'transition-regression',
);

const SCREENSHOTS = {
  denied: `camera-permission-denied-camera-state-${VIEWPORT_TAG}.png`,
  transitionBefore: `camera-permission-transition-before-grant-${VIEWPORT_TAG}.png`,
  transitionAfter: `camera-permission-transition-after-grant-${VIEWPORT_TAG}.png`,
  granted: `camera-permission-granted-camera-state-${VIEWPORT_TAG}.png`,
};

function normalizePermissionState(permission) {
  if (!permission || !permission.supported) return null;
  return permission.state;
}

async function readPermissionState(page) {
  return page.evaluate(async () => {
    if (!('permissions' in navigator)) {
      return { supported: false, state: null, error: null };
    }

    try {
      const status = await navigator.permissions.query({ name: 'camera' });
      return { supported: true, state: status.state, error: null };
    } catch (error) {
      return {
        supported: true,
        state: null,
        error: error?.message ?? String(error),
      };
    }
  });
}

function assertStateValue(permission, expectedStates) {
  const state = normalizePermissionState(permission);
  expect(permission?.supported, 'Permission API should be supported').toBe(true);
  expect(expectedStates.includes(state), `Expected ${expectedStates.join(', ')} got ${state}`).toBe(true);
  return state;
}

function writeArtifact(name, data) {
  fs.mkdirSync(ARTIFACT_ROOT, { recursive: true });
  fs.writeFileSync(path.join(ARTIFACT_ROOT, `${name}.json`), JSON.stringify(data, null, 2));
}

function writeScreenshot(page, name) {
  const filePath = path.join(ARTIFACT_ROOT, name);
  return page.screenshot({ path: filePath, fullPage: true }).then(() => filePath);
}

function sha256(filePath) {
  return crypto.createHash('sha256').update(fs.readFileSync(filePath)).digest('hex');
}

function assertScreenshotArtifacts(artifacts) {
  expect(artifacts.length, 'expected screenshot artifacts').toBe(4);
  const names = new Set(artifacts.map((entry) => entry.name));
  const expectedNames = Object.values(SCREENSHOTS);
  expect(names.size, 'expected all screenshot names to be unique').toBe(4);
  for (const expectedName of expectedNames) {
    expect(names.has(expectedName), `Expected screenshot name: ${expectedName}`).toBe(true);
  }

  const hashes = new Set();
  for (const entry of artifacts) {
    expect(fs.existsSync(entry.path), `Expected ${entry.name} to exist`).toBe(true);
    expect(fs.statSync(entry.path).size, `${entry.name} should not be empty`).toBeGreaterThan(500);
    expect(fs.statSync(entry.path).size, `${entry.name} should not be tiny`).toBeGreaterThan(1024);
    expect(entry.hash).toMatch(/^[a-f0-9]{64}$/);
    hashes.add(entry.hash);
  }

  return {
    uniqueHashCount: hashes.size,
    hashes: [...hashes],
  };
}

test('camera denied and grant transition keeps deterministic permission API + screenshot names', async () => {
  fs.mkdirSync(ARTIFACT_ROOT, { recursive: true });
  const screenshotArtifacts = [];
  const logs = [];

  const browser = await chromium.launch({
    headless: true,
    args: ['--deny-permission-prompts', '--use-fake-device-for-media-stream'],
  });
  const context = await browser.newContext({
    viewport: VIEWPORT,
  });
  const page = await context.newPage();
  const deniedUrl = `${ORIGIN}${SCAN_PATH}&qa_camera_status=denied`;

  page.on('console', (msg) => {
    logs.push(`[${msg.type()}] ${msg.text()}`);
  });

  await page.goto(deniedUrl, { waitUntil: 'domcontentloaded' });
  await page.waitForTimeout(2500);

  const denied = await readPermissionState(page);
  const deniedState = assertStateValue(denied, ['prompt', 'denied']);

  const deniedScreenshot = await writeScreenshot(page, SCREENSHOTS.denied);
  screenshotArtifacts.push({
    name: SCREENSHOTS.denied,
    path: deniedScreenshot,
    hash: sha256(deniedScreenshot),
    permissionState: deniedState,
  });

  const transitionBefore = await writeScreenshot(page, SCREENSHOTS.transitionBefore);
  screenshotArtifacts.push({
    name: SCREENSHOTS.transitionBefore,
    path: transitionBefore,
    hash: sha256(transitionBefore),
    permissionState: deniedState,
  });

  await context.grantPermissions(['camera'], { origin: ORIGIN });
  await page.reload({ waitUntil: 'domcontentloaded' });
  await page.waitForTimeout(2500);

  const granted = await readPermissionState(page);
  const grantedState = assertStateValue(granted, ['granted']);
  const transitionAfter = await writeScreenshot(page, SCREENSHOTS.transitionAfter);
  screenshotArtifacts.push({
    name: SCREENSHOTS.transitionAfter,
    path: transitionAfter,
    hash: sha256(transitionAfter),
    permissionState: grantedState,
  });

  const grantedScenarioUrl = `${ORIGIN}${SCAN_PATH}&qa_camera_status=granted`;
  await page.goto(grantedScenarioUrl, { waitUntil: 'domcontentloaded' });
  await page.waitForTimeout(2500);
  const grantedDirect = await readPermissionState(page);
  const grantedDirectState = assertStateValue(grantedDirect, ['granted']);
  const grantedScenarioScreenshot = await writeScreenshot(page, SCREENSHOTS.granted);
  screenshotArtifacts.push({
    name: SCREENSHOTS.granted,
    path: grantedScenarioScreenshot,
    hash: sha256(grantedScenarioScreenshot),
    permissionState: grantedDirectState,
  });

  const hashSummary = assertScreenshotArtifacts(screenshotArtifacts);

  await page.close();
  await context.close();
  await browser.close();

  writeArtifact('camera-permission-transition-regression', {
    scenarioUrls: {
      denied: deniedUrl,
      grantedScenario: grantedScenarioUrl,
    },
    permission: {
      denied: deniedState,
      beforeGrant: deniedState,
      afterGrant: grantedState,
      grantedDirect: grantedDirectState,
    },
    screenshots: SCREENSHOTS,
    screenshotSummaries: screenshotArtifacts.map((entry) => ({
      name: entry.name,
      permissionState: entry.permissionState,
      hash: entry.hash,
      size: fs.statSync(entry.path).size,
    })),
    hashSummary,
    logs,
    viewport: VIEWPORT_TAG,
    passedAt: new Date().toISOString(),
  });
});
