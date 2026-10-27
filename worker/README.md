# Slove Analytics Worker

First-party Worker + D1 for issues #60, #61 and #62. Guardian opt-in is self-declared, default
off, per installation rather than per person. No player accounts or vendor SDKs; the
only authenticated reader is the owner, through Cloudflare Access (see below).
Installation-linked data is **pseudonymous**, not irreversibly anonymous.

## Contract (unreleased schema v1)

`POST /v1/events` accepts exactly `{ "deletionSecret": "...", "events": [...] }`.
Every batch requires one installation and its matching secret; first contact
registers the credential. Secrets are 32–128 base64url characters (the client
uses 43 random characters); only SHA-256 hashes are stored. Unknown envelope
and event fields are rejected. No exercise text or raw answers are accepted.

Events contain `v`, random `eventId`, `sessionId`, `installationId`, `gameId`
(`grammar`, `vocabulary`, `idioms`, `spot` only), bounded `contentVersion`, `itemId`, `itemIndex`
(0–10000), `timestampUtc`, `kind`, `outcome`, `reason`, `itemState`.
Nullable fields are sent as null by the client. Kinds are `round_started`,
`item_shown`, `item_answered`, `item_resolved`, `round_ended`, `spot_attempt`. Outcomes are
`correct`/`wrong`; end reasons are `completed`, `user_back`, `restart`,
`inferred_interruption`, and Spot-only `timeout`. Termination is inferred at next launch, not observed.
A terminal shown item has state `resolved`/`unresolved`; an unanswered item is
not wrong. All item IDs identify rendered exercise variants/texts, not shared learning notions.

### Units and Spot count deltas

Grammar, Vocabulary and Idioms use one rendered MC exercise as their shown unit;
its first committed answer emits `item_answered` (correct/wrong) and
`item_resolved`. Spot uses a **text**, not a press, as its shown/resolved unit.
`item_resolved` is emitted only when every mistake in that text has been found;
revealing corrections does not resolve a text. Unresolved is not wrong. Terminal
state retains the last rendered item; earlier unresolved texts are shown texts
without a resolution. Background is not an end; startup recovery infers an
interruption using activity-bounded time. Each replay has a fresh session.

Only `spot_attempt` accepts three additional integer fields:
- `attemptDelta`: exactly 1 for each in-play word press, including repeats;
- `correctDiscoveryDelta`: 0 or 1, newly found mistakes only;
- `distinctWrongDelta`: 0 or 1, the first wrong press at that text/position in
  this round. The same position in a different text is a different local key.

The last two deltas cannot both be 1. A repeated found-token press during an
unresolved text has both deltas 0. Resolution does not itself lock legacy
wrong-word input: accepted wrong presses while that resolved text is still shown
continue to increment attempts and first-position distinct wrong, without undoing
resolution or emitting another resolution. Found-token repeat observation is not
newly enabled after resolution. No input is counted while checking/revealing,
after timeout, after text replacement, on the summary, or after exiting. The client preserves its
existing scoring/accuracy sets. Word text, raw selected positions/answers and
arbitrary fields are rejected. `itemIndex` is the text's round index, never the
pressed word's position. Deltas require a Spot exercise ID/index and no outcome
or reason. Spot `item_answered` is rejected: discoveries are not MC answers.
Non-attempt events omit the deltas (null is also accepted for compatibility).
MC answer totals must not be combined with Spot discovery/distinct-wrong totals.

Client lifecycle, device-only distinct-position sets, queued deltas, and any
resolution from that interaction share one atomic durable snapshot. Retries keep
the same stable event IDs; the D1 primary key prevents double counting. Migration
0005 adds nullable event delta columns and nullable aggregate counters:
`attempts`, `correct_discoveries`, `distinct_wrong_positions`. Purging sums each
counter alongside event `count`, in the same transaction as removal. Each whole
cell still requires at least **five distinct installations**, regardless of how
many attempts one installation sends. Additionally, each retained counter requires
at least **five distinct positive-delta contributing installations for that specific
counter** in the same bucket/dimensions. Six installations with six attempts,
two discoveries and four distinct wrong positions retain attempts=6 but both
numerators are **null (suppressed), not measured zero**. Repeated positive events
from one installation do not qualify. Null propagates through additive upserts:
once any retained contribution is suppressed, later purges cannot turn that
incomplete numerator into an exact sum. MC counters are null/not applicable.
Future #62 queries/rollups must preserve null/suppression, never coalesce it to
zero or recover small cohorts by differencing; retained counts can undercount
across discarded sparse purge cells and are not necessarily full population totals. Item and overall cells retain separate
game/unit dimensions. No local position sets enter ingestion or retained totals.

UTC timestamps must be canonical `YYYY-MM-DDTHH:mm:ss.sss[sss]Z`; validation
and storage normalize to milliseconds. A single server-time snapshot per batch
requires timestamps strictly newer than the 90-day horizon and not in the future.
Bad device clocks therefore
lose delivery rather than widening retention. Bodies are streamed and cancelled
above **60000 actual UTF-8 bytes**, with at most 100 events. Registration and
conditional event inserts are transactional; wrong secrets cannot append data,
and revocation cannot race into re-registration. `eventId` deduplication preserves
the first accepted event, including terminal replays with a different reason.
Success is 202; malformed input 400, oversize 413, wrong secret 401, revoked 410.
The client treats non-2xx as delivery failure and keeps its bounded retry queue.

`POST /v1/delete` accepts exactly `{ "installationId": "...", "deletionSecret":
"..." }`. Matching deletion atomically revokes registration and removes linked
events. Legitimate retries and never-registered identities return **200**;
wrong credentials return 401. A never-registered deletion reserves that random
identity with the presented credential. Deletion acknowledgment is independent
of subsequent durable client cleanup. There is no public read/report endpoint;
the owner-only report is described below.

## Retention and deletion limits

Daily scheduled purge removes linked events after the earlier of event time or
server receipt time plus 90 days (daily scheduling can add up to one day; monitor
cron failures). Events at the horizon expire; future client dates are rejected.
Inactive identity credential rows expire after 90 days without ingestion, once
no linked events remain. Revocation records (installation ID + credential hash
and dates) expire at **90 days from first deletion**, without refresh on retry,
using the same daily purge cadence. There is no extra credential-retention day
or indefinite inactive identity registry. With strict no-future acceptance and
exclusive ingestion horizon, original event replays are already stale at
tombstone expiry (including the exact boundary). Deliberately forged fresh
events reusing an expired identity cannot be distinguished from a new registration;
this protocol is not authentication of a person or proof of guardian consent.

Aggregation and removal use one D1 transactional batch: failed/concurrent purges
do not double count. Day/week overall counts retain kind, outcome, end reason,
and terminal resolution; item counts additionally retain static content revision,
exercise ID and position. Each emitted cell requires **at least five distinct
installations**, not five events. No event/session/installation IDs or credential
hashes enter aggregates. Sparse cells are discarded, not held indefinitely;
counts are privacy-suppressed and may undercount across purge boundaries.
Deletion removes still-linked events, not previously unlinked aggregate totals.
Migration 0004 discards earlier unreleased aggregates that used an unsafe
single-installation threshold. Aggregates have no public query surface. The
same purge batch also advances the singleton `purge_marker.cutoff` (migration
0006); a failed or rolled-back purge leaves it unchanged.

## Private owner report (#62)

Every `/private` and `/private/*` request (page, script, API and unknown paths)
is verified before any database access. The Worker requires the
`Cf-Access-Jwt-Assertion` header, verifies its RS256 signature against
`<ACCESS_ISSUER>/cdn-cgi/access/certs` (public keys only, cached at most 5
minutes), and checks issuer, audience, `exp` and an `email` on the owner
allowlist. Missing/invalid configuration, claims, algorithms, keys or JWKS
fetches all return 403. All responses are `private, no-store` with a strict
CSP, `nosniff` and `no-referrer`; the page renders text only (no `innerHTML`).

| Route (GET only) | Content |
|---|---|
| `/private/report/` | Romanian report page |
| `/private/report/app.js` | Its script |
| `/private/report/api/recent` | Linked recent sessions |
| `/private/report/api/history` | Fixed unlinked weekly history |

Owner verification fields (actual non-secret values are in `wrangler.jsonc`;
the isolated test profile is separate in `wrangler_test.jsonc`):

```jsonc
"vars": {
  "ACCESS_ISSUER": "https://<team-name>.cloudflareaccess.com", // https, *.cloudflareaccess.com only
  "ACCESS_AUDIENCE": "<Access application AUD tag>"            // 1–256 characters
}
```

Set `ACCESS_OWNER_EMAILS` as a Worker secret (`wrangler secret put
ACCESS_OWNER_EMAILS --config wrangler.jsonc`), never in committed vars. It is a
comma-separated owner allowlist with at most ten entries.

**Recent** accepts only `from`/`to` (`YYYY-MM-DD`, UTC, `from` inclusive, `to`
exclusive), `game` (four game IDs), `version` (≤64), `installation` (≤128),
`limit` (1–25, default 25) and an opaque `cursor`; each at most once, query ≤2048
characters, anything else is 400. Default window: the 7 UTC days ending at the
start of tomorrow. Windows are at most 31 days, cannot start before the UTC day of
the 90-day horizon or end after tomorrow, and rows outside the logical 90-day
horizon (event or receipt time) are excluded even before the purge runs. More
than 5000 matching events, 500 distinct item/version groups, 500 distinct ending
position/reason groups, or a body over 256000 bytes returns 422 (narrow the
filters). Deleted installations disappear immediately. Credential rows are never
read.

Per session the report shows status, missing start, and `lastItem`/`lastIndex`
with `lastItemEvidence`: `terminal` comes from the `round_ended` item; otherwise
`observed` is the highest observed round index in the window (ties by item ID).
Event order at equal timestamps is not used. Per-game `summary.byItem` combines
item counts across all matching sessions and installations by content version and
exercise ID (not round position). `summary.endedAt` groups round endings by
version, terminal item ID/index and reason; a missing terminal item is explicitly
unknown, never guessed from the highest observed index. These summaries cover
the full filtered window, independently of the 25-row session page, and are also
scoped by the installation filter when present. They have no raw text or selected
positions and are available only to the authenticated owner.

For example, two opted-in installations that both answer exercise `g1`, version
`v1`, once correctly and once incorrectly produce one item row with `shown: 2`,
`resolved: 2`, `correct: 1`, `wrong: 1`. If their rounds end at indexes 0 and 2,
there are two ending-position rows with count 1 each. Changing the session page
does not change these totals; filtering to one installation restricts them.

`left` counts items departed without
resolution, proven by a higher shown index, the round end, or a terminal
`unresolved` state (even when the item was shown before the window, without
adding a shown count). The current item with no later evidence is
`openUnresolved` (unknown), not left. Unresolved is never wrong.

**History** accepts no parameters. It publishes nothing until a scheduled purge
has committed a `purge_marker`. Then it lists the 52 `week:%Y-W%W` buckets that
end before the UTC day preceding that cutoff (an extra conservative publication
buffer). Conditional event inserts check the committed cutoff inside the same D1
transaction as registration/ingestion, so even a request validated before a purge
cannot append timestamps at or before its publication boundary afterward. Events
that expire during a delayed request are acknowledged but not retained. Later
cron runs cannot change a published week. Only overall cells are summed per week
and game; day, item, version and installation cells are never exposed. Every value
is partial; suppressed counters remain null.

## Operations

- **Access:** create a self-hosted Access application covering the Worker
  hostname with path `/private` and `/private/*`. Use an Allow policy limited to
  the owner identities plus MFA, a short session duration, and no service-token
  or bypass policy. Keep `ACCESS_OWNER_EMAILS` in sync with it; the Worker
  re-checks the allowlist as a second barrier. Block or disable the
  `workers.dev` route so the report is reachable only behind Access.
- **Rotation:** Access rotates its signing keys; the Worker refetches the JWKS
  after at most 5 minutes or on an unknown `kid` when its 30-second refetch cooldown
  permits; otherwise the request is denied. Rotating the Access application
  (new AUD tag) requires updating `ACCESS_AUDIENCE` in the same change. To revoke
  an owner, remove them from the Access policy and the allowlist and revoke their
  active Access sessions. No token, cookie or owner identity is stored.
- **Retention jobs:** the daily `0 3 * * *` cron purges and aggregates. Monitor
  it with Workers cron/trigger logs or alerts. A stale `purge_marker.cutoff`
  (more than about two days behind `now - 90 days`) means purges are failing:
  linked data is being kept too long and history stops advancing.
- **Rollback:** redeploy the previous Worker version. Migration 0006 is
  additive. Earlier code ignores `purge_marker`; do not drop it while this code
  can still be deployed. Removing the Access vars closes the report (403).

## Checks

```bash
npm ci
npx playwright install chromium   # once; CI uses --with-deps
npm run check       # tsc --noEmit + Worker/D1 handler tests + Chromium report UI tests
npm run db:migrate  # local D1 only
```

Tests apply the actual migrations and verify real RS256 tokens against a mocked
JWKS, without bypassing verification. The UI suite serves the real page/script
from an isolated local fixture host with mocked API responses. `schema.sql` is a
one-time fresh bootstrap mirror of those migrations, not an idempotent
reapplication script. CI runs the Worker check independently of Flutter checks.

Dependencies: `jose` (pinned 6.1.3) for standards-compliant JWT/JWKS verification
instead of hand-written crypto. `@playwright/test` (pinned 1.58.2, dev only)
runs the browser tests.

## Production collection gate

`PUBLIC_ENDPOINTS_ENABLED` defaults to `false` in `wrangler.jsonc`; both public
POST routes return 503 until explicitly enabled. **Do not enable production
collection without the release approvals below.** The separately scoped
`wrangler_test.jsonc` profile is for adult/synthetic local testing only.
The in-isolate IP Map is only a local backstop, not distributed/global rate
limiting; it resets across isolates. Before enabling, the operator must configure
and independently test Cloudflare edge rate-limit/WAF rules covering BOTH routes,
including the workers.dev/custom-domain bypass paths, burst abuse and deletion
registration abuse. If a suitable plan/rule cannot be provisioned, keep the gate
closed and design an approved durable limiter. Do not claim global enforcement
from the Map or from Cloudflare's per-location Rate Limiting binding alone.

Release additionally requires actual D1 provisioning/migration review, cron
monitoring, restricted Cloudflare/D1 administrative access, HTTPS endpoint
configuration, body/secret/IP logging review (no application event-body logging),
manual first-run/offline/deletion tests, child-privacy/legal and store-policy
sign-off, and publication of the reviewed canonical policy at
https://didactiv.ro/confidentialitate/slove/ before store submission. A reachable
URL is not proof that the revised policy is published or approved. Guardian UI
is not proof of lawful consent. Provisioning the isolated test environment does
not constitute child-privacy, legal or store-policy approval.

References retrieved during implementation:
- https://developers.cloudflare.com/d1/worker-api/d1-database/ (batch transactions)
- https://developers.cloudflare.com/workers/runtime-apis/bindings/rate-limit/ (per-location limits)
- https://developers.cloudflare.com/workers/best-practices/workers-best-practices/

Report pre-release checklist (repeat for each rollout): provision the Access
application and policy; confirm unauthenticated, non-owner and expired-session
requests to every `/private` path are denied at the edge and by the Worker;
log in as the owner and check the page, filters, drilldown and history against
known local data; verify responses are not cached; review that the privacy
policy and store data-safety answers describe owner access to installation-linked
records. Public store submission and store-console approvals are separate from provisioning
a closed production service and preparing internal builds.

Additional reference: https://developers.cloudflare.com/cloudflare-one/identity/authorization-cookie/validating-json/
(Access JWT validation).

## Isolated analytics test environment (#65)

The test collector is `https://analytics-test.didactiv.ro`. Its D1 database is
restricted to the EU. The default production configuration and store build
workflows remain separate; they do not enable this endpoint automatically.

Run the macOS app explicitly against this collector from the repository root:

```bash
bash scripts/run_macos_analytics_test.sh
# Equivalent:
flutter run -d macos --dart-define-from-file=config/analytics_test.json
```

Stop an older Flutter run before starting one with different Dart defines;
hot reload or hot restart does not change the build's endpoint. Existing consent
and pending deletion credentials remain in place. Do not reset them to test
server deletion: the configured server can acknowledge a pending request, even
if that identity never uploaded events.

The owner report is at `https://analytics-test.didactiv.ro/private/report/`.
Cloudflare Access limits it to the owner and requires independent MFA, with a
one-hour session. The expected application settings are recorded in
`access_test_policy.json`. Its authorization cookie uses `SameSite=Lax`, allowing
top-level GET redirects back from the separate Access identity domain; `Strict`
can loop on first login even when a direct refresh succeeds. HttpOnly, the
binding cookie, MFA and the Worker JWT checks remain enabled. When applying this
partial policy through the Access API, merge it into the current application
configuration; never replace or clear the owner policy or submit `application_id`
as an application-body field. Verify policy identity, owner selectors, audience
and MFA are unchanged afterward.

The Worker independently verifies the JWT issuer, signature,
audience, expiry and owner allowlist. The owner email is an encrypted Worker
secret, not a player credential or an app setting. First login may require MFA
enrollment through `https://iova.cloudflareaccess.com/AddMfaDevice`. Enter login
codes and register authenticators in the browser, never in chat or source files.

Test writes are restricted at the edge to the developer's configured IPv4 egress
and IPv6 test network. Those addresses are managed privately, not committed.
Changing networks or IPv6 prefixes can return 403 until the pilot rule is
updated. Never remove the pilot restriction merely to resolve a failed request.
An edge rule covers both `/v1/events` and `/v1/delete`: 20 requests per 10 seconds
per IP **and edge location**, with a 10-second mitigation. This is not a strict
worldwide counter or an aggregate spending cap. The isolate-local Map remains
only a backstop. Both `workers.dev` and preview routing are disabled, and
application/request-body logging is disabled.

Use the pinned operational CLI without upgrading the project's existing test
stack implicitly:

```bash
cd worker
npm exec --yes --package=wrangler@4.152.0 -- wrangler deploy --config wrangler_test.jsonc --dry-run
npm exec --yes --package=wrangler@4.152.0 -- wrangler d1 migrations list DB --config wrangler_test.jsonc --remote
```

To stop test ingestion, change only this profile's `PUBLIC_ENDPOINTS_ENABLED`
to `"false"` and redeploy with the same explicit config. Keep Access, WAF and
bypass restrictions in place during rollback. Do not point this profile at a
production database or deploy the test flag with the production config.

Before enabling a new test collector, independently check both edge POST routes,
a non-pilot source, every private entry path, and disabled bypass hosts. Verify
the real app transport can ingest all four games, deduplicate retries, reject
wrong deletion credentials, acknowledge deletion (including never-registered
identities), reject revoked identities, and leave no linked synthetic events.
Owner/MFA browser smoke testing and monitoring the next scheduled retention run
are separate operational checks; configuration alone does not prove them.

## Production profile and internal rollout (#66)

`wrangler.jsonc` targets the separate EU-jurisdiction database `slove-analytics`
and `https://analytics.didactiv.ro`; the owner report is at
`https://analytics.didactiv.ro/private/report/`. Its Access application is
`72565362-6b24-457b-9fda-62153ecf99bc`, with a distinct audience, the same owner-only
selectors, MFA/one-hour sessions, HttpOnly/binding cookie and SameSite=Lax. Keep
the owner allowlist in a Worker secret. Alternate workers.dev/version URLs and
body logging remain disabled.

Keep `PUBLIC_ENDPOINTS_ENABLED` false until the production collection gate above
is satisfied. Closed-route HTTP 503 and Access redirects establish protection,
not successful ingestion or legal/store approval. Repeat the real transport,
deletion/revocation, abuse and owner-browser tests before rollout. Check the
first scheduled purge and monitor `purge_marker` using the query below; do not
claim that setting a cron proves a successful run.

The zone plan permits one edge rate-limit rule. The existing rule therefore
covers **both** analytics hostnames and both write paths with one shared
20-request/10-second budget per IP and edge location, followed by a 10-second
mitigation. It is neither per-host nor a global/spending cap. The test-only pilot
network restriction is unchanged; do not remove it to enable production.

After the activation checks, set repository variable `ANALYTICS_ENDPOINT` to the
production URL. Only `deploy-staging.yml` uses it for the TestFlight/Play internal
rollout. The public-store workflow is deliberately unchanged. The local macOS
helper continues to use the isolated **test** collector and test report.

```bash
cd worker
npm exec --yes --package=wrangler@4.152.0 -- wrangler deploy --config wrangler.jsonc --dry-run
npm exec --yes --package=wrangler@4.152.0 -- wrangler d1 migrations list DB --config wrangler.jsonc --remote
npm exec --yes --package=wrangler@4.152.0 -- wrangler d1 execute DB --config wrangler.jsonc --remote --command 'SELECT cutoff FROM purge_marker;'
```

If the reviewed policy is not published or store/child-privacy approval is still
pending, leave collection closed and do not merge an endpoint-enabled internal
release. Staging validation rejects a missing or incorrect endpoint before any
signed upload.
