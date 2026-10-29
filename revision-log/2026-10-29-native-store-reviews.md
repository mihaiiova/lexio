# Review: Native store reviews
**Date:** 2026-10-29
**Session:** Added standard iOS and Android review requests and a direct Settings store link.

## History Checked
- `2026-10-27-production-analytics-preparation.md`
- `2026-10-27-simplify-analytics-retry.md`
- `2026-10-26-access-first-login-cookie.md`
- `2026-10-26-analytics-test-deployment.md`
- `2026-10-26-analytics-delete-availability.md`

## Recurring Patterns
- None found requiring a process change. As in prior rounds, platform/device verification is distinguished from automated tests, and unrelated `.pi/` edits remain untouched.

## Scores
| Dimension | Score |
|-----------|-------|
| Friction | 0.2 |
| Repetition | 0.2 |
| Missing capability | 0.1 |
| Knowledge gap | 0.3 |
| Fragility | 0.4 |

## Suggestions
No significant improvement opportunities found.

## Changes Made
- No shared process, permission or global configuration changes.

## Notes
- Checked Apple, Google and Flutter plugin guidance before implementation. Used native APIs with no custom screening, incentives, score-based eligibility or automatic store fallback.
- Scheduling is persisted locally, independent of analytics consent, and fails silently without blocking gameplay. Summary lifecycle tests cover single counting across rebuilds and suppression while inactive or disposed.
- Added release configuration instructions for the numeric iOS Apple ID and passed it through both existing IPA workflows. No store ID was guessed; the iOS Settings link remains hidden if unconfigured.
- Flutter analysis has no issues; all 395 Flutter tests pass. Native dialogs and published store links still require real-device verification. No build upload, deployment, merge or store submission was performed.
