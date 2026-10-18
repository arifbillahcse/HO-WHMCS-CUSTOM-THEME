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
 * No-op anywhere this markup is absent — see
 * hostorio-store-cards.js's file header for why that matters on a
 * page this theme does not render itself.
 */
(function () {
    'use strict';

    function tag(el, className) {
        if (el) {
            el.classList.add(className);
        }
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
            tag(root.querySelector('#btnCheckAvailability'), 'ho-domain-search-btn');
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
