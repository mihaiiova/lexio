# Review: Issue #62 private analytics report
**Date:** 2026-10-23
**Session:** Completed owner-only reporting, protected Access paths, retained item/population metrics, canonical historical publication and browser checks.

## History Checked
- `2026-10-24-analytics-all-games.md`
- `2026-10-23-analytics-backend-safety.md`
- `2026-10-14-app-store-cover.md`
- `2026-10-07-separate-content-deployment.md`
- `2026-10-02-staging-play-upload.md`

## Recurring Patterns
- Explicit-path staging preserved the existing unrelated `.pi/` changes, as recorded in the October logs.
- No prior entry among these five documents the current external-runner tool-access mismatch; do not claim historical recurrence from the current session alone.

## Scores
| Dimension | Score |
|-----------|-------|
| Friction | 0.9 |
| Repetition | 0.6 |
| Missing capability | 0.6 |
| Knowledge gap | 0.4 |
| Fragility | 0.6 |

## Suggestions
| # | Category | Suggestion | Score | Accepted? |
|---|----------|------------|-------|-----------|
| 1 | prompts | Persist a self-contained source/diff/validation packet pattern for external CLI reviews whose effective tool access may be restricted. Current session: the first CLI reviewers could not inspect files, while inline source packets enabled evidence-backed reviews. | 0.9 | Pending; no shared skill/configuration edits authorized or made. |

## Changes Made
- Used temporary inline source packets as a task-recovery technique; no permanent process/model/permission configuration changes.
- Preserved all three user-owned `.pi/*.json` modifications through explicit staging.

## Notes
- The native implementation provider hit a usage limit after four checkpoint commits. The alternate CLI writer could edit product files but could not run checks or make commits; its returned completion was not treated as verified delivery.
- The first external review pair had no source tools. Their handoff-only reports were classified incomplete, not clean reviews or confirmed product findings. A later independent pair received actual numbered source inline; the behavioral gap they identified was reproduced and fixed before follow-up approval.
- Parent verification executed Flutter analysis/tests, Worker typecheck and real-migration handler tests, and real Chromium UI tests. Manual Access login, deployed migration, child/privacy/store review and production operations were not performed.
- Recovery edits were written before command execution was available; not every recovery test has observed red-first evidence. The late-ingestion publication fence, population item/end summaries, and applied-filter pagination regressions each have observed red and green runs.
- A committed purge marker alone did not fence ingestion requests validated before the purge. A failing delayed-request test established the need to check the marker inside the D1 insertion transaction. This permits immutable historical publication without exposing overlapping daily/item subsets.
- Per-session detail did not fulfill population-level item outcomes and ending locations. Added bounded filtered-window totals independently of pagination, preserving version separation and authoritative terminal positions.
- Pending process suggestion does not block the product work; persistent workflow changes require a separate user decision.
