import { handleReport } from './report';
import {
  type AnalyticsEvent,
  MAX_EVENTS_PER_BATCH,
  MAX_PAYLOAD_BYTES,
  validateEvent,
} from './schema';

export interface Env {
  DB: D1Database;
  ACCESS_ISSUER?: string;
  ACCESS_AUDIENCE?: string;
  ACCESS_OWNER_EMAILS?: string;
  RATE_LIMIT_MAX?: string;
  PUBLIC_ENDPOINTS_ENABLED?: string;
}

const RATE_WINDOW_MS = 60_000;
const MAX_RATE_BUCKETS = 10_000;
const rateBuckets = new Map<string, { windowStart: number; count: number }>();

// Sparse day/week cells can identify a single installation, so aggregates are
// only recorded when a bucket has at least this many distinct installations.
const MIN_AGGREGATE_INSTALLATIONS = 5;
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
  const reader = request.body?.getReader();
  if (!reader) return {ok: true, text: ''};
  const chunks: Uint8Array[] = [];
  let size = 0;
  try {
    while (true) {
      const {done, value} = await reader.read();
      if (done) break;
      size += value.byteLength;
      if (size > MAX_PAYLOAD_BYTES) {
        await reader.cancel();
        return {ok: false, response: jsonResponse({error: 'payload too large'}, 413)};
      }
      chunks.push(value);
    }
    const bytes = new Uint8Array(size);
    let offset = 0;
    for (const chunk of chunks) { bytes.set(chunk, offset); offset += chunk.byteLength; }
    return {ok: true, text: new TextDecoder('utf-8', {fatal: true, ignoreBOM: false}).decode(bytes)};
  } catch {
    return {ok: false, response: jsonResponse({error: 'invalid body'}, 400)};
  } finally {
    reader.releaseLock();
  }
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

function validSecret(value: unknown): value is string {
  return typeof value === 'string' && /^[a-zA-Z0-9_-]{32,128}$/.test(value);
}

async function handleEvents(request: Request, env: Env): Promise<Response> {
  const body = await readBoundedBody(request);
  if (!body.ok) return body.response;

  let parsed: unknown;
  try {
    parsed = JSON.parse(body.text);
  } catch {
    return jsonResponse({ error: 'invalid JSON' }, 400);
  }

  if (!isRecord(parsed) || Object.keys(parsed).some(key => !['events', 'deletionSecret'].includes(key)) || !Array.isArray(parsed.events)) {
    return jsonResponse({ error: 'events must be an array' }, 400);
  }
  if (parsed.events.length === 0) {
    return jsonResponse({ error: 'events must not be empty' }, 400);
  }
  if (parsed.events.length > MAX_EVENTS_PER_BATCH) {
    return jsonResponse({ error: 'too many events in batch' }, 413);
  }

  const now = Date.now();
  const events: AnalyticsEvent[] = [];
  for (const raw of parsed.events) {
    const result = validateEvent(raw, now);
    if (!result.ok) {
      return jsonResponse({ error: `invalid event: ${result.error}` }, 400);
    }
    events.push(result.event);
  }

  if (!validSecret(parsed.deletionSecret) || events.some(event => event.installationId !== events[0].installationId)) {
    return jsonResponse({ error: 'invalid credentials or mixed installations' }, 400);
  }
  const installationId = events[0].installationId;
  const hash = await sha256Hex(parsed.deletionSecret);
  const statements = events.map((event) =>
    env.DB.prepare(
      `INSERT OR IGNORE INTO events
        (event_id, session_id, installation_id, game_id, content_version,
         item_id, item_index, timestamp_utc, kind, outcome, reason, item_state, attempt_delta, correct_discovery_delta, distinct_wrong_delta)
       SELECT ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?
       WHERE EXISTS (SELECT 1 FROM installations WHERE installation_id = ? AND deletion_secret_hash = ? AND revoked_at IS NULL)
         AND ? > COALESCE((SELECT cutoff FROM purge_marker WHERE id = 1), '')`,
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
      event.itemState,
      event.attemptDelta,
      event.correctDiscoveryDelta,
      event.distinctWrongDelta,
      installationId, hash, event.timestampUtc,
    ),
  );

  await env.DB.batch([
    env.DB.prepare(`INSERT INTO installations (installation_id, deletion_secret_hash, last_seen_at)
      VALUES (?, ?, ?)
      ON CONFLICT(installation_id) DO UPDATE SET last_seen_at = excluded.last_seen_at
      WHERE deletion_secret_hash = excluded.deletion_secret_hash AND revoked_at IS NULL`)
      .bind(installationId, hash, new Date(now).toISOString()),
    ...statements,
  ]);
  const installation = await env.DB.prepare('SELECT deletion_secret_hash, revoked_at FROM installations WHERE installation_id = ?').bind(installationId).first();
  if (!installation || !timingSafeEqual(String(installation.deletion_secret_hash), hash)) {
    return jsonResponse({ error: 'unauthorized' }, 401);
  }
  if (installation.revoked_at !== null) return jsonResponse({ error: 'revoked' }, 410);
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

  if (!isRecord(parsed) || Object.keys(parsed).some(key => !['installationId', 'deletionSecret'].includes(key))) {
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
  if (!validSecret(deletionSecret)) {
    return jsonResponse({ error: 'missing deletionSecret' }, 400);
  }

  const providedHash = await sha256Hex(deletionSecret);
  const now = new Date().toISOString();
  await env.DB.batch([
    env.DB.prepare(`INSERT INTO installations (installation_id, deletion_secret_hash, revoked_at, last_seen_at)
      VALUES (?, ?, ?, ?)
      ON CONFLICT(installation_id) DO UPDATE SET revoked_at = COALESCE(revoked_at, excluded.revoked_at)
      WHERE deletion_secret_hash = excluded.deletion_secret_hash`)
      .bind(installationId, providedHash, now, now),
    env.DB.prepare(`DELETE FROM events WHERE installation_id = ? AND EXISTS
      (SELECT 1 FROM installations WHERE installation_id = ? AND deletion_secret_hash = ? AND revoked_at IS NOT NULL)`)
      .bind(installationId, installationId, providedHash),
  ]);
  const row = await env.DB.prepare('SELECT deletion_secret_hash FROM installations WHERE installation_id = ?').bind(installationId).first();
  if (!row || !timingSafeEqual(String(row.deletion_secret_hash), providedHash)) {
    return jsonResponse({ error: 'unauthorized' }, 401);
  }

  return jsonResponse({ deleted: true }, 200);
}

export async function purgeExpired(env: Env): Promise<number> {
  const cutoff = new Date(Date.now() - RETENTION_DAYS * 86400000).toISOString();
  const dimensions = 'bucket, scope, game_id, kind, content_version, item_id, item_index, outcome, reason, item_state';
  // Nullable counter addition preserves suppression across later purge contributions.
  const statements = [
    "'day:' || substr(timestamp_utc, 1, 10)",
    "'week:' || strftime('%Y-W%W', timestamp_utc)",
  ].flatMap(bucket => ['overall', 'item'].map(scope => {
    const itemDimensions = scope === 'item'
      ? "content_version, COALESCE(item_id, ''), COALESCE(item_index, -1)"
      : "'', '', -1";
    return env.DB.prepare(`
      INSERT INTO aggregates (${dimensions}, count, attempts, correct_discoveries, distinct_wrong_positions)
      SELECT ${bucket}, '${scope}', game_id, kind, ${itemDimensions},
        COALESCE(outcome, ''), COALESCE(reason, ''), COALESCE(item_state, ''), COUNT(*),
        CASE WHEN COUNT(DISTINCT CASE WHEN attempt_delta > 0 THEN installation_id END) >= ${MIN_AGGREGATE_INSTALLATIONS}
          THEN SUM(attempt_delta) ELSE NULL END,
        CASE WHEN COUNT(DISTINCT CASE WHEN correct_discovery_delta > 0 THEN installation_id END) >= ${MIN_AGGREGATE_INSTALLATIONS}
          THEN SUM(correct_discovery_delta) ELSE NULL END,
        CASE WHEN COUNT(DISTINCT CASE WHEN distinct_wrong_delta > 0 THEN installation_id END) >= ${MIN_AGGREGATE_INSTALLATIONS}
          THEN SUM(distinct_wrong_delta) ELSE NULL END FROM events
      WHERE timestamp_utc <= ? OR created_at <= ?
      GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
      HAVING COUNT(DISTINCT installation_id) >= ?
      ON CONFLICT(${dimensions}) DO UPDATE SET count = count + excluded.count,
        attempts = attempts + excluded.attempts,
        correct_discoveries = correct_discoveries + excluded.correct_discoveries,
        distinct_wrong_positions = distinct_wrong_positions + excluded.distinct_wrong_positions
    `).bind(cutoff, cutoff, MIN_AGGREGATE_INSTALLATIONS);
  }));
  // D1 batch is one transaction: a failure rolls back both counting and removal.
  const results = await env.DB.batch([
    ...statements,
    env.DB.prepare('DELETE FROM events WHERE timestamp_utc <= ? OR created_at <= ?').bind(cutoff, cutoff),
    env.DB.prepare(`DELETE FROM installations WHERE
      (revoked_at IS NOT NULL AND revoked_at <= ?) OR
      (revoked_at IS NULL AND COALESCE(last_seen_at, created_at) <= ? AND NOT EXISTS
        (SELECT 1 FROM events WHERE events.installation_id = installations.installation_id))`)
      .bind(cutoff, cutoff),
    // Report history publishes only weeks this committed cutoff proves final.
    env.DB.prepare(`INSERT INTO purge_marker (id, cutoff) VALUES (1, ?)
      ON CONFLICT(id) DO UPDATE SET cutoff = excluded.cutoff WHERE excluded.cutoff > purge_marker.cutoff`)
      .bind(cutoff),
  ]);
  return results[4].meta.changes;
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    if (url.pathname === '/private' || url.pathname.startsWith('/private/')) return handleReport(request, env);
    if (request.method === 'POST' && ['/v1/events', '/v1/delete'].includes(url.pathname)) {
      if (env.PUBLIC_ENDPOINTS_ENABLED !== 'true') return jsonResponse({error: 'deployment safety gate closed'}, 503);
      // Isolate-local backstop only; distributed enforcement is a release gate.
      if (!allowRequest(request.headers.get('cf-connecting-ip') ?? 'unknown', readRateLimit(env))) {
        return jsonResponse({error: 'rate limited'}, 429);
      }
    }
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
