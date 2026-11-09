---
name: neoper
description: Build, scaffold, refactor, or review modules in the Seen monorepo (client/, super-admin/, and seen/ backend integration) following strict Neop architecture and project rules. Covers backend Resource/Request inspection, entity types, enums, createService (real + mock), Zod i18n schemas, composables (useTable, useForm, useDetails, useModal, defineFilters, useCan, usePageHeader), slot-based DataTable, FormContainer/FormField views, auto-imports, CSS variables, RBAC permissions, and i18n verification. Use whenever asked to "new module", "create module", "add feature", "scaffold module", "module builder", "build module", "neoper", or work on a Seen frontend module.
---

# Neoper — Seen Module Builder

Build and maintain modules in `client/` (user dashboard) and `super-admin/` (admin panel) aligned with `seen/` (Laravel `neop-ba` backend).

> **References** (load on demand):
> - `references/composable-api.md` — `useTable`, `useForm`, `useDetails`, `useModal`, `defineFilters`, `useCan`, `useConfirm`, `usePageHeader`, `useFormatter`, `useImportExport`
> - `references/vue-templates.md` — List view, Stats cards, DataTable slots, Form view, AlertDialog, 300-line sub-component splitting
> - `references/i18n-guide.md` — `en`/`ar` locale JSON structure, key naming, `bun run i18n:report`
> - `references/shadcn-mapping.md` — `@/components/uic/` mapping, Hugeicons/Lucide icons, `StatusBadge`, Sonner toasts
> - `references/advanced-patterns.md` — Multi-step wizards, domain-nested components, module state singletons, VueFlow canvas

## Monorepo Architecture

- **Frontend apps**: `client/src/` (`/user/v1/workspace/{module}`) and `super-admin/src/` (`/admin/v1/{module}`)
- **Backend API**: `seen/` (Laravel 12 + `neop-ba` — `BaseResource`, `BaseCrudController`, `BaseRequest`, `int`-backed `BackedEnum`)

```text
src/
  enums/{module}.ts               ← Const enum object + type + StatusVariantMap
  types/entities/{module}.ts      ← Entity interfaces (snake_case, mirrors Resource scopes)
  constants/endpoints.ts          ← Endpoint constants (or config/endpoints.ts)
  services/{module}Service.ts     ← API service via createService<T>()
  modules/{module}/schema.ts      ← Zod validation schema factory: schema(t)
  modules/{module}/index.ts       ← Router registration via registerModule()
  composables/{module}/           ← ALL state & logic: use{Module}Tab, use{Module}Form
  components/{module}/            ← Sub-components: {Module}Stats, {Module}Table, Delete{Module}Dialog
  views/admin/{module}/tabs/      ← Tab/list views ONLY
  views/admin/{module}/modals/    ← Modal/detail/form views ONLY
  i18n/locales/{en,ar}/{module}.json ← Bilingual translations
```

---

## Workflow — Build in Order

### Step 0 — Reference Docs & Backend Inspection (MANDATORY)
1. **External URLs provided?** Convert to local markdown first:
   ```bash
   mkdir -p docs/references/{subject}/
   web2md '<url>' -o docs/references/{subject}/{YYYY-MM-DD}-{name}.md # fallback: read_url_content
   ```
2. **Inspect `seen/` backend** — NEVER guess field names:
   ```bash
   find seen/app/Http/Resources seen/app/Http/Controllers seen/app/Enums seen/app/Http/Requests -name "*{Module}*"
   ```
   - **`{Module}Resource.php`**: Read `scopeDefinitions()` (`micro` for dropdowns, `mini` for tables, `full` for detail/edit) and `relationMappings()` (`?include=`). Check whether status uses `$this->status->toOption()` (`{ value, label }`) or raw `status` + `status_label`.
   - **`{Module}Request.php`**: Read `commonRules()`, `storeRules()`, `updateRules()` to mirror in Zod.
   - **Scaffold shortcut**: If starting fresh in `client/` or `super-admin/`, check if `bun make {module}` is available before writing boilerplate by hand.

### Step 1 — Enums & Entity Types
- `src/enums/{module}.ts`: Export `as const` object, type, and `StatusVariantMap` using `VARIANTS` from `@/utils/statusVariants`.
- `src/types/entities/{module}.ts`: Mirror backend `scopeDefinitions()` in `snake_case`, including optional guard booleans (`can_update?`, `can_delete?`).

### Step 2 — API Service
Create `src/services/{module}Service.ts` with `createService<T>('/user/v1/workspace/{module}')` (or `/admin/v1/{module}`).
- Provides: `list`, `dropdown`, `get`, `create`, `update`, `delete`, `toggle`, `export`, `import`.
- **Mock mode** (when backend WIP): `{ useMock: true, mockFields: mockFieldsFromKeys([...]), mockCount: 30 }`.

### Step 3 — Zod Validation Schema
Create `src/modules/{module}/schema.ts`. Always export a factory receiving `t`:
```ts
export function productFormSchema(t: (key: string, fallback?: string) => string) {
  return z.object({
    name: z.string({ required_error: t('products.validation.name_required', 'Name is required.') })
      .min(1, t('products.validation.name_required', 'Name is required.')),
  })
}
```

### Step 4 — Composables (`src/composables/{module}/`)
- **`use{Module}Tab.ts`**: Wires `useTable<T>`, `defineFilters()`, column defs, sort key map (`createdAt -> created_at`), delete confirmation, and `useCan()`.
- **`use{Module}Form.ts`**: Wires `useForm` with `schema: computed(() => schema(t))`, `mutationFn`, and `onSuccess`.
- Register new composable directory in `vite.config.ts` → `AutoImport.dirs` and re-export in `src/composables/index.ts` if shared.

### Step 5 — Components & Views
- Create `{Module}Stats.vue` (mandatory analytics cards for list views), table/dialog sub-components in `src/components/{module}/`.
- Create views in `src/views/admin/{module}/tabs/` and `modals/`. See `references/vue-templates.md`.

### Step 6 — Router & i18n Verification
- Register routes via `registerModule()` in `src/modules/{module}/index.ts`. Set `meta: { openMode: 'modal' | 'full', permission: '{module}.{action}' }`.
- Add all keys to `src/i18n/locales/en/{module}.json` and `ar/{module}.json`.
- Run verification before finishing:
  ```bash
  node scripts/strip-auto-imports.mjs 2>/dev/null || true
  bun run i18n:report && bun run lint
  ```

---

## Strict Project Rules

### 1. Ponytail (Laziness & Reuse First)
- **Reuse before writing**: Use `createService`, `useTable`, `useForm`, `useDetails`, `useModal`, `defineFilters`, `useConfirm`, `useImportExport`. Never re-implement pagination, debounce, 422 error mapping, or Axios wrappers.
- **No unrequested abstractions**: Fewest files and shortest diff that satisfies the module spec.

### 2. Composable / View Separation (#1 Architecture Rule)
- **ALL logic in composables**: `ref`, `computed`, `watch`, API calls, handlers, filter configs, schemas.
- **Views are pure template**: `<script setup lang="ts">` is 5–20 lines (destructuring composable only). Zero `ref()`, `computed()`, `watch()`, or handler declarations in `.vue` views.
- **300-Line Rule**: Split any `.vue` file >300 lines into `src/components/{module}/` sub-components (<200 lines each). Sub-components use **props + emits only** (never call composables directly).

### 3. Auto-Imports (No Redundant Imports)
- **DO NOT manually import** in `.vue` files:
  - Vue APIs (`ref`, `computed`, `watch`, `onMounted`, `nextTick`)
  - Router/Pinia/i18n (`useRoute`, `useRouter`, `defineStore`, `storeToRefs`, `useI18n`)
  - Shared composables & stores (`useTable`, `useForm`, `defineFilters`, `useCan`, `useAuthStore`, `useWorkspaceStore`, `usePermissionStore`)
  - Any `.vue` component in `src/components/` (`DataTable`, `Button`, `Input`, `StatusBadge`, etc.)
- **DO manually import**: Services (`@/services/...`), Types (`@/types/...`), Schemas (`@/modules/.../schema`), third-party libs (`vue-sonner`, icons), and components referenced inside `.ts` files.

### 4. Code Style, UI & Theming
- **SFC rules**: `<script setup lang="ts">` → `<template>` → `<style>` (never add custom `<style>` blocks; Tailwind v4 only). No consecutive empty lines (`bun clean:empty-lines`).
- **Theming**: Dark mode is default. Use CSS variables (`var(--background)`, `var(--primary)`, `--bg-main`, `--text-primary`) and explicit dark/light utility classes (`dark:bg-slate-800`). Use `neop-*` classes (`.neop-table`, `.neop-form-container`, `.neop-btn-save`) and `modal:` / `full:` layout variants.
- **Components & Icons**: Always use `@/components/uic/` (shadcn-vue on Reka UI v2). Prefer `*Field` wrappers that support `v-model` (`CheckboxField`, `InputField`, `SelectField`, `AsyncSelectField`) over raw `<Checkbox>`, `<Input>`, `<Select>`, or `<input>` elements. Use `@hugeicons/vue` (`@hugeicons/core-free-icons`) or `lucide-vue-next` for icons, `<Logo />` for branding.

### 5. API, Permissions (RBAC) & Naming
- **API**: Never use raw `fetch()` or fetch inside `onMounted()`. Always go through `createService` + TanStack Query composables. Pass `_suppress403Toast: true` on guarded background table fetches.
- **Permissions**: Gate `fetchFn` with `if (!can('{module}.view')) return Promise.resolve({ data: [], total: 0 })` and `immediate: can('{module}.view')`. Gate UI actions with `v-can="'{module}.manage'"`, `<PermGuard>`, or `v-if="can('{module}.manage')"`. Explicitly set `meta: { permission: '{module}.create' | '{module}.update' }` on mutating routes (overrides default `.view`).
- **Naming**: Resource names plural lowercase (`products`); Vue components `PascalCase.vue`; composables `use{Feature}.ts`; services `{module}Service.ts`; i18n `{module}.{section}.{key}` always with English fallback `t('key', 'Fallback')`; git commits **lowercase Conventional Commits** (`feat(products): add module`).

---

## Troubleshooting Protocol

1. **Stop guessing** if an API or payload mismatch persists.
2. **Inspect backend** (`seen/app/Http/Resources/...`, `seen/app/Http/Controllers/...`) or verify live via `curl` with workspace/auth headers.
3. **Backend bug?** Output a **Backend Fix Recommendation** (`Target File`, `Root Cause`, `Proposed Fix` following `seen/AGENTS.md` `neop-ba` rules: `final class`, `BaseResource::scopeDefinitions()`, `BaseCrudService`, `int`-backed TitleCase enums).
