{*
    Shared feature list for the .ho-auth left panel (login.tpl and
    clientregister.tpl show the same three lines).

    Rebuilt as solid, filled shapes rather than 2px outline strokes —
    outline icons at 20px on a translucent panel box read as too faint
    to register as anything at a glance, which is what was reported
    against the first SVG pass. Each icon is now a single bold
    currentColor silhouette (orb / document / shield), with fine detail
    picked out using a dark navy overlay fill at partial opacity rather
    than a second stroke colour, so it stays crisp against the solid
    shape instead of disappearing into it.

    Still inline SVG rather than a Font Awesome glyph, for the same
    reason as the product-card checkmarks in hostorio-store-cards.js:
    an icon font's glyph carries its own uneven padding inside its
    character cell, so flex-centring the box around it still leaves the
    visible ink off-centre. A hand-drawn shape has no such padding.
*}
<ul class="ho-auth-features">
    <li>
        <span class="ho-auth-feature-icon">
            <svg class="ho-auth-feature-svg" viewBox="0 0 24 24" aria-hidden="true" focusable="false">
                <circle cx="12" cy="12" r="9" fill="currentColor"></circle>
                <circle cx="14.5" cy="9.5" r="4.5" fill="#01257D" fill-opacity="0.55"></circle>
            </svg>
        </span>
        <div><strong>Domain Management</strong><span>Register, transfer &amp; manage all TLDs</span></div>
    </li>
    <li>
        <span class="ho-auth-feature-icon">
            <svg class="ho-auth-feature-svg" viewBox="0 0 24 24" aria-hidden="true" focusable="false">
                <path d="M5 3H15L19 7V21H5V3Z" fill="currentColor"></path>
                <path d="M15 3V7H19Z" fill="#01257D" fill-opacity="0.4"></path>
                <rect x="8" y="11" width="8" height="1.6" rx="0.8" fill="#01257D" fill-opacity="0.45"></rect>
                <rect x="8" y="15" width="8" height="1.6" rx="0.8" fill="#01257D" fill-opacity="0.45"></rect>
            </svg>
        </span>
        <div><strong>Invoice &amp; Billing</strong><span>View and pay invoices instantly</span></div>
    </li>
    <li>
        <span class="ho-auth-feature-icon">
            <svg class="ho-auth-feature-svg" viewBox="0 0 24 24" aria-hidden="true" focusable="false">
                <path d="M12 2L4 5v6c0 5.5 3.8 10.7 8 12 4.2-1.3 8-6.5 8-12V5l-8-3z" fill="currentColor"></path>
                <path d="M8.5 12.2l2.3 2.3 4.2-4.6" fill="none" stroke="#01257D" stroke-opacity="0.55" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"></path>
            </svg>
        </span>
        <div><strong>Secure &amp; Reliable</strong><span>Enterprise-grade security &amp; uptime</span></div>
    </li>
</ul>
