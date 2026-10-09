/**
 * Hostorio — merge Review (cart.php?a=view) into Checkout (a=checkout)
 *
 * Deliberately narrower than the earlier one-page-checkout attempt
 * (reverted): this touches only the review and payment steps, never
 * domain choice or configuration — the two pages where that attempt's
 * real failure (a WHMCS\Exception\InvalidDomain fatal error) actually
 * happened. Nothing here submits a domain, configures an addon, or
 * constructs any POST body at all. It only (a) skips the read-only
 * review page via a plain navigation, and (b) clones read-only content
 * from it onto the checkout page. The actual "Complete Order" form —
 * payment method, ToS, submit — stays exactly WHMCS's own, untouched.
 *
 * Two independent pieces, each gated on real DOM ids/classes
 * confirmed from this site's own rendered HTML (not guessed):
 *
 * 1. On a=view: redirect straight to a=checkout. Confirmed real
 *    markers for this page: .view-cart-items (the Product/Options
 *    table) and .order-summary (the pricing sidebar).
 *
 * 2. On a=checkout (confirmed real marker: #frmCheckout, the actual
 *    payment form): clone those same two fragments in from a=view,
 *    inserted above the untouched payment form.
 *
 *    .order-summary's actual numbers are filled in by WHMCS's own JS
 *    after the page loads (confirmed in the earlier attempt — a plain
 *    fetch() only ever sees an empty shell), so this loads a=view in
 *    a hidden iframe, which actually runs that JS, and waits for
 *    #totalCartPrice to have a real value before cloning anything out
 *    of it. Capped at ~6s, after which it falls back to a plain
 *    message rather than leaving the customer looking at nothing.
 */
(function () {
    'use strict';

    function isViewUrl() {
        return /[?&]a=view(&|$)/.test(window.location.search);
    }

    function skipReviewPage() {
        var root = document.getElementById('order-standard_cart');
        if (!root) {
            return;
        }
        if (!isViewUrl()) {
            return;
        }
        var hasReviewMarkers = document.querySelector('.view-cart-items') || document.querySelector('.order-summary');
        if (!hasReviewMarkers) {
            return;
        }
        window.location.replace('cart.php?a=checkout');
    }

    function injectReviewIntoCheckout() {
        var checkoutForm = document.getElementById('frmCheckout');
        if (!checkoutForm) {
            return;
        }
        if (document.getElementById('hoReviewPanel')) {
            return; // already run once on this page
        }

        var panel = document.createElement('div');
        panel.id = 'hoReviewPanel';
        panel.className = 'ho-review-panel';
        panel.innerHTML = '<div class="ho-review-loading">Loading your order…</div>';
        checkoutForm.parentNode.insertBefore(panel, checkoutForm);

        var iframe = document.createElement('iframe');
        iframe.style.display = 'none';
        iframe.setAttribute('aria-hidden', 'true');
        iframe.setAttribute('title', 'Order review (loading)');
        document.body.appendChild(iframe);

        var attempts = 0;
        var maxAttempts = 40; // ~6s at 150ms

        function render(doc) {
            panel.innerHTML = '';
            var items = doc && doc.querySelector('.view-cart-items');
            var summary = doc && doc.querySelector('.order-summary');

            if (items) {
                panel.appendChild(items.cloneNode(true));
            }
            if (summary) {
                panel.appendChild(summary.cloneNode(true));
            }
            if (!items && !summary) {
                panel.innerHTML = '<p>Your order details will show on your receipt after payment.</p>';
            }
        }

        function poll() {
            attempts++;
            var doc = null;
            try {
                doc = iframe.contentDocument;
            } catch (e) {
                doc = null;
            }
            var totalEl = doc && doc.getElementById('totalCartPrice');
            if ((totalEl && totalEl.textContent.trim()) || attempts >= maxAttempts) {
                render(doc);
                iframe.parentNode.removeChild(iframe);
                return;
            }
            setTimeout(poll, 150);
        }

        iframe.addEventListener('load', function () {
            poll();
        }, { once: true });

        iframe.src = 'cart.php?a=view';
    }

    function init() {
        // Critical: this exact page (including this script) is what
        // gets loaded inside injectReviewIntoCheckout's own hidden
        // iframe. Without this guard, that iframe's copy of the script
        // runs too: sees a=view, redirects itself to a=checkout, whose
        // copy of the script then creates ANOTHER hidden iframe loading
        // a=view, which redirects itself again — unbounded recursive
        // iframes. Confirmed live: dozens of repeated cart.php?a=view
        // requests and browser "unload not allowed" violations were
        // exactly this loop running until the outer poll's timeout cut
        // it off, which is also why the review content never actually
        // rendered (the inner iframe kept navigating itself away from
        // a=view before anything could be read from it).
        if (window.self !== window.top) {
            return;
        }

        try {
            skipReviewPage();
        } catch (e) {
            // leave the native review page to render as-is
        }
        try {
            injectReviewIntoCheckout();
        } catch (e) {
            var panel = document.getElementById('hoReviewPanel');
            if (panel) {
                panel.remove();
            }
        }
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
}());
