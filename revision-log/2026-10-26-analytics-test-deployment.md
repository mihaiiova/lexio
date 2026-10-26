# Review: Isolated analytics test deployment
**Date:** 2026-10-26
**Session:** Provisioned and connected the first-party analytics test collector, protected owner report and macOS test build (#65).

## History Checked
- `2026-10-26-analytics-delete-availability.md`
- `2026-10-23-analytics-toggle-reenable.md`
- `2026-10-23-friendly-analytics-consent.md`
- `2026-10-23-private-analytics-report.md`
- `2026-10-24-analytics-all-games.md`

## Recurring Patterns
- Missing collector configuration from the preceding consent rounds is now addressed by a separate deployed test profile, not another local consent reset.
- No prior entry documents the current Cloudflare OAuth/browser permission problem. Do not conflate it with the older external-reviewer tool-access limitation.
- Explicit file staging continues to preserve the existing user-owned `.pi/` changes.

## Scores
| Dimension | Score |
|-----------|-------|
| Friction | 0.8 |
| Repetition | 0.5 |
| Missing capability | 0.2 |
| Knowledge gap | 0.5 |
| Fragility | 0.6 |

## Suggestions
| # | Category | Suggestion | Score | Accepted? |
|---|----------|------------|-------|-----------|
| 1 | mcps | Use the official project-local Cloudflare MCP with explicit OAuth scopes for multi-service administration rather than defaulting to manual tokens or unsupported browser automation. Current signal: Wrangler lacked Access/WAF authority, Safari blocked scripting, and the first MCP login had identity-only scopes. | 0.8 | Accepted: the user explicitly requested project MCP configuration and completed scoped OAuth. |

## Changes Made
- Added the official Cloudflare API server to `.mcp.json`, preserved the Dart server, requested only the operational scope categories needed here, and kept credentials in the adapter's secure store rather than source files.
- No global Pi skills, permissions, model configuration or shared package pins were changed.

## Notes
- User explicitly authorized deployment; created only a separate test Worker and EU-jurisdiction D1 database, applying six reviewed migrations. Default production configuration and store workflows remain unchanged and closed.
- Access allows only the owner, with one-hour sessions and independent MFA. Enabling the organization MFA capability did not change its other existing settings or enforce MFA globally. Echoing disabled `service_token_inactivity` with null action/duration caused a provider validation error; omitting that disabled/null object allowed the documented update, and other organization fields were checked unchanged.
- Edge protection applies only to the test hostname. The pilot network allowlist is maintained privately; the shared write-route limiter counts per IP and edge location, not globally worldwide. No raw request-body logging was enabled.
- A burst while the Worker gate was still closed produced 429 on both routes, proving enforcement outside the in-isolate Map. A separately deployed Cloudflare-network probe received 403 on both routes and was then deleted. Direct workers.dev probes returned 404; both workers.dev and custom-domain preview routing were checked disabled.
- The real app HTTP transport ingested 20 synthetic events across all four games. Replaying them kept 20 unique stored rows. Wrong-key deletion returned 401; correct deletion and retries succeeded; revoked ingestion returned 410; never-registered deletion was idempotent. D1 then contained zero linked synthetic events and two revocation records retained under the existing policy.
- Built and opened the macOS debug app with the explicit test endpoint, without resetting consent, credentials or progress. Opened the owner report in Safari. Actual owner/MFA browser login is a human check, not claimed as completed; monitoring the next scheduled purge is also outstanding.
- Parent verification passed Flutter analysis, all Flutter tests, Worker/D1/browser tests, shell syntax validation and macOS compilation. Generated test-profile binding types into ignored artifacts. No store upload, production collection or child-privacy/legal sign-off occurred.
