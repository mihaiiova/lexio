# Review: Friendly analytics consent
**Date:** 2026-10-23
**Session:** Replaced the first-launch analytics dialog with concise Romanian onboarding and accessible privacy details (#64).

## History Checked
- `2026-10-23-private-analytics-report.md`
- `2026-10-24-analytics-all-games.md`
- `2026-10-23-analytics-backend-safety.md`
- `2026-10-14-app-store-cover.md`
- `2026-10-07-separate-content-deployment.md`

## Recurring Patterns
- Explicit-path staging preserved unrelated `.pi/` changes, as in the October entries.
- The read-only external-runner limitations recorded in `2026-10-23-private-analytics-report.md` still apply. Numbered inline source packets supplied actual review evidence without requiring additional tool permissions. This recovery worked; no new process change is needed.

## Scores
| Dimension | Score |
|-----------|-------|
| Friction | 0.3 |
| Repetition | 0.1 |
| Missing capability | 0.2 |
| Knowledge gap | 0.2 |
| Fragility | 0.4 |

## Suggestions
No significant improvement opportunities found.

## Changes Made
- No process, configuration, model or permission changes proposed or made.

## Notes
- Public-widget regressions cover consent persistence, rejection/gameplay parity, no pre-consent events, privacy round-trips, safe back, failed activation and withdrawal. Nine onboarding layouts cover small phones and desktop at 1x, 2x and 3.2x text scaling, with accessible action labels and tap targets.
- The layout tests exposed truncation in the shared button. An opt-in wrapping property preserves existing consumers' defaults.
- Two source-backed reviews found no blockers and identified the same decline-action prominence issue. A regression failed against the ghost style before changing only that action to the existing secondary style. Privacy details also explicitly explain the existing deletion prerequisite for re-enabling analytics.
- The full suite caught an outdated privacy-copy assertion; its replacement still checks that the Home privacy route explains default-off collection.
- Reviewer output was retained as review data, not as instructions or evidence of tool execution. Reviewers ran no checks; the parent ran analysis, the full Flutter suite and the Worker checks. All passed after the review fixes; canonical and in-app privacy section strings were compared as well.
- Manual VoiceOver/TalkBack/device testing and child-privacy/store approval remain unverified. Guardian-directed wording does not verify age or parental consent. No collector activation, push, merge or deployment occurred.
