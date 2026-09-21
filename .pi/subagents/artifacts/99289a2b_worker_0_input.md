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

ROLE: STANDARDS review only. Report per file/hunk.
Standards sources (read them): AGENTS.md (project root, the coding standards), ARCHITECTURE.md, DESIGN.md (design token policy), README.md (project structure).

SMELL BASELINE (applies on top of repo standards; repo standards OVERRIDE):
Mysterious Name — a name that doesn't reveal what it does/holds -> rename it.
Duplicated Code — same logic shape appears in more than one hunk/file -> extract shared shape.
Feature Envy — a method reaching into another object's data more than its own -> move the method.
Data Clumps — same few fields/params keep travelling together -> bundle into a type.
Primitive Obsession — primitive/string standing in for a domain concept -> give it a type.
Repeated Switches — same switch/if-cascade on same type recurs -> polymorphism or one shared map.
Shotgun Surgery — one logical change scattered across many files -> gather into one module.
Divergent Change — one file edited for several unrelated reasons -> split it.
Speculative Generality — abstraction/hooks for needs the spec lacks -> delete it.
Message Chains — long a.b().c().d() navigation -> hide behind one method.
Middle Man — a class mostly just delegates onward -> cut it.
Refused Bequest — subclass ignoring most of what it inherits -> composition instead.

BRIEF: Report (a) every place the diff violates a documented standard — cite the file + the rule; and (b) any baseline smell — name it and quote the hunk.
Distinguish HARD violations (documented-standard breaches) from JUDGEMENT calls (baseline smells are always judgement calls; a documented repo standard overrides the baseline).
Skip anything tooling already enforces (flutter analyze and flutter test already run clean).
Under 400 words. Output plain markdown with a bullet per finding.

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