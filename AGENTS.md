# Global Agent Guide

## IMPORTANT RULES (MUST FOLLOW)

### Documentation & Knowledge

- **Read latest docs before using external code.** When working with any cli, package, framework, library, or external dependency, always fetch and read the current documentation first.
  - Rationale: APIs change, features deprecate, best practices evolve. Outdated knowledge = broken code.
  - Process: Search for official docs → Read docs → Then execute commands
  - Example: For TanStack Start, search "TanStack Start getting started", read the docs page, then use the CLI command documented there.

- When searching for latest data, NEVER include year/date in search query. Examples:
  - Wrong: `"Convex documentation 2025"`, `"latest React docs 2025"`, `"best practices 2024"`
  - Right: `"Convex documentation"`, `"latest React docs"`, `"React best practices"`
  - The query should focus on the topic, not temporal markers.

### Technical Decisions

- **Before making technical decisions, follow this process:**
  1. Search for existing solutions (libraries, patterns, best practices)
  2. Ask clarifying questions to user — be specific, not vague
  3. Analyze edge cases and potential failure modes
  4. Present options with tradeoffs
  5. Only proceed after user confirmation
  - Rationale: Avoids rework from misunderstood requirements or overlooked edge cases
  - Never assume. Always verify. Always ask.

### Package Management

- **Package manager priority.** Use `bun` > `pnpm` > `npm` (in that order). Check availability with `command -v <pm>`. Use first available.
  - Rationale: bun/pnpm faster, better dependency handling than npm.
  - NEVER use npm or npx if bun or pnpm is available. Always prefer `bunx` over `npx`, `bun add` over `npm install`.

### Tool Selection

- **Prefer existing tools over custom code.** Before writing code from scratch, search for open-source, stable, well-maintained tools that solve the problem. When a tool is found:
  - Present the tool with brief rationale (name, repo, why it fits)
  - Ask user to confirm before proceeding with the suggested tool
  - Only write custom code if no suitable tool exists or user declines the suggestion

### Project Context Maintenance

**Maintain `/docs/PROJECT_CONTEXT.md`** for continuity.

- **When to read:** Session start, before new features
- **When to update:** After features, decisions, milestones

---

## Skills Guide

- **Use skills first.** Check for matching skill before writing code. Load with `read` tool, follow instructions.
- **Combine multiple skills.** Read all matches, extract patterns, resolve conflicts, synthesize.
- **Sources:** `~/.pi/agent/skills/` and `.pi/skills/`
- **No match?** Use best judgment with tools and context.

---

## Code Quality Guidelines

Based on Andrej Karpathy's observations on LLM coding pitfalls.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

### 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

### 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

### 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

### 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

**Working well if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.

---

## Product-Minded Engineering

Based on *The Product-Minded Engineer* by Drew Hoskins (O'Reilly, 2026).

### Core Shift

From "how do I implement this?" to "**who is this for, what do they need, and how will they discover, understand, and use it?**"

### The Three Questions

Before coding, answer:
1. **Who?** → Persona
2. **What?** → Scenario
3. **How?** → Journey

### Scenario Template

```
[Persona] is [description]. They want to [goal].
Intending to [action], they [step 1]. Then [step 2].
Finally, they [outcome].
```

**Types:** Discovery, Understanding, Usage, Friction, North Star

### Persona Components

- **Demographics + Means + Motivation**
- **Universal traits:** Limited attention, multitask, shortest path, forget things, avoid risk
- **Shoe-shifting:** Pretend you don't know the implementation
- **Nonpersonas:** Define who you are NOT building for

### Naming Rules

1. **Avoid ambiguity** - Above all
2. **Be specific**
3. **Match user ontology**
4. **Convey intent**

```python
# Bad: def process_request(req)
# Good: def submit_order(order)
```

### Error Messages

**Three parts:** What happened + Why + What to do

| Type | Audience | When |
|------|----------|------|
| System | Users | Runtime |
| User Invalid Arg | Users | Runtime |
| Dev Invalid Arg | Devs | Dev time |
| Assertion | Team | Dev time |

**Shift left:** Catch errors early.

### Prioritization

| Priority | Criteria |
|----------|----------|
| P0 | Can't ship without |
| P1 | Critical for success |
| P2 | Nice to have |

### Testing Philosophy

**Dogfood:** Use your own product first. Log friction.

**Tests:** Test user behavior, not implementation.

```python
# Bad: mock_db.query.assert_called_once()
# Good: test_user_can_order_favorite_drink()
```

### Pre-Implementation Checklist

- [ ] Who is the user? (persona named)
- [ ] What do they need? (scenario written)
- [ ] How find it? (discovery path)
- [ ] How use it? (journey mapped)
- [ ] What if fail? (error message)
- [ ] How test? (scenario test)

### Common Mistakes

| Mistake | Fix |
|---------|-----|
| Coding before requirements | Write scenario first |
| Generic errors | Include context + action |
| Testing implementation | Test user behavior |
| Naming for yourself | Shoe-shift |
| No defaults | Choose safe defaults |
| Skipping dogfooding | Test your own product |

---

## Serper.dev API

Serper provides Google Search API endpoints via POST requests to `https://google.serper.dev/<endpoint>`. All requests require the header `X-API-KEY: <YOUR_API_KEY>` and `Content-Type: application/json`.

### Common Parameters

These parameters are shared across most search endpoints. Only include them when needed.

| Parameter  | Key    | Description                                                                                              |
| ---------- | ------ | -------------------------------------------------------------------------------------------------------- |
| Query      | `q`    | Search query string                                                                                      |
| Country    | `gl`   | 2-letter country code (e.g. `"us"`, `"np"`, `"gb"`)                                                      |
| Language   | `hl`   | Language code (e.g. `"en"`, `"fr"`, `"ja"`)                                                              |
| Date Range | `tbs`  | Filter by time: `"qdr:h"` (hour), `"qdr:d"` (day), `"qdr:w"` (week), `"qdr:m"` (month), `"qdr:y"` (year) |
| Page       | `page` | Page number for pagination, default `1`                                                                  |
| Results    | `num`  | Number of results to return                                                                              |

### Endpoints

1. **Web Search** `/search` — General web search results
   ```json
   { "q": "best AI frameworks", "gl": "us", "hl": "en", "tbs": "qdr:m", "page": 1 }
   ```

2. **Image Search** `/images` — Find images
   ```json
   { "q": "eiffel tower sunset", "gl": "us", "hl": "en", "num": 10 }
   ```

3. **Video Search** `/videos` — Find videos
   ```json
   { "q": "how to make sourdough bread", "gl": "us", "hl": "en" }
   ```

4. **News Search** `/news` — Latest news
   ```json
   { "q": "AI regulation", "gl": "us", "hl": "en", "tbs": "qdr:w" }
   ```

5. **Shopping Search** `/shopping` — Buy products
   ```json
   { "q": "wireless noise cancelling headphones", "gl": "us", "hl": "en", "num": 20 }
   ```

6. **Scholar Search** `/scholar` — Research papers
   ```json
   { "q": "transformer attention mechanism", "gl": "us", "hl": "en", "page": 1 }
   ```

7. **Patents Search** `/patents` — IP / inventions
   ```json
   { "q": "neural network inference optimization", "num": 10, "page": 1 }
   ```

8. **Places Search** `/places` — Local businesses
   - Extra: `location` — bias to area (e.g. `"New York, NY"`)
   ```json
   { "q": "coffee shops", "gl": "us", "hl": "en", "location": "Brooklyn, NY" }
   ```

9. **Maps Search** `/maps` — Map with GPS pin
   - Extra: `ll` — GPS position `"@lat,lng,zoom"` (e.g. `"@40.7128,-74.0060,14z"`)
   ```json
   { "q": "pizza restaurant", "ll": "@40.7128,-74.0060,13z", "hl": "en" }
   ```

10. **Reviews** `/reviews` — Business reviews
    - Requires: `fid`, `cid`, or `placeId`
    - Extra: `sortBy` — `"mostRelevant"` (default) or `"newest"`
    ```json
    { "placeId": "ChIJN1t_tDeuEmsRUsoyG83frY4", "sortBy": "newest", "gl": "us", "hl": "en" }
    ```

11. **Autocomplete** `/autocomplete` — Search suggestions
    ```json
    { "q": "how to learn", "gl": "us", "hl": "en" }
    ```

12. **Reverse Image Search (Lens)** `/lens` — Identify an image
    - Requires: `url` — publicly accessible image URL
    ```json
    { "url": "https://example.com/image.jpg", "gl": "us", "hl": "en" }
    ```

### Mini-Batch Mode

Most endpoints support batch querying (up to 100 queries per request) by passing an array:
```json
[
  { "q": "python tutorials" },
  { "q": "javascript tutorials" }
]
```

---

## Web Scraping

- **Always verify URL exists before scraping.** Google search first to confirm the URL is valid and accessible.
  - Rationale: Avoids wasting time on dead links, outdated URLs, or typos.
  - Process: Search → Verify URL in results → Then scrape
  - Example: Before scraping Deepgram docs, search "Deepgram streaming STT documentation" to find the correct URL.

Use `~/agent-skills/read-url.sh` for scraping web pages. Outputs clean markdown content to stdout for AI processing.

```bash
./read-url.sh <url>
```
