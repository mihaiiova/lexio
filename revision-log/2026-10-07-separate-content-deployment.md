# Review: Separate mobile and exercise-content releases
**Date:** 2026-10-07
**Session:** Moved Cloudflare exercise-content deployment out of the mobile production workflow.

## History Checked
- `2026-10-02-staging-play-upload.md`
- `2026-09-01-spec-44-game-list-progress-cards.md`
- `2026-09-01-spec-42-difficulty-ordered-serving.md`
- `2026-09-01-spec-41-discovery-progress.md`
- `2026-08-18-design-docs-ci-alignment.md`

## Recurring Patterns
- None found. The current mobile/content deployment coupling is distinct from the prior Play upload issue.

## Scores
| Dimension | Score |
|-----------|-------|
| Friction | 0.4 |
| Repetition | 0.3 |
| Missing capability | 0.2 |
| Knowledge gap | 0.5 |
| Fragility | 0.6 |

## Suggestions
| # | Category | Suggestion | Score | Accepted? |
|---|----------|------------|-------|-----------|
| — | — | No significant improvement opportunities found. | — | — |

## Changes Made
- Created a manual exercise-content release workflow separate from mobile production.
- Kept the mobile content URL optional; absent configuration uses bundled exercises.

## Notes
- Workflow YAML parsed successfully and `git diff --check` passed. No release was triggered.
- Existing unrelated `.pi/state.json` and `.playwright-cli/` changes were left untouched.
