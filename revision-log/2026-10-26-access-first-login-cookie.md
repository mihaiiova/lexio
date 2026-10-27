# Review: First-login Access redirect loop
**Date:** 2026-10-26
**Session:** Corrected the test report's Access cookie policy after Safari looped on first authentication but loaded after refresh (#65).

## History Checked
- `2026-10-26-analytics-test-deployment.md`
- `2026-10-26-analytics-delete-availability.md`
- `2026-10-23-analytics-toggle-reenable.md`
- `2026-10-23-friendly-analytics-consent.md`
- `2026-10-23-private-analytics-report.md`

## Recurring Patterns
- The deployment entry explicitly left owner-browser authentication as a manual check. This feedback exposed a first-navigation configuration issue, not a new analytics-delivery or credential-loss failure.
- No repeated process problem requiring a shared configuration change was identified.

## Scores
| Dimension | Score |
|-----------|-------|
| Friction | 0.3 |
| Repetition | 0.2 |
| Missing capability | 0.2 |
| Knowledge gap | 0.4 |
| Fragility | 0.5 |

## Suggestions
No significant improvement opportunities found.

## Changes Made
- No shared process, browser security settings or credential-storage configuration changed.

## Notes
- The active Access application used SameSite=Strict. A two-origin browser fixture reproduced the exact pattern: fresh cross-site sign-in looped, while direct navigation/refresh succeeded. SameSite=Lax completed with one callback. The first route-interception-only probe did not correctly model redirected requests; the useful feedback loop uses real loopback HTTP origins and dummy test-only cookies.
- Updated only the test application's cookie setting to Lax. Verified HttpOnly, binding cookie, one-hour session, audience, MFA and the existing owner-only policy identity/selectors remained intact. The provider updated policy metadata timestamps during its full application PUT; authorization semantics were checked separately rather than claiming byte-for-byte policy equality.
- Recorded the expected non-secret application settings in `worker/access_test_policy.json`; added two repeatable local browser tests for fresh SSO and the Strict/refresh failure pattern. These test cookie mechanics without handling real OAuth tokens, MFA factors or the owner's Safari cookies.
- Worker typecheck, handler/D1 tests and all seven browser tests passed. A real fresh Safari login after the configuration change remains a human verification step; the simulated browser test is not claimed as that verification.
- The second screenshot already showed working report JavaScript. Its plain styling is the existing minimal UI, not a failed stylesheet load. Local analytics was off with a pending deletion, so an empty report is consistent with the current state; no consent was enabled or data fabricated to populate it.
- Temporary authorization URLs in screenshots were treated as sensitive and were not copied into code or logs. No Safari scripting restriction was disabled, no sessions were globally revoked, and no consent/progress or collector write protections were changed.
