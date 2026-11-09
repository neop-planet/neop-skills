# SEO & Structured Data — 100/100 Strapi + Nuxt Architecture

The Seen website uses a fully customizable, CMS-driven SEO system across Strapi v5 and Nuxt 4.

---

## 1. The `shared.seo` Component (`strapi/src/components/shared/seo.json`)

Attached to `api::page.page`, `api::article.article`, `api::blog-page.blog-page`, `api::about-page.about-page`, `api::global.global`, and all public collection types:

- **Core Meta**: `metaTitle` (50–60 chars ideal), `metaDescription` (120–160 chars ideal), `metaImage`, `keywords`, `focusKeyword`, `metaRobots` (`index, follow`), `metaViewport`, `canonicalURL`
- **Social**: `openGraph` (`shared.open-graph`), `twitterCardType` (`summary_large_image`), `twitterTitle`, `twitterDescription`, `twitterImage`
- **AI / AEO & Structured Data**: `structuredData` (JSON-LD), `breadcrumbTitle`, `faqSchema` (JSON), `aiSummary` (concise summary for LLM/AI answer engines), `speakableSelectors`, `noai`
- **Automated Audit**: `seoScore` (`0–100`), `seoAnalysis` (JSON breakdown of title, description, keywords, canonical, OpenGraph, structuredData, and AEO readiness)

---

## 2. Automatic 100/100 Enrichment (`strapi/src/utils/seoAnalyzer.ts`)

Never write partial `seo` objects by hand in seeders. Always pass your page/entry metadata through `enrichAndScoreSeo(rawSeo, context)`:

```ts
import { enrichAndScoreSeo } from '../../utils/seoAnalyzer';

const seo = enrichAndScoreSeo(
  {
    metaTitle: title.slice(0, 65),
    metaDescription: description,
    metaImage: defaultImageId,
  },
  {
    title,
    description,
    slug: locale === 'ar' ? arSlug : enSlug,
    slug_en: enSlug,
    slug_ar: arSlug,
    page_key: pageKey,
    locale,
    hasImage: Boolean(defaultImageId),
    defaultImageId,
  }
);
```

- **In Seeders**:
  - Pages use `ensurePage()` in `seedCommon.ts` (calls `enrichAndScoreSeo` automatically).
  - Collections use `withSlugAndSeo()` in `strapi/src/seed/modules/helpers.ts` (auto-generates `slug` and a 100/100 `seo` block).
- **In Strapi Admin (Live Edits)**:
  - `strapi/src/index.ts` registers a `strapi.db.lifecycles.subscribe` hook (`beforeCreate` / `beforeUpdate`) that automatically runs `enrichAndScoreSeo()` whenever an editor creates or updates any content type with an `seo` field.

---

## 3. Global SEO Single Types in Strapi

Seeded in `strapi/src/seed/modules/seedGlobal.ts`:
1. **`api::schema-settings.schema-settings`**: Controls `Organization` and `SoftwareApplication` JSON-LD (`business_name`, `phone`, `email`, `address`, `latitude`/`longitude`, `app_rating_value`, `app_rating_count`).
2. **`api::site-setting.site-setting`**: Global brand identity, contact numbers, social URLs, and default OG fallback.
3. **`api::tracking-settings.tracking-settings`**: Controls GTM, GA4, Meta/Snapchat/TikTok/LinkedIn pixels, Search Console/Bing/Yandex verification tags, `allow_ai_bots`, and `custom_robots_txt`.

---

## 4. Nuxt Frontend SEO Consumption (`nuxt/app/composables/usePageSeo.ts`)

- Every page calls `usePageSeo()` with the Strapi `seo` object, localized paths (`en` / `ar`), and fallback title/description.
- Renders `<title>`, `<meta name="description">`, OpenGraph tags, Twitter Cards, `<link rel="canonical">`, `<link rel="alternate" hreflang="en|ar|x-default">`, `aiSummary` meta tags, and `<script type="application/ld+json">` (`structuredData` + `faqSchema`).
