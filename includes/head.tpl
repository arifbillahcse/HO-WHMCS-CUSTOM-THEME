<!-- Styling -->
<!-- Hostorio brand fonts: Roboto (body) + Rosario (headings).
     Replaces the stock Open Sans / Raleway includes. -->
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Roboto:wght@400;500;700&family=Rosario:wght@400;500;700&display=swap" rel="stylesheet">
<link href="{assetPath file='all.min.css'}?v={$versionHash}" rel="stylesheet">
<link href="{$WEB_ROOT}/assets/fonts/css/fontawesome.min.css" rel="stylesheet">
<link href="{$WEB_ROOT}/assets/fonts/css/fontawesome-solid.min.css" rel="stylesheet">
<link href="{$WEB_ROOT}/assets/fonts/css/fontawesome-regular.min.css" rel="stylesheet">
<link href="{$WEB_ROOT}/assets/fonts/css/fontawesome-light.min.css" rel="stylesheet">
<link href="{$WEB_ROOT}/assets/fonts/css/fontawesome-brands.min.css" rel="stylesheet">
<link href="{$WEB_ROOT}/assets/fonts/css/fontawesome-duotone.min.css" rel="stylesheet">
{*
    Cache-buster for this theme's own CSS and JS.

    The stock assets above use ?v={$versionHash}, which is derived from
    the WHMCS version — it changes when WHMCS is upgraded, never when a
    template file is edited. That is right for files that only change on
    upgrade, but wrong for the ones below: editing them leaves the URL
    byte-identical, so browsers and any CDN in front keep serving the
    previous copy and the change appears not to have deployed at all.

    BUMP THIS STRING on every deploy that touches css/custom.css,
    css/hostorio-layout.css, js/hostorio-sidebar.js,
    js/hostorio-product-overview.js, js/hostorio-store-cards.js, or
    js/hostorio-ai-search.js.

    A literal rather than filemtime() because WHMCS's Smarty security
    policy may refuse unregistered PHP calls, and a stale stylesheet is
    a better failure than a fatal template error.

    scope="global": default {assign} scope only reaches templates
    head.tpl itself includes. includes/ai-search.tpl needs this same
    value too, but it's included from clientareahome.tpl — a sibling
    branch under the master layout, not a descendant of head.tpl — so
    without global scope it would render as empty there.
*}
{assign var="hoAssetVersion" value="ho-22" scope="global"}
{*
    custom.css previously rendered as bare {$__assetPath__}, with no
    version query at all — so an edit to the token layer could never
    reach a returning visitor. Written out the same way as
    hostorio-layout.css below so all three share one buster. The
    assetExists guard stays: custom.css is optional, and linking it
    unconditionally would 404 on an install that has none.
*}
{assetExists file="custom.css"}
<link href="{$WEB_ROOT}/templates/{$template}/css/custom.css?v={$hoAssetVersion}" rel="stylesheet">
{/assetExists}
<!-- Hostorio layout: header, navigation, footer. Loads last so it
     can override both the stock bundle and the token base layer.
     Built from $WEB_ROOT + $template rather than assetPath so it
     resolves from the active theme directory directly. -->
<link href="{$WEB_ROOT}/templates/{$template}/css/hostorio-layout.css?v={$hoAssetVersion}" rel="stylesheet">

<!-- HTML5 Shim and Respond.js IE8 support of HTML5 elements and media queries -->
<!-- WARNING: Respond.js doesn't work if you view the page via file:// -->
<!--[if lt IE 9]>
  <script src="https://oss.maxcdn.com/libs/html5shiv/3.7.0/html5shiv.js"></script>
  <script src="https://oss.maxcdn.com/libs/respond.js/1.4.2/respond.min.js"></script>
<![endif]-->

<script type="text/javascript">
    var csrfToken = '{$token}',
        markdownGuide = '{lang|addslashes key="markdown.title"}',
        locale = '{if !empty($mdeLocale)}{$mdeLocale}{else}en{/if}',
        saved = '{lang|addslashes key="markdown.saved"}',
        saving = '{lang|addslashes key="markdown.saving"}',
        whmcsBaseUrl = "{\WHMCS\Utility\Environment\WebHelper::getBaseUrl()}";
    {if $captcha}{$captcha->getPageJs()}{/if}
</script>
<script src="{assetPath file='scripts.min.js'}?v={$versionHash}"></script>
{*
    DIAGNOSTIC — TEMPORARY. All four of this theme's own custom
    scripts (the three below, plus hostorio-ai-search.js in
    includes/ai-search.tpl) and the chat widget tag in header.tpl are
    disabled here to isolate a report that the order-form checkout
    flow (product -> domain choice -> configure -> checkout) breaks
    under this theme but works on WHMCS's stock theme.

    Root-cause mechanism, confirmed by reading the order form's own
    JS: the "Use"/"Check"/"Continue" buttons on the domain-choice step
    are plain <button type="submit"> inside a <form> with no action/
    method attribute — it only works because JS intercepts the submit
    and redirects manually. If that binding never attaches (jQuery not
    ready, or an earlier script in the same tag throwing and halting
    the rest of that file), the browser falls back to a native GET
    submit of the current URL, which reads exactly like "redirected
    back to the product page" for every domain option — matching the
    report. Every other layer (the AJAX call, the pages it navigates
    through) was verified working correctly independent of theme.

    This commented block is the test: if disabling every JS file this
    theme adds fixes the flow, the cause is confirmed to be one of
    them, and they get re-enabled one at a time from here to find
    which. If it does NOT fix it, the cause is elsewhere and none of
    this should stay commented — restore it immediately either way.
*}
{* <!-- Off-canvas behaviour for the sidebar rail below 992px. Same
     $WEB_ROOT + $template path as hostorio-layout.css. -->
<script src="{$WEB_ROOT}/templates/{$template}/js/hostorio-sidebar.js?v={$hoAssetVersion}" defer></script>
<!-- Removes the "Quick Shortcuts" / "Quick Create Email Account"
     panels the cPanel provisioning module adds to a product's
     Overview tab — module output, not a template in this theme, so
     there is no .tpl to edit them out of. Loaded sitewide rather than
     only on clientareaproductdetails: it is a no-op wherever those
     headings are not present, and gating it on $templatefile would
     need to name every action value that page can be reached under. -->
<script src="{$WEB_ROOT}/templates/{$template}/js/hostorio-product-overview.js?v={$hoAssetVersion}" defer></script>
<!-- Reshapes the order form's product cards on /store/<category> and
     cart.php?gid=N: turns each product's <br>-separated description
     into a real ticked list, and lifts the products out of WHMCS's
     two-per-row Bootstrap rows into one grid. That markup comes from
     templates/orderforms/, not this theme, and neither change is
     reachable from CSS — see the file header. No-op on every other
     page, since it keys off #order-standard_cart. -->
<script src="{$WEB_ROOT}/templates/{$template}/js/hostorio-store-cards.js?v={$hoAssetVersion}" defer></script> *}

{if $templatefile == "viewticket" && !$loggedin}
  <meta name="robots" content="noindex" />
{/if}
