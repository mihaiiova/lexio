# Task for worker

You are a delegated subagent running from a fork of the parent session. Treat the inherited conversation as reference-only context, not a live thread to continue. Do not continue or answer prior messages as if they are waiting for a reply. Your sole job is to execute the task below and return a focused result for that task using your tools.

Task:
Repo: /Users/m/dev/lexio (your cwd is already this directory).
Fixed point is HEAD (5dddcbb). The change under review is the UNCOMMITTED working tree.
Get the diff by running: git diff HEAD
Also read these NEW untracked files (part of the change):
  test/analytics/game_session_analytics_test.dart
  test/games/spot/spot_screen_test.dart
  test/progress/progress_repository_test.dart
If git is unavailable, read each changed file from this diff-stat instead:
  .github/workflows/ci.yml, ARCHITECTURE.md, DESIGN.md, README.md, ROADMAP.md, docs/releasing.md,
  lib/analytics/game_session_analytics.dart, lib/design/animations.dart, lib/design/components/lexio_button.dart,
  lib/design/components/lexio_card.dart, lib/design/radius.dart, lib/design/spacing.dart, lib/design/typography.dart,
  lib/games/grammar/grammar_game.dart, lib/games/grammar/grammar_screen.dart, lib/games/spot/spot_game.dart,
  lib/games/spot/spot_screen.dart, lib/games/spot/widgets/text_token.dart, lib/progress/user_progress.dart,
  test/games/grammar/grammar_game_test.dart, test/games/grammar/grammar_screen_test.dart, test/games/spot/spot_game_test.dart,
  (deleted) lib/games/game_interface.dart

ROLE: SPEC review only. The change implements four GitHub issues. Full spec text follows.

ISSUE #36 — Ensure durable learning-progress persistence:
ProgressRepository.recordAnswer/recordAnswers update memory then async-write SharedPreferences; screens call them without awaiting/serializing/failure-handling, so a stale/unfinished write can lose the newest UserProgress snapshot.
Goals: persist the newest UserProgress snapshot reliably; serialize writes so an older snapshot cannot overwrite a newer one; handle storage failures without unhandled async errors.
Acceptance: rapid answers persist the latest snapshot; failed writes handled explicitly, no uncaught async errors; existing stored progress stays readable/compatible; analyze+test pass.

ISSUE #37 — Harden game state and empty-content handling:
GrammarGameState.answer() accepts repeated answers for the same exercise (unlike vocab/idioms). Grammar and Spot state accessors assume non-empty lists while screens don't consistently reject empty rounds before reading the current item.
Goals: make grammar answer idempotent per exercise; prevent index-zero crashes for empty grammar and Spot selections; present a user-facing empty-state/error screen.
Acceptance: a second grammar answer for the current exercise returns unchanged state; Grammar and Spot show a safe empty state; no empty-collection path accesses currentExercise/currentText; analyze+test pass.

ISSUE #38 — Capture unfinished game sessions across app lifecycle changes:
GameSessionAnalytics emits game_abandoned only from widget disposal; backgrounding/termination don't reliably dispose widgets, so unfinished sessions are undercounted.
Goals: define when a backgrounded session is abandoned; observe lifecycle events; preserve exactly-once semantics for completed and abandoned sessions.
Acceptance: lifecycle/timeout rule documented in code; interrupted unfinished sessions emit at most one abandonment event; completed sessions emit one completion and never abandonment; analyze+relevant tests pass.

ISSUE #39 — Align design tokens, architecture, documentation, and CI coverage:
UI files hardcode sizes/spacing/radii/durations despite token policy. LexioGame is defined but unused; vocab and idioms duplicate game-flow logic; docs conflict with implementation (font/color system, exercise counts, dependency constraints, supported targets). CI runs flutter test but not the screenshot integration suite under integration_test/.
Goals: move non-token UI values into design tokens; decide remove/adopt/replace LexioGame; reduce duplicated game-flow code only where a clearer shared seam exists; correct docs and make CI/test coverage statements accurate.
Acceptance: UI values use tokens; game interface either used or removed with docs updated; duplicate game-flow addressed through a tested abstraction OR explicitly retained with rationale; README/architecture/design/CI descriptions match behavior; integration-test execution decision documented and reflected in CI if a release gate.

BRIEF: Report (a) requirements any issue asked for that are MISSING or PARTIAL; (b) behaviour in the diff that was NOT asked for (scope creep); (c) requirements that look implemented but where the implementation looks WRONG.
Quote the relevant issue line for each finding. Under 400 words. Plain markdown bullets.

## Acceptance Contract
Acceptance level: attested
Completion is not accepted from prose alone. End with a structured acceptance report.

Criteria:
- criterion-1: Return concrete findings with file paths and severity when applicable

Required evidence: review-findings, residual-risks

Finish with a fenced JSON block tagged `acceptance-report` in this shape:
Use empty arrays when no items apply; array fields contain strings unless object entries are shown.
`criteriaSatisfied[].status` must be exactly one of: satisfied, not-satisfied, not-applicable.
`commandsRun[].result` must be exactly one of: passed, failed, not-run.
`manualNotes` and `notes` are optional strings; an empty string means no note and does not satisfy `manual-notes` evidence.
```acceptance-report
{
  "criteriaSatisfied": [
    {
      "id": "criterion-1",
      "status": "satisfied",
      "evidence": "specific proof"
    }
  ],
  "changedFiles": [
    "src/file.ts"
  ],
  "testsAddedOrUpdated": [
    "test/file.test.ts"
  ],
  "commandsRun": [
    {
      "command": "command",
      "result": "passed",
      "summary": "short result"
    }
  ],
  "validationOutput": [
    "validation output or concise summary"
  ],
  "residualRisks": [
    "none"
  ],
  "noStagedFiles": true,
  "diffSummary": "short description of the diff",
  "reviewFindings": [
    "blocker: file.ts:12 - issue found, or no blockers"
  ],
  "manualNotes": "anything else the parent should know"
}
```