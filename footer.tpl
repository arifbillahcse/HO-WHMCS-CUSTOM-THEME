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
            {assign var="hiddenSidebarPanelNames" value=['Client Details', 'Client Contacts', 'Client Shortcuts']}
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

{*
    No footer at all on login and registration, for the same reason
    header.tpl drops the nav rail there: every link in it leads
    somewhere that requires a session, so the whole block is noise
    around the one control those pages exist for.

    Wraps the section rather than its contents so nothing is left
    behind — an empty navy bar reads as a rendering fault, not as a
    deliberate choice. The back-to-top button goes with it; jQuery
    binds it by class and no-ops on an empty selection.
*}
{if !$showingLoginPage && $templatefile != 'clientregister'}
<section id="footer">
    <div class="container">

        {*
            Footer link labels and contact details below are plain text so
            they always render. To translate them, swap the text for the
            matching {$LANG.key} or {lang key='...'} tag.

            EDIT BEFORE GOING LIVE: the address, phone, email and social
            profile URLs in the "Contact" and "Follow us" blocks are
            placeholders.
        *}

        <div class="row">

            <div class="col-md-4 col-sm-12 footer-col">
                <span class="footer-brand-name">{$companyname}</span>
                <p class="footer-about">
                    Reliable web hosting, domain registration and business email,
                    backed by round-the-clock support.
                </p>
                <ul class="footer-social">
                    <li><a href="#" title="Facebook"><i class="fab fa-facebook-f"></i></a></li>
                    <li><a href="#" title="X"><i class="fab fa-twitter"></i></a></li>
                    <li><a href="#" title="LinkedIn"><i class="fab fa-linkedin-in"></i></a></li>
                    <li><a href="#" title="YouTube"><i class="fab fa-youtube"></i></a></li>
                    <li><a href="#" title="WhatsApp"><i class="fab fa-whatsapp"></i></a></li>
                </ul>
            </div>

            <div class="col-md-2 col-sm-4 footer-col">
                <h5 class="footer-col-title">Account</h5>
                <ul class="footer-links">
                    <li><a href="{$WEB_ROOT}/clientarea.php">Client Area</a></li>
                    <li><a href="{$WEB_ROOT}/clientarea.php?action=services">My Services</a></li>
                    <li><a href="{$WEB_ROOT}/clientarea.php?action=domains">My Domains</a></li>
                    <li><a href="{$WEB_ROOT}/clientarea.php?action=invoices">Invoices</a></li>
                </ul>
            </div>

            <div class="col-md-3 col-sm-4 footer-col">
                <h5 class="footer-col-title">Services</h5>
                <ul class="footer-links">
                    <li><a href="{$WEB_ROOT}/cart.php">{$LANG.orderhosting}</a></li>
                    <li><a href="{$WEB_ROOT}/domainchecker.php">{$LANG.buyadomain}</a></li>
                    <li><a href="{$WEB_ROOT}/announcements.php">Announcements</a></li>
                    <li><a href="{$WEB_ROOT}/serverstatus.php">Network Status</a></li>
                </ul>
            </div>

            <div class="col-md-3 col-sm-4 footer-col">
                <h5 class="footer-col-title">Support</h5>
                <ul class="footer-contact">
                    <li>
                        <i class="fas fa-life-ring"></i>
                        <a href="{$WEB_ROOT}/submitticket.php">{$LANG.getsupport}</a>
                    </li>
                    <li>
                        <i class="fas fa-book"></i>
                        <a href="{$WEB_ROOT}/knowledgebase.php">Knowledgebase</a>
                    </li>
                    <li>
                        <i class="fas fa-envelope"></i>
                        <a href="{$WEB_ROOT}/contact.php">Contact Us</a>
                    </li>
                    <li>
                        <i class="fas fa-phone"></i>
                        <span>+880 0000-000000</span>
                    </li>
                </ul>
            </div>

        </div>

        <div class="footer-bottom">
            <p>{lang key="copyrightFooterNotice" year=$date_year company=$companyname}</p>
            <ul class="footer-legal">
                <li><a href="{$WEB_ROOT}/index.php">Privacy Policy</a></li>
                <li><a href="{$WEB_ROOT}/index.php">Terms of Service</a></li>
            </ul>
        </div>

    </div>

    <a href="#" class="back-to-top" title="Back to top"><i class="fas fa-chevron-up"></i></a>
</section>
{/if}

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
