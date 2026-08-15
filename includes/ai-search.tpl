{*
    Client area AI search / assistant box.

    Posts straight to the Hostorio chat API rather than opening the
    floating widget, so the answer lands inline on the dashboard —
    the "ask a question, read the answer here" pattern, not a chat
    bubble the user has to open first.

    API contract (verified against the live endpoint):
        POST {data-endpoint}
        {"message": "...", "conversation_id": "..."}   <- id optional
      → 200 {"ok":true, "answer":"...", "conversation_id":"...",
              "sources":[], "actions":[], "truncated":false}
      → 4xx {"ok":false, "error":{"code":"...","message":"..."}}

    Behaviour lives in js/hostorio-ai-search.js, styling in
    css/hostorio-layout.css (section 3d). Both are loaded from here
    so this partial is self-contained and can be dropped onto any
    other page as-is.
*}
<section class="ho-ai-search" data-endpoint="https://chat.hostorio.com/api/chat">

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

    {* Filled in by the script; stays empty (and hidden) until asked. *}
    <div class="ho-ai-search-answer" aria-live="polite"></div>

    <p class="ho-ai-search-foot">
        Prefer to browse? <a href="{$WEB_ROOT}/knowledgebase.php">Search the knowledgebase</a>
        or <a href="{$WEB_ROOT}/submitticket.php">open a ticket</a>.
    </p>

</section>
<script src="{$WEB_ROOT}/templates/{$template}/js/hostorio-ai-search.js?v={$versionHash}" defer></script>
