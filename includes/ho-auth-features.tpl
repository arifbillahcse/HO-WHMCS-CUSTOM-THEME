{*
    Shared feature list for the .ho-auth left panel (login.tpl and
    clientregister.tpl show the same three lines). Icons are inline SVG,
    not Font Awesome glyphs — the same fix used for the product-card
    checkmarks in hostorio-store-cards.js: an icon font's glyph carries
    its own uneven padding inside its character cell, so flex-centering
    the box around it still leaves the visible ink looking off-centre.
    An SVG path has no such hidden padding, so centring the box centres
    what is actually drawn. stroke="currentColor" picks up
    .ho-auth-feature-icon's own color so these inherit the same brand
    orange the Font Awesome glyphs used.
*}
<ul class="ho-auth-features">
    <li>
        <span class="ho-auth-feature-icon">
            <svg class="ho-auth-feature-svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false">
                <circle cx="12" cy="12" r="10"></circle>
                <line x1="2" y1="12" x2="22" y2="12"></line>
                <path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"></path>
            </svg>
        </span>
        <div><strong>Domain Management</strong><span>Register, transfer &amp; manage all TLDs</span></div>
    </li>
    <li>
        <span class="ho-auth-feature-icon">
            <svg class="ho-auth-feature-svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false">
                <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                <polyline points="14 2 14 8 20 8"></polyline>
                <line x1="16" y1="13" x2="8" y2="13"></line>
                <line x1="16" y1="17" x2="8" y2="17"></line>
            </svg>
        </span>
        <div><strong>Invoice &amp; Billing</strong><span>View and pay invoices instantly</span></div>
    </li>
    <li>
        <span class="ho-auth-feature-icon">
            <svg class="ho-auth-feature-svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false">
                <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path>
                <polyline points="9 12 11 14 15 10"></polyline>
            </svg>
        </span>
        <div><strong>Secure &amp; Reliable</strong><span>Enterprise-grade security &amp; uptime</span></div>
    </li>
</ul>
