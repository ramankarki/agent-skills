# OpenAPI Spec — Best Practices

> Guidelines for writing clean, maintainable, developer-friendly OpenAPI specs. Based on [OpenAPI Initiative](https://learn.openapis.org/best-practices.html), [Swagger](https://swagger.io/resources/articles/best-practices-in-api-design/), and [Fern](https://buildwithfern.com/post/api-design-best-practices-guide).

---

## 1. Design-First, Not Code-First

Write spec **before** code. OpenAPI can't describe every possible HTTP API — it has limitations.

- Code first → you inevitably build something OAS can't represent → either rewrite code or write dishonest spec
- Design first → spec is contract, code follows contract, tooling validates code against contract
- Use spec as source of truth for docs, SDKs, tests, CI validation

> **For Storyzip:** Since we're code-generating from Hono routes, treat the generated spec as primary artifact. Review it before writing handlers.

---

## 2. Single Source of Truth

One spec drives everything. Never duplicate API information.

- **Bad:** Endpoint defined in code + hand-written YAML + README examples
- **Good:** One OpenAPI file → generate docs, SDKs, validation from it
- If using code annotations to generate: generated spec becomes source of truth, code annotations become dead — remove them

---

## 3. DRY — Use `$ref` Aggressively

Anything appearing more than once → move to `components/`.

```yaml
# Bad — repeated schema inline
paths:
  /users:
    get:
      responses:
        200:
          content:
            application/json:
              schema:
                type: object
                properties:
                  id: { type: string }
                  name: { type: string }
  /users/{id}:
    get:
      responses:
        200:
          content:
            application/json:
              schema:
                type: object
                properties:
                  id: { type: string }
                  name: { type: string }
```

```yaml
# Good — shared component
components:
  schemas:
    User:
      type: object
      properties:
        id:
          type: string
          description: Unique user identifier
          example: "clx4k5n8s0000abc123def456"
        name:
          type: string
          description: Display name
          example: "Jane Doe"

paths:
  /users:
    get:
      responses:
        200:
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/User'
  /users/{id}:
    get:
      responses:
        200:
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/User'
```

**What to extract:**

| Repeated pattern | Move to |
|---|---|
| Response/request schemas | `components/schemas` |
| Path/query/header params | `components/parameters` |
| Common responses (401, 403, 429) | `components/responses` |
| Common headers | `components/headers` |
| Auth definitions | `components/securitySchemes` |

---

## 4. Document All Responses (Especially Errors)

Every endpoint must declare **all** status codes it can return. Not just 200.

```yaml
paths:
  /recordings/{id}:
    get:
      responses:
        '200':
          description: Recording found
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Recording'
        '401':
          $ref: '#/components/responses/Unauthorized'
        '404':
          description: Recording not found
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '429':
          $ref: '#/components/responses/RateLimited'
```

**Error format:** Use [RFC 9457 Problem Details](https://www.rfc-editor.org/rfc/rfc9457).

```yaml
components:
  schemas:
    Error:
      type: object
      required: [type, title, status]
      properties:
        type:
          type: string
          format: uri
          description: URI identifying the error category
          example: "https://api.storyzip.xyz/errors/not-found"
        title:
          type: string
          description: Short human-readable summary
          example: "Recording not found"
        status:
          type: integer
          description: HTTP status code
          example: 404
        detail:
          type: string
          description: Human-readable explanation specific to this occurrence
          example: "No recording exists with id 'clx4k5n8s0000abc123def456'"
        instance:
          type: string
          format: uri
          description: URI identifying the specific problem occurrence
```

---

## 5. Use Tags to Group Endpoints

Tags = UI grouping in Swagger/Scalar docs. One tag per resource.

```yaml
tags:
  - name: Recordings
    description: Upload, list, and manage recordings
  - name: Analysis
    description: AI-powered speaking and storytelling analysis
  - name: Storage
    description: Presigned upload/download URLs
  - name: Progress
    description: User progress tracking and trends

paths:
  /recordings:
    get:
      tags: [Recordings]
      summary: List all recordings
  /recordings/{id}:
    get:
      tags: [Recordings]
      summary: Get recording by ID
```

---

## 6. Every Endpoint Gets: summary + description + operationId

```yaml
/recordings/{id}:
  get:
    operationId: getRecordingById       # unique, camelCase, used by codegen
    summary: Get a recording            # short, UI title in docs
    description: |                      # full explanation, shown expanded
      Returns the full recording including transcript and AI analysis scores.
      Requires authentication. Analysis may still be processing (see status field).
    tags: [Recordings]
```

**operationId rules:**
- Unique across entire spec
- camelCase
- Verb + noun: `getRecording`, `createRecording`, `deleteRecording`, `listRecordings`
- Codegen tools use this for function/method names — make them clean

---

## 7. Parameter and Schema — Descriptions + Examples

Every field, every param, every property needs `description` and `example`.

```yaml
parameters:
  - name: id
    in: path
    required: true
    description: The recording's unique identifier (CUID)
    schema:
      type: string
      pattern: '^[a-z0-9]+$'
      minLength: 24
      maxLength: 32
    example: "clx4k5n8s0000abc123def456"

  - name: limit
    in: query
    description: Maximum number of recordings to return
    schema:
      type: integer
      minimum: 1
      maximum: 100
      default: 20
    example: 10
```

**Schema properties:**

```yaml
components:
  schemas:
    Recording:
      type: object
      properties:
        id:
          type: string
          description: Unique recording identifier (CUID)
          example: "clx4k5n8s0000abc123def456"
        duration:
          type: number
          description: Recording duration in seconds
          minimum: 1
          maximum: 600
          example: 45.2
        status:
          type: string
          description: Processing status
          enum: [uploaded, processing, completed, failed]
          example: "completed"
        created_at:
          type: string
          format: date-time
          description: ISO 8601 timestamp of upload
          example: "2026-06-13T14:30:00Z"
```

---

## 8. Semantic Versioning

```yaml
info:
  title: Storyzip API
  version: 1.0.0
  description: |
    AI communication coach for Instagram creators.
    Record yourself, get AI feedback on speaking and storytelling.

    ## Changelog
    - **1.0.0** — Initial MVP release
```

| Bump | When |
|---|---|
| MAJOR (2.0.0) | Breaking changes: remove field, change type, remove endpoint |
| MINOR (1.1.0) | New endpoints, optional new fields |
| PATCH (1.0.1) | Bug fixes, doc improvements, no behavior change |

---

## 9. Use `servers` Array

```yaml
servers:
  - url: https://api.storyzip.xyz
    description: Production
  - url: https://staging-api.storyzip.xyz
    description: Staging
  - url: http://localhost:8787
    description: Local development (Cloudflare Workers)
```

---

## 10. Pagination — Cursor-Based Over Offset

For list endpoints with potentially large datasets, use cursor-based pagination.

```yaml
parameters:
  - name: cursor
    in: query
    description: |
      Opaque pagination token from `next_cursor` in previous response.
      Omit for first page.
    schema:
      type: string
    example: "eyJpZCI6ImNseDRrNW44czAwMDBhYmMxMjNkZWY0NTYifQ"

  - name: limit
    in: query
    description: Maximum items to return (default 20, max 100)
    schema:
      type: integer
      minimum: 1
      maximum: 100
      default: 20
```

**Response:**

```yaml
ListRecordingsResponse:
  type: object
  properties:
    data:
      type: array
      items:
        $ref: '#/components/schemas/Recording'
    next_cursor:
      type: string
      nullable: true
      description: Token for next page. `null` means last page.
      example: "eyJpZCI6ImNseDRrNW44czAwMDBhYmMxMjNkZWY0NTYifQ"
```

**Why not offset?** Offset pagination (`page=2&limit=20`) degrades with large tables — database must scan and skip all previous rows. Cursor-based queries stay constant-time.

---

## 11. Security Schemes

```yaml
components:
  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
      description: Google OAuth JWT from Better Auth session

# Apply globally
security:
  - bearerAuth: []

# Override for public endpoints
paths:
  /health:
    get:
      security: []    # no auth required
      responses:
        '200':
          description: Service is healthy
```

---

## 12. Split Large Specs Into Multiple Files

Single file is fine for MVP. When spec grows beyond ~500 lines, split:

```
openapi/
  openapi.yaml              # entry point: info, servers, tags, security
  paths/
    recordings.yaml
    analysis.yaml
    auth.yaml
    storage.yaml
  schemas/
    recording.yaml
    analysis.yaml
    error.yaml
  responses/
    common.yaml             # 401, 403, 429
  parameters/
    common.yaml             # cursor, limit, id
```

Bundle with `redocly bundle` or `swagger-cli bundle` for serving as single file.

---

## 13. Commit Spec to Source Control

- OpenAPI spec is source code, not documentation artifact
- Commit to repo alongside code
- Run validation in CI: `redocly lint openapi.yaml` or `spectral lint openapi.yaml`
- Treat spec changes as code changes — review in PR

---

## 14. Custom Error Codes (Application-Level)

HTTP status codes alone aren't enough. 400 doesn't tell you *which* validation failed. 404 doesn't say *what* is missing. Add a machine-readable `code` field for programmatic handling.

### Structure: RFC 9457 + Custom Code

```yaml
components:
  schemas:
    ApiError:
      type: object
      required: [code, message]
      properties:
        code:
          type: string
          description: |
            Machine-readable error code. Stable across versions.
            Use SCREAMING_SNAKE_CASE.
          example: "RECORDING_NOT_FOUND"
        message:
          type: string
          description: Human-readable description of the error
          example: "No recording exists with id 'clx4k5n8s0000abc123def456'"
        status:
          type: integer
          description: HTTP status code (mirrored for convenience)
          example: 404
        details:
          type: array
          description: Field-level validation errors (when applicable)
          items:
            type: object
            properties:
              field:
                type: string
                description: Path to the invalid field (e.g. "body.duration")
              message:
                type: string
                description: What's wrong with this field
              code:
                type: string
                description: Machine-readable validation code
            example:
              field: "body.duration"
              message: "Duration must be between 1 and 600 seconds"
              code: "INVALID_RANGE"
```

### Error Code Naming Convention

```
<DOMAIN>_<PROBLEM>
```

| Pattern | Example |
|---|---|
| `RESOURCE_NOT_FOUND` | `RECORDING_NOT_FOUND`, `ANALYSIS_NOT_FOUND` |
| `RESOURCE_ALREADY_EXISTS` | `RECORDING_ALREADY_DELETED` |
| `VALIDATION_ERROR` | `INVALID_DURATION`, `MISSING_REQUIRED_FIELD` |
| `PERMISSION_DENIED` | `NOT_OWNER`, `INSUFFICIENT_CREDITS` |
| `QUOTA_EXCEEDED` | `DAILY_LIMIT_REACHED`, `STORAGE_FULL` |
| `STATE_CONFLICT` | `RECORDING_STILL_PROCESSING`, `ANALYSIS_ALREADY_EXISTS` |
| `UPSTREAM_ERROR` | `TRANSCRIPTION_FAILED`, `ANALYSIS_FAILED` |
| `RATE_LIMITED` | `TOO_MANY_REQUESTS` |

### Full Example — Recording Endpoint

```yaml
paths:
  /recordings/{id}:
    get:
      operationId: getRecordingById
      responses:
        '200':
          description: Recording found
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Recording'
        '401':
          description: Missing or invalid authentication
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ApiError'
              example:
                code: "UNAUTHORIZED"
                message: "Valid session required. Please sign in."
                status: 401
        '403':
          description: Authenticated but not authorized
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ApiError'
              example:
                code: "FORBIDDEN"
                message: "You don't own this recording"
                status: 403
        '404':
          description: Recording not found
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ApiError'
              example:
                code: "RECORDING_NOT_FOUND"
                message: "No recording exists with the given ID"
                status: 404
        '409':
          description: Recording exists but can't be accessed right now
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ApiError'
              example:
                code: "RECORDING_STILL_PROCESSING"
                message: "Analysis not yet complete. Poll again in a few seconds."
                status: 409
        '429':
          description: Rate limit exceeded
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ApiError'
              example:
                code: "RATE_LIMIT_EXCEEDED"
                message: "Too many requests. Retry after 60 seconds."
                status: 429
```

### Why Machine-Readable Codes Matter

```typescript
// Client code can handle errors programmatically
switch (error.code) {
  case 'RECORDING_STILL_PROCESSING':
    // Show spinner, poll again in 5s
    break
  case 'RATE_LIMIT_EXCEEDED':
    // Show backoff message, use Retry-After header
    break
  case 'INSUFFICIENT_CREDITS':
    // Redirect to purchase credits page
    break
  case 'UNAUTHORIZED':
    // Redirect to login
    break
}
```

Without codes, clients parse error **messages** — fragile, breaks on copy changes.

### Rules

- Codes are **stable** — never rename, never repurpose. Add new codes, deprecate old ones.
- Codes use `SCREAMING_SNAKE_CASE`
- Always pair code with human `message`
- HTTP status still matters — don't return `200 OK` with `code: "RECORDING_NOT_FOUND"`
- Field-level validation errors go in `details[]` array, not top-level code

---

## 15. Serve Spec at Standard Paths

Make spec discoverable for tools, SDK generators, and AI agents:

```
/openapi.json          # Full spec (JSON)
/openapi.yaml          # Full spec (YAML)
/docs                  # Rendered docs (Scalar / Swagger UI)
```

---

## 16. readOnly / writeOnly — Separate Input from Output Schemas

Single schema for both input and output = broken. Fields like `id`, `created_at`, `updated_at` must never appear in request bodies. Fields like `password` must never appear in responses.

Use `readOnly` and `writeOnly` to mark intent, or split into dedicated input/output schemas.

```yaml
components:
  schemas:
    User:
      type: object
      properties:
        id:
          type: string
          description: Unique identifier
          readOnly: true           # never accepted in request
          example: "clx4k5n8s0000abc123def456"
        email:
          type: string
          format: email
          description: User's email address
          example: "jane@example.com"
        password:
          type: string
          format: password
          description: Account password
          writeOnly: true          # never returned in response
        created_at:
          type: string
          format: date-time
          readOnly: true
          example: "2026-06-13T14:30:00Z"
        updated_at:
          type: string
          format: date-time
          readOnly: true
          example: "2026-06-14T09:15:00Z"
```

**Why not reuse one schema everywhere?** Codegen tools generate types from schemas. Without `readOnly`/`writeOnly`, `CreateUserBody` includes `id` and `created_at` — wrong types, wrong validation.

**Alternative: separate schemas per operation.** When input diverges significantly from output (create vs update vs response), use dedicated schemas:

```yaml
components:
  schemas:
    User:                          # Full output (response)
      properties:
        id: { type: string }
        email: { type: string }
        name: { type: string }
        created_at: { type: string, format: date-time }
    UserCreate:                    # POST body
      required: [email, password]
      properties:
        email: { type: string, format: email }
        password: { writeOnly: true, type: string, format: password }
        name: { type: string }
    UserUpdate:                    # PATCH body (all optional)
      properties:
        email: { type: string, format: email }
        name: { type: string }
```

**Rule of thumb:** If input has ≥3 fields that differ from output → separate schema. Otherwise, `readOnly`/`writeOnly` annotations suffice.

---

## 17. oneOf / anyOf / discriminator — Polymorphism

Union types are common for event payloads, error variants, analysis results, or search responses. Use `oneOf`/`anyOf` with `discriminator` for type narrowing.

```yaml
components:
  schemas:
    AnalysisEvent:
      oneOf:
        - $ref: '#/components/schemas/PacingEvent'
        - $ref: '#/components/schemas/FillerWordEvent'
        - $ref: '#/components/schemas/ToneShiftEvent'
      discriminator:
        propertyName: type
        mapping:
          pacing: '#/components/schemas/PacingEvent'
          filler_word: '#/components/schemas/FillerWordEvent'
          tone_shift: '#/components/schemas/ToneShiftEvent'

    PacingEvent:
      type: object
      required: [type, timestamp, words_per_minute]
      properties:
        type:
          type: string
          enum: [pacing]
        timestamp:
          type: number
          description: Seconds into recording
        words_per_minute:
          type: integer
          description: Speaking rate at this moment

    FillerWordEvent:
      type: object
      required: [type, timestamp, word]
      properties:
        type:
          type: string
          enum: [filler_word]
        timestamp:
          type: number
        word:
          type: string
          description: The filler word detected
          enum: [um, uh, like, you_know, basically]
```

**When to use each:**

| Keyword | Semantics | Example |
|---|---|---|
| `oneOf` | Exactly one variant matches | Event type, payment method |
| `anyOf` | One or more can match | Search result (could be user OR recording) |
| `allOf` | All must match (composition) | Merge base + extension schemas |

**Why discriminator matters:** Without it, generated TypeScript types are bare unions — you get `PacingEvent | FillerWordEvent` but no way to narrow by `type` field without manual type guards. Discriminator lets codegen produce proper discriminated unions.

---

## 18. default Values on Properties

Schema `default` values drive mock servers, SDK generators, and docs. Omit only when no sensible default exists.

```yaml
limit:
  type: integer
  minimum: 1
  maximum: 100
  default: 20                  # tools use this

sort:
  type: string
  default: "-created_at"       # newest first

status:
  type: string
  enum: [uploaded, processing, completed, failed]
  default: "uploaded"          # initial state for POST
```

**Placement:**
- Query params: `default` in parameter `schema` (shown in docs, used by "Try It")
- Request body properties: `default` in schema property (used by mock servers, SDK constructors)
- Response properties: rarely needed unless value has a standard fallback

**Anti-pattern:** `default: null` on non-nullable fields. If `null` is valid, mark `nullable: true`.

---

## 19. Enum Value Descriptions

OpenAPI 3.1 has no native `description` per enum value. Without descriptions, consumers guess what each value means.

**Workaround 1: oneOf + const (recommended for OpenAPI 3.1)**

```yaml
status:
  oneOf:
    - const: uploaded
      title: Uploaded
      description: File received by server, not yet analyzed
    - const: processing
      title: Processing
      description: AI analysis is currently running
    - const: completed
      title: Completed
      description: Analysis finished, all scores available
    - const: failed
      title: Failed
      description: Analysis failed — check error_details field
```

**Workaround 2: x-enum-descriptions extension (for Scalar / Redoc)**

```yaml
status:
  type: string
  enum: [uploaded, processing, completed, failed]
  x-enum-descriptions:
    uploaded: "File received, not yet analyzed"
    processing: "AI analysis in progress"
    completed: "Analysis complete, all scores available"
    failed: "Analysis failed — check error_details field"
```

**Workaround 3: description field (least specific)**

```yaml
status:
  type: string
  enum: [uploaded, processing, completed, failed]
  description: |
    Processing status:
    - `uploaded` — File received, not yet analyzed
    - `processing` — AI analysis in progress
    - `completed` — Analysis complete
    - `failed` — Analysis failed
```

Prefer workaround 1 (`oneOf`+`const`). Most codegen tools handle it. Machine-readable. Swagger UI shows descriptions per value.

---

## 20. API Versioning Strategy

Decide and document versioning approach before first release. Two common strategies:

| Strategy | Example | Best for |
|---|---|---|
| **URL path** | `/v1/recordings` | Public APIs, simple, highly discoverable |
| **Header** | `Accept: application/vnd.api+json;version=1` | Internal APIs, clean URLs |
| **Query param** | `/recordings?version=1` | Avoid — pollutes query namespace |

**Recommendation: URL path versioning** for public APIs. Explicit, tooling-friendly, easy to route.

```yaml
servers:
  - url: https://api.storyzip.xyz/v1
    description: API v1

paths:
  /recordings:       # resolved as /v1/recordings
    get:
      ...
```

**Version lifecycle:**

```
v1 (stable) ──► v2 (beta) ──► v2 (stable) ──► v1 (deprecated) ──► v1 (sunset)
```

- Maintain ≥2 versions during migration
- Announce deprecation with `Sunset` header (see section 21)
- Give clients ≥6 months to migrate before removing old version

---

## 21. Deprecation — Sunset and Migration

Mark endpoints and schema properties as `deprecated: true` before removal. Use HTTP headers for runtime signaling.

### Marking Deprecated Endpoints

```yaml
paths:
  /recordings/legacy:
    get:
      deprecated: true
      summary: List recordings (legacy)
      description: |
        **Deprecated.** Use `GET /recordings` instead.
        This endpoint will be removed in v2.0.0 (2026-12-31).
      responses:
        '200':
          headers:
            Sunset:
              description: Date when this endpoint will be removed
              schema:
                type: string
                format: date
              example: "2026-12-31"
            Deprecation:
              description: Human-readable deprecation notice
              schema:
                type: string
              example: "Use GET /recordings instead. See docs for migration guide."
```

### Deprecating Schema Properties

```yaml
legacy_score:
  type: integer
  deprecated: true
  description: Use `detailed_scores` instead. Removed in v2.0.0.
```

### Deprecation Headers

| Header | Purpose | Example |
|---|---|---|
| `Sunset` | Date of planned removal (RFC 8594) | `Sat, 31 Dec 2026 23:59:59 GMT` |
| `Deprecation` | Human-readable migration hint | `"Use GET /recordings instead"` |
| `Link` | Link to successor resource | `</v2/recordings>; rel="successor-version"` |

### Sunset Policy

```
T-6 months:  mark deprecated, add headers, notify via changelog
T-3 months:  start returning `warning` level in responses
T-1 month:   email registered API consumers
T+0:         remove endpoint, bump MAJOR version
```

**Rules:**
- Never remove a field or endpoint without deprecation period
- Never repurpose a field name (rename + deprecate old one instead)
- Deprecated things still work — just warn

---

## 22. Filtering, Sorting, and Search

List endpoints need more than pagination. Standardize filtering, sorting, and search patterns.

### Filtering

```yaml
parameters:
  - name: status
    in: query
    description: Filter by processing status. Repeat for multiple values.
    schema:
      type: string
      enum: [uploaded, processing, completed, failed]
    example: "completed"

  - name: created_after
    in: query
    description: Filter recordings created after this ISO 8601 timestamp
    schema:
      type: string
      format: date-time
    example: "2026-06-01T00:00:00Z"

  - name: created_before
    in: query
    description: Filter recordings created before this ISO 8601 timestamp
    schema:
      type: string
      format: date-time
    example: "2026-06-15T00:00:00Z"

  - name: duration_min
    in: query
    description: Minimum duration in seconds
    schema:
      type: number
      minimum: 0
    example: 30

  - name: duration_max
    in: query
    description: Maximum duration in seconds
    schema:
      type: number
      maximum: 600
    example: 120
```

### Sorting

```yaml
  - name: sort
    in: query
    description: |
      Field to sort by. Prefix with `-` for descending order.
      Default: `-created_at` (newest first).
    schema:
      type: string
      enum:
        - created_at
        - -created_at
        - duration
        - -duration
        - name
        - -name
    default: "-created_at"
```

### Search

```yaml
  - name: q
    in: query
    description: Full-text search across recording title and transcript
    schema:
      type: string
      minLength: 1
      maxLength: 200
    example: "pitch practice"
```

**Naming convention for filters:**

| Pattern | Example |
|---|---|
| Exact match | `status=completed` |
| Range start | `created_after=...`, `duration_min=30` |
| Range end | `created_before=...`, `duration_max=120` |
| Contains | `tag=storytelling` |
| Search | `q=keyword` |

---

## 23. Idempotency — Safe Retries

Network failures happen. Clients retry. Without idempotency, retried POST = duplicate resource, retried payment = double charge.

Use `Idempotency-Key` header (IETF draft standard):

```yaml
paths:
  /recordings:
    post:
      parameters:
        - name: Idempotency-Key
          in: header
          required: false
          description: |
            Unique key for idempotent request. Send same key to safely retry.
            Server deduplicates keys for 24 hours.
            Generate as UUID v4 on client.
          schema:
            type: string
            format: uuid
          example: "550e8400-e29b-41d4-a716-446655440000"
      responses:
        '201':
          description: |
            Recording created.

            **200 OK** returned instead when `Idempotency-Key` matches
            a previous successful request (same response body).
        '409':
          description: |
            Idempotency key reused with different request body.
            First request already processed. Return first result.
        '422':
          description: |
            Idempotency key reused with different request body.
            First request already processed with different parameters.
```

**Rules:**
- Only for `POST`, `PUT`, `PATCH` (never `GET`; `DELETE` is already idempotent)
- Server stores (key → response) for ≥24h
- If same key + different body → `409 Conflict` or `422 Unprocessable`
- Keys must be globally unique per client (UUID v4 recommended)

---

## 24. Conditional Requests — ETag / 304

For cacheable resources, support conditional requests to save bandwidth and reduce server load.

```yaml
paths:
  /recordings/{id}:
    get:
      parameters:
        - name: If-None-Match
          in: header
          description: ETag from previous `GET`. Returns `304 Not Modified` if unchanged.
          schema:
            type: string
          example: '"abc123"'
      responses:
        '200':
          description: Recording returned
          headers:
            ETag:
              description: |
                Opaque entity tag. Changes when recording or its analysis changes.
                Pass as `If-None-Match` on next request.
              schema:
                type: string
              example: '"abc123"'
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Recording'
        '304':
          description: Resource unchanged — use cached version
```

**When to use:**
- Resources that change infrequently (recordings with completed analysis)
- Large response bodies (transcripts, analysis results)
- Mobile clients on metered connections

**When to skip:**
- Real-time data that changes every request
- List endpoints with dynamic filtering/sorting
- Already using short cache headers (`Cache-Control: max-age=5`)

---

## 25. Content Negotiation — Multiple Response Formats

Document when an endpoint returns multiple formats (JSON, CSV, PDF).

```yaml
paths:
  /recordings/{id}/transcript:
    get:
      parameters:
        - name: Accept
          in: header
          description: Response format
          schema:
            type: string
            enum:
              - application/json
              - text/plain
              - application/pdf
            default: application/json
      responses:
        '200':
          description: Transcript returned
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Transcript'
            text/plain:
              schema:
                type: string
                example: "Um, so today I wanted to talk about..."
            application/pdf:
              schema:
                type: string
                format: binary
                description: PDF transcript with timestamps
        '406':
          description: Requested format not supported
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ApiError'
              example:
                code: "UNSUPPORTED_MEDIA_TYPE"
                message: "This endpoint only supports: application/json, text/plain, application/pdf"
                status: 406
```

**Rules:**
- `Accept` header drives format selection (standard HTTP)
- Default format when `Accept: */*` is `application/json`
- Return `406 Not Acceptable` when requested format unsupported
- List available formats in 406 response message

---

## 26. File Upload — multipart/form-data

Upload endpoints need `multipart/form-data` content type.

```yaml
paths:
  /recordings/upload:
    post:
      operationId: uploadRecording
      summary: Upload a new recording
      requestBody:
        required: true
        content:
          multipart/form-data:
            schema:
              type: object
              required: [file]
              properties:
                file:
                  type: string
                  format: binary
                  description: |
                    Audio recording file.
                    Supported: m4a, mp3, wav, webm.
                    Max size: 10 MB.
                title:
                  type: string
                  description: Optional title for the recording
                  example: "Pitch Practice #3"
                metadata:
                  type: string
                  description: JSON-encoded extra metadata
                  example: '{"tags":["pitch","investors"],"language":"en"}'
      responses:
        '201':
          description: Recording uploaded, processing started
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Recording'
        '413':
          description: File too large
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ApiError'
              example:
                code: "FILE_TOO_LARGE"
                message: "File exceeds 10 MB limit"
                status: 413
```

**Rules:**
- Always document supported file types in description
- Always document max file size, return `413 Payload Too Large` if exceeded
- Use `format: binary` for file fields
- Non-file fields in multipart are always strings (numbers/booleans must be parsed server-side)

---

## 27. Rate Limiting Headers

Beyond the 429 response body, document rate limit response headers so clients can implement backoff without parsing JSON.

### Define Headers in components

```yaml
components:
  headers:
    RateLimit-Limit:
      description: Maximum requests allowed per window
      schema:
        type: integer
      example: 100
    RateLimit-Remaining:
      description: Requests remaining in current window
      schema:
        type: integer
      example: 42
    RateLimit-Reset:
      description: Unix timestamp (seconds) when the window resets
      schema:
        type: integer
      example: 1718400000
    Retry-After:
      description: |
        Seconds until next request is allowed.
        Returned on `429 Too Many Requests` responses.
      schema:
        type: integer
      example: 30
```

### Add to Responses

```yaml
components:
  responses:
    RateLimited:
      description: Rate limit exceeded
      headers:
        RateLimit-Limit:
          $ref: '#/components/headers/RateLimit-Limit'
        RateLimit-Remaining:
          $ref: '#/components/headers/RateLimit-Remaining'
        RateLimit-Reset:
          $ref: '#/components/headers/RateLimit-Reset'
        Retry-After:
          $ref: '#/components/headers/Retry-After'
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ApiError'
```

### Include on All Authenticated Endpoints

```yaml
paths:
  /recordings:
    get:
      responses:
        '200':
          description: List of recordings
          headers:
            RateLimit-Limit:
              $ref: '#/components/headers/RateLimit-Limit'
            RateLimit-Remaining:
              $ref: '#/components/headers/RateLimit-Remaining'
            RateLimit-Reset:
              $ref: '#/components/headers/RateLimit-Reset'
        '429':
          $ref: '#/components/responses/RateLimited'
```

**Standard:** Use `RateLimit-*` headers per [IETF draft-ietf-httpapi-ratelimit-headers](https://datatracker.ietf.org/doc/draft-ietf-httpapi-ratelimit-headers/). Legacy `X-RateLimit-*` is acceptable but non-standard.

---

## 28. Webhooks (OpenAPI 3.1+)

If your API pushes events to client servers, document webhooks with the top-level `webhooks` keyword (separate from `paths` — they're outgoing, not incoming).

```yaml
webhooks:
  analysis.completed:
    post:
      summary: Analysis finished
      description: |
        Fired when AI analysis completes for a recording.
        Client must respond `200 OK` within 5 seconds.
        Server retries up to 3 times with exponential backoff.
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required: [event, recording_id, timestamp]
              properties:
                event:
                  type: string
                  enum: [analysis.completed]
                recording_id:
                  type: string
                  description: The recording that was analyzed
                timestamp:
                  type: string
                  format: date-time
                scores:
                  $ref: '#/components/schemas/AnalysisScores'
      responses:
        '200':
          description: Acknowledged
        '410':
          description: |
            Webhook subscription expired or was revoked.
            Client should stop expecting events.

  analysis.failed:
    post:
      summary: Analysis failed
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/AnalysisFailedEvent'
      responses:
        '200':
          description: Acknowledged
```

**Rules:**
- Webhook names use reverse-domain notation: `resource.action`
- Signature verification header (e.g., `X-Webhook-Signature`) documented in security schemes
- Retry policy documented in description (how many retries, backoff strategy)
- `410 Gone` response stops further delivery attempts
- Client timeout expectations documented in description

---

## 29. Extensions — x-*

OpenAPI allows custom `x-*` properties for tooling-specific metadata. Use them sparingly and document them.

```yaml
paths:
  /recordings:
    get:
      x-codeSamples:                    # Multi-language examples (used by ReadMe, Scalar)
        - lang: TypeScript
          source: |
            const { data } = await client.GET('/recordings', {
              params: { query: { limit: 10 } }
            })
        - lang: Python
          source: |
            recordings = client.recordings.list(limit=10)

      x-scalar-ignore: false            # Scalar: hide internal endpoints
      x-internal: false                 # Custom: mark internal-only endpoints
```

**Common extensions:**

| Extension | Tool | Purpose |
|---|---|---|
| `x-codeSamples` | ReadMe, Scalar | Multi-language code examples |
| `x-scalar-*` | Scalar | UI customization |
| `x-redoc-*` | Redoc | Rendering hints |
| `x-internal` | Custom | Mark endpoints excluded from public docs |
| `x-deprecated-since` | Custom | Version when deprecation started |
| `x-enum-descriptions` | Scalar, Redoc | Per-value descriptions for enums |

**Rules:**
- Always document custom extensions in a project `CONTRIBUTING.md` or spec preamble
- Never use `x-*` for data that affects API behavior — that goes in standard fields
- Prefix with project name for project-specific extensions: `x-storyzip-*`

---

## 30. Naming Conventions

Consistent naming prevents confusion. Establish conventions before first endpoint.

### Paths

| Rule | Example | Anti-Pattern |
|---|---|---|
| Plural nouns for collections | `/recordings` | `/recording`, `/getRecording` |
| Singular for singleton resources | `/users/{id}/settings` | `/users/{id}/setting` |
| kebab-case for multi-word | `/recording-segments` | `/recordingSegments`, `/recording_segments` |
| No verbs in path | `POST /recordings` | `POST /createRecording` |
| No trailing slash | `/recordings` | `/recordings/` |
| IDs are path params | `/recordings/{id}` | `/recordings?id=123` |
| Nested resources, max 2 deep | `/recordings/{id}/segments` | `/recordings/{id}/segments/{sid}/notes` |

```yaml
# Good
paths:
  /recordings:
    post:
      operationId: createRecording
  /recordings/{id}:
    get:
      operationId: getRecordingById
  /recordings/{id}/segments:
    get:
      operationId: listRecordingSegments

# Bad
paths:
  /recording:
    get:
      operationId: getRecordings
  /createRecording:
    post:
      operationId: createRecording
  /Recordings/{recordingId}/Segments/:
    get:
      operationId: getSegments
```

### Parameters

| Element | Convention | Example |
|---|---|---|
| Path params | camelCase | `userId`, `recordingId` |
| Query params | snake_case | `created_after`, `page_size` |
| Headers | Capital-Hyphen-Case | `Idempotency-Key`, `X-Request-Id` |

### Schema Properties

| Element | Convention | Example |
|---|---|---|
| Object properties | snake_case | `created_at`, `words_per_minute` |
| Enum values | snake_case | `filler_word`, `tone_shift` |
| Error codes | SCREAMING_SNAKE_CASE | `RECORDING_NOT_FOUND` |

### Operation IDs

| Rule | Example |
|---|---|
| camelCase | `getRecordingById` |
| Verb + noun (list = plural) | `listRecordings`, `createRecording`, `deleteRecording` |
| Nested resources use parent | `listRecordingSegments`, `getRecordingSegmentById` |
| Standard verb set | `list`, `get`, `create`, `update`, `replace`, `delete` |

---

## 31. HTTP Method Semantics

Use correct HTTP method for each action. Method choice = part of API contract.

| Method | Semantics | Idempotent | Safe | Example |
|---|---|---|---|---|
| `GET` | Retrieve resource(s) | Yes | Yes | `GET /recordings` |
| `POST` | Create resource / trigger action | **No** | No | `POST /recordings` |
| `PUT` | Full replacement (send entire resource) | Yes | No | `PUT /recordings/{id}` |
| `PATCH` | Partial update (send changed fields only) | No | No | `PATCH /recordings/{id}` |
| `DELETE` | Remove resource | Yes | No | `DELETE /recordings/{id}` |
| `HEAD` | Same as `GET` but no body | Yes | Yes | `HEAD /recordings/{id}` |
| `OPTIONS` | CORS preflight / capabilities | Yes | Yes | `OPTIONS /recordings` |

**PUT vs PATCH — common confusion:**

```yaml
# PUT — client sends entire replacement. Omitted fields = removed.
PUT /recordings/{id}
{
  "title": "New title",
  "tags": ["pitch"]
  # duration is omitted → server sets to null/default
}

# PATCH — client sends only changed fields. Omitted fields = unchanged.
PATCH /recordings/{id}
{
  "title": "New title"
  # duration unchanged — server keeps existing value
}
```

**POST for actions (non-CRUD):**

```yaml
POST /recordings/{id}/retry-analysis    # trigger action, not create resource
POST /recordings/{id}/export            # trigger export job
POST /auth/sign-out                     # action, not resource
```

**Rules:**
- `GET` must never mutate state (no side effects)
- `PUT` requires full resource body — don't use for partial updates
- `DELETE` returns `404` on second call (resource already gone)
- `POST` non-idempotent by default — add `Idempotency-Key` for safety (see section 23)
- Never tunnel actions through query params: `POST /recordings?action=delete` is wrong, use `DELETE /recordings/{id}`

---

## 32. Long-Running Operations — 202 Accepted

For async operations (recording analysis, exports, batch processing), return `202 Accepted` immediately, not block until completion.

```yaml
paths:
  /recordings/{id}/analyze:
    post:
      operationId: analyzeRecording
      summary: Start AI analysis
      description: |
        Queues analysis for the recording. Analysis runs asynchronously.
        Poll the status endpoint or register a webhook for completion.
      responses:
        '202':
          description: Analysis queued
          headers:
            Location:
              description: URL to poll for status
              schema:
                type: string
                format: uri
              example: "https://api.storyzip.xyz/v1/recordings/clx4k5/analysis"
            Retry-After:
              description: Suggested polling interval (seconds)
              schema:
                type: integer
              example: 5
          content:
            application/json:
              schema:
                type: object
                properties:
                  status:
                    type: string
                    enum: [pending]
                  estimated_seconds:
                    type: integer
                    description: Approximate time until completion
                    example: 30

  /recordings/{id}/analysis:
    get:
      operationId: getAnalysisStatus
      summary: Get analysis status
      description: Poll this endpoint to check if analysis has completed.
      responses:
        '200':
          description: Analysis result
          content:
            application/json:
              schema:
                oneOf:
                  - $ref: '#/components/schemas/AnalysisInProgress'
                  - $ref: '#/components/schemas/AnalysisCompleted'
                  - $ref: '#/components/schemas/AnalysisFailed'
              discriminator:
                propertyName: status
                mapping:
                  pending: '#/components/schemas/AnalysisInProgress'
                  processing: '#/components/schemas/AnalysisInProgress'
                  completed: '#/components/schemas/AnalysisCompleted'
                  failed: '#/components/schemas/AnalysisFailed'

components:
  schemas:
    AnalysisInProgress:
      type: object
      required: [status]
      properties:
        status:
          type: string
          enum: [pending, processing]
        progress:
          type: integer
          minimum: 0
          maximum: 100
          description: Completion percentage
          example: 45

    AnalysisCompleted:
      type: object
      required: [status, scores]
      properties:
        status:
          type: string
          enum: [completed]
        scores:
          $ref: '#/components/schemas/AnalysisScores'

    AnalysisFailed:
      type: object
      required: [status, error]
      properties:
        status:
          type: string
          enum: [failed]
        error:
          type: string
          description: Why analysis failed
          example: "Audio too noisy for reliable transcription"
```

**Rules:**
- `202` response must include `Location` header pointing to status endpoint
- Include `Retry-After` header with suggested polling interval
- Status endpoint returns `200` with `status` field (`pending` / `processing` / `completed` / `failed`)
- Don't return `404` while operation is pending — that implies the resource doesn't exist
- For webhook-driven flows, document webhook as primary delivery + status polling as fallback

---

## 33. Request IDs — Traceability

Return a unique request ID on every response for debugging and support.

```yaml
components:
  headers:
    X-Request-Id:
      description: |
        Unique identifier for this request. Include in support tickets.
        Server generates if client doesn't send one.
      schema:
        type: string
      example: "req_clx4k5n8s0000abc123def456"

paths:
  /recordings:
    get:
      responses:
        '200':
          headers:
            X-Request-Id:
              $ref: '#/components/headers/X-Request-Id'
        '500':
          headers:
            X-Request-Id:
              $ref: '#/components/headers/X-Request-Id'
```

**Rules:**
- Client can send `X-Request-Id` header — server uses it if present, generates one if not
- Log the ID server-side with every log line for that request
- Include in error responses, error messages, and `instance` field in RFC 9457 errors
- Return it on all status codes, including `500`
- Format: `req_` prefix + unique string (CUID, UUID, or ULID)

---

## 34. Array Query Parameters

Document how clients pass multiple values for same parameter. Pick one strategy, apply consistently.

**Strategy A: Repeated key (recommended)**

```yaml
parameters:
  - name: status
    in: query
    description: |
      Filter by one or more statuses.
      Repeat the parameter for multiple values.
    schema:
      type: array
      items:
        type: string
        enum: [uploaded, processing, completed, failed]
    style: form           # ?status=uploaded&status=completed
    explode: true
    example: ["uploaded", "completed"]
```

Produces: `?status=uploaded&status=completed`

**Strategy B: CSV (simpler, less standard)**

```yaml
parameters:
  - name: status
    in: query
    description: Filter by one or more statuses, comma-separated.
    schema:
      type: array
      items:
        type: string
        enum: [uploaded, processing, completed, failed]
    style: form
    explode: false
    example: ["uploaded", "completed"]
```

Produces: `?status=uploaded,completed`

### Document the chosen style

```yaml
# In array filter parameters
  - name: tag
    in: query
    description: |
      Filter by tags. Repeat for multiple: `?tag=pitch&tag=investors`.
      Returns recordings matching ANY tag (OR logic).
      Use `tag[]=pitch&tag[]=investors` for AND logic (if supported).
```

**Recommendation:** Repeated key (Strategy A). Most HTTP clients support it. Most servers parse it automatically. Comma in values causes ambiguity with CSV approach.

---

## 35. OpenAPI Version — 3.0 vs 3.1

State which OpenAPI version the spec targets. Affects syntax choices throughout the spec.

```yaml
openapi: 3.1.0
```

### Key differences that affect spec design

| Feature | OpenAPI 3.0 | OpenAPI 3.1 |
|---|---|---|
| `nullable` | `nullable: true` alongside `type` | `type: [string, "null"]` (JSON Schema style) |
| `examples` | Array of example objects | Array of example objects (no change) |
| `webhooks` | Not supported | Top-level `webhooks` keyword |
| Path params with `/` | Requires `allowReserved: true` | Same |
| `exclusiveMinimum` | Boolean alongside `minimum` | Number that IS the minimum (no `minimum` needed) |
| `const` | Not supported | Supported |
| `$ref` alongside other keywords | Not allowed | Allowed (sibling keywords override) |

### Recommendation

Use **OpenAPI 3.1** for new specs:

- `webhooks` support (section 28)
- JSON Schema compatibility (no `nullable` hack)
- `const` for enum descriptions (section 19)
- `$ref` + sibling keywords for cleaner overrides

If targeting 3.0 (legacy tooling constraint):
- Replace `type: [string, "null"]` with `type: string` + `nullable: true`
- Remove `webhooks` section
- Remove `const` from enum workarounds
- Never use `$ref` alongside other keywords in same object

---

## Priority Cheat Sheet

| Priority | Rule |
|---|---|
| **P0** | Every endpoint has `summary` + `operationId` |
| **P0** | Every param/field has `description` + `example` |
| **P0** | All error responses documented (401, 404, 429, 500) |
| **P0** | Single source of truth — spec drives everything |
| **P0** | `readOnly` / `writeOnly` on all schema properties |
| **P0** | `oneOf` + `discriminator` for polymorphic types |
| **P0** | `deprecated: true` on sunset endpoints/fields |
| **P0** | Correct HTTP method semantics (PUT vs PATCH vs POST) |
| **P0** | Consistent naming conventions (paths, params, properties) |
| **P0** | Declare OpenAPI version (prefer 3.1) |
| **P1** | DRY schemas via `$ref` (components) |
| **P1** | Tags per resource group |
| **P1** | Semver versioning |
| **P1** | Cursor-based pagination for lists |
| **P1** | Filtering, sorting, search params on list endpoints |
| **P1** | Idempotency-Key for POST/PUT/PATCH |
| **P1** | Rate limit headers (`RateLimit-*`, `Retry-After`) |
| **P1** | `default` values on schema properties |
| **P1** | `202 Accepted` + `Location` for long-running operations |
| **P1** | `X-Request-Id` on all responses |
| **P1** | Array query parameter style documented (repeated key vs CSV) |
| **P2** | `servers` array with all environments |
| **P2** | Split into multiple files when > 500 lines |
| **P2** | Serve at `/openapi.json` |
| **P2** | CI validation of spec |
| **P2** | ETag + `304 Not Modified` for cacheable resources |
| **P2** | Enum value descriptions (`oneOf`+`const` or `x-` ext) |
| **P2** | `multipart/form-data` for file uploads |
| **P2** | Webhooks for async events (OpenAPI 3.1+) |
| **P2** | API versioning strategy documented |
| **P2** | `x-*` extensions documented |
