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
 * Namespinning call). If any one of those three never completes or
 * errors — in practice, usually the Namespinning suggestions call,
 * which depends on a separate external API WHMCS calls out to — the
 * counter never reaches 3 and the button stays disabled until the
 * whole page is reloaded. That root cause lives in WHMCS's own
 * bundled JS and the Namespinning service's own availability, neither
 * of which a theme can fix — worth checking Setup > General Settings
 * > Domains > domain suggestions in WHMCS admin if this keeps
 * happening. This just stops a visitor from getting stuck on it: a
 * short fallback timer force-clears the disabled state if WHMCS's own
 * logic hasn't already cleared it first.
 *
 * No-op anywhere this markup is absent — see
 * hostorio-store-cards.js's file header for why that matters on a
 * page this theme does not render itself.
 */
(function () {
    'use strict';

    // Longer than any legitimate search should take, short enough
    // that a visitor isn't left stuck for long if the stock counter
    // never reaches 3. If WHMCS's own script already re-enabled the
    // button by the time this fires, the disabled check below makes
    // it a no-op.
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

        btn.addEventListener('click', function () {
            window.setTimeout(function () {
                if (btn.disabled) {
                    btn.disabled = false;
                    btn.classList.remove('disabled');
                }
            }, STUCK_BUTTON_TIMEOUT_MS);
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
