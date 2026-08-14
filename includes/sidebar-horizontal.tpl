{*
    Horizontal counterpart to includes/sidebar.tpl.

    Renders the same $primarySidebar panel/item objects (View filters,
    Actions, etc. on Services/Domains/Invoices/Tickets) as a row of
    pill buttons above the page content instead of a left-hand column.
    No PHP/core changes — same data, different markup.

    The "mobileSelect" <select> fallback from sidebar.tpl is dropped:
    below 992px this bar scrolls horizontally instead of collapsing
    into a dropdown.
*}
{foreach $sidebar as $item}
    <div menuItemName="{$item->getName()}" class="ho-filterbar{if $item->getClass()} {$item->getClass()}{else} panel-sidebar{/if}"{if $item->getAttribute('id')} id="{$item->getAttribute('id')}"{/if}>
        <span class="ho-filterbar-label">
            {if $item->hasIcon()}<i class="{$item->getIcon()}"></i>&nbsp;{/if}
            {$item->getLabel()}
            {if $item->hasBadge()}&nbsp;<span class="badge">{$item->getBadge()}</span>{/if}
        </span>

        {if $item->hasBodyHtml()}
            <div class="ho-filterbar-body">
                {$item->getBodyHtml()}
            </div>
        {/if}

        {if $item->hasChildren()}
            <div class="ho-filterbar-items{if $item->getChildrenAttribute('class')} {$item->getChildrenAttribute('class')}{/if}">
                {foreach $item->getChildren() as $childItem}
                    {if $childItem->getUri()}
                        <a menuItemName="{$childItem->getName()}"
                           href="{$childItem->getUri()}"
                           class="ho-filterbar-item{if $childItem->isDisabled()} disabled{/if}{if $childItem->getClass()} {$childItem->getClass()}{/if}{if $childItem->isCurrent()} active{/if}"
                           {if $childItem->getAttribute('dataToggleTab')}
                               data-toggle="tab"
                           {/if}
                           {assign "customActionData" $childItem->getAttribute('dataCustomAction')}
                           {if is_array($customActionData)}
                               data-active="{$customActionData['active']}"
                               data-identifier="{$customActionData['identifier']}"
                               data-serviceid="{$customActionData['serviceid']}"
                           {/if}
                           {if $childItem->getAttribute('target')}
                               target="{$childItem->getAttribute('target')}"
                           {/if}
                           id="{$childItem->getId()}"
                        >
                            {if $childItem->hasIcon()}<i class="{$childItem->getIcon()} ho-filterbar-item-icon"></i>{/if}
                            {$childItem->getLabel()}
                            {if $childItem->hasBadge()}<span class="badge">{$childItem->getBadge()}</span>{/if}
                            {if is_array($customActionData)}<span class="loading" style="display: none;"><i class="fas fa-spinner fa-spin"></i></span>{/if}
                        </a>
                    {else}
                        <div menuItemName="{$childItem->getName()}" class="ho-filterbar-item{if $childItem->getClass()} {$childItem->getClass()}{/if}" id="{$childItem->getId()}">
                            {if $childItem->hasIcon()}<i class="{$childItem->getIcon()}"></i>&nbsp;{/if}
                            {$childItem->getLabel()}
                            {if $childItem->hasBadge()}<span class="badge">{$childItem->getBadge()}</span>{/if}
                        </div>
                    {/if}
                {/foreach}
            </div>
        {/if}

        {if $item->hasFooterHtml()}
            <div class="ho-filterbar-footer">
                {$item->getFooterHtml()}
            </div>
        {/if}
    </div>
{/foreach}
