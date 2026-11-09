# shadcn-vue & UI Component Mapping

All UI elements in modules MUST use components from `@/components/uic/` (built on `reka-ui` v2).
> **Auto-Import Rule**: In `.vue` files, `unplugin-vue-components` auto-imports all components from `src/components/`. Only import them explicitly when referencing them in `.ts` files or dynamic `:is="..."` bindings.

---

## Component → Module Concern

| Module Concern | Components | Source Path (for `.ts` / `:is`) |
|---|---|---|
| **Action buttons** | `Button` | `@/components/uic/button` |
| **Form fields (`v-model` wrappers — PREFERRED)** | `InputField`, `SelectField`, `AsyncSelectField`, `CheckboxField` | `@/components/uic/{input,select,checkbox}` |
| **Form primitives (only when wrapper doesn't fit)** | `Input`, `Textarea`, `Select`, `Switch`, `RadioGroup` | `@/components/uic/{component}` |
| **Form validation** | `FormField`, `FormItem`, `FormLabel`, `FormControl`, `FormMessage` | `@/components/uic/form` |
| **Form layout wrapper** | `FormContainer` | `@/components/ui/FormContainer.vue` |
| **Delete confirmation** | `AlertDialog`, `AlertDialogAction`, `AlertDialogCancel`, `AlertDialogContent`, `AlertDialogDescription`, `AlertDialogFooter`, `AlertDialogHeader`, `AlertDialogTitle` | `@/components/uic/alert-dialog` |
| **Create/Edit modals** | `Dialog`, `DialogContent`, `DialogDescription`, `DialogFooter`, `DialogHeader`, `DialogTitle`, `DialogTrigger` | `@/components/uic/dialog` |
| **Slide-over panels** | `Sheet`, `SheetContent`, `SheetDescription`, `SheetFooter`, `SheetHeader`, `SheetTitle`, `SheetTrigger` | `@/components/uic/sheet` |
| **Row action menus** | `DropdownMenu`, `DropdownMenuContent`, `DropdownMenuItem`, `DropdownMenuTrigger` | `@/components/uic/dropdown-menu` |
| **Status display** | `StatusBadge`, `Badge` | `@/components/uic/StatusBadge.vue`, `@/components/uic/badge` |
| **Stats cards** | `Card`, `CardContent`, `CardDescription`, `CardHeader`, `CardTitle` | `@/components/uic/card` |
| **Loading states** | `Skeleton`, `Spinner` | `@/components/uic/skeleton`, `@/components/uic/spinner` |
| **Tooltips** | `Tooltip`, `TooltipContent`, `TooltipProvider`, `TooltipTrigger` | `@/components/uic/tooltip` |
| **Notifications** | `toast` (from `vue-sonner`) | `vue-sonner` |
| **Date pickers** | `Calendar`, `DatePicker` | `@/components/uic/calendar`, `@/components/uic/date-picker` |
| **Tabs** | `Tabs`, `TabsContent`, `TabsList`, `TabsTrigger` | `@/components/uic/tabs` |
| **Data tables** | `DataTable`, `DataTableFilters`, `Table`, `TableBody`, `TableCell`, `TableHead`, `TableHeader`, `TableRow` | `@/components/uic/table` |
| **Popovers / Combobox** | `Popover`, `Command`, `CommandInput`, `CommandList`, `CommandItem` | `@/components/uic/popover`, `@/components/uic/command` |
| **Number / Tag inputs** | `NumberField`, `TagsInput` | `@/components/uic/number-field`, `@/components/uic/tags-input` |
| **Permission guard** | `PermGuard` (`v-can` directive) | `@/components/common/` |
| **Branding** | `Logo` | `@/components/common/Logo.vue` (never raw `<img>`) |

---

## Icons

Use **`@hugeicons/vue`** (`@hugeicons/core-free-icons`) or **`lucide-vue-next`**:

```ts
import { HugeiconsIcon } from '@hugeicons/vue'
import { ShoppingBasket01Icon } from '@hugeicons/core-free-icons'
// Or Lucide fallback:
import { Eye, Edit, Trash2, MoreHorizontal, Plus, Search, Filter, Download, Upload } from 'lucide-vue-next'
```

---

## Theming & CSS Classes

- **CSS Variables**: Always prefer CSS variables (`var(--background)`, `var(--primary)`, `--bg-main`, `--text-primary`) and Tailwind dark/light classes (`dark:bg-slate-800`) over hardcoded hex colors.
- **Neop utility classes**: `.neop-table`, `.neop-form-container`, `.neop-btn-save`.
- **Responsive view-mode variants**: Use `modal:` and `full:` Tailwind variants for forms rendered in modal vs full-page mode.
- **Class merging**: Use `cn()` from `@/utils/` (`clsx` + `tailwind-merge`).

---

## Toast Notifications & StatusBadge

```ts
import { toast } from 'vue-sonner'

toast.success(t('products.created_successfully', 'Product created successfully'))
toast.error(t('products.delete_failed', 'Failed to delete product'))
```

```vue
<StatusBadge :status="{ value: row.status, label: row.status_label }" />
```

---

## Troubleshooting

| Problem | Fix |
|---|---|
| Component not found | Run `npx shadcn-vue@latest add {component}` |
| Redundant imports warning | Run `node scripts/strip-auto-imports.mjs` |
| Reka UI vs Radix Vue | Never mix — this project uses **Reka UI v2** |
| Detailed component docs | Read `.agents/skills/shadcn-vue/components/{component-name}.md` |
