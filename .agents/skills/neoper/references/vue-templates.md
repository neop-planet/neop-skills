# Vue Templates Reference

Complete view templates for module building. All views follow:
1. **Strict Composable/View Separation** (zero state/logic in `.vue` files)
2. **Auto-Import Rules** (`useI18n`, `useRouter`, `useTable`, `useForm`, `defineFilters`, and all `src/components/` `.vue` components are auto-imported — do NOT import them manually in `.vue` files)
3. **300-Line Rule** (split into `src/components/{module}/` sub-components when >300 lines)

---

## List View (Orchestrator + DataTable Tab)

```vue
<!-- src/views/admin/products/tabs/ProductsTab.vue -->
<script setup lang="ts">
import type { Product } from '@/types/entities/products'
import { Eye, MoreHorizontal, Trash2 } from 'lucide-vue-next'
import { useProductsTab } from '@/composables/products/useProductsTab'

const { t } = useI18n()
const {
  columns, filterConfig, table, analytics,
  handleSearch, handleSort, handleView,
  showDeleteDialog, isDeleting,
  handleDeleteClick, confirmDelete,
  can,
} = useProductsTab()
</script>

<template>
  <div class="flex flex-col gap-[24px]">
    <ProductsStats v-if="analytics" :analytics="analytics" />

    <DataTable
      v-model:selected="table.selectedItems.value"
      :data="(table.items.value as any[])"
      :loading="table.loading.value"
      :columns="columns"
      :total-items="table.totalItems.value"
      :page="table.page.value"
      :per-page="table.perPage.value"
      :table-enhancements="{ rowSelection: true }"
      select-all-records
      separated-records
      alternating-colors
      modern-search
      searchable
      filterable
      server-side
      :filter-config="filterConfig"
      @update:search="handleSearch"
      @update:page="table.goToPage($event)"
      @update:per-page="table.setPerPage($event)"
      @update:filters="table.setFilters"
      @sort="handleSort"
    >
      <template #name="{ row }">
        <span
          class="text-[14px] font-[500] text-[#475569] dark:text-slate-200 cursor-pointer hover:underline"
          @click="handleView(row as Product)"
        >
          {{ (row as Product).name }}
        </span>
      </template>

      <template #status="{ row }">
        <StatusBadge :status="{ value: (row as Product).status, label: (row as Product).status_label }" />
      </template>

      <template #actions="{ row }">
        <DropdownMenu>
          <DropdownMenuTrigger as-child>
            <button class="p-[6px] rounded-full hover:bg-white dark:hover:bg-slate-800 transition-all">
              <MoreHorizontal class="w-[14px] h-[14px] text-slate-400" />
            </button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end" class="rounded-[8px] p-[8px]">
            <DropdownMenuItem
              class="flex items-center gap-[8px] px-[8px] py-[12px] text-[14px] cursor-pointer"
              @click="handleView(row as Product)"
            >
              <Eye class="w-[14px] h-[14px]" /> {{ t('common.view', 'View') }}
            </DropdownMenuItem>
            <DropdownMenuItem
              v-if="can('products.manage')"
              class="flex items-center gap-[8px] px-[8px] py-[12px] text-[14px] text-red-500 cursor-pointer"
              @click="handleDeleteClick(row as Product)"
            >
              <Trash2 class="w-[14px] h-[14px]" /> {{ t('common.delete', 'Delete') }}
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      </template>
    </DataTable>
  </div>
</template>
```

> **Note on Slot-Based `<DataTable>` (`#header` + `#row`) + `<DataTableFilters>`**:
> In modules using explicit slot-based tables (see `GEMINI.md`), place `<DataTableFilters :fields="filterConfig.fields" :filters="table.activeFilters.value" @update:filters="table.setFilters" />` above `<DataTable>` and render `<template #header>` and `<template #row="{ row }">` directly. Check neighbouring modules in the target app (`client/` vs `super-admin/`) and match their DataTable mode.

---

## DataTable Props, Events & Slots

| Prop | Type | Description |
|------|------|-------------|
| `data` | `any[]` | Row data array |
| `columns` | `Column[]` | `{ key, label, sortable?, hidden?, editable? }` |
| `loading` | `boolean` | Show skeleton loader |
| `searchable` / `filterable` | `boolean` | Enable search input / filter UI |
| `filterConfig` | `FilterConfig` | Filter field definitions from `defineFilters()` |
| `serverSide` | `boolean` | Server-side pagination/search/filter |
| `totalItems` / `page` / `perPage` | `number` | Pagination state |
| `selected` | `(string\|number)[]` | Selected row IDs (`v-model:selected`) |
| `tableEnhancements` | `object` | `{ rowSelection: true, inlineEditing: true }` |
| `selectAllRecords` | `boolean` | Gmail-style "select all X records" banner |
| `separatedRecords` / `alternatingColors` | `boolean` | Visual row separation / zebra stripes |
| `modernSearch` | `boolean` | Modern inline search + filter popovers |

- **Events**: `update:search`, `update:page`, `update:perPage`, `update:filters`, `update:selected`, `sort (column, dir)`, `reorder`, `inlineEdit`
- **Slots**: `#columnKey="{ row, value }"`, `#head-columnKey="{ col }"`, `#actions="{ row }"`, `#toolbar`, `#header`, `#row`, `#empty`, `#modern-filter`

---

## Form View (Composable + Template)

All form setup lives in `use{Module}Form.ts`; the `.vue` view only binds the returned `form`:

```vue
<!-- src/views/admin/products/modals/ProductFormModal.vue -->
<script setup lang="ts">
import { useProductForm } from '@/composables/products/useProductForm'

const { t } = useI18n()
const { form, categories } = useProductForm()
</script>

<template>
  <form class="neop-form-container" @submit.prevent="form.onSubmit()">
    <FormField v-slot="{ componentField }" name="name">
      <FormItem>
        <FormLabel>{{ t('products.fields.name', 'Product Name') }}</FormLabel>
        <FormControl>
          <Input v-bind="componentField" />
        </FormControl>
        <FormMessage />
      </FormItem>
    </FormField>

    <FormField v-slot="{ componentField }" name="category_id">
      <FormItem>
        <FormLabel>{{ t('products.fields.category', 'Category') }}</FormLabel>
        <FormControl>
          <Select v-bind="componentField">
            <SelectTrigger>
              <SelectValue :placeholder="t('common.select', 'Select...')" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem v-for="cat in categories" :key="cat.id" :value="cat.id">
                {{ cat.name }}
              </SelectItem>
            </SelectContent>
          </Select>
        </FormControl>
        <FormMessage />
      </FormItem>
    </FormField>

    <Button type="submit" class="neop-btn-save" :disabled="!form.canSubmit.value || form.isPending.value">
      {{ form.isPending.value ? t('common.saving', 'Saving...') : t('common.save', 'Save') }}
    </Button>
  </form>
</template>
```

---

## Delete Confirmation (AlertDialog Sub-Component)

```vue
<!-- src/components/products/DeleteProductDialog.vue -->
<script setup lang="ts">
defineProps<{
  open: boolean
  loading: boolean
}>()
const emit = defineEmits<{
  confirm: []
  cancel: []
}>()
const { t } = useI18n()
</script>

<template>
  <AlertDialog :open="open" @update:open="val => !val && emit('cancel')">
    <AlertDialogContent>
      <AlertDialogHeader>
        <AlertDialogTitle>{{ t('common.confirm_delete', 'Confirm Delete') }}</AlertDialogTitle>
        <AlertDialogDescription>
          {{ t('products.delete_confirm_message', 'Are you sure you want to delete this product?') }}
        </AlertDialogDescription>
      </AlertDialogHeader>
      <AlertDialogFooter>
        <AlertDialogCancel @click="emit('cancel')">{{ t('common.cancel', 'Cancel') }}</AlertDialogCancel>
        <AlertDialogAction
          :disabled="loading"
          class="bg-red-500 hover:bg-red-600"
          @click="emit('confirm')"
        >
          {{ loading ? t('common.deleting', 'Deleting...') : t('common.delete', 'Delete') }}
        </AlertDialogAction>
      </AlertDialogFooter>
    </AlertDialogContent>
  </AlertDialog>
</template>
```

---

## Splitting a Large List Page (300-Line Rule)

When a view exceeds ~300 lines, extract sub-components (<200 lines each, props + emits only) into `src/components/{module}/`:

```vue
<!-- src/views/admin/products/tabs/ProductsTab.vue -->
<script setup lang="ts">
import { useProductsTab } from '@/composables/products/useProductsTab'

const {
  columns, filterConfig, table, analytics,
  handleSearch, handleSort, handleView,
  showDeleteDialog, isDeleting, handleDeleteClick, confirmDelete, cancelDelete,
  can,
} = useProductsTab()
</script>

<template>
  <div class="flex flex-col gap-[24px]">
    <ProductsStats :analytics="analytics" />
    <ProductsTable
      :columns="columns" :table="table" :filter-config="filterConfig" :can="can"
      @search="handleSearch" @sort="handleSort" @view="handleView" @delete="handleDeleteClick"
    />
    <DeleteProductDialog
      :open="showDeleteDialog" :loading="isDeleting"
      @confirm="confirmDelete" @cancel="cancelDelete"
    />
  </div>
</template>
```
