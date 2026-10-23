import worker, { type Env } from '../src/index';
import { env, applyD1Migrations, fetchMock } from 'cloudflare:test';
import { beforeAll, beforeEach, afterEach, expect, it, vi } from 'vitest';
import { exportJWK, generateKeyPair, SignJWT } from 'jose';

const day = 86400000;
const today = new Date().toISOString().slice(0, 10);
const dateOf = (daysAgo: number) => new Date(Date.parse(today) - daysAgo*day).toISOString().slice(0, 10);

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
  await env.DB.exec('DELETE FROM events; DELETE FROM installations; DELETE FROM aggregates; DELETE FROM purge_marker;');
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
  expect(first.summary.spot).toMatchObject({started: 1, inProgress: 1, shown: 1, resolved: 0, left: 0, openUnresolved: 1, attempts: 4, discoveries: 1, distinctWrong: 1});
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

it('aggregates item outcomes and terminal positions across installations independently of pagination', async () => {
  const jwt = await token();
  const timestamp = `${dateOf(1)}T12:00:00.000Z`;
  let n = 0;
  async function event(installation: string, session: string, kind: string, extra: Record<string, unknown> = {}) {
    const e = {version: 'v1', item: 'shared', index: 0, outcome: null, reason: null, state: null, ...extra};
    await env.DB.prepare(`INSERT INTO events(event_id, installation_id, session_id, game_id, content_version, timestamp_utc, kind, item_id, item_index, outcome, reason, item_state) VALUES (?, ?, ?, 'grammar', ?, ?, ?, ?, ?, ?, ?, ?)`)
      .bind(`population-${n++}`, installation, session, e.version, timestamp, kind, e.item, e.index, e.outcome, e.reason, e.state).run();
  }
  for (const [installation, session, index, outcome] of [['install-a', 'a', 0, 'correct'], ['install-b', 'b', 2, 'wrong']] as const) {
    await event(installation, session, 'round_started', {item: null, index: null});
    await event(installation, session, 'item_shown', {index});
    await event(installation, session, 'item_answered', {index, outcome});
    await event(installation, session, 'item_resolved', {index});
    await event(installation, session, 'round_ended', {index, reason: 'completed', state: 'resolved'});
  }
  await event('install-c', 'c', 'item_shown', {index: 1});
  await event('install-c', 'c', 'round_ended', {index: 1, reason: 'user_back', state: 'unresolved'});
  await event('install-d', 'd', 'item_shown', {version: 'v2', index: 1});
  const first = await (await get('/api/recent?limit=1', jwt)).json() as any;
  expect(first.sessions).toHaveLength(1);
  expect(first.summary.grammar.byItem).toEqual(expect.arrayContaining([
    expect.objectContaining({id: 'shared', version: 'v1', shown: 3, resolved: 2, left: 1, openUnresolved: 0, correct: 1, wrong: 1}),
    expect.objectContaining({id: 'shared', version: 'v2', shown: 1, resolved: 0, left: 0, openUnresolved: 1}),
  ]));
  expect(first.summary.grammar.endedAt).toEqual(expect.arrayContaining([
    {version: 'v1', itemId: 'shared', itemIndex: 0, reason: 'completed', count: 1},
    {version: 'v1', itemId: 'shared', itemIndex: 2, reason: 'completed', count: 1},
    {version: 'v1', itemId: 'shared', itemIndex: 1, reason: 'user_back', count: 1},
  ]));
  expect(first.summary.grammar.endedAt).toHaveLength(3);
  const next = await (await get(`/api/recent?limit=1&cursor=${encodeURIComponent(first.nextCursor)}`, jwt)).json() as any;
  expect(next.summary).toEqual(first.summary);
  const one = await (await get('/api/recent?installation=install-b', jwt)).json() as any;
  expect(one.summary.grammar.byItem).toEqual([
    expect.objectContaining({id: 'shared', version: 'v1', shown: 1, resolved: 1, correct: 0, wrong: 1}),
  ]);
});

it.each(['item_shown', 'round_ended'])('bounds %s population groups before returning a report', async (kind) => {
  await env.DB.prepare(`WITH RECURSIVE n(i) AS (SELECT 1 UNION ALL SELECT i + 1 FROM n WHERE i < 501)
    INSERT INTO events(event_id, installation_id, session_id, game_id, content_version, timestamp_utc, kind, item_id, item_index, reason, item_state)
    SELECT 'group-' || i, 'inst-groups', 'round-' || i, 'grammar', 'v1', ?, ?,
      CASE WHEN ? = 'item_shown' THEN 'item-' || i ELSE 'shared' END, i, ?, ? FROM n`)
    .bind(`${dateOf(1)}T12:00:00.000Z`, kind, kind, kind === 'round_ended' ? 'user_back' : null, kind === 'round_ended' ? 'unresolved' : null).run();
  const response = await get('/api/recent?limit=1', await token());
  expect(response.status).toBe(422);
  expect(await response.text()).not.toContain('inst-groups');
});

it('expires linked rows logically, honors deletion and labels missing starts and recovered interruptions', async () => {
  const jwt = await token();
  const now = Date.now();
  const old = new Date(now - 90*86400000-1000).toISOString();
  const recent = new Date(now - 86400000).toISOString();
  for (const [id, time, created] of [['old-event',old,recent], ['old-receipt',recent,old], ['kept',recent,recent]]) {
    await env.DB.prepare(`INSERT INTO events(event_id, installation_id, session_id, game_id, content_version, timestamp_utc, created_at, kind, reason, item_id, item_index, item_state) VALUES (?, 'inst-linked', ?, 'grammar', 'v1', ?, ?, 'round_ended', 'inferred_interruption', 'last-item', 3, 'unresolved')`).bind(id,id,time,created).run();
  }
  await env.DB.prepare(`INSERT INTO installations(installation_id, deletion_secret_hash) VALUES ('credential-only', 'never-return-this')`).run();
  const body = await (await get('/api/recent',jwt)).json() as any;
  expect(body.sessions).toHaveLength(1);
  expect(body.sessions[0]).toMatchObject({session: 'kept', missingStart: true, status: 'inferred_interruption', lastItem: 'last-item', lastIndex: 3, lastItemEvidence: 'terminal'});
  expect(body.sessions[0].metrics).toMatchObject({shown: 0, left: 1, openUnresolved: 0, wrong: 0});
  expect(JSON.stringify(body)).not.toContain('credential-only');
  const secret = 'd'.repeat(43);
  const hash = [...new Uint8Array(await crypto.subtle.digest('SHA-256',new TextEncoder().encode(secret)))].map(b => b.toString(16).padStart(2,'0')).join('');
  await env.DB.prepare(`INSERT INTO installations(installation_id, deletion_secret_hash) VALUES ('inst-linked', ?)`).bind(hash).run();
  expect((await worker.fetch(new Request('https://example.test/v1/delete', {method:'POST', body: JSON.stringify({installationId:'inst-linked',deletionSecret:secret})}), env)).status).toBe(200);
  expect((await (await get('/api/recent?installation=inst-linked',jwt)).json() as any).sessions).toEqual([]);
});

it('offers only canonical closed weekly overall history and preserves suppressed counters', async () => {
  const jwt = await token();
  const old = new Date(Date.now()-100*86400000).toISOString();
  const bucket = await env.DB.prepare(`SELECT 'week:' || strftime('%Y-W%W', ?) AS bucket`).bind(old).first<string>('bucket');
  for (const [scope, kind, outcome, count, attempts, discoveries, wrongs] of [
    ['overall','spot_attempt','',6,6,null,null], ['item','spot_attempt','',123,123,123,123],
    ['overall','item_shown','',10,null,null,null], ['overall','item_answered','correct',5,null,null,null],
  ]) {
    await env.DB.prepare(`INSERT INTO aggregates(bucket,scope,game_id,kind,content_version,item_id,item_index,outcome,reason,item_state,count,attempts,correct_discoveries,distinct_wrong_positions) VALUES (?, ?, ?, ?, '', '', -1, ?, '', '', ?, ?, ?, ?)`)
      .bind(bucket,scope,kind === 'item_answered' ? 'grammar':'spot',kind,outcome,count,attempts,discoveries,wrongs).run();
  }
  expect(await (await get('/api/history',jwt)).json()).toMatchObject({published: false, buckets: [], weeks: []});
  await worker.scheduled({} as ScheduledEvent, env);
  const body = await (await get('/api/history',jwt)).json() as any;
  expect(body).toMatchObject({published: true, partial: true});
  expect(body.buckets).toHaveLength(52);
  expect(body.weeks).toContainEqual(expect.objectContaining({bucket, game:'spot', partial:true, shown:10, attempts:6, discoveries:null, distinctWrong:null}));
  expect(JSON.stringify(body)).not.toContain('123');
  for (const query of ['from=2020-01-01', 'installation=inst-linked', 'version=v1', 'scope=item', 'grain=day', 'bucket='+bucket, 'cursor=x']) {
    expect((await get('/api/history?'+query,jwt)).status).toBe(400);
  }
});

it('derives departures and the last position from indexes and terminal evidence, not random event order', async () => {
  const jwt = await token();
  const inside = `${dateOf(1)}T12:00:00.000Z`;
  async function event(session: string, game: string, kind: string, extra: {id?: string; time?: string; item?: string; index?: number; outcome?: string; reason?: string; state?: string} = {}) {
    await env.DB.prepare(`INSERT INTO events(event_id, installation_id, session_id, game_id, content_version, timestamp_utc, kind, item_id, item_index, outcome, reason, item_state) VALUES (?, 'inst-order', ?, ?, 'v1', ?, ?, ?, ?, ?, ?, ?)`)
      .bind(extra.id ?? crypto.randomUUID(), session, game, extra.time ?? inside, kind, extra.item ?? null, extra.index ?? null, extra.outcome ?? null, extra.reason ?? null, extra.state ?? null).run();
  }
  // Shared timestamps everywhere; '0000-'/'zzzz-' IDs force the misleading sort order.
  await event('active', 'grammar', 'round_started');
  await event('active', 'grammar', 'item_shown', {item: 'a', index: 0});
  await event('active', 'grammar', 'item_answered', {item: 'a', index: 0, outcome: 'wrong'});
  await event('active', 'grammar', 'item_resolved', {item: 'a', index: 0});
  await event('active', 'grammar', 'item_shown', {item: 'b', index: 1, id: 'zzzz-active-b'});
  await event('active', 'grammar', 'item_shown', {item: 'c', index: 2, id: '0000-active-c'});
  await event('ended', 'spot', 'round_started');
  await event('ended', 'spot', 'item_shown', {item: 't0', index: 0, id: 'zzzz-ended-t0'});
  await event('ended', 'spot', 'item_shown', {item: 't1', index: 1});
  await event('ended', 'spot', 'round_ended', {item: 't1', index: 1, reason: 'timeout', state: 'unresolved', id: '0000-ended-end'});
  await event('sliced', 'vocabulary', 'round_started', {time: `${dateOf(3)}T12:00:00.000Z`});
  await event('sliced', 'vocabulary', 'item_shown', {item: 'v3', index: 3, time: `${dateOf(3)}T12:00:00.000Z`});
  await event('sliced', 'vocabulary', 'round_ended', {item: 'v3', index: 3, reason: 'inferred_interruption', state: 'unresolved'});
  await event('resumed', 'idioms', 'round_started');
  await event('resumed', 'idioms', 'item_shown', {item: 'r0', index: 0, id: 'zzzz-resumed-r0'});
  await event('resumed', 'idioms', 'item_shown', {item: 'r1', index: 1});
  await event('resumed', 'idioms', 'item_answered', {item: 'r1', index: 1, outcome: 'correct'});
  await event('resumed', 'idioms', 'item_resolved', {item: 'r1', index: 1});
  await event('resumed', 'idioms', 'round_ended', {item: 'r1', index: 1, reason: 'inferred_interruption', state: 'resolved', id: '0000-resumed-end'});
  await event('partial', 'grammar', 'round_started');
  await event('partial', 'grammar', 'item_shown', {item: 'p0', index: 0});
  await event('partial', 'grammar', 'item_resolved', {item: 'p0', index: 0});
  await event('partial', 'grammar', 'item_shown', {item: 'p1', index: 1});
  await event('partial', 'grammar', 'round_ended', {item: 'p1', index: 1, reason: 'user_back', state: 'unresolved', time: `${today}T00:00:00.000Z`});
  await event('unknown', 'spot', 'round_started');

  const body = await (await get(`/api/recent?from=${dateOf(2)}&to=${today}`, jwt)).json() as any;
  const session = (id: string) => body.sessions.find((s: any) => s.session === id);
  expect(session('active')).toMatchObject({status: 'in_progress', lastItem: 'c', lastIndex: 2, lastItemEvidence: 'observed'});
  expect(session('active').metrics).toMatchObject({shown: 3, resolved: 1, left: 1, openUnresolved: 1, wrong: 1});
  expect(session('active').items).toEqual(expect.arrayContaining([
    expect.objectContaining({id: 'b', left: 1, openUnresolved: 0}), expect.objectContaining({id: 'c', left: 0, openUnresolved: 1})]));
  expect(session('ended')).toMatchObject({status: 'timeout', lastItem: 't1', lastIndex: 1, lastItemEvidence: 'terminal'});
  expect(session('ended').metrics).toMatchObject({shown: 2, resolved: 0, left: 2, openUnresolved: 0});
  expect(session('sliced')).toMatchObject({missingStart: true, status: 'inferred_interruption', lastItem: 'v3', lastIndex: 3, lastItemEvidence: 'terminal'});
  expect(session('sliced').metrics).toMatchObject({shown: 0, left: 1, openUnresolved: 0, wrong: 0});
  expect(session('sliced').items).toEqual([expect.objectContaining({id: 'v3', terminalState: 'unresolved', shown: 0, left: 1})]);
  expect(session('resumed')).toMatchObject({status: 'inferred_interruption', lastItem: 'r1', lastIndex: 1, lastItemEvidence: 'terminal'});
  expect(session('resumed').metrics).toMatchObject({shown: 2, resolved: 1, correct: 1, left: 1, openUnresolved: 0});
  expect(session('partial')).toMatchObject({status: 'in_progress', lastItem: 'p1', lastIndex: 1, lastItemEvidence: 'observed'});
  expect(session('partial').metrics).toMatchObject({left: 0, openUnresolved: 1});
  expect(session('unknown')).toMatchObject({status: 'in_progress', lastItem: null, lastIndex: null, lastItemEvidence: null});
  expect(body.summary.grammar).toMatchObject({shown: 5, resolved: 2, left: 1, openUnresolved: 2, wrong: 1, inProgress: 2});

  const whole = await (await get(`/api/recent?from=${dateOf(2)}&to=${dateOf(-1)}&game=grammar&installation=inst-order`, jwt)).json() as any;
  expect(whole.sessions.find((s: any) => s.session === 'partial')).toMatchObject({status: 'user_back', lastItem: 'p1', lastItemEvidence: 'terminal',
    metrics: expect.objectContaining({left: 1, openUnresolved: 0})});
});

it('publishes only weeks a committed purge proves final, across rollback, retry and delayed cron', async () => {
  const start = Date.parse('2026-06-03T12:00:00.000Z');
  async function cohort(time: number, prefix: string) {
    const iso = new Date(time).toISOString();
    for (let i = 0; i < 5; i++) {
      await env.DB.prepare(`INSERT INTO events(event_id, installation_id, session_id, game_id, content_version, timestamp_utc, created_at, kind, item_id, item_index) VALUES (?, ?, ?, 'vocabulary', 'v1', ?, ?, 'item_shown', 'secret-item', 0)`)
        .bind(`${prefix}-${i}`, `inst-${i}`, `${prefix}-${i}`, iso, iso).run();
    }
  }
  const week = (time: number) => env.DB.prepare(`SELECT 'week:' || strftime('%Y-W%W', ?) AS bucket`).bind(new Date(time).toISOString()).first<string>('bucket');
  const history = async () => (await get('/api/history', await token())).json() as Promise<any>;
  vi.useFakeTimers({toFake: ['Date']});
  vi.setSystemTime(start);
  try {
    await cohort(start - 100*day, 'early');
    await cohort(start - 80*day, 'late');
    const early = await week(start - 100*day);
    const late = await week(start - 80*day);
    await env.DB.prepare("CREATE TRIGGER fail_report_purge BEFORE DELETE ON events BEGIN SELECT RAISE(ABORT, 'forced failure'); END").run();
    try {
      await expect(worker.scheduled({} as ScheduledEvent, env)).rejects.toThrow();
    } finally { await env.DB.prepare('DROP TRIGGER fail_report_purge').run(); }
    expect(await env.DB.prepare('SELECT COUNT(*) AS n FROM purge_marker').first()).toMatchObject({n: 0});
    expect(await history()).toMatchObject({published: false, buckets: [], weeks: []});

    await Promise.all([worker.scheduled({} as ScheduledEvent, env), worker.scheduled({} as ScheduledEvent, env)]);
    const first = await history();
    expect(first.published).toBe(true);
    expect(first.buckets).toHaveLength(52);
    expect(first.buckets).toContain(early);
    expect(first.buckets).not.toContain(late);
    expect(first.weeks).toEqual([expect.objectContaining({bucket: early, game: 'vocabulary', shown: 5, resolved: null, correct: null})]);
    expect(JSON.stringify(first)).not.toMatch(/day:|secret-item|inst-|early-/);

    // Cron delayed by 20 days: the late week is past the calendar horizon but not yet purged.
    vi.setSystemTime(start + 20*day);
    expect(await history()).toEqual(first);
    await worker.scheduled({} as ScheduledEvent, env);
    const second = await history();
    expect(second.buckets).toContain(late);
    expect(second.weeks).toContainEqual(expect.objectContaining({bucket: late, game: 'vocabulary', shown: 5}));
    expect(second.weeks).toContainEqual(first.weeks[0]);
  } finally {
    vi.useRealTimers();
  }
});

it('denies malformed claims, wrong algorithms, unknown keys, JWKS failures and bad configuration on every route', async () => {
  const noDb = {...config(), DB: {prepare() {throw new Error('DB accessed before authorization');}} as unknown as D1Database};
  const routes = [['GET', '/private'], ['GET', '/private/report'], ['GET', '/private/report/'], ['GET', '/private/report/app.js'],
    ['GET', '/private/report/api/recent?limit=1'], ['GET', '/private/report/api/history'], ['POST', '/private/report/api/recent'], ['GET', '/private/other']];
  const call = (method: string, path: string, jwt: string, settings: Env) =>
    worker.fetch(new Request(`https://example.test${path}`, {method, headers: {'Cf-Access-Jwt-Assertion': jwt}}), settings);
  const exp = Math.floor(Date.now()/1000)+600;
  const claims = {iss: issuer, aud: 'report-audience', exp, email: 'owner@example.test'};
  const {email: _email, ...noEmail} = claims;
  const {exp: _exp, ...noExp} = claims;
  const sign = (payload: Record<string, unknown>, alg = 'RS256', kid = 'fixture', key: CryptoKey | Uint8Array = keys.privateKey) =>
    new SignJWT(payload).setProtectedHeader({alg, kid}).sign(key);
  const b64 = (value: unknown) => btoa(JSON.stringify(value)).replace(/=+$/, '').replace(/\+/g, '-').replace(/\//g, '_');
  const denied = [
    await sign(noEmail), await sign(noExp), await sign({...claims, email: ['owner@example.test']}),
    await sign({...claims, nbf: exp}), await sign({...claims, aud: ['other']}),
    await sign(claims, 'HS256', 'fixture', new TextEncoder().encode('s'.repeat(32))),
    await sign(claims, 'PS256', 'fixture', (await generateKeyPair('PS256')).privateKey),
    await sign(claims, 'RS256', 'rotated-out'),
    `${b64({alg: 'none'})}.${b64(claims)}.`,
    `${(await token()).split('.').slice(0, 2).join('.')}.${'A'.repeat(342)}`,
    'x'.repeat(16385),
  ];
  for (const [method, path] of routes) {
    for (const jwt of denied) {
      const response = await call(method, path, jwt, noDb);
      expect(response.status).toBe(403);
      expect(response.headers.get('cache-control')).toBe('private, no-store');
    }
  }
  const valid = await token();
  for (const change of [
    {ACCESS_ISSUER: 'http://owner-test.cloudflareaccess.com'}, {ACCESS_ISSUER: `${issuer}.evil.test`}, {ACCESS_ISSUER: `${issuer}/`},
    {ACCESS_AUDIENCE: 'a'.repeat(257)}, {ACCESS_AUDIENCE: undefined}, {ACCESS_OWNER_EMAILS: 'not-an-email'},
    {ACCESS_OWNER_EMAILS: 'owner@example.test,'}, {ACCESS_OWNER_EMAILS: Array.from({length: 11}, (_, i) => `owner${i}@example.test`).join(',')},
  ]) {
    for (const [method, path] of routes) expect((await call(method, path, valid, {...noDb, ...change})).status).toBe(403);
  }
  const jwks = (host: string) => fetchMock.get(`https://${host}.cloudflareaccess.com`).intercept({path: '/cdn-cgi/access/certs'});
  jwks('jwks-down').reply(500, 'down').persist();
  jwks('jwks-garbage').reply(200, 'not json').persist();
  jwks('jwks-empty').reply(200, {keys: []}).persist();
  for (const host of ['jwks-down', 'jwks-garbage', 'jwks-empty', 'jwks-unreachable']) {
    const hostIssuer = `https://${host}.cloudflareaccess.com`;
    const jwt = await token({iss: hostIssuer});
    for (const [method, path] of routes) expect((await call(method, path, jwt, {...noDb, ACCESS_ISSUER: hostIssuer})).status).toBe(403);
  }
  // The fixture itself is valid, so the denials above are not fixture failures.
  expect((await call('GET', '/private/report/', valid, config())).status).toBe(200);
  expect((await call('GET', '/private', valid, config())).status).toBe(404);
  expect((await call('POST', '/private/report/api/recent', valid, config())).status).toBe(404);
});

it('bounds dates, limits, cursors, query size and retained rows', async () => {
  const jwt = await token();
  for (const query of [`from=${dateOf(91)}&to=${dateOf(85)}`, `to=${dateOf(-2)}`, `from=${dateOf(40)}&to=${dateOf(8)}`,
    `from=${dateOf(3)}&to=${dateOf(3)}`, `from=${dateOf(2)}&to=${dateOf(3)}`, 'from=2026-02-30', 'from=2026-1-01', 'to=tomorrow',
    'limit=0', 'limit=26', 'limit=1.5', 'limit=1&limit=2', 'cursor=not-json', `cursor=${encodeURIComponent('["a"]')}`,
    `cursor=${encodeURIComponent(JSON.stringify(['a', 'b', 'c', 'd', 1]))}`, `cursor=${encodeURIComponent(JSON.stringify(['a', 'b', 'c', 'd', 'x'.repeat(129)]))}`,
    `installation=${'i'.repeat(129)}`, `version=${'v'.repeat(65)}`, `game=spot&version=${'v'.repeat(2100)}`]) {
    expect((await get(`/api/recent?${query}`, jwt)).status).toBe(400);
  }
  expect((await get(`/api/recent?from=${dateOf(30)}&to=${dateOf(-1)}&limit=25`, jwt)).status).toBe(200);
  expect(await (await get('/api/recent', jwt)).json()).toMatchObject({from: `${dateOf(6)}T00:00:00.000Z`, toExclusive: `${dateOf(-1)}T00:00:00.000Z`});
  const insertMany = (count: number, prefix: string) => env.DB.prepare(`WITH RECURSIVE n(i) AS (SELECT 1 UNION ALL SELECT i + 1 FROM n WHERE i < ?)
    INSERT INTO events(event_id, installation_id, session_id, game_id, content_version, timestamp_utc, kind)
    SELECT ? || i, 'inst-cap', ? || i, 'grammar', 'v1', ?, 'round_started' FROM n`).bind(count, prefix, prefix, `${dateOf(1)}T12:00:00.000Z`).run();
  await insertMany(5000, 'cap-');
  const capped = await (await get('/api/recent', jwt)).json() as any;
  expect(capped.sessions).toHaveLength(25);
  expect(capped.summary.grammar.started).toBe(5000);
  expect(capped.nextCursor).not.toBeNull();
  await insertMany(1, 'over-');
  const over = await get('/api/recent', jwt);
  expect(over.status).toBe(422);
  expect(await over.text()).not.toContain('cap-');
});
