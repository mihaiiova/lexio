# Log Format

Each review session writes one entry to `revision-log/`.

## File naming
`YYYY-MM-DD-<short-slug>.md` — date of review, slug summarizing the session.

## Template

```markdown
# Review: [context]
**Date:** YYYY-MM-DD
**Session:** [what was being developed]

## Scores
| Dimension | Score |
|-----------|-------|
| Friction | X.X |
| Repetition | X.X |
| Missing capability | X.X |
| Knowledge gap | X.X |
| Fragility | X.X |

## Suggestions
| # | Category | Suggestion | Score | Accepted? |
|---|----------|------------|-------|-----------|
| 1 | docs | ... | 0.X | ✅ |
| 2 | skills | ... | 0.X | ❌ |

## Changes Made
[Artifacts created/modified for each accepted suggestion — file paths, commits, issue links]

## Notes
[Rationale for rejections, decisions, follow-ups]
```
