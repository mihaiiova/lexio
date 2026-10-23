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
