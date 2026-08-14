# Hostorio WHMCS Custom Theme

This repo tracks the client-area theme for `my.hostorio.com` (WHMCS 9.0.6, Twenty-One base).

## Structure

- **`twenty-one/`** — Pristine, untouched copy of WHMCS's stock Twenty-One theme. Never edit files here. Kept as a reference / rollback point and to diff against after future WHMCS core upgrades.
- **`ho-whmcs-theme/`** — The active custom theme. All design work happens here. Deploy by copying this folder to `templates/ho-whmcs-theme/` on the WHMCS server, then set **Admin Area → System Settings → General Settings → Client Theme** to `ho-whmcs-theme`.

Because WHMCS has no child-theme mechanism, keeping a full untouched copy alongside the working copy is the safest way to preserve upgrade compatibility: WHMCS core updates never touch `templates/*`, so both folders survive core upgrades untouched by WHMCS itself, and `twenty-one/` gives us a clean baseline to diff against when merging in any stock template changes from a new WHMCS release.

## Design tokens

`ho-whmcs-theme/css/custom.css` holds the single `:root` CSS custom-properties block used across the theme (colors, spacing, radius, typography). It reuses the token names WHMCS itself introduced for the newer Dynamic Store pages, extended to cover the rest of the theme (header, footer, dashboard, invoices, tickets). Update brand colors/fonts in one place there.

## Local preview

This repo only contains the theme layer, not a full WHMCS install. To preview changes:
1. Set up a local/staging WHMCS installation (Docker image or a WHMCS trial license on a LAMP/Docker stack).
2. Copy `ho-whmcs-theme/` into that install's `templates/` directory.
3. Activate it as the Client Theme in the admin area.
