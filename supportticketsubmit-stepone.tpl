{*
    Department picker (submitticket.php, step 1).

    Stock rendered each department as a bold text link with an envelope
    glyph and the description as loose body copy beneath it, laid out
    in a Bootstrap two-column grid. The clickable area was the few
    words of the name only, and nothing framed one department from the
    next, so the page read as a paragraph rather than a choice.

    Here each department is a card and the whole card is the link, so
    the target is the full tile rather than the name text. Layout is a
    CSS grid that fits as many columns as the width allows (see
    .ho-dept-grid), which drops to one column on a phone on its own —
    no col-md-6 and no {if $num % 2} clearfix to keep in step with it.

    Every card carries the same icon rather than one picked per
    department: WHMCS has no icon field on a support department, and
    the names are admin-defined free text ("Sales", "General
    Enquiries", anything at all, in any language), so a guess keyed off
    the name would mislabel any department it failed to recognise.
*}
<div class="ho-dept-picker">

    <p class="ho-dept-intro">{$LANG.supportticketsheader}</p>

    <div class="ho-dept-grid">
        {foreach from=$departments key=num item=department}
            <a href="{$smarty.server.PHP_SELF}?step=2&amp;deptid={$department.id}" class="ho-dept-card">
                <span class="ho-dept-card-icon">
                    <i class="fas fa-headset"></i>
                </span>
                <span class="ho-dept-card-text">
                    <span class="ho-dept-card-name">{$department.name}</span>
                    {if $department.description}
                        <span class="ho-dept-card-desc">{$department.description}</span>
                    {/if}
                </span>
                <span class="ho-dept-card-go">
                    <i class="fas fa-arrow-right"></i>
                </span>
            </a>
        {foreachelse}
            {include file="$template/includes/alert.tpl" type="info" msg=$LANG.nosupportdepartments textcenter=true}
        {/foreach}
    </div>

</div>
