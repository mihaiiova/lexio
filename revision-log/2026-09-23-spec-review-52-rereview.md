# Review: Spec 52 remote content bundles re-review
**Date:** 2026-09-23
**Session:** Re-reviewed spec #52 from `staging`, ran the verification gate, fixed the identity-coupling blocker, and re-verified.

## History Checked
- `2026-09-22-spec-review-52.md`
- `2026-09-21-store-assets.md`
- `2026-09-21-black-brand-assets.md`
- `2026-09-20-spec-review-48.md`
- `2026-09-19-spec-review-47.md`

## Recurring Patterns
- Prior logs repeatedly mention local Flutter toolchain drift during verification. The current session produced no new product-file drift from that issue.

## Scores
| Dimension | Score |
|---|---|
| Friction | 0.4 |
| Repetition | 0.2 |
| Missing capability | 0.2 |
| Knowledge gap | 0.4 |
| Fragility | 0.6 |

## Suggestions
| # | Category | Suggestion | Score | Accepted? |
|---|---|---|---|---|
| — | — | No significant improvement opportunities found. | — | — |

## Changes Made
- Removed validator coupling that rejected vocabulary, idiom, and spot wording corrections when their explicit permanent `notionId` was retained.
- Made the notion-ID backfill script preserve existing IDs on reruns.
- Added regression tests for corrected wording retaining identity and for bundled/remote discovery-count parity.

## Notes
- The first review found a P1 identity blocker; it was fixed in the working tree and all affected checks passed again.
- The issue already carries the `spec:reviewed` label, so no lifecycle-label mutation was needed.
