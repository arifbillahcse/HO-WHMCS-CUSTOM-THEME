/**
 * Hostorio — sidebar rail
 *
 * Two jobs:
 *   1. the off-canvas drawer state below 992px (above that the rail
 *      is a permanent column and there is nothing to toggle);
 *   2. expanding and collapsing menu sections inside the rail.
 *
 * Everything visual lives in css/hostorio-layout.css; this only sets
 * `ho-sidebar-open` on <body> and `ho-nav-open` on menu sections.
 *
 * Deliberately dependency-free — it runs from a plain deferred
 * <script> tag in includes/head.tpl and must not assume jQuery or
 * Bootstrap have initialised yet.
 */
(function () {
    'use strict';

    var OPEN_CLASS = 'ho-sidebar-open';
    var SECTION_OPEN_CLASS = 'ho-nav-open';
    var DESKTOP_MIN_WIDTH = 992;

    function init() {
        var sidebar = document.getElementById('main-menu');
        if (!sidebar) {
            return;
        }

        var body = document.body;
        var openers = document.querySelectorAll('.ho-sidebar-toggle');
        var closers = sidebar.querySelectorAll('.ho-sidebar-close');

        // Injected rather than templated so the markup stays clean
        // and the dimmer cannot appear if this script fails to run.
        var backdrop = document.createElement('div');
        backdrop.className = 'ho-sidebar-backdrop';
        body.appendChild(backdrop);

        function isOpen() {
            return body.classList.contains(OPEN_CLASS);
        }

        function setOpen(open) {
            // add/remove rather than toggle(class, force): the second
            // argument is ignored by older engines, which would flip
            // the state instead of setting it.
            if (open) {
                body.classList.add(OPEN_CLASS);
            } else {
                body.classList.remove(OPEN_CLASS);
            }
            for (var i = 0; i < openers.length; i++) {
                openers[i].setAttribute('aria-expanded', open ? 'true' : 'false');
            }
        }

        function bind(nodes, handler) {
            for (var i = 0; i < nodes.length; i++) {
                nodes[i].addEventListener('click', handler);
            }
        }

        bind(openers, function (event) {
            event.preventDefault();
            setOpen(!isOpen());
        });

        bind(closers, function (event) {
            event.preventDefault();
            setOpen(false);
        });

        backdrop.addEventListener('click', function () {
            setOpen(false);
        });

        sidebar.addEventListener('click', function (event) {
            var link = event.target.closest ? event.target.closest('a') : null;
            if (!link) {
                return;
            }

            // Section headers expand in place instead of opening a
            // Bootstrap dropdown. Bootstrap closes every open dropdown
            // on any document click, which is right for a menu that
            // floats over the page and wrong for a rail that is always
            // on screen — a section would collapse the moment the user
            // clicked anything. Stopping propagation keeps Bootstrap's
            // delegated handlers out of it entirely, so the expanded
            // state is ours to keep.
            if (link.getAttribute('data-toggle') === 'dropdown') {
                event.preventDefault();
                event.stopPropagation();
                link.parentNode.classList.toggle(SECTION_OPEN_CLASS);
                return;
            }

            // A link that navigates should not leave the drawer open
            // behind the new page paint.
            if (link.getAttribute('href')) {
                setOpen(false);
            }
        });

        // WHMCS marks the current page's item .active but leaves its
        // parent collapsed. In a horizontal bar that was invisible;
        // in a rail the section should already be open on load.
        var sections = sidebar.querySelectorAll('.navbar-nav > li.dropdown');
        for (var s = 0; s < sections.length; s++) {
            if (sections[s].classList.contains('active') ||
                sections[s].querySelector('.dropdown-menu > li.active')) {
                sections[s].classList.add(SECTION_OPEN_CLASS);
            }
        }

        document.addEventListener('keydown', function (event) {
            if ((event.key === 'Escape' || event.keyCode === 27) && isOpen()) {
                setOpen(false);
            }
        });

        // Crossing into the desktop layout while the drawer is open
        // would otherwise leave <body> stuck with overflow:hidden.
        window.addEventListener('resize', function () {
            if (isOpen() && window.innerWidth >= DESKTOP_MIN_WIDTH) {
                setOpen(false);
            }
        });
    }

    // Header language + currency switchers (header.tpl). Kept out of
    // init() above because that returns early when #main-menu is
    // absent, and login and registration render without the rail but
    // with the header.
    function initHeaderSelectors() {
        var selectors = document.querySelectorAll('.language-selector, .currency-selector');
        if (!selectors.length) {
            return;
        }

        // Bound on the document rather than each trigger so the same
        // handler closes every open panel on an outside click.
        document.addEventListener('click', function (event) {
            Array.prototype.forEach.call(selectors, function (selector) {
                if (selector.contains(event.target)) {
                    // A language option is a real link and a currency
                    // option submits its own form; let that action
                    // happen rather than collapsing the panel under the
                    // pointer first.
                    if (event.target.closest('.language-option, .currency-option')) {
                        return;
                    }
                    selector.classList.toggle('active');
                } else {
                    selector.classList.remove('active');
                }
            });
        });

        document.addEventListener('keydown', function (event) {
            if (event.key === 'Escape' || event.keyCode === 27) {
                Array.prototype.forEach.call(selectors, function (selector) {
                    selector.classList.remove('active');
                });
            }
        });

        // Currency options have no href to navigate to — WHMCS reads
        // the choice from a POSTed field (confirmed from its own
        // store/ssl/shared/currency-chooser.tpl), so the click has to
        // fill that field and submit the form itself.
        document.addEventListener('click', function (event) {
            var option = event.target.closest('.currency-option');
            if (!option) {
                return;
            }
            var form = option.closest('form');
            var input = form ? form.querySelector('#currencySwitcherInput') : null;
            if (!form || !input) {
                return;
            }
            input.value = option.getAttribute('data-currency-id') || '';
            form.submit();
        });
    }

    function boot() {
        init();
        initHeaderSelectors();
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', boot);
    } else {
        boot();
    }
}());
