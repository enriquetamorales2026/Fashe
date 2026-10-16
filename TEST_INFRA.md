# Test Infrastructure & Opaque-Box E2E Testing Suite: Mirevaine Atelier Theme

## 1. Test Philosophy & Framework Overview

### 1.1 Opaque-Box & Requirement-Driven Architecture
The Mirevaine Shopify Online Store 2.0 Theme test suite adheres strictly to **opaque-box, requirement-driven verification**. Tests evaluate external interfaces, rendered assets, schema contracts, JSON validation, CSS variable generation, DOM structures, and HTTP endpoint health without coupling to private implementation idiosyncrasies.

Every test case in this specification traces directly to an authoritative requirement:
- **`ORIGINAL_REQUEST.md`** Requirements R1 through R5 and Acceptance Criteria
- **`PROJECT.md`** Architecture, Code Layout, Feature Inventory (F1–F14), and Interface Contracts
- **RFC 8259** JSON Data Interchange Format specification
- **W3C SVG 1.1** & Portable Network Graphics (PNG) specifications
- **W3C Web Content Accessibility Guidelines (WCAG) 2.1 AA**

### 1.2 Progressive Testability & Milestone Alignment
During milestone execution (M1 through M6), the test suite supports progressive verification:
- Isolated feature testing executes with zero cross-milestone leaks.
- Verification commands accept filtering by Tier (`-Tier`), Feature (`-Feature`), and Milestone (`-Milestone`).
- Comprehensive regression runs execute across all tiers to guarantee zero regressions.

---

## 2. Feature Inventory (F1 through F14)

| Feature ID | Feature Name | Target Surface | Milestone | Authoritative Source |
|---|---|---|---|---|
| **F1** | Logo Artwork Extraction | `assets/mirevaine-logo.png`, `assets/mirevaine-logo.svg` | M1 | `ORIGINAL_REQUEST.md` R1, `PROJECT.md` F1 |
| **F2** | Favicon Extraction | `assets/mirevaine-favicon.png`, `assets/mirevaine-favicon.svg` | M1 | `ORIGINAL_REQUEST.md` R1, `PROJECT.md` F2 |
| **F3** | Logo & Favicon Theme Wiring | `config/settings_data.json`, `sections/header.liquid`, `sections/footer.liquid`, `layout/theme.liquid` | M1 | `ORIGINAL_REQUEST.md` R1, `PROJECT.md` F3 |
| **F4** | JSON Comment Sanitization | All JSON files in `config/`, `sections/`, `templates/`, `locales/` | M2 | `ORIGINAL_REQUEST.md` AC 1, `PROJECT.md` F4 |
| **F5** | Color Scheme Calibration | `config/settings_data.json`, `snippets/theme-styles.liquid` | M2 | `ORIGINAL_REQUEST.md` R2, `PROJECT.md` F5 |
| **F6** | Typography & Letter-Spacing | `config/settings_data.json`, `snippets/theme-styles.liquid`, `assets/base.css` | M2 | `ORIGINAL_REQUEST.md` R2, `PROJECT.md` F6 |
| **F7** | Desktop Navigation Ribbon | `sections/header.liquid`, `assets/base.css` | M3 | `ORIGINAL_REQUEST.md` R3, `PROJECT.md` F7 |
| **F8** | 5-Category Navigation Fallback | `sections/header.liquid`, mobile drawer | M3 | `ORIGINAL_REQUEST.md` R3, `PROJECT.md` F8 |
| **F9** | Category Sidebar & Footer Links | `snippets/category-sidebar.liquid`, `sections/footer.liquid`, `sections/footer-group.json` | M3 | `ORIGINAL_REQUEST.md` R3, `PROJECT.md` F9 |
| **F10** | The Atelier Story Page | `templates/page.about.json` | M4 | `ORIGINAL_REQUEST.md` R4, `PROJECT.md` F10 |
| **F11** | Archival Care Guide Page | `templates/page.care.json` | M4 | `ORIGINAL_REQUEST.md` R4, `PROJECT.md` F11 |
| **F12** | Client Concierge Page | `templates/page.contact.json` | M4 | `ORIGINAL_REQUEST.md` R4, `PROJECT.md` F12 |
| **F13** | Catalogue & Cart Enhancements | `templates/collection.json`, `snippets/product-card.liquid`, `snippets/cart-summary.liquid`, `sections/cart-drawer.liquid` | M5 | `ORIGINAL_REQUEST.md` R5, `PROJECT.md` F13 |
| **F14** | E2E Suite & Git Finalization | Git repository, `origin/master`, `https://mirevaine.myshopify.com/` | M6 | `ORIGINAL_REQUEST.md` AC, `PROJECT.md` F14 |

---

## 3. 4-Tier Test Suite Architecture

```
+-----------------------------------------------------------------------------------+
|                            TIER 4: APPLICATION SCENARIOS                         |
|   5 Multi-step Real-World Boutique Shopper & Concierge Application Journeys       |
+-----------------------------------------------------------------------------------+
|                        TIER 3: CROSS-FEATURE COMBINATIONS                         |
|   10 Pairwise Interaction Tests Verifying Cross-Module Architectural Contracts    |
+-----------------------------------------------------------------------------------+
|                       TIER 2: BOUNDARY & CORNER CASES                            |
|   70 Edge Case Tests (5 per feature) Stressing Empty, Boundary, Extreme Values   |
+-----------------------------------------------------------------------------------+
|                         TIER 1: FEATURE COVERAGE (ISOLATED)                       |
|   70 Direct Unit / Feature Verification Tests (5 per feature)                     |
+-----------------------------------------------------------------------------------+
```

---

## 4. Tier 1: Feature Coverage (70 Test Cases)

### Feature 1: Logo Artwork Extraction
- **`T1.F1.1`**: Verify header logo PNG asset `assets/mirevaine-logo.png` exists in the filesystem.
- **`T1.F1.2`**: Verify `assets/mirevaine-logo.png` dimensions are exactly 571 pixels wide by 328 pixels high.
- **`T1.F1.3`**: Verify `assets/mirevaine-logo.png` color format is 32-bit ARGB (`Format32bppArgb`) with alpha transparency channel.
- **`T1.F1.4`**: Verify header logo SVG asset `assets/mirevaine-logo.svg` exists in the filesystem.
- **`T1.F1.5`**: Verify `assets/mirevaine-logo.svg` contains valid `viewBox="0 0 571 328"` and includes the wordmark text "MIREVAINE" and tagline "ELEVATED ACCESSORIES FOR EVERYDAY ELEGANCE".

### Feature 2: Favicon Extraction
- **`T1.F2.1`**: Verify app icon/favicon PNG asset `assets/mirevaine-favicon.png` exists in the filesystem.
- **`T1.F2.2`**: Verify `assets/mirevaine-favicon.png` dimensions are exactly 148 pixels wide by 148 pixels high (1:1 aspect ratio).
- **`T1.F2.3`**: Verify `assets/mirevaine-favicon.png` color format is 32-bit ARGB with alpha transparency channel.
- **`T1.F2.4`**: Verify app icon/favicon SVG asset `assets/mirevaine-favicon.svg` exists in the filesystem.
- **`T1.F2.5`**: Verify `assets/mirevaine-favicon.svg` has a square viewBox and contains the rounded chocolate tile rect and monogram element.

### Feature 3: Logo & Favicon Theme Wiring
- **`T1.F3.1`**: Verify `layout/theme.liquid` references favicon asset (`mirevaine-favicon.svg` or `mirevaine-favicon.png`) within the HTML `<head>`.
- **`T1.F3.2`**: Verify `sections/header.liquid` contains fallback or direct rendering of the brand logo asset (`mirevaine-logo.svg` or `mirevaine-logo.png`).
- **`T1.F3.3`**: Verify `sections/footer.liquid` contains brand logo or wordmark fallback.
- **`T1.F3.4`**: Verify `config/settings_data.json` contains `logo_width` setting in current settings.
- **`T1.F3.5`**: Verify `layout/theme.liquid` sets logo CSS width constraints (`--logo-width`).

### Feature 4: JSON Comment Sanitization
- **`T1.F4.1`**: Verify `config/settings_data.json` parses successfully with strict RFC 8259 JSON parser.
- **`T1.F4.2`**: Verify `sections/header-group.json` parses successfully with strict RFC 8259 JSON parser.
- **`T1.F4.3`**: Verify `sections/footer-group.json` parses successfully with strict RFC 8259 JSON parser.
- **`T1.F4.4`**: Verify `templates/collection.json` parses successfully with strict RFC 8259 JSON parser.
- **`T1.F4.5`**: Verify 100% of all `.json` files across `config/`, `sections/`, `templates/`, and `locales/` parse without syntax errors.

### Feature 5: Color Scheme Calibration
- **`T1.F5.1`**: Verify `scheme_1` background color in `config/settings_data.json` is Canvas Alabaster (`#FAF8F5`).
- **`T1.F5.2`**: Verify `scheme_1` text and button color in `config/settings_data.json` is Deep Espresso Chocolate (`#2E1E16`).
- **`T1.F5.3`**: Verify `scheme_1` accent color in `config/settings_data.json` is Warm Brushed Gold (`#B38E5D`).
- **`T1.F5.4`**: Verify `scheme_2` background color in `config/settings_data.json` is Soft Cashmere Oatmeal (`#F2EDE4`).
- **`T1.F5.5`**: Verify `scheme_3` / `scheme_4` dark chocolate schemes specify background `#2E1E16` and text `#FAF8F5`.

### Feature 6: Typography & Letter-Spacing
- **`T1.F6.1`**: Verify `heading_font` in `config/settings_data.json` is configured to Cormorant Garamond (`cormorant_garamond_n4`).
- **`T1.F6.2`**: Verify `body_font` in `config/settings_data.json` is configured to Assistant (`assistant_n4`).
- **`T1.F6.3`**: Verify `heading_tracking` setting in `config/settings_data.json` is present and valid.
- **`T1.F6.4`**: Verify CSS variable `--heading-tracking` is generated in `snippets/theme-styles.liquid`.
- **`T1.F6.5`**: Verify uppercase letter-spacing styling is configured for button and navigation elements in `assets/base.css`.

### Feature 7: Desktop Navigation Ribbon
- **`T1.F7.1`**: Verify `sections/header.liquid` contains desktop navigation container `<nav class="nav...`.
- **`T1.F7.2`**: Verify desktop navigation ribbon is centered or styled as an editorial ribbon (`nav--center` or equivalent).
- **`T1.F7.3`**: Verify desktop navigation is displayed on desktop screens (`@media (min-width: 990px)`).
- **`T1.F7.4`**: Verify navigation links contain hover state styling in `assets/base.css`.
- **`T1.F7.5`**: Verify active navigation state (`aria-current` or active class) is supported in header template.

### Feature 8: 5-Category Navigation Fallback
- **`T1.F8.1`**: Verify navigation fallback in `sections/header.liquid` includes Handbags link (`/collections/handbags`).
- **`T1.F8.2`**: Verify navigation fallback in `sections/header.liquid` includes Jewelry link (`/collections/jewelry`).
- **`T1.F8.3`**: Verify navigation fallback in `sections/header.liquid` includes Belts link (`/collections/belts`).
- **`T1.F8.4`**: Verify navigation fallback in `sections/header.liquid` includes Scarves link (`/collections/scarves`).
- **`T1.F8.5`**: Verify navigation fallback in `sections/header.liquid` includes Hair accessories link (`/collections/hair-accessories`).

### Feature 9: Category Sidebar & Footer Links
- **`T1.F9.1`**: Verify `snippets/category-sidebar.liquid` contains link to All Accessories (`/collections/all`).
- **`T1.F9.2`**: Verify `snippets/category-sidebar.liquid` contains fallback links to all 5 accessory categories.
- **`T1.F9.3`**: Verify `snippets/category-sidebar.liquid` compares `collection.handle` to highlight active collection.
- **`T1.F9.4`**: Verify footer links in `sections/footer.liquid` or `sections/footer-group.json` contain collection links.
- **`T1.F9.5`**: Verify footer links include brand touchpoints (`/pages/about`, `/pages/care`, `/pages/contact`).

### Feature 10: The Atelier Story Page
- **`T1.F10.1`**: Verify `templates/page.about.json` exists in `templates/`.
- **`T1.F10.2`**: Verify `templates/page.about.json` parses as valid JSON.
- **`T1.F10.3`**: Verify `templates/page.about.json` contains a hero banner section.
- **`T1.F10.4`**: Verify `templates/page.about.json` contains Tuscan leatherwork / craftsmanship narrative content.
- **`T1.F10.5`**: Verify `templates/page.about.json` contains European heritage / noble fibres pillar content.

### Feature 11: Archival Care Guide Page
- **`T1.F11.1`**: Verify `templates/page.care.json` exists in `templates/`.
- **`T1.F11.2`**: Verify `templates/page.care.json` parses as valid JSON.
- **`T1.F11.3`**: Verify `templates/page.care.json` contains leather preservation instructions.
- **`T1.F11.4`**: Verify `templates/page.care.json` contains fine metal / gold polishing instructions.
- **`T1.F11.5`**: Verify `templates/page.care.json` contains silk care / noble fibres instructions.

### Feature 12: Client Concierge Page
- **`T1.F12.1`**: Verify `templates/page.contact.json` exists in `templates/`.
- **`T1.F12.2`**: Verify `templates/page.contact.json` parses as valid JSON.
- **`T1.F12.3`**: Verify `templates/page.contact.json` contains a functional contact form section (`contact-form`).
- **`T1.F12.4`**: Verify `templates/page.contact.json` contains bespoke inquiries / private appointments content.
- **`T1.F12.5`**: Verify `templates/page.contact.json` contains salon touchpoints / concierge directory.

### Feature 13: Catalogue & Cart Enhancements
- **`T1.F13.1`**: Verify `templates/collection.json` defaults to `sidebar` layout (`"layout": "sidebar"`).
- **`T1.F13.2`**: Verify `snippets/product-card.liquid` supports hover zoom on product cards (`animate-zoom` / `card__image--primary`).
- **`T1.F13.3`**: Verify `snippets/product-card.liquid` supports secondary hover image (`card__image--secondary`).
- **`T1.F13.4`**: Verify `snippets/cart-summary.liquid` defines free shipping threshold of $250 (`250` or `25000`).
- **`T1.F13.5`**: Verify `snippets/cart-summary.liquid` and `sections/cart-drawer.liquid` support order notes (`cart-note`).

### Feature 14: E2E Suite & Git Finalization
- **`T1.F14.1`**: Verify HTTP GET request to `https://mirevaine.myshopify.com/` returns `HTTP/1.1 200 OK`.
- **`T1.F14.2`**: Verify response HTML from `https://mirevaine.myshopify.com/` contains `<title>Mirevaine</title>`.
- **`T1.F14.3`**: Verify local git branch is `master`.
- **`T1.F14.4`**: Verify git remote `origin` is set to `https://github.com/enriquetamorales2026/Fashe.git`.
- **`T1.F14.5`**: Verify tracking branch is set to `origin/master`.

---

## 5. Tier 2: Boundary & Corner Cases (70 Test Cases)

### Feature 1: Logo Artwork Extraction
- **`T2.F1.1`**: Verify corner pixels `(0,0)`, `(570,0)`, `(0,327)`, `(570,327)` in `assets/mirevaine-logo.png` have alpha channel = 0 (100% transparent).
- **`T2.F1.2`**: Verify `assets/mirevaine-logo.png` file size is between 30 KB and 300 KB (valid compressed PNG, non-corrupted).
- **`T2.F1.3`**: Verify `assets/mirevaine-logo.svg` is valid XML with root `<svg xmlns="http://www.w3.org/2000/svg">`.
- **`T2.F1.4`**: Verify `assets/mirevaine-logo.svg` contains explicit `letter-spacing` style attribute on wordmark.
- **`T2.F1.5`**: Verify source image `assets/mirevaine-brand-identity.png` exists and is non-empty.

### Feature 2: Favicon Extraction
- **`T2.F2.1`**: Verify outer corner pixels `(0,0)`, `(147,0)`, `(0,147)`, `(147,147)` in `assets/mirevaine-favicon.png` have alpha = 0.
- **`T2.F2.2`**: Verify `assets/mirevaine-favicon.png` has exact 1:1 aspect ratio (`Width == Height == 148`).
- **`T2.F2.3`**: Verify `assets/mirevaine-favicon.svg` uses Deep Espresso Chocolate `#2E1E16` (or brand chocolate) for the tile background fill.
- **`T2.F2.4`**: Verify `assets/mirevaine-favicon.svg` tile corner radius `rx` is between 15% and 22% of tile width.
- **`T2.F2.5`**: Verify `assets/mirevaine-favicon.png` file size is between 10 KB and 100 KB.

### Feature 3: Logo & Favicon Theme Wiring
- **`T2.F3.1`**: Verify `layout/theme.liquid` contains both SVG favicon tag and PNG fallback icon link tags.
- **`T2.F3.2`**: Verify `sections/header.liquid` logo image tag includes an `alt` attribute for accessibility.
- **`T2.F3.3`**: Verify `sections/header.liquid` logo element specifies `width` and `height` to prevent Cumulative Layout Shift (CLS).
- **`T2.F3.4`**: Verify `logo_width` value in `config/settings_data.json` is within range 60 to 300.
- **`T2.F3.5`**: Verify `sections/header.liquid` falls back to brand text title if logo image is omitted.

### Feature 4: JSON Comment Sanitization
- **`T2.F4.1`**: Verify no file across `config/`, `sections/`, `templates/`, `locales/` contains C-style block comments `/* ... */`.
- **`T2.F4.2`**: Verify no JSON file contains single-line comments `// ...`.
- **`T2.F4.3`**: Verify no JSON file contains trailing commas before closing braces `}` or brackets `]`.
- **`T2.F4.4`**: Verify all JSON files are encoded in clean UTF-8.
- **`T2.F4.5`**: Verify `config/settings_schema.json` parses as an array of setting objects with non-empty schema entries.

### Feature 5: Color Scheme Calibration
- **`T2.F5.1`**: Verify all 4 schemes in `config/settings_data.json` define all 7 required color keys (`background`, `text`, `button`, `button_label`, `outline_button`, `accent`, `border`).
- **`T2.F5.2`**: Verify `presets["Mirevaine Atelier"]` in `config/settings_data.json` reflects calibrated scheme colors.
- **`T2.F5.3`**: Verify `snippets/theme-styles.liquid` translates hex color values into space-separated RGB triplet variables.
- **`T2.F5.4`**: Verify border tokens in schemes provide subtle contrast matching their respective background tones.
- **`T2.F5.5`**: Verify legacy jet black `#141312` is eliminated from scheme 1 background and text settings.

### Feature 6: Typography & Letter-Spacing
- **`T2.F6.1`**: Verify `.header__brand-title` letter-spacing in `assets/base.css` is at least 0.25em.
- **`T2.F6.2`**: Verify `.header__brand-sub` tagline letter-spacing in `assets/base.css` is at least 0.35em.
- **`T2.F6.3`**: Verify heading font fallback family includes standard luxury serif fonts.
- **`T2.F6.4`**: Verify body font fallback family includes standard clean sans-serif fonts.
- **`T2.F6.5`**: Verify font scaling in `config/settings_data.json` has `heading_scale` >= 100 and `body_scale` >= 100.

### Feature 7: Desktop Navigation Ribbon
- **`T2.F7.1`**: Verify desktop navigation ribbon markup is cleanly separated from mobile drawer markup.
- **`T2.F7.2`**: Verify desktop navigation ribbon is hidden below mobile breakpoint (`@media (max-width: 989px)`).
- **`T2.F7.3`**: Verify `<nav>` element contains accessible `aria-label`.
- **`T2.F7.4`**: Verify dropdown or submenu elements contain accessible ARIA attributes.
- **`T2.F7.5`**: Verify navigation link labels use uppercase text transform and generous letter-spacing.

### Feature 8: 5-Category Navigation Fallback
- **`T2.F8.1`**: Verify mobile navigation drawer contains links to all 5 accessory categories.
- **`T2.F8.2`**: Verify all 5 category URLs match the canonical format `/collections/<handle>`.
- **`T2.F8.3`**: Verify all 5 category handles are lowercased and hyphen-separated.
- **`T2.F8.4`**: Verify category fallback list contains exact names: Handbags, Jewelry, Belts, Scarves, Hair accessories.
- **`T2.F8.5`**: Verify mobile drawer close button `#MenuDrawer-Close` exists and is accessible.

### Feature 9: Category Sidebar & Footer Links
- **`T2.F9.1`**: Verify `assets/base.css` specifies `position: sticky` on desktop category sidebar.
- **`T2.F9.2`**: Verify active category item renders distinct styling (`category-sidebar__link--active`).
- **`T2.F9.3`**: Verify footer navigation blocks support multi-column responsive layout.
- **`T2.F9.4`**: Verify footer template renders copyright text and atelier identity.
- **`T2.F9.5`**: Verify footer contains direct touchpoints for client concierge and care guide.

### Feature 10: The Atelier Story Page
- **`T2.F10.1`**: Verify `templates/page.about.json` contains a multicolumn or multi-pillar section with 3 or more pillars.
- **`T2.F10.2`**: Verify `order` array in `templates/page.about.json` strictly matches keys in `sections` object.
- **`T2.F10.3`**: Verify section color schemes in `templates/page.about.json` reference valid schemes (`scheme_1`, `scheme_2`, `scheme_3`).
- **`T2.F10.4`**: Verify rich text editorial section contains atelier philosophy statements.
- **`T2.F10.5`**: Verify newsletter subscription section is integrated at the base of `page.about.json`.

### Feature 11: Archival Care Guide Page
- **`T2.F11.1`**: Verify `templates/page.care.json` contains accordion FAQ section for granular care questions.
- **`T2.F11.2`**: Verify `order` array in `templates/page.care.json` strictly matches keys in `sections` object.
- **`T2.F11.3`**: Verify care guide includes concierge restoration call-to-action block.
- **`T2.F11.4`**: Verify care guide sections specify appropriate quiet luxury color schemes.
- **`T2.F11.5`**: Verify care accordion items have non-empty headings and body content.

### Feature 12: Client Concierge Page
- **`T2.F12.1`**: Verify `sections/contact-form.liquid` renders required fields (Name, Email, Message).
- **`T2.F12.2`**: Verify `order` array in `templates/page.contact.json` strictly matches keys in `sections` object.
- **`T2.F12.3`**: Verify client concierge template includes private appointments / bespoke inquiry guidance.
- **`T2.F12.4`**: Verify contact form section specifies calibrated color scheme.
- **`T2.F12.5`**: Verify form input styling harmonizes with theme border and background tokens in `assets/base.css`.

### Feature 13: Catalogue & Cart Enhancements
- **`T2.F13.1`**: Verify `.card:hover .card__image--secondary` has `transform: scale(1.04)` synchronized with primary image zoom.
- **`T2.F13.2`**: Verify cart free shipping progress bar fill color is set to `rgb(var(--color-accent))`.
- **`T2.F13.3`**: Verify cart summary calculates remaining shipping balance accurately against $250.00 threshold.
- **`T2.F13.4`**: Verify product card swatches handle color name options gracefully.
- **`T2.F13.5`**: Verify desktop collection grid specifies 3 columns with responsive 2-column mobile fallback.

### Feature 14: E2E Suite & Git Finalization
- **`T2.F14.1`**: Verify git repository has clean working tree or staged changes without merge markers (`<<<<<<<`).
- **`T2.F14.2`**: Verify live store headers return Cloudflare server and Shopify e-commerce headers.
- **`T2.F14.3`**: Verify live store root URL does not redirect to password page or 404 error page.
- **`T2.F14.4`**: Verify `.gitignore` excludes editor artifacts while tracking theme templates and assets.
- **`T2.F14.5`**: Verify git commit log reflects clean semantic commit history.

---

## 6. Tier 3: Cross-Feature Combinations (10 Interaction Tests)

- **`T3.C1: Brand Identity Asset Integration (F1 + F2 + F3)`**  
  *Scope*: Assets ↔ Liquid Templates  
  *Assertion*: Cropped PNG/SVG logo and favicon assets exist and are referenced in `layout/theme.liquid` `<head>` and `sections/header.liquid` without missing asset errors or broken image tags.

- **`T3.C2: Color Scheme & Typography Harmonization (F5 + F6)`**  
  *Scope*: Settings Data ↔ CSS Tokens  
  *Assertion*: Calibrated color schemes (`scheme_1` through `scheme_4`) generate matching CSS custom properties in `snippets/theme-styles.liquid` that apply across Cormorant Garamond serif headings and Assistant body copy.

- **`T3.C3: Desktop & Mobile Navigation Hierarchy (F7 + F8)`**  
  *Scope*: Header ↔ Drawer Fallbacks  
  *Assertion*: Desktop navigation ribbon and mobile slide-out drawer render identical 5 accessory category links (`/collections/handbags`, `jewelry`, `belts`, `scarves`, `hair-accessories`).

- **`T3.C4: Category Sidebar & Collection Template Integration (F9 + F13)`**  
  *Scope*: Collection Template ↔ Sidebar Snippet  
  *Assertion*: `templates/collection.json` defaults to `"layout": "sidebar"`, which triggers `sections/main-collection.liquid` to render `snippets/category-sidebar.liquid` displaying all 5 categories and All Accessories.

- **`T3.C5: Brand Story & Theme Scheme Consistency (F10 + F5)`**  
  *Scope*: About Template ↔ Color System  
  *Assertion*: `templates/page.about.json` utilizes the calibrated color schemes (`scheme_1` Canvas Alabaster, `scheme_2` Soft Cashmere Oatmeal) for its editorial blocks.

- **`T3.C6: Archival Care Guide & Typography/Accordion Integration (F11 + F6)`**  
  *Scope*: Care Template ↔ Typography Hierarchy  
  *Assertion*: `templates/page.care.json` utilizes accordion blocks whose typographic hierarchy follows the serif heading and tracked uppercase eyebrow styling.

- **`T3.C7: Client Concierge & Footer Navigation Touchpoints (F12 + F9)`**  
  *Scope*: Contact Template ↔ Footer Navigation  
  *Assertion*: Client Concierge page `/pages/contact` is wired into footer navigation links alongside salon appointment and bespoke inquiry CTAs.

- **`T3.C8: Product Card Visual Polish & Theme Hover Animations (F13 + F6)`**  
  *Scope*: Product Cards ↔ Base CSS Animation  
  *Assertion*: Hover zoom animations and secondary image transitions on product cards apply uniformly to cards rendered across featured collection and search templates.

- **`T3.C9: Cart Drawer Shipping Bar & Theme Color Tokens (F13 + F5)`**  
  *Scope*: Cart Summary ↔ Color Tokens  
  *Assertion*: Cart summary free shipping progress bar utilizes `rgb(var(--color-accent))` calibrated to Warm Brushed Gold (`#B38E5D`) against the Soft Cashmere background.

- **`T3.C10: JSON Schema Integrity & Multi-Template Coherence (F4 + F10 + F11 + F12 + F13)`**  
  *Scope*: Global JSON Repository  
  *Assertion*: All theme templates (`collection.json`, `page.about.json`, `page.care.json`, `page.contact.json`, `settings_data.json`) pass strict RFC 8259 validation together.

---

## 7. Tier 4: Real-World Application Scenarios (5 Shopper & Client Workflows)

### Scenario 1: The High-Jewelry Connoisseur Journey (`T4.S1`)
- **Shopper Action**: Shopper arrives on Mirevaine homepage on desktop.
- **Verification**:
  1. Header logo displays high-resolution flourished "M" and "MIREVAINE" wordmark.
  2. Canvas Alabaster `#FAF8F5` background and Deep Espresso `#2E1E16` headings establish quiet luxury atmosphere.
  3. Shopper clicks "Jewelry" in the centered desktop navigation ribbon, navigating to `/collections/jewelry`.
  4. Desktop layout renders sticky Category sidebar with "Jewelry" highlighted as active.
  5. Shopper hovers over product card: primary and secondary images execute synchronized zoom (1.04 scale) with smooth cross-fade.

### Scenario 2: Archival Leather Care & Concierge Inquiry Flow (`T4.S2`)
- **Shopper Action**: Client seeks preservation guidance for a vintage leather handbag.
- **Verification**:
  1. Client clicks "Archival Care" in footer navigation, reaching `/pages/care`.
  2. Page displays hero statement and material pillars (Leather Preservation, Fine Metals, Silk Twill).
  3. Client expands accordion FAQ item detailing leather nourishment and rain exposure.
  4. Client clicks concierge restoration CTA, navigating to `/pages/contact`.
  5. Client fills out private appointment & bespoke commission inquiry form.

### Scenario 3: Luxury Gifting & Free Shipping Threshold Attainment (`T4.S3`)
- **Shopper Action**: Client curates an elevated accessory bundle.
- **Verification**:
  1. Client adds handcrafted belt ($180) to cart; cart drawer opens smoothly via AJAX.
  2. Dynamic shipping progress bar calculates remaining balance ($70) with Warm Brushed Gold fill.
  3. Client adds fine silk twill scarf ($95), pushing subtotal to $275 (> $250).
  4. Progress bar reaches 100% with gold fill and announces "You qualify for free shipping."
  5. Client enters bespoke gift packaging note into the order notes textarea.

### Scenario 4: Mobile Smartphone Shopper Exploration Flow (`T4.S4`)
- **Shopper Action**: Mobile client visits store on 375px viewport.
- **Verification**:
  1. Compact brand icon / logo fits responsively without horizontal overflow.
  2. Tapping mobile drawer icon opens `#MenuDrawer` smoothly.
  3. Drawer displays all 5 luxury categories (Handbags, Jewelry, Belts, Scarves, Hair accessories).
  4. Tapping Handbags loads `/collections/handbags`; sidebar stacks responsively above 2-column product grid.
  5. Swatch indicators display cleanly below product titles.

### Scenario 5: Atelier Heritage Brand Discovery Flow (`T4.S5`)
- **Shopper Action**: Discerning client explores the house origins.
- **Verification**:
  1. Client clicks "The Atelier Story" in footer or header navigation, loading `/pages/about`.
  2. Hero banner introduces "Tuscan Heritage & Noble Craft".
  3. Alternating image-with-text sections present Tuscan leathercraft and Florentine vermeil artistry.
  4. 3-column heritage section outlines pillars of European provenance.
  5. Client subscribes to the Mirevaine Gazette newsletter at the bottom of the page.

---

## 8. Test Execution Guide

### 8.1 Command-Line Interface
The complete test suite is executed via PowerShell:

```powershell
# Run the complete test suite across all 4 tiers (all 155 test cases)
powershell.exe -ExecutionPolicy Bypass -File tests\run_e2e_tests.ps1

# Run specific tiers
powershell.exe -ExecutionPolicy Bypass -File tests\run_e2e_tests.ps1 -Tier 1,2
powershell.exe -ExecutionPolicy Bypass -File tests\run_e2e_tests.ps1 -Tier 3,4

# Run specific feature tests
powershell.exe -ExecutionPolicy Bypass -File tests\run_e2e_tests.ps1 -Feature F1,F2,F3

# Run in reporting / soft-exit mode (returns 0 for harness verification)
powershell.exe -ExecutionPolicy Bypass -File tests\run_e2e_tests.ps1 -ReportOnly
```

### 8.2 Pass / Fail Criteria
- **Pass (Exit Code 0)**: 100% of selected test cases assert true.
- **Fail (Exit Code 1)**: Any test case assertion fails. Detailed failure diagnostics, file path, line number, and expected vs actual values are output to console.
