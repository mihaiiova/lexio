# Review: Unconfigured analytics deletion
**Date:** 2026-10-26
**Session:** Removed the requested onboarding note and made server-deletion availability reflect the actual collector configuration (#64).

## History Checked
- `2026-10-23-analytics-toggle-reenable.md`
- `2026-10-23-friendly-analytics-consent.md`
- `2026-10-23-private-analytics-report.md`
- `2026-10-24-analytics-all-games.md`
- `2026-10-23-analytics-backend-safety.md`

## Recurring Patterns
- Unconfigured local collection was already documented in the toggle and consent rounds. This round addresses the remaining misleading server-deletion action, rather than clearing credentials or claiming server success.
- Explicit-path staging continues to preserve unrelated `.pi/` changes.

## Scores
| Dimension | Score |
|-----------|-------|
| Friction | 0.3 |
| Repetition | 0.2 |
| Missing capability | 0.1 |
| Knowledge gap | 0.2 |
| Fragility | 0.4 |

## Suggestions
No significant improvement opportunities found.

## Changes Made
- No process, permission or shared configuration changes proposed or made.

## Notes
- Three public Settings regressions failed because server deletion remained actionable without an endpoint. Tests use the actual HTTP transport and cover enabled, paused and already-pending deletion states.
- The transport now exposes configuration availability, independently of connectivity. Empty, malformed, non-HTTPS and hostless endpoints cannot make event or deletion requests. Valid HTTPS configurations retain their normal online/offline behavior.
- Settings disables the unavailable action, explains missing configuration and does not mutate consent, issue a request or show success. Existing pending requests and deletion credentials remain intact; no active application or local preferences were modified.
- Removed only the requested parent/settings note from onboarding. Settings and detailed privacy disclosures remain accessible, and the README no longer implies that the consent screen verifies parental authority.
- Parent validation passed analysis, the full Flutter suite and Worker checks. App and canonical privacy section strings match. No new dependencies, backend deployment or collector activation occurred.
- Manual screen-reader/device checks and child-privacy/store approval remain unverified. Actual server-side deletion requires a configured, reachable collector and its acknowledgment.
