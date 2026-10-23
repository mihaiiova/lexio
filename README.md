# Slove

Beautiful Romanian word games. Calm, minimalist, typography-first.

## Overview

Slove is a collection of premium word games for the Romanian language — the "NYT Games for Romanian". Four interactive games: grammar correction, vocabulary definitions, Romanian idioms, and find-the-mistake texts.

**Platforms**: iOS, Android

## Quick Start

```bash
flutter pub get
flutter run
```

## Games

| Game | Romanian Title | Type | Exercises |
|---|---|---|---|
| Grammar | Corect sau greșit? | True/false grammar challenge | 511 generated exercises |
| Vocabulary | Ce înseamnă? | Multiple-choice definitions | 100 |
| Idioms | Vorba vine | Expression meaning | 60 |
| Spot | Găsește greșeala | Timed error-finding (60s) | 59 texts |

## Public content

The full Romanian content (words, idioms, grammar pairs, and spot texts) is
published in [`content_public/`](content_public/README.md) for editorial review.
Regenerate after content changes:

```bash
python3 scripts/generate_public_pages.py
```

## Project Structure

```
lib/
  main.dart                    # Entry point
  app/                         # App shell, routing
  design/                      # Design system
    theme.dart                 # Centralized theme
    colors.dart                # Color tokens
    typography.dart            # Type scale
    spacing.dart               # Spacing scale
    radius.dart                # Border radius tokens
    shadows.dart               # Shadow tokens
    animations.dart            # Animation durations & curves
    components/                # Reusable UI components (LexioButton, LexioCard, LexioFeedback)
  games/                       # All games
    grammar/                   # Grammar game — Corect sau greșit?
    vocabulary/                # Vocabulary game — Ce înseamnă?
    idioms/                    # Idioms game — Vorba vine
    spot/                      # Spot game — Găsește greșeala
  home/                        # Home screen
  content/                     # Local exercise data (JSON)
  progress/                    # Local progress persistence (SharedPreferences, spaced repetition)
```

## Design Principles

- **Typography-first**: Large, readable text with generous spacing
- **Minimalist**: Only essential UI chrome
- **Calm**: Gentle colors, subtle animations
- **Premium**: Clean cards, consistent spacing, refined details
- **Fast**: Local content and progress; optional analytics never blocks play

## Architecture Decisions

- Each game is an isolated module; the home catalogue owns its navigation metadata
- Design tokens are centralized — changing fonts, colors, spacing, radii, or animation timing needs edits in one place
- Content is stored as local JSON for easy addition of thousands of exercises
- **Offline-first content**: bundled baseline plus a static bundle refreshed in the background; progress stays local
- **Local persistence**: Progress tracked via `SharedPreferences` with spaced repetition
- **Local learning, narrow analytics exception** — content and progress remain local (a static CDN delivers content one-way). Optional consent-gated first-party Worker/D1 analytics uses a separate per-installation secret for authenticated deletion; there are no accounts or general authentication backend.
- **Privacy-conscious**: guardian-opt-in first-party analytics (default off), no advertising or accounts; full learning progress remains local
- **Deadline-based timer**: Spot game uses wall-clock deadlines, not callback counting
- **Lifecycle-safe**: App respects background/foreground transitions (WidgetsBindingObserver)
- **Brand**: Primary blue `#4588E0`, NoticiaText font family, white surfaces

## Testing

```bash
flutter analyze   # Static analysis — zero warnings
flutter test      # Unit and widget tests under test/
flutter drive --driver test_driver/integration_test.dart --target integration_test/screenshot_test.dart  # Device screenshot workflow
```

Test structure:
```
test/
  design/          # Design component tests
  games/
    grammar/       # Grammar game tests
    spot/          # Spot game tests (logic + integration + content)
    vocabulary/    # Vocabulary game tests
  progress/        # Spaced repetition logic
  accessibility/   # Semantics tests
integration_test/
  screenshot_test.dart  # Device-only screenshot capture workflow
```

Content validation and bundle generation:
```bash
python3 scripts/validate_content.py                 # structural + notionId validation
python3 scripts/generate_content_bundle.py --bump   # regenerate the remote bundle + manifest
```

## Dependencies

- **flutter**: UI framework
- **shared_preferences**: Local progress and content-bundle storage
- **http**: Offline-first remote content download
- **url_launcher**: External DOOM dictionary links
- **flutter_localizations**: Romanian locale support

## CI/CD

- **CI** (`.github/workflows/ci.yml`): Analyze → unit/widget tests → Build Web → Build Android (AAB) — runs on PRs and feature-branch pushes
- **Screenshot integration test**: run manually on a connected device or emulator; it captures store-review assets and is not a CI release gate
- **Staging** (`.github/workflows/deploy-staging.yml`): push to `staging` → TestFlight + Play internal testing
- **Production** (`.github/workflows/deploy-prod.yml`): push to `master` → App Store Connect + Play production

See [`docs/releasing.md`](docs/releasing.md) for how to version, test, and ship updates.

## Privacy

- The Romanian privacy policy is available from the home-screen footer and at https://didactiv.ro/confidentialitate/slove/.
- The canonical policy text is stored in `store_listings/privacy_policy.md`.
- There is no vendor tracking SDK. Optional first-party analytics is **off by default** and requires a guardian-directed opt-in. Guardian confirmation is self-declared, not verified legal consent. Play remains available after declining and offline.
- Settings permits withdrawing consent and requesting deletion of this installation's linked records. Collection stops immediately; an offline/failed deletion retains its credential for retry and prevents re-enabling until acknowledgment. Re-enabling then creates a fresh random installation identity, not a person/account identifier.
- All four games send only bounded lifecycle events, exercise IDs, active bundle revision, timestamps and outcomes/count deltas; never exercise text, raw answers, words or selected positions. Installation-linked records are not irreversibly anonymous. Events expire at 90 days; inactive credentials expire after 90 days without ingestion once linked events are gone, and revocation records expire 90 days after first deletion, without retry extension. Daily scheduled purging can add up to a day (operational failures can delay it further and require monitoring); no extra credential-retention exception or indefinite inactive identity metadata is intended. Ingestion rejects future timestamps and events at/older than the 90-day horizon, so original payloads cannot replay after tombstone expiry. Only unlinked aggregate totals may remain; deletion does not reverse previously unlinked totals.
- The first-party Cloudflare Worker/D1 implementation is in [`worker/`](worker/). Configure a reviewed HTTPS collector at build time with `flutter run --dart-define=ANALYTICS_ENDPOINT=https://your-collector.example` (or the same flag for `flutter build`). It uses `POST /v1/events` and authenticated `POST /v1/delete`; never embed administrative credentials in the app.
- With the endpoint unset or the network unavailable, delivery fails safely: the bounded local queue retries at launch, resume, subsequent collection and explicit flush points, without an offline retry loop. Batches contain at most 100 events and stay below 60 KB. Revocation clears queued events; no pre-consent play is backfilled.
- If local withdrawal cannot be saved, Settings warns that collection is off for this process but the old setting can return after relaunch; retry saving before closing. If all local writes fail, no durable revocation guarantee is possible. Server deletion acknowledgment is independent of local storage. Lifecycle state, device-only Spot distinct-position sets, and queued events share one durable snapshot per action; Spot discovery/resolution is atomic too. A total local storage failure can still lose unsent analytics. Stable event IDs prevent repeated delivery from duplicating metrics.
- Child-privacy/legal and store-policy review, manual first-run/offline testing, endpoint provisioning and production deployment remain release gates. This implementation is not evidence that those sign-offs occurred.

### Analytics metric units

| Games | Shown / resolved unit | Interaction metrics |
|---|---|---|
| Grammar, Vocabulary, Idioms | One rendered exercise variant; resolved by its first committed answer | One correct/wrong answer per exercise |
| Spot | One rendered text; resolved only when all its mistakes are found | All in-play word presses (including repeats), newly found mistakes, distinct wrong word positions per round |

These are different units: do not add MC correct/wrong answers to Spot discoveries
or distinct wrong positions. Revealing corrections is not Spot completion. The
same wrong position in two different texts counts twice; a repeated wrong press
in the same text counts only as another attempt. A repeated found-token press
while the text is still unresolved counts as an attempt, not another discovery;
legacy wrong-word presses after resolution, before leaving the text, still count
as attempts/distinct wrong positions because gameplay still accepts them. They do
not undo resolution or emit another resolution. No new found-token action is
enabled after resolution; locked/ended input is not counted. Gameplay scoring sets
are unchanged.
Spot sends `spot_attempt` events with `attemptDelta: 1`,
`correctDiscoveryDelta: 0|1`, and `distinctWrongDelta: 0|1`. Actual word positions
stay on device. Retained
Spot counters each require five distinct positive-delta contributing installations;
insufficient cohorts are null/suppressed, never a measured zero. Suppression
propagates through later aggregate updates. See the
[bounded Worker schema](worker/README.md).

Impressions run after rendering, never from build. Every replay has a fresh
round session. Back exits retain the last rendered exercise/text and resolution;
timed Spot expiry uses `timeout`. Backgrounding alone does not close a round.
An unfinished round is inferred interrupted on next startup at its last observed
activity (bounded by the recovery clock), not at an invented app-kill time.
An unresolved exit is not a wrong answer. Earlier unresolved texts can be derived
from text impressions lacking a corresponding resolution. Item IDs are exercise
IDs, not shared learning notion IDs; item indices are round/text positions, never
selected word or answer positions. No pre-consent play is backfilled.

## License

All rights reserved. © 2026 Slove.
