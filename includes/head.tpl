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
{assetExists file="custom.css"}
<link href="{$__assetPath__}" rel="stylesheet">
{/assetExists}
{*
    Cache-buster for this theme's own CSS/JS.

    The stock assets above use ?v={$versionHash}, which is derived from
    the WHMCS version — it changes when WHMCS is upgraded, never when a
    template file is edited. That is right for files that only change on
    upgrade, but wrong for these two: editing them leaves the URL
    byte-identical, so browsers and any CDN in front keep serving the
    previous copy and the change appears not to have deployed at all.

    Bump this string on every deploy that touches css/hostorio-layout.css
    or js/hostorio-sidebar.js. A literal rather than filemtime() because
    WHMCS's Smarty security policy may refuse unregistered PHP calls, and
    a stale stylesheet is a better failure than a fatal template error.
*}
{assign var="hoAssetVersion" value="ho-4"}
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
<!-- Off-canvas behaviour for the sidebar rail below 992px. Same
     $WEB_ROOT + $template path as hostorio-layout.css. -->
<script src="{$WEB_ROOT}/templates/{$template}/js/hostorio-sidebar.js?v={$hoAssetVersion}" defer></script>

{if $templatefile == "viewticket" && !$loggedin}
  <meta name="robots" content="noindex" />
{/if}
