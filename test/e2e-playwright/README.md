## Scanner camera permission checks

Quick QA entry points for camera permission coverage in web scanner.

### 1) Command-line regression (default)

- In this folder:
  - `npm install`
  - `npm run test:camera-permission-state`
- Artifacts:
  - `qa-artifact/camera-permission-state/camera-permission-denied.json`
  - `qa-artifact/camera-permission-state/camera-permission-granted.json`
  - `qa-artifact/camera-permission-state/camera-permission-transition-summary.json`
  - matching `*.png` screenshots in the same folder

### 2) Mobile strict variant (390x844) + naming checks

- Run a mobile-sized check with deterministic filenames from `tmp-playwright`:
  - `npm run test:camera-permission-state:mobile-390x844`
  - expected names (written by the script):
      - `camera-permission-denied-camera-state-390x844.png`
      - `camera-permission-granted-camera-state-390x844.png`
      - `camera-permission-transition-before-grant-390x844.png`
      - `camera-permission-transition-after-grant-390x844.png`
- Artifacts are written to:
  - `qa-artifact/camera-permission-state/mobile-390x844/`
- Pass check:
  - script prints `[PASS] camera-permission mobile viewport regression completed`
  - all 4 expected screenshot names exist

### 3) Focused Playwright transition (permission API states + naming)

- Run focused transition + permission API assertions:
  - `npm run test:camera-permission-state:playwright`
- Artifacts:
  - `qa-artifact/camera-permission-state/transition-regression/camera-permission-transition-regression.json`
  - screenshot set with exact names:
    - `camera-permission-denied-camera-state-390x844.png`
    - `camera-permission-transition-before-grant-390x844.png`
    - `camera-permission-transition-after-grant-390x844.png`
    - `camera-permission-granted-camera-state-390x844.png`
- Test validates:
  - Permission API state transitions from denied/prompt -> granted
  - Expected screenshot filenames (exact matches)
  - Browser console output captured in JSON artifact

### 4) Manual capture flow (command + headed)

#### 4.1 Command-line manual capture

- Capture denied/prompt/granted + blocked browser state in one pass:
  - `npm run test:camera-permission-state:manual-390x844`
- Capture screenshots and console evidence to:
  - `qa-artifact/manual-camera-flow/denied-camera-status.png`
  - `qa-artifact/manual-camera-flow/prompt-camera-status.png`
  - `qa-artifact/manual-camera-flow/granted-camera-status.png`
  - `qa-artifact/manual-camera-flow/denied-browser-blocked-camera-status.png`
  - matching `*.json` state snapshots
- Expected summary:
  - `qa-artifact/manual-camera-flow/camera-status-manual-summary.json`

#### 4.2 Visual/manual browser review

- Headed browser review:
  - `node camera-permission-manual-flow-390x844.cjs --headed`

- Manual URLs (for direct visual check, no script):
  - denied: `http://127.0.0.1:5173/#/home?tab=scan&scenario=camera-permission-manual&qa_camera_status=denied`
  - prompt: `http://127.0.0.1:5173/#/home?tab=scan&scenario=camera-permission-manual&qa_camera_status=prompt`
  - granted: `http://127.0.0.1:5173/#/home?tab=scan&scenario=camera-permission-manual&qa_camera_status=granted`

### 5) One-shot e2e sweep (mobile + playwright + manual)

- Full verification run in one command:
  - `npm run test:camera-permission-state:all-390x844`
- Optional skip cleanup:
  - `node camera-permission-state-e2e-390x844.cjs --skip-cleanup`
- This command runs, in order:
  - cleanup artifacts
  - mobile strict regression
  - playwright focused transition
  - manual flow capture
- Pass check:
  - prints `[PASS] camera permission e2e sweep completed`

### 6) Cleanup permission artifacts

- Run before another fresh permission sweep:
  - `npm run qa:clean-camera-permission-artifacts`
- This will reset:
  - `qa-artifact/camera-permission-state/`
  - `qa-artifact/camera-permission-state/mobile-390x844/`
  - `qa-artifact/camera-permission-state/transition-regression/`
  - `qa-artifact/manual-camera-flow/`
