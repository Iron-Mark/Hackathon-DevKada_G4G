const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { chromium } = require('playwright');

const ORIGIN = 'http://127.0.0.1:5173';
const SCAN_URL = `${ORIGIN}/#/home?tab=scan&scenario=camera-permission-regression`;
const ARTIFACT_ROOT = path.join(__dirname, 'qa-artifact', 'camera-permission-state');

const RUN_CONFIG = {
  denied: {
    args: ['--deny-permission-prompts', '--use-fake-device-for-media-stream'],
    expectPermissionStates: ['prompt', 'denied'],
  },
  granted: {
    args: ['--use-fake-device-for-media-stream'],
    initPermissions: ['camera'],
    expectPermissionStates: ['granted'],
  },
};

function normalizePermissionState(value) {
  if (!value || !value.supported) return null;
  return value.state;
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
        error: error?.message || String(error),
      };
    }
  });
}

function writeArtifact(name, data) {
  fs.mkdirSync(ARTIFACT_ROOT, {
    recursive: true,
  });
  fs.writeFileSync(path.join(ARTIFACT_ROOT, `${name}.json`), JSON.stringify(data, null, 2));
}

async function runScenario({ name, urlTag, args, initPermissions }) {
  const browser = await chromium.launch({
    headless: true,
    args,
  });

  const context = await browser.newContext();
  if (initPermissions?.length) {
    await context.grantPermissions(initPermissions, { origin: ORIGIN });
  }
  const page = await context.newPage();
  const events = {
    name,
    scenarioUrl: `${SCAN_URL}&qa_camera_status=${urlTag}`,
    permission: null,
    finalUrl: null,
    console: [],
  };

  page.on('console', (msg) => events.console.push(`[${msg.type()}] ${msg.text()}`));
  const startedAt = Date.now();

  await page.goto(`${SCAN_URL}&qa_camera_status=${urlTag}`, {
    waitUntil: 'domcontentloaded',
  });
  await page.waitForTimeout(2500);
  events.permission = await readPermissionState(page);
  events.finalUrl = page.url();
  events.durationMs = Date.now() - startedAt;

  await page.screenshot({
    path: path.join(ARTIFACT_ROOT, `${name}-camera-state.png`),
    fullPage: true,
  });

  await page.close();
  await context.close();
  await browser.close();
  return events;
}

async function runTransitionScenario() {
  const browser = await chromium.launch({
    headless: true,
    args: ['--use-fake-device-for-media-stream'],
  });
  const context = await browser.newContext();
  const page = await context.newPage();
  const events = {
    name: 'camera-permission-transition',
    steps: [],
    console: [],
  };

  page.on('console', (msg) => events.console.push(`[${msg.type()}] ${msg.text()}`));

  await page.goto(`${SCAN_URL}&qa_camera_status=denied`, {
    waitUntil: 'domcontentloaded',
  });
  await page.waitForTimeout(2500);

  const denied = {
    permission: await readPermissionState(page),
    statusByPermissionApi: 'before-grant',
  };
  events.steps.push({ stage: 'before-grant', ...denied });

  await page.screenshot({
    path: path.join(ARTIFACT_ROOT, 'camera-permission-transition-before-grant.png'),
    fullPage: true,
  });

  await context.grantPermissions(['camera'], { origin: ORIGIN });
  await page.reload({ waitUntil: 'domcontentloaded' });
  await page.waitForTimeout(2500);

  const granted = {
    permission: await readPermissionState(page),
    statusByPermissionApi: 'after-grant',
  };
  events.steps.push({ stage: 'after-grant', ...granted });
  events.finalUrl = page.url();

  await page.screenshot({
    path: path.join(ARTIFACT_ROOT, 'camera-permission-transition-after-grant.png'),
    fullPage: true,
  });

  await page.close();
  await context.close();
  await browser.close();

  return { events, denied, granted };
}

function assertPermissionState(permission, expectedStates, label) {
  assert.ok(permission?.supported, `permission API unsupported for ${label}`);
  const state = normalizePermissionState(permission);
  assert.ok(
    state && expectedStates.includes(state),
    `${label} permission state should be one of ${expectedStates.join(', ')}, got ${state}`,
  );
}

(async () => {
  const denied = await runScenario({
    name: 'camera-permission-denied',
    urlTag: 'denied',
    ...RUN_CONFIG.denied,
  });
  assertPermissionState(denied.permission, RUN_CONFIG.denied.expectPermissionStates, 'denied');

  const granted = await runScenario({
    name: 'camera-permission-granted',
    urlTag: 'granted',
    ...RUN_CONFIG.granted,
  });
  assertPermissionState(granted.permission, RUN_CONFIG.granted.expectPermissionStates, 'granted');

  const transition = await runTransitionScenario();
  assertPermissionState(transition.denied.permission, ['prompt', 'denied'], 'transition-before-grant');
  assertPermissionState(transition.granted.permission, ['granted'], 'transition-after-grant');

  writeArtifact('camera-permission-denied', denied);
  writeArtifact('camera-permission-granted', granted);
  writeArtifact('camera-permission-transition', transition.events);
  writeArtifact('camera-permission-transition-summary', {
    before: transition.denied.permission.state,
    after: transition.granted.permission.state,
    steps: transition.events.steps.map((step) => ({
      stage: step.stage,
      state: step.permission.state,
      permissionError: step.permission.error,
    })),
    passedAt: new Date().toISOString(),
  });

  console.log('[PASS] camera-permission regression test completed');
  console.log(`denied=${JSON.stringify(denied.permission)} granted=${JSON.stringify(granted.permission)}`);
})();
