# Collections, Pages & Deployment — Seen Website Guide

How to add new Collection Types, Single Types, or Pages in `website/strapi` and `website/nuxt`, and deploy them to production.

---

## 1. Adding a New Strapi Collection Type

1. **Create Schema & Core Controllers/Services/Routes**:
   - `strapi/src/api/{name}/content-types/{name}/schema.json` (enable `i18n.localized: true` and include `"seo": { "type": "component", "component": "shared.seo" }`)
   - `strapi/src/api/{name}/controllers/{name}.ts` (`factories.createCoreController`)
   - `strapi/src/api/{name}/services/{name}.ts` (`factories.createCoreService`)
   - `strapi/src/api/{name}/routes/{name}.ts` (`factories.createCoreRouter`)
2. **Grant Public Read Permissions (`seedCollections.ts`)**:
   - Add `'api::{name}.{name}'` to `collectionsToPublicise` in `strapi/src/seed/modules/seedCollections.ts`.
3. **Create Bilingual Seed Data (`strapi/src/seed/modules/data/{name}.ts`)**:
   - Export `get{Name}(): BilingualEntry[]` with `en` and `ar` objects.
   - Seed in `seedCollections.ts` using `await seedCollection(strapi, 'api::{name}.{name}', get{Name}().map(withSlugAndSeo))`.
4. **Add Nuxt Composable (`nuxt/app/composables/useSeenContent.ts`)**:
   - Create a typed fetcher composable using `useStrapiClient()` with `locale` reactivity.

---

## 2. Adding a New Marketing Page

1. **Create Page Seeder (`strapi/src/seed/modules/pages/{page}.ts`)**:
   - Export `seed{Page}Page(strapi: Core.Strapi)` calling `ensurePage(strapi, { pageKey, enSlug, arSlug, enTitle, arTitle, enDesc, arDesc, enZone, arZone })`.
   - Call `seed{Page}Page(strapi)` inside `strapi/src/seed/modules/seedPages.ts`.
2. **Register Bilingual Slugs (`nuxt/app/composables/usePageSlugs.ts`)**:
   - Add the `pageKey` default slugs (`en` and `ar`) to `DEFAULT_SLUGS` in `usePageSlugs.ts` so `Navbar.vue`, `Footer.vue`, and `LocaleSwitcher.vue` resolve `/en/{enSlug}` and `/ar/{arSlug}` seamlessly.
3. **Dark Hero Navbar Detection (`nuxt/app/components/Navbar.vue`)**:
   - If the new page starts with a dark navy hero (`#05245c`), add its path to `hasDarkHero` in `Navbar.vue` so the header uses white text before scrolling.
   - Note: Keep the mobile drawer `<div v-if="menuOpen">` OUTSIDE `<header>` in `Navbar.vue` so `<header>`'s `backdrop-blur` never traps `position: fixed` on mobile!

---

## 3. Deployment & Seeding via GitHub Actions

Push to `origin develop` from `/home/adham/projects/neop/seen/website` using commit message flags:

| Commit Flag | Behavior on Production (`seen-website.neop.co`) |
| :--- | :--- |
| `[deploy]` | Builds Strapi & Nuxt in CI, rsyncs artifacts, restarts PM2 (`SEED_ON_BOOT=false`). |
| `[deploy] [seed]` | Builds, deploys, and runs idempotent seeders (`SEED_ON_BOOT=true`) — updates pages, collections, SEO, and any modified images (via MD5 hash check). |
| `[deploy] [force-seed]` | Builds, deploys, and forces a full re-seed (`SEED_ON_BOOT=true`, `SEED_FORCE=true`). |

### Verification Commands
```bash
# Watch CI run until completion
cd /home/adham/projects/neop/seen/website
gh run watch $(gh run list --limit 1 --json databaseId -q '.[0].databaseId') --exit-status

# Verify live EN and AR pages
curl -s "https://seen-website.neop.co/en" | grep -oE '/uploads/[^"'\'' >]+?\.(png|jpg|svg)' | sort -u
curl -s "https://seen-website.neop.co/ar" | grep -oE '/uploads/[^"'\'' >]+?\.(png|jpg|svg)' | sort -u
```
