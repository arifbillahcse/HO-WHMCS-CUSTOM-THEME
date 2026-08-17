<section class="pricing-section {if $elementIndex % 2 == 0}background-light{else}background-main{/if}" role="region"
         aria-labelledby="pricing-title-{$smarty.foreach.blocks.index}">
    <div class="pricing-container">
        {if $config->title}
            <h2 class="pricing-title" id="pricing-title-{$smarty.foreach.blocks.index}">
                {$config->title}
            </h2>
        {/if}

        {if $config->subtitle}
            <p class="pricing-subtitle">
                {$config->subtitle}
            </p>
        {/if}
        {if $hasPlan}
        <div class="pricing-grid">
            {*
                "Most Popular" ribbon, plan icon and the tagline-above-price
                order below are Hostorio changes to this stock partial, to
                match the pricing cards on hostorio.com. Styling lives in
                store/dynamic/assets/hostorio-store.css (this theme's own
                file), not in dynamic-store.css, which is WHMCS's and gets
                replaced on upgrade.

                The ribbon is driven by a FEATURE KEY, not by a WHMCS API:
                give one plan a feature named "Most Popular" in the Dynamic
                Store page builder (any value) and that card gets the
                ribbon. The key is then skipped when the feature list is
                rendered, so it never shows up as a bullet.

                Deliberately a naming convention rather than a property on
                $service or $plan: $service is admin-supplied page config
                whose full shape is not documented, and $plan is a WHMCS
                object that ships ionCube-encoded and cannot be inspected
                from this repo. Every other guess at an undocumented WHMCS
                API in this project failed silently and cost a deploy cycle
                to find. A feature key is data this template already
                iterates and is therefore certain to exist.
            *}
            {foreach $config->services as $service}
                {$plan = $products[$service['slug']]}
                {if !$plan}{continue}{/if}

                {$isMostPopular = false}
                {foreach $service['features'] as $feature => $value}
                    {if $feature|lower == 'most popular'}
                        {$isMostPopular = true}
                    {/if}
                {/foreach}

                <div class="pricing-card{if $isMostPopular} pricing-card-featured{/if}">
                    {if $isMostPopular}
                        <div class="pricing-ribbon">{$config->ribbonLabel|default:'Most Popular'}</div>
                    {/if}

                    <div class="pricing-header">
                        {* One icon for every plan, matching hostorio.com,
                           which uses the same glyph on all four cards.
                           WHMCS has no per-product icon field to read. *}
                        <div class="plan-icon" aria-hidden="true">
                            <i class="fas fa-server"></i>
                        </div>

                        <h3 class="plan-name">{$plan.name}</h3>

                        {if $plan.description}
                            <p class="plan-description">{$plan.description}</p>
                        {/if}

                        <div class="plan-price">
                                <span class="price-amount">
                                {if $plan->isFree()}
                                    {lang key="orderpaymenttermfree"}
                                {else}
                                    {$plan->pricing()->first()->toPrefixedString()}
                                {/if}
                                </span>
                        </div>
                    </div>

                    <ul class="plan-features">
                        {foreach $service['features'] as $feature => $value}
                            {if $feature|lower == 'most popular'}{continue}{/if}
                            {*
                                Icon first, then the text — hostorio.com
                                lists every feature as a tick followed by a
                                phrase. Stock put the label first and the
                                tick after it, which also meant a boolean
                                feature rendered as "Free SSL Certificate:"
                                with a dangling colon before the tick. A
                                boolean now renders as its name alone, so
                                entering features as name => true in the
                                page builder reproduces the marketing site
                                exactly; the name: value form is kept for
                                features that carry a value.
                            *}
                            <li class="feature-item">
                                {if is_bool($value) && $value === false}
                                    <i class="fas fa-times feature-cross" aria-hidden="true"></i>
                                {else}
                                    <i class="fas fa-check feature-check" aria-hidden="true"></i>
                                {/if}
                                {if is_bool($value)}
                                    <span>{$feature}</span>
                                {else}
                                    <span>{$feature}: <b>{$value}</b></span>
                                {/if}
                            </li>
                        {/foreach}
                    </ul>

                    <div class="plan-action">
                        <form method="post" action="{routePath('cart-order')}">
                            <input type="hidden" name="checkout" value="1">
                            <input type="hidden" name="pid" value="{$plan.id}">
                            <button class="plan-button">{lang key='store.getstarted'}</button>
                        </form>
                    </div>
                </div>
            {/foreach}
            {else}
            <div class="service-link">
                <a href="{$WEB_ROOT}/contact.php" class="btn btn-info">
                    {lang key="learnmore"}
                </a>
            </div>
        </div>
        {/if}
    </div>
</section>
