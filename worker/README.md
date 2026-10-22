# Slove Analytics Worker

First-party Cloudflare Worker + D1 for Slove's consent-gated analytics. It is a
narrow exception to the project's otherwise no-backend rule (see issue #60 and
`ARCHITECTURE.md`).

## Endpoints

### `POST /v1/events`

Accepts a bounded batch of schema-validated events:

```json
{
  "installationId": "optional-when-registering",
  "deletionSecret": "optional-once-for-registration",
  "events": [
    {
      "v": 1,
      "eventId": "...",
      "sessionId": "...",
      "installationId": "...",
      "gameId": "grammar",
      "contentVersion": "bundled",
      "itemId": null,
      "itemIndex": null,
      "timestampUtc": "2026-01-02T03:04:05.000Z",
      "kind": "round_started",
      "outcome": null,
      "reason": null
    }
  ]
}
```

- Payloads are capped at 256 KB and 100 events per batch.
- Events are deduplicated by `eventId` (`INSERT OR IGNORE`), so retries are
  idempotent.
- The optional `deletionSecret` is hashed (SHA-256) and stored per installation
  on first contact; it is never logged or returned.

### `POST /v1/delete`

```json
{ "installationId": "...", "deletionSecret": "..." }
```

Deletes the installation's linked event records when the deletion secret
matches the stored hash. The random `installationId` alone is not a credential.
Deletion is replay-safe: an unknown installation returns `404`, a wrong secret
returns `401`, and a successful deletion removes both events and the stored
secret hash.

## Retention

The scheduled handler runs daily and purges linked events older than 90 days.
Before deleting, it preserves only non-linkable aggregate day/week counts (per
game and event kind) with a minimum bucket size to avoid sparse identifying
cells. De-linked aggregates cannot be reversed by a later deletion request.

## Schema

`schema.sql` (also applied as `migrations/0001_initial.sql`) defines:

- `events` — linked event records (90-day retention).
- `installations` — SHA-256 deletion-secret hashes.
- `aggregates` — non-linkable day/week counts.

## Local development

```bash
npm install
npm run db:migrate   # applies migrations to the local D1
npm test             # vitest + @cloudflare/vitest-pool-workers
```

## Deployment (out of scope for this issue)

1. Create a D1 database and put its id in `wrangler.jsonc`.
2. `npx wrangler d1 migrations apply slove-analytics --remote`
3. `npx wrangler deploy`

Access-protect any future read/admin surface; the owner report UI is issue #62
and is intentionally out of scope here.

## Data minimization

Event bodies and deletion secrets are never written to application logs. The
ingestion handler logs only accepted/rejected counts through HTTP responses.
