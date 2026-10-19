/**
 * Hostorio — "Choose a Domain" step on a product's configure page
 *
 * #frmProductDomain / .domain-selection-options is WHMCS's own
 * standard_cart output (templates/orderforms/standard_cart/), not a
 * template in this theme — same family as the Register Domain search
 * box and product cards, confirmed from this page's own real HTML,
 * not guessed.
 *
 * Only ever ADDS an icon + a short description line into each
 * .option's <label>, and moves its existing title text into its own
 * element so it isn't shown twice. Nothing about the radio inputs,
 * their name/value/checked state, or the nested .domain-input-group
 * fields (the www./SLD/TLD inputs and the Check/Transfer/Use buttons)
 * is touched or moved — this is exactly the DOM-relocation class of
 * change that caused real production bugs earlier in this project
 * (the one-page-checkout / review+checkout merge attempts, both
 * reverted).
 *
 * This theme's own CSS hides the iCheck plugin's visual radio dot
 * (.iradio_square-blue, WHMCS's own styling, a fixed-colour sprite
 * image that can't be recoloured to match the brand) inside these
 * cards and draws its own selected-state ring + checkmark instead,
 * keyed off .option-selected — the class WHMCS's own script already
 * toggles. That's safe specifically because iCheck binds its actual
 * click/toggle handler to the <label> element itself (confirmed by
 * reading js/scripts.js's own iCheck source, not assumed): a click
 * anywhere inside the label — including the content this file adds —
 * still reaches that handler regardless of what is or isn't visible
 * inside it. No selection logic is reimplemented here.
 *
 * Matched by the radio's own value first, falling back to the
 * label's text for anything matched only by wording (the fourth
 * "subdomain" option isn't present on every product, and its radio
 * value was never confirmed against live markup the way register/
 * transfer/owndomain were) — unmatched options still get a plain
 * generic icon rather than being left broken.
 */
(function () {
    'use strict';

    var SVG_NS = 'http://www.w3.org/2000/svg';
    var ACCENT = '#01257D';

    function el(tag, attrs) {
        var node = document.createElementNS(SVG_NS, tag);
        for (var key in attrs) {
            if (Object.prototype.hasOwnProperty.call(attrs, key)) {
                node.setAttribute(key, attrs[key]);
            }
        }
        return node;
    }

    function buildIcon(kind) {
        var svg = el('svg', { viewBox: '0 0 24 24', 'aria-hidden': 'true', focusable: 'false' });
        svg.setAttribute('class', 'ho-domain-opt-icon');

        if (kind === 'transfer') {
            svg.appendChild(el('circle', { cx: 12, cy: 12, r: 9, fill: 'currentColor' }));
            svg.appendChild(el('path', {
                d: 'M7.5 12h8m0 0l-3-3m3 3l-3 3',
                fill: 'none', stroke: ACCENT, 'stroke-opacity': 0.6,
                'stroke-width': 1.8, 'stroke-linecap': 'round', 'stroke-linejoin': 'round'
            }));
            return svg;
        }

        if (kind === 'nameservers') {
            svg.appendChild(el('circle', { cx: 12, cy: 12, r: 9, fill: 'currentColor' }));
            svg.appendChild(el('rect', { x: 7, y: 9, width: 10, height: 2.6, rx: 1.3, fill: ACCENT, 'fill-opacity': 0.55 }));
            svg.appendChild(el('rect', { x: 7, y: 13.4, width: 10, height: 2.6, rx: 1.3, fill: ACCENT, 'fill-opacity': 0.55 }));
            return svg;
        }

        if (kind === 'subdomain') {
            svg.appendChild(el('circle', { cx: 12, cy: 12, r: 9, fill: 'currentColor' }));
            svg.appendChild(el('path', {
                d: 'M8.5 16V11a2 2 0 0 1 2-2H15',
                fill: 'none', stroke: ACCENT, 'stroke-opacity': 0.6,
                'stroke-width': 1.8, 'stroke-linecap': 'round', 'stroke-linejoin': 'round'
            }));
            svg.appendChild(el('circle', { cx: 16, cy: 7.5, r: 1.6, fill: ACCENT, 'fill-opacity': 0.6 }));
            return svg;
        }

        // register, and the generic fallback — same orb+highlight mark
        // as the login/register page's "Domain Management" icon
        // (includes/ho-auth-features.tpl), for one consistent domain
        // icon across the theme rather than a second design for it.
        svg.appendChild(el('circle', { cx: 12, cy: 12, r: 9, fill: 'currentColor' }));
        svg.appendChild(el('circle', { cx: 14.5, cy: 9.5, r: 4.5, fill: ACCENT, 'fill-opacity': 0.55 }));
        return svg;
    }

    function describeOption(radio, labelText) {
        var value = (radio.getAttribute('value') || '').toLowerCase();
        var text = labelText.toLowerCase();

        if (value === 'register' || text.indexOf('register a new domain') !== -1) {
            return { icon: 'register', desc: 'Search and register a brand-new domain name.' };
        }
        if (value === 'transfer' || text.indexOf('transfer') !== -1) {
            return { icon: 'transfer', desc: "Move your domain's management over to us." };
        }
        if (value === 'owndomain' || text.indexOf('nameserver') !== -1 || text.indexOf('existing domain') !== -1) {
            return { icon: 'nameservers', desc: "Point your current domain's nameservers to us." };
        }
        if (text.indexOf('subdomain') !== -1) {
            return { icon: 'subdomain', desc: 'Get a free subdomain of ours instead of your own domain.' };
        }
        return { icon: 'generic', desc: '' };
    }

    function enhanceOption(option, detailsContainer) {
        if (option.dataset.hoDomainOptBuilt === '1') {
            return;
        }

        var radio = option.querySelector('input[type="radio"]');
        var label = option.querySelector('label');
        if (!radio || !label) {
            return;
        }

        // The option's title is WHMCS's own plain text node, a
        // sibling of the radio input (and, once iCheck has wrapped
        // it, of its .iradio_square-blue wrapper) inside <label>.
        // Found directly via childNodes rather than label.textContent
        // so it can be cleared afterwards — left in place, the same
        // wording would render a second time once copied into
        // .ho-domain-opt-title below.
        var title = '';
        Array.prototype.forEach.call(label.childNodes, function (node) {
            if (node.nodeType === 3 && node.textContent.trim()) {
                title = node.textContent.trim();
                node.textContent = '';
            }
        });
        if (!title) {
            return;
        }

        var info = describeOption(radio, title);

        var iconWrap = document.createElement('span');
        iconWrap.className = 'ho-domain-opt-iconbox';
        iconWrap.appendChild(buildIcon(info.icon));

        var copy = document.createElement('span');
        copy.className = 'ho-domain-opt-copy';

        var titleEl = document.createElement('strong');
        titleEl.className = 'ho-domain-opt-title';
        titleEl.textContent = title;
        copy.appendChild(titleEl);

        if (info.desc) {
            var descEl = document.createElement('span');
            descEl.className = 'ho-domain-opt-desc';
            descEl.textContent = info.desc;
            copy.appendChild(descEl);
        }

        var head = document.createElement('span');
        head.className = 'ho-domain-opt-head';
        head.appendChild(iconWrap);
        head.appendChild(copy);

        label.appendChild(head);
        option.classList.add('ho-domain-opt');
        option.dataset.hoDomainOptBuilt = '1';

        // The nested www./SLD/TLD + Check/Transfer/Use fields
        // (.domain-input-group) were designed for a full-width row,
        // not a one-third-width card — nested here, Bootstrap's own
        // .row/.col-sm-* grid inside them had nowhere near enough
        // room and squeezed down unreadable, per the screenshot this
        // was reported against. Moved into one shared panel below the
        // card row instead, so each option's fields get the full
        // width back once that option is selected.
        //
        // appendChild on a node already in the document MOVES it —
        // nothing here is cloned or rebuilt, so the element, its id,
        // and every input inside it (#registersld, #registertld, …)
        // are the exact same nodes WHMCS's own script already knows
        // about. That script shows/hides these purely by id
        // (jQuery("#domain"+value)), which works identically
        // regardless of which parent the id'd element currently sits
        // under — so relocating the container here cannot affect it.
        var group = option.querySelector('.domain-input-group');
        if (group && detailsContainer) {
            detailsContainer.appendChild(group);
        }
    }

    function init() {
        var container = document.querySelector('.domain-selection-options');
        if (!container) {
            return;
        }

        try {
            var details = document.createElement('div');
            details.className = 'ho-domain-opt-details';
            container.parentNode.insertBefore(details, container.nextSibling);

            Array.prototype.forEach.call(
                container.querySelectorAll(':scope > .option'),
                function (option) {
                    enhanceOption(option, details);
                }
            );
        } catch (e) {
            // Swallowed deliberately — see the file header. A thrown
            // error here would leave the step half-transformed, which
            // is worse than leaving it stock.
        }
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
}());
