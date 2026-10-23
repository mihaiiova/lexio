-- Unlinked singleton proof of the latest committed purge cutoff. It is written in
-- the same transactional batch as aggregation/removal; history publishes nothing
-- without it.
CREATE TABLE purge_marker (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  cutoff TEXT NOT NULL
);
