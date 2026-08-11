# Review: Release docs cleanup + review skill
**Date:** 2026-08-11
**Session:** Set up dart-mcp-server in pi, create GitHub Issues from release docs, clean up markdown tracking docs, build review skill with writing-great-skills applied in v2.

## Scores
| Dimension | Score |
|-----------|-------|
| Friction | 0.4 |
| Repetition | 0.2 |
| Missing capability | 0.65 |
| Knowledge gap | 0.3 |
| Fragility | 0.3 |

## Suggestions
| # | Category | Suggestion | Score | Accepted? |
|---|----------|------------|-------|-----------|
| 1 | documentation | Add note to AGENTS.md to load writing-great-skills before creating/editing skills | 0.65 | ❌ |

## Changes Made
- Created `.mcp.json` with dart-mcp-server (lazy lifecycle)
- Created GitHub Issues #24–#35 for release tracking
- Trimmed `RELEASE_READINESS_REPORT.md` from 95→25 lines (now points to issues)
- Updated `ROADMAP.md` v1.1 checklist with issue links
- Added tracking-issue headers to `SMOKE_TEST_CHECKLIST.md` and `EDITORIAL_REVIEW.md`
- Added "Project Organization" section to `AGENTS.md`
- Built `.pi/skills/review/SKILL.md` + `LOG_FORMAT.md`
- Created `revision-log/` directory

## Notes
- Suggestion #1 rejected: adding per-skill load instructions to AGENTS.md is sediment. The review skill itself is the systemic fix — it catches missing-capability patterns in future sessions without per-skill documentation.
