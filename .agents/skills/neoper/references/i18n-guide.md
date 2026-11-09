# i18n Guide

Internationalization conventions for the Seen codebase.

---

## File Structure

Translation files live in `src/i18n/locales/{lang}/` with one JSON file per namespace (module):

```
src/i18n/locales/
  en/
    products.json        ← English translations for 'products' namespace
    common.json          ← Shared keys (buttons, labels, etc.)
  ar/
    products.json        ← Arabic translations
    common.json
```

The i18n loader (`src/i18n/index.ts`) uses `import.meta.glob` to eagerly load all JSON files per language, keyed by filename. So `products.json` becomes the `products` namespace.

---

## Key Naming Convention

```
{namespace}.{section}.{key}
```

Examples:
```
products.page_title              → "Products"
products.table.name              → "Product Name"
products.fields.status           → "Status"         (filter labels)
products.statuses.active         → "Active"         (status option labels)
products.create.title            → "Create Product"
products.create.name_label       → "Product Name"
products.detail.title            → "Product Details"
products.delete_success          → "Product deleted successfully"
```

---

## Usage in Code

Always use `t('key', 'Fallback')` with a fallback string:

```vue
<script setup lang="ts">
const { t } = useI18n()
</script>

<template>
  <h1>{{ t('products.page_title', 'Products') }}</h1>
  <!-- With interpolation -->
  <span>{{ t('products.delete_confirm', 'Delete {name}?', { name: product.name }) }}</span>
</template>
```

```ts
// In composables
const { t } = useI18n()
const columns = [
  { key: 'name', header: t('products.table.name', 'Product Name') },
]
toast.success(t('products.delete_success', 'Product deleted successfully'))
```

---

## Locale File Example

**EN** — `src/i18n/locales/en/products.json`:
```json
{
  "page_title": "Products",
  "page_desc": "Manage your product catalog.",
  "create_button": "Create Product",
  "table": {
    "name": "Product Name",
    "sku": "SKU",
    "price": "Price",
    "status": "Status"
  },
  "fields": {
    "status": "Status"
  },
  "statuses": {
    "active": "Active",
    "inactive": "Inactive"
  },
  "create": {
    "title": "Create Product",
    "name_label": "Product Name"
  },
  "delete_success": "Product deleted successfully"
}
```

**AR** — `src/i18n/locales/ar/products.json`:
```json
{
  "page_title": "المنتجات",
  "page_desc": "إدارة كتالوج المنتجات الخاص بك.",
  "create_button": "إنشاء منتج",
  "table": {
    "name": "اسم المنتج",
    "sku": "رمز التخزين",
    "price": "السعر",
    "status": "الحالة"
  },
  "fields": {
    "status": "الحالة"
  },
  "statuses": {
    "active": "نشط",
    "inactive": "غير نشط"
  },
  "create": {
    "title": "إنشاء منتج",
    "name_label": "اسم المنتج"
  },
  "delete_success": "تم حذف المنتج بنجاح"
}
```

---

## Standard Sections

| Section | Purpose | Example keys |
|---------|---------|-------------|
| Root level | Page-level strings | `page_title`, `page_desc`, `create_button` |
| `table.*` | DataTable column headers | `table.name`, `table.status` |
| `fields.*` | Filter field labels | `fields.status`, `fields.created_at` |
| `statuses.*` / `types.*` | Enum/option labels | `statuses.active`, `types.marketing` |
| `create.*` / `edit.*` | Form labels/placeholders | `create.title`, `create.name_label` |
| `detail.*` | Detail view sections | `detail.title`, `detail.general_summary` |
| Action results | Toast messages | `delete_success`, `delete_failed` |

---

## i18n Report

After adding `t()` calls, run:

```bash
bun run i18n:report
```

This scans all `.vue`, `.ts`, `.js`, `.tsx` files for `t()` / `$t()` calls and outputs `i18n-report.jsonc` with missing keys grouped by language.

**Rule**: The report should be empty (no missing keys) before considering a feature complete.
