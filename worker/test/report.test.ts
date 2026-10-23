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
