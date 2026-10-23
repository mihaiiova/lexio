// Bounded schema validation for analytics events.
//
// The event shape mirrors the Flutter client's versioned contract: stable
// identifiers and bounded outcomes only, with no raw content or free-form
// payload fields.

export const SCHEMA_VERSION = 1;
export const MAX_PAYLOAD_BYTES = 60_000;
export const MAX_EVENTS_PER_BATCH = 100;
export const MAX_ID_LENGTH = 128;
export const MAX_GAME_ID_LENGTH = 64;
export const MAX_CONTENT_VERSION_LENGTH = 64;

export const EVENT_KINDS = [
  'round_started',
  'item_shown',
  'item_answered',
  'item_resolved',
  'round_ended',
] as const;
export type EventKind = (typeof EVENT_KINDS)[number];

export const OUTCOMES = ['correct', 'wrong'] as const;
export type Outcome = (typeof OUTCOMES)[number];

export const ROUND_END_REASONS = [
  'completed',
  'user_back',
  'restart',
  'inferred_interruption',
] as const;
export type RoundEndReason = (typeof ROUND_END_REASONS)[number];

export interface AnalyticsEvent {
  v: number;
  eventId: string;
  sessionId: string;
  installationId: string;
  gameId: string;
  contentVersion: string;
  itemId: string | null;
  itemIndex: number | null;
  timestampUtc: string;
  kind: EventKind;
  outcome: Outcome | null;
  reason: RoundEndReason | null;
  itemState: 'resolved' | 'unresolved' | null;
}

export type ValidationResult =
  | { ok: true; event: AnalyticsEvent }
  | { ok: false; error: string };

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

function isNonEmptyString(value: unknown, maxLength: number): value is string {
  return (
    typeof value === 'string' &&
    value.length > 0 &&
    value.length <= maxLength
  );
}

function isBoundedInt(value: unknown): value is number {
  return typeof value === 'number' && Number.isInteger(value) && value >= 0 && value <= 10000;
}

function isIsoUtcTimestamp(value: unknown): value is string {
  if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}(?:\d{3})?Z$/.test(value)) return false;
  const parsed = Date.parse(value);
  if (!Number.isFinite(parsed)) return false;
  const canonical = value.slice(0, 23) + 'Z';
  return new Date(parsed).toISOString() === canonical &&
    parsed >= Date.now() - 90 * 86400000 && parsed <= Date.now() + 5 * 60000;
}

export function validateEvent(raw: unknown): ValidationResult {
  if (!isRecord(raw)) {
    return { ok: false, error: 'event must be an object' };
  }

  const fields = ['v', 'eventId', 'sessionId', 'installationId', 'gameId', 'contentVersion', 'timestampUtc', 'kind', 'itemId', 'itemIndex', 'outcome', 'reason', 'itemState'];
  if (Object.keys(raw).some(key => !fields.includes(key))) return {ok: false, error: 'unknown field'};
  if (raw.v !== SCHEMA_VERSION) {
    return { ok: false, error: 'unsupported schema version' };
  }

  const required = [
    'eventId',
    'sessionId',
    'installationId',
    'gameId',
    'contentVersion',
    'timestampUtc',
    'kind',
  ] as const;
  for (const key of required) {
    if (!(key in raw)) {
      return { ok: false, error: `missing field ${key}` };
    }
  }

  if (!isNonEmptyString(raw.eventId, MAX_ID_LENGTH)) {
    return { ok: false, error: 'eventId must be 1..128 characters' };
  }
  if (!isNonEmptyString(raw.sessionId, MAX_ID_LENGTH)) {
    return { ok: false, error: 'sessionId must be 1..128 characters' };
  }
  if (!isNonEmptyString(raw.installationId, MAX_ID_LENGTH)) {
    return { ok: false, error: 'installationId must be 1..128 characters' };
  }
  if (raw.gameId !== 'grammar') {
    return { ok: false, error: 'gameId must be 1..64 characters' };
  }
  if (!isNonEmptyString(raw.contentVersion, MAX_CONTENT_VERSION_LENGTH)) {
    return { ok: false, error: 'contentVersion must be 1..64 characters' };
  }
  if (!isIsoUtcTimestamp(raw.timestampUtc)) {
    return { ok: false, error: 'timestampUtc must be an ISO-8601 timestamp' };
  }

  if (!EVENT_KINDS.includes(raw.kind as EventKind)) {
    return { ok: false, error: 'unknown event kind' };
  }
  const kind = raw.kind as EventKind;

  if (raw.itemId !== null && raw.itemId !== undefined) {
    if (!isNonEmptyString(raw.itemId, MAX_ID_LENGTH)) {
      return { ok: false, error: 'itemId must be 1..128 characters' };
    }
  }
  if (raw.itemIndex !== null && raw.itemIndex !== undefined) {
    if (!isBoundedInt(raw.itemIndex)) {
      return { ok: false, error: 'itemIndex must be a non-negative integer' };
    }
  }

  if (raw.outcome !== null && raw.outcome !== undefined) {
    if (!OUTCOMES.includes(raw.outcome as Outcome)) {
      return { ok: false, error: 'unknown outcome' };
    }
  }
  if (raw.reason !== null && raw.reason !== undefined) {
    if (!ROUND_END_REASONS.includes(raw.reason as RoundEndReason)) {
      return { ok: false, error: 'unknown round end reason' };
    }
  }

  const itemId = (raw.itemId as string | null) ?? null;
  const itemIndex = (raw.itemIndex as number | null) ?? null;
  const outcome = (raw.outcome as Outcome | null) ?? null;
  const reason = (raw.reason as RoundEndReason | null) ?? null;

  const itemState = raw.itemState ?? null;
  if (itemState !== null && itemState !== 'resolved' && itemState !== 'unresolved') return {ok: false, error: 'invalid itemState'};
  if ((itemId === null) !== (itemIndex === null)) return {ok: false, error: 'incomplete item'};
  if (kind !== 'round_ended' && itemState !== null) return {ok: false, error: 'nonterminal itemState'};
  if (kind === 'round_ended' && ((itemId === null) !== (itemState === null))) return {ok: false, error: 'terminal itemState required with item'};

  if (kind === 'round_started') {
    if (itemId !== null || itemIndex !== null || outcome !== null || reason !== null) {
      return { ok: false, error: 'round_started must not carry item or outcome fields' };
    }
  } else if ((kind === 'item_shown' || kind === 'item_resolved')) {
    if (itemId === null || itemIndex === null || outcome !== null || reason !== null) {
      return { ok: false, error: 'item_shown requires itemId and itemIndex only' };
    }
  } else if (kind === 'item_answered') {
    if (itemId === null || itemIndex === null || outcome === null || reason !== null) {
      return { ok: false, error: 'item_answered requires itemId, itemIndex and outcome' };
    }
  } else if (kind === 'round_ended') {
    if (reason === null || outcome !== null) {
      return { ok: false, error: 'round_ended requires a reason and no outcome' };
    }
  }

  return {
    ok: true,
    event: {
      v: raw.v as number,
      eventId: raw.eventId as string,
      sessionId: raw.sessionId as string,
      installationId: raw.installationId as string,
      gameId: raw.gameId as string,
      contentVersion: raw.contentVersion as string,
      itemId,
      itemIndex,
      timestampUtc: raw.timestampUtc as string,
      kind,
      outcome,
      reason,
      itemState,
    },
  };
}
