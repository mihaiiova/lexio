# Slove Analytics Worker

First-party Worker + D1 for issue #60. Guardian opt-in is self-declared, default
off, per installation rather than per person. No accounts or vendor SDKs.
Installation-linked data is **pseudonymous**, not irreversibly anonymous.

## Contract (unreleased schema v1)

`POST /v1/events` accepts exactly `{ "deletionSecret": "...", "events": [...] }`.
Every batch requires one installation and its matching secret; first contact
registers the credential. Secrets are 32–128 base64url characters (the client
uses 43 random characters); only SHA-256 hashes are stored. Unknown envelope
and event fields are rejected. No exercise text or raw answers are accepted.

Events contain `v`, random `eventId`, `sessionId`, `installationId`, `gameId`
(currently only `grammar`), bounded `contentVersion`, `itemId`, `itemIndex`
(0–10000), `timestampUtc`, `kind`, `outcome`, `reason`, `itemState`.
Nullable fields are sent as null by the client. Kinds are `round_started`,
`item_shown`, `item_answered`, `item_resolved`, `round_ended`. Outcomes are
`correct`/`wrong`; end reasons are `completed`, `user_back`, `restart`,
`inferred_interruption`. Termination is inferred at next launch, not observed.
A terminal shown item has state `resolved`/`unresolved`; an unanswered item is
not wrong. Grammar item IDs identify rendered exercise variants, not notions.

UTC timestamps must be canonical `YYYY-MM-DDTHH:mm:ss.sss[sss]Z`, no older than
90 days and no more than 5 minutes ahead of receipt. Bad device clocks therefore
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
of subsequent durable client cleanup. There is no public read/report endpoint.

## Retention and deletion limits

Daily scheduled purge removes linked events after the earlier of event time or
server receipt time plus 90 days (daily scheduling can add up to one day; monitor
cron failures). Future client dates cannot extend receipt-based retention.
Inactive identity credential rows expire after 90 days without ingestion, once
no linked events remain. Revocation records (installation ID + credential hash
and dates) remain for **91 days from first deletion**, without refresh on retry,
then expire. This bounded anti-replay exception is not an indefinite registry.
Original event replays are then too old to ingest. Deliberately forged fresh
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
single-installation threshold. Aggregates have no public query surface; future
report design (#62) must review differencing across overlapping cells.

## Checks

```bash
npm ci
npm run check       # tsc --noEmit + Worker/D1 handler tests
npm run db:migrate  # local D1 only
```

Tests apply the actual migrations. `schema.sql` is a one-time fresh bootstrap
mirror of those migrations, not an idempotent reapplication script. CI runs the
Worker check independently of Flutter checks. No dependencies were added.

## Closed deployment gate — no deployment authorized

`PUBLIC_ENDPOINTS_ENABLED` defaults to `false`; both public POST routes return
503 until explicitly enabled. **Do not enable it or deploy from this task.**
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
is not proof of lawful consent. None of these manual sign-offs happened here.

References retrieved during implementation:
- https://developers.cloudflare.com/d1/worker-api/d1-database/ (batch transactions)
- https://developers.cloudflare.com/workers/runtime-apis/bindings/rate-limit/ (per-location limits)
- https://developers.cloudflare.com/workers/best-practices/workers-best-practices/

Other games (#61), owner reporting (#62), production deployment and store-console
changes remain out of scope.
