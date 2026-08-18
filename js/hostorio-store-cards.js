/**
 * Hostorio — product cards on the order form's category pages
 *
 * Runs on /store/<category> and cart.php?gid=N, which render through
 * WHMCS's Order Form Template (templates/orderforms/standard_cart/),
 * NOT through this theme. Confirmed from that page's own rendered
 * HTML: the wrapper is #order-standard_cart and each card is
 * .product > header / .product-desc / footer.
 *
 * Two things CSS alone cannot do to that markup, both needed to match
 * the pricing cards on hostorio.com:
 *
 * 1. FEATURE LIST. The description is one <p> of plain text separated
 *    by <br> — "5GB NVMe Storage<br>1 Domain<br>...". There is no
 *    per-line element for a tick to attach to, so no selector can
 *    reach an individual feature. Rebuilt here as a real <ul>, one
 *    <li> per line, each with its own tick.
 *
 * 2. FOUR ACROSS. WHMCS emits products two per row —
 *    .row.row-eq-height > .col-md-6, a fresh .row every two products
 *    — so the break after every second card is in the markup, not the
 *    CSS. Widening the columns cannot fix it: the third card starts a
 *    new row regardless, and narrower columns would just leave the
 *    row half empty. Every .product is moved into one grid container
 *    instead, and the emptied rows removed, so a single CSS grid
 *    controls the count at every width.
 *
 * Line text is written with textContent, never innerHTML, so a
 * product description containing markup cannot inject it here.
 *
 * Defensive throughout: every step is guarded and the whole thing sits
 * in try/catch. If any assumption about this markup is wrong the page
 * is left exactly as WHMCS rendered it, which is a working page —
 * the same failure posture as hooks/services-menu-categories.php,
 * for the same reason: this markup belongs to a template set outside
 * this repo and can change under a WHMCS upgrade without warning.
 */
(function () {
    'use strict';

    function buildFeatureList(product) {
        var desc = product.querySelector('.product-desc p[id$="-description"]');
        if (!desc || desc.dataset.hoFeaturesBuilt === '1') {
            return;
        }

        // Split on <br> in any of its forms. Working from innerHTML is
        // what makes the line breaks visible at all — textContent
        // collapses them and the individual features become
        // unrecoverable.
        var lines = desc.innerHTML
            .split(/<br\s*\/?>/i)
            .map(function (line) {
                // Strip any tags the line itself carried, then let the
                // browser resolve entities by round-tripping through a
                // detached element's textContent.
                var tmp = document.createElement('div');
                tmp.innerHTML = line;
                return (tmp.textContent || '').trim();
            })
            .filter(function (line) {
                return line.length > 0;
            });

        if (!lines.length) {
            return;
        }

        var list = document.createElement('ul');
        list.className = 'ho-product-features';

        lines.forEach(function (line) {
            var li = document.createElement('li');

            var icon = document.createElement('i');
            icon.className = 'fas fa-check ho-product-feature-check';
            icon.setAttribute('aria-hidden', 'true');

            var text = document.createElement('span');
            text.textContent = line;

            li.appendChild(icon);
            li.appendChild(text);
            list.appendChild(li);
        });

        desc.parentNode.replaceChild(list, desc);
        list.dataset.hoFeaturesBuilt = '1';
    }

    /**
     * Moves the price block from inside <footer> to directly after
     * <header>, so a card reads name -> price -> features -> button,
     * as on hostorio.com. Stock leaves it in the footer BELOW the
     * feature list, which puts the one number a customer compares
     * across cards at the bottom of each one.
     *
     * Done here rather than with CSS `order` because .product-pricing
     * is a child of <footer>, not of .product — ordering it only
     * moves it within the footer, which it already leads.
     *
     * Also tags the card with .ho-product-card. The order form's own
     * stylesheet loads after this theme's and may scope its rules by
     * the same #order-standard_cart id, which would tie on
     * specificity and win on source order; the extra class gives this
     * theme's rules a class more to sit on without inventing a
     * selector for markup that is not ours.
     */
    function liftPricing(product) {
        product.classList.add('ho-product-card');

        var pricing = product.querySelector('.product-pricing');
        var header = product.querySelector('header');
        if (!pricing || !header || pricing.dataset.hoLifted === '1') {
            return;
        }

        header.parentNode.insertBefore(pricing, header.nextSibling);
        pricing.dataset.hoLifted = '1';
    }

    function reflowIntoGrid(root) {
        var container = root.querySelector('#products');
        if (!container || container.dataset.hoGridBuilt === '1') {
            return;
        }

        var products = container.querySelectorAll('.product');
        if (products.length < 2) {
            // One product needs no grid, and zero means the category is
            // empty — leave WHMCS's own markup (and its empty-state) be.
            return;
        }

        var grid = document.createElement('div');
        grid.className = 'ho-product-grid';

        Array.prototype.forEach.call(products, function (product) {
            grid.appendChild(product);
        });

        // Every .product has been moved out, so what remains is the now
        // empty .row / .col-* scaffolding. Cleared rather than left in
        // place: empty Bootstrap rows still carry margins and would
        // print a gap under the grid.
        container.innerHTML = '';
        container.appendChild(grid);
        container.dataset.hoGridBuilt = '1';
    }

    function init() {
        var root = document.getElementById('order-standard_cart');
        if (!root) {
            return;
        }

        try {
            Array.prototype.forEach.call(
                root.querySelectorAll('.product'),
                function (product) {
                    buildFeatureList(product);
                    liftPricing(product);
                }
            );
            reflowIntoGrid(root);
        } catch (e) {
            // Deliberately swallowed — see the file header. A thrown
            // error here would leave the page half-transformed, which
            // is worse than leaving it stock.
        }
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
}());
