---
name: neoper-fodooly
description: Pulls and summarizes daily changes across the Seen monorepo using "bk" (seen/ backend) and "fr" (client/ + super-admin/ frontend) shorthands. Translates backend Laravel/neop-ba commits (Resources, Requests, Enums, Controllers, routes) into actionable Neoper frontend tasks (types, enums, services, Zod schemas, composables, i18n) and vice versa. Use when the user says "neoper-fodooly", "fodooly", "bk", "fr", "what changed in bk", "what changed in fr", "pull bk", "pull fr", or asks for a daily digest.
---

# Neoper Fodooly (`bk` & `fr` Daily Digest)

Inspect recent commits in `bk` (`seen/`) or `fr` (`client/`, `super-admin/`) and output an actionable Neoper sync report.

## Workflow

### Step 1: Map Target (`bk` | `fr` | `all`)

| Shorthand | Monorepo Path(s) | Stack |
|-----------|------------------|-------|
| `bk` (default if unspecified) | `seen/` | Laravel 12 + `neop-ba` (`BaseResource`, `BaseRequest`, `BackedEnum`) |
| `fr` | `client/` + `super-admin/` | Vue 3 + Neoper (`types/entities`, `enums`, `services`, `schema.ts`, `composables`) |
| `client` / `super-admin` | Single frontend app | Vue 3 + Neoper |
| `all` / `both` | `seen/`, `client/`, `super-admin/` | Full monorepo sync |

### Step 2: Pull & List Commits Safely

Run the bundled script (fast-forward only, never touches dirty trees):

```bash
bash .agents/skills/neoper-fodooly/scripts/daily_digest.sh "<bk|fr|all>" "[since]" "[branch]"
```

- `since` defaults to `midnight`. Common values: `yesterday`, `"3 days ago"`, `2026-11-01`.
- If `0` commits since `midnight`, automatically re-run with `yesterday` (or inspect the last 5 commits if asked) and note the date range.

### Step 3: Inspect Diffs (Never Guess from Titles)

For every commit touching Neoper-relevant files, inspect the actual diff:

```bash
git -C <repo> show <hash> -- <files>
```

**How to translate `bk` (`seen/`) diffs into `fr` (`client/` & `super-admin/`) tasks:**
- `app/Http/Resources/*Resource.php` (`scopeDefinitions`: `micro`, `mini`, `full`; `relationMappings`; `toOption()`) → Update `src/types/entities/{module}.ts` (`snake_case` interfaces).
- `app/Http/Requests/*Request.php` (`commonRules`, `storeRules`, `updateRules`) → Update `src/modules/{module}/schema.ts` (`schema(t)` Zod rules) & `use{Module}Form.ts`.
- `app/Enums/*.php` (`int`-backed `BackedEnum`) → Update `src/enums/{module}.ts` (`as const` + `StatusVariantMap`).
- `routes/*.php` & `app/Http/Controllers/*Controller.php` → Update `src/constants/endpoints.ts` and `src/services/{module}Service.ts` (`/user/v1/workspace/{module}` for `client`, `/admin/v1/{module}` for `super-admin`).
- Permissions / middleware → Update `useCan('{module}.{action}')` and route `meta.permission`.

**How to summarize `fr` (`client/` & `super-admin/`) diffs:**
- Highlight new/updated modules, changed endpoints/services, schema validations, composable state changes, and missing `en`/`ar` i18n keys or client ↔ super-admin drift.

### Step 4: Output Report

Keep it scannable and reply in the user's language:

1. **Summary**: `X commits in [bk|fr] since [time] — Y require sync.`
2. **Breaking Changes** (first, if any): removed/renamed fields, changed types/enums, new required request fields, endpoint or permission changes.
3. **`bk` → `fr` Mapping** (or `fr` Change Digest):
   - **Endpoints & Services**: Method + path (`/user/v1/...` or `/admin/v1/...`), payload & `micro`/`mini`/`full` response shapes.
   - **Types, Enums & Zod**: Exact field/enum additions or validation rule updates.
4. **Neoper Action Checklist**: Concrete files to create/edit in `client/src/...` or `super-admin/src/...`.
5. **Ignored**: One line listing internal-only commits (refactors, CI, tests).

## Rules

- Never edit files in `seen/` when running a digest or force-pull/reset/clean any repo.
- Never invent payload shapes not in the diff; mark uncertain items `"unclear — check Resource/Request"`.
- Never paste secrets/tokens from diffs; warn if committed.
