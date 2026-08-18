{*
    Domain pricing — the featured-TLD cards, category filter and price
    table under the search box on the Register Domain page.

    The search box itself is NOT here: that is WHMCS's own
    domainchecker.tpl, which this theme does not override, which is why
    it still renders as a stock blue gradient banner. This file covers
    everything below it.

    Redesigned from the stock layout, which had each featured TLD's
    price sitting in a full-width colour bar keyed to the TLD name
    (.price.com blue, .price.shop orange, .price.net yellow, ... in
    styles.css). That palette is Twenty-One's, not Hostorio's, and it
    put a different accent colour on every card, so the row read as
    unrelated tiles rather than one set of options. Markup here keeps
    the same .featured-tld / .price structure WHMCS's own data fills,
    plus .ho-tld-card hooks for the restyle in hostorio-layout.css —
    the stock classes stay so nothing that depends on them breaks.
*}
<div class="domain-pricing ho-domain-pricing">

    {if $featuredTlds}
        <div class="featured-tlds-container ho-tld-grid">
            {foreach $featuredTlds as $num => $tldinfo}
                <div class="featured-tld ho-tld-card">
                    <div class="img-container ho-tld-card-logo">
                        <img src="{$BASE_PATH_IMG}/tld_logos/{$tldinfo.tldNoDots}.png" alt="{$tldinfo.tld}">
                    </div>
                    <div class="price {$tldinfo.tldNoDots} ho-tld-card-price">
                        {if is_object($tldinfo.register)}
                            {$tldinfo.register->toPrefixed()}{if $tldinfo.period > 1}{lang key="orderForm.shortPerYears" years={$tldinfo.period}}{else}{lang key="orderForm.shortPerYear" years=''}{/if}
                        {else}
                            {lang key="domainregnotavailable"}
                        {/if}
                    </div>
                </div>
            {/foreach}
        </div>
    {/if}

    <div class="ho-tld-toolbar">
        <h4 class="ho-tld-toolbar-title">{lang key='pricing.browseExtByCategory'}</h4>

        {if !$loggedin && $currencies}
            <form method="post" action="" class="ho-tld-currency">
                <select name="currency" class="form-control currency-selector" onchange="submit()">
                    <option>
                        {lang key="changeCurrency"} ({$activeCurrency.prefix} {$activeCurrency.code})
                    </option>
                    {foreach $currencies as $currency}
                        <option value="{$currency['id']}">
                            {$currency['prefix']} {$currency['code']}
                        </option>
                    {/foreach}
                </select>
            </form>
        {/if}
    </div>

    <div class="tld-filters ho-tld-filters">
        {foreach $tldCategories as $category => $count}
            <a href="#" data-category="{$category}" class="label label-default">{lang key="domainTldCategory.$category" defaultValue=$category} <span class="ho-tld-filter-count">{$count}</span></a>
        {/foreach}
    </div>

    {include file="$template/includes/tablelist.tpl" tableName="DomainPricing" noOrdering=true}
    <script type="text/javascript">
        jQuery(document).ready(function(){
            var table = jQuery('#tableDomainPricing').removeClass('hidden').DataTable();
            {if $orderby == 'date'}
                table.order(0, '{$sort}');
            {elseif $orderby == 'subject'}
                table.order(1, '{$sort}');
            {/if}
            table.draw();
            jQuery('#tableLoading').addClass('hidden');
            jQuery('.tld-filters a').unbind();
            jQuery('.tld-filters a').click(function(e) {
                e.preventDefault();
                if (jQuery(this).hasClass('label-success')) {
                    jQuery('#tableDomainPricing_wrapper input[type="search"]').val('').trigger('keyup');
                    jQuery('.tld-filters a').removeClass('label-success');
                } else {
                    jQuery('#tableDomainPricing_wrapper input[type="search"]').val(jQuery(this).data('category')).trigger('keyup');
                    jQuery('.tld-filters a').removeClass('label-success');
                    jQuery(this).addClass('label-success');
                }
            });
        });
    </script>

    {*
        Grace and redemption period columns are dropped from the table.
        They are registry-recovery windows that matter only once a
        domain has already expired — on a page whose job is choosing a
        TLD to buy, they added two columns of mostly "-" and pushed the
        three prices someone is actually comparing into a narrower
        measure. They remain visible on the domain's own management
        page, where an expiring domain is the subject.

        Seven columns down to five also leaves the remaining ones more
        room on a narrow screen. It does NOT necessarily mean all five
        fit a phone unaided — includes/tablelist.tpl runs DataTables
        with responsive: true, so that plugin still decides what to
        collapse, and it cannot be exercised in a static harness. The
        column indices the sort script above keys off (0 and 1) are
        unaffected, since only the last two columns were removed.
    *}
    <div class="table-container clearfix">
        <table class="table table-list hidden ho-tld-table" id="tableDomainPricing">
            <thead>
            <tr>
                <th>{lang key='domaintld'}</th>
                <th>{lang key='category'}</th>
                <th>{lang key='pricing.register'}</th>
                <th>{lang key='pricing.transfer'}</th>
                <th>{lang key='pricing.renewal'}</th>
            </tr>
            </thead>
            <tbody>
            {foreach $pricing as $extension => $data}
                <tr>
                    <td class="ho-tld-cell">
                        <span class="ho-tld-name">{$extension}</span>
                        {if $data.group}
                            <span class="tld-sale-group tld-sale-group-{$data.group}">
                                {$data.group}!
                            </span>
                        {/if}
                    </td>
                    <td>
                        {$data.categories[0]}
                        <span class="hidden">
                            {foreach $data.categories as $category}
                                {$category}
                            {/foreach}
                        </span>
                    </td>
                    {foreach $data.register as $years => $price}
                        <td>
                            {if $price >= 0}
                                <span class="ho-tld-price">{$price}</span>
                                <small class="ho-tld-term">{$years} {if $years > 1}{lang key="orderForm.years"}{else}{lang key="orderForm.year"}{/if}</small>
                            {else}
                                <small class="ho-tld-unavailable">{lang key="domainregnotavailable"}</small>
                            {/if}
                        </td>
                        {break}
                    {foreachelse}
                        <td>-</td>
                    {/foreach}
                    {foreach $data.transfer as $years => $price}
                        <td>
                            {if $price >= 0}
                                <span class="ho-tld-price">{$price}</span>
                                <small class="ho-tld-term">{$years} {if $years > 1}{lang key="orderForm.years"}{else}{lang key="orderForm.year"}{/if}</small>
                            {else}
                                <small class="ho-tld-unavailable">{lang key="domainregnotavailable"}</small>
                            {/if}
                        </td>
                        {break}
                    {foreachelse}
                        <td>-</td>
                    {/foreach}
                    {foreach $data.renew as $years => $price}
                        <td>
                            {if $price >= 0}
                                <span class="ho-tld-price">{$price}</span>
                                <small class="ho-tld-term">{$years} {if $years > 1}{lang key="orderForm.years"}{else}{lang key="orderForm.year"}{/if}</small>
                            {else}
                                <small class="ho-tld-unavailable">{lang key="domainregnotavailable"}</small>
                            {/if}
                        </td>
                        {break}
                    {foreachelse}
                        <td>-</td>
                    {/foreach}
                </tr>
            {foreachelse}
                <tr>
                    <td colspan="5">{lang key="pricing.noExtensionsDefined"}</td>
                </tr>
            {/foreach}
            </tbody>
        </table>
        <div class="text-center" id="tableLoading">
            <p><i class="fas fa-spinner fa-spin"></i> {$LANG.loading}</p>
        </div>
    </div>

</div>
