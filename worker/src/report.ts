import { createRemoteJWKSet, jwtVerify } from 'jose';
import type { Env } from './index';
import { QueryError, recentReport } from './report_queries';

// One bounded, public-key-only cache; never retain tokens or owner identity.
let keyCache: {issuer: string; keys: ReturnType<typeof createRemoteJWKSet>} | undefined;
async function authorized(request: Request, env: Env): Promise<boolean> {
  const issuer = env.ACCESS_ISSUER ?? '';
  const audience = env.ACCESS_AUDIENCE ?? '';
  const owners = (env.ACCESS_OWNER_EMAILS ?? '').split(',').map(value => value.trim().toLowerCase());
  if (!/^https:\/\/[a-z0-9-]+\.cloudflareaccess\.com$/.test(issuer) || !audience || audience.length > 256 ||
      owners.length > 10 || owners.some(value => !/^[^\s@,]+@[^\s@,]+\.[^\s@,]+$/.test(value))) return false;
  const token = request.headers.get('Cf-Access-Jwt-Assertion');
  if (!token || token.length > 16384) return false;
  try {
    if (keyCache?.issuer !== issuer) keyCache = {issuer, keys: createRemoteJWKSet(new URL(`${issuer}/cdn-cgi/access/certs`), {
      timeoutDuration: 3000, cacheMaxAge: 300000, cooldownDuration: 30000,
    })};
    const {payload} = await jwtVerify(token, keyCache.keys, {issuer, audience, algorithms: ['RS256'], requiredClaims: ['exp', 'email']});
    return typeof payload.email === 'string' && owners.includes(payload.email.toLowerCase());
  } catch { return false; }
}
export function reportResponse(body: string, status = 200, type = 'application/json'): Response {
  return new Response(body, {status, headers: {
    'content-type': `${type}; charset=utf-8`, 'cache-control': 'private, no-store',
    'content-security-policy': "default-src 'none'; script-src 'self'; connect-src 'self'; form-action 'self'; base-uri 'none'; frame-ancestors 'none'",
    'x-content-type-options': 'nosniff', 'referrer-policy': 'no-referrer',
  }});
}
export async function handleReport(request: Request, env: Env): Promise<Response> {
  if (!await authorized(request, env)) return reportResponse('{"error":"Acces refuzat"}', 403);
  const path = new URL(request.url).pathname;
  if (request.method === 'GET' && ['/private/report', '/private/report/'].includes(path)) {
    return reportResponse('<!doctype html><html lang="ro"><meta charset="utf-8"><title>Raport privat</title><h1>Raport privat</h1></html>', 200, 'text/html');
  }
  if (request.method === 'GET' && path === '/private/report/api/recent') {
    try {
      const body = JSON.stringify(await recentReport(new URL(request.url), env));
      if (new TextEncoder().encode(body).length > 256000) throw new QueryError(422);
      return reportResponse(body);
    } catch (error) {
      return reportResponse('{"error":"Interogare indisponibilă. Restrângeți filtrele."}', error instanceof QueryError ? error.status : 503);
    }
  }
  return reportResponse('{"error":"Indisponibil"}', 404);
}
