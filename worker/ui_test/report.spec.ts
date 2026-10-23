import {test, expect} from '@playwright/test';
const metrics = {started:1,completed:0,ended:0,inProgress:1,missingStart:0,shown:1,resolved:0,left:0,openUnresolved:1,correct:0,wrong:0,attempts:4,discoveries:1,distinctWrong:1};
const malicious = '<img src=x onerror="window.injected=true">';
test('filters, installation drilldown, summary units and safe in-progress rendering', async ({page}) => {
  const urls: URL[] = [];
  await page.route('**/api/recent*', route => {
    urls.push(new URL(route.request().url()));
    return route.fulfill({json:{summary:{spot:{...metrics,endedByReason:{}}},sessions:[{installation:malicious,session:'s1',game:'spot',version:'v1',lastActivity:'2026-10-22T01:00:00.000Z',lastItem:malicious,lastIndex:0,lastItemEvidence:'observed',status:'in_progress',missingStart:true,metrics,items:[{id:malicious,index:0,terminalState:null,...metrics}]}],nextCursor:null}});
  });
  await page.goto('/private/report/');
  await expect(page.getByRole('heading',{name:'General — numai instalări cu acord'})).toBeVisible();
  await expect(page.getByText('În desfășurare / final necunoscut', {exact:false})).toBeVisible();
  await expect(page.getByText('Apăsări acceptate: 4', {exact:false}).first()).toBeVisible();
  await expect(page.getByText('Descoperiri distincte: 1', {exact:false}).first()).toBeVisible();
  await expect(page.getByText('Poziții greșite distincte pe rundă: 1', {exact:false}).first()).toBeVisible();
  await expect(page.getByText('Fără rezolvare, fără plecare sau final observat — stare necunoscută: 1').first()).toBeVisible();
  await expect(page.getByText('Plecări fără rezolvare (item următor sau final observat): 0').first()).toBeVisible();
  await expect(page.getByText('(cel mai mare index observat în interval; finalul poate lipsi)', {exact:false})).toBeVisible();
  await page.getByLabel('De la (UTC, inclusiv)').fill('2026-10-01');
  await page.getByLabel('Până la (UTC, exclusiv)').fill('2026-10-20');
  await page.getByLabel('Joc').selectOption('spot');
  await page.getByLabel('Versiune conținut').fill('v1');
  await page.getByRole('button',{name:'Aplică filtrele'}).click();
  await expect.poll(() => urls.at(-1)?.searchParams.get('from')).toBe('2026-10-01');
  expect(urls.at(-1)?.searchParams.get('to')).toBe('2026-10-20');
  expect(urls.at(-1)?.searchParams.get('game')).toBe('spot');
  expect(urls.at(-1)?.searchParams.get('version')).toBe('v1');
  await page.getByRole('button',{name:'Vezi această instalare'}).click();
  await expect.poll(() => urls.at(-1)?.searchParams.get('installation')).toBe(malicious);
  expect(await page.evaluate(() => (window as any).injected)).toBeUndefined();
  await expect(page.locator('img')).toHaveCount(0);
});
test('empty, denied and historical suppression are explicit', async ({page}) => {
  await page.route('**/api/recent*', r => r.fulfill({json:{summary:{},sessions:[],nextCursor:null}}));
  await page.route('**/api/history', r => r.fulfill({json:{published:true,partial:true,weeks:[{bucket:'week:2026-W20',game:'spot',partial:true,shown:6,attempts:6,discoveries:null,distinctWrong:null}]}}));
  await page.goto('/private/report/');
  await expect(page.getByText('Nu există sesiuni în interval.')).toBeVisible();
  await page.getByRole('button',{name:'Istoric săptămânal fix'}).click();
  await expect(page.getByText('Descoperiri distincte: suprimat / necunoscut', {exact:false})).toBeVisible();
  await page.route('**/api/recent*', r => r.fulfill({status:403,json:{error:'Acces refuzat'}}));
  await page.getByRole('button',{name:'Aplică filtrele'}).click();
  await expect(page.getByRole('status')).toHaveText('Acces refuzat. Autentificați-vă din nou prin Access.');
});
test('pagination keeps filters and labels terminal-only unresolved items honestly', async ({page}) => {
  const urls: URL[] = [];
  const ended = {...metrics,inProgress:0,ended:1,shown:0,left:1,openUnresolved:0};
  const session = (id: string) => ({installation:'i1',session:id,game:'grammar',version:'v1',lastActivity:'2026-10-22T01:00:00.000Z',
    lastItem:'g7',lastIndex:7,lastItemEvidence:'terminal',status:'inferred_interruption',missingStart:true,metrics:ended,
    items:[{id:'g7',index:7,terminalState:'unresolved',...ended}]});
  await page.route('**/api/recent*', route => {
    const url = new URL(route.request().url());
    urls.push(url);
    return route.fulfill({json: url.searchParams.has('cursor')
      ? {summary:{},sessions:[session('page-two')],nextCursor:null}
      : {summary:{},sessions:[session('page-one')],nextCursor:'["c1"]'}});
  });
  await page.goto('/private/report/');
  await page.getByLabel('Joc').selectOption('grammar');
  await page.getByRole('button',{name:'Aplică filtrele'}).click();
  await expect(page.getByText('Sesiune: page-one', {exact:false})).toBeVisible();
  await expect(page.getByText('Ultimul item: g7 · Index: 7 (din evenimentul final)', {exact:false})).toBeVisible();
  await page.getByText('Detalii pe item', {exact:false}).click();
  await expect(page.getByText('Stare la final: nerezolvat (nu greșit)')).toBeVisible();
  await expect(page.getByText('Afișarea nu apare în interval și nu este numărată.')).toBeVisible();
  await page.getByRole('button',{name:'Pagina următoare'}).click();
  await expect(page.getByText('Sesiune: page-two', {exact:false})).toBeVisible();
  expect(urls.at(-1)?.searchParams.get('cursor')).toBe('["c1"]');
  expect(urls.at(-1)?.searchParams.get('game')).toBe('grammar');
  await expect(page.getByRole('button',{name:'Pagina următoare'})).toBeHidden();
});
test('history stays unpublished without a committed purge', async ({page}) => {
  await page.route('**/api/recent*', r => r.fulfill({json:{summary:{},sessions:[],nextCursor:null}}));
  await page.route('**/api/history', r => r.fulfill({json:{published:false,partial:true,buckets:[],weeks:[]}}));
  await page.goto('/private/report/');
  await page.getByRole('button',{name:'Istoric săptămânal fix'}).click();
  await expect(page.getByText('Istoric nepublicat', {exact:false})).toBeVisible();
  await expect(page.getByText('Nu există celule istorice publicabile.')).toHaveCount(0);
});
