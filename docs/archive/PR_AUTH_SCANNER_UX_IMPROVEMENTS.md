# PR: Auth & Scanner UX Improvements + Gallery Picker

**Branch**: `feat/auth-scanner-ux-improvements`  
**Date**: 2026-04-28  
**Status**: Historical PR note; current scan-layout hardening artifacts live under `qa-artifact/scan-layout-strict-overlap/`

---

## 🎯 Features: Auth & Scanner UX Improvements + Gallery Picker

### 📊 Summary
This PR includes three major enhancements:
- ✅ Animated loading state for sign-out with smooth UX transitions
- ✅ Auth system refactoring with 10 reusable components (50-80% code reduction)
- ✅ Gallery/image picker feature for offline Baybayin translation

### 🎬 Key Changes

#### 1️⃣ Sign-Out Loading State
- Set `AsyncLoading` state when user initiates sign-out
- Convert `SignOutTile` to `StatefulWidget` with `AnimationController`
- Animated spinner rotates smoothly (not static)
- Button dims to 60% opacity during loading
- Border fades to indicate disabled state
- Auto-redirect to login on completion

**Files**: 3
- `lib/features/auth/presentation/providers/auth_notifier.dart`
- `lib/features/home/presentation/widgets/settings/sign_out_tile.dart`
- `lib/features/home/presentation/screens/settings_screen.dart`

#### 2️⃣ Authentication Refactoring
Extracted 10+ reusable components for cleaner, maintainable code:
- `auth_sheet.dart` — Modal sheet wrapper
- `phone_field.dart` — Phone input component
- `sign_in_form.dart` & `sign_up_form.dart` — Form components
- `country_picker_sheet.dart` — Country code selector (NEW)
- Plus: drag handle, headline, prompts, etc.

Simplified 5 auth screens (50-80% smaller):
- `phone_sign_in_screen.dart`: 298 lines → ~80 lines
- `sign_in_screen.dart`: 134 lines reduced
- `sign_up_screen.dart`: 118 lines reduced

**Files**: 15 (10 new components + 5 refactored screens)

#### 3️⃣ Gallery/Image Picker
Allow users to translate from photos instead of just camera:
- Added `image_picker` dependency
- User taps gallery icon → device image picker opens
- Select image → displays in camera area
- YOLO detector processes gallery image
- Results shown with bounding boxes overlay
- Loading indicator during processing
- Dismiss clears selection → camera returns

**Flow**:
1. Scanner tab → Tap gallery icon
2. Device picker opens → Select photo
3. Image displays (replaces live camera feed)
4. YOLO runs detection on image
5. Results overlay shown
6. Dismiss button clears & returns to camera

**Files**: 1 core + dependencies
- `lib/features/home/presentation/screens/scan_tab.dart` (+79 lines)
- `pubspec.yaml` (image_picker dependency)

---

## ✅ Testing Status
- [x] `flutter analyze` → 0 issues
- [x] `flutter test` → All 8 tests pass
- [x] Code formatting → Compliant
- [x] Scan layout hardening → `scripts/scan-layout-overlap-pass.ps1` wrote passing artifacts under `qa-artifact/scan-layout-strict-overlap/`
- [ ] Manual testing on Android
- [ ] Manual testing on iOS
- [ ] Manual testing on Web device/browser permissions

---

## 📈 Statistics
| Metric | Value |
|--------|-------|
| Files Changed | 50 |
| Lines Added | 1,276 |
| Lines Removed | 781 |
| New Dependencies | 1 (image_picker) |
| Breaking Changes | None |

---

## 📱 Platform Support
- Android/iOS: native camera and gallery flows.
- Web: browser webcam preview, capture-based TFLite detection, and gallery fallback when a compatible model URL and browser permissions are available.
- Desktop builds are not verified by this PR note.

---

## 🧪 Testing Checklist
- [ ] Sign-out button: spinner animates smoothly
- [ ] Sign-out button: dims and becomes non-interactive
- [ ] Sign-out: redirects to login after completion
- [ ] Auth screens: all render without errors
- [ ] Phone sign-in: works correctly
- [ ] Country picker: opens and works
- [ ] Gallery picker: opens image selection
- [ ] Gallery: YOLO detection runs on selected image
- [ ] Gallery: results display with overlay
- [ ] Gallery: dismiss clears selection
- [ ] No console errors or warnings

---

## 📝 Notes
- All state management uses Riverpod AsyncValue pattern
- Animation properly disposed to prevent memory leaks
- Image picker and web camera behavior depend on platform permissions and configured model URLs
- No database migrations required
- Backwards compatible with existing auth flow

Scan hardening proof:

- `qa-artifact/scan-layout-strict-overlap/report.json`
- `qa-artifact/scan-layout-strict-overlap/scan-layout-overlap-contact-sheet.html`

---

## 🔗 GitHub PR
https://github.com/ACSADians/kudlit-app/pull/new/feat/auth-scanner-ux-improvements
