const fs = require('node:fs');
const path = require('node:path');
const { chromium } = require('playwright');

const ORIGIN = 'http://127.0.0.1:5173';
const SCAN_PATH = '/#/home?tab=scan&scenario=camera-permission-manual';
const VIEWPORT = { width: 390, height: 844 };
const OUT_DIR = path.join(__dirname, 'qa-artifact', 'manual-camera-flow');
const EXPECTED_SCREENSHOTS = [
  'denied-camera-status.png',
  'prompt-camera-status.png',
  'granted-camera-status.png',
  'denied-browser-blocked-camera-status.png',
];

const SCENARIOS = [
  {
    state: 'denied',
    urlTag: 'denied',
    screenshot: 'denied-camera-status.png',
    launchArgs: ['--use-fake-device-for-media-stream'],
    grantPermission: false,
    expectedPermissionStates: ['prompt', 'denied'],
  },
  {
    state: 'prompt',
    urlTag: 'prompt',
    screenshot: 'prompt-camera-status.png',
    launchArgs: ['--use-fake-device-for-media-stream'],
    grantPermission: false,
    expectedPermissionStates: ['prompt'],
  },
  {
    state: 'granted',
    urlTag: 'granted',
    screenshot: 'granted-camera-status.png',
    launchArgs: ['--use-fake-device-for-media-stream'],
    grantPermission: true,
    expectedPermissionStates: ['granted'],
  },
  {
    state: 'denied-blocked',
    urlTag: 'denied',
    screenshot: 'denied-browser-blocked-camera-status.png',
    launchArgs: ['--deny-permission-prompts'],
    grantPermission: false,
    expectedPermissionStates: ['prompt', 'denied'],
    blockedContext: true,
  },
];

function normalizePermissionState(value) {
  if (!value || !value.supported) {
    return null;
  }
  return value.state;
}

async function readPermissionState(page) {
  return page.evaluate(async () => {
    if (!('permissions' in navigator)) {
      return { supported: false, state: null, error: null };
    }

    try {
      const status = await navigator.permissions.query({ name: 'camera' });
      return {
        supported: true,
        state: status.state,
        error: null,
      };
    } catch (error) {
      return {
        supported: true,
        state: null,
        error: error?.message ?? String(error),
      };
    }
  });
}

async function captureScenario({
  state,
  urlTag,
  screenshot,
  launchArgs,
  grantPermission,
  expectedPermissionStates,
  blockedContext = false,
}) {
  const browser = await chromium.launch({
    headless: !process.argv.includes('--headed'),
    args: launchArgs,
  });

  const context = await browser.newContext({
    viewport: VIEWPORT,
  });

  if (grantPermission) {
    await context.grantPermissions(['camera'], { origin: ORIGIN });
  }

  const page = await context.newPage();
  const console = [];
  const pageErrors = [];

  page.on('console', (msg) => {
    console.push(`[${msg.type()}] ${msg.text()}`);
  });
  page.on('pageerror', (error) => {
    pageErrors.push({
      name: error?.name || 'error',
      message: error?.message || String(error),
    });
  });

  const targetUrl = `${ORIGIN}${SCAN_PATH}&qa_camera_status=${urlTag}`;
  await page.goto(targetUrl, { waitUntil: 'domcontentloaded' });
  await page.waitForTimeout(3000);

  const permission = await readPermissionState(page);
  const stateValue = normalizePermissionState(permission);
  if (!permission.supported || !stateValue || !expectedPermissionStates.includes(stateValue)) {
    await page.close();
    await context.close();
    await browser.close();
    throw new Error(
      `${state} permission state should be one of ${expectedPermissionStates.join(
        ', ',
      )}, got ${permission.state}`,
    );
  }

  const screenshotPath = path.join(OUT_DIR, screenshot);
  await page.screenshot({
    path: screenshotPath,
    fullPage: true,
  });

  const artifact = {
    state,
    blockedContext,
    scenarioUrl: targetUrl,
    permission,
    screenshot: screenshotPath.replace(/.*qa-artifact[\\/]/, 'qa-artifact/'),
    console,
    pageErrors,
    viewport: `${VIEWPORT.width}x${VIEWPORT.height}`,
    capturedAt: new Date().toISOString(),
  };

  await page.close();
  await context.close();
  await browser.close();

  return { screenshot, artifact };
}

function assertExpectedArtifacts(artifacts) {
  const seen = artifacts.map((entry) => entry.screenshot).sort();
  const expected = [...EXPECTED_SCREENSHOTS].sort();
  const missing = expected.filter((name) => !seen.includes(name));

  if (missing.length > 0) {
    throw new Error(`Missing expected manual screenshots: ${missing.join(', ')}`);
  }
}

(async () => {
  fs.mkdirSync(OUT_DIR, { recursive: true });
  const outputs = [];

  for (const scenario of SCENARIOS) {
    outputs.push(await captureScenario(scenario));
  }

  outputs.forEach(({ artifact }) => {
    fs.writeFileSync(
      path.join(
        OUT_DIR,
        `${artifact.state === 'denied-blocked' ? 'denied-browser-blocked' : artifact.state}-camera-status.json`,
      ),
      JSON.stringify(artifact, null, 2),
    );
  });

  assertExpectedArtifacts(outputs.map((entry) => ({ screenshot: entry.screenshot })));

  const summary = {
    scenario: `camera-manual-web-${VIEWPORT.width}x${VIEWPORT.height}`,
    capturedAt: new Date().toISOString(),
    runs: outputs.map((entry) => ({
      state: entry.artifact.state,
      permissionState: entry.artifact.permission.state,
      screenshot: entry.artifact.screenshot,
      consoleCount: entry.artifact.console.length,
      pageErrorCount: entry.artifact.pageErrors.length,
    })),
    passCriteria:
      'blocked/prompt/granted states plus deterministic file naming + permission API state validation',
  };
  fs.writeFileSync(
    path.join(OUT_DIR, 'camera-status-manual-summary.json'),
    JSON.stringify(summary, null, 2),
  );

  console.log('[PASS] manual camera flow capture completed');
  for (const item of summary.runs) {
    console.log(
      `${item.state}: permission=${item.permissionState} screenshot=${item.screenshot}`,
    );
  }
})().catch((error) => {
  console.error('[FAIL] manual camera flow capture failed:', error?.message || error);
  process.exitCode = 1;
});
