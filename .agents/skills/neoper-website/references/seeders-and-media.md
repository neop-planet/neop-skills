# Seeders & Bilingual Media — Strapi v5 Guide

All seeders live in `website/strapi/src/seed/` and run automatically on boot when `SEED_ON_BOOT=true` or `SEED_FORCE=true`.

---

## 1. How `uploadLocalFileToStrapi` Works (`seedCommon.ts`)

`uploadLocalFileToStrapi(strapi, relativeFilePath)` looks up files in `website/nuxt/public/<relativeFilePath>` (or `website/strapi/public/<relativeFilePath>`):

- **Keyed by `basename`**: It caches and looks up existing `plugin::upload.file` rows by `filename = path.basename(relativeFilePath)`.
  - **Rule**: Every distinct image (including EN vs AR variants) MUST have a unique filename (e.g., `image.png` vs `image-ar.png`, `feature-flow.png` vs `feature-flow-ar.png`, `mobile-app-mockup.png` vs `mobile-app-mockup-ar.png`).
- **MD5 Content-Hash Auto-Update**:
  - Computes a 12-char MD5 hash of the local file buffer and stores `caption = "${filename}#${sourceHash}"`.
  - On subsequent seeds, if the local file's MD5 matches `existing.caption` and the file exists on disk, it returns the cached DB row immediately.
  - If you replace or edit a local PNG/JPG/SVG file, the MD5 changes, so `uploadLocalFileToStrapi` automatically deletes the stale upload and uploads the new file!

---

## 2. Adding Bilingual (EN + AR) Page Media (`pages/media.ts` & `pages/home.ts`)

1. Place source files in `website/nuxt/public/seen-home/...`:
   - EN: `seen-home/hero/image.png`, `seen-home/sections/feature-flow.png`, `seen-home/sections/mobile-app-mockup.png`
   - AR: `seen-home/hero/image-ar.png`, `seen-home/sections/feature-flow-ar.png`, `seen-home/sections/mobile-app-mockup-ar.png`
2. Add both to `HomeMedia` and `uploadHomeMedia(strapi)` in `strapi/src/seed/modules/pages/media.ts`.
3. In `strapi/src/seed/modules/pages/home.ts` (and `solutions.ts`):
   - Wire EN media to `enZone`:
     ```ts
     image: media.heroImage ? media.heroImage.id : undefined,
     ```
   - Wire AR media to `arZone`:
     ```ts
     image: media.heroImageAr ? media.heroImageAr.id : undefined,
     ```
4. In `strapi/src/seed/modules/seedCollections.ts`:
   - Upload both `featureImagesEn[i]` and `featureImagesAr[i]` and assign:
     ```ts
     featureEntries[i].en.image = uploadedEn.id;
     featureEntries[i].ar.image = uploadedAr.id;
     ```

---

## 3. Reordering or Editing Page Sections (`pages/*.ts`)

Page section order is controlled directly by the array order in `enZone` and `arZone` inside `strapi/src/seed/modules/pages/{page}.ts`:
- `ensurePage(strapi, config)` updates both `en` and `ar` locales on the same Strapi `documentId`, normalizes all dynamic zone blocks via `normalizeDynamicZone()`, and enriches SEO to 100/100 via `enrichAndScoreSeo()`.
- Always keep `enZone` and `arZone` section order synchronized (e.g., on `home.ts`: Hero → Features → Clients Marquee → Stats Counter → Integrations Bento → Mobile App Download → Our Partners Marquee → Pricing → Why Seen → Gradient Banner CTA).

---

## 4. Global & Single-Type Seeders (`seedGlobal.ts`)

`strapi/src/seed/modules/seedGlobal.ts` seeds:
- `api::global.global` (`en` + `ar`):
  - `navbar` (`left_navbar_items`, `right_navbar_items`, `logo`)
  - `footer` (`policy_links`, `internal_links`, `social_media_links`, `copyright`, `description`, `built_with`)
  - `whatsapp_float` (`phoneNumber: '447926690825'`, `tooltip`, `defaultText`, `avatars`)
  - `whatsapp_avatars` (relation to uploaded team avatar files)
- `api::schema-settings.schema-settings` (`en` + `ar` Organization & SoftwareApplication JSON-LD settings)
- `api::site-setting.site-setting` (`en` + `ar` phone `+44 7926 690825`, `whatsapp`, brand colors, social URLs)
- `api::contact-settings.contact-settings` (`en` + `ar` `whatsapp_number: '447926690825'`, support/sales emails)
- `api::tracking-settings.tracking-settings` (GTM, GA4, pixels, `allow_ai_bots`, `custom_robots_txt`)
