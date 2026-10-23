-- Slove analytics D1 schema.
-- Linked event records are retained for 90 days, then purged into non-linkable
-- aggregate day/week counts. Deletion secrets are stored only as SHA-256 hashes.

CREATE TABLE IF NOT EXISTS events (
  event_id TEXT PRIMARY KEY,
  session_id TEXT NOT NULL,
  installation_id TEXT NOT NULL,
  game_id TEXT NOT NULL,
  content_version TEXT NOT NULL,
  item_id TEXT,
  item_index INTEGER,
  timestamp_utc TEXT NOT NULL,
  kind TEXT NOT NULL,
  outcome TEXT,
  reason TEXT,
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);

CREATE INDEX IF NOT EXISTS idx_events_installation
  ON events(installation_id, created_at);
CREATE INDEX IF NOT EXISTS idx_events_timestamp
  ON events(timestamp_utc);

CREATE TABLE IF NOT EXISTS installations (
  installation_id TEXT PRIMARY KEY,
  deletion_secret_hash TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);

CREATE TABLE IF NOT EXISTS aggregates (
  bucket TEXT NOT NULL,
  game_id TEXT NOT NULL,
  kind TEXT NOT NULL,
  count INTEGER NOT NULL,
  PRIMARY KEY (bucket, game_id, kind)
);
ALTER TABLE installations ADD COLUMN revoked_at TEXT;
ALTER TABLE installations ADD COLUMN last_seen_at TEXT;
UPDATE installations SET last_seen_at = created_at;
ALTER TABLE events ADD COLUMN item_state TEXT;
-- Earlier unreleased aggregates used an event-count privacy threshold and must
-- not be carried forward as installation-thresholded data.
DROP TABLE aggregates;
CREATE TABLE aggregates (
  bucket TEXT NOT NULL,
  scope TEXT NOT NULL,
  game_id TEXT NOT NULL,
  kind TEXT NOT NULL,
  content_version TEXT NOT NULL,
  item_id TEXT NOT NULL,
  item_index INTEGER NOT NULL,
  outcome TEXT NOT NULL,
  reason TEXT NOT NULL,
  item_state TEXT NOT NULL,
  count INTEGER NOT NULL,
  PRIMARY KEY (bucket, scope, game_id, kind, content_version, item_id, item_index, outcome, reason, item_state)
);
ALTER TABLE events ADD COLUMN attempt_delta INTEGER;
ALTER TABLE events ADD COLUMN correct_discovery_delta INTEGER;
ALTER TABLE events ADD COLUMN distinct_wrong_delta INTEGER;
ALTER TABLE aggregates ADD COLUMN attempts INTEGER;
ALTER TABLE aggregates ADD COLUMN correct_discoveries INTEGER;
ALTER TABLE aggregates ADD COLUMN distinct_wrong_positions INTEGER;
