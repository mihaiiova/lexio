# Review: Play internal-testing upload
**Date:** 2026-10-02
**Session:** Fixed the staging Play API review flag and verified a staging deploy on both platforms.

## History Checked
- `2026-09-23-spec-review-52-rereview.md`
- `2026-09-01-spec-44-game-list-progress-cards.md`
- `2026-09-01-spec-42-difficulty-ordered-serving.md`
- `2026-09-01-spec-41-discovery-progress.md`
- `2026-08-18-design-docs-ci-alignment.md`

## Recurring Patterns
- The orphaned working-tree changes from `2026-09-01-spec-41-discovery-progress.md` remain present; this round used explicit-path staging and left them untouched.

## Scores
| Dimension | Score |
|---|---|
| Friction | 0.5 |
| Repetition | 0.3 |
| Missing capability | 0.2 |
| Knowledge gap | 0.4 |
| Fragility | 0.6 |

## Suggestions
| # | Category | Suggestion | Score | Accepted? |
|---|---|---|---|---|
| — | — | No significant improvement opportunities found. | — | — |

## Changes Made
- Removed the Play review-hold flag from the staging workflow in commit `b5dc528`; the Play internal-testing upload now commits successfully.

## Notes
- Staging CI and Android passed; the iOS IPA built but App Store Connect rejected the upload with `Cannot determine the Apple ID from Bundle ID 'com.mihaiiova.lexio' and platform 'IOS'`.
- The workflow uses the shared `Prod` secrets environment but different test-track destinations. The iOS app record/API-key team association must be verified before another upload.
- Existing unrelated working-tree changes were left untouched.
