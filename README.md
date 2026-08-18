# Hostorio WHMCS Custom Theme

This repo tracks the client-area theme for `my.hostorio.com` (WHMCS 9.0.6, Twenty-One base).

## Structure

**The repo root *is* the theme directory.** `header.tpl`, `footer.tpl`, `css/`, `js/`, `includes/`, `store/` and the rest sit directly at the top level, laid out exactly as WHMCS expects inside `templates/<theme>/`. There is no wrapper folder to copy — a checkout of this repo is a working theme.

Two directories are *not* part of the theme WHMCS renders:

- **`hooks/`** — WHMCS hooks that support the theme but cannot run from inside it. See "Hooks" below.
- **`.git/`** — harmless to WHMCS; it never reads it.

`theme.yaml` sets `name: "Six"`, which is Twenty-One's internal name. **Do not change it** — WHMCS resolves `{assetPath}` lookups through that name, and renaming it 404s the theme's stock CSS/JS. It is unrelated to the folder name the theme is installed under, which is what the admin area's Client Theme setting selects.

## Deployment

The live site pulls this repo directly via **cPanel → Git Version Control**, with the repo checked out as the theme folder inside `templates/`. To deploy:

1. Push to the branch cPanel is tracking.
2. In cPanel → Git Version Control → **Manage** → **Update from Remote** (it does not poll GitHub on its own).
3. Hard-refresh the browser.

Theme templates recompile on their own when Smarty sees a newer `.tpl`. CSS and JS do not — see "Cache-busting" below.

**`hooks/` does not deploy this way** and must be copied manually; see below.

## Cache-busting

`includes/head.tpl` assigns `$hoAssetVersion` (currently a literal like `ho-14`) and appends it as `?v=` to this theme's own CSS and JS.

**Bump that string on every deploy that touches:**

- `css/custom.css`
- `css/hostorio-layout.css`
- `js/hostorio-sidebar.js`
- `js/hostorio-product-overview.js`

WHMCS's stock assets use `?v={$versionHash}` instead, which is derived from the WHMCS *version* — it changes on a WHMCS upgrade and never when a template file is edited. Leaving these files on that value means an edit keeps a byte-identical URL, so browsers and any CDN in front keep serving the previous copy and the change looks like it never deployed.

## Design tokens

`css/custom.css` holds the single `:root` custom-properties block used across the theme (colors, spacing, radius, typography), plus the `html { font-size }` base the `rem` tokens resolve against. It reuses the token names WHMCS introduced for the Dynamic Store pages, extended to cover the rest of the theme. Update brand colors, fonts and the base size in one place there.

`css/hostorio-layout.css` loads after it and holds the actual layout and component work, in numbered sections (header, app shell, sidebar, footer, content area, Dynamic Store, responsive).

## Hooks

`hooks/` holds WHMCS hooks that support the theme but **cannot run from inside it** — WHMCS only auto-loads hooks from the WHMCS installation's own `includes/hooks/` directory, never from `templates/*`.

**These do not arrive via the git pull above.** Copy each file to `{WHMCS root}/includes/hooks/` by hand after changing it. They are kept in this repo purely so the source is version-controlled alongside the theme it serves; each file's header comment documents what it does and where it goes.

## Upgrade compatibility

WHMCS core updates never touch `templates/*`, so this theme survives them untouched. The trade-off is that stock template changes shipped in a new WHMCS release do not arrive either, and have to be merged in by hand.

To diff against a clean baseline after an upgrade, unpack the release's own `templates/twenty-one/` into a scratch directory and compare — this repo does not carry a pristine copy. (It did once, at `twenty-one/`, removed when the repo was flattened to root so that a checkout could be a theme directory directly.)

## Local preview

This repo contains only the theme layer, not a full WHMCS install. To preview changes:

1. Set up a local/staging WHMCS installation (Docker image, or a WHMCS trial licence on a LAMP stack).
2. Check this repo out into that install's `templates/` directory as a folder — e.g. `templates/ho-whmcs-theme/`.
3. Activate it under **Admin Area → System Settings → General Settings → Client Theme**.
4. Copy `hooks/*.php` into `{WHMCS root}/includes/hooks/`.
