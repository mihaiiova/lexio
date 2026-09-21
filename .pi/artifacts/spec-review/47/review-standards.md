## Review

**Scope checked:** full `staging...a4cb99b` diff (13 files) against `AGENTS.md` (conventions, design tokens, game/test structure, Do-Nots), `DESIGN.md` (token tables), `ARCHITECTURE.md` (state pattern, technical constraints), `README.md` test structure, plus the Fowler smell baseline. Verified in-repo: `analysis_options.yaml` (flutter_lints 6.0.0 → `lints` 6.1.0), CI (analyze/test only, no format gate), `lib/progress/user_progress.dart`, `lib/analytics/analytics_service.dart`.

### Correct
- **No hard standard violations found.** No `package:lexio/` imports added (one removed: `semantics_test.dart:6`); no new dependencies; no hardcoded colors/font sizes/padding/radius in changed `lib/` code — the new `Wrap` uses `LexioSpacing.md`/`LexioSpacing.sm` (`spot_screen.dart:501-503`); all new user-facing strings are Romanian (`spot_screen.dart:218,312`); snake_case files, `_`-private members, `final`-first, const constructors where the state is const; state stays screen-local.
- The relative-import + `// ignore: avoid_relative_lib_imports` pattern in the new tests matches the dominant existing convention (~20 pre-existing test files use it) and satisfies `AGENTS.md` → *Imports: Never use `package:lexio/` imports*. Not a finding, though `avoid_relative_lib_imports` is not actually enabled by the project's lint set.
- `///` docs added on the new public sink API are idiomatic Dart and consistent with the file's pre-existing class doc; `AGENTS.md`'s "no *what* comments" rule targets inline comments. Suppressed.
- `AnalyticsServiceSink` is not a Middle Man: `AnalyticsService` is sealed/static-only, so the adapter is the only available DI seam.

### Finding
- **P2 · judgement — Duplicated Code.** The lifecycle cascade
  `if (state == AppLifecycleState.resumed) { _session.markResumed(); } else if (...) { unawaited(_progress?.flush()); _session.markBackgrounded(); }`
  is now byte-identical in `grammar_screen.dart:70-79`, `idioms_screen.dart:63-71`, `vocabulary_screen.dart:67-75`, `spot_screen.dart:67-75` (spot only adds `_onResume()`). Smallest fix: one mixin/helper (e.g. `GameSessionLifecycle`) that owns flush + session forwarding.
- **P2 · judgement — Duplicated Code / Shotgun Surgery.** The "injected else load" branch repeats at `grammar_screen.dart:50-58` and `:156-166`, `spot_screen.dart:45-55` and `:175-183`; one seam forced the same optional `progressRepository` parameter through 4 screens + `home_screen.dart:16-19,47,61,69,77`. Fix: a single shared construction helper.
- **P2 · judgement — Data Clumps.** `GameSessionAnalyticsSink.recordCompletion(String gameId, int score, int durationSeconds)` (`game_session_analytics.dart:12`); the test sink immediately bundles the triple into `_Completion` (`game_session_analytics_test.dart:114-124`) — evidence a `GameSessionCompletion` value type is wanted.
- **P2 · judgement — Duplicated Code (tests).** `_grammarIncorrect/_vocabulary/_idiom/_spotText` are copied verbatim into `test/accessibility/responsive_test.dart:123-187` and `test/accessibility/semantics_test.dart:190-252` (near-duplicates also in both new injection tests). Fix: shared `test/fixtures/` builders. Repo precedent is per-file fixtures, so low priority.

### Merge verdict
**OK with notes.** No blockers; findings are P2 style/dedup items. No extra test or Git commands required beyond the already-supplied `flutter analyze` (clean) and `flutter test` (170 passed).