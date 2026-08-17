{include file="$template/includes/tablelist.tpl" tableName="TicketsList" filterColumn="2"}
<script type="text/javascript">
    jQuery(document).ready( function ()
    {
        var table = jQuery('#tableTicketsList').removeClass('hidden').DataTable();
        {if $orderby == 'did' || $orderby == 'dept'}
            table.order(0, '{$sort}');
        {elseif $orderby == 'subject' || $orderby == 'title'}
            table.order(1, '{$sort}');
        {elseif $orderby == 'status'}
            table.order(2, '{$sort}');
        {elseif $orderby == 'lastreply'}
            table.order(3, '{$sort}');
        {/if}
        table.draw();
        jQuery('#tableLoading').addClass('hidden');
    });
</script>
<div class="table-container clearfix">
    <table id="tableTicketsList" class="table table-list hidden">
        <thead>
            <tr>
                <th>{$LANG.supportticketsdepartment}</th>
                <th>{$LANG.supportticketssubject}</th>
                <th>{$LANG.supportticketsstatus}</th>
                <th>{$LANG.supportticketsticketlastupdated}</th>
            </tr>
        </thead>
        <tbody>
            {foreach from=$tickets item=ticket}
                <tr onclick="window.location='viewticket.php?tid={$ticket.tid}&amp;c={$ticket.c}'">
                    <td>
                        {$ticket.department}
                    </td>
                    <td>
                        <a href="viewticket.php?tid={$ticket.tid}&amp;c={$ticket.c}" class="border-left">
                            {*
                                .ticket-unread-dot is added here, not part of
                                stock markup — bold subject text alone (the
                                only unread cue WHMCS renders) is easy to miss
                                scanning a list top to bottom; a dot in the
                                same position on every row is not. Styled in
                                hostorio-layout.css. "Unread" is a literal
                                string rather than a $LANG key: no existing
                                key covers this one-word tooltip, and none of
                                the WHMCS core language packs (including the
                                Bangla one this theme's switcher points at)
                                ship one to borrow instead.
                            *}
                            <span class="ticket-number">{if $ticket.unread}<span class="ticket-unread-dot" title="Unread"></span>{/if}#{$ticket.tid}</span>
                            <span class="ticket-subject{if $ticket.unread} unread{/if}">{$ticket.subject|escape}</span>
                        </a>
                    </td>
                    <td>
                        <span class="label status {if is_null($ticket.statusColor)}status-{$ticket.statusClass}"{else}status-custom" style="border-color: {$ticket.statusColor}; color: {$ticket.statusColor}"{/if}>
                            {$ticket.status|strip_tags}
                        </span>
                    </td>
                    <td class="text-center">
                        <span class="hidden">{$ticket.normalisedLastReply}</span>
                        {$ticket.lastreply}
                    </td>
                </tr>
            {/foreach}
        </tbody>
    </table>
    <div class="text-center" id="tableLoading">
        <p><i class="fas fa-spinner fa-spin"></i> {$LANG.loading}</p>
    </div>
</div>
