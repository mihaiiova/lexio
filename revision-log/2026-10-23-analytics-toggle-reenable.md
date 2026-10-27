# Review: Analytics toggle and monochrome consent actions
**Date:** 2026-10-23
**Session:** Removed the requested onboarding assurances, applied white-on-black consent buttons, and repaired ordinary analytics off/on behavior (#64).

## History Checked
- `2026-10-23-friendly-analytics-consent.md`
- `2026-10-23-private-analytics-report.md`
- `2026-10-24-analytics-all-games.md`
- `2026-10-23-analytics-backend-safety.md`
- `2026-10-14-app-store-cover.md`

## Recurring Patterns
- Explicit-path staging again preserves unrelated `.pi/` modifications.
- Numbered inline source packets again enabled a read-only external review without changing permissions, as described in the private-report and friendly-consent entries.
- A previous local reset did not change the product's off/on contract. This round fixes that contract through the full public Settings interaction rather than treating another reset as the product fix.

## Scores
| Dimension | Score |
|-----------|-------|
| Friction | 0.4 |
| Repetition | 0.3 |
| Missing capability | 0.2 |
| Knowledge gap | 0.4 |
| Fragility | 0.5 |

## Suggestions
No significant improvement opportunities found.

## Changes Made
- No process, permission, model or shared configuration changes proposed or made.

## Notes
- The public Settings regression failed because ordinary withdrawal left `Switch.onChanged` null. The repository regression separately failed because withdrawal marked the installation as awaiting deletion. Ordinary withdrawal now retains its credentials, stops collection and discards queued events without starting deletion; only explicit deletion blocks opt-in.
- Resuming requires a durable empty identity-bound snapshot before enabling. A review highlighted possible recovery of an uncleared legacy pending round; a regression reproduced an unwanted inferred event before binding empty snapshots to the retained identity. This overrides legacy state even if cleanup fails repeatedly.
- Tests also cover offline resume after relaunch, failed queue cleanup, pending explicit deletion across off/relaunch, deletion fencing an in-flight first activation, and keeping deletion available while analytics is off.
- The requested assurance text is removed only from onboarding. Privacy details remain available. Both consent choices use a new opt-in monochrome variant; existing button defaults and game feedback colors are unchanged.
- The source-backed review found no P1/P2 blockers. The parent ran analysis, all 371 Flutter tests and the Worker checks after the final legacy-round hardening; all passed. App and canonical policy section strings match.
- Legacy pending-deletion records remain fail-closed in the product because historical ordinary withdrawal and explicit deletion cannot be distinguished safely. Only the known local developer fixture was repaired: app closed, no configured collector, no queued events or pending round, original consent privately backed up, identity/credential retained, analytics still off, and every other saved preference including progress verified unchanged.
- No push, merge, deployment or collector activation occurred. Manual device/screen-reader checks and child-privacy/store approval remain unverified.
