# Dynamic Zone Sections — Strapi v5 & Nuxt 4 Guide

Every marketing section on the Seen website is a Strapi Dynamic Zone component rendered by `nuxt/app/components/DynamicZone.vue`.

---

## 1. Create Reusable Sub-Components First (`strapi/src/components/shared/`)

**Rule**: Never use `"type": "json"` for structured arrays or objects. Create or reuse a component in `strapi/src/components/shared/`:

- `shared.list-item` — `{ text: string }` (for simple string bullet lists)
- `shared.bullet-item` — `{ title: string, desc: text }` (for titled feature bullets)
- `shared.cta-link` — `{ text: string, url: string }` (for primary/secondary CTAs)
- `shared.trust-badge` — `{ text: string, icon: string }`

Example `strapi/src/components/shared/feature-card-item.json`:
```json
{
  "collectionName": "components_shared_feature_card_items",
  "info": {
    "displayName": "Feature Card Item",
    "icon": "layer"
  },
  "attributes": {
    "badge": { "type": "string" },
    "headline": { "type": "string", "required": true },
    "shortDesc": { "type": "text" },
    "mockupType": { "type": "string" },
    "image": {
      "type": "media",
      "multiple": false,
      "allowedTypes": ["images"]
    },
    "bullets": {
      "type": "component",
      "repeatable": true,
      "component": "shared.bullet-item"
    }
  }
}
```

---

## 2. Create the Dynamic Zone Component (`strapi/src/components/dynamic-zone/{section}.json`)

For sections that can pull from either a Collection Type or inline custom items, include `source`, `selected_{items}`, and repeatable custom items:

```json
{
  "collectionName": "components_dynamic_zone_stacked_cards_showcases",
  "info": {
    "displayName": "Stacked Cards Showcase",
    "icon": "stack"
  },
  "attributes": {
    "badge": { "type": "string" },
    "headline": { "type": "string" },
    "subtitle": { "type": "text" },
    "source": {
      "type": "enumeration",
      "enum": ["custom", "collection"],
      "default": "custom"
    },
    "selected_features": {
      "type": "relation",
      "relation": "oneToMany",
      "target": "api::feature.feature"
    },
    "features": {
      "type": "component",
      "repeatable": true,
      "component": "shared.feature-card-item"
    }
  }
}
```

---

## 3. Register in `page/schema.json` and `page-populate.ts` (CRITICAL)

1. **Add to `strapi/src/api/page/content-types/page/schema.json`** inside `attributes.dynamic_zone.components`:
   ```json
   "dynamic-zone.stacked-cards-showcase"
   ```
2. **Add to `strapi/src/api/page/middlewares/page-populate.ts`** inside `populate.dynamic_zone.on`:
   > **WARNING**: Strapi v5 does NOT auto-populate nested components or media inside Dynamic Zones. Any media, relation, or sub-component omitted from `page-populate.ts` will be `undefined` in Nuxt!
   ```ts
   'dynamic-zone.stacked-cards-showcase': {
     populate: {
       selected_features: {
         populate: {
           image: true,
           bullets: true,
         },
       },
       features: {
         populate: {
           image: true,
           bullets: true,
         },
       },
     },
   },
   ```

---

## 4. Normalize in `seedCommon.ts` (Optional Helper)

In `strapi/src/seed/modules/seedCommon.ts` → `normalizeDynamicZone()`, resolve any media paths/URLs to Strapi media IDs (`resolveMediaId(strapi, item.image)`) and convert string arrays to `{ text }` objects (`toListItems(arr)`) before `docService.create/update`.

---

## 5. Build the Nuxt Section Component & Register in `DynamicZone.vue`

1. Create `nuxt/app/components/sections/{SectionName}.vue`:
   - Accept `locale: string` plus all Strapi component fields as props.
   - Always render Strapi media using `<StrapiMedia :src="image?.url" ... />` or `useStrapiMediaResolver()`.
   - When using the hybrid `source` pattern:
     ```ts
     const items = computed(() => {
       if (props.source === 'collection' && props.selected_features?.length) {
         return props.selected_features;
       }
       return props.features?.length ? props.features : (props.selected_features || []);
     });
     ```
   - For CTA buttons with rotating team avatars (`ctaAvatars`), slice 3 avatars and rotate every 3000ms:
     ```ts
     const avatarOffset = ref(0);
     const visibleAvatars = computed(() => {
       const list = props.ctaAvatars || [];
       if (list.length <= 3) return list;
       return [0, 1, 2].map((i) => list[(avatarOffset.value + i) % list.length]!);
     });
     ```
2. Register in `nuxt/app/components/DynamicZone.vue`:
   ```ts
   'dynamic-zone.stacked-cards-showcase': {
     component: StackedCardsShowcase,
     name: 'Stacked Cards Showcase',
   },
   ```
