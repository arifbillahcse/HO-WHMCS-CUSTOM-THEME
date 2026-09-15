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

    API contract, as specified by the chatbot developer (two
    endpoints, not one — this replaced an earlier single-endpoint
    design before either was ever wired up live):

        POST {data-send-endpoint}
        {"message": "...", "conversation_id": "..."}   <- "" if new
      → 200 {"ok":true, "conversation_id":"...", "reply":"..."}
      → 4xx {"ok":false, "error":"..."}

        GET {data-history-endpoint}?conversation_id=...
      → 200 {"ok":true, "messages":[{"role":"user"|"bot","content":"..."}, ...]}
      → 4xx {"ok":false, "messages":[]}

    Behaviour lives in js/hostorio-ai-search.js, styling in
    css/hostorio-layout.css (section 3d). Both are loaded from here
    so this partial is self-contained and can be dropped onto any
    other page as-is.
*}
<section class="ho-ai-search"
         data-send-endpoint="https://chat.hostorio.com/api/chat/send"
         data-history-endpoint="https://chat.hostorio.com/api/chat/history">

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
    versionHash (WHMCS's own cache-buster) only changes on a WHMCS
    upgrade, never when this file is edited — see the long comment on
    hoAssetVersion in includes/head.tpl. Using it here meant an edit
    to this script could never reach a returning visitor; switched to
    this theme's own buster so it cache-busts the same way every other
    hostorio-*.js file does.
*}
<script src="{$WEB_ROOT}/templates/{$template}/js/hostorio-ai-search.js?v={$hoAssetVersion}" defer></script>
