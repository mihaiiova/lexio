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
