# Slove Analytics Worker

First-party Worker + D1 for issues #60 and #61. Guardian opt-in is self-declared, default
off, per installation rather than per person. No accounts or vendor SDKs.
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
of subsequent durable client cleanup. There is no public read/report endpoint.

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

Owner reporting/private queries (#62), production deployment and store-console
changes remain out of scope.
