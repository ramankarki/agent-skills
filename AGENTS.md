# Global Agent Guide

## IMPORTANT RULES (MUST FOLLOW)

- **Read latest docs before using external code.** When working with any package, framework, library, or external dependency, always fetch and read the current documentation first.
  - Rationale: APIs change, features deprecate, best practices evolve. Outdated knowledge = broken code.
  - Process: Search for official docs → Read docs → Then execute commands
  - Example: For TanStack Start, search "TanStack Start getting started", read the docs page, then use the CLI command documented there.

- When searching for latest data, NEVER include year/date in search query. Examples:
  - Wrong: `"Convex documentation 2025"`, `"latest React docs 2025"`, `"best practices 2024"`
  - Right: `"Convex documentation"`, `"latest React docs"`, `"React best practices"`
  - The query should focus on the topic, not temporal markers.

- **Package manager priority.** Use `bun` > `pnpm` > `npm` (in that order). Check availability with `command -v <pm>`. Use first available.
  - Rationale: bun/pnpm faster, better dependency handling than npm.
  - NEVER use npm or npx if bun or pnpm is available. Always prefer `bunx` over `npx`, `bun add` over `npm install`.

- **Prefer existing tools over custom code.** Before writing code from scratch, search for open-source, stable, well-maintained tools that solve the problem. When a tool is found:
  - Present the tool with brief rationale (name, repo, why it fits)
  - Ask user to confirm before proceeding with the suggested tool
  - Only write custom code if no suitable tool exists or user declines the suggestion

## Skills guide

- **Use skills first.** Check for matching skill before writing code. Load with `read` tool, follow instructions.
- **Combine multiple skills.** Read all matches, extract patterns, resolve conflicts, synthesize.
- **Sources:** `~/.pi/agent/skills/` and `.pi/skills/`
- **No match?** Use best judgment with tools and context.

## Web Scraping

Use `~/agent-skills/read-url.sh` for scraping web pages. Outputs markdown content to stdout.

```bash
./read-url.sh <url>
```

Output is clean markdown suitable for AI processing. Cached files and index are stored in `~/agent-skills/pages/`.

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

1. Web Search

**POST** `https://google.serper.dev/search`
Google web search results.
Parameters: `q`, `gl`, `hl`, `tbs`, `page`

```json
{
  "q": "best AI frameworks",
  "gl": "us",
  "hl": "en",
  "tbs": "qdr:m",
  "page": 1
}
```

2. Image Search

**POST** `https://google.serper.dev/images`
Google Images results.
Parameters: `q`, `gl`, `hl`, `tbs`, `num`, `page`

```json
{ "q": "eiffel tower sunset", "gl": "us", "hl": "en", "num": 10 }
```

3. Video Search

**POST** `https://google.serper.dev/videos`
Google Videos results.
Parameters: `q`, `gl`, `hl`, `tbs`, `page`

```json
{ "q": "how to make sourdough bread", "gl": "us", "hl": "en" }
```

4. News Search

**POST** `https://google.serper.dev/news`
Google News results.
Parameters: `q`, `gl`, `hl`, `tbs`, `page`

```json
{ "q": "AI regulation", "gl": "us", "hl": "en", "tbs": "qdr:w" }
```

5. Shopping Search

**POST** `https://google.serper.dev/shopping`
Google Shopping results.
Parameters: `q`, `gl`, `hl`, `page`, `num` (max 40)

```json
{
  "q": "wireless noise cancelling headphones",
  "gl": "us",
  "hl": "en",
  "num": 20
}
```

6. Scholar Search

**POST** `https://google.serper.dev/scholar`
Google Scholar academic papers.
Parameters: `q`, `gl`, `hl`, `page`

```json
{ "q": "transformer attention mechanism", "gl": "us", "hl": "en", "page": 1 }
```

7. Patents Search

**POST** `https://google.serper.dev/patents`
Google Patents results.
Parameters: `q`, `page`, `num` (max 40)

```json
{ "q": "neural network inference optimization", "num": 10, "page": 1 }
```

8. Places Search

**POST** `https://google.serper.dev/places`
Google Maps places/business listings.
Parameters: `q`, `gl`, `hl`, `page`
Extra:

- `location` — optional string to bias results to a specific area (e.g. `"New York, NY"`)

```json
{ "q": "coffee shops", "gl": "us", "hl": "en", "location": "Brooklyn, NY" }
```

9. Maps Search

**POST** `https://google.serper.dev/maps`
Google Maps results with geo-targeting.
Parameters: `q`, `hl`, `page`
Extra:

- `ll` — GPS position and zoom as string: `"@latitude,longitude,zoom"` (e.g. `"@40.7128,-74.0060,14z"`)
- `placeId` — Google Place ID (optional)
- `cid` — Google CID identifier (optional)

```json
{ "q": "pizza restaurant", "ll": "@40.7128,-74.0060,13z", "hl": "en" }
```

10. Reviews

**POST** `https://google.serper.dev/reviews`
Google Maps reviews for a specific place.
Requires one of: `fid`, `cid`, or `placeId` to identify the place.
Extra:

- `fid` — Feature ID of the place
- `cid` — Google CID of the place
- `placeId` — Google Place ID
- `sortBy` — `"mostRelevant"` (default) or `"newest"`
- `topicId` — Optional topic filter ID
- `nextPageToken` — Token for pagination (returned in previous response)
- `gl`, `hl`

```json
{
  "placeId": "ChIJN1t_tDeuEmsRUsoyG83frY4",
  "sortBy": "newest",
  "gl": "us",
  "hl": "en"
}
```

11. Autocomplete

**POST** `https://google.serper.dev/autocomplete`
Google Search autocomplete suggestions.
Parameters: `q`, `gl`, `hl`

```json
{ "q": "how to learn", "gl": "us", "hl": "en" }
```

12. Reverse Image Search (Lens)

**POST** `https://google.serper.dev/lens`
Google Lens reverse image search.
Parameters: `gl`, `hl`
Extra:

- `url` _(required)_ — Publicly accessible image URL to search by

```json
{
  "url": "https://upload.wikimedia.org/wikipedia/commons/a/a7/Camponotus_flavomarginatus_ant.jpg",
  "gl": "us",
  "hl": "en"
}
```

### Mini-Batch Mode

Most endpoints support batch querying (up to 100 queries per request) by passing an array instead of a single object. Each query in the batch consumes 1 credit.

```json
[
  { "q": "python tutorials" },
  { "q": "javascript tutorials" },
  { "q": "rust tutorials" }
]
```

### Full Request Template

```javascript
const response = await fetch('https://google.serper.dev/<endpoint>', {
  method: 'POST',
  headers: {
    'X-API-KEY': '<YOUR_API_KEY>',
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({ q: 'your query', gl: 'us', hl: 'en' }),
});
const data = await response.json();
```

### Choosing the Right Endpoint

| Task               | Endpoint            |
| ------------------ | ------------------- |
| General web search | `/search`           |
| Find images        | `/images`           |
| Find videos        | `/videos`           |
| Latest news        | `/news`             |
| Buy products       | `/shopping`         |
| Research papers    | `/scholar`          |
| IP / inventions    | `/patents`          |
| Local businesses   | `/places`           |
| Map with GPS pin   | `/maps`             |
| Business reviews   | `/reviews`          |
| Search suggestions | `/autocomplete`     |
| Identify an image  | `/lens`             |
