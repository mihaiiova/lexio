import type { Env } from './index';

const day = 86400000;
const games = ['grammar', 'vocabulary', 'idioms', 'spot'];
const maxEvents = 5000;
export class QueryError extends Error {
  constructor(readonly status = 400) { super('Unsupported report query'); }
}
function params(url: URL, allowed: string[]): URLSearchParams {
  if (url.search.length > 2048) throw new QueryError();
  for (const key of url.searchParams.keys()) {
    if (!allowed.includes(key) || url.searchParams.getAll(key).length !== 1 || !url.searchParams.get(key)) throw new QueryError();
  }
  return url.searchParams;
}
function date(value: string): number {
  const time = Date.parse(`${value}T00:00:00.000Z`);
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value) || !Number.isFinite(time) || new Date(time).toISOString().slice(0,10) !== value) throw new QueryError();
  return time;
}
interface EventRow {
  session_id: string; installation_id: string; game_id: string; content_version: string;
  item_id: string | null; item_index: number | null; timestamp_utc: string;
  kind: string; outcome: string | null; reason: string | null; item_state: string | null;
  attempt_delta: number | null; correct_discovery_delta: number | null; distinct_wrong_delta: number | null;
}
function counters() { return {started: 0, completed: 0, ended: 0, inProgress: 0, missingStart: 0, shown: 0, resolved: 0, left: 0, openUnresolved: 0, correct: 0, wrong: 0, attempts: 0, discoveries: 0, distinctWrong: 0}; }
type Counters = ReturnType<typeof counters>;
function itemCounters() {
  return {shown: 0, resolved: 0, left: 0, openUnresolved: 0, correct: 0, wrong: 0, attempts: 0, discoveries: 0, distinctWrong: 0};
}
type ItemTotal = ReturnType<typeof itemCounters> & {id: string; version: string};
interface EndingTotal {version: string; itemId: string | null; itemIndex: number | null; reason: string; count: number}
type Summary = Counters & {endedByReason: Record<string, number>; byItem: ItemTotal[]; endedAt: EndingTotal[]};
const maxSummaryGroups = 500;
interface Item {
  id: string; index: number; terminalState: string | null; shown: number; resolved: number; left: number; openUnresolved: number;
  correct: number; wrong: number; attempts: number; discoveries: number; distinctWrong: number;
}
interface Session {
  installation: string; session: string; game: string; version: string; lastActivity: string;
  lastItem: string | null; lastIndex: number | null; lastItemEvidence: 'terminal' | 'observed' | null;
  status: string; missingStart: boolean; metrics: Counters; items: Item[];
}
function sessionKey(s: Session): string { return JSON.stringify([s.lastActivity, s.installation, s.session, s.game, s.version]); }
export async function recentReport(url: URL, env: Env): Promise<unknown> {
  const p = params(url, ['from', 'to', 'game', 'version', 'installation', 'limit', 'cursor']);
  const now = Date.now();
  const cutoff = new Date(now - 90 * day).toISOString();
  const to = p.has('to') ? date(p.get('to')!) : date(new Date(now).toISOString().slice(0,10)) + day;
  const from = p.has('from') ? date(p.get('from')!) : to - 7 * day;
  if (from >= to || to - from > 31 * day || from < date(cutoff.slice(0,10)) || to > date(new Date(now).toISOString().slice(0,10)) + day) throw new QueryError();
  const limit = p.has('limit') ? Number(p.get('limit')) : 25;
  if (!Number.isInteger(limit) || limit < 1 || limit > 25) throw new QueryError();
  const clauses = ['timestamp_utc > ?', 'created_at > ?', 'timestamp_utc >= ?', 'timestamp_utc < ?'];
  const values: (string | number)[] = [cutoff, cutoff, new Date(from).toISOString(), new Date(to).toISOString()];
  for (const [param, column, max] of [['game', 'game_id', 64], ['version', 'content_version', 64], ['installation', 'installation_id', 128]] as const) {
    const value = p.get(param);
    if (value !== null) {
      if (value.length > max || (param === 'game' && !games.includes(value))) throw new QueryError();
      clauses.push(`${column} = ?`); values.push(value);
    }
  }
  let cursor: string | null = p.get('cursor');
  if (cursor !== null) {
    try {
      const decoded: unknown = JSON.parse(cursor);
      if (!Array.isArray(decoded) || decoded.length !== 5 || decoded.some(v => typeof v !== 'string' || v.length > 128)) throw new QueryError();
      cursor = JSON.stringify(decoded);
    } catch { throw new QueryError(); }
  }
  // Index-bounded window, hard input cap, no credential-table inventory or joins.
  const {results} = await env.DB.prepare(`SELECT session_id, installation_id, game_id, content_version, item_id, item_index,
    timestamp_utc, kind, outcome, reason, item_state, attempt_delta, correct_discovery_delta, distinct_wrong_delta
    FROM events WHERE ${clauses.join(' AND ')} ORDER BY timestamp_utc, event_id LIMIT ?`).bind(...values, maxEvents + 1).all<EventRow>();
  if (results.length > maxEvents) throw new QueryError(422);
  // Event IDs are random, so equal timestamps carry no order; departure and the
  // last position come only from round indexes and the terminal event.
  const rounds = new Map<string, {s: Session; ended: boolean; terminal: Item | null}>();
  for (const e of results) {
    const key = JSON.stringify([e.installation_id, e.session_id, e.game_id, e.content_version]);
    let round = rounds.get(key);
    if (!round) {
      round = {ended: false, terminal: null, s: {installation: e.installation_id, session: e.session_id, game: e.game_id, version: e.content_version,
        lastActivity: e.timestamp_utc, lastItem: null, lastIndex: null, lastItemEvidence: null, status: 'in_progress', missingStart: true, metrics: counters(), items: []}};
      rounds.set(key, round);
    }
    const s = round.s;
    s.lastActivity = e.timestamp_utc;
    if (e.kind === 'round_started') { s.metrics.started++; s.missingStart = false; }
    if (e.kind === 'round_ended') { round.ended = true; s.status = e.reason ?? 'unknown'; s.metrics.ended++; if (e.reason === 'completed') s.metrics.completed++; }
    if (e.item_id !== null && e.item_index !== null) {
      let item = s.items.find(i => i.id === e.item_id && i.index === e.item_index);
      if (!item) {
        item = {id: e.item_id, index: e.item_index, terminalState: null, shown: 0, resolved: 0, left: 0, openUnresolved: 0, correct: 0, wrong: 0, attempts: 0, discoveries: 0, distinctWrong: 0};
        s.items.push(item);
      }
      if (e.kind === 'round_ended') { item.terminalState = e.item_state; round.terminal = item; }
      if (e.kind === 'item_shown') item.shown++;
      if (e.kind === 'item_resolved') item.resolved++;
      if (e.kind === 'item_answered' && e.game_id !== 'spot') {
        if (e.outcome === 'correct') item.correct++;
        if (e.outcome === 'wrong') item.wrong++;
      }
      if (e.kind === 'spot_attempt' && e.game_id === 'spot') {
        item.attempts += e.attempt_delta ?? 0; item.discoveries += e.correct_discovery_delta ?? 0; item.distinctWrong += e.distinct_wrong_delta ?? 0;
      }
    }
  }
  const summary: Record<string, Summary> = {};
  const itemTotals = new Map<string, ItemTotal>();
  const endingTotals = new Map<string, EndingTotal>();
  const sessions: Session[] = [];
  for (const {s, ended, terminal} of rounds.values()) {
    sessions.push(s);
    s.metrics.inProgress = s.status === 'in_progress' ? 1 : 0;
    s.metrics.missingStart = s.missingStart ? 1 : 0;
    const frontier = s.items.reduce((max, i) => i.shown > 0 || i === terminal ? Math.max(max, i.index) : max, -1);
    for (const item of s.items) {
      // Unfinished current work is not a departure; unresolved is never wrong.
      if (item.resolved === 0 && item.terminalState !== 'resolved') {
        if (item.terminalState === 'unresolved') item.left = 1;
        else if (item.shown > 0 && (ended || item.index < frontier)) item.left = 1;
        else if (item.shown > 0) item.openUnresolved = 1;
      }
      for (const key of ['shown', 'resolved', 'left', 'openUnresolved', 'correct', 'wrong', 'attempts', 'discoveries', 'distinctWrong'] as const) s.metrics[key] += item[key];
    }
    const latest = terminal ?? s.items.reduce<Item | null>((best, i) =>
      best === null || i.index > best.index || (i.index === best.index && i.id > best.id) ? i : best, null);
    s.lastItem = latest?.id ?? null;
    s.lastIndex = latest?.index ?? null;
    s.lastItemEvidence = terminal ? 'terminal' : latest ? 'observed' : null;
    const total = summary[s.game] ??= {...counters(), endedByReason: {}, byItem: [], endedAt: []};
    for (const key of Object.keys(s.metrics) as (keyof Counters)[]) total[key] += s.metrics[key];
    for (const item of s.items) {
      const key = JSON.stringify([s.game, s.version, item.id]);
      let aggregate = itemTotals.get(key);
      if (!aggregate) {
        if (itemTotals.size >= maxSummaryGroups) throw new QueryError(422);
        aggregate = {...itemCounters(), id: item.id, version: s.version};
        itemTotals.set(key, aggregate);
        total.byItem.push(aggregate);
      }
      for (const metric of Object.keys(itemCounters()) as (keyof ReturnType<typeof itemCounters>)[]) aggregate[metric] += item[metric];
    }
    if (ended) {
      total.endedByReason[s.status] = (total.endedByReason[s.status] ?? 0) + 1;
      const key = JSON.stringify([s.game, s.version, terminal?.id ?? null, terminal?.index ?? null, s.status]);
      let aggregate = endingTotals.get(key);
      if (!aggregate) {
        if (endingTotals.size >= maxSummaryGroups) throw new QueryError(422);
        aggregate = {version: s.version, itemId: terminal?.id ?? null, itemIndex: terminal?.index ?? null, reason: s.status, count: 0};
        endingTotals.set(key, aggregate);
        total.endedAt.push(aggregate);
      }
      aggregate.count++;
    }
  }
  const sorted = sessions.sort((a,b) => sessionKey(a) < sessionKey(b) ? 1 : sessionKey(a) > sessionKey(b) ? -1 : 0);
  const eligible = cursor === null ? sorted : sorted.filter(s => sessionKey(s) < cursor!);
  const page = eligible.slice(0, limit);
  return {scope: 'opted_in_only', from: new Date(from).toISOString(), toExclusive: new Date(to).toISOString(), summary,
    sessions: page, nextCursor: eligible.length > limit ? sessionKey(page[page.length-1]) : null};
}

function weekBucket(time: number): string {
  const d = new Date(time);
  const year = d.getUTCFullYear();
  const first = Date.UTC(year, 0, 1);
  const firstMonday = first + ((8-new Date(first).getUTCDay())%7)*day;
  const week = time < firstMonday ? 0 : Math.floor((time-firstMonday)/(7*day))+1;
  return `week:${year}-W${String(week).padStart(2,'0')}`;
}
export async function historicalReport(url: URL, env: Env): Promise<unknown> {
  // One canonical surface: no day/item partitions, ranges, totals, or version/installation subsets.
  params(url, []);
  // The ingestion INSERT checks the committed cutoff inside its D1 transaction,
  // so requests validated earlier cannot append behind the publication boundary.
  // Keep a conservative one-day publication buffer in addition to that fence.
  const marker = await env.DB.prepare('SELECT cutoff FROM purge_marker WHERE id = 1').first<string>('cutoff');
  if (marker === null) return {scope:'opted_in_only', published:false, partial:true, buckets:[], weeks:[]};
  const cutoff = Date.parse(marker) - day;
  if (!Number.isFinite(cutoff)) throw new QueryError(503);
  const current = weekBucket(cutoff);
  const buckets: string[] = [];
  for (let time = date(new Date(cutoff).toISOString().slice(0,10)); buckets.length < 52; time -= day) {
    const bucket = weekBucket(time);
    if (bucket !== current && !buckets.includes(bucket)) buckets.push(bucket);
  }
  interface AggregateRow {bucket: string; game_id: string; kind: string; outcome: string; count: number; attempts: number | null; discoveries: number | null; distinctWrong: number | null}
  const {results} = await env.DB.prepare(`SELECT bucket, game_id, kind, outcome, SUM(count) AS count,
    CASE WHEN COUNT(attempts) = COUNT(*) THEN SUM(attempts) ELSE NULL END AS attempts,
    CASE WHEN COUNT(correct_discoveries) = COUNT(*) THEN SUM(correct_discoveries) ELSE NULL END AS discoveries,
    CASE WHEN COUNT(distinct_wrong_positions) = COUNT(*) THEN SUM(distinct_wrong_positions) ELSE NULL END AS distinctWrong
    FROM aggregates WHERE scope = 'overall' AND bucket IN (${buckets.map(() => '?').join(',')})
    GROUP BY bucket, game_id, kind, outcome ORDER BY bucket DESC, game_id, kind, outcome LIMIT 5001`).bind(...buckets).all<AggregateRow>();
  if (results.length > 5000) throw new QueryError(422);
  interface Week {bucket: string; game: string; partial: true; started: number | null; ended: number | null; shown: number | null; resolved: number | null; correct: number | null; wrong: number | null; attempts: number | null; discoveries: number | null; distinctWrong: number | null}
  const weeks = new Map<string, Week>();
  for (const row of results) {
    const key = JSON.stringify([row.bucket,row.game_id]);
    let w = weeks.get(key);
    if (!w) {
      w = {bucket:row.bucket,game:row.game_id,partial:true,started:null,ended:null,shown:null,resolved:null,correct:null,wrong:null,attempts:null,discoveries:null,distinctWrong:null};
      weeks.set(key,w);
    }
    const metric = ({round_started:'started',round_ended:'ended',item_shown:'shown',item_resolved:'resolved'} as const)[row.kind as 'round_started'];
    if (metric) w[metric] = (w[metric] ?? 0) + row.count;
    if (row.kind === 'item_answered' && row.game_id !== 'spot') {
      if (row.outcome === 'correct') w.correct = (w.correct ?? 0)+row.count;
      if (row.outcome === 'wrong') w.wrong = (w.wrong ?? 0)+row.count;
    }
    if (row.kind === 'spot_attempt') { w.attempts = row.attempts; w.discoveries = row.discoveries; w.distinctWrong = row.distinctWrong; }
  }
  return {scope:'opted_in_only', published:true, partial:true, buckets, weeks:[...weeks.values()]};
}
