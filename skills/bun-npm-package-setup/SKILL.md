---
name: bun-npm-package-setup
description: Scaffold production-ready TypeScript npm packages with Bun, Conventional Commits, commitlint+husky, GitHub Actions CI, release-please, npm publish with OIDC provenance, and monorepo support. Use when creating a new npm package, setting up CI/CD for a TypeScript library/CLI, or configuring automated npm publishing.
---

# Production-Ready npm Package Setup

Complete guide for TypeScript npm packages — from `git init` to automated publish. Self-contained. Written for Bun + GitHub Actions.

---

## 1. Prerequisites

### GitHub ↔ npm OIDC

1. npmjs.com → Your package → Settings → Access → Add GitHub Account
2. Enter `owner/repo`
3. No token needed — GitHub Actions OIDC authorizes publish

### npm 2FA

npmjs.com → Account → Two-Factor Authentication → Enable TOTP. Required for publishing.

---

## 2. package.json

```json
{
  "name": "my-package",
  "version": "1.0.0",
  "description": "What it does in one line",
  "type": "module",
  "license": "MIT",
  "sideEffects": false,

  "publishConfig": { "access": "public" },

  "bin": { "my-cli": "./dist/cli.js" },

  "files": ["dist", "README.md"],

  "engines": { "bun": ">=1.1.0" },

  "exports": {
    ".": { "import": "./dist/index.js", "types": "./dist/index.d.ts" },
    "./utils": { "import": "./dist/utils.js", "types": "./dist/utils.d.ts" }
  },

  "keywords": ["typescript", "bun", "cli"],

  "repository": {
    "type": "git",
    "url": "git+https://github.com/username/my-package.git"
  },

  "bugs": {
    "url": "https://github.com/username/my-package/issues"
  },

  "homepage": "https://github.com/username/my-package#readme",

  "funding": {
    "type": "github",
    "url": "https://github.com/sponsors/username"
  },

  "scripts": {
    "build": "bun build src/index.ts --outdir dist --target bun",
    "prepublishOnly": "bun run build && bun test && bun run typecheck",
    "prepare": "bun .husky/install.mjs",
    "publish:dry": "npm pack --dry-run",
    "test": "bun test",
    "typecheck": "tsc --noEmit",
    "format": "prettier --write ."
  }
}
```

**CLI-only package?** Use a simple string for `exports`:
```json
"exports": "./dist/cli.js"
```

**Multi-entry build?** Chain with `&&`:
```json
"build": "bun build src/cli.ts --outdir dist --target bun && bun build src/server.ts --outdir dist --target bun"
```

### Field reference

| Field | Required? | Purpose |
|-------|-----------|---------|
| `publishConfig.access` | Yes | Public package |
| `files` | Yes | Only dist + README ship |
| `bin` | CLI only | `bunx my-cli` entry |
| `exports` | Library | Modern entry + subpath imports |
| `repository` | Yes | npm sidebar link + provenance |
| `bugs` | Recommended | Issue tracker link |
| `homepage` | Recommended | Repo/docs link |
| `sideEffects` | Library | Enables tree-shaking |
| `engines` | Yes | Runtime constraint |
| `keywords` | Yes | npm discoverability (10-15) |
| `funding` | Optional | Sponsor button |
| `prepublishOnly` | Yes | Build+test+typecheck before publish |
| `prepare` | Recommended | Husky auto-install (skips in CI) |
| `publish:dry` | Recommended | Preview what ships |

---

## 3. Conventional Commits

```
feat: add new feature           → bumps MINOR (1.0.0 → 1.1.0)
fix: handle edge case           → bumps PATCH (1.0.0 → 1.0.1)
perf: improve speed             → bumps PATCH
docs: update readme             → no bump
chore: update deps              → no bump
feat!: drop old API             → bumps MAJOR (1.0.0 → 2.0.0)
```

Breaking change: add `!` after type or `BREAKING CHANGE:` in body.

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

CI uses `bun install --frozen-lockfile` — fails if lockfile out of sync.

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
  workflow_call:

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

`workflow_call` makes CI reusable — called from release workflow as gate before release-please.

**Why pull_request + workflow_call?** Commitlint uses PR base/head SHAs on PRs; falls back to `--last` when called via workflow_call (push to main).

**Optional — audit:** Add `bun audit` step after install to catch known vulnerabilities.

**Optional — multi-platform matrix:**
```yaml
strategy:
  matrix:
    os: [ubuntu-latest, macos-latest, windows-latest]
    bun: ['1.1.0', 'latest']
```

---

## 7. Release Automation

**Single workflow** — CI gate + release-please + npm publish. No duplication.

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
  ci:
    uses: ./.github/workflows/ci.yml

  release-please:
    needs: ci
    runs-on: ubuntu-latest
    outputs:
      release_created: ${{ steps.release.outputs.release_created }}
    steps:
      - uses: googleapis/release-please-action@v5
        id: release
        with:
          config-file: release-please-config.json

  npm-publish:
    needs: release-please
    if: ${{ needs.release-please.outputs.release_created }}
    runs-on: ubuntu-latest
    permissions:
      contents: read
      id-token: write
    steps:
      - uses: actions/checkout@v6
      - uses: oven-sh/setup-bun@v2
        with:
          bun-version: latest
      - uses: actions/setup-node@v6
        with:
          node-version: latest
          registry-url: 'https://registry.npmjs.org'

      - run: bun install --frozen-lockfile
      - run: npm publish --provenance
```

**Flow:** push to main → CI (typecheck + test + build) → release-please → if release created → npm publish + smoke test.

**Why both Bun and Node?** `bun install` needed for `prepublishOnly` (build + test + typecheck). `npm publish --provenance` needed because `bun publish` does not support OIDC/provenance yet ([bun#15601](https://github.com/oven-sh/bun/issues/15601)).

`release-please-config.json`:

```json
{
  "$schema": "https://raw.githubusercontent.com/googleapis/release-please/main/schemas/config.json",
  "release-type": "node",
  "include-v-in-tag": true,
  "changelog-sections": [
    { "type": "feat", "section": "Features" },
    { "type": "fix", "section": "Bug Fixes" },
    { "type": "perf", "section": "Performance" },
    { "type": "docs", "section": "Documentation" },
    { "type": "refactor", "section": "Refactoring", "hidden": true },
    { "type": "test", "section": "Tests", "hidden": true },
    { "type": "chore", "section": "Chores", "hidden": true }
  ],
  "packages": {
    ".": {
      "changelog-path": "CHANGELOG.md",
      "bump-minor-pre-major": true,
      "bump-patch-for-minor-pre-major": true
    }
  }
}
```

**Also create `.release-please-manifest.json`** (required even for single packages):
```json
{
  ".": "1.0.0"
}
```

**How it works:** Push to main → Release PR opens (version bump + changelog) → review → merge → git tag + GitHub Release.

---

---

## 8. npm Provenance (OIDC)

```
**Important:** `bun publish` does not support OIDC/provenance yet ([bun#15601](https://github.com/oven-sh/bun/issues/15601)). Use `npm publish --provenance` with `actions/setup-node@v6`.

Workflow runs
  → id-token: write permission
  → GitHub provides OIDC token
  → npm publish --provenance exchanges it
  → npm verifies: "came from repo X, workflow Y, commit Z"
  → Package page shows "Built and signed on GitHub Actions"
```

Verify: npm package page → Provenance tab → shows commit hash + workflow file.

---

## 9. README Badges

```markdown
![CI](https://github.com/user/repo/actions/workflows/ci.yml/badge.svg)
![npm](https://img.shields.io/npm/v/my-package)
![license](https://img.shields.io/npm/l/my-package)
```

---

## 10. PR Template

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
- [ ] Docs updated if needed

## Testing

<!-- How did you test this? -->
```

---

## 11. npm Maintenance

### Deprecate old versions
```bash
npm deprecate my-package@"< 1.0.0" "Upgrade to v1.x — security fixes"
```

Users see warning on install. Doesn't unpublish — just warns.

### Emergency manual publish
```bash
git checkout main && git pull
npm version minor -m "chore: release %s"
git push --follow-tags
# Release triggers publish workflow
```

### Preview what ships
```bash
bun run publish:dry    # requires: "publish:dry": "npm pack --dry-run"
```

---

## 12. Full Release Flow

```
git checkout -b feat/new-feature
# code...
# pre-commit hook runs `bun test`
git commit -m "feat: add new feature"
git push → open PR → CI runs → merge
  ↓
release-please opens Release PR
  → version bump + CHANGELOG.md
  → review → merge
  ↓
GitHub Release + git tag (v1.1.0)
  ↓
release-please workflow on push to main:
  → CI runs (typecheck + test + build)
  → release-please job (only if CI passed)
  → if release_created:
    → npm-publish job
    → bun install --frozen-lockfile
    → prepublishOnly (build + test + typecheck)
    → npm publish --provenance (via setup-node)
    → smoke test
  ↓
Live on npm ✅
```

---

## 13. Monorepo

### Structure
```
my-project/
├── package.json          # "workspaces": ["packages/*"], "private": true
├── bun.lock
└── packages/
    ├── core/package.json
    ├── cli/package.json
    └── shared/package.json
```

### release-please

`release-please-config.json`:
```json
{
  "release-type": "node",
  "plugins": ["node-workspace"],
  "packages": {
    "packages/core": {},
    "packages/cli": {},
    "packages/shared": {}
  }
}
```

`.release-please-manifest.json` (required for monorepos):
```json
{
  "packages/core": "1.2.0",
  "packages/cli": "0.8.1",
  "packages/shared": "1.0.0"
}
```

### CI — per-package matrix
```yaml
strategy:
  matrix:
    package: ['packages/core', 'packages/cli', 'packages/shared']
steps:
  - run: bun run --filter '${{ matrix.package }}' typecheck
  - run: bun test --filter '${{ matrix.package }}'
  - run: bun run --filter '${{ matrix.package }}' build
```

### Publishing — per-package
```yaml
- uses: actions/setup-node@v6
  with:
    node-version: latest
    registry-url: 'https://registry.npmjs.org'
- run: cd ${{ github.event.release.tag_name }} && npm publish --provenance --access public
```

### Bun workspace commands
```bash
bun run --filter @scope/core build    # one package
bun run --filter '*' test             # all packages
bun add zod --filter @scope/core      # add dep to one
bun add -D typescript -w              # add devDep to root
```

---

## 14. Production Checklist

- [ ] `name` correct, available on npm
- [ ] `publishConfig.access: "public"`
- [ ] `files` lists only dist + README
- [ ] `bin` entry points to built CLI (if CLI)
- [ ] `exports` configured (if library)
- [ ] `repository`, `bugs`, `homepage` set
- [ ] `sideEffects: false` (if pure JS library)
- [ ] `keywords` filled (10-15)
- [ ] `prepublishOnly` runs build + test + typecheck
- [ ] `prepare` script for husky auto-install
- [ ] `publish:dry` script for preview
- [ ] `engines` declares runtime constraint
- [ ] `bun.lock` committed
- [ ] `.prettierrc` + `.prettierignore` configured
- [ ] `.gitattributes` with LF line endings (include `*.yaml`)
- [ ] `tsconfig.json` strict: true
- [ ] `.husky/commit-msg` runs commitlint
- [ ] `.husky/pre-commit` runs tests
- [ ] `.husky/install.mjs` skips in CI
- [ ] `.github/workflows/ci.yml` exists (PR trigger + commitlint)
- [ ] `.github/workflows/release-please.yml` exists (merged with publish)
- [ ] `release-please-config.json` configured
- [ ] `.release-please-manifest.json` exists
- [ ] `.github/PULL_REQUEST_TEMPLATE.md` exists
- [ ] `CHANGELOG.md` exists
- [ ] GitHub ↔ npm OIDC connected
- [ ] npm 2FA enabled
- [ ] README badges (CI, version)
- [ ] Smoke test in publish workflow
