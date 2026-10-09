/**
 * Hostorio — one-page checkout (domain + configure + review combined)
 *
 * Collapses three separate cart.php page loads — choose a domain
 * (a=add), configure it (a=confdomains), review the order (a=view) —
 * into one page, matching the "Idea B" mockup the user picked
 * (numbered step cards, running total pinned in a bar at the bottom).
 * Checkout itself (a=checkout, payment method + ToS + Complete Order)
 * is left as a completely untouched second page — the one part of
 * this flow that handles payment, and the one part this script never
 * touches.
 *
 * This is "Option A" from that discussion: WHMCS's own cart.php still
 * does every bit of real work (pricing, premium-domain detection, tax,
 * addon availability, promo codes) — this script only calls its real
 * endpoints in the background instead of letting the browser navigate
 * between them, then redraws the result. Nothing here recomputes a
 * price or re-validates a domain; it either shows what cart.php itself
 * returned, or shows nothing and lets the native page stand.
 *
 * CONFIRMED against real HAR captures of this exact site (both are
 * real requests this script reproduces byte-for-byte):
 *
 *   POST /index.php?rp=/domain/check
 *     token, type=domain, domain=<sld><tld>, sld, tld (leading dot),
 *     source=cartAddDomain
 *   -> {"result":[{ domainName, isAvailable, isRegistered, isPremium,
 *                    isValidDomain, domainErrorMessage, minLength,
 *                    maxLength, pricing:{"<period>":{register,...}},
 *                    premiumCostPricing, ... }]}
 *
 *   POST /cart.php?a=add&pid=<pid>&domainselect=1
 *     token, idnlanguage, domainoption=register,
 *     domains[]=<sld.tld>, domainsregperiod[<sld.tld>]=<period>
 *   -> 302 to a=confdomains (or straight to a=view if nothing on this
 *      product needs configuring — both seen live)
 *
 *   POST /cart.php?a=confdomains
 *     token, update=true, <whatever addon checkboxes were checked>
 *     (e.g. dnsmanagement[0]=on, idprotection[0]=on,
 *      emailforwarding[0]=on — confirmed, but THIS SCRIPT NEVER
 *      HARDCODES THOSE NAMES: see "Configure" below)
 *   -> 302 to a=view
 *
 * INFERRED, NOT CONFIRMED against a real capture (the test run that
 * produced the HARs only exercised "register a new domain" —
 * "own domain" and "transfer" were never actually submitted):
 *   - domainoption=owndomain and domainoption=transfer are confirmed
 *     as real radio VALUES on the live page (seen in rendered HTML:
 *     id="selowndomain", id="seltransfer"), but the full field set
 *     WHMCS expects alongside them (an eppcode[<domain>] field for
 *     transfer, in particular) is this script's best guess at WHMCS's
 *     documented convention, not something this site was seen to
 *     submit. Test the Transfer and Own-domain paths specifically
 *     before trusting them in production.
 *   - Custom nameservers: the real submission for these was never
 *     captured (the test run used default nameservers throughout).
 *     This script submits ns1/ns2 using the field-id convention
 *     already confirmed elsewhere in this theme's own CSS
 *     (input.form-control[id^="inputNs"]) — but field NAME on submit
 *     (as opposed to id) is inferred, not confirmed.
 *
 * Why addons and the order summary are CLONED rather than rebuilt:
 * hardcoding "dnsmanagement[0], idprotection[0], emailforwarding[0]"
 * would only work for the one product tested, and would silently
 * submit nothing for any product with a different addon set — a
 * customer's chosen addon quietly not being added to their order is
 * exactly the kind of invisible bug this project has flagged as the
 * real risk of this approach. Instead, this script takes the REAL
 * .addon-products fragment WHMCS already rendered (whatever checkboxes
 * it contains, for whatever product this is) and the REAL
 * .order-summary fragment, and reads/resubmits whatever is actually
 * inside them at the moment of submission. The appearance is
 * restyled; the fields and their validation stay entirely WHMCS's.
 *
 * Defensive throughout, same posture as hostorio-store-cards.js: this
 * page belongs to templates/orderforms/standard_cart/, not this repo,
 * and a WHMCS upgrade can change it without warning. Every lookup is
 * guarded; if a step's expected markup is not where assumed, this
 * script stops and leaves the rest of the native flow to render
 * normally rather than leaving the customer stuck on a half-built
 * custom page.
 */
(function () {
    'use strict';

    function init() {
        var root = document.getElementById('order-standard_cart');
        if (!root) {
            return;
        }

        // Real ids on this exact page, confirmed from its own rendered
        // HTML (not from the bundled JS's generic references, which
        // named a #frmDomainChecker this page never actually has —
        // that was the original bug: this script looked for an id
        // that simply isn't here, and exited before ever reaching the
        // DOM it should have built against).
        //
        //   #frmProductDomainPid        hidden input, value = pid
        //   #frmProductDomain           the radio choice + sld/tld
        //                               inputs (no action — its own
        //                               "Check"/"Transfer"/"Use"
        //                               buttons are handled by WHMCS's
        //                               JS via AJAX, never submitted)
        //   #frmProductDomainSelections the form that actually POSTs
        //                               to cart.php?a=add&pid=N&
        //                               domainselect=1 (confirmed —
        //                               this is the real HAR-captured
        //                               request), carrying the real
        //                               token plus #resultDomainOption
        //                               / #resultDomain hidden fields
        //
        // All three together confirm this is genuinely the domain-
        // choice step for a product that needs one. A product that
        // doesn't, or a direct hit on a=confdomains/a=view (back
        // button, bookmark, reload mid-flow), leaves them absent, and
        // this script exits having touched nothing.
        //
        // Deliberately not gated on window.location.search containing
        // a=add, either: this page is served at a pretty URL
        // (/store/<category>/<product>) with no query string at all —
        // the same SEO-friendly-URL shape that caused the checkout
        // redirect bug fixed earlier in header.tpl.
        var pidField = document.getElementById('frmProductDomainPid');
        var nativeOptionsForm = document.getElementById('frmProductDomain');
        var nativeSelectionsForm = document.getElementById('frmProductDomainSelections');
        if (!pidField || !nativeOptionsForm || !nativeSelectionsForm) {
            return;
        }

        var pid = pidField.value;
        if (!pid) {
            return;
        }

        var token = window.csrfToken;
        if (!token) {
            return;
        }

        try {
            build(root, nativeOptionsForm, nativeSelectionsForm, pid, token);
        } catch (err) {
            // Something about this page didn't match what this script
            // assumes — leave the native forms exactly as they were
            // rather than leave a half-built custom UI on screen.
            nativeOptionsForm.style.display = '';
            nativeSelectionsForm.style.display = '';
            var mount = document.getElementById('hoOnepageCheckout');
            if (mount) {
                mount.remove();
            }
        }
    }

    function build(root, nativeOptionsForm, nativeSelectionsForm, pid, token) {
        nativeOptionsForm.style.display = 'none';
        nativeSelectionsForm.style.display = 'none';

        var mount = document.createElement('div');
        mount.id = 'hoOnepageCheckout';
        mount.className = 'ho-onepage';
        nativeOptionsForm.parentNode.insertBefore(mount, nativeOptionsForm);

        mount.innerHTML =
            '<div class="ho-onepage-steps">' +
                '<div class="ho-onepage-step ho-onepage-step-active">' +
                    '<span class="ho-onepage-step-num">1</span>Choose &amp; Configure' +
                '</div>' +
                '<div class="ho-onepage-step-line"></div>' +
                '<div class="ho-onepage-step">' +
                    '<span class="ho-onepage-step-num">2</span>Payment' +
                '</div>' +
            '</div>' +
            '<div class="ho-onepage-card" id="hoStepDomain">' +
                '<h3 class="ho-onepage-card-title"><span class="ho-onepage-badge">1</span>Domain</h3>' +
                '<div class="ho-onepage-choice-row">' +
                    '<button type="button" class="ho-onepage-choice is-active" data-choice="register">Register a new domain</button>' +
                    '<button type="button" class="ho-onepage-choice" data-choice="owndomain">I already have a domain</button>' +
                    '<button type="button" class="ho-onepage-choice" data-choice="transfer">Transfer my domain</button>' +
                '</div>' +
                '<div class="ho-onepage-domain-fields">' +
                    '<div class="ho-onepage-field" style="flex: 1 1 240px;">' +
                        '<label for="hoSld">Domain name</label>' +
                        '<input type="text" id="hoSld" placeholder="yourbrand">' +
                    '</div>' +
                    '<div class="ho-onepage-field" style="flex: 0 0 120px;">' +
                        '<label for="hoTld">TLD</label>' +
                        '<select id="hoTld">' +
                            '<option value=".com">.com</option>' +
                            '<option value=".net">.net</option>' +
                            '<option value=".org">.org</option>' +
                            '<option value=".shop">.shop</option>' +
                            '<option value=".live">.live</option>' +
                            '<option value=".info">.info</option>' +
                        '</select>' +
                    '</div>' +
                    '<div class="ho-onepage-field ho-onepage-field-transfer" style="flex: 1 1 160px; display: none;">' +
                        '<label for="hoEpp">EPP / auth code</label>' +
                        '<input type="text" id="hoEpp" placeholder="Required for transfer">' +
                    '</div>' +
                    '<div class="ho-onepage-field" style="flex: 0 0 auto;">' +
                        '<button type="button" id="hoCheckBtn" class="ho-onepage-btn-ghost">Check availability</button>' +
                    '</div>' +
                '</div>' +
                '<div id="hoDomainResult"></div>' +
                '<div id="hoRegPeriodWrap" class="ho-onepage-field" style="margin-top: var(--space-3); max-width: 200px;">' +
                    '<label for="hoRegPeriod">Registration period</label>' +
                    '<select id="hoRegPeriod">' +
                        '<option value="1">1 year</option>' +
                        '<option value="2">2 years</option>' +
                        '<option value="3">3 years</option>' +
                    '</select>' +
                '</div>' +
                '<button type="button" id="hoDomainContinue" class="ho-onepage-btn-primary" disabled style="margin-top: var(--space-4);">Continue</button>' +
            '</div>' +
            '<div class="ho-onepage-card" id="hoStepConfigure" style="display: none;">' +
                '<h3 class="ho-onepage-card-title"><span class="ho-onepage-badge">2</span>Configure</h3>' +
                '<div id="hoConfigureMount"></div>' +
                '<button type="button" id="hoConfigureContinue" class="ho-onepage-btn-primary" style="margin-top: var(--space-4);">Continue</button>' +
            '</div>' +
            '<div class="ho-onepage-card" id="hoStepReview" style="display: none;">' +
                '<h3 class="ho-onepage-card-title"><span class="ho-onepage-badge">3</span>Review</h3>' +
                '<div id="hoReviewMount"></div>' +
            '</div>' +
            '<div class="ho-onepage-bar">' +
                '<div class="ho-onepage-bar-total">' +
                    '<span class="ho-onepage-bar-label">Total due today</span>' +
                    '<span class="ho-onepage-bar-amount" id="hoBarAmount">—</span>' +
                '</div>' +
                '<a href="cart.php?a=checkout" class="ho-onepage-btn-primary ho-onepage-bar-cta" id="hoPayLink" style="display: none;">Continue to Payment →</a>' +
            '</div>';

        var state = {
            choice: 'register',
            available: false,
            sld: '',
            tld: '.com',
        };

        var choiceButtons = mount.querySelectorAll('.ho-onepage-choice');
        var transferField = mount.querySelector('.ho-onepage-field-transfer');
        var regPeriodWrap = document.getElementById('hoRegPeriodWrap');
        var continueBtn = document.getElementById('hoDomainContinue');

        function setChoice(choice) {
            state.choice = choice;
            state.available = false;
            continueBtn.disabled = choice === 'register';
            document.getElementById('hoDomainResult').innerHTML = '';
            for (var i = 0; i < choiceButtons.length; i++) {
                choiceButtons[i].classList.toggle('is-active', choiceButtons[i].getAttribute('data-choice') === choice);
            }
            transferField.style.display = choice === 'transfer' ? '' : 'none';
            regPeriodWrap.style.display = choice === 'register' ? '' : 'none';
            // "Own domain" needs no registration, no availability check —
            // nothing stops the customer continuing immediately.
            if (choice === 'owndomain') {
                continueBtn.disabled = false;
            }
        }

        for (var i = 0; i < choiceButtons.length; i++) {
            choiceButtons[i].addEventListener('click', function (e) {
                setChoice(e.currentTarget.getAttribute('data-choice'));
            });
        }

        document.getElementById('hoCheckBtn').addEventListener('click', function () {
            checkAvailability();
        });

        function checkAvailability() {
            var sld = document.getElementById('hoSld').value.trim();
            var tld = document.getElementById('hoTld').value;
            var resultBox = document.getElementById('hoDomainResult');
            if (!sld) {
                return;
            }

            // A customer typing the full domain ("yourbrand.com") into
            // what's meant to be the name-only field, with the TLD
            // dropdown still sitting on its own default, silently builds
            // a malformed double-extension domain (yourbrand.com.com) —
            // confirmed live: it passed this check, got submitted, and
            // then broke every later cart recalculation (WHMCS's own
            // calcCartTotals() throws InvalidDomain trying to punycode-
            // decode it), including the final checkout page itself.
            // Caught here, before it ever reaches a real request.
            if (sld.indexOf('.') !== -1) {
                resultBox.innerHTML = '<div class="ho-onepage-note ho-onepage-note-error">Enter just the name here — choose the extension from the dropdown beside it (e.g. type "yourbrand", not "yourbrand.com").</div>';
                continueBtn.disabled = true;
                return;
            }

            resultBox.innerHTML = '<div class="ho-onepage-note">Checking…</div>';
            continueBtn.disabled = true;

            var body = new URLSearchParams();
            body.set('token', window.csrfToken);
            body.set('type', 'domain');
            body.set('domain', sld + tld);
            body.set('sld', sld);
            body.set('tld', tld);
            body.set('source', 'cartAddDomain');

            fetch('index.php?rp=/domain/check', {
                method: 'POST',
                credentials: 'same-origin',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8' },
                body: body.toString(),
            })
                .then(function (r) { return r.json(); })
                .then(function (data) {
                    var info = data && data.result && data.result[0];
                    if (!info) {
                        resultBox.innerHTML = '<div class="ho-onepage-note ho-onepage-note-error">Could not check that domain. Try again.</div>';
                        return;
                    }
                    if (!info.isValidDomain) {
                        resultBox.innerHTML = '<div class="ho-onepage-note ho-onepage-note-error">' + escapeHtml(info.domainErrorMessage || 'That domain name is not valid.') + '</div>';
                        return;
                    }
                    if (!info.isAvailable) {
                        resultBox.innerHTML = '<div class="ho-onepage-note ho-onepage-note-error">' + escapeHtml(info.domainName) + ' is already taken.</div>';
                        return;
                    }

                    var price = '';
                    if (info.isPremium && info.premiumCostPricing && info.premiumCostPricing.register) {
                        price = info.premiumCostPricing.register + ' (premium pricing)';
                    } else if (info.shortestPeriod && info.shortestPeriod.register) {
                        price = info.shortestPeriod.register + '/yr';
                    }

                    resultBox.innerHTML = '<div class="ho-onepage-note ho-onepage-note-ok">✓ ' + escapeHtml(info.domainName) + ' is available' + (price ? ' — ' + escapeHtml(price) : '') + '</div>';
                    state.available = true;
                    state.sld = sld;
                    state.tld = tld;
                    continueBtn.disabled = false;
                })
                .catch(function () {
                    resultBox.innerHTML = '<div class="ho-onepage-note ho-onepage-note-error">Could not check that domain. Try again.</div>';
                });
        }

        continueBtn.addEventListener('click', function () {
            submitDomainChoice();
        });

        function submitDomainChoice() {
            continueBtn.disabled = true;
            continueBtn.textContent = 'Please wait…';

            var body = new URLSearchParams();
            body.set('token', window.csrfToken);
            body.set('idnlanguage', '');

            if (state.choice === 'register') {
                var domain = state.sld + state.tld;
                body.set('domainoption', 'register');
                body.append('domains[]', domain);
                body.set('domainsregperiod[' + domain + ']', document.getElementById('hoRegPeriod').value);
            } else if (state.choice === 'owndomain') {
                var ownSld = document.getElementById('hoSld').value.trim();
                var ownTld = document.getElementById('hoTld').value;
                var ownDomain = ownSld + ownTld;
                body.set('domainoption', 'owndomain');
                body.append('domains[]', ownDomain);
            } else {
                // Transfer. INFERRED field set (eppcode[<domain>]) — not
                // confirmed against a real capture; see file docblock.
                var trSld = document.getElementById('hoSld').value.trim();
                var trTld = document.getElementById('hoTld').value;
                var trDomain = trSld + trTld;
                body.set('domainoption', 'transfer');
                body.append('domains[]', trDomain);
                body.set('domainsregperiod[' + trDomain + ']', '1');
                body.set('eppcode[' + trDomain + ']', document.getElementById('hoEpp').value.trim());
            }

            fetch('cart.php?a=add&pid=' + encodeURIComponent(pid) + '&domainselect=1', {
                method: 'POST',
                credentials: 'same-origin',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: body.toString(),
                redirect: 'follow',
            })
                .then(function (r) { return r.text(); })
                .then(function (html) {
                    var doc = new DOMParser().parseFromString(html, 'text/html');

                    if (doc.getElementById('frmProductDomain')) {
                        // Still on the domain-choice page — WHMCS rejected
                        // it (most likely it was sniped between check and
                        // submit). Let the customer try again rather than
                        // silently stall.
                        continueBtn.disabled = false;
                        continueBtn.textContent = 'Continue';
                        document.getElementById('hoDomainResult').innerHTML =
                            '<div class="ho-onepage-note ho-onepage-note-error">That didn\'t go through — please check availability again.</div>';
                        return;
                    }

                    lockDomainStep();

                    var addons = doc.querySelector('.addon-products');
                    if (addons) {
                        showConfigureStep(addons);
                    } else {
                        // Nothing to configure for this product — WHMCS
                        // itself skipped straight to the review page
                        // (confirmed real behaviour, seen live for a
                        // product with no addons). The order summary
                        // itself still needs a fresh, JS-executed load
                        // (see loadFreshReview) rather than this
                        // fetch's own static HTML.
                        loadFreshReview();
                    }
                })
                .catch(function () {
                    continueBtn.disabled = false;
                    continueBtn.textContent = 'Continue';
                });
        }

        function showConfigureStep(addonsFragment) {
            var card = document.getElementById('hoStepConfigure');
            var configureMount = document.getElementById('hoConfigureMount');
            configureMount.appendChild(addonsFragment.cloneNode(true));
            card.style.display = '';
            card.scrollIntoView({ behavior: 'smooth', block: 'start' });

            document.getElementById('hoConfigureContinue').addEventListener('click', function () {
                submitConfigure(configureMount);
            }, { once: true });
        }

        function submitConfigure(configureMount) {
            var btn = document.getElementById('hoConfigureContinue');
            btn.disabled = true;
            btn.textContent = 'Please wait…';

            var body = new URLSearchParams();
            body.set('token', window.csrfToken);
            body.set('update', 'true');

            // Resubmit whatever is actually in the cloned fragment —
            // this product's real addons, not a hardcoded list, so this
            // works for any product's addon set, not just the one this
            // script was tested against.
            var inputs = configureMount.querySelectorAll('input[name], select[name]');
            for (var i = 0; i < inputs.length; i++) {
                var el = inputs[i];
                if (el.type === 'checkbox') {
                    if (el.checked) {
                        body.append(el.name, el.value || 'on');
                    }
                } else {
                    body.append(el.name, el.value);
                }
            }

            fetch('cart.php?a=confdomains', {
                method: 'POST',
                credentials: 'same-origin',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: body.toString(),
                redirect: 'follow',
            })
                .then(function () {
                    document.getElementById('hoStepConfigure').style.opacity = '0.6';
                    btn.style.display = 'none';
                    loadFreshReview();
                })
                .catch(function () {
                    btn.disabled = false;
                    btn.textContent = 'Continue';
                });
        }

        /**
         * The order summary (.order-summary / #totalCartPrice) is not
         * in cart.php?a=view's server-rendered HTML — it is filled in
         * by WHMCS's own JS after the page loads (the little refresh
         * icon on the real "Order Summary" header is the tell). A
         * plain fetch()+DOMParser, used everywhere else in this file,
         * never runs that JS, so it only ever sees an empty shell —
         * confirmed live: the Review card rendered with a header and
         * nothing under it.
         *
         * A hidden iframe actually loads the page for real — its own
         * scripts run, including whatever AJAX call fills the summary
         * in — so this loads cart.php?a=view there and waits for
         * #totalCartPrice to actually have a value before reading
         * anything out of it. Capped at ~6s: if the summary still
         * hasn't appeared by then, the Review card falls back to a
         * plain message rather than waiting forever.
         */
        function loadFreshReview() {
            // Shown immediately — the poll below can take up to ~6s,
            // and an empty page with nothing happening reads as frozen
            // rather than working, which is exactly what was reported
            // live even on a run that was (slowly) still succeeding.
            var card = document.getElementById('hoStepReview');
            document.getElementById('hoReviewMount').innerHTML =
                '<div class="ho-onepage-note">Loading your order summary…</div>';
            card.style.display = '';
            card.scrollIntoView({ behavior: 'smooth', block: 'start' });

            var iframe = document.createElement('iframe');
            iframe.style.display = 'none';
            iframe.setAttribute('aria-hidden', 'true');
            iframe.setAttribute('title', 'Order summary (loading)');
            document.body.appendChild(iframe);

            var attempts = 0;
            var maxAttempts = 40; // ~6s at 150ms

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
                    showReviewStep(doc || document);
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

        function showReviewStep(doc) {
            var summary = doc.querySelector('.order-summary');
            var card = document.getElementById('hoStepReview');
            var reviewMount = document.getElementById('hoReviewMount');
            reviewMount.innerHTML = ''; // clear the "Loading…" placeholder

            if (summary) {
                reviewMount.appendChild(summary.cloneNode(true));
            } else {
                reviewMount.innerHTML = '<p>Your order is ready — continue to payment to see the full summary.</p>';
            }

            card.style.display = '';
            card.scrollIntoView({ behavior: 'smooth', block: 'start' });

            var totalEl = doc.getElementById('totalCartPrice');
            if (totalEl) {
                document.getElementById('hoBarAmount').textContent = totalEl.textContent.trim();
            }
            document.getElementById('hoPayLink').style.display = '';
        }

        // Dims AND disables the Domain card's own inputs/buttons once
        // its choice has actually been submitted to the cart. Opacity
        // alone left it fully interactive — confirmed live: a customer
        // checked a second, different domain in the already-"done"
        // card after continuing, which cannot change what was already
        // committed and only reads as confusing (or, worse, as if it
        // might silently replace the order).
        function lockDomainStep() {
            var card = document.getElementById('hoStepDomain');
            card.style.opacity = '0.6';
            continueBtn.style.display = 'none';
            var controls = card.querySelectorAll('input, select, button');
            for (var i = 0; i < controls.length; i++) {
                controls[i].disabled = true;
            }
        }

        function escapeHtml(str) {
            var div = document.createElement('div');
            div.textContent = String(str);
            return div.innerHTML;
        }
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
}());
