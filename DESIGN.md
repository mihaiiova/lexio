# DESIGN.md — Slove Design System

## Philosophy

Slove's design draws from premium vocabulary apps: large typography, generous whitespace, subtle animations, clean cards, minimal chrome. The interface should feel like turning pages in a beautiful book.

## Typography

Two font families for contrast:
- **Playfair Display** — display/headings (elegant, literary)
- **DM Sans** — body/labels (clean, legible)

### Scale

| Token | Size | Weight | Line Height | Use |
|---|---|---|---|---|
| `displayLarge` | 40 | 700 | 1.1 | Screen titles |
| `displayMedium` | 32 | 700 | 1.15 | Game result headlines |
| `headingLarge` | 26 | 600 | 1.2 | Section headers |
| `headingMedium` | 21 | 600 | 1.25 | Game titles |
| `headingSmall` | 18 | 600 | 1.3 | App bar titles |
| `bodyLarge` | 17 | 400 | 1.5 | Primary body text |
| `bodyMedium` | 15 | 400 | 1.5 | Secondary body text |
| `bodySmall` | 13 | 400 | 1.4 | Labels, captions |
| `labelLarge` | 16 | 600 | 1.3 | Button text |
| `labelMedium` | 14 | 500 | 1.3 | Chips, badges |
| `labelSmall` | 12 | 500 | 1.3 | Overlines, tags |
| `accentLarge` | 20 | 500 | 1.4 | Pull quotes (italic) |
| `monoSmall` | 13 | 400 | 1.4 | Code/numbers |

## Colors

### Palette

- **Primary**: Deep forest green (`#2D5A3D`) — calm, trustworthy, premium
- **Accent**: Warm gold (`#D4A853`) — delight, celebration
- **Background**: Warm off-white (`#FAF9F6`) — book page feel
- **Surface**: Pure white (`#FFFFFF`) — clean cards

### Semantic Colors

- **Success**: Green (`#2D7D46`) — correct answers
- **Error**: Red (`#C62828`) — mistakes
- **Warning**: Orange (`#E65100`) — alerts
- **Info**: Blue (`#1565C0`) — neutral messages

Each semantic color has a matching background variant (10% opacity) for subtle containers.

## Spacing

Based on a 4px grid:

| Token | Value | Use |
|---|---|---|
| `xxs` | 2 | Minimal gap |
| `xs` | 4 | Tight gap |
| `sm` | 8 | Compact gap |
| `md` | 12 | Standard gap |
| `lg` | 16 | Comfortable gap |
| `xl` | 24 | Large gap |
| `xxl` | 32 | Section gap |
| `xxxl` | 48 | Major section gap |
| `huge` | 64 | Screen-level separation |

Semantic spacing:
- `screenHorizontal` = 24 (consistent side padding)
- `cardPadding` = 20 (internal card padding)
- `buttonPadding` = 16 (button internal padding)
- `sectionGap` = 32 (between major sections)
- `itemGap` = 16 (between items in a list)

## Radius

| Token | Value | Use |
|---|---|---|
| `none` | 0 | Sharp elements |
| `sm` | 4 | Tags, badges |
| `md` | 8 | Inputs, small containers |
| `lg` | 12 | Buttons |
| `xl` | 16 | Cards |
| `xxl` | 24 | Modal surfaces |
| `full` | 999 | Pills, avatars |

## Shadows

Progressive elevation system:

| Token | Elevation | Use |
|---|---|---|
| `subtle` | ~1dp | Subtle lift |
| `card` | ~2dp | Default cards |
| `elevated` | ~4dp | Highlighted cards |
| `floating` | ~8dp | Overlays |

Use `cardCombined` for default cards (subtle + card) and `elevatedCombined` for hero surfaces.

## Animations

### Durations

| Token | Value | Use |
|---|---|---|
| `instant` | 100ms | Toggle states |
| `fast` | 200ms | Hover, focus |
| `normal` | 300ms | Page elements |
| `slow` | 500ms | Major transitions |
| `reveal` | 600ms | Content appearing |
| `page` | 350ms | Page transitions |

### Curves

| Token | Curve | Feel |
|---|---|---|
| `easeOut` | Standard ease-out | Natural deceleration |
| `easeInOut` | Standard ease-in-out | Symmetric transitions |
| `spring` | Elastic out | Playful bounces |
| `smooth` | Custom cubic (0.22, 0.61, 0.36, 1) | Polished, premium |
| `bouncy` | Custom cubic (0.34, 1.56, 0.64, 1) | Exaggerated bounce |

## Components

### LexioCard
Surface container. Props: child, onTap, padding, margin, backgroundColor, borderColor, shadows, borderRadius. Default: white surface with card shadow.

### LexioButton
Action button. Variants: primary, secondary, ghost, danger. Sizes: small, medium, large. Props: label, onPressed, icon, isExpanded, isLoading.

### LexioFeedback
Status message. Types: success, error, warning, info. Props: message, description, action, actionLabel.
