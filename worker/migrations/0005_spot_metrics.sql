ALTER TABLE events ADD COLUMN attempt_delta INTEGER;
ALTER TABLE events ADD COLUMN correct_discovery_delta INTEGER;
ALTER TABLE events ADD COLUMN distinct_wrong_delta INTEGER;
ALTER TABLE aggregates ADD COLUMN attempts INTEGER NOT NULL DEFAULT 0;
ALTER TABLE aggregates ADD COLUMN correct_discoveries INTEGER NOT NULL DEFAULT 0;
ALTER TABLE aggregates ADD COLUMN distinct_wrong_positions INTEGER NOT NULL DEFAULT 0;
