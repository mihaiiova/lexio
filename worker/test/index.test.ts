import { SELF, env } from 'cloudflare:test';
import { beforeAll, beforeEach, describe, expect, it } from 'vitest';

const DAY_MS = 24 * 60 * 60 * 1000;

const DDL = [
  `CREATE TABLE IF NOT EXISTS events (
    event_id TEXT PRIMARY KEY,
    session_id TEXT NOT NULL,
    installation_id TEXT NOT NULL,
    game_id TEXT NOT NULL,
    content_version TEXT NOT NULL,
    item_id TEXT,
    item_index INTEGER,
    timestamp_utc TEXT NOT NULL,
    kind TEXT NOT NULL,
    outcome TEXT,
    reason TEXT,
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
  )`,
  `CREATE INDEX IF NOT EXISTS idx_events_installation ON events(installation_id, created_at)`,
  `CREATE INDEX IF NOT EXISTS idx_events_timestamp ON events(timestamp_utc)`,
  `CREATE TABLE IF NOT EXISTS installations (
    installation_id TEXT PRIMARY KEY,
    deletion_secret_hash TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
  )`,
  `CREATE TABLE IF NOT EXISTS aggregates (
    bucket TEXT NOT NULL,
    game_id TEXT NOT NULL,
    kind TEXT NOT NULL,
    count INTEGER NOT NULL,
    PRIMARY KEY (bucket, game_id, kind)
  )`,
];

let eventCounter = 0;

function makeEvent(overrides: Record<string, unknown> = {}): Record<string, unknown> {
  eventCounter += 1;
  return {
    v: 1,
    eventId: `ev_${eventCounter}`,
    sessionId: 's_1',
    installationId: 'inst_1',
    gameId: 'grammar',
    contentVersion: 'bundled',
    itemId: null,
    itemIndex: null,
    timestampUtc: new Date().toISOString(),
    kind: 'round_started',
    outcome: null,
    reason: null,
    ...overrides,
  };
}

function postEvents(body: unknown): Promise<Response> {
  return SELF.fetch('https://example.com/v1/events', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(body),
  });
}

beforeAll(async () => {
  for (const sql of DDL) {
    await env.DB.prepare(sql).run();
  }
});

beforeEach(async () => {
  await env.DB.prepare('DELETE FROM events').run();
  await env.DB.prepare('DELETE FROM installations').run();
  await env.DB.prepare('DELETE FROM aggregates').run();
});

describe('POST /v1/events', () => {
  it('rejects malformed JSON', async () => {
    const response = await SELF.fetch('https://example.com/v1/events', {
      method: 'POST',
      body: 'not-json',
    });
    expect(response.status).toBe(400);
  });

  it('rejects an oversized payload', async () => {
    const response = await postEvents({
      events: [makeEvent(), { ...makeEvent(), eventId: `big_${'x'.repeat(300 * 1024)}` }],
    });
    expect(response.status).toBe(413);
  });

  it('rejects a batch with too many events', async () => {
    const events = Array.from({ length: 101 }, () => makeEvent());
    const response = await postEvents({ events });
    expect(response.status).toBe(413);
  });

  it('rejects a schema-invalid event', async () => {
    const response = await postEvents({
      events: [makeEvent({ kind: 'round_started', itemId: 'n1' })],
    });
    expect(response.status).toBe(400);
  });

  it('accepts valid events and deduplicates by event id', async () => {
    const event = makeEvent();
    const first = await postEvents({ events: [event] });
    expect(first.status).toBe(202);

    const second = await postEvents({ events: [event] });
    expect(second.status).toBe(202);

    const count = await env.DB.prepare(
      'SELECT COUNT(*) AS count FROM events WHERE event_id = ?',
    )
      .bind(event.eventId)
      .first();
    expect(Number(count?.count ?? 0)).toBe(1);
  });
});

describe('POST /v1/delete', () => {
  async function registerInstallation(secret: string): Promise<void> {
    const response = await postEvents({
      installationId: 'inst_delete',
      deletionSecret: secret,
      events: [makeEvent({ installationId: 'inst_delete' })],
    });
    expect(response.status).toBe(202);
  }

  it('authorizes deletion only with the matching secret', async () => {
    await registerInstallation('correct-secret');

    const wrong = await SELF.fetch('https://example.com/v1/delete', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        installationId: 'inst_delete',
        deletionSecret: 'wrong-secret',
      }),
    });
    expect(wrong.status).toBe(401);

    const correct = await SELF.fetch('https://example.com/v1/delete', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        installationId: 'inst_delete',
        deletionSecret: 'correct-secret',
      }),
    });
    expect(correct.status).toBe(200);

    const count = await env.DB.prepare(
      'SELECT COUNT(*) AS count FROM events WHERE installation_id = ?',
    )
      .bind('inst_delete')
      .first();
    expect(Number(count?.count ?? 0)).toBe(0);

    // Replay is harmless: the installation no longer exists.
    const replay = await SELF.fetch('https://example.com/v1/delete', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        installationId: 'inst_delete',
        deletionSecret: 'correct-secret',
      }),
    });
    expect(replay.status).toBe(404);
  });
});

describe('scheduled purge', () => {
  async function insertEvent(
    eventId: string,
    timestampUtc: string,
    kind = 'item_shown',
    gameId = 'grammar',
  ): Promise<void> {
    await env.DB.prepare(
      `INSERT INTO events
        (event_id, session_id, installation_id, game_id, content_version,
         item_id, item_index, timestamp_utc, kind, outcome, reason)
       VALUES (?, 's', 'inst_purge', ?, 'bundled', 'n1', 0, ?, ?, null, null)`,
    )
      .bind(eventId, gameId, timestampUtc, kind)
      .run();
  }

  it('purges old linked events into non-linkable aggregates', async () => {
    const oldDay = new Date(Date.now() - 100 * DAY_MS).toISOString().slice(0, 10);
    for (let i = 0; i < 6; i++) {
      await insertEvent(`old_${i}`, `${oldDay}T00:00:00.000Z`);
    }
    await insertEvent('recent', new Date().toISOString());

    const scheduledEvent = {
      cron: '0 3 * * *',
      scheduledTime: Date.now(),
      type: 'scheduled',
    };
    const scheduledHandler = SELF as unknown as {
      scheduled: (event: typeof scheduledEvent) => Promise<void>;
    };
    await scheduledHandler.scheduled(scheduledEvent);

    const oldCount = await env.DB.prepare(
      'SELECT COUNT(*) AS count FROM events WHERE event_id LIKE ?',
    )
      .bind('old_%')
      .first();
    expect(Number(oldCount?.count ?? 0)).toBe(0);

    const recent = await env.DB.prepare(
      'SELECT COUNT(*) AS count FROM events WHERE event_id = ?',
    )
      .bind('recent')
      .first();
    expect(Number(recent?.count ?? 0)).toBe(1);

    const aggregate = await env.DB.prepare(
      'SELECT count FROM aggregates WHERE bucket = ? AND game_id = ? AND kind = ?',
    )
      .bind(`day:${oldDay}`, 'grammar', 'item_shown')
      .first();
    expect(Number(aggregate?.count ?? 0)).toBe(6);
  });
});
