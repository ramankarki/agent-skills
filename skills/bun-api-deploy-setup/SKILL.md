---
name: bun-api-deploy-setup
description: Scaffold production-ready TypeScript API/backend projects with Bun, Conventional Commits, commitlint+husky, GitHub Actions CI, release-please, and deploy to Cloudflare Workers/Fly.io/VPS/Docker. Use when creating a new API server, setting up CI/CD for a backend, or configuring automated deployment.
---

# Production-Ready API/Backend Setup

Complete guide for TypeScript backend/API projects — from `git init` to automated deploy. Self-contained. Written for Bun + GitHub Actions.

---

## 1. Prerequisites

### Cloud Provider Setup

Get API tokens from your provider. Store in GitHub repo → Settings → Secrets:

| Provider | Secret Name | Token Source |
|----------|-------------|-------------|
| Cloudflare Workers | `CLOUDFLARE_API_TOKEN` | Dashboard → API Tokens |
| Fly.io | `FLY_API_TOKEN` | `flyctl auth token` |
| Vercel | `VERCEL_TOKEN` | Settings → Tokens |
| Railway | `RAILWAY_TOKEN` | Settings → Tokens |
| Docker Registry | `REGISTRY_TOKEN` | Registry → Access Tokens |
| VPS/SSH | `SSH_PRIVATE_KEY` + `SSH_HOST` | Your server |

---

## 2. package.json

```json
{
  "name": "my-api",
  "version": "1.0.0",
  "type": "module",
  "license": "MIT",
  "private": true,
  "engines": { "bun": ">=1.1.0" },

  "keywords": ["api", "typescript", "bun"],

  "scripts": {
    "build": "bun build src/index.ts --outdir dist --target bun",
    "start": "bun run dist/index.js",
    "dev": "bun run --watch src/index.ts",
    "prepare": "bun .husky/install.mjs",
    "test": "bun test",
    "typecheck": "tsc --noEmit",
    "format": "prettier --write ."
  }
}
```

**Key differences from npm packages:**
- `private: true` — prevents accidental publish
- No `publishConfig`, `files`, `bin`, `prepublishOnly`
- Add `start` + `dev` scripts
- `prepare` for husky auto-install (skips in CI)
- No `exports`/`sideEffects` (unless library sub-package)

### .env.example

```bash
# Copy to .env and fill in values
PORT=3000
DATABASE_URL=postgres://...
API_SECRET=changeme
```

Never commit `.env`. Always commit `.env.example`.

---

## 3. Conventional Commits

```
feat: add user auth endpoint    → bumps MINOR (1.0.0 → 1.1.0)
fix: handle null body           → bumps PATCH (1.0.0 → 1.0.1)
perf: cache db queries          → bumps PATCH
docs: document auth flow        → no bump
chore: update deps              → no bump
feat!: drop v1 auth             → bumps MAJOR (1.0.0 → 2.0.0)
```

Enforce with `commitlint` + `husky`:
```bash
bun add -D @commitlint/cli @commitlint/config-conventional husky
bunx husky init
echo "bunx commitlint --edit \$1" > .husky/commit-msg
```

**Pre-commit hook** — run tests before every commit:
```bash
echo "bun test" > .husky/pre-commit
```

**Smart husky install** — skip in CI/production. `.husky/install.mjs`:
```js
if (process.env.NODE_ENV === 'production' || process.env.CI === 'true') {
  process.exit(0)
}
const husky = (await import('husky')).default
console.log(husky())
```

Wire it up in `package.json`:
```json
"scripts": {
  "prepare": "bun .husky/install.mjs"
}
```

`commitlint.config.js`:
```js
export default { extends: ['@commitlint/config-conventional'] }
```

Add to CI workflow (uses PR base/head SHAs for accurate diff):
```yaml
- name: Lint commits
  run: |
    if [ "${{ github.event_name }}" = "pull_request" ]; then
      bunx commitlint --from "${{ github.event.pull_request.base.sha }}" --to "${{ github.event.pull_request.head.sha }}" --verbose
    else
      bunx commitlint --last --verbose
    fi
```

---

## 4. Lockfile + .gitattributes

```bash
bun install          # generates bun.lock
git add bun.lock
```

`.gitignore` must NOT include `bun.lock`.

`.gitattributes`:
```
* text=auto eol=lf
*.ts text eol=lf
*.json text eol=lf
*.md text eol=lf
*.yml text eol=lf
*.yaml text eol=lf
```

CI uses `bun install --frozen-lockfile`.

### .prettierrc

```json
{
  "printWidth": 100,
  "tabWidth": 2,
  "semi": false,
  "singleQuote": true,
  "trailingComma": "none"
}
```

`.prettierignore`:
```
node_modules
bun.lock
```

---

## 5. TypeScript Config

```json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitReturns": true,
    "forceConsistentCasingInFileNames": true
  }
}
```

Enable `strict` from day one. Retrofitting is painful.

**As project grows**, add: `declaration: true` (emit `.d.ts` for consumers), `skipLibCheck: true` (faster typecheck), `types: ["bun-types"]` (Bun globals).

---

## 6. CI Workflow

`.github/workflows/ci.yml`:

```yaml
name: CI
on:
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6

      - uses: oven-sh/setup-bun@v2
        with:
          bun-version: latest

      - run: bun install --frozen-lockfile

      - name: Lint commits
        run: |
          if [ "${{ github.event_name }}" = "pull_request" ]; then
            bunx commitlint --from "${{ github.event.pull_request.base.sha }}" --to "${{ github.event.pull_request.head.sha }}" --verbose
          else
            bunx commitlint --last --verbose
          fi

      - run: bun run typecheck

      - run: bun test

      - run: bun run build
```

**Why pull_request only?** Commitlint needs base/head SHAs which only exist on PRs. Single-commit pushes to main would fail. Run tests via pre-commit hook + CI on PR instead.

**Optional — audit:** Add `bun audit` step after install to catch known vulnerabilities.

---

## 7. Release Automation

`.github/workflows/release-please.yml`:

```yaml
name: release-please
on:
  push:
    branches: [main]

permissions:
  contents: write
  pull-requests: write

jobs:
  release-please:
    runs-on: ubuntu-latest
    steps:
      - uses: googleapis/release-please-action@v5
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
          config-file: release-please-config.json
```

`release-please-config.json`:

```json
{
  "$schema": "https://raw.githubusercontent.com/googleapis/release-please/main/schemas/config.json",
  "release-type": "simple",
  "include-v-in-tag": true,
  "changelog-sections": [
    { "type": "feat", "section": "Features", "hidden": false },
    { "type": "fix", "section": "Bug Fixes", "hidden": false },
    { "type": "perf", "section": "Performance", "hidden": false },
    { "type": "docs", "section": "Documentation", "hidden": false },
    { "type": "refactor", "section": "Refactoring", "hidden": true },
    { "type": "test", "section": "Tests", "hidden": true },
    { "type": "chore", "section": "Chores", "hidden": true }
  ],
  "packages": {
    ".": {
      "changelog-path": "CHANGELOG.md"
    }
  }
}
```

**Also create `.release-please-manifest.json`** (required even for single package):
```json
{
  ".": "1.0.0"
}
```

**Note:** `release-type: "simple"` for API projects (not `"node"` — no npm publish).

---

## 8. Deploy Workflow

### Cloudflare Workers

`.github/workflows/deploy.yml`:

```yaml
name: Deploy
on:
  workflow_dispatch:
  release:
    types: [published]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - uses: oven-sh/setup-bun@v2
        with: { bun-version: latest }
      - run: bun install --frozen-lockfile
      - run: bun test
      - run: bun run build
      - run: bunx wrangler deploy
        env:
          CLOUDFLARE_API_TOKEN: ${{ secrets.CLOUDFLARE_API_TOKEN }}
      - name: Smoke test
        run: curl -sSf https://api.example.com/health
```

### Fly.io

```yaml
- uses: superfly/flyctl-actions/setup-flyctl@master
- run: flyctl deploy --remote-only
  env:
    FLY_API_TOKEN: ${{ secrets.FLY_API_TOKEN }}
```

### VPS via SSH

```yaml
- uses: appleboy/ssh-action@v1
  with:
    host: ${{ secrets.SSH_HOST }}
    username: deploy
    key: ${{ secrets.SSH_PRIVATE_KEY }}
    script: |
      cd /app && git pull origin main
      bun install --frozen-lockfile
      bun run build
      bun run start:prod
```

### Docker + Registry

```yaml
- run: docker build -t ghcr.io/user/my-api:${{ github.ref_name }} .
- run: docker push ghcr.io/user/my-api:${{ github.ref_name }}
  env:
    REGISTRY_TOKEN: ${{ secrets.REGISTRY_TOKEN }}
- run: |
    curl -X POST https://api.example.com/deploy \
      -H "Authorization: Bearer ${{ secrets.DEPLOY_KEY }}" \
      -d '{"image": "ghcr.io/user/my-api:${{ github.ref_name }}"}'
```

---

## 9. Environment Variables

### Staging vs Production

```yaml
env:
  NODE_ENV: ${{ github.ref_name == 'main' && 'production' || 'staging' }}

- run: bun run build --env $NODE_ENV
```

### GitHub Environments

Repo → Settings → Environments → Create `production`. Add protection rules (required reviewers, wait timer). Then:

```yaml
jobs:
  deploy:
    environment: production
    steps:
      - run: ./deploy.sh
        env:
          DATABASE_URL: ${{ secrets.PROD_DATABASE_URL }}
```

---

## 10. Rollback

### Git-based rollback

```bash
# Deploy previous release
git checkout v1.2.0
# Manual deploy or workflow_dispatch with tag input
```

### Cloudflare Workers

```bash
bunx wrangler rollback    # one-click rollback to previous deploy
```

### Docker

```bash
docker pull ghcr.io/user/my-api:v1.2.0   # previous image
docker run ... ghcr.io/user/my-api:v1.2.0
```

---

## 11. README Badges

```markdown
![CI](https://github.com/user/repo/actions/workflows/ci.yml/badge.svg)
![license](https://img.shields.io/github/license/user/repo)
```

---

## 12. PR Template

`.github/PULL_REQUEST_TEMPLATE.md`:

```markdown
## Summary

<!-- What does this PR do? -->

## Type

- [ ] feat (new feature)
- [ ] fix (bug fix)
- [ ] perf (performance)
- [ ] docs (documentation)
- [ ] chore (maintenance)
- [ ] refactor

## Checklist

- [ ] `bun run typecheck` passes
- [ ] `bun test` passes
- [ ] `bun run build` succeeds
- [ ] API docs updated if new endpoint
- [ ] `.env.example` updated if new env vars

## Testing

<!-- How did you test this? -->
```

---

## 13. Full Release Flow

```
git checkout -b feat/new-endpoint
# code...
git commit -m "feat: add user profile endpoint"
git push → open PR → CI runs → merge
  ↓
release-please opens Release PR
  → version bump + CHANGELOG.md
  → review → merge
  ↓
GitHub Release + git tag (v1.1.0)
  ↓
Deploy workflow triggers
  → bun install --frozen-lockfile
  → test + build
  → deploy command
  → smoke test
  ↓
Live ✅
```

### Emergency deploy
```bash
git checkout v1.2.0    # previous working version
git push origin v1.2.0
# Manual deploy via workflow_dispatch
```

---

## 14. Monorepo

### Structure
```
my-project/
├── package.json          # "workspaces": ["packages/*"], "private": true
├── bun.lock
└── packages/
    ├── api/
    │   ├── package.json
    │   └── src/
    ├── workers/
    │   ├── package.json
    │   └── src/
    └── shared/
        ├── package.json
        └── src/
```

### release-please

```json
{
  "release-type": "simple",
  "packages": {
    "packages/api": {},
    "packages/workers": {},
    "packages/shared": {}
  }
}
```

`.release-please-manifest.json` (required):
```json
{
  "packages/api": "1.2.0",
  "packages/workers": "0.5.0",
  "packages/shared": "1.0.0"
}
```

### CI — per-package matrix
```yaml
strategy:
  matrix:
    package: ['packages/api', 'packages/workers', 'packages/shared']
steps:
  - run: bun run --filter '${{ matrix.package }}' typecheck
  - run: bun test --filter '${{ matrix.package }}'
  - run: bun run --filter '${{ matrix.package }}' build
```

### Deploy — per-package
```yaml
- name: Deploy API
  if: contains(github.event.release.tag_name, 'packages/api')
  run: cd packages/api && bunx wrangler deploy

- name: Deploy Workers
  if: contains(github.event.release.tag_name, 'packages/workers')
  run: cd packages/workers && bunx wrangler deploy
```

### Bun workspace commands
```bash
bun run --filter @scope/api dev       # dev one package
bun run --filter '*' test             # test all
bun add hono --filter @scope/api      # add dep to one
bun add -D typescript -w              # add devDep to root
```

---

## 15. Production Checklist

- [ ] `private: true` in package.json
- [ ] `.env.example` committed (not `.env`)
- [ ] Cloud credentials in GitHub Secrets
- [ ] `bun.lock` committed
- [ ] `.prettierrc` + `.prettierignore` configured
- [ ] `.gitattributes` with LF line endings (include `*.yaml`)
- [ ] `tsconfig.json` strict: true
- [ ] `.husky/commit-msg` runs commitlint
- [ ] `.husky/pre-commit` runs tests
- [ ] `.husky/install.mjs` skips in CI
- [ ] `.github/workflows/ci.yml` exists (PR trigger + commitlint)
- [ ] `.github/workflows/release-please.yml` exists
- [ ] `release-please-config.json` configured (`release-type: simple`)
- [ ] `.release-please-manifest.json` exists
- [ ] `.github/workflows/deploy.yml` exists
- [ ] `.github/PULL_REQUEST_TEMPLATE.md` exists
- [ ] `CHANGELOG.md` exists
- [ ] README badges (CI, license)
- [ ] Smoke test after deploy
- [ ] Rollback plan documented
- [ ] Environment protection rules for production
