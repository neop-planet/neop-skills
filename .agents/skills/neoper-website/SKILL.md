---
name: neoper-website
description: Build, scaffold, seed, optimize SEO, or edit pages, dynamic-zone sections, and collections in the Seen marketing website (`website/strapi` + `website/nuxt`). Covers Strapi v5 content-types, structured Dynamic Zone components (zero raw JSON blobs), deep populate middlewares (`page-populate.ts`), bilingual EN/AR seeders (`ensurePage`, `seedCollections`, `seedGlobal`), MD5-cached media uploads (`uploadLocalFileToStrapi`), 100/100 SEO (`enrichAndScoreSeo`, JSON-LD `Schema Settings`, `Site Settings`, `Tracking Settings`), Nuxt 4 section components (`DynamicZone.vue`), and `[deploy] [seed]` CI workflows. Use whenever asked to add/edit a website section, page, collection, seeder, media asset, or SEO in `website/`.
---

# Neoper Website — Seen Website (`website/strapi` + `website/nuxt`)

End-to-end guide for building, seeding, and deploying pages, dynamic-zone sections, collections, media, and SEO in `/home/adham/projects/neop/seen/website`.

> **References** (load on demand):
> - `references/dynamic-zones.md` — Structured Strapi components, `page-populate.ts`, `DynamicZone.vue`, `source: 'custom' | 'collection'`
> - `references/seeders-and-media.md` — Bilingual (`en`/`ar`) page & collection seeders, `uploadLocalFileToStrapi` MD5 auto-update
> - `references/seo-and-schema.md` — `shared.seo`, `enrichAndScoreSeo` (100/100 score), `Schema Settings`, `Site Settings`, `Tracking Settings`, Nuxt `usePageSeo`
> - `references/collections-and-pages.md` — Adding new Strapi Collection/Single Types, public permissions, `usePageSlugs`, and Nuxt pages

---

## Architecture Overview

```text
website/
├── strapi/
│   ├── src/components/
│   │   ├── dynamic-zone/*.json         ← Section schemas (NEVER use raw json fields)
│   │   └── shared/*.json               ← Reusable sub-components (seo, list-item, bullet-item, etc.)
│   ├── src/api/
│   │   ├── page/content-types/page/schema.json       ← Registers all dynamic_zone sections
│   │   ├── page/middlewares/page-populate.ts         ← MANDATORY deep populate for every section
│   │   └── {collection}/content-types/{collection}/  ← Collection & Single Types
│   ├── src/utils/seoAnalyzer.ts        ← enrichAndScoreSeo() (computes 100/100 SEO score + JSON-LD)
│   └── src/seed/
│       ├── index.ts                    ← Main seed runner (SEED_ON_BOOT / SEED_FORCE)
│       └── modules/
│           ├── seedCommon.ts           ← uploadLocalFileToStrapi (MD5 hash), ensurePage, normalizeDynamicZone
│           ├── seedCollections.ts      ← Bilingual collections + grantPublicCollectionPermissions
│           ├── seedGlobal.ts           ← Global navbar/footer, Schema/Site/Tracking/Contact Settings
│           └── pages/{home,solutions,pricing,about,contact,media}.ts
└── nuxt/
    ├── public/seen-home/               ← Source images uploaded to Strapi during seed
    └── app/
        ├── components/DynamicZone.vue  ← Maps `dynamic-zone.*` to Vue components
        ├── components/sections/*.vue   ← Section Vue components (use StrapiMedia for images)
        ├── composables/useSeenContent.ts & usePageSeo.ts & usePageSlugs.ts
        └── pages/[locale]/             ← Bilingual (`en` / `ar`) SSR/ISR routes
```

---

## Mandatory Project Rules (Checklist)

1. **Zero Raw JSON Fields in Strapi Sections**:
   - NEVER use `"type": "json"` for cards, bullets, tiers, FAQs, channels, or links.
   - ALWAYS create or reuse structured sub-components in `strapi/src/components/shared/*.json` (`shared.list-item`, `shared.bullet-item`, `shared.partner-item`, etc.) so editors get real form inputs in Strapi Admin.
2. **Every Dynamic Zone Section Must Be Registered in 4 Places**:
   - `strapi/src/components/dynamic-zone/{section}.json` (component schema)
   - `strapi/src/api/page/content-types/page/schema.json` (`dynamic_zone.components` array)
   - `strapi/src/api/page/middlewares/page-populate.ts` (explicitly populate every nested component, relation, and media field — Strapi v5 drops unpopulated nested fields!)
   - `nuxt/app/components/DynamicZone.vue` (`REGISTRY` mapping to `nuxt/app/components/sections/{Section}.vue`)
3. **Bilingual (`en` + `ar`) Content & Media**:
   - Every page and collection entry must be seeded in both `en` and `ar`.
   - When a section has UI mockups containing text (e.g., Hero, Features, Mobile App CTA), upload distinct EN (`feature-flow.png`) and AR (`feature-flow-ar.png`) files in `pages/media.ts` and wire them to `enZone` and `arZone` respectively.
   - `uploadLocalFileToStrapi` caches by `path.basename(filePath)` and stores `<filename>#<md5>` in `caption`. Give EN and AR files distinct filenames, and whenever a local image is edited, its MD5 hash change automatically triggers a re-upload on seed.
4. **Hybrid `source: 'custom' | 'collection'` Pattern**:
   - Sections backed by collections (Features, Partners, Metrics, Integrations, Pricing, Values, Team, Solutions) must support `source: "custom" | "collection"`, a `selected_{items}` relation, and repeatable custom items so editors can either pick collection entries or customize inline.
5. **100/100 SEO on Every Entity**:
   - Every Page, Article, and Collection entry uses `shared.seo` enriched via `enrichAndScoreSeo()` in `strapi/src/utils/seoAnalyzer.ts` (and auto-scored on admin save via the global lifecycle hook in `strapi/src/index.ts`).
6. **Deploy & Seed Workflow**:
   - Commit messages control production CI on `develop`:
     - `[deploy]` — Build & rsync Nuxt + Strapi and restart PM2 services.
     - `[deploy] [seed]` — Also run non-destructive bilingual seeder (`SEED_ON_BOOT=true`).
     - `[deploy] [force-seed]` — Force full re-seed (`SEED_FORCE=true`).

---

## Quick Workflows

### Workflow A: Add or Edit a Dynamic Zone Section
1. Read `references/dynamic-zones.md`.
2. Define/update `strapi/src/components/dynamic-zone/{name}.json` + any `shared/*.json` sub-components.
3. Add `'dynamic-zone.{name}'` to `page/schema.json` and add its full nested `populate` tree to `page-populate.ts`.
4. Add normalization (if needed) in `seedCommon.ts` → `normalizeDynamicZone()`, and seed EN + AR data in `strapi/src/seed/modules/pages/{page}.ts`.
5. Build `nuxt/app/components/sections/{Name}.vue` (using `<StrapiMedia>` for all CMS images) and register it in `nuxt/app/components/DynamicZone.vue`.

### Workflow B: Add or Update Images / Bilingual Assets
1. Read `references/seeders-and-media.md`.
2. Place EN and AR assets in `website/nuxt/public/seen-home/...` with distinct filenames (e.g., `feature-flow.png` and `feature-flow-ar.png`).
3. Register uploads in `strapi/src/seed/modules/pages/media.ts` (`uploadHomeMedia`) and pass EN media to `enZone` and AR media to `arZone`.
4. Commit and push with `[deploy] [seed]`.

### Workflow C: Add a New Page or Collection Type
1. Read `references/collections-and-pages.md` and `references/seo-and-schema.md`.
2. Create Strapi schema (`draftAndPublish: true`, `i18n.localized: true`, `seo: shared.seo`), grant public `find`/`findOne` permissions in `seedCollections.ts`, seed EN + AR via `withSlugAndSeo` or `ensurePage`, and register the slug in `nuxt/app/composables/usePageSlugs.ts`.
