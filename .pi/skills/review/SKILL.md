---
name: review
description: Post-development retrospective. Use when the user finishes a feature, wraps up a round, or says review. Scores the conversation for friction, repetition, missing capabilities, knowledge gaps, and fragility — then implements concrete improvements.
---

# Review

At the end of a development round, review the conversation and fix how we work. The scope is process, tools, organization, documentation, and architecture — not product features.

## Steps

### 1. Score the conversation
Rate each dimension 0.0–1.0. Only dimensions scoring > 0.6 produce a suggestion.

**Friction** — time lost to missing tools, unclear code, poor discoverability, cumbersome workflows.
- 0.0–0.3: smooth, not worth fixing
- 0.6: spent significant time fighting something a change would fix
- 0.8+: major time sink

**Repetition** — same action, explanation, or pattern repeated unnecessarily.
- 0.0–0.3: minimal
- 0.6: same thing 3+ times, could be automated or documented
- 0.8+: pervasive

**Missing capability** — a skill, MCP server, or tool would have materially improved outcomes.
- 0.0–0.3: everything available
- 0.6: a nameable capability would have saved substantial effort
- 0.8+: absence fundamentally limited what was possible

**Knowledge gap** — missing or unclear docs, architecture decisions, or conventions caused confusion.
- 0.0–0.3: everything clear
- 0.6: had to rediscover something that should have been documented
- 0.8+: significant time lost to missing project knowledge

**Fragility** — something works now but is likely to break or block future work.
- 0.0–0.3: no concerns
- 0.6: identifiable risk with a concrete trigger
- 0.8+: likely to cause problems in 1–2 rounds

### 2. Report suggestions
For each dimension scoring > 0.6, present one concrete suggestion:

```
## Review: [context]

| Dimension | Score |
|-----------|-------|
| Friction | X.X |
| Repetition | X.X |
| Missing capability | X.X |
| Knowledge gap | X.X |
| Fragility | X.X |

### Suggestions

#### 1. [Dimension] (0.X)
**Signal:** [specific evidence from this conversation]
**Suggestion:** [name the thing — "Add a skill that X", not "improve tooling"]
**Category:** [skills | mcps | organization | prompts | architecture | documentation | other]
```

If nothing scores > 0.6, say "No significant improvement opportunities" and still log.

Every suggestion must cite a **signal** — a specific moment from the conversation. No drive-by opinions.

### 3. Implement
For each suggestion the user accepts, make the change immediately. Completion criterion: every accepted suggestion has a concrete artifact — a new file, an edited file, a deleted file, a new GitHub issue, a commit.

### 4. Log
Write `revision-log/YYYY-MM-DD-<slug>.md`. See [LOG_FORMAT.md](LOG_FORMAT.md) for the template. Create the directory if needed.
