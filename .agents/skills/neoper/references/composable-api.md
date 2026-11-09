# Composable API Reference

Complete signatures and return values for all shared composables in `src/composables/shared/`.

---

## useTable<T>

**Import**: `import { useTable } from '@/composables/shared/useTable'`

### Options

```ts
useTable<T>({
  fetchFn,           // (params) => Promise<{ data: T[], total: number }>
  queryKey,          // TanStack query key (defaults to [resourceName])
  resourceName,      // String — used for query key + filter store
  defaultPerPage,    // Number (default: 10)
  defaultStatus,     // 'all' | 'active' | etc.
  filterConfig,      // From defineFilters()
  formatter,         // { toTable: (item) => transformedRow }
  mockData,          // T[] for offline dev
  immediate,         // boolean — auto-fetch on mount
  watchKeys,         // WatchSource[] — auto-refetch triggers
  onSuccess,         // (data) => void
  onError,           // (error) => void
  refetchOnFocus,    // boolean (default: false)
})
```

### Returns

`items`, `rawItems`, `totalItems`, `loading`, `error`, `forbidden`, `page`, `perPage`, `totalPages`, `searchQuery`, `setSearchQuery`, `sortBy`, `sortOrder`, `setSorting`, `toggleSort`, `activeFilters`, `setFilters`, `clearFilters`, `hasActiveFilters`, `activeFilterCount`, `selectedItems`, `onSelectionChange`, `clearSelection`, `refresh`, `resetAll`

### Real-world Example (from useContactsTab)

```ts
const table = useTable<ContactRow>({
  resourceName: 'contacts',
  fetchFn: (params) => {
    if (!can('contacts.view'))
      return Promise.resolve({ data: [], total: 0 })
    return workspaceContactsService
      .list({
        limit: (params?.limit as number) ?? 15,
        page: (params?.page as number) ?? 1,
        search: params?.search as string,
        sort_by: (params?.sort_by as string) ?? 'created_at',
        sort_dir: (params?.sort_dir as string) ?? 'desc',
        filters: Object.keys(filters).length > 0 ? filters : undefined,
        _suppress403Toast: true,
      } as any)
      .then((res) => ({
        data: res.data as ContactRow[],
        total: res.meta?.total ?? res.data.length,
      }))
  },
  defaultPerPage: 15,
  immediate: can('contacts.view'),
})
```

---

## useForm<T>

**Import**: `import { useForm } from '@/composables/shared/useForm'`

### Options

```ts
useForm<T>({
  resourceName,          // String — for success/error messages + query invalidation
  schema,                // ZodTypeAny | Ref<ZodTypeAny> | ComputedRef<ZodTypeAny>
  initialValues,         // Record<string, any>
  action,                // 'create' | 'update' | 'custom' (default: 'create')
  mutationFn,            // (data: any) => Promise<T | void>
  onSuccess,             // (data: T | void) => void
  onError,               // (err: unknown) => void
  successMessage,        // Custom success message
  showNotifications,     // boolean (default: true)
  confirmBeforeSubmit,   // boolean — show confirmation dialog
  confirmTitle,          // Custom title for confirmation dialog
  confirmMessage,        // Custom message for confirmation dialog
  confirmLabel,          // Label for confirm button
  cancelLabel,           // Label for cancel button
})
```

### Returns

Everything from vee-validate's `useForm` PLUS:
- `onSubmit` — validated submit handler
- `displayErrors` — errors shown only after first submit attempt
- `canSubmit` — silent reactive validation (for disabling buttons)
- `isPending` — mutation loading state
- `showConfirmDialog`, `executeSubmit`, `cancelSubmit` — confirmation flow
- `mapApiErrors` — auto-maps 422 API errors to form fields

### Usage

```ts
const { t } = useI18n()
const form = useForm({
  resourceName: 'product',
  schema: computed(() => productFormSchema(t)),
  initialValues: { name: '', sku: '', price: 0 },
  action: 'create',
  mutationFn: (data) => productsService.create(data),
  onSuccess: () => router.push({ name: 'products-list' }),
  confirmBeforeSubmit: true,
  confirmTitle: 'Create Product?',
})
```

---

## useDetails<T>

**Import**: `import { useDetails } from '@/composables/shared/useDetails'`

### Options & Returns

```ts
const { item, loading, error, refresh } = useDetails<Product>({
  resourceName: 'products',
  getFn: (id) => productsService.get(id, { include: 'category' }),
  autoLoadId: true,   // reads :id from route params automatically
  // Optional:
  id: ref(someId),    // explicit ID (overridden by autoLoadId if set)
  queryKey: [...],    // custom TanStack query key
})
```

Uses `@tanstack/vue-query` internally. `autoLoadId` reads `route.params.id`.

---

## useModal<T>

**Import**: `import { useModal } from '@/composables/shared/useModal'`

### Options & Returns

```ts
const modal = useModal<Product>({
  onFetchOne: (id) => productsService.get(id),
  getFormData: () => ({ ...currentItem }),
  clearErrors: () => form.resetForm(),
  // Optional:
  onCreate: (data) => productsService.create(data),
  onEdit: (id, data) => productsService.update(id, data),
})

// Returns:
// modal.showCreate, modal.showEdit, modal.showView
// modal.openCreate(), modal.openEdit(id), modal.openView(id)
// modal.closeCreate(), modal.closeEdit(), modal.closeView()
// modal.handleCreate(), modal.handleEdit()
// modal.selectedId, modal.createFormData, modal.editFormData
```

---

## defineFilters

**Import**: `import { defineFilters } from '@/composables/shared/useFilters'`

### Usage

```ts
const filterConfig = defineFilters('{module}', [
  // Static options (values auto-derive i18n labels)
  { key: 'status', type: 'select', values: ['active', 'inactive'] },

  // API endpoint options
  { key: 'category_id', type: 'select',
    endpoint: () => categoriesService.dropdown(),
    labelKey: 'name', valueKey: 'id' },

  // Boolean toggle
  { key: 'is_featured', type: 'toggle' },

  // Date range
  { key: 'created_at', type: 'dateRange' },

  // Multiselect with API endpoint
  { key: 'tag_ids', type: 'multiselect',
    endpoint: () => tagsService.list({ paginate: false }),
    valueKey: 'id', labelKey: 'name' },
])
```

Field types: `'text'` | `'select'` | `'multiselect'` | `'toggle'` | `'dateRange'`

Additional options per field: `label`, `options`, `optionPrefix`, `alias`, `transform`, `placeholder`

---

## useCan

**Import**: `import { useCan } from '@/composables/shared/useCan'`

```ts
const { can, canAny, canAll, canResource } = useCan()

can('products.view')                          // single permission
canAny(['products.view', 'products.manage'])  // any of these
canResource('products', 'delete')             // resource.action format
```

---

## useConfirm

**Import**: `import { useConfirm } from '@/composables/shared/useConfirm'`

```ts
const { confirm, confirmState, cancel } = useConfirm()

function handleDelete(id: number) {
  confirm('Delete Product', 'Are you sure?', async () => {
    await productsService.delete(id)
    cancel()
    await table.refresh()
  })
}
```

`confirmState` is a ref with: `{ show, title, message, callback }`.

---

## usePageHeader

**Import**: `import { usePageHeader } from '@/composables/shared/usePageHeader'`

```ts
const { setPageHeader, clearPageHeader } = usePageHeader()

onMounted(() => {
  setPageHeader({
    title: t('products.title', 'Products'),
    description: t('products.description', 'Manage your product catalog.'),
    actions: ProductsHeaderActions,   // Optional Vue component
    showBackButton: false,            // Optional
    titleBadge: null,                 // Optional Vue component
  })
})
```

Returns: `pageTitle`, `pageDescription`, `pageActions`, `pageShowBackButton`, `pageTitleBadge`, `setPageHeader`, `clearPageHeader`

---

## useFormatter

**Import**: `import { useFormatter } from '@/composables/shared/useFormatter'`

```ts
const { formatForTable, formatForForm, formatForApi } = useFormatter({
  formatter: {
    toTable: (item) => ({ ...item, priceFormatted: `$${item.price.toFixed(2)}` }),
    toForm: (item) => ({ ...item }),
    toApi: (formData, mode) => ({ ...formData }),
  },
})
```

---

## useImportExport

**Import**: `import { useImportExport } from '@/composables/shared/useImportExport'`

```ts
const ie = useImportExport({
  resourceName: 'products',
  service: productsService,
  columns: [
    { key: 'name', label: 'Name', required: true },
    { key: 'sku', label: 'SKU', required: true },
    { key: 'price', label: 'Price', type: 'number' },
  ],
})
```
