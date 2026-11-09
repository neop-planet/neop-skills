---
name: neoper-backend
description: >
  Complete architecture guide for the Neop Base Backend (neop-ba) Laravel framework.
  Teaches all base classes, patterns, conventions, and code templates so Antigravity
  can generate perfectly-structured code without reading source files every conversation.
  Use this skill whenever working on any neop-ba project task or when asked for "neoper-backend" or "neoper backend".
---

# Neop Base Backend — Architecture Skill

## When to Use This Skill

Load this skill when:
- Creating any new file in a neop-ba project (controller, service, DTO, resource, etc.)
- Asked to scaffold a new module or feature
- Reviewing or fixing code that should follow neop-ba patterns
- Answering questions about how the framework works

---

## ⛔ IMPORTANT — Read Before Anything Else

This project uses a **STRICT custom architecture** (neop-ba).

You MUST prioritize:
- Custom architecture rules from **this skill**
- **NOT** default Laravel practices from Boost / `GEMINI.md`

If ANY conflict occurs between Boost (generic Laravel) and this skill → **follow this skill. Always.**

Examples of conflicts where this skill wins:
- Boost says use `FormRequest` → **this skill says use `BaseRequest`**
- Boost says use `JsonResource::toArray()` → **this skill says use `BaseResource::scopeDefinitions()`**
- Boost says put logic in controllers → **this skill says ALL logic goes in Services**
- Boost says use Eloquent directly → **this skill says use `BaseRepository`**
- Boost says use string enums → **this skill says ALWAYS `int`-backed**

---

## Architecture Flow

```
HTTP Request
    ↓
Controller  (BaseCrudController | BaseController + composable Traits)
    ↓
Service     (BaseCrudService | BaseService + composable Traits)
    ↓
Repository  (BaseRepository + BaseFilter)
    ↓
Model       (BaseModel | Eloquent\Model | Authenticatable)
    ↓
Response    (ApiResponse trait → JSON envelope)
```

---

## Layer Quick Reference

| Layer | Base Class | Key Rule |
|---|---|---|
| Controller | `BaseCrudController` | No DTOs, no logic — only validate → service → response |
| Service | `BaseCrudService` | ALL business logic, hooks, transactions, events |
| Repository | `BaseRepository` | DB ONLY — no cache, events, logic |
| Filter | `BaseFilter` | Separate query filter logic from repository |
| DTO | `BaseDTO` | Immutable, `readonly`, declared on **Service** |
| Request | `BaseRequest` | `commonRules()` + auto-unique-ignore |
| Resource | `BaseResource` | `scopeDefinitions()` micro/mini/full, auto-translation, `applyVisibilityOverrides()` |
| Model | `BaseModel` | Opt-in: audit, media, translations |
| Enum | `BackedEnum` + `BaseEnumTrait` | Always `int`, TitleCase cases |
| Response | `ApiResponse` trait | Never `response()->json()` |

---

## Code Templates

### Controller — Full CRUD

```php
<?php
declare(strict_types=1);

namespace App\Http\Controllers\Api\Admin\V1\Products;

use App\Core\Base\Controllers\BaseCrudController;
use App\Http\Requests\ProductRequest;
use App\Http\Resources\ProductResource;
use App\Services\Products\ProductService;

/**
 * @extends BaseCrudController<ProductService>
 */
final class ProductController extends BaseCrudController
{
    public function __construct(ProductService $service)
    {
        parent::__construct(
            service: $service,
            resourceClass: ProductResource::class,
            requestClass: ProductRequest::class,
        );
    }

    protected function getIndexRelations(): array
    {
        return ['category'];
    }

    protected function getShowRelations(): array
    {
        return ['category:id,name', 'tags', 'reviews_count'];
    }
}
```

### Controller — Read-Only (custom traits)

```php
/**
 * @extends BaseController<ReportService>
 */
final class ReportController extends BaseController
{
    use HasIndex;
    use HasShow;

    public function __construct(ReportService $service)
    {
        parent::__construct(service: $service, resourceClass: ReportResource::class);
    }
}
```

### Controller — Toggle

```php
// Default (column = 'status'):
return $this->toggle($id);

// Custom column:
public function toggleActive(int $id): JsonResponse
{
    return $this->toggle($id, 'is_active');
}
```

---

### Service — Full CRUD

```php
<?php
declare(strict_types=1);

namespace App\Services\Products;

use App\Core\Base\Services\BaseCrudService;
use App\Core\Contracts\DTOContract;
use App\Core\Exceptions\BusinessException;
use App\DTOs\Products\CreateProductDTO;
use App\DTOs\Products\UpdateProductDTO;
use App\Events\Products\ProductCreated;
use App\Repositories\Contracts\ProductContract;
use Illuminate\Database\Eloquent\Model;

final class ProductService extends BaseCrudService
{
    protected ?string $createDTOClass = CreateProductDTO::class;
    protected ?string $updateDTOClass = UpdateProductDTO::class;

    public function __construct(ProductContract $repository)
    {
        parent::__construct($repository);
    }

    protected function beforeCreate(DTOContract|array $dto): void
    {
        // Business validation before save
    }

    protected function afterCreate(Model $model): void
    {
        /** @var CreateProductDTO $dto */
        $dto = $this->getCreateData();

        $this->dispatch(new ProductCreated($model));
        $this->clearCache();
    }

    protected function beforeUpdate(Model $model, DTOContract|array $dto): void
    {
        if (! $model->canBeUpdated()) {
            throw BusinessException::make(
                __('products.cannot_update'),
                'PRODUCT_CANNOT_UPDATE',
                403,
            );
        }
    }

    protected function afterUpdate(Model $model): void
    {
        $this->clearCache();
    }

    protected function beforeDelete(Model $model): void
    {
        if ($model->hasDependents(['orders'])) {
            throw BusinessException::make(
                __('products.cannot_delete_has_orders'),
                'PRODUCT_HAS_ORDERS',
                422,
            );
        }
    }
}
```

### Service — Cache Usage

```php
protected string $cacheTag = 'products';

public function getFeatured(): Collection
{
    return $this->cache('featured', fn() =>
        $this->repository()->filter(['is_featured' => true])->get()
    , ttl: 3600);
}
```

### Service — Transaction

```php
public function createWithVariants(array $data): Model
{
    return $this->transaction(function () use ($data) {
        $product = $this->repository()->create($data['product']);
        foreach ($data['variants'] as $variant) {
            $product->variants()->create($variant);
        }
        return $product;
    });
}
```

### Service — Activity Logging

```php
use App\Core\Base\Services\Concerns\HasActivityLog;

final class RoleService extends BaseCrudService
{
    use HasActivityLog;

    protected bool $loggingEnabled = true;
    protected ?string $logActionEnumClass = RoleActionEnum::class;

    protected function getTrackedFields(): array
    {
        return [
            'name'        => ['type' => 'translatable'], // JSON {en, ar}
            'status'      => ['type' => 'enum'],          // raw enum value
            'permissions' => ['type' => 'relation'],      // pivot IDs
        ];
    }
}
```

---

### Repository

```php
<?php
declare(strict_types=1);

namespace App\Repositories\SQL\Products;

use App\Core\Base\BaseRepository;
use App\Filters\ProductFilter;
use App\Models\Product;

class ProductRepository extends BaseRepository
{
    protected ?string $filterClass = ProductFilter::class;

    public function __construct()
    {
        parent::__construct(new Product());
    }

    // Custom query example
    public function getFeaturedWithCategory(): Collection
    {
        return $this->filter(['is_featured' => true])
            ->loadRelations(['category:id,name'])
            ->select(['id', 'name', 'price', 'category_id'])
            ->get(paginate: false, limit: 10);
    }
}
```

### Filter Class

```php
<?php
declare(strict_types=1);

namespace App\Filters;

use App\Core\Filters\BaseFilter;
use App\Core\Filters\Concerns\HasDateRange;
use App\Core\Filters\Concerns\HasStatus;

class ProductFilter extends BaseFilter
{
    use HasDateRange;
    use HasStatus;

    protected array $searchable = ['name', 'sku', 'category.name'];
    protected array $sortable   = ['name', 'price', 'created_at'];

    protected function allowedFilters(): array
    {
        return ['status', 'category_id', 'is_featured', 'from', 'to'];
    }

    protected function categoryId(string $value): void
    {
        $this->builder->where('category_id', $value);
    }
}
```

---

### DTO — Create

```php
<?php
declare(strict_types=1);

namespace App\DTOs\Products;

use App\Core\Base\BaseDTO;
use App\Enums\ProductStatusEnum;

final class CreateProductDTO extends BaseDTO
{
    // Use $map when input key differs from constructor param
    protected static array $map = [
        'category_id' => 'categoryId',
    ];

    // Use $hidden to exclude from toArray() (e.g., pivot sync fields)
    protected static array $hidden = [];

    public function __construct(
        public readonly string            $name,
        public readonly float             $price,
        public readonly int               $categoryId,
        public readonly ProductStatusEnum $status = ProductStatusEnum::Active,
        public readonly ?string           $sku    = null,
    ) {}

    public function validate(): void
    {
        if ($this->price < 0) {
            throw new \InvalidArgumentException('Price must be positive.');
        }
    }
}
```

### DTO — Update (all nullable)

```php
final class UpdateProductDTO extends BaseDTO
{
    protected static array $map = [
        'category_id' => 'categoryId',
    ];

    public function __construct(
        public readonly ?string            $name       = null,
        public readonly ?float             $price      = null,
        public readonly ?int               $categoryId = null,
        public readonly ?ProductStatusEnum $status     = null,
        public readonly ?string            $sku        = null,
    ) {}
}
```

---

### Request

```php
<?php
declare(strict_types=1);

namespace App\Http\Requests;

use App\Core\Base\BaseRequest;
use App\Enums\ProductStatusEnum;
use Illuminate\Validation\Rule;

final class ProductRequest extends BaseRequest
{
    protected function commonRules(): array
    {
        return [
            'name'        => ['required', 'string', 'max:255'],
            'price'       => ['required', 'numeric', 'min:0'],
            'sku'         => ['required', 'string', Rule::unique('products', 'sku')],
            'category_id' => ['required', 'integer', 'exists:categories,id'],
            'status'      => ['required', Rule::in(ProductStatusEnum::values())],
        ];
    }

    protected function storeRules(): array
    {
        return [
            // POST-only rules (e.g., initial stock)
        ];
    }

    protected function updateRules(): array
    {
        return [
            // Change 'required' → 'sometimes' for optional update fields
            'name' => $this->modifyRule('name', 'required', 'sometimes'),
        ];
    }

    protected function sanitizers(): array
    {
        return [
            'trim'      => ['name', 'sku'],
            'lowercase' => ['sku'],
            'nullable'  => ['description'],
            'integer'   => ['category_id'],
        ];
    }
}
```

---

### Resource

BaseResource provides a **translation-aware visibility pipeline**:

```
visibilityOverrides()        ← base method (do NOT override)
    ├── applyTranslationOverrides()   ← auto Spatie i18n (private)
    └── applyVisibilityOverrides()    ← child hook (override this)
```

**Automatic Translation Support** — for models using Spatie `HasTranslations`:

| Mechanism | Behaviour |
|---|---|
| `?translated=1` | Translatable fields return all locales: `{ "en": "...", "ar": "..." }` |
| `Accept-Language: ar` header | Translatable fields return the requested locale string |
| Neither | Spatie default: returns app-locale string via accessor |

Spatie-injected `{field}_translations` sibling keys are always stripped automatically.

```php
<?php
declare(strict_types=1);

namespace App\Http\Resources;

use App\Core\Base\BaseResource;
use Illuminate\Http\Request;

class ProductResource extends BaseResource
{
    public function scopeDefinitions(): array
    {
        return [
            'micro' => [
                'id'   => $this->id,
                'name' => $this->name,
            ],
            'mini' => [
                'sku'       => $this->sku,
                'price'     => $this->price,
                'is_active' => $this->is_active,
                'status'    => $this->status->toOption(), // ← enum as structured object
            ],
            'full' => [
                'description' => $this->description,
                'created_at'  => $this->created_at,
                'updated_at'  => $this->updated_at,
                'can_delete'  => $this->canBeDeleted(), // ← business guard for frontend
                'can_update'  => $this->canBeUpdated(),
            ],
        ];
    }

    public function relationMappings(): array
    {
        return [
            'category' => CategoryResource::class,
            'tags'     => TagResource::class,
        ];
    }

    public function hiddenFields(): array
    {
        return ['internal_cost', 'supplier_notes'];
    }

    // ⚠️ Override applyVisibilityOverrides() — NOT visibilityOverrides()
    protected function applyVisibilityOverrides(Request $request, array $fields): array
    {
        if (! $request->user()?->hasRole('admin')) {
            unset($fields['can_delete'], $fields['can_update']);
        }
        return $fields;
    }
}
```

---

### Model — Full Features

```php
<?php
declare(strict_types=1);

namespace App\Models;

use App\Core\Base\BaseModel;
use App\Enums\ProductStatusEnum;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

class Product extends BaseModel
{
    use SoftDeletes;

    // ─── Feature Toggles ────────────────────────────────────────────
    protected bool $usesAudit        = true;
    protected bool $usesMedia        = true;
    protected bool $usesTranslations = true;

    // ─── Configuration ──────────────────────────────────────────────
    protected $fillable = ['name', 'description', 'price', 'sku', 'status', 'category_id'];
    protected array $translatable = ['name', 'description'];

    // ─── Casts ──────────────────────────────────────────────────────
    protected function casts(): array
    {
        return [
            'price'  => 'decimal:2',
            'status' => ProductStatusEnum::class,
        ];
    }

    // ─── Media Collections ──────────────────────────────────────────
    public function registerMediaCollections(): void
    {
        $this->addMediaCollection('images')
            ->acceptsMimeTypes(['image/jpeg', 'image/png', 'image/webp']);
    }

    // ─── Relationships ──────────────────────────────────────────────
    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class);
    }

    // ─── Business Guards ────────────────────────────────────────────
    public function canBeDeleted(): bool
    {
        return ! $this->hasDependents(['orders']);
    }

    public function canBeUpdated(): bool
    {
        return true;
    }
}
```

---

### Enum — Full Example

```php
<?php
declare(strict_types=1);

namespace App\Enums;

use App\Core\Contracts\HasEnumMetadata;
use App\Core\Traits\BaseEnumTrait;

enum ProductStatusEnum: int implements HasEnumMetadata
{
    use BaseEnumTrait;

    case Active   = 1;
    case Inactive = 2;
    case Draft    = 3;

    public function metadata(): array
    {
        return match ($this) {
            self::Active   => ['color' => 'green',  'icon' => 'check-circle', 'badge' => 'Active'],
            self::Inactive => ['color' => 'gray',   'icon' => 'minus-circle', 'badge' => 'Inactive'],
            self::Draft    => ['color' => 'yellow', 'icon' => 'clock',        'badge' => 'Draft'],
        };
    }
}
```

```php
// lang/en/enums.php
'product_status_enum' => [
    'active'   => 'Active',
    'inactive' => 'Inactive',
    'draft'    => 'Draft',
],

// lang/ar/enums.php
'product_status_enum' => [
    'active'   => 'نشط',
    'inactive' => 'غير نشط',
    'draft'    => 'مسودة',
],
```

---

## Response Envelope

```json
{
  "success": true,
  "message": "Resource created successfully.",
  "data": { "id": 1, "name": "..." },
  "meta": {}
}
```

```php
// Success:
return $this->success($data, 'response.retrieved');
return $this->created($model);
return $this->updated($model);
return $this->deleted();

// With extra fields:
return $this->created($user, additional: ['token' => $token]);

// Errors:
return $this->errorNotFound();
return $this->errorForbidden();
return $this->errorUnauthorized();

// ✅ Preferred for business errors (throw, don't return):
throw BusinessException::make(__('products.cannot_delete'), 'PRODUCT_CANNOT_DELETE', 422);
throw NotFoundException::model('Product', $id);
```

---

## Guard & Route Structure

```
/api/admin/v1/  ← Admin guard (auth:sanctum, guard_name = 'admin')
/api/user/v1/   ← User guard (auth:sanctum + client middleware, guard_name = 'api')
```

Route files: `routes/api/admin/v1/features/{entity}.php`
Aggregated in: `routes/api/admin/v1/api.php`

---

## Localization

The framework ships a `SetLocale` middleware that sets the app locale from the `Accept-Language` header.

**Config** (`config/app.php`):
```php
'supported_locales' => explode(',', env('APP_SUPPORTED_LOCALES', 'en,ar')),
```

**Middleware** (`App\Core\Http\Middleware\SetLocale`):
- Parses `Accept-Language: ar-EG,ar;q=0.9` → `ar`
- Validates against `config('app.supported_locales')`
- Sets `App::setLocale()` if valid, otherwise keeps the default `config('app.locale')`

Register in route groups or globally in `bootstrap/app.php`:
```php
->withMiddleware(function (Middleware $middleware) {
    $middleware->append(\App\Core\Http\Middleware\SetLocale::class);
})
```

This middleware works together with BaseResource's automatic translation support:
- `SetLocale` middleware sets the app locale → Spatie accessors return that locale by default
- `?translated=1` query param → returns all locale variants regardless

---

## Naming Conventions

| Thing | Convention | Example |
|---|---|---|
| Class names | PascalCase | `ProductService`, `CreateProductDTO` |
| Properties | camelCase | `$categoryId`, `$isActive` |
| DB columns | snake_case | `category_id`, `is_active` |
| Route names | kebab-case | `admin.products.index` |
| Lang keys | dot.notation | `products.cannot_delete` |
| Enum cases | TitleCase | `case Active = 1` |
| Controller | `final class` always | — |
| Service | `final class` always | — |
| DTO | `final class` always | — |
| Request | `final class` always | — |

---

## Built-in Models Reference

| Model | Guard | Extends | Special |
|---|---|---|---|
| `User` | `api` | `Authenticatable` | HasRoles, Sanctum, TOTP |
| `Admin` | `admin` | `Authenticatable` | HasRoles, Sanctum, TOTP, SoftDeletes |
| `Client` | — | `Model` | Device tracking, biometric, FCM |
| `OtpToken` | — | `Model` | Polymorphic, UUID token, attempts |
| `TempUpload` | — | `Model` + `HasMedia` | Token-based media staging |
| `Product` | — | `BaseModel` | Reference example: all 3 toggles ON |

---

## Anti-Patterns (NEVER DO)

```php
// ❌ DTOs in Controller
$dto = CreateProductDTO::fromRequest($request); // belongs in service

// ❌ Business logic in Controller
if ($dto->price < 0) { throw new Exception; }

// ❌ DB queries in Controller
DB::table('products')->insert([...]);

// ❌ String-backed enum
enum Status: string { case active = 'active'; }

// ❌ UPPERCASE enum cases
case ACTIVE = 1; // ← should be: case Active = 1;

// ❌ String unique rule (breaks auto-ignore)
'email' => 'required|unique:users,email' // ← use Rule::unique() object

// ❌ Hardcoded message strings
return $this->success($data, 'Product retrieved.'); // ← use lang key

// ❌ response()->json() in Controllers
return response()->json(['data' => $product]); // ← use $this->success()

// ❌ Override toArray() in Resource
public function toArray($request): array { ... } // ← use scopeDefinitions()

// ❌ Override visibilityOverrides() in child Resource
protected function visibilityOverrides(...) { ... } // ← override applyVisibilityOverrides()

// ❌ Cache in Repository
Cache::remember(...) // ← belongs in Service

// ❌ Event::dispatch() in Service
Event::dispatch(new ProductCreated($model)); // ← use $this->dispatch()
```

---

## AI Scaffolding Prompts (From Docs)

Use these prompts when generating complete modules:

### Full Module Scaffold Prompt
```
You are a Laravel expert working inside the Neop Base Backend framework.
This framework provides: BaseModel, BaseCrudService, BaseRepository,
BaseCrudController, BaseRequest, BaseResource, BaseDTO, and BaseEnumTrait.

Task: Create a complete module for [Entity Name] from scratch.

Generate: Model, Migration, Enum, Repository Contract, Repository SQL,
Filter, Create DTO, Update DTO, Service, Request, Resource, Controller,
Routes, Permissions Seeder, PHPUnit Tests.

Entity: [name]
Fields: [field: type]
Translatable fields: [fields]
Media collections: [name: single/multiple]
Relationships: [type: related model]
Enums: [EnumName → cases with int values]
Audit logging: [yes/no]
```

### Per-Layer Prompts

**DTO:**
```
Extend BaseDTO. All properties readonly. Use $map for key renaming.
Use $casts only for array-typed fields containing DTOs.
Create DTO: all required. Update DTO: all nullable = null.
```

**Request:**
```
Extend BaseRequest. commonRules() for shared rules.
storeRules() for POST-only. updateRules() for PUT-only.
Rule::unique() object (not string). sanitizers() for input cleaning.
modifyRule() to change one rule without duplication.
```

**Resource:**
```
Extend BaseResource. scopeDefinitions() with micro/mini/full (cumulative).
Never override toArray(). Enum fields: ->toOption(). 
relationMappings() → Resource class or raw attribute array.
Never override visibilityOverrides() — override applyVisibilityOverrides() instead.
Translation handled automatically via ?translated=1 and Accept-Language header.
```

**Service:**
```
Extend BaseCrudService. $createDTOClass and $updateDTOClass.
Use hooks: beforeCreate, afterCreate, beforeUpdate, afterUpdate, beforeDelete.
$this->transaction() for compound writes. $this->dispatch() for events.
BusinessException for business rule violations.
```

**Repository:**
```
Extend BaseRepository. parent::__construct(new Model()).
$filterClass bound. Fluent: filter()->loadRelations()->get().
No business logic, no cache, no events here.
```

**Filter:**
```
Extend BaseFilter. $searchable, $sortable, allowedFilters().
Custom method per filter key. Optional: HasDateRange, HasStatus, HasRangeFilter.
```

**Enum:**
```
int-backed. use BaseEnumTrait. TitleCase cases.
Add to lang/en/enums.php and lang/ar/enums.php.
Implement HasEnumMetadata for color/icon/badge.
```

**Model:**
```
BaseModel with $usesAudit/$usesMedia/$usesTranslations toggles.
casts() method. registerMediaCollections() if media. $translatable array if i18n.
Business guards: canBeDeleted(), canBeUpdated() as model methods.
```
