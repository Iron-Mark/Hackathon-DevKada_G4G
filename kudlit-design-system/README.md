# Kudlit Design System

> Offline-first mobile app tackling the digital exclusion of endangered writing systems — starting with **Baybayin**, the pre-colonial script of the Philippines.

Kudlit uses YOLOv12 for real-time handwritten-script detection and Gemma 4 for contextual disambiguation, enabling users to learn and transliterate Baybayin without an internet connection. It runs fully on-device on capable hardware and gracefully degrades to cloud inference on low-end devices. Baybayin is the starting point; the pipeline is script-agnostic and extensible to other endangered writing systems across Southeast Asia and beyond.

**Target platform:** Flutter (native mobile — Android + iOS). This design system distils the visual language originally proven in the BaybayInscribe web client and restates it for a Flutter build, renamed **Kudlit**.

## Sources

- **Origin codebase:** [`UMak-Gilas-Tech/baybayinscribe-client`](https://github.com/UMak-Gilas-Tech/baybayinscribe-client) — Next.js / React / Tailwind v4 web client.
  - `app/globals.css` — `@theme` color tokens, radii, font vars, shake / heartbeat keyframes.
  - `components/` — sidebar, home cards, quiz cards, vision (scanner), baybayin_latin (transliteration glyph rendering).
  - `public/fonts/BaybayinSimpleTAWBID.*` — core display font for Baybayin glyphs.
  - `public/images/` — Butty mascot set, app icon, background, lesson + quiz thumbnails.

All assets referenced in this system were copied out of the repo above; no new illustration was drawn.

---

## Index

- `README.md` — this file. Brand context, content fundamentals, visual foundations, iconography.
- `colors_and_type.css` — CSS variables for colors, spacing, radii, elevation, fonts, type scale, and motion. Import this into any artifact.
- `fonts/` — `BaybayinSimpleTAWBID.{otf,ttf,woff,woff2}`. UI font is **Geist** (loaded from Google Fonts).
- `assets/` — app icons, background, Butty mascot illustrations, lesson thumbnails, flag icons, login BG.
- `preview/` — ~20 small HTML specimen cards registered to the Design System tab.
- `ui_kits/mobile/` — Flutter-oriented UI kit recreation: splash, home, scanner, transliterator, and quiz screens inside an Android phone frame. Built in JSX for fidelity.
- `SKILL.md` — portable skill manifest for cross-project use.

---

## Brand snapshot

- **Name:** Kudlit — the Tagalog term for the small mark above/below a Baybayin consonant that changes its vowel sound. A tiny dot that entirely changes meaning — a fitting metaphor for assistive, contextual tech.
- **Mascot:** *Butty*, a round blue-and-peach/tan creature with a small hat-fin — curious, friendly, a little goofy. Appears across lesson cards, the scanner screen (reading a script scroll), empty states, and profile avatars. Butty carries most of the emotional lift in the app.
- **Writing system spotlight:** Baybayin glyphs in the bespoke **Baybayin Simple TAWBID** display font. Used as hero elements, never as body copy.
- **Primary audience:** Filipino students and heritage learners; accessibility and low-end-device users are first-class considerations (graceful degradation to cloud inference).

---

## CONTENT FUNDAMENTALS

### Voice
Warm, direct, and a little playful — the mascot speaks in first person (*"Hi, I'm Butty!"*, *"Wow! I can read Baybayin!"*) but UI chrome is plain and functional. Avoid marketing gloss; state what the button does.

### Grammar & casing
- **Title Case** for navigation labels and card titles: *"Baybayin Scanner"*, *"Guide to Baybayin"*, *"Baybayin Quizzes and Challenges"*.
- **Sentence case** for body copy, placeholders, and errors: *"Detected baybayin text will go here."*, *"No lessons yet"*.
- Button labels are short, Title Case, imperative: *"Start Learning"*, *"Take Quiz"*, *"Clear History"*, *"I Understand"*.

### Person
- **Second person** for instructional copy: *"Make sure the text is clear, well-lit, and fully visible."*
- **First person** strictly for Butty's speech bubbles: *"I think I can read Baybayin!"*
- **Declarative** for system statuses: *"Loading AI Model…"*, *"Camera Preferences"*.

### Tone examples (verbatim from source)
- Empty / low-confidence: *"No Baybayin script found :( Make sure the text is clear, well-lit, and fully visible."* — uses an ASCII frownie, stays soft rather than technical.
- High-confidence: *"Wow! I can read Baybayin!"* — enthusiasm, exclamation mark.
- Accuracy disclaimer: *"The AI model may not be 100% accurate. Expect occasional misreads and always verify the output."* — honest about limits, no hedging.
- Confirmation: *"Do you want to log out of your session?"* / *"Yes, Log me out"* / *"No, don't log me out"* — conversational two-sided choice, not abstract "Confirm/Cancel".

### Emoji / punctuation
- Real emoji: **not used**. Occasional ASCII emoticons (`:(`) live inside Butty's voice only.
- Exclamation marks are reserved for Butty and for celebratory moments; everywhere else, a period.
- Ellipses (`…`) for progress states: *"Logging out…"*, *"Loading AI Model…"*.

---

## VISUAL FOUNDATIONS

### Color vibe
Deep, confident **denim-navy** anchors everything. The palette leans cool, but the mascot's **peach/tan skin** warms every screen where Butty appears. Accents (success / danger / warning / info) are used only in their semantic roles — never decoratively.

- **Surface plane:** `--neutral-white` (`hsl(226, 91%, 91%)`) — not pure white but a pale blue-tinted paper. Everything feels lightly washed with the brand hue.
- **Ink:** `--blue-300` / `--blue-400` for headings and primary buttons. Body text uses `--neutral-black` which is actually deep navy (`hsl(224, 45%, 10%)`).
- **Topbar:** saturated mid-blue (`--blue-500`) with a darker 1.25px border-bottom — the only prominent horizontal chrome.

### Typography
- **UI:** Geist (Google) / Geist Mono. Variable axis, used 400 / 500 / 600 / 700.
- **Display script:** *Baybayin Simple TAWBID* (bundled OTF/TTF/WOFF/WOFF2) — exclusively for rendering Baybayin characters. **Never body copy.**
- Scale: 40 / 32 / 24 / 20 / 16 / 14 / 12. Line heights 1.15 / 1.3 / 1.5.
- Headings are tight (-0.015 to -0.02 em tracking). Body is untracked.

### Spacing & layout
- 4-pixel base grid (4, 8, 12, 16, 20, 24, 32, 40, 48, 64).
- Cards are the default container. Home surface is a horizontally-scrolling row of cards on desktop, stacked on mobile (`sm:max-w-[300px]` in source).
- Max page width is 1400px (`--max-width-8xl`).

### Backgrounds
- **Hero / auth:** a full-bleed `BaybayInscribe-BackgroundImage.webp` — a soft illustrated motif sitting beneath a blue wash. Used only on auth and on the main home shell.
- **App body:** flat `--blue-900` (light surface) with the background image floated at `-z-10` behind content — so there is always a hint of texture without interfering.
- **No gradient UI chrome.** Meshes, aurora gradients, bluish-purple gradients are explicitly avoided.

### Imagery
- **Butty illustrations** — hand-drawn feel, chunky black outline (~1.5px), flat fills. Character is blue (body) + peach/tan (belly/face). Expressions: *Wave*, *Read*, *Paint*, *Phone*, *PencilRun*, *TextBubble*, plus profile variants (*Artistic*, *Coder*, *Stand*, *ThumbsUp*, *TongueCheek*).
- **Lesson thumbnails** — stylized Baybayin glyph compositions on transparent/white background, used inside card image slots.
- **Photography** — not used.
- **Grain / texture:** none. Illustrations do the emotional work.

### Animation
- Use with restraint and always on `var(--dur-slow)` (`500ms`) with the default `ease` — source code uses `transition-all duration-500` on cards and sidebar state.
- Hover → `-translate-y-2`. Active → `translate-y-0 scale-95 shadow-none` (cards physically press in).
- Two named keyframes live in the theme: **shake** (0.5s, input error) and **heartbeat** (1.5s infinite, scale pulse to 1.4× — used on lives/hearts).
- No bounces, no springs, no parallax.

### Hover / press states
- **Hover:** color shift toward `--blue-400`/`--blue-300`, `-translate-y-2`, sometimes `scale-105` on icons. Title color shifts `group-hover:text-blue-300` with `group-hover:font-bold`.
- **Press / active:** `active:translate-y-0 active:shadow-none active:scale-95` — a clear "press in" feel.
- **Disabled:** `opacity-75`, cursor-not-allowed, button bg fades to `--blue-500/75`, text to `--blue-900/60`.

### Borders
- Default: 1px solid `--border` (`--blue-300`).
- A bespoke `1.25px` token (`--border-width-1.25`) is used on the topbar toggle button and accent outlines — a small but signature detail.
- Dividers are `h-[0.2px] opacity-50 bg-gray-500 w-full` — nearly hairline.

### Shadows
- Standard app-icon shadow: `0 4px 4px 0 rgba(0,0,0,0.25)` — crisp, slightly heavy. Applied to the logo and raised avatars.
- Topbar: subtle `shadow-md`.
- No inner shadows. No layered / realistic card shadows.

### Corner radii
- Default card / component: `0.625rem` (10px).
- Buttons: `rounded-lg` (8px) for standard, `rounded-full` for pill actions and status chips.
- Dialog / sheet / popover: `0.875rem`.
- Avatars: `rounded-full`.

### Cards
- Surface: `--neutral-white` (paper), 10px radius, 1px `--border` or no border, `shadow-sm`.
- Home card layout: image header top (`sm:h-[200px]`, filled with `--blue-900`), content stack below, pill button pinned to bottom. Max height 459px on desktop.
- Quiz card is a warmer tint: `#dbe3fa` → `#BFCCF8` on hover.

### Transparency & blur
- Used sparingly. Modal overlay: `bg-[#0E1425]/80` (the deep navy black at 80% opacity) — no backdrop blur.
- Sidebar avatar hover: `bg-blue-800/50` — light tint, no blur.
- No glassmorphism, no frosted surfaces.

### Layout rules
- Fixed topbar (64px, `h-16`), sticky sidebar on desktop (collapses to icon rail), main content scrolls underneath.
- Auth routes suppress the shell entirely and paint full-bleed imagery.
- Mobile: cards re-flow to vertical list, sidebar becomes an overlay drawer.

---

## ICONOGRAPHY

### Primary icon system
**Lucide** (`lucide-react` in the source) — 1.5 stroke by default. This is the working icon set for the app: `Menu`, `Languages`, `ScanText`, `PencilRuler`, `BotMessageSquare`, `BookOpenText`, `ListTodo`, `Users`, `LogOut`, `Clock`, `ChevronRight`, `ChevronDown`, `History`, `TriangleAlert`, `Webcam`, `Settings`, `TextQuote`.

In this design system we link Lucide from CDN (`https://unpkg.com/lucide@latest` — static SVG) rather than shipping a sprite. Flutter builds should use the [`lucide_icons`](https://pub.dev/packages/lucide_icons) package for 1:1 parity.

### Mascot & illustration
The **Butty** set in `assets/` *is* the iconographic heart of the brand — more than any glyph icon. Use a Butty illustration wherever an empty state, loading state, or onboarding moment would otherwise call for a stock icon.

### Baybayin glyphs
Rendered via the bundled **Baybayin Simple TAWBID** font, not as SVG or PNG icons. Any time a Baybayin character must appear in-UI, set `font-family: var(--font-baybayin)` on a span and type the Latin-mapped character — the font substitution handles the rest. This keeps the glyphs resolution-independent and lets `baybayin_latin.tsx` toggle between transliteration variants.

### App icon & logos
- `assets/BaybayInscribe-AppIcon.webp` — current primary app mark (Butty's face + a Baybayin paper fragment in the mouth). Used in the topbar.
- `assets/BaybayInscribe-AppIcon-old.webp` — historical mark, kept for the admin surface in the source. **Flag:** Kudlit will likely want a new wordmark; for now the ex-BaybayInscribe icon is the placeholder.
- `assets/TransliteratorHeader.webp` — banner for the transliterator feature.

### Flags
- `assets/flag-ph.webp`, `assets/flag-us.webp` — used by the language switcher.

### Emoji & unicode
- Not used as icons. Never substitute a 📷 for `ScanText`.
- Do not draw hand-rolled SVG replacements; always prefer Lucide or Butty.

---

## Flags & substitutions

- **UI font** — production `app/layout.tsx` uses `next/font/google` Geist + Geist Mono. We import the same families from Google Fonts at the top of `colors_and_type.css`. No visual loss expected.
- **Logo / wordmark** — no Kudlit-branded lockup exists yet. Currently using the BaybayInscribe app-icon as a visual placeholder. **Ask the user for a Kudlit wordmark.**
- **Admin UI** — omitted from UI kit. Admin surfaces from the web client (`app/(screens)/admin/…`) do not apply to the Flutter mobile scope.
