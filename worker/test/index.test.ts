import worker from '../src/index';
import { SELF, env, applyD1Migrations } from 'cloudflare:test';
import { beforeAll, beforeEach, describe, expect, it, vi } from 'vitest';

const DAY_MS = 24 * 60 * 60 * 1000;

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
    body: JSON.stringify(typeof body === 'object' && body !== null ? {deletionSecret: 'a'.repeat(64), ...body} : body),
  });
}

beforeAll(async () => {
  await applyD1Migrations(env.DB, env.TEST_MIGRATIONS);
});

beforeEach(async () => {
  await env.DB.prepare('DELETE FROM events').run();
  await env.DB.prepare('DELETE FROM installations').run();
  await env.DB.prepare('DELETE FROM aggregates').run();
});

describe('POST /v1/events', () => {
  it('requires credentials and rejects mixed installations and tampered secrets', async () => {
    expect((await postEvents({deletionSecret: undefined, events: [makeEvent()]})).status).toBe(400);
    const deletionSecret = 'a'.repeat(64);
    expect((await postEvents({deletionSecret, events: [makeEvent()]})).status).toBe(202);
    expect((await postEvents({deletionSecret: 'b'.repeat(64), events: [makeEvent()]})).status).toBe(401);
    expect((await postEvents({deletionSecret, events: [makeEvent(), makeEvent({installationId: 'other'})]})).status).toBe(400);
  });

  it('accepts resolved lifecycle and preserves the first terminal event on replay', async () => {
    const terminal = makeEvent({eventId: 's_terminal', sessionId: 's_terminal', kind: 'round_ended', reason: 'user_back', itemId: 'ex_1', itemIndex: 0, itemState: 'unresolved'});
    expect((await postEvents({events: [makeEvent({kind: 'item_resolved', itemId: 'ex_1', itemIndex: 0, itemState: null}), terminal]})).status).toBe(202);
    expect((await postEvents({events: [{...terminal, reason: 'inferred_interruption'}]})).status).toBe(202);
    expect((await env.DB.prepare('SELECT reason, item_state FROM events WHERE event_id = ?').bind('s_terminal').first())).toMatchObject({reason: 'user_back', item_state: 'unresolved'});
  });

  it('rejects unknown fields, games, positions, invalid UTC and out-of-window timestamps', async () => {
    for (const change of [
      {rawAnswer: 'private'}, {gameId: 'unknown'}, {itemIndex: 10001},
      {timestampUtc: '2026-01-01'}, {timestampUtc: '2026-02-30T00:00:00.000Z'},
      {timestampUtc: new Date(Date.now() + 6 * 60 * 1000).toISOString()},
      {timestampUtc: new Date(Date.now() - 91 * DAY_MS).toISOString()},
      {kind: 'round_ended', reason: 'user_back', itemId: 'ex_1', itemIndex: 0},
    ]) expect((await postEvents({events: [makeEvent(change)]})).status).toBe(400);
  });

  it('cancels oversized chunked bodies before buffering the entire stream', async () => {
    let chunks = 0;
    let cancelled = false;
    const stream = new ReadableStream<Uint8Array>({
      pull(controller) {
        chunks++;
        controller.enqueue(new Uint8Array(30000));
        if (chunks === 20) controller.close();
      },
      cancel() { cancelled = true; },
    });
    const response = await worker.fetch(new Request('https://example.com/v1/events', {method: 'POST', body: stream}), env);
    expect(response.status).toBe(413);
    expect(cancelled).toBe(true);
    expect(chunks).toBeLessThan(6);
  });

  it('keeps public writes disabled until the deployment safety gate is enabled', async () => {
    for (const path of ['events', 'delete']) {
      expect((await worker.fetch(new Request(`https://example.com/v1/${path}`, {method: 'POST', body: '{}'}), {...env, PUBLIC_ENDPOINTS_ENABLED: 'false'})).status).toBe(503);
    }
  });

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
      deletionSecret: secret,
      events: [makeEvent({ installationId: 'inst_delete' })],
    });
    expect(response.status).toBe(202);
  }

  it('acknowledges never-registered deletion and rejects delayed registration', async () => {
    const body = {installationId: 'never_sent', deletionSecret: 'n'.repeat(64)};
    for (let i = 0; i < 2; i++) {
      expect((await SELF.fetch('https://example.com/v1/delete', {method: 'POST', body: JSON.stringify(body)})).status).toBe(200);
    }
    expect((await postEvents({deletionSecret: body.deletionSecret, events: [makeEvent({installationId: body.installationId})]})).status).toBe(410);
  });

  it('cannot recreate linked records when ingestion overlaps authenticated deletion', async () => {
    const deletionSecret = 'd'.repeat(64);
    const event = makeEvent({installationId: 'overlap'});
    expect((await postEvents({deletionSecret, events: [event]})).status).toBe(202);
    const [, deletion] = await Promise.all([
      postEvents({deletionSecret, events: [makeEvent({installationId: 'overlap'})]}),
      SELF.fetch('https://example.com/v1/delete', {method: 'POST', body: JSON.stringify({installationId: 'overlap', deletionSecret})}),
    ]);
    expect(deletion.status).toBe(200);
    expect((await postEvents({deletionSecret, events: [event]})).status).toBe(410);
    expect(await env.DB.prepare("SELECT COUNT(*) AS count FROM events WHERE installation_id = 'overlap'").first()).toMatchObject({count: 0});
  });

  it('authorizes deletion only with the matching secret', async () => {
    await registerInstallation('c'.repeat(64));

    const wrong = await SELF.fetch('https://example.com/v1/delete', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        installationId: 'inst_delete',
        deletionSecret: 'w'.repeat(64),
      }),
    });
    expect(wrong.status).toBe(401);

    const correct = await SELF.fetch('https://example.com/v1/delete', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        installationId: 'inst_delete',
        deletionSecret: 'c'.repeat(64),
      }),
    });
    expect(correct.status).toBe(200);

    const count = await env.DB.prepare(
      'SELECT COUNT(*) AS count FROM events WHERE installation_id = ?',
    )
      .bind('inst_delete')
      .first();
    expect(Number(count?.count ?? 0)).toBe(0);

    // Replay is harmless: the bounded revocation record remains.
    const replay = await SELF.fetch('https://example.com/v1/delete', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        installationId: 'inst_delete',
        deletionSecret: 'c'.repeat(64),
      }),
    });
    expect(replay.status).toBe(200);
    expect((await postEvents({deletionSecret: 'c'.repeat(64), events: [makeEvent({installationId: 'inst_delete'})]})).status).toBe(410);
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

  it('normalizes timestamp precision and enforces exact ingestion horizon', async () => {
    const now = Date.parse('2026-05-01T12:00:00.123Z');
    vi.useFakeTimers({toFake: ['Date']});
    vi.setSystemTime(now);
    try {
      for (const [timestampUtc, status] of [
        [new Date(now - 90 * DAY_MS - 1).toISOString(), 400],
        [new Date(now - 90 * DAY_MS).toISOString(), 400],
        [new Date(now - 90 * DAY_MS + 1).toISOString(), 202],
        ['2026-05-01T12:00:00.123000Z', 202],
        ['2026-05-01T12:00:00.124000Z', 400],
      ] as const) {
        const response = await worker.fetch(new Request('https://example.com/v1/events', {
          method: 'POST', body: JSON.stringify({deletionSecret: 'a'.repeat(64), events: [makeEvent({timestampUtc})]}),
        }), env);
        expect(response.status).toBe(status);
      }
      expect((await env.DB.prepare('SELECT timestamp_utc FROM events ORDER BY timestamp_utc').all()).results)
        .toEqual([{timestamp_utc: '2026-01-31T12:00:00.124Z'}, {timestamp_utc: '2026-05-01T12:00:00.123Z'}]);
    } finally {
      vi.useRealTimers();
    }
  });

  it('expires tombstones at 90 days without permitting original-payload replay', async () => {
    const now = Date.now();
    vi.useFakeTimers({toFake: ['Date']});
    vi.setSystemTime(now);
    const submit = (event: Record<string, unknown>) => worker.fetch(new Request('https://example.com/v1/events', {
      method: 'POST', body: JSON.stringify({deletionSecret: 'a'.repeat(64), events: [event]}),
    }), env);
    try {
      const original = makeEvent({timestampUtc: new Date(now).toISOString()});
      expect((await submit(original)).status).toBe(202);
      for (const ahead of [1, 4 * 60 * 1000]) {
        expect((await submit(makeEvent({timestampUtc: new Date(now + ahead).toISOString()}))).status).toBe(400);
      }
      expect((await worker.fetch(new Request('https://example.com/v1/delete', {
        method: 'POST', body: JSON.stringify({installationId: 'inst_1', deletionSecret: 'a'.repeat(64)}),
      }), env)).status).toBe(200);
      vi.setSystemTime(now + 90 * DAY_MS - 1);
      await worker.scheduled({} as ScheduledEvent, env);
      expect((await submit(original)).status).toBe(410);
      vi.setSystemTime(now + 90 * DAY_MS);
      await worker.scheduled({} as ScheduledEvent, env);
      expect(await env.DB.prepare('SELECT installation_id FROM installations').first()).toBeNull();
      expect((await submit(original)).status).toBe(400);
      vi.setSystemTime(now + 90 * DAY_MS + 1);
      expect((await submit(original)).status).toBe(400);
      expect(await env.DB.prepare('SELECT installation_id FROM installations').first()).toBeNull();
    } finally {
      vi.useRealTimers();
    }
  });

  it('suppresses many events from only one installation', async () => {
    const old = new Date(Date.now() - 100 * DAY_MS).toISOString();
    for (let i = 0; i < 6; i++) await insertEvent(`sparse_${i}`, old);
    await worker.scheduled({} as ScheduledEvent, env);
    expect(await env.DB.prepare('SELECT COUNT(*) AS count FROM aggregates').first()).toMatchObject({count: 0});
  });

  it('rolls back aggregates when deletion fails and retries without double counting', async () => {
    const old = new Date(Date.now() - 100 * DAY_MS).toISOString();
    for (let i = 0; i < 6; i++) {
      await insertEvent(`atomic_${i}`, old);
      await env.DB.prepare('UPDATE events SET installation_id = ? WHERE event_id = ?').bind(`inst_${i}`, `atomic_${i}`).run();
    }
    await env.DB.prepare("CREATE TRIGGER fail_purge BEFORE DELETE ON events BEGIN SELECT RAISE(ABORT, 'forced failure'); END").run();
    try {
      await expect(worker.scheduled({} as ScheduledEvent, env)).rejects.toThrow();
      expect(await env.DB.prepare('SELECT COUNT(*) AS count FROM aggregates').first()).toMatchObject({count: 0});
    } finally {
      await env.DB.prepare('DROP TRIGGER fail_purge').run();
    }
    await Promise.all([worker.scheduled({} as ScheduledEvent, env), worker.scheduled({} as ScheduledEvent, env)]);
    const counts = await env.DB.prepare("SELECT count FROM aggregates WHERE scope = 'overall'").all();
    expect(counts.results.map(row => row.count)).toEqual([6, 6]);
  });

  it('expires inactive credentials and bounded revocations, not recent revocations', async () => {
    await postEvents({events: [makeEvent()]});
    await env.DB.prepare('DELETE FROM events').run();
    const old = new Date(Date.now() - 100 * DAY_MS).toISOString();
    await env.DB.prepare('UPDATE installations SET last_seen_at = ?').bind(old).run();
    await env.DB.prepare('INSERT INTO installations (installation_id, deletion_secret_hash, revoked_at, last_seen_at) VALUES (?, ?, ?, ?)').bind('old_revoked', 'hash', old, old).run();
    await SELF.fetch('https://example.com/v1/delete', {method: 'POST', body: JSON.stringify({installationId: 'recent_revoked', deletionSecret: 'r'.repeat(64)})});
    await worker.scheduled({} as ScheduledEvent, env);
    expect((await env.DB.prepare('SELECT installation_id FROM installations').all()).results).toEqual([{installation_id: 'recent_revoked'}]);
  });

  it('retains useful item/outcome dimensions only for cells with five installations', async () => {
    const old = new Date(Date.now() - 100 * DAY_MS).toISOString();
    for (let i = 0; i < 6; i++) {
      await insertEvent(`metric_${i}`, old, 'item_answered');
      await env.DB.prepare("UPDATE events SET installation_id = ?, outcome = 'wrong' WHERE event_id = ?").bind(`inst_${i}`, `metric_${i}`).run();
    }
    await insertEvent('sparse_correct', old, 'item_answered');
    await env.DB.prepare("UPDATE events SET outcome = 'correct' WHERE event_id = 'sparse_correct'").run();
    await worker.scheduled({} as ScheduledEvent, env);
    const rows = await env.DB.prepare("SELECT item_id, item_index, content_version, outcome, count FROM aggregates WHERE scope = 'item'").all();
    expect(rows.results).toEqual([
      {item_id: 'n1', item_index: 0, content_version: 'bundled', outcome: 'wrong', count: 6},
      {item_id: 'n1', item_index: 0, content_version: 'bundled', outcome: 'wrong', count: 6},
    ]);
  });

  it('uses receipt retention even for a future client timestamp and leaves recent rows', async () => {
    await insertEvent('receipt_expired', new Date(Date.now() + 4 * 60000).toISOString());
    await env.DB.prepare('UPDATE events SET created_at = ? WHERE event_id = ?').bind(new Date(Date.now() - 91 * DAY_MS).toISOString(), 'receipt_expired').run();
    await insertEvent('inside_window', new Date(Date.now() - 89 * DAY_MS).toISOString());
    await worker.scheduled({} as ScheduledEvent, env);
    expect((await env.DB.prepare('SELECT event_id FROM events').all()).results).toEqual([{event_id: 'inside_window'}]);
  });

  it('purges old linked events into non-linkable aggregates', async () => {
    const oldDay = new Date(Date.now() - 100 * DAY_MS).toISOString().slice(0, 10);
    for (let i = 0; i < 6; i++) {
      await insertEvent(`old_${i}`, `${oldDay}T00:00:00.000Z`);
      await env.DB.prepare('UPDATE events SET installation_id = ? WHERE event_id = ?').bind(`inst_${i}`, `old_${i}`).run();
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
