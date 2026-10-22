import {
  MAX_EVENTS_PER_BATCH,
  MAX_PAYLOAD_BYTES,
  validateEvent,
} from './schema';

export interface Env {
  DB: D1Database;
  RATE_LIMIT_MAX?: string;
}

const RATE_WINDOW_MS = 60_000;
const MAX_RATE_BUCKETS = 10_000;
const rateBuckets = new Map<string, { windowStart: number; count: number }>();

// Sparse day/week cells can identify a single installation, so aggregates are
// only recorded when a bucket has at least this many events.
const MIN_AGGREGATE_COUNT = 5;
const RETENTION_DAYS = 90;

function jsonHeaders(): Headers {
  const headers = new Headers();
  headers.set('content-type', 'application/json');
  return headers;
}

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), { status, headers: jsonHeaders() });
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

function readRateLimit(env: Env): number {
  const parsed = Number.parseInt(env.RATE_LIMIT_MAX ?? '60', 10);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : 60;
}

function allowRequest(ip: string, max: number): boolean {
  if (rateBuckets.size >= MAX_RATE_BUCKETS) {
    rateBuckets.clear();
  }
  const now = Date.now();
  const bucket = rateBuckets.get(ip);
  if (!bucket || now - bucket.windowStart >= RATE_WINDOW_MS) {
    rateBuckets.set(ip, { windowStart: now, count: 1 });
    return true;
  }
  bucket.count += 1;
  return bucket.count <= max;
}

async function readBoundedBody(
  request: Request,
): Promise<{ ok: true; text: string } | { ok: false; response: Response }> {
  const contentLength = Number(request.headers.get('content-length') ?? '0');
  if (contentLength > MAX_PAYLOAD_BYTES) {
    return { ok: false, response: jsonResponse({ error: 'payload too large' }, 413) };
  }
  const text = await request.text();
  if (new TextEncoder().encode(text).byteLength > MAX_PAYLOAD_BYTES) {
    return { ok: false, response: jsonResponse({ error: 'payload too large' }, 413) };
  }
  return { ok: true, text };
}

async function sha256Hex(value: string): Promise<string> {
  const digest = await crypto.subtle.digest(
    'SHA-256',
    new TextEncoder().encode(value),
  );
  return [...new Uint8Array(digest)]
    .map((byte) => byte.toString(16).padStart(2, '0'))
    .join('');
}

function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) {
    diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return diff === 0;
}

async function registerDeletionSecret(
  env: Env,
  installationId: string,
  deletionSecret: string,
): Promise<void> {
  const hash = await sha256Hex(deletionSecret);
  await env.DB.prepare(
    'INSERT INTO installations (installation_id, deletion_secret_hash) VALUES (?, ?) ON CONFLICT(installation_id) DO NOTHING',
  )
    .bind(installationId, hash)
    .run();
}

async function handleEvents(request: Request, env: Env): Promise<Response> {
  const ip = request.headers.get('cf-connecting-ip') ?? 'unknown';
  if (!allowRequest(ip, readRateLimit(env))) {
    return jsonResponse({ error: 'rate limited' }, 429);
  }

  const body = await readBoundedBody(request);
  if (!body.ok) return body.response;

  let parsed: unknown;
  try {
    parsed = JSON.parse(body.text);
  } catch {
    return jsonResponse({ error: 'invalid JSON' }, 400);
  }

  if (!isRecord(parsed) || !Array.isArray(parsed.events)) {
    return jsonResponse({ error: 'events must be an array' }, 400);
  }
  if (parsed.events.length === 0) {
    return jsonResponse({ error: 'events must not be empty' }, 400);
  }
  if (parsed.events.length > MAX_EVENTS_PER_BATCH) {
    return jsonResponse({ error: 'too many events in batch' }, 413);
  }

  const events = [];
  for (const raw of parsed.events) {
    const result = validateEvent(raw);
    if (!result.ok) {
      return jsonResponse({ error: `invalid event: ${result.error}` }, 400);
    }
    events.push(result.event);
  }

  if (typeof parsed.deletionSecret === 'string' && parsed.deletionSecret) {
    await registerDeletionSecret(env, events[0].installationId, parsed.deletionSecret);
  }

  const statements = events.map((event) =>
    env.DB.prepare(
      `INSERT OR IGNORE INTO events
        (event_id, session_id, installation_id, game_id, content_version,
         item_id, item_index, timestamp_utc, kind, outcome, reason)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    ).bind(
      event.eventId,
      event.sessionId,
      event.installationId,
      event.gameId,
      event.contentVersion,
      event.itemId,
      event.itemIndex,
      event.timestampUtc,
      event.kind,
      event.outcome,
      event.reason,
    ),
  );

  await env.DB.batch(statements);
  // Data minimization: report counts only, never event bodies or secrets.
  return jsonResponse({ accepted: events.length }, 202);
}

async function handleDelete(request: Request, env: Env): Promise<Response> {
  const body = await readBoundedBody(request);
  if (!body.ok) return body.response;

  let parsed: unknown;
  try {
    parsed = JSON.parse(body.text);
  } catch {
    return jsonResponse({ error: 'invalid JSON' }, 400);
  }

  if (!isRecord(parsed)) {
    return jsonResponse({ error: 'invalid body' }, 400);
  }
  const installationId = parsed.installationId;
  const deletionSecret = parsed.deletionSecret;
  if (
    typeof installationId !== 'string' ||
    installationId.length === 0 ||
    installationId.length > 128
  ) {
    return jsonResponse({ error: 'invalid installationId' }, 400);
  }
  if (typeof deletionSecret !== 'string' || deletionSecret.length === 0) {
    return jsonResponse({ error: 'missing deletionSecret' }, 400);
  }

  const row = await env.DB.prepare(
    'SELECT deletion_secret_hash FROM installations WHERE installation_id = ?',
  )
    .bind(installationId)
    .first();

  if (!row) {
    return jsonResponse({ error: 'unknown installation' }, 404);
  }

  const expectedHash = String(row.deletion_secret_hash);
  const providedHash = await sha256Hex(deletionSecret);
  if (!timingSafeEqual(expectedHash, providedHash)) {
    return jsonResponse({ error: 'unauthorized' }, 401);
  }

  await env.DB.batch([
    env.DB.prepare('DELETE FROM events WHERE installation_id = ?').bind(installationId),
    env.DB.prepare('DELETE FROM installations WHERE installation_id = ?').bind(installationId),
  ]);

  return jsonResponse({ deleted: true }, 200);
}

async function upsertAggregate(
  env: Env,
  bucket: string,
  gameId: string,
  kind: string,
  count: number,
): Promise<void> {
  await env.DB.prepare(
    `INSERT INTO aggregates (bucket, game_id, kind, count)
     VALUES (?, ?, ?, ?)
     ON CONFLICT(bucket, game_id, kind)
     DO UPDATE SET count = count + excluded.count`,
  )
    .bind(bucket, gameId, kind, count)
    .run();
}

export async function purgeExpired(env: Env): Promise<number> {
  const cutoff = new Date(Date.now() - RETENTION_DAYS * 24 * 60 * 60 * 1000);
  const cutoffIso = cutoff.toISOString();

  const dayRows = await env.DB.prepare(
    `SELECT game_id, kind, substr(timestamp_utc, 1, 10) AS day, COUNT(*) AS count
     FROM events
     WHERE timestamp_utc < ?
     GROUP BY game_id, kind, day`,
  )
    .bind(cutoffIso)
    .all();

  for (const row of dayRows.results) {
    const count = Number(row.count);
    if (count >= MIN_AGGREGATE_COUNT) {
      await upsertAggregate(env, `day:${row.day}`, String(row.game_id), String(row.kind), count);
    }
  }

  const weekRows = await env.DB.prepare(
    `SELECT game_id, kind, strftime('%Y-W%W', timestamp_utc) AS week, COUNT(*) AS count
     FROM events
     WHERE timestamp_utc < ?
     GROUP BY game_id, kind, week`,
  )
    .bind(cutoffIso)
    .all();

  for (const row of weekRows.results) {
    const count = Number(row.count);
    if (count >= MIN_AGGREGATE_COUNT) {
      await upsertAggregate(env, `week:${row.week}`, String(row.game_id), String(row.kind), count);
    }
  }

  const deleted = await env.DB.prepare(
    'DELETE FROM events WHERE timestamp_utc < ?',
  )
    .bind(cutoffIso)
    .run();

  return deleted.meta.changes;
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    if (url.pathname === '/v1/events' && request.method === 'POST') {
      return handleEvents(request, env);
    }
    if (url.pathname === '/v1/delete' && request.method === 'POST') {
      return handleDelete(request, env);
    }
    return jsonResponse({ error: 'not found' }, 404);
  },

  async scheduled(_event: ScheduledEvent, env: Env): Promise<void> {
    await purgeExpired(env);
  },
};
