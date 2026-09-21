# Audit release UX, accessibility, and small-screen behavior

## Parent

[Epic: Release-readiness hardening and regression coverage](https://github.com/mihaiiova/lexio/issues/45)

# Problem Statement
The app has ad-hoc `Semantics` coverage and no documented responsive breakpoint or minimum-device contract. Existing accessibility tests mostly assert rendered text/navigation rather than semantic labels, while four game screens contain interactive controls, progress indicators, timers, token taps, and result flows that can fail on small screens or under lifecycle edge cases.

# Solution
Perform an evidence-based release audit after the verification baseline is stable. Review crash and edge-case behavior, then harden only the observed risks across home, grammar, vocabulary, idioms, spot, privacy, and analytics lifecycle flows. Make the acceptance bar explicit: interactive controls have useful Romanian semantics, critical status/progress updates are discoverable, and the primary flows render without overflow at 320×568, 375×667, and one tablet-width configuration.

# User Stories
- As a learner using a small phone, I can complete each game without clipped controls, overflow, or unreachable actions.
- As a learner using a screen reader, I can identify and operate answer, next, navigation, progress, timer, and result controls.
- As a release owner, I receive a prioritized risk list with reproducible evidence and linked GitHub Issues.

# Implementation Decisions
- Start with `HomeScreen`, `GrammarScreen`, `IdiomsScreen`, `VocabularyScreen`, `SpotScreen`, shared design components, and `PrivacyScreen`; include `GameSessionAnalytics` lifecycle behavior when the audit reaches it.
- Use design tokens from `lib/design/`; do not solve layout problems with new hardcoded values.
- Prefer semantic Flutter widgets and existing component seams; do not add a dependency solely for accessibility or visual testing.
- Treat P0/P1 crash, data-loss, inaccessible critical action, and reproducible overflow findings as release blockers until fixed or explicitly waived in a GitHub Issue.

# Testing Decisions
- Extend `test/accessibility/semantics_test.dart` to inspect actual `Semantics` nodes/labels/actions for critical controls, using the injectable constructors `GrammarScreen(exercises:)`, `IdiomsScreen(exercises:)`, `VocabularyScreen(exercises:)`, `SpotScreen(texts:)`, and `HomeScreen(progressStorage:)`.
- Add widget tests that pump the critical states at 320×568, 375×667, and tablet width and assert no `RenderFlex`/layout overflow while exercising answer, next, navigation, timer, and result paths.
- Use `GameSessionAnalytics(gameId, sink:, backgroundAbandonmentDelay:)` and `GameSessionAnalyticsSink` for deterministic lifecycle-event checks where the audit identifies a risk.
- Record manual/device-only limitations separately; the CI gate remains the automated analyze/test/content-validation suite.

# Out of Scope
- A full visual redesign, localization system change, store screenshot production, or a new golden-test dependency.
- Implementing unrelated ROADMAP items that are not evidenced by this audit.

# Further Notes
The accepted quality bar is explicit: useful semantics for all critical interactive controls, critical-flow widget coverage, and no overflow at the two phone sizes plus a tablet-width configuration.

## Blocked by

- [Stabilize verification and progress durability](https://github.com/mihaiiova/lexio/issues/46)

<!-- pi:new-spec:v2 repo=mihaiiova/lexio plan=4eaf4e48-1ee7-4a4e-a7bd-0a1e9d0a3e88 kind=child id=audit-release-ux-accessibility-responsive -->
