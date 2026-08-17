/**
 * Hostorio — remove unwanted panels from the product overview tab
 *
 * The "Quick Shortcuts" icon grid and "Quick Create Email Account"
 * form on a hosting product's Overview tab (clientarea.php?action=
 * productdetails) are not this theme's markup and not WHMCS core's
 * either — they come from the cPanel provisioning module's own
 * overview template ($tplOverviewTabOutput in
 * clientareaproductdetails.tpl, a single opaque HTML string the
 * module hands the page, not a Smarty object this theme can filter
 * the way $panels / $secondarySidebar are elsewhere). There is no
 * .tpl file in this repo to edit them out of.
 *
 * Removed here instead, after the page has rendered, by finding each
 * panel's own heading text and walking up to its nearest .panel
 * ancestor — the same "match by the text actually on screen, not a
 * guessed class or id" approach this theme already uses in
 * clientareahome.tpl's hiddenPanelLabels, for the same reason: an
 * internal name is not documented, is not what the module prints on
 * screen, and is not safe to guess.
 *
 * Deliberately dependency-free, like hostorio-sidebar.js: runs from a
 * plain deferred <script> tag and must not assume jQuery has
 * initialised yet.
 */
(function () {
    'use strict';

    // Exact panel-heading text to remove. Matched against a heading
    // element's own textContent, trimmed — not against the whole
    // page — so this cannot accidentally match some other panel that
    // merely mentions these words in passing.
    var HIDDEN_PANEL_HEADINGS = [
        'Quick Shortcuts',
        'Quick Create Email Account'
    ];

    function removePanelsByHeading() {
        var headings = document.querySelectorAll(
            '.panel-title, .panel-heading, h1, h2, h3, h4, h5, h6'
        );

        headings.forEach(function (heading) {
            var text = (heading.textContent || '').trim();
            if (HIDDEN_PANEL_HEADINGS.indexOf(text) === -1) {
                return;
            }

            var panel = heading.closest('.panel');
            if (panel) {
                panel.remove();
            }
        });
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', removePanelsByHeading);
    } else {
        removePanelsByHeading();
    }
}());
