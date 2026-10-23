import worker, { type Env } from '../src/index';
import { env, applyD1Migrations, fetchMock } from 'cloudflare:test';
import { beforeAll, beforeEach, afterEach, expect, it } from 'vitest';
import { exportJWK, generateKeyPair, SignJWT } from 'jose';

const issuer = 'https://owner-test.cloudflareaccess.com';
let keys: Awaited<ReturnType<typeof generateKeyPair>>;
const config = (): Env => ({...env, ACCESS_ISSUER: issuer, ACCESS_AUDIENCE: 'report-audience', ACCESS_OWNER_EMAILS: 'owner@example.test'});
async function token(claims: Record<string, unknown> = {}, otherKey = false) {
  return new SignJWT({email: 'owner@example.test', ...claims}).setProtectedHeader({alg: 'RS256', kid: 'fixture'})
    .setIssuer(typeof claims.iss === 'string' ? claims.iss : issuer).setAudience(typeof claims.aud === 'string' ? claims.aud : 'report-audience')
    .setExpirationTime(typeof claims.exp === 'number' ? claims.exp : Math.floor(Date.now()/1000)+600)
    .sign(otherKey ? (await generateKeyPair('RS256')).privateKey : keys.privateKey);
}
async function get(path: string, jwt?: string, settings = config()) {
  return worker.fetch(new Request(`https://example.test/private/report${path}`, {headers: jwt ? {'Cf-Access-Jwt-Assertion': jwt} : {}}), settings);
}
beforeAll(async () => { keys = await generateKeyPair('RS256', {extractable: true}); await applyD1Migrations(env.DB, env.TEST_MIGRATIONS); });
beforeEach(async () => {
  fetchMock.activate(); fetchMock.disableNetConnect();
  fetchMock.get(issuer).intercept({path: '/cdn-cgi/access/certs'}).reply(200, {keys: [{...await exportJWK(keys.publicKey), kid: 'fixture', alg: 'RS256', use: 'sig'}]}).persist();
  await env.DB.exec('DELETE FROM events; DELETE FROM installations; DELETE FROM aggregates;');
});
afterEach(() => { fetchMock.deactivate(); });
it('cryptographically gates every private entry before database access', async () => {
  const denied = [undefined, 'forged', await token({}, true), await token({iss: 'https://evil.test'}), await token({aud: 'other'}), await token({exp: 1}), await token({email: 'stranger@example.test'})];
  const noDb = {...config(), DB: {prepare() {throw new Error('DB accessed before authorization');}} as unknown as D1Database};
  for (const path of ['', '/', '/app.js', '/api/recent', '/api/history', '/unknown']) {
    for (const jwt of denied) expect((await get(path, jwt, noDb)).status).toBe(403);
    for (const missing of ['ACCESS_ISSUER', 'ACCESS_AUDIENCE', 'ACCESS_OWNER_EMAILS'] as const) {
      expect((await get(path, await token(), {...noDb, [missing]: ''})).status).toBe(403);
    }
  }
  const page = await get('/', await token());
  expect(page.status).toBe(200);
  expect(page.headers.get('cache-control')).toBe('private, no-store');
  expect(page.headers.get('content-security-policy')).toContain("default-src 'none'");
  expect((await get('/unknown', await token())).status).toBe(404);
});

it('summarizes retained four-game sessions with separate units, filters and stable pagination', async () => {
  const jwt = await token();
  const timestamp = new Date(Date.now()-86400000).toISOString();
  let n = 0;
  async function insert(game: string, session: string, kind: string, extra: Record<string, unknown> = {}) {
    const e = {item: null, index: null, outcome: null, reason: null, attempts: null, discoveries: null, wrongs: null, ...extra};
    await env.DB.prepare(`INSERT INTO events(event_id, installation_id, session_id, game_id, content_version, timestamp_utc, kind, item_id, item_index, outcome, reason, attempt_delta, correct_discovery_delta, distinct_wrong_delta) VALUES (?, ?, ?, ?, 'v1', ?, ?, ?, ?, ?, ?, ?, ?, ?)`)
      .bind(`fixture-${n++}`, 'install-a', session, game, timestamp, kind, e.item, e.index, e.outcome, e.reason, e.attempts, e.discoveries, e.wrongs).run();
  }
  for (const game of ['grammar', 'vocabulary', 'idioms', 'spot']) {
    await insert(game, game, 'round_started');
    await insert(game, game, 'item_shown', {item: '<img src=x onerror=alert(1)>', index: 0});
    if (game !== 'spot') {
      await insert(game, game, 'item_answered', {item: '<img src=x onerror=alert(1)>', index: 0, outcome: 'correct'});
      await insert(game, game, 'item_resolved', {item: '<img src=x onerror=alert(1)>', index: 0});
      await insert(game, game, 'round_ended', {reason: 'completed'});
    } else {
      for (const [discoveries, wrongs] of [[1,0],[0,0],[0,1],[0,0]]) await insert(game, game, 'spot_attempt', {item: '<img src=x onerror=alert(1)>', index: 0, attempts: 1, discoveries, wrongs});
    }
  }
  const first = await (await get('/api/recent?limit=2', jwt)).json() as any;
  expect(first.sessions).toHaveLength(2);
  expect(first.summary.grammar).toMatchObject({started: 1, completed: 1, shown: 1, resolved: 1, left: 0, correct: 1, wrong: 0});
  expect(first.summary.spot).toMatchObject({started: 1, inProgress: 1, shown: 1, resolved: 0, left: 1, attempts: 4, discoveries: 1, distinctWrong: 1});
  const second = await (await get(`/api/recent?limit=2&cursor=${encodeURIComponent(first.nextCursor)}`, jwt)).json() as any;
  expect(new Set([...first.sessions, ...second.sessions].map((s: any) => s.game)).size).toBe(4);
  const filtered = await (await get('/api/recent?game=spot&version=v1&installation=install-a', jwt)).json() as any;
  expect(filtered.sessions).toHaveLength(1);
  expect(filtered.sessions[0]).toMatchObject({status: 'in_progress', lastItem: '<img src=x onerror=alert(1)>', missingStart: false});
  expect(JSON.stringify(filtered)).not.toContain('fixture-');
  for (const query of ['game=evil', 'sql=SELECT', 'sort=installation', 'limit=1000', 'from=2020-01-01&to=2026-01-01', 'version=', 'game=spot&game=grammar']) {
    expect((await get(`/api/recent?${query}`, jwt)).status).toBe(400);
  }
});
