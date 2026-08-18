# DESIGN.md — Slove Design System

## Philosophy

Slove's design draws from premium vocabulary apps: large typography, generous whitespace, subtle animations, clean cards, minimal chrome. The interface should feel like turning pages in a beautiful book.

## Typography

The bundled **NoticiaText** family is used for the application typography, with regular, italic, bold, and bold-italic variants.

### Scale

| Token | Size | Weight | Line Height | Use |
|---|---|---|---|---|
| `displayHero` | 64 | 400 | 1.05 | Hero display |
| `displayLarge` | 40 | 700 | 1.1 | Screen titles |
| `displayMedium` | 32 | 700 | 1.15 | Result headlines |
| `sentence` | 34 | 400 | 1.35 | Game prompts |
| `headingLarge` | 26 | 600 | 1.2 | Section headers |
| `headingMedium` | 28 | 600 | 1.25 | Game titles |
| `headingSmall` | 19 | 600 | 1.3 | Small headings |
| `bodyLarge` | 19 | 400 | 1.5 | Primary body text |
| `bodyMedium` | 17 | 400 | 1.5 | Secondary body text |
| `bodySmall` | 14 | 400 | 1.4 | Labels and captions |
| `labelLarge` | 18 | 600 | 1.3 | Prominent labels |
| `labelMedium` | 15 | 500 | 1.3 | Controls |
| `labelSmall` | 13 | 500 | 1.3 | Compact labels |
| `spotText` | 20 | 400 | 1.35 | Spot text tokens |
| `spotCorrection` | 13 | 700 | 1.35 | Spot corrections |
| `overline` | 11 | 500 | 1.3 | Uppercase metadata |
| `accentLarge` | 20 | 500 | 1.4 | Pull quotes |
| `monoSmall` | 13 | 400 | 1.4 | Code and numbers |

## Colors

### Palette

- **Primary**: Blue (`#4588E0`) — main actions and progress
- **Secondary**: Coral (`#E04B40`) — vocabulary accents
- **Accent**: Amber (`#E6981A`) — highlights and Spot accents
- **Background and surface**: White (`#FFFFFF`) — clean reading surface

### Semantic Colors

- **Success**: Green (`#52A860`) — correct answers
- **Error**: Red (`#CC3333`) — mistakes
- **Warning**: Amber (`#E6981A`) — alerts
- **Info**: Blue (`#4588E0`) — neutral messages

Each semantic color has a matching background variant (10% opacity) for subtle containers.

## Spacing

Based on a 4px grid:

| Token | Value | Use |
|---|---|---|
| `hairline` | 1 | Hairline insets |
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
- `tokenVertical` = 3 (Spot token inset)
- `buttonSmallVertical` = 10 (small-button vertical inset)

## Radius

| Token | Value | Use |
|---|---|---|
| `none` | 0 | Sharp elements |
| `xs` | 2 | Fine progress indicators |
| `sm` | 4 | Tags, badges |
| `md` | 8 | Inputs, small containers |
| `lg` | 12 | Buttons |
| `xl` | 16 | Cards |
| `xxl` | 24 | Modal surfaces |
| `full` | 999 | Pills, avatars |

## Sizes

Dimension tokens for icons, strokes, and transitions (`lib/design/sizes.dart`).

| Token | Value | Use |
|---|---|---|
| `progressBarActive` | 4 | Active progress segment height |
| `progressBarIdle` | 3 | Idle progress segment height |
| `iconCheckmark` | 80 | Correct-answer flash icon |
| `iconFeedback` | 20 | Feedback message icon |
| `iconSpinner` | 16 | Button loading spinner |
| `iconSizeStep` | 2 | Icon size increment over label text |
| `strokeWidth` | 2 | Spinner stroke width |
| `strikeThickness` | 2 | Strikethrough decoration thickness |
| `slideOffset` | 12 | Small transition slide distance |
| `slideOffsetLarge` | 20 | Large transition slide distance |

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
| `shake` | 400ms | Incorrect-token shake |
| `feedback` | 450ms | Answer feedback |

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
