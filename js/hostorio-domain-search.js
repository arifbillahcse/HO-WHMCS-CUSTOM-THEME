/**
 * Hostorio — domain search box on the Register Domain page
 *
 * That box (#order-standard_cart .domain-checker-bg) is WHMCS's own
 * stock domainchecker.tpl output, not a template in this theme, so
 * there is no .tpl to add a class to. Tags its elements with
 * theme-owned classes on load so hostorio-layout.css can style them
 * directly instead of leaning on WHMCS's own ids/classes (stable so
 * far, but not ours, and not guaranteed to survive a WHMCS update).
 *
 * Also works around a stock behaviour, not a bug introduced here:
 * templates/orderforms/standard_cart/js/scripts.min.js disables
 * #btnCheckAvailability the moment a search starts, and only
 * re-enables it once a counter (domainLookupCallCount) reaches
 * exactly 3 — one tick per lookup it kicks off alongside the main
 * search (the spotlight TLDs, and the "Suggested Domains" /
 * Namespinning call). Confirmed against the stock WHMCS theme too
 * (same behaviour there, so it isn't this theme's doing) and against
 * a live search: the primary result (the actual availability/price
 * the button exists for) renders almost immediately — it's
 * specifically the Namespinning suggestions call that runs slow,
 * sometimes for a long time, and the button sits disabled for all of
 * it even though the search it was clicked for already has an answer
 * on screen. That slowness is on WHMCS's/Namespinning's side, not
 * fixable from here — worth checking Setup > General Settings >
 * Domains > domain suggestions in WHMCS admin if it's consistently
 * this slow.
 *
 * Rather than just waiting it out, this re-enables the button the
 * moment the primary result (#primaryLookupResult) actually appears,
 * via a MutationObserver on its class attribute — independent of
 * whether or how long the slower suggestions call beside it takes. A
 * flat timeout stays as a last-resort safety net in case that element
 * is ever renamed in a WHMCS update.
 *
 * No-op anywhere this markup is absent — see
 * hostorio-store-cards.js's file header for why that matters on a
 * page this theme does not render itself.
 */
(function () {
    'use strict';

    // Last-resort only — the MutationObserver below is what normally
    // clears this, almost as soon as the real result is on screen.
    // This just guards against that element ever being renamed in a
    // future WHMCS update, so a visitor is never stuck longer than
    // this regardless.
    var STUCK_BUTTON_TIMEOUT_MS = 12000;

    function tag(el, className) {
        if (el) {
            el.classList.add(className);
        }
    }

    function initSearchButtonFallback(btn) {
        if (!btn) {
            return;
        }

        function clearDisabled() {
            if (btn.disabled) {
                btn.disabled = false;
                btn.classList.remove('disabled');
            }
        }

        // #primaryLookupResult starts hidden (class "w-hidden") and
        // WHMCS's own script drops that class once the real
        // availability/price result is ready — the signal this reuses
        // rather than waiting on the slower, unrelated suggestions
        // call the button has no real reason to depend on.
        var primaryResult = document.getElementById('primaryLookupResult');
        if (primaryResult && window.MutationObserver) {
            new MutationObserver(function () {
                if (!primaryResult.classList.contains('w-hidden')) {
                    clearDisabled();
                }
            }).observe(primaryResult, { attributes: true, attributeFilter: ['class'] });
        }

        btn.addEventListener('click', function () {
            window.setTimeout(clearDisabled, STUCK_BUTTON_TIMEOUT_MS);
        });
    }

    function init() {
        var root = document.getElementById('order-standard_cart');
        if (!root) {
            return;
        }

        try {
            tag(root.querySelector('.domain-checker-bg'), 'ho-domain-search');
            tag(root.querySelector('.domain-checker-bg .input-group-box'), 'ho-domain-search-bar');
            tag(root.querySelector('#inputDomain'), 'ho-domain-search-input');

            var searchBtn = root.querySelector('#btnCheckAvailability');
            tag(searchBtn, 'ho-domain-search-btn');
            initSearchButtonFallback(searchBtn);
        } catch (e) {
            // Swallowed deliberately — see the file header.
        }
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
}());
