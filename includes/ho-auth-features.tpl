{*
    Shared feature list for the .ho-auth left panel (login.tpl and
    clientregister.tpl show the same three lines).

    Every class here is unique to this block and used by exactly one
    rule in hostorio-layout.css ("Feature list" section) — including
    the icon wrapper, which used to just be a bare <span> matched by a
    broader ".ho-auth-features span" rule meant for the description
    text next to it. That rule's specificity beat the icon's own, so
    it silently overrode the icon's orange with its own pale text
    colour. Giving every element its own class, with no selector in
    the stylesheet written against a bare tag name, makes that
    particular class of bug structurally impossible here: nothing can
    be reached by a rule that wasn't written for it.

    Icons are solid, filled SVG shapes rather than Font Awesome glyphs
    — same reasoning as the product-card checkmarks in
    hostorio-store-cards.js: an icon font's glyph carries its own
    uneven padding inside its character cell, so centring the box
    around it still leaves the visible ink looking off-centre. Detail
    is picked out with a dark navy fill at partial opacity rather than
    a second stroke colour, so it reads clearly against the solid
    orange shape instead of a thin line disappearing into it.
*}
<ul id="hoAuthFeatureList" class="ho-auth-feat-list">
    <li class="ho-auth-feat-row">
        <span class="ho-auth-feat-iconbox">
            <svg class="ho-auth-feat-icon" viewBox="0 0 24 24" aria-hidden="true" focusable="false">
                <circle cx="12" cy="12" r="9" fill="currentColor"></circle>
                <circle cx="14.5" cy="9.5" r="4.5" fill="#01257D" fill-opacity="0.55"></circle>
            </svg>
        </span>
        <div class="ho-auth-feat-copy">
            <strong class="ho-auth-feat-title">Domain Management</strong>
            <span class="ho-auth-feat-desc">Register, transfer &amp; manage all TLDs</span>
        </div>
    </li>
    <li class="ho-auth-feat-row">
        <span class="ho-auth-feat-iconbox">
            <svg class="ho-auth-feat-icon" viewBox="0 0 24 24" aria-hidden="true" focusable="false">
                <path d="M5 3H15L19 7V21H5V3Z" fill="currentColor"></path>
                <path d="M15 3V7H19Z" fill="#01257D" fill-opacity="0.4"></path>
                <rect x="8" y="11" width="8" height="1.6" rx="0.8" fill="#01257D" fill-opacity="0.45"></rect>
                <rect x="8" y="15" width="8" height="1.6" rx="0.8" fill="#01257D" fill-opacity="0.45"></rect>
            </svg>
        </span>
        <div class="ho-auth-feat-copy">
            <strong class="ho-auth-feat-title">Invoice &amp; Billing</strong>
            <span class="ho-auth-feat-desc">View and pay invoices instantly</span>
        </div>
    </li>
    <li class="ho-auth-feat-row">
        <span class="ho-auth-feat-iconbox">
            <svg class="ho-auth-feat-icon" viewBox="0 0 24 24" aria-hidden="true" focusable="false">
                <path d="M12 2L4 5v6c0 5.5 3.8 10.7 8 12 4.2-1.3 8-6.5 8-12V5l-8-3z" fill="currentColor"></path>
                <path d="M8.5 12.2l2.3 2.3 4.2-4.6" fill="none" stroke="#01257D" stroke-opacity="0.55" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"></path>
            </svg>
        </span>
        <div class="ho-auth-feat-copy">
            <strong class="ho-auth-feat-title">Secure &amp; Reliable</strong>
            <span class="ho-auth-feat-desc">Enterprise-grade security &amp; uptime</span>
        </div>
    </li>
</ul>
