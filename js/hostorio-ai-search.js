/**
 * Hostorio — client area AI search
 *
 * Drives the box rendered by includes/ai-search.tpl. Grown from a
 * single-turn "ask a question, read the answer" box into a small
 * persistent chat log:
 *
 * - Each turn appends a user bubble and a bot bubble to
 *   .ho-ai-search-answer, rather than replacing it — so a reload
 *   restores that log has content across the request lifetime.
 * - conversation_id is kept in localStorage (key: hoai_conversation_id)
 *   so a page reload can re-fetch history and keep talking to the
 *   same conversation instead of starting cold.
 * - Tabs on the same browser stay in sync via a BroadcastChannel
 *   (channel: hoai_chat_sync): a message sent in one tab is echoed
 *   into every other open tab's log. This is same-browser sync only —
 *   BroadcastChannel does not cross devices or even reach the tab
 *   that sent the message (the sender already rendered its own turn).
 *
 * API contract (see includes/ai-search.tpl for the full shapes,
 * and its header comment for how these were verified — read from
 * the chatbot's own PHP source, not taken on a secondhand description
 * that turned out not to match what was actually deployed):
 *   POST data-send-endpoint    {message, conversation_id}
 *     -> {ok:true, conversation_id, answer, sources, actions, truncated}
 *      | {ok:false, error:{code, message}}
 *   GET  data-history-endpoint?conversation_id=...
 *     -> {ok:true, messages:[{role:"user"|"assistant", content}]}
 *      | {ok:false, error:{code, message}}
 *
 * Answer text is written with textContent, never innerHTML — it comes
 * back from a model (or, for history, from storage) and must not be
 * able to inject markup into the dashboard. The only structure built
 * from it is the bullet list in renderAnswer(), and that reads the
 * text as data too.
 *
 * Dependency-free, same as js/hostorio-sidebar.js: it runs from a
 * deferred <script> and cannot assume jQuery or Bootstrap are ready.
 */
(function () {
    'use strict';

    var ROOT_SELECTOR = '.ho-ai-search';
    var BUSY_CLASS = 'ho-ai-search-busy';
    var ANSWERED_CLASS = 'ho-ai-search-answered';
    var STORAGE_KEY = 'hoai_conversation_id';
    var CHANNEL_NAME = 'hoai_chat_sync';

    /* ---------- storage & cross-tab sync ----------
       Both are conveniences, not requirements: a box that can't read
       or write localStorage (private browsing, storage disabled) or
       whose browser lacks BroadcastChannel (older Safari) still works
       for the current tab — it just won't survive a reload or sync
       elsewhere. Every access is guarded so a throw here never breaks
       asking a question. */

    function readStoredConversationId() {
        try {
            return window.localStorage.getItem(STORAGE_KEY) || null;
        } catch (e) {
            return null;
        }
    }

    function writeStoredConversationId(id) {
        if (!id) {
            return;
        }
        try {
            window.localStorage.setItem(STORAGE_KEY, id);
        } catch (e) {
            // Ignored — see the file header.
        }
    }

    function openChannel(onMessage) {
        try {
            if (typeof BroadcastChannel === 'undefined') {
                return null;
            }
            var channel = new BroadcastChannel(CHANNEL_NAME);
            channel.onmessage = function (event) {
                if (event && event.data) {
                    onMessage(event.data);
                }
            };
            return channel;
        } catch (e) {
            return null;
        }
    }

    function broadcast(channel, payload) {
        if (!channel) {
            return;
        }
        try {
            channel.postMessage(payload);
        } catch (e) {
            // Ignored — see the file header.
        }
    }

    function init() {
        var roots = document.querySelectorAll(ROOT_SELECTOR);
        for (var i = 0; i < roots.length; i++) {
            wire(roots[i]);
        }
    }

    function wire(root) {
        var sendEndpoint = root.getAttribute('data-send-endpoint');
        var historyEndpoint = root.getAttribute('data-history-endpoint');
        var form = root.querySelector('.ho-ai-search-form');
        var input = root.querySelector('.ho-ai-search-input');
        var panel = root.querySelector('.ho-ai-search-answer');

        // Missing any of these means the markup changed; do nothing
        // rather than half-wire the box. historyEndpoint alone is not
        // required — without it the box just can't restore a prior
        // conversation, which is a smaller failure than not working
        // at all.
        if (!sendEndpoint || !form || !input || !panel) {
            return;
        }

        var conversationId = readStoredConversationId();
        var pending = false;

        function showAnswered() {
            root.classList.add(ANSWERED_CLASS);
        }

        var channel = openChannel(function (msg) {
            // A message from another tab. Adopt its conversation if
            // this tab has none yet; otherwise only render turns that
            // belong to the conversation already open here, so two
            // unrelated conversations in two tabs can't interleave.
            if (!conversationId) {
                conversationId = msg.conversationId || null;
                writeStoredConversationId(conversationId);
            } else if (msg.conversationId && msg.conversationId !== conversationId) {
                return;
            }

            if (msg.userText) {
                appendMessage(panel, 'user', msg.userText);
            }
            if (msg.botText) {
                appendMessage(panel, 'bot', msg.botText);
            }
            if (msg.userText || msg.botText) {
                showAnswered();
            }
        });

        if (conversationId && historyEndpoint) {
            loadHistory(panel, historyEndpoint, conversationId, showAnswered);
        }

        function ask(question) {
            if (pending || !question) {
                return;
            }
            pending = true;
            root.classList.add(BUSY_CLASS);
            showAnswered();

            appendMessage(panel, 'user', question);
            var pendingBubble = appendMessage(panel, 'bot', 'Thinking…', { pending: true });

            var headers = { 'Content-Type': 'application/json' };
            var token = root.getAttribute('data-chat-token');
            if (token) {
                headers['X-Chat-Token'] = token;
            }

            fetch(sendEndpoint, {
                method: 'POST',
                headers: headers,
                body: JSON.stringify({
                    message: question,
                    conversation_id: conversationId || ''
                })
            }).then(function (response) {
                // The API answers with JSON on success and on error
                // alike, so parse either way and branch on ok.
                return response.json().catch(function () {
                    return null;
                });
            }).then(function (data) {
                if (!data || data.ok === false || !data.answer) {
                    var message = (data && data.error && typeof data.error.message === 'string' && data.error.message)
                        ? data.error.message
                        : 'Something went wrong. Please try again.';
                    failMessage(pendingBubble, message);
                    return;
                }

                if (data.conversation_id) {
                    conversationId = data.conversation_id;
                    writeStoredConversationId(conversationId);
                }

                fillMessage(pendingBubble, data.answer, data);
                broadcast(channel, {
                    conversationId: conversationId,
                    userText: question,
                    botText: data.answer
                });
            }).catch(function () {
                failMessage(
                    pendingBubble,
                    'Could not reach the assistant. Please check your connection and try again.'
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

    /* ---------- history ---------- */

    /**
     * Fetches a conversation's prior turns and renders them in order.
     * Silent on any failure — a conversation that can't be restored
     * just starts the panel empty, the same as a first-time visitor,
     * rather than surfacing an error for something the user didn't
     * explicitly ask to happen.
     */
    function loadHistory(panel, historyEndpoint, conversationId, onLoaded) {
        var joiner = historyEndpoint.indexOf('?') === -1 ? '?' : '&';
        var url = historyEndpoint + joiner + 'conversation_id=' + encodeURIComponent(conversationId);

        fetch(url, {
            headers: { 'Content-Type': 'application/json' }
        }).then(function (response) {
            return response.json().catch(function () {
                return null;
            });
        }).then(function (data) {
            if (!data || data.ok === false || !data.messages || !data.messages.length) {
                return;
            }

            for (var i = 0; i < data.messages.length; i++) {
                var turn = data.messages[i];
                if (!turn || (turn.role !== 'user' && turn.role !== 'assistant')) {
                    continue;
                }
                var bubbleRole = turn.role === 'assistant' ? 'bot' : 'user';
                appendMessage(panel, bubbleRole, String(turn.content || ''));
            }
            onLoaded();
        }).catch(function () {
            // Ignored — see the function header.
        });
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

    /**
     * Appends one chat bubble (user or bot) to the log and returns it,
     * so a bot bubble created as a "Thinking…" placeholder can later
     * be filled in or turned into an error in place — the transcript
     * keeps its turn order either way, rather than the answer jumping
     * to wherever the panel happens to append next.
     */
    function appendMessage(panel, role, text, opts) {
        opts = opts || {};
        var msg = el('div', 'ho-ai-search-msg ho-ai-search-msg-' + role);
        if (opts.pending) {
            msg.classList.add('ho-ai-search-msg-pending');
        }

        if (role === 'bot') {
            msg.appendChild(renderAnswer(text));
        } else {
            msg.appendChild(el('p', null, text));
        }

        panel.appendChild(msg);
        panel.scrollTop = panel.scrollHeight;
        return msg;
    }

    /**
     * data carries the full send response (sources/actions/truncated)
     * so a fresh answer can show them; history replay has none of
     * these per turn (displayHistory() returns only role/content) and
     * simply omits them by passing no third argument.
     */
    function fillMessage(msg, text, data) {
        clear(msg);
        msg.classList.remove('ho-ai-search-msg-pending');
        msg.appendChild(renderAnswer(text));

        if (data) {
            var sources = sourceList(data.sources);
            if (sources) {
                msg.appendChild(el('h4', 'ho-ai-search-subhead', 'Related'));
                msg.appendChild(sources);
            }

            var actions = actionList(data.actions);
            if (actions) {
                msg.appendChild(actions);
            }

            if (data.truncated) {
                msg.appendChild(el(
                    'p',
                    'ho-ai-search-status',
                    'This answer was shortened. Ask a follow-up for more detail.'
                ));
            }
        }

        if (msg.parentNode) {
            msg.parentNode.scrollTop = msg.parentNode.scrollHeight;
        }
    }

    function failMessage(msg, text) {
        clear(msg);
        msg.classList.remove('ho-ai-search-msg-pending');
        msg.classList.add('ho-ai-search-msg-error');
        msg.appendChild(el('p', null, text));
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
     * `sources` is `array<int, string>` — citation labels, not links
     * (ChatReply::$sources in the chatbot's own source: "citations
     * that survived context trimming"). Rendered as plain text, same
     * reasoning as everything else here: nothing from the model
     * becomes a live link or markup.
     */
    function sourceList(sources) {
        if (!sources || !sources.length) {
            return null;
        }

        var list = el('ul', 'ho-ai-search-list ho-ai-search-sources');
        for (var i = 0; i < sources.length; i++) {
            if (typeof sources[i] === 'string' && sources[i]) {
                list.appendChild(el('li', null, sources[i]));
            }
        }
        return list.childNodes.length ? list : null;
    }

    /**
     * `actions` is `array<{name, outcome}>` — a record of tools the
     * assistant ran (e.g. a password reset), not links to follow.
     * outcome is one of ok/denied/needs_confirmation/error (see
     * ToolResult.php); shown as a small status line per action.
     */
    function actionList(actions) {
        if (!actions || !actions.length) {
            return null;
        }

        var list = el('ul', 'ho-ai-search-actions');
        for (var i = 0; i < actions.length; i++) {
            var action = actions[i];
            if (!action || typeof action.name !== 'string') {
                continue;
            }
            var label = action.name.replace(/_/g, ' ');
            var outcome = typeof action.outcome === 'string' ? action.outcome.replace(/_/g, ' ') : 'done';
            var li = el('li', 'ho-ai-search-action ho-ai-search-action-' + (action.outcome || 'ok'));
            li.appendChild(el('span', null, label + ': ' + outcome));
            list.appendChild(li);
        }
        return list.childNodes.length ? list : null;
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
}());
