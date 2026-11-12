---
name: smart-cv-ui
description: Applies the Smart CV Maker visual design system (AppTheme colours, spacing, radii, typography, icon rules, bottom-sheet and card patterns, responsive and bilingual layout) to new or changed Flutter screens and widgets. Use whenever building or restyling UI — dashboard cards, editor tools, preview controls, AI chat, community pages, dialogs or sheets — in this repository.
---

# Smart CV UI

The app should look calm, clean and uniform. New UI must be indistinguishable in style from existing screens.

## Tokens (always from `lib/app/theme.dart`)

| Use | Token |
| --- | --- |
| Page background | `AppTheme.surfaceLight` |
| Cards, sheets | `AppTheme.surfaceCard` + `Border.all(color: AppTheme.softBorder)` |
| Primary text | `AppTheme.primaryNavy` |
| Secondary text | `AppTheme.mutedText` |
| Brand accent (icons, links, selected) | `AppTheme.brandIndigo` on `AppTheme.indigoSurface` |
| Create / primary CTA | theme `FilledButton` (or `AppTheme.createCvButton` for "create CV") |
| Warning / quota | `AppTheme.warningAmber` on `AppTheme.amberSurface` |
| Error / destructive | `AppTheme.dangerRose` (backgrounds at `alpha: 0.08`) |
| Success | `AppTheme.successGreen` on `AppTheme.tealSurface` |

Never hard-code hex colours or use `Colors.red/green/orange/purple...` in feature code. CV template colours are the only exception (they belong to the document, not the app chrome).

## Spacing, shape, type

- Spacing scale: 4, 8, 12, 16, 24. Page padding 16; gap between cards 12.
- Radii: cards 16, list tiles / inputs / buttons 12, icon tiles 12, sheets use the theme default.
- Icon tile: 40×40 container, `indigoSurface` background, radius 12, `brandIndigo` icon.
- Titles: w800 15–18 px `primaryNavy`; body 13–14 px; captions 12 px `mutedText`, line-height 1.35–1.45.
- Buttons: theme defaults; pair one `FilledButton` with `OutlinedButton`/`TextButton`. Max one filled button per card.

## Icon and decoration rules

- Use outlined/rounded Material icons in a single colour (brand or muted). No multicolour icon sets, gradients, glow, emoji, or decorative illustrations in app chrome.
- One accent colour per card. Status colour only for actual status (quota low, error, success).
- Prefer text + subtle icon over icon-only buttons; icon-only buttons need a `tooltip`.

## Patterns

- Tools open as `showModalBottomSheet(showDragHandle: true, isScrollControlled: true)`; long content uses `DraggableScrollableSheet`.
- Sheets return a value; the caller saves. Destructive or AI-applied changes show a before/after or confirmation.
- Empty states: short sentence + one action. Loading: `LinearProgressIndicator` at the top or an inline spinner, never a full-screen blocker except for short AI calls (`runWithAiProgress`).
- Snackbars are `SnackBarBehavior.floating` with one sentence.
- Drag-and-drop lists use `ReorderableListView` with a visible drag handle and a numbered order badge.

## Responsive and language

- Must work at 360 px wide (Samsung A11) without overflow; use `ResponsiveLayoutBuilder` for desktop/web max-width containers.
- Use `maxLines` + `TextOverflow.ellipsis` for titles in rows.
- App chrome is Vietnamese; CV content labels follow `cv.language`.

## Review checklist

- [ ] No raw hex or `Colors.*` accents in new feature widgets.
- [ ] Card/sheet structure matches an existing component.
- [ ] Tested at 360×780 in a widget test or the browser preview.
- [ ] All tap targets ≥ 40 px; icon-only buttons have tooltips.
