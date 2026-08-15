/**
 * Hostorio — client area AI search
 *
 * Drives the box rendered by includes/ai-search.tpl: takes the
 * question, POSTs it to the chat API named in the element's
 * data-endpoint, and renders the answer inline underneath.
 *
 * The reply's conversation_id is kept for the life of the page, so a
 * follow-up question continues the same thread instead of starting a
 * cold one.
 *
 * Answer text is written with textContent, never innerHTML — it comes
 * back from a model and must not be able to inject markup into the
 * dashboard. The only structure built from it is the bullet list
 * below, and that reads the text as data too.
 *
 * Dependency-free, same as js/hostorio-sidebar.js: it runs from a
 * deferred <script> and cannot assume jQuery or Bootstrap are ready.
 */
(function () {
    'use strict';

    var ROOT_SELECTOR = '.ho-ai-search';
    var BUSY_CLASS = 'ho-ai-search-busy';
    var ANSWERED_CLASS = 'ho-ai-search-answered';

    function init() {
        var roots = document.querySelectorAll(ROOT_SELECTOR);
        for (var i = 0; i < roots.length; i++) {
            wire(roots[i]);
        }
    }

    function wire(root) {
        var endpoint = root.getAttribute('data-endpoint');
        var form = root.querySelector('.ho-ai-search-form');
        var input = root.querySelector('.ho-ai-search-input');
        var panel = root.querySelector('.ho-ai-search-answer');

        // Missing any of these means the markup changed; do nothing
        // rather than half-wire the box.
        if (!endpoint || !form || !input || !panel) {
            return;
        }

        var conversationId = null;
        var pending = false;

        function ask(question) {
            if (pending || !question) {
                return;
            }
            pending = true;
            root.classList.add(BUSY_CLASS);
            root.classList.add(ANSWERED_CLASS);
            showStatus(panel, 'Thinking…', true);

            var body = { message: question };
            if (conversationId) {
                body.conversation_id = conversationId;
            }

            var headers = { 'Content-Type': 'application/json' };
            var token = root.getAttribute('data-chat-token');
            if (token) {
                headers['X-Chat-Token'] = token;
            }

            fetch(endpoint, {
                method: 'POST',
                headers: headers,
                body: JSON.stringify(body)
            }).then(function (response) {
                // The API answers with JSON on success and on error
                // alike, so parse either way and branch on ok.
                return response.json().catch(function () {
                    return null;
                });
            }).then(function (data) {
                if (!data) {
                    throw new Error('unreadable');
                }
                if (data.ok === false || !data.answer) {
                    var message = data.error && data.error.message
                        ? data.error.message
                        : 'Something went wrong. Please try again.';
                    showStatus(panel, message, false);
                    return;
                }
                if (data.conversation_id) {
                    conversationId = data.conversation_id;
                }
                render(panel, data, question);
            }).catch(function () {
                showStatus(
                    panel,
                    'Could not reach the assistant. Please check your connection and try again.',
                    false
                );
            }).then(function () {
                pending = false;
                root.classList.remove(BUSY_CLASS);
            });
        }

        form.addEventListener('submit', function (event) {
            event.preventDefault();
            var question = input.value.trim();
            if (!question) {
                input.focus();
                return;
            }
            ask(question);
            input.value = '';
        });

        var chips = root.querySelectorAll('.ho-ai-search-chip');
        for (var c = 0; c < chips.length; c++) {
            chips[c].addEventListener('click', function (event) {
                ask(event.currentTarget.textContent.trim());
            });
        }
    }

    /* ---------- rendering ---------- */

    function clear(node) {
        while (node.firstChild) {
            node.removeChild(node.firstChild);
        }
    }

    function el(tag, className, text) {
        var node = document.createElement(tag);
        if (className) {
            node.className = className;
        }
        if (text !== undefined) {
            node.textContent = text;
        }
        return node;
    }

    function showStatus(panel, message, busy) {
        clear(panel);
        panel.setAttribute('aria-busy', busy ? 'true' : 'false');
        panel.appendChild(el('p', 'ho-ai-search-status', message));
    }

    function render(panel, data, question) {
        clear(panel);
        panel.setAttribute('aria-busy', 'false');

        panel.appendChild(el('p', 'ho-ai-search-question', question));
        panel.appendChild(renderAnswer(data.answer));

        var sources = linkList(data.sources, 'ho-ai-search-source');
        if (sources) {
            panel.appendChild(el('h4', 'ho-ai-search-subhead', 'Related'));
            panel.appendChild(sources);
        }

        var actions = linkList(data.actions, 'ho-ai-search-action');
        if (actions) {
            actions.className = 'ho-ai-search-actions';
            panel.appendChild(actions);
        }

        if (data.truncated) {
            panel.appendChild(el(
                'p',
                'ho-ai-search-status',
                'This answer was shortened. Ask a follow-up for more detail.'
            ));
        }
    }

    /**
     * The API returns plain text using "- " for bullets. Group runs of
     * those into a real <ul> and keep everything else as paragraphs;
     * no markdown parser, so nothing in the reply can become markup.
     */
    function renderAnswer(answer) {
        var wrap = el('div', 'ho-ai-search-body');
        var lines = String(answer).split('\n');
        var list = null;

        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim();

            if (!line) {
                list = null;
                continue;
            }

            if (line.charAt(0) === '-' || line.charAt(0) === '*') {
                if (!list) {
                    list = el('ul', 'ho-ai-search-list');
                    wrap.appendChild(list);
                }
                list.appendChild(el('li', null, line.slice(1).trim()));
                continue;
            }

            list = null;
            wrap.appendChild(el('p', null, line));
        }

        return wrap;
    }

    /**
     * `sources` and `actions` are documented as arrays but their item
     * shape is not guaranteed, so only entries carrying both a label
     * and an http(s) link are rendered — anything else is skipped
     * rather than printed as "[object Object]".
     */
    function linkList(items, itemClass) {
        if (!items || !items.length) {
            return null;
        }

        var list = el('ul', 'ho-ai-search-links');
        var count = 0;

        for (var i = 0; i < items.length; i++) {
            var item = items[i];
            if (!item || typeof item !== 'object') {
                continue;
            }

            var href = item.url || item.href || item.link;
            var label = item.title || item.label || item.name || href;
            if (!href || !/^https?:\/\//i.test(href)) {
                continue;
            }

            var link = el('a', itemClass, String(label));
            link.href = href;
            link.rel = 'noopener';

            var li = el('li');
            li.appendChild(link);
            list.appendChild(li);
            count++;
        }

        return count ? list : null;
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
}());
