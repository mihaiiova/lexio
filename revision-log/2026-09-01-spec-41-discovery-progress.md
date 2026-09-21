# Review: Spec #41 discovery progress bar
**Date:** 2026-09-01
**Session:** Implemented and reviewed issue #41 (mastered-item discovery progress bar under each game and in the end-of-round review).

## History Checked
- `2026-08-18-design-docs-ci-alignment.md`
- `2026-08-18-lifecycle-session-analytics.md`
- `2026-08-18-game-state-hardening.md`
- `2026-08-18-progress-persistence-validation.md`
- `2026-08-18-progress-persistence-round.md`

## Recurring Patterns
- None found. The `git add -A` staging problem in this session is new; no prior entry names it.

## Scores
| Dimension | Score |
|-----------|-------|
| Friction | 0.75 |
| Repetition | 0.50 |
| Missing capability | 0.40 |
| Knowledge gap | 0.35 |
| Fragility | 0.65 |

## Suggestions
| # | Category | Suggestion | Score | Accepted? |
|---|----------|------------|-------|-----------|
| 1 | skills | Stage explicit file paths and check `git status` for pre-existing uncommitted state before the first commit, instead of `git add -A`. | 0.75 | ❌ |
| 2 | organization | Open an issue to commit-or-discard the orphaned working-tree changes (partial subject feature, `.pi` artifacts, screenshots). | 0.65 | ✅ |

## Changes Made
- Opened [#43 — Clean up orphaned uncommitted working-tree changes](https://github.com/mihaiiova/lexio/issues/43).

## Notes
- Suggestion 1 was rejected: the user prefers the current workflow unchanged.
- The partial review-item "subject" feature from a prior session was removed from the #41 branch and left uncommitted in the working tree as found.
- `flutter analyze` and the full `flutter test` suite pass (148 tests) on the committed branch.
