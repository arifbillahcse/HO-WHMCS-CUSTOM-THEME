{include file="$template/includes/flashmessage.tpl"}

{include file="$template/includes/ai-search.tpl"}

<div class="tiles clearfix">
    <div class="row">
        <div class="col-sm-3 col-xs-6 tile" onclick="window.location='clientarea.php?action=services'">
            <a href="clientarea.php?action=services">
                <div class="icon"><i class="fas fa-cube"></i></div>
                <div class="stat">{$clientsstats.productsnumactive}</div>
                <div class="title">{$LANG.navservices}</div>
                <div class="highlight bg-color-blue"></div>
            </a>
        </div>
        {if $clientsstats.numdomains || $registerdomainenabled || $transferdomainenabled}
            <div class="col-sm-3 col-xs-6 tile" onclick="window.location='clientarea.php?action=domains'">
                <a href="clientarea.php?action=domains">
                    <div class="icon"><i class="fas fa-globe"></i></div>
                    <div class="stat">{$clientsstats.numactivedomains}</div>
                    <div class="title">{$LANG.navdomains}</div>
                    <div class="highlight bg-color-green"></div>
                </a>
            </div>
        {elseif $condlinks.affiliates && $clientsstats.isAffiliate}
            <div class="col-sm-3 col-xs-6 tile" onclick="window.location='affiliates.php'">
                <a href="affiliates.php">
                    <div class="icon"><i class="fas fa-shopping-cart"></i></div>
                    <div class="stat">{$clientsstats.numaffiliatesignups}</div>
                    <div class="title">{$LANG.affiliatessignups}</div>
                    <div class="highlight bg-color-green"></div>
                </a>
            </div>
        {else}
            <div class="col-sm-3 col-xs-6 tile" onclick="window.location='clientarea.php?action=quotes'">
                <a href="clientarea.php?action=quotes">
                    <div class="icon"><i class="far fa-file-alt"></i></div>
                    <div class="stat">{$clientsstats.numquotes}</div>
                    <div class="title">{$LANG.quotes}</div>
                    <div class="highlight bg-color-green"></div>
                </a>
            </div>
        {/if}
        <div class="col-sm-3 col-xs-6 tile" onclick="window.location='supporttickets.php'">
            <a href="supporttickets.php">
                <div class="icon"><i class="fas fa-comments"></i></div>
                <div class="stat">{$clientsstats.numactivetickets}</div>
                <div class="title">{$LANG.navtickets}</div>
                <div class="highlight bg-color-red"></div>
            </a>
        </div>
        <div class="col-sm-3 col-xs-6 tile" onclick="window.location='clientarea.php?action=invoices'">
            <a href="clientarea.php?action=invoices">
                <div class="icon"><i class="fas fa-credit-card"></i></div>
                <div class="stat">{$clientsstats.numunpaidinvoices}</div>
                <div class="title">{$LANG.navinvoices}</div>
                <div class="highlight bg-color-gold"></div>
            </a>
        </div>
    </div>
</div>

{*
    The stock knowledgebase search box stood here. The AI box above
    covers the same ground and a second search field directly under it
    only competes for the same intent, so it is retired — its link
    lives in that box's footer instead. To bring it back, restore:

    <form role="form" method="post" action="clientarea.php?action=kbsearch">
        <div class="row">
            <div class="col-md-12 home-kb-search">
                <input type="text" name="search" class="form-control input-lg" placeholder="{$LANG.clientHomeSearchKb}" />
                <i class="fas fa-search"></i>
            </div>
        </div>
    </form>
*}

{foreach from=$addons_html item=addon_html}
    <div>
        {$addon_html}
    </div>
{/foreach}

{if $captchaError}
    <div class="alert alert-danger">
        {$captchaError}
    </div>
{/if}

{*
    Panels WHMCS puts on this page that we do not want.

    These are not markup anywhere in the theme — WHMCS builds them as
    menu items and hands them over in $panels — so they cannot be
    deleted, only dropped from the menu before it is rendered. Doing it
    here rather than in an includes/hooks/ PHP file keeps the change
    inside the template set.

    Matched by getLabel() — the heading printed on screen — rather
    than by getName(). getName() is an internal identifier that is
    not documented and is not the string this page displays, so a
    list of guessed getName() values silently matched nothing on a
    real install and every panel below kept rendering.

    Even matching the label exactly was not enough: 'Recent News' and
    'Shortcuts' were removed, but 'Your Info' and 'Contacts' were not,
    on a real install. That split proves getLabel() does hold the
    visible text — it rules out a systemic bug — so the remaining
    difference is almost certainly casing or singular/plural wording
    ('Contact' vs 'Contacts') too small to see in a screenshot but
    enough to break a byte-for-byte match.

    |lower folds case on both sides before comparing. It is a genuine
    compiled-in Smarty modifier (libs/plugins/modifiercompiler.lower.php
    ships with Smarty itself), so it runs regardless of what WHMCS's
    Smarty security policy on this install allows or forbids. |trim is
    not: this Smarty version has no such built-in, so it silently falls
    back to calling PHP's trim() as an unregistered function — exactly
    the kind of call a security policy exists to block. No other
    template in this theme calls trim(), lower-cases, or any other raw
    function inside a real Smarty tag (only inside plain-PHP .tpl files
    like invoicepdf.tpl, which Smarty's policy never sees), so there is
    no evidence it is permitted here — using it risked trading two
    stubborn panels for a page that errors outright. Singular and
    plural forms are listed explicitly instead, which needs nothing
    beyond in_array().

    If a label still gets through after this, the remaining gap is
    wording, not case or plural — copy the heading text directly from
    the rendered page (view source, not a screenshot) and add that
    exact string, lowercased, below.
*}
{assign var="hiddenPanelLabels" value=['your info', 'recent news', 'contacts', 'contact', 'shortcuts', 'shortcut']}
{foreach $panels as $item}
    {if in_array($item->getLabel()|lower, $hiddenPanelLabels)}
        {assign var="panels" value=$panels->removeChild($item->getName())}
    {/if}
{/foreach}

<div class="client-home-panels">
    <div class="row">
        <div class="col-sm-12">

            {function name=outputHomePanels}
                <div menuItemName="{$item->getName()}" class="panel panel-default panel-accent-{$item->getExtra('color')}{if $item->getClass()} {$item->getClass()}{/if}"{if $item->getAttribute('id')} id="{$item->getAttribute('id')}"{/if}>
                    <div class="panel-heading">
                        <h3 class="panel-title">
                            {if $item->getExtra('btn-link') && $item->getExtra('btn-text')}
                                <div class="pull-right">
                                    <a href="{$item->getExtra('btn-link')}" class="btn btn-default bg-color-{$item->getExtra('color')} btn-xs">
                                        {if $item->getExtra('btn-icon')}<i class="{$item->getExtra('btn-icon')}"></i>{/if}
                                        {$item->getExtra('btn-text')}
                                    </a>
                                </div>
                            {/if}
                            {if $item->hasIcon()}<i class="{$item->getIcon()}"></i>&nbsp;{/if}
                            {$item->getLabel()}
                            {if $item->hasBadge()}&nbsp;<span class="badge">{$item->getBadge()}</span>{/if}
                        </h3>
                    </div>
                    {if $item->hasBodyHtml()}
                        <div class="panel-body">
                            {$item->getBodyHtml()}
                        </div>
                    {/if}
                    {if $item->hasChildren()}
                        <div class="list-group{if $item->getChildrenAttribute('class')} {$item->getChildrenAttribute('class')}{/if}">
                            {foreach $item->getChildren() as $childItem}
                                {if $childItem->getUri()}
                                    <a menuItemName="{$childItem->getName()}" href="{$childItem->getUri()}" class="list-group-item{if $childItem->getClass()} {$childItem->getClass()}{/if}{if $childItem->isCurrent()} active{/if}"{if $childItem->getAttribute('dataToggleTab')} data-toggle="tab"{/if}{if $childItem->getAttribute('target')} target="{$childItem->getAttribute('target')}"{/if} id="{$childItem->getId()}">
                                        {if $childItem->hasIcon()}<i class="{$childItem->getIcon()}"></i>&nbsp;{/if}
                                        {$childItem->getLabel()}
                                        {if $childItem->hasBadge()}&nbsp;<span class="badge">{$childItem->getBadge()}</span>{/if}
                                    </a>
                                {else}
                                    <div menuItemName="{$childItem->getName()}" class="list-group-item{if $childItem->getClass()} {$childItem->getClass()}{/if}" id="{$childItem->getId()}">
                                        {if $childItem->hasIcon()}<i class="{$childItem->getIcon()}"></i>&nbsp;{/if}
                                        {$childItem->getLabel()}
                                        {if $childItem->hasBadge()}&nbsp;<span class="badge">{$childItem->getBadge()}</span>{/if}
                                    </div>
                                {/if}
                            {/foreach}
                        </div>
                    {/if}
                    <div class="panel-footer">
                        {if $item->hasFooterHtml()}
                            {$item->getFooterHtml()}
                        {/if}
                    </div>
                </div>
            {/function}

            {foreach $panels as $item}
                {if $item->getExtra('colspan')}
                    {outputHomePanels}
                    {assign "panels" $panels->removeChild($item->getName())}
                {/if}
            {/foreach}

        </div>
        <div class="col-sm-6">

            {foreach $panels as $item}
                {if $item@iteration is odd}
                    {outputHomePanels}
                {/if}
            {/foreach}

        </div>
        <div class="col-sm-6">

            {foreach $panels as $item}
                {if $item@iteration is even}
                    {outputHomePanels}
                {/if}
            {/foreach}

        </div>
    </div>
</div>
