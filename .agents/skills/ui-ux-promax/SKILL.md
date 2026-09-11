---
name: ui-ux-promax
description: Use this skill for advanced UI/UX design tasks, such as creating visually appealing, modern, and highly polished interfaces with rich aesthetics, consistent spacing, and smooth interactive feedback.
---

# UI/UX Promax

This skill provides expert guidance on producing top-tier, "Promax" level User Interfaces and User Experiences.

## Core Design Philosophy
1. **Modern Aesthetics**: Interfaces must not only work but look exceptional. Prioritize visual impact.
2. **Consistent Spacing**: Use a defined grid system (e.g., 4px or 8px base grid) for all margins and paddings.
3. **Interactive Feedback**: All touchpoints must have clear, immediate feedback (hover states, active states, loading indicators).
4. **Platform-Appropriate Design**: Adapt the UI to feel native to the platform (Android Material, iOS Cupertino, or a strong custom brand identity like Kudlit DS).

## Procedural Workflow

When tasked with designing or refining a UI component:

1. **Analyze the Brand**: Identify the core colors, typography, and visual language (e.g., Kudlit uses blue-tinted paper surfaces, dark denim ink, and the Geist font).
2. **Component Decomposition**: Break down the UI into logical, reusable components. Keep build methods small.
3. **Accessibility First**: Ensure high contrast, readable text sizes, and support for reduced motion.
4. **Empty and Loading States**: Never leave a screen blank. Design thoughtful empty states (e.g., using "Butty" the mascot) and smooth loading transitions.

## Execution Checklist
- [ ] Are colors mapped to the central Design System instead of hardcoded hex values?
- [ ] Is the spacing consistent and a multiple of the base grid?
- [ ] Are animations smooth and tied to an `AnimationController` (if in Flutter)?
- [ ] Is there proper semantic labeling for screen readers?
