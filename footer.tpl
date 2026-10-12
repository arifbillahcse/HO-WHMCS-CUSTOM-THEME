            {*
                Secondary sidebar (Categories/Actions on store pages, etc.)
                now renders as a horizontal sticky bar at the top instead of
                a left column. The main-content is now full width.

                Client Contacts and Client Shortcuts, on the client area
                home page, arrive through this collection — same
                reasoning as $primarySidebar above (see header.tpl):
                dropped here, before hasChildren() is checked, rather
                than in sidebar-horizontal-secondary.tpl, which store
                pages also use for their own, unrelated Categories bar
                and must stay generic. Filtering before the check means
                a home page with nothing left in $secondarySidebar skips
                this whole sticky, shadowed container instead of
                rendering it empty.
            *}
            {*
                'Support' is the bar of My Support Tickets /
                Announcements / Knowledgebase / Downloads / Network
                Status / Open Ticket that WHMCS puts under every
                support page. Every one of those links is already in
                the nav rail, so it restated the navigation directly
                beneath itself. Dropped by name, which takes it off
                all of those pages at once, not only Open Ticket.
            *}
            {assign var="hiddenSidebarPanelNames" value=['Client Details', 'Client Contacts', 'Client Shortcuts', 'Support']}
            {foreach $secondarySidebar as $sidebarItem}
                {if in_array($sidebarItem->getName(), $hiddenSidebarPanelNames)}
                    {assign var="secondarySidebar" value=$secondarySidebar->removeChild($sidebarItem->getName())}
                {/if}
            {/foreach}
            {if !$inShoppingCart && $secondarySidebar->hasChildren()}
                <div class="ho-secondary-sidebar-container">
                    {include file="$template/includes/sidebar-horizontal-secondary.tpl" sidebar=$secondarySidebar}
                </div>
            {/if}
                </div><!-- /.main-content -->
            <div class="clearfix"></div>
        </div>
    </div>
</section>

{* Footer removed sitewide at the user's request — it previously
   rendered on every page except login/register (those already had
   it dropped). The markup (brand column, Account/Services/Support
   link lists, copyright bar, back-to-top button) is gone, not just
   hidden; section 4 of hostorio-layout.css styles it and is now
   unused dead CSS, left in place rather than torn out in case the
   footer comes back later. *}

    </div><!-- /.ho-content -->
</div><!-- /.ho-shell — opened in header.tpl -->

<div id="fullpage-overlay" class="hidden">
    <div class="outer-wrapper">
        <div class="inner-wrapper">
            <img src="{$WEB_ROOT}/assets/img/overlay-spinner.svg">
            <br>
            <span class="msg"></span>
        </div>
    </div>
</div>

<div class="modal system-modal fade" id="modalAjax" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content panel-primary">
            <div class="modal-header panel-heading">
                <button type="button" class="close" data-dismiss="modal">
                    <span aria-hidden="true">&times;</span>
                    <span class="sr-only">{$LANG.close}</span>
                </button>
                <h4 class="modal-title"></h4>
            </div>
            <div class="modal-body panel-body">
                {$LANG.loading}
            </div>
            <div class="modal-footer panel-footer">
                <div class="pull-left loader">
                    <i class="fas fa-circle-notch fa-spin"></i>
                    {$LANG.loading}
                </div>
                <button type="button" class="btn btn-default" data-dismiss="modal">
                    {$LANG.close}
                </button>
                <button type="button" class="btn btn-primary modal-submit">
                    {$LANG.submit}
                </button>
            </div>
        </div>
    </div>
</div>

{include file="$template/includes/generate-password.tpl"}

{$footeroutput}

</body>
</html>
