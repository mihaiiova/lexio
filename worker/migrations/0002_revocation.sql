ALTER TABLE installations ADD COLUMN revoked_at TEXT;
ALTER TABLE installations ADD COLUMN last_seen_at TEXT;
UPDATE installations SET last_seen_at = created_at;
