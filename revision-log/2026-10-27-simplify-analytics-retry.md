# Review: Simplify local analytics recovery
**Date:** 2026-10-27
**Session:** Retried an existing deletion at normal lifecycle flush points and restarted a single configured macOS client (#65).

## History Checked
- `2026-10-26-access-first-login-cookie.md`
- `2026-10-26-analytics-test-deployment.md`
- `2026-10-26-analytics-delete-availability.md`
- `2026-10-23-analytics-toggle-reenable.md`
- `2026-10-23-friendly-analytics-consent.md`

## Recurring Patterns
- Earlier entries distinguish missing configuration, collection off and pending deletion. Re-checking the actual running client's state remains more useful than repeating generic retry instructions.
- No previous entry establishes a recurring need for multi-instance development protection. Adding it for this incident was unjustified.

## Scores
| Dimension | Score |
|-----------|-------|
| Friction | 0.8 |
| Repetition | 0.6 |
| Missing capability | 0.1 |
| Knowledge gap | 0.3 |
| Fragility | 0.4 |

## Suggestions
| # | Category | Suggestion | Score | Accepted? |
|---|----------|------------|-------|-----------|
| 1 | other | Resolve transient development-process state by closing/restarting the app, not by introducing persistent instance guards and extra Settings behavior. | 0.8 | Yes: explicitly requested by the user. |

## Changes Made
- Removed the proposed launcher process guard and its new shell test; restored the original simple launcher.
- Removed the proposed Settings initialization behavior and related UI/privacy/documentation changes.
- Retained only the repository's bounded pending-deletion retry through existing startup/resume flush points, with an in-flight request shared by concurrent callers and regressions for credential retention, ordinary opt-out and no automatic opt-in.

## Notes
- Invalid empty request bodies received HTTP 400 on both test routes, distinguishing reachable schema validation from network rejection without uploading metrics or credentials.
- Regressions first failed for missing retry and concurrent duplicate deletion requests. Static analysis and all 383 Flutter tests passed after the minimal repository change.
- Following permission to restart, verified the older apps were closed and launched one macOS instance with the explicit test configuration. The real pending deletion was acknowledged: persisted pending=false and identity cleared. Analytics remained off, as required; collecting a subsequent game still requires the user's explicit opt-in.
- No consent reset, fabricated report metrics, production activation, push or release. Existing unrelated `.pi/` changes remain untouched.
