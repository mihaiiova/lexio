# Review: Issue #61 all-game analytics
**Date:** 2026-10-24
**Session:** Added consent-gated Vocabulary, Idioms and distinct-unit Spot metrics.

## History Checked
- `2026-10-23-analytics-backend-safety.md`
- `2026-10-14-app-store-cover.md`
- `2026-10-07-separate-content-deployment.md`
- `2026-10-02-staging-play-upload.md`
- `2026-09-01-spec-44-game-list-progress-cards.md`

## Recurring Patterns
- Explicit-path staging again preserved unrelated `.pi/` changes, consistent with the October history. No recurring problem requiring a new process change.

## Scores
| Dimension | Score |
|-----------|-------|
| Friction | 0.4 |
| Repetition | 0.3 |
| Missing capability | 0.2 |
| Knowledge gap | 0.3 |
| Fragility | 0.6 |

## Suggestions
No significant improvement opportunities found above the skill's 0.6 threshold.

## Changes Made
- No additional process/configuration changes proposed or made.

## Notes
- Public-seam red/green checkpoints covered lifecycle, durable Spot deltas, Worker validation/retention, Home wiring and exposure/deadline races. Supplemental tests exercise existing state semantics and privacy fences.
- The MC tracer was red first; Idioms initially received the matching implementation in the same slice before its dedicated assertions were added. This is a test-first granularity limitation, not independent Idioms red evidence.
- A full-suite failure exposed a legacy byte-limit fixture using an unknown game ID. The fixture now uses a known game while retaining its large UTF-8 fields; production validation was not weakened.
- Manual device, legal/store and deployment checks remain unavailable; automated results do not replace them.
- Source inspection found legacy wrong-word input remains active after text resolution. Supervisor clarified that those accepted presses must still be counted without changing scoring or repeating resolution; the earlier completion guard was removed via a failing regression first. Found-token repeat observation remains unresolved-play-only.
- Supervisor approved per-counter positive-contributor suppression after review found a whole-cell threshold did not protect sparse Spot numerators. Nullable counters preserve suppression through upserts; regression tests were red before that repair. Future #62 consumers must preserve null, not treat it as zero.
