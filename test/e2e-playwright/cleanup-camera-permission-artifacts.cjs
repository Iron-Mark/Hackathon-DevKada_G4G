const fs = require('node:fs');
const path = require('node:path');

const ROOT = path.join(__dirname, 'qa-artifact');
const TARGET_DIRS = [
  'camera-permission-state',
  path.join('camera-permission-state', 'mobile-390x844'),
  path.join('camera-permission-state', 'transition-regression'),
  'manual-camera-flow',
];

function exists(target) {
  return fs.existsSync(target);
}

function removeDir(target) {
  if (!exists(target)) {
    return;
  }

  fs.rmSync(target, { recursive: true, force: true });
  console.log(`[CLEAN] removed ${path.relative(__dirname, target)}`);
}

function recreateDir(target) {
  fs.mkdirSync(target, { recursive: true });
  console.log(`[CLEAN] recreated ${path.relative(__dirname, target)}`);
}

function main() {
  if (!exists(ROOT)) {
    console.log(`[CLEAN] root missing: ${path.relative(process.cwd(), ROOT)}`);
    return;
  }

  TARGET_DIRS.forEach((relativeDir) => {
    const absoluteDir = path.join(ROOT, relativeDir);
    removeDir(absoluteDir);
    recreateDir(absoluteDir);
  });

  console.log('[PASS] camera permission QA artifacts cleaned');
}

main();
