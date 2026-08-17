<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="{$charset}" />
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{if $kbarticle.title}{$kbarticle.title} - {/if}{$pagetitle} - {$companyname}</title>

    {include file="$template/includes/head.tpl"}

    {$headoutput}

    {* Hostorio Chatbot Widget *}
    <script src="https://chat.hostorio.com/api/widget/widget.js"
            data-endpoint="https://chat.hostorio.com/api/chat"
            data-accent="#2563eb"
            defer></script>

</head>
{*
    Login and registration render without the nav rail (below) and
    without the footer (footer.tpl). This class is the hook for what
    that leaves behind — see the chromeless-pages section in
    css/hostorio-layout.css.
*}
<body data-phone-cc-input="{$phoneNumberInputStyle}"{if $showingLoginPage || $templatefile == 'clientregister'} class="ho-page-chromeless"{/if}>
{if $captcha}{$captcha->getMarkup()}{/if}
{$headeroutput}

<section id="header">
    <div class="container">

        {*
            Opens the navigation drawer below 992px. On wider screens
            the rail is permanently visible and this button is hidden,
            so it replaces the old .navbar-toggle entirely.

            Login and registration render without the rail (see the
            .ho-shell below), so there is nothing there for it to open.
        *}
        {if !$showingLoginPage && $templatefile != 'clientregister'}
            <button type="button" class="ho-sidebar-toggle" aria-controls="main-menu" aria-expanded="false">
                <span class="sr-only">{lang key='toggleNav'}</span>
                <i class="fas fa-bars"></i>
            </button>
        {/if}

        <ul class="top-nav">
            {*
                Language switcher, restricted to English and Bangla.

                WHMCS ships ~25 locales and the stock Bootstrap popover
                listed every one of them in a three-column grid. Only two
                are actually translated for this install, so the list is
                filtered to those and rendered as the flag + native-name
                dropdown the marketing site already uses, so the two
                properties read as one product.

                $offeredLanguages holds WHMCS's own language keys. 'bengali'
                is the folder name a Bangla pack must use under /lang for
                WHMCS to pick it up; until that pack exists WHMCS reports
                only one locale, count($locales) > 1 is false, and this
                whole block stays hidden — no empty control appears.

                Unlike the marketing site's version, the options are plain
                links rather than <button data-language="..."> driven by JS:
                WHMCS switches locale server-side from the ?language= query
                parameter, so a link does the work with nothing to script,
                and the current locale is marked from $activeLocale rather
                than tracked in the browser.
            *}
            {if $languagechangeenabled && count($locales) > 1}
                {assign var="offeredLanguages" value=['english', 'bengali']}
                <li class="language-nav-item">
                    <div class="language-selector" id="languageChooser">
                        <img src="{$WEB_ROOT}/templates/{$template}/img/flags/{if $activeLocale.language == 'bengali'}bd{else}us{/if}.png" alt="{$activeLocale.localisedName}" class="flag-icon">
                        <span>{$activeLocale.localisedName}</span>
                        <i class="fas fa-chevron-down"></i>

                        <div class="language-dropdown-menu">
                            {foreach $locales as $locale}
                                {if in_array($locale.language, $offeredLanguages)}
                                    <a href="{$currentpagelinkback}language={$locale.language}" class="language-option{if $locale.language == $activeLocale.language} active{/if}">
                                        <img src="{$WEB_ROOT}/templates/{$template}/img/flags/{if $locale.language == 'bengali'}bd{else}us{/if}.png" alt="{$locale.localisedName}" class="flag-icon">
                                        <span>{$locale.localisedName}</span>
                                    </a>
                                {/if}
                            {/foreach}
                        </div>
                    </div>
                </li>
            {/if}
            {if $loggedin}
                <li class="cart-nav-item">
                    <a href="{$WEB_ROOT}/cart.php?a=view" title="{$LANG.viewcart}">
                        <i class="fas fa-shopping-cart"></i>
                        <span id="cartItemCount" class="label label-info">{$cartitemcount}</span>
                    </a>
                </li>
                <li class="primary-action">
                    <a href="{$WEB_ROOT}/logout.php" class="btn">
                        {$LANG.clientareanavlogout}
                    </a>
                </li>
            {else}
                <li>
                    <a href="{$WEB_ROOT}/clientarea.php">{$LANG.login}</a>
                </li>
                {if $condlinks.allowClientRegistration}
                    <li>
                        <a href="{$WEB_ROOT}/register.php">{$LANG.register}</a>
                    </li>
                {/if}
                <li class="cart-nav-item">
                    <a href="{$WEB_ROOT}/cart.php?a=view" title="{$LANG.viewcart}">
                        <i class="fas fa-shopping-cart"></i>
                        <span id="cartItemCount" class="label label-info">{$cartitemcount}</span>
                    </a>
                </li>
            {/if}
            {if $adminMasqueradingAsClient || $adminLoggedIn}
                <li>
                    <a href="{$WEB_ROOT}/logout.php?returntoadmin=1" class="btn btn-logged-in-admin" data-toggle="tooltip" data-placement="bottom" title="{if $adminMasqueradingAsClient}{$LANG.adminmasqueradingasclient} {$LANG.logoutandreturntoadminarea}{else}{$LANG.adminloggedin} {$LANG.returntoadminarea}{/if}">
                        <i class="fas fa-sign-out-alt"></i>
                    </a>
                </li>
            {/if}
        </ul>

        {*
            $assetLogoPath is WHMCS's own logo, set in Admin > Setup >
            General Settings > General > Company Logo; if one is
            uploaded there it takes priority automatically. Until
            then, the marketing site's own logo is the fallback rather
            than the plain wordmark text, so the client area matches
            hostorio.com without depending on that admin step.
        *}
        {if $assetLogoPath}
            <a href="{$WEB_ROOT}/index.php" class="logo"><img src="{$assetLogoPath}" alt="{$companyname}"></a>
        {else}
            <a href="{$WEB_ROOT}/index.php" class="logo"><img src="https://hostorio.com/wp-content/themes/Hostorio/assets/images/logo/hostorio-logo.png" alt="{$companyname}"></a>
        {/if}

    </div>
</section>

{*
    App shell: left navigation rail + content column.

    The rail carries the same $primaryNavbar / $secondaryNavbar data
    the horizontal bar used to render, so nothing about the menu
    source changes — only the wrapper markup, which stacks the items
    vertically. Bootstrap's dropdown JS still drives the sub-menus;
    hostorio-layout.css renders them inline (accordion style) rather
    than as floating panels.

    .ho-shell must stay closed in footer.tpl.
*}
<div class="ho-shell">

{*
    Login and registration are deliberately chromeless. A visitor who
    is not signed in has nowhere to navigate to — every rail link
    bounces straight back to the login form — so the rail is dropped
    rather than hidden.

    Nothing else has to change for it: .ho-content is flex:1 1 auto,
    so the content column simply takes the full width, and
    js/hostorio-sidebar.js no-ops when #main-menu is absent.

    footer.tpl trims its link columns on the same condition.
*}
{if !$showingLoginPage && $templatefile != 'clientregister'}
    <aside id="main-menu" class="ho-sidebar">
        <div class="ho-sidebar-inner">

            {* Only shown while the rail is an overlay drawer (<992px);
               on desktop the logo in the header sits directly above it. *}
            <div class="ho-sidebar-head">
                <a href="{$WEB_ROOT}/index.php" class="ho-sidebar-brand">{$companyname}</a>
                <button type="button" class="ho-sidebar-close">
                    <span class="sr-only">{$LANG.close}</span>
                    <i class="fas fa-times"></i>
                </button>
            </div>

            <nav id="nav" class="navbar navbar-default navbar-main" role="navigation">
                <div id="primary-nav" class="ho-sidebar-nav">

                    <ul class="nav navbar-nav ho-nav-primary">

                        {include file="$template/includes/navbar.tpl" navbar=$primaryNavbar}

                    </ul>

                    <ul class="nav navbar-nav ho-nav-secondary">

                        {include file="$template/includes/navbar.tpl" navbar=$secondaryNavbar}

                    </ul>

                </div>
            </nav>

        </div>
    </aside>
{/if}

<div class="ho-content">

{if $templatefile == 'homepage'}
    <section id="home-banner">
        <div class="container text-center">
            {if $registerdomainenabled || $transferdomainenabled}
                <h2>{$LANG.homebegin}</h2>
                <form method="post" action="domainchecker.php" id="frmDomainHomepage">
                    <input type="hidden" name="transfer" />
                    <div class="row">
                        <div class="{if $showAdvancedSearchOptions}col-lg-6 col-lg-offset-3 {/if}col-md-8 col-md-offset-2 col-sm-10 col-sm-offset-1">
                            <div class="input-group input-group-lg{if $showAdvancedSearchOptions} advanced-input{/if}">
                                {if $showAdvancedSearchOptions}
                                    <textarea name="message"
                                              id="message"
                                              title="{lang key='domainSearch.domainOrAiPrompt'}"
                                              data-placement="left"
                                              data-trigger="manual"
                                              placeholder="{lang key='domainSearch.domainOrAiInstruction'}"></textarea>
                                {else}
                                    <input type="text" class="form-control" name="domain" placeholder="{$LANG.exampledomain}" autocapitalize="none" data-toggle="tooltip" data-placement="left" data-trigger="manual" title="{lang key='orderForm.required'}" />
                                {/if}
                                <span class="input-group-btn">
                                    {if $registerdomainenabled}
                                        <input type="submit" class="btn search{$captcha->getButtonClass($captchaForm)}" value="{$LANG.search}" id="btnDomainSearch" />
                                    {/if}
                                    {if $transferdomainenabled}
                                        <input type="submit" id="btnTransfer" class="btn transfer{$captcha->getButtonClass($captchaForm)}" value="{$LANG.domainstransfer}" />
                                    {/if}
                                </span>
                                {if $showAdvancedSearchOptions}
                                    <span class="input-group input-group-lg{if $showAdvancedSearchOptions} advanced-input{/if}">
                                        <select name="tlds[]" class="multiselect multiselect-filter" multiple="multiple" data-placeholder="{lang key='domainSearch.tlds'}" data-min-selection="1">
                                            {foreach $tlds as $tld}
                                                <option{if in_array($tld, $selectedTlds)} selected {if count($selectedTlds) <= 1}disabled="disabled"{/if}{/if} value="{$tld}">{$tld}</option>
                                            {/foreach}
                                        </select>
                                        <select name="maxLength" class="multiselect" data-placeholder="{lang key='domainSearch.maxLength'}">
                                            {foreach $searchLengths as $len}
                                                <option value="{$len}" {if $maxLength === $len}selected{/if}>{$len}</option>
                                            {/foreach}
                                        </select>
                                        <label>
                                            <input type="checkbox" class="no-icheck" name="filter" {if $safeSearchSelected}checked{/if}> {lang key="domainSearch.safeSearch"}
                                        </label>
                                    </span>
                                {/if}
                            </div>
                        </div>
                    </div>

                    {include file="$template/includes/captcha.tpl"}
                </form>
            {else}
                <h2>{$LANG.doToday}</h2>
            {/if}
        </div>
    </section>
    <div class="home-shortcuts">
        <div class="container">
            <div class="row">
                <div class="col-md-4 hidden-sm hidden-xs text-center">
                    <p class="lead">
                        {$LANG.howcanwehelp}
                    </p>
                </div>
                <div class="col-sm-12 col-md-8">
                    <ul>
                        {if $registerdomainenabled || $transferdomainenabled}
                            <li>
                                <a id="btnBuyADomain" href="domainchecker.php">
                                    <i class="fas fa-globe"></i>
                                    <p>
                                        {$LANG.buyadomain} <span>&raquo;</span>
                                    </p>
                                </a>
                            </li>
                        {/if}
                        <li>
                            <a id="btnOrderHosting" href="{$WEB_ROOT}/cart.php">
                                <i class="far fa-hdd"></i>
                                <p>
                                    {$LANG.orderhosting} <span>&raquo;</span>
                                </p>
                            </a>
                        </li>
                        <li>
                            <a id="btnMakePayment" href="clientarea.php">
                                <i class="fas fa-credit-card"></i>
                                <p>
                                    {$LANG.makepayment} <span>&raquo;</span>
                                </p>
                            </a>
                        </li>
                        <li>
                            <a id="btnGetSupport" href="submitticket.php">
                                <i class="far fa-envelope"></i>
                                <p>
                                    {$LANG.getsupport} <span>&raquo;</span>
                                </p>
                            </a>
                        </li>
                    </ul>
                </div>
            </div>
        </div>
    </div>
{/if}

{if $showAdvancedSearchOptions}
    <script>
        $(document).ready(function() {
            jQuery('#frmDomainHomepage .multiselect').each(function () {
                const enableFiltering = $(this).hasClass('multiselect-filter');
                const minSelection = jQuery(this).data('min-selection');
                $(this).multiselect({
                    onChange: function (element) {
                        const closestSelect = element.closest('select');
                        const selectedOptions = closestSelect.find('option:selected');
                        if (minSelection === undefined) {
                            return;
                        }
                        const atMinOptions = selectedOptions.length <= minSelection;
                        const targetOptions = atMinOptions ? selectedOptions : closestSelect.find('option');
                        targetOptions.each(function () {
                            const inputElement = jQuery('input[value="' + jQuery(this).val() + '"]');
                            inputElement.prop('disabled', atMinOptions ? 'disabled' : false);
                        });
                    },
                    buttonText: function(options, select) {
                        return select.data('placeholder');
                    },
                    maxHeight: 200,
                    includeFilterClearBtn: false,
                    enableCaseInsensitiveFiltering: enableFiltering,
                });
            })
        });
    </script>
{/if}

{include file="$template/includes/validateuser.tpl"}
{include file="$template/includes/verifyemail.tpl"}

<section id="main-body">
    <div class="container{if $skipMainBodyContainer}-fluid without-padding{/if}">
        <div class="row">

        {*
            $primarySidebar (the "View" filters / "Actions" panel WHMCS
            renders on Services, Domains, Invoices, Tickets, etc.) used
            to get its own col-md-3 left column here, mirroring the
            old horizontal navbar's sibling layout. Now that navigation
            lives in the rail (see the .ho-shell above), that left
            column is gone — the panel renders as a horizontal bar
            inside .main-content instead. Same $primarySidebar data,
            no core/PHP changes; see includes/sidebar-horizontal.tpl.
        *}
        {*
            Login and registration take the middle six columns of the
            grid, so the row reads col-3 | col-6 | col-3 — the offset
            supplies the empty quarter on the left, the column's own
            width the one on the right. Both are md classes, so the
            split only applies from 992px up and the form stays
            full-bleed on phones and tablets.

            Stock the form is full width. That was survivable while the
            nav rail took its width off the left, but these two pages
            drop the rail, so without this a field runs the whole
            window and the paired rows on the registration form drift
            too far apart to read as pairs.
        *}
        <!-- Container for main page display content -->
        <div class="col-xs-12{if $showingLoginPage || $templatefile == 'clientregister'} col-md-6 col-md-offset-3{/if} main-content">
            {if !$showingLoginPage && !$inShoppingCart && $templatefile != 'homepage' && !$skipMainBodyContainer}
                {include file="$template/includes/pageheader.tpl" title=$displayTitle desc=$tagline showbreadcrumb=true}
            {/if}
            {*
                Client Details ("Your Info" on the client area home
                page) is not part of $panels — clientareahome.tpl
                filters that collection separately and never touches
                this one. It arrives through $primarySidebar instead,
                the same collection Services/Domains/Tickets pages use
                for their View/Actions bar, which is why it has to be
                filtered here rather than in sidebar-horizontal.tpl:
                that template is shared by every page using this
                sidebar and must stay generic.

                Filtered before hasChildren() is checked, not after,
                so that if this is the only panel present the whole
                bar — and its border — never renders instead of
                showing empty.

                Matched on getName(), read directly off this page's
                own rendered menuItemName="..." attribute rather than
                guessed.
            *}
            {assign var="hiddenSidebarPanelNames" value=['Client Details', 'Client Contacts', 'Client Shortcuts']}
            {foreach $primarySidebar as $sidebarItem}
                {if in_array($sidebarItem->getName(), $hiddenSidebarPanelNames)}
                    {assign var="primarySidebar" value=$primarySidebar->removeChild($sidebarItem->getName())}
                {/if}
            {/foreach}
            {if !$inShoppingCart && $primarySidebar->hasChildren()}
                {include file="$template/includes/sidebar-horizontal.tpl" sidebar=$primarySidebar}
            {/if}
