# Review: Closed production analytics preparation
**Date:** 2026-10-27
**Session:** Provisioned a separate production service and prepared 1.1.1 for internal distribution, without enabling collection (#66).

## History Checked
- `2026-10-27-simplify-analytics-retry.md`
- `2026-10-26-access-first-login-cookie.md`
- `2026-10-26-analytics-test-deployment.md`
- `2026-10-26-analytics-delete-availability.md`
- `2026-10-23-analytics-toggle-reenable.md`

## Recurring Patterns
- The previous deployment explicitly distinguished provisioning from collection and store approval. This round retains that distinction: the live public policy still says no game-usage collection.
- The user's simplification request is preserved: no development-instance guard, new Settings behavior, new dependency or deployment framework.

## Scores
| Dimension | Score |
|-----------|-------|
| Friction | 0.5 |
| Repetition | 0.3 |
| Missing capability | 0.1 |
| Knowledge gap | 0.5 |
| Fragility | 0.6 |

## Suggestions
No significant improvement opportunities found.

## Changes Made
- No shared process, permissions, browser security or global configuration changes.

## Notes
- User confirmed local test success, selected TestFlight/Play INTERNAL, and requested separate production infrastructure first. Public store submission was not selected.
- Created EU-jurisdiction `slove-analytics` D1, applied all six migrations, deployed `analytics.didactiv.ro` with PUBLIC_ENDPOINTS_ENABLED=false and daily 03:00 UTC cron. Verified zero event and identity rows; the first scheduled purge still needs observation.
- Separate owner-only Access app uses its own audience, MFA1h, Lax/HttpOnly/binding cookie and a Worker owner-allowlist secret. Unauthenticated private paths redirect to Access. workers.dev, version-prefix and alias probes return 404; alternate routing is disabled. Real owner-browser login is still a human check.
- The zone plan permits one rate-limit rule. Rather than purchasing more capacity or weakening protection, extended the existing rule to both exact analytics hostnames. Its 20 requests/10s/IP/edge-location budget is shared across hosts, not a global spending cap. Closed-gate bursts independently produced 429 on both routes. The test-only pilot restriction was not changed.
- Valid-event ingestion, authenticated deletion/revocation and deletion-registration abuse still require the controlled activation smoke; closed-route probes are not represented as those tests. Collection remains closed pending all activation gates.
- Prepared the production endpoint only in the staging workflow, with a required repository variable and pre-upload validation. Did not set that variable, merge staging or upload signed builds. Public-release workflow unchanged.
- Fixed the private report's misleading anonymous-installation label; the records remain pseudonymous. Updated operational instructions and the stale no-backend wording in release docs.
- Parent validation: no Flutter analysis issues, all 383 Flutter tests, 36 Worker/D1 tests, seven browser tests, workflow YAML/configuration checks, generated bindings and Worker deployment checks passed.
- Independent read-only reviewer approved closed provisioning but blocked activation until edge/bypass/abuse checks, published reviewed policy, store disclosures and privacy/child-policy approvals. Live canonical policy fetched during this round was still dated 23 September 2026 and denied game-usage collection; repository policy is only a proposed replacement until publication/review.
- A Python HTTPS probe lacked its local CA roots; subsequent probes used system curl with normal TLS verification, never disabled verification. Invalid preview hostname was replaced with documented version/alias URL formats. No secrets, MFA codes or authorization cookies were logged or committed.
- Existing unrelated `.pi/` modifications remain unstaged. No public release or legal-compliance certification is claimed.
