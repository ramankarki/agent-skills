---
name: product-minded-engineering
description: Use when building features, designing APIs, writing error messages, prioritizing tasks, writing tests, or receiving vague requirements
---

# Product-Minded Engineering

**Based on:** *The Product-Minded Engineer* by Drew Hoskins (O'Reilly, 2026)

## Core Shift

From "how do I implement this?" to "**who is this for, what do they need, and how will they discover, understand, and use it?**"

## The Double Diamond (SDLC)

```
Discover → Define → Develop → Deliver
   ↓         ↓        ↓        ↓
 Who/Why   What    Build     Ship
          /How            /Iterate
```

**Discover/Define:** Early cycle - understand problem
**Develop/Deliver:** Late cycle - build solution

## The Three Questions

Before coding, answer:
1. **Who?** → Persona
2. **What?** → Scenario
3. **How?** → Journey

## Scenario Template

```
[Persona] is [description]. They want to [goal].
Intending to [action], they [step 1]. Then [step 2].
Finally, they [outcome].
```

**Types:** Discovery, Understanding, Usage, Friction, North Star

## Persona

**Components:** Demographics + Means + Motivation

**Universal traits:** Limited attention, multitask, shortest path, forget things, avoid risk

**Shoe-shifting:** Pretend you don't know the implementation.

**Nonpersonas:** Define who you are NOT building for.

## Customer Discovery

1. **Interview** - Ask for stories, not opinions
2. **Patterns** - Same problems = real need
3. **Probe friction** - "What was hardest?"
4. **Validate** - Show mockups

## The Great Reindexing

```
North Star → Requirements → Compendium → Flows → Jobs
```

## User Journey

| Phase | Focus |
|-------|-------|
| Discovery | Naming, navigation |
| Understanding | Docs, examples |
| Usage | Defaults, safety |
| Error | Actionable messages |

## Naming

1. **Avoid ambiguity** - Above all
2. **Be specific**
3. **Match user ontology**
4. **Convey intent**

```python
# Bad: def process_request(req)
# Good: def submit_order(order)
```

## Error Messages

**Three parts:** What happened + Why + What to do

| Type | Audience | When |
|------|----------|------|
| System | Users | Runtime |
| User Invalid Arg | Users | Runtime |
| Dev Invalid Arg | Devs | Dev time |
| Assertion | Team | Dev time |

**Shift left:** Catch errors early.

## Prioritization

| Priority | Criteria |
|----------|----------|
| P0 | Can't ship without |
| P1 | Critical for success |
| P2 | Nice to have |

## Dogfooding & Testing

**Dogfood:** Use your own product first. Log friction.

**Tests:** Test user behavior, not implementation.

```python
# Bad: mock_db.query.assert_called_once()
# Good: test_user_can_order_favorite_drink()
```

## Affordances & Signifiers

- **Signifiers** = Clues for action
- **Affordances** = What product can do

**Traffic light:** 🟢 Safe → 🟡 Caution → 🔴 Dangerous

## Product Architecture

- **Latency** - What blocks users?
- **Availability** - What when system fails?
- **Consistency** - What guarantees?

**RyW/WoW/RoW:** Read/Write your Writes, Write after Others

## Checklist

Before implementing:
- [ ] Who is the user? (persona named)
- [ ] What do they need? (scenario written)
- [ ] How find it? (discovery path)
- [ ] How use it? (journey mapped)
- [ ] What if fail? (error message)
- [ ] How test? (scenario test)

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Coding before requirements | Write scenario first |
| Generic errors | Include context + action |
| Testing implementation | Test user behavior |
| Naming for yourself | Shoe-shift |
| No defaults | Choose safe defaults |
| Skipping dogfooding | Test your own product |

## Project Context Maintenance

**Maintain `/docs/PROJECT_CONTEXT.md`** for continuity.

**When to read:** Session start, before new features
**When to update:** After features, decisions, milestones

### Template:

```markdown
# Project Context

**Last updated:** YYYY-MM-DD
**Current focus:** [What you're working on]

## Target Users (Personas)
| Persona | Description | Key Needs |
|---------|-------------|-----------|
| [Name] | [Role] | [What they need] |

## Core Problem
[One sentence: what problem do users have?]

## Features
| Feature | Scenario | Status | Date |
|---------|----------|--------|------|
| [Name] | [User story] | live/dev | YYYY-MM-DD |

## Key Decisions
| Decision | Rationale | Trade-off |
|----------|-----------|-----------|
| [What] | [Why] | [Cost of not-B] |

## Open Questions
| Question | Status |
|----------|--------|
| [Item] | open/resolved |
```

## AI Workflow

1. Read `/docs/PROJECT_CONTEXT.md` at session start
2. Answer Three Questions before coding
3. Write scenario BEFORE generating code
4. Name based on user action
5. Generate error messages with context
6. Create scenario tests before implementation
7. Update PROJECT_CONTEXT.md after significant work
