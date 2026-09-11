# Kudlit — Mobile UI Kit

High-fidelity recreation of the Kudlit Flutter mobile app, distilled from the [baybayinscribe-client](https://github.com/UMak-Gilas-Tech/baybayinscribe-client) Next.js reference. Rendered as React/JSX inside an Android device frame for preview purposes.

## Files
- `index.html` — clickable prototype with a bottom-nav shell. Navigate Login → Home → Scanner / Transliterator / Quiz.
- `KudlitAtoms.jsx` — shared atoms: `K` token object, `KudlitTopbar`, `KudlitBottomNav`, `KBtn`, `KLessonCard`, `KQuizCard`, `KSection`.
- `LoginScreen.jsx` — auth/splash with Butty + email/Google entry.
- `HomeScreen.jsx` — dashboard: welcome banner, lesson grid, quiz row, tool cards.
- `ScannerScreen.jsx` — camera viewport with YOLO-style detection overlay and Butty result panel.
- `TransliteratorScreen.jsx` — Latin ⇄ Baybayin text converter with history.
- `QuizScreen.jsx` — multiple-choice quiz with lives + answer feedback.
- `android-frame.jsx` — Material 3 Android device frame (starter component).

## Design provenance
- Colors, radii, shadows, and type scale come from `app/globals.css` in the web client.
- Screen compositions mirror `components/home/*`, `components/vision/*`, and the route pages under `app/(screens)/`.
- Mascot (Butty) and lesson thumbnails are the original assets from `public/images/` in the reference repo.
- Iconography: Lucide (CDN in this kit; `lucide_icons` package for the Flutter build).

## Renamed surface
This kit uses **"Kudlit"** as the product name everywhere the web client said "BaybayInscribe". The app icon is the existing BaybayInscribe mark — a Kudlit-specific wordmark is pending from the user.
