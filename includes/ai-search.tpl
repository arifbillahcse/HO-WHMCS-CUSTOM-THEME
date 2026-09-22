{*
    Client area AI search / assistant box.

    Posts straight to the Hostorio chat API rather than opening the
    floating widget, so the answer lands inline on the dashboard —
    the "ask a question, read the answer here" pattern, not a chat
    bubble the user has to open first.

    Grown into a small persistent chat log: the conversation survives
    a reload (conversation_id in localStorage, history re-fetched on
    load) and stays in sync across tabs open on the same browser via
    BroadcastChannel — see js/hostorio-ai-search.js for both.

    API contract — read directly from the chatbot's own source
    (arifbillahcse/hostorio-ai-chatboot: public/index.php's router,
    ChatController.php, ChatReply::toPublicArray(), Response::error())
    rather than from a description of it, after a description given
    secondhand turned out not to match what was actually deployed —
    it named a POST /api/chat/send that no route in that codebase
    defines, a "reply" field the code never emits, and a plain-string
    error where the code always sends an {code,message} object:

        POST {data-send-endpoint}    (this IS /api/chat — no /send)
        {"message": "...", "conversation_id": "..."}   <- "" if new
      → 200 {"ok":true, "conversation_id":"...", "answer":"...",
              "sources":[...], "actions":[...], "truncated":false}
      → 4xx {"ok":false, "error":{"code":"...","message":"..."}}

        GET {data-history-endpoint}?conversation_id=...
      → 200 {"ok":true, "messages":[{"role":"user"|"assistant","content":"..."}, ...]}
      → 4xx {"ok":false, "error":{"code":"not_found","message":"..."}}

    Behaviour lives in js/hostorio-ai-search.js, styling in
    css/hostorio-layout.css (section 3d). Both are loaded from here
    so this partial is self-contained and can be dropped onto any
    other page as-is.

    data-chat-token: identity, for account-specific answers ("your
    domains expire on..."). Deliberately NOT generated here — that
    would mean either a {php} block (unsupported by the Smarty version
    WHMCS ships, and blocked outright even where it isn't, for the
    obvious reason a theme file becoming able to run arbitrary PHP
    would be) or embedding IDENTITY_BRIDGE_SECRET in a template file
    this repo's normal workflow would commit to git. Both are real
    ways to leak that secret.

    Minted instead by a WHMCS hook — includes/hooks/hostorio_chatbot.php,
    shipped in the chatbot's own repo at
    integrations/whmcs/hostorio_chatbot.php — installed directly on the
    WHMCS server, outside this theme and outside version control. Its
    ClientAreaPage hook return value becomes {$hostorio_chat_token}
    automatically on every client area page; this line just forwards
    it. Empty/undefined (hook not installed yet, or customer is a
    guest) is not an error — hostorio-ai-search.js already treats a
    missing token as "ask anonymously" rather than failing.
*}
<section class="ho-ai-search"
         data-send-endpoint="https://chat.hostorio.com/api/chat"
         data-history-endpoint="https://chat.hostorio.com/api/chat/history"
         data-chat-token="{$hostorio_chat_token|default:''}">

    <h2 class="ho-ai-search-greeting">
        {if $loggedin && $clientsdetails.firstname}
            Hi, {$clientsdetails.firstname}! How can I help you today?
        {else}
            How can I help you today?
        {/if}
    </h2>

    <form class="ho-ai-search-form" role="search" autocomplete="off">
        <label class="sr-only" for="hoAiSearchInput">Ask a question</label>
        <input type="text"
               id="hoAiSearchInput"
               class="ho-ai-search-input"
               name="message"
               placeholder="Type what you're looking for or ask a question">
        <button type="submit" class="ho-ai-search-submit" aria-label="Send">
            <i class="fas fa-arrow-up" aria-hidden="true"></i>
        </button>
    </form>

    {* Starting points, so an empty box is not the only prompt.
       Clicking one submits it. *}
    <div class="ho-ai-search-suggestions">
        <button type="button" class="ho-ai-search-chip">How do I renew my domain?</button>
        <button type="button" class="ho-ai-search-chip">Upgrade my hosting plan</button>
        <button type="button" class="ho-ai-search-chip">Where can I find my invoices?</button>
    </div>

    {* Filled in by the script with one bubble per turn; stays empty
       (and hidden) until there is a question asked or history to
       show. *}
    <div class="ho-ai-search-answer" aria-live="polite"></div>

    <p class="ho-ai-search-foot">
        Prefer to browse? <a href="{$WEB_ROOT}/knowledgebase.php">Search the knowledgebase</a>
        or <a href="{$WEB_ROOT}/submitticket.php">open a ticket</a>.
    </p>

</section>
{*
    DIAGNOSTIC — TEMPORARY. Disabled alongside this theme's other
    custom scripts to isolate a checkout-flow report — see the
    matching block in includes/head.tpl for the full explanation.
    Restore this once that test is done, whichever way it comes out.
*}
{*
<script src="{$WEB_ROOT}/templates/{$template}/js/hostorio-ai-search.js?v={$hoAssetVersion}" defer></script>
*}
