const { execSync } = require('node:child_process');
const path = require('node:path');

const ROOT = __dirname;
const BROWSER_VIEWPORT_LABEL = '390x844';

const STEPS = [
  {
    name: 'cleanup camera permission artifacts',
    command: 'npm run qa:clean-camera-permission-artifacts',
  },
  {
    name: 'mobile regression (denied/granted/transition screenshots)',
    command: 'node camera-permission-state-regression-mobile-390x844.cjs',
  },
  {
    name: 'focused Playwright transition + permission API checks',
    command: 'npm run test:camera-permission-state:playwright',
  },
  {
    name: 'manual flow capture with console log',
    command: 'node camera-permission-manual-flow-390x844.cjs',
  },
];

function runStep(index, step) {
  execSync(step.command, {
    cwd: ROOT,
    stdio: 'inherit',
  });
}

function run(argv) {
  console.log(`[QA] running camera permission e2e sweep @ ${BROWSER_VIEWPORT_LABEL}`);
  console.log(`[QA] workspace: ${path.join(ROOT, '')}`);

  const skipCleanup = argv.includes('--skip-cleanup');
  const filteredSteps = skipCleanup
    ? STEPS.filter((step) => step.name !== 'cleanup camera permission artifacts')
    : STEPS;

  filteredSteps.forEach((step, index) => runStep(index, step));

  console.log('[PASS] camera permission e2e sweep completed');
}

run(process.argv);
