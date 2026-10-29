ALTER TABLE events ADD COLUMN attempt_delta INTEGER;
ALTER TABLE events ADD COLUMN correct_discovery_delta INTEGER;
ALTER TABLE events ADD COLUMN distinct_wrong_delta INTEGER;
ALTER TABLE aggregates ADD COLUMN attempts INTEGER;
ALTER TABLE aggregates ADD COLUMN correct_discoveries INTEGER;
ALTER TABLE aggregates ADD COLUMN distinct_wrong_positions INTEGER;
