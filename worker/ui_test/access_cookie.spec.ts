import {readFileSync} from 'node:fs';
import {createServer, type Server} from 'node:http';
import {test, expect, type Page} from '@playwright/test';

const policy = JSON.parse(readFileSync(new URL('../access_test_policy.json', import.meta.url), 'utf8'));

async function listen(server: Server): Promise<number> {
  await new Promise<void>((resolve, reject) => {
    server.once('error', reject);
    server.listen(0, '127.0.0.1', resolve);
  });
  const address = server.address();
  if (!address || typeof address === 'string') throw new Error('Expected a loopback port');
  return address.port;
}

async function probe(page: Page, sameSite: string, shouldSucceed: boolean) {
  let callbacks = 0;
  let reportOrigin = '';
  let identityOrigin = '';
  const identity = createServer((request, response) => {
    if (request.url === '/start') {
      response.writeHead(200, {'content-type':'text/html'});
      response.end(`<a id="login" href="${reportOrigin}/authorized">Continue</a>`);
    } else {
      response.writeHead(302, {location:`${reportOrigin}/authorized`});
      response.end();
    }
  });
  const report = createServer((request, response) => {
    if (request.url === '/authorized') {
      callbacks++;
      response.writeHead(302, {
        location:`${reportOrigin}/private/report/`,
        // Test-only cookie on loopback HTTP; never a real Access credential.
        'set-cookie':`fixture_auth=test-only; Path=/; HttpOnly; SameSite=${sameSite}`,
      });
      response.end();
    } else if (!request.headers.cookie?.includes('fixture_auth=test-only')) {
      response.writeHead(302, {location:`${identityOrigin}/continue`});
      response.end();
    } else {
      response.writeHead(200, {'content-type':'text/html'});
      response.end('<h1>Report loaded</h1>');
    }
  });
  try {
    identityOrigin = `http://127.0.0.1:${await listen(identity)}`;
    reportOrigin = `http://localhost:${await listen(report)}`;
    await page.goto(`${identityOrigin}/start`);
    let failure: unknown;
    try {
      await page.locator('#login').click({timeout:5000});
      await expect(page.getByRole('heading', {name:'Report loaded'})).toBeVisible({timeout:2000});
    } catch (error) {
      failure = error;
    }
    if (shouldSucceed) {
      expect(failure).toBeUndefined();
      expect(callbacks).toBe(1);
    } else {
      expect(failure).toBeDefined();
      expect(callbacks).toBeGreaterThan(1);
      await page.goto(`${reportOrigin}/private/report/`);
      await expect(page.getByRole('heading', {name:'Report loaded'})).toBeVisible();
    }
  } finally {
    await page.goto('about:blank');
    await Promise.all([
      new Promise<void>((resolve, reject) => identity.close(error => error ? reject(error) : resolve())),
      new Promise<void>((resolve, reject) => report.close(error => error ? reject(error) : resolve())),
    ]);
  }
}

test('configured test Access cookie completes fresh cross-site login', async ({page}) => {
  expect(policy.domain).toBe('analytics-test.didactiv.ro/private');
  expect(policy.same_site_cookie_attribute).toBe('lax');
  expect(policy.http_only_cookie_attribute).toBe(true);
  expect(policy.enable_binding_cookie).toBe(true);
  expect(policy.mfa_config.mfa_disabled).toBe(false);
  expect(policy.session_duration).toBe('1h');
  await probe(page, policy.same_site_cookie_attribute, true);
});

test('Strict reproduces the redirect loop while a direct refresh succeeds', async ({page}) => {
  await probe(page, 'strict', false);
});
