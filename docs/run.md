Fix 1 — add --no-dds flag (quickest fix):
  flutter run -d emulator-5554 --no-dds

Fix 2 — if that still fails, also disable auth
  codes:
  flutter run -d emulator-5554 --no-dds
  --disable-service-auth-codes

Camera permission E2E check (scanner)

Use this when validating web scanner camera permission transitions.

- Start app on `http://127.0.0.1:5173`.
- From repo root:
- `cd "tmp-playwright"`
- `npm install`

### Recommended quick check

- Run full e2e sweep (clean + mobile + playwright + manual):
  - `npm run test:camera-permission-state:all-390x844`

### Full sequence (if you prefer step-by-step)

- `npm run test:camera-permission-state:mobile-390x844`
- `npm run test:camera-permission-state:playwright`
- `npm run test:camera-permission-state:manual-390x844`
- `npm run qa:clean-camera-permission-artifacts`

Manual scripted mobile capture (including blocked/prompt/granted states):
- `npm run test:camera-permission-state:manual-390x844`
- `node camera-permission-manual-flow-390x844.cjs --headed` (visual review)
- blocked scenario URL:
  - `http://127.0.0.1:5173/#/home?tab=scan&scenario=camera-permission-manual&qa_camera_status=denied`

Pass criteria:
- Playwright regression passes and writes:
  - `tmp-playwright/qa-artifact/camera-permission-state/transition-regression/camera-permission-transition-regression.json`
- Mobile regression writes expected 390x844 screenshot names:
  - `camera-permission-denied-camera-state-390x844.png`
  - `camera-permission-granted-camera-state-390x844.png`
  - `camera-permission-transition-before-grant-390x844.png`
  - `camera-permission-transition-after-grant-390x844.png`
- Manual flow writes expected artifacts under:
  - `tmp-playwright/qa-artifact/manual-camera-flow/`
- Final command prints:
  - `[PASS] camera permission e2e sweep completed`
