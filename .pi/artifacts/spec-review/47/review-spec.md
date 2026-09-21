## Review

### Acceptance-criteria matrix

| ID | Requirement | Evidence in diff | Status |
|---|---|---|---|
| R1 | Interactive controls (answer, next, navigation, progress, timer, result) expose useful Romanian semantics | Covered by `test/accessibility/semantics_test.dart` (`file:line`): home entries :64–68 (new `Semantics(button:, label:, onTap:, excludeSemantics:)`, `lib/home/home_screen.dart:186–190`), grammar answer+next :85–93, vocabulary options/back :110–113, idioms back/progress :130–131, spot back/timer/progress/token :148–151. **Result controls not covered**: summary rows are `Semantics(button: true)` with **no label** (`lib/design/components/lexio_action_row.dart:19–21`) and no test renders a summary screen. | partial |
| R2 | Critical status/progress updates are discoverable to screen readers | Spot timer `Semantics(label: 'Timp rămas: …', liveRegion: true)` (`lib/games/spot/spot_screen.dart:327–331`) asserted at `semantics_test.dart:149`; progress labels asserted at :87, :111, :131, :150. All progress assertions are the *initial* `0 din N`; no progress bar sets `liveRegion` (`grammar_screen.dart:268`); the one live region changes every second (`spot_screen.dart:117–135`). | partial |
| R3 | No overflow at 320×568 | `test/accessibility/responsive_test.dart:38–106`: home, grammar wrong-answer→explanation, vocabulary/idioms incorrect card, spot play actions, privacy. Result/summary state, spot checking/advance state and home→game navigation never rendered. | partial |
| R4 | No overflow at 375×667 | Same loop, `Size(375, 667)` (`responsive_test.dart:31–35`). Same gaps. | partial |
| R5 | No overflow at one tablet config | Same loop, `'tablet': Size(800, 1280)`. Same gaps. | partial |
| R6 | Injectable seams: `GrammarScreen(exercises:)`, `SpotScreen(texts:)`, `HomeScreen(progressRepository:)` | `grammar_screen.dart:20–28,47–58`; `spot_screen.dart:19–26,42–51`; `home_screen.dart:19–21`; idioms/vocabulary already had `exercises:`/`progressRepository:` (unchanged, `idioms_screen.dart:23–24`); consumed by `test/games/grammar/grammar_screen_injection_test.dart`, `test/games/spot/spot_screen_injection_test.dart`, `test/home/home_screen_test.dart:18`. | met |
| R7 | `GameSessionAnalytics` accepts injectable sink + `backgroundAbandonmentDelay` | `lib/analytics/game_session_analytics.dart:5–46`; exercised in `test/analytics/game_session_analytics_test.dart:8–52`. | met |
| R8 | Backgrounded past delay → abandoned; resume before delay prevents it | `game_session_analytics.dart:69–110` (`markBackgrounded`/`markResumed`/`_abandonIfStillBackgrounded`), tests `game_session_analytics_test.dart:55–95`. Screen wiring (`grammar_screen.dart:71–78`, idioms, vocabulary, spot) untested; `AppLifecycleState.hidden` unhandled. | met |
| R9 | Home injects the progress repository into game screens | `home_screen.dart:50,61,72,83`. Only test is `test/home/home_screen_test.dart:18–23`, which asserts titles and never taps an entry. `LexioApp` still builds `const HomeScreen()` (`lib/app/app.dart:23`) → seam is test-only. | partial |
| R10 | PrivacyScreen audited at the three sizes | `responsive_test.dart:101–106`; `privacy_screen.dart:22` is a `ListView` (cannot overflow), so the check is near-vacuous. | met |
| R11 | Prioritized risk list with reproducible evidence + linked GitHub Issues | No docs/artifacts in the diff (13 files, none `.md`); `RELEASE_READINESS_REPORT.md` unchanged (still "119 tests passed"). Not verifiable from the repo. | missing |

### (a) Missing or partial
- **R11 missing** — *"As a release owner, I receive a prioritized risk list with reproducible evidence and linked GitHub Issues."* Nothing in the diff; confirm the linked issues exist in the tracker before closing #47 (P2; escalate if none exist).
- **R3–R5 partial** — spec: tests should "*exercise answer, next, navigation, timer, and result paths*". `responsive_test.dart:46–98` stops at the question/incorrect states: no summary (`RUNDĂ ÎNCHEIATĂ`, `Joacă din nou`), no spot checking/advance, no navigation. Home/privacy are also pumped without `LexioTheme.light` (:40, :104) while the other four apply it.
- **R9 partial** — injection reaches `GrammarScreen`/`VocabularyScreen`/`IdiomsScreen`/`SpotScreen` (P2), but no test taps a home entry, and production (`app.dart:23`) always passes `null`, so propagation is unproven.
- **R1 partial** — *"interactive controls have useful Romanian semantics"*: summary result rows (`lexio_action_row.dart:19–21`) are unlabelled and untested.

### (b) Scope creep
- `grammar_screen.dart:156–166`: `_playAgain` now degrades to `const GameProgress()` instead of no-op — a behaviour change not requested by the audit.
- Test-only import churn (`semantics_test.dart:4–25`, `avoid_relative_lib_imports` ignores): consistent with AGENTS.md, not with the spec.

### (c) Implemented but wrong
- **R2** — *"critical status/progress updates are discoverable"*: the timer live region is announced every second because `_startTimer` calls `setState` unconditionally (`spot_screen.dart:117–135`), and `semantics_test.dart:149` certifies it with a single snapshot; progress bars get no `liveRegion` at all.
- **R8** — *"Sessions backgrounded past the delay are abandoned"*: `AppLifecycleState.hidden` is unhandled in all four handlers (`grammar_screen.dart:71–78` and siblings); on the web/desktop targets the timer may never arm — one web/device check needed.

**Correct:** both layout fixes are real and exercised at all three sizes — `LexioIncorrectAnswerCard` `Expanded` (via wrong-option taps, `responsive_test.dart:61–86`) and the spot action-row `Wrap` (spot play-actions state).

**Merge verdict:** OK with notes (no P0/P1; resolve R11 in the tracker).