<?php
/**
 * Hostorio — primary navbar tweaks for logged-in clients
 *
 * DEPLOYMENT: this file does NOT run from inside the theme. Copy it to
 * {WHMCS root}/includes/hooks/services-menu-categories.php on the
 * server — WHMCS only auto-loads hooks from that directory, never from
 * templates/<theme>/. It is committed here, in the theme repo, purely
 * so the source is version-controlled alongside the theme it serves.
 *
 * WHAT IT DOES, in order:
 *
 * 1. Logged-out visitors see every hosting category under "Store"
 *    (Web Hosting, VPS, Business Email, ...) because WHMCS builds that
 *    dropdown from the live product-group list. Logged-in clients only
 *    see "My Services / Order New Services / View Available Addons"
 *    under "Services" instead — the same category list is not there.
 *    Appends it, reading tblproductgroups directly so a category added
 *    in Admin -> Products/Services -> Product Groups appears here
 *    automatically, with no further edits. pinServicesTopItems() pins
 *    "My Services" (order=1) above these and removes "Order New
 *    Services" entirely (the category links below already cover
 *    ordering; nothing in the finished menu leaves an order=2 gap
 *    behind), and each category gets its own setOrder() (3, 4, 5, ...)
 *    in the same sequence as tblproductgroups.order (the admin-
 *    configured order) — without that, everything after "My Services"
 *    rendered alphabetically instead.
 *
 * 2. Applies a small set of per-item tweaks to the Services and
 *    Support dropdowns — see $navTweaks below. Hides "View Available
 *    Addons" (Services) and "Downloads" (Support). To add another
 *    later, add an entry under the right parent's label in $navTweaks;
 *    nothing else in this file needs to change. ("Order New Services"
 *    -> "Order/Add Services" used to be a $navTweaks renameByLabel
 *    entry too, but now happens inside pinServicesTopItems() /
 *    moveChildToFront() instead — see that function's own docblock
 *    for why.)
 *
 * 3. Renames "Home" itself to "Dashboard" on the primary navbar, and
 *    the account dropdown's "Hello, {name}!" to "Profile {name}!" on
 *    the secondary navbar — a separate WHMCS menu carrying Support,
 *    Open Ticket, and that greeting, built from its own
 *    ClientAreaSecondaryNavbar hook point.
 *
 * NOT LIVE-TESTED: everything else in this theme was verified by
 * actually rendering it through Smarty. This hook runs against WHMCS's
 * own PHP classes (WHMCS\View\Menu\Item, WHMCS\Database\Capsule), and
 * there is no WHMCS install available to run it against here, so this
 * could not be verified the same way. It is written defensively —
 * wrapped in try/catch, checks before every method call — specifically
 * so that if an assumption about that API is wrong on this WHMCS
 * version, the hook fails silently (the navbar just looks as it did
 * before) rather than breaking the client area. If a change does not
 * appear after deploying, check the WHMCS activity/error log for
 * "services-menu-categories" rather than assuming the site is broken.
 * Removing the file from includes/hooks/ instantly and safely reverts
 * this — it touches no database state.
 *
 * Every match below is against getLabel() (Services, Support, Downloads,
 * Order New Services) or a getName() value read directly from this
 * page's own rendered menuItemName="..." attribute (View Available
 * Addons) — never a guessed internal identifier. This theme's other
 * menu/panel fixes found more than once that the internal name is not
 * the text WHMCS prints on screen and is not safe to guess.
 */

use WHMCS\Database\Capsule;

add_hook('ClientAreaPrimaryNavbar', 1, function ($primaryNavbar) {
    try {
        if (!is_object($primaryNavbar) || !method_exists($primaryNavbar, 'getChildren')) {
            return;
        }

        $servicesItem = findChildByLabel($primaryNavbar, 'services');

        // Moves "My Services" (order=1) and "Order New Services" — given
        // its "Order/Add Services" rename right here rather than in
        // $navTweaks below, see moveChildToFront() — to the top, before
        // addProductCategories() appends the category links below them,
        // so the categories' own setOrder() calls (3, 4, 5, ...) start
        // after these two rather than colliding with them.
        pinServicesTopItems($servicesItem);
        addProductCategories($servicesItem);

        // "Home" itself, not a child of it — findChildByLabel() finds
        // the item, renameTopLevelByLabel() renames whatever matching
        // item it finds directly on $primaryNavbar.
        renameTopLevelByLabel($primaryNavbar, 'home', 'Dashboard');

        // Parent label => tweaks applied to that parent's own children.
        // hideByName matches a child's exact, confirmed getName();
        // hideByLabel and renameByLabel match case-insensitively
        // against getLabel(), lower-cased, on the left of each pair.
        //
        // No renameByLabel entry for "Order New Services" here — that
        // used to live in this list, but pinServicesTopItems() now
        // removes and re-adds that item under its new label directly
        // (see moveChildToFront() below), so by the time this list runs
        // there is no longer a child labeled "Order New Services" left
        // to match.
        $navTweaks = [
            'services' => [
                'hideByName' => ['View Available Addons', 'Services Divider'],
            ],
            'domains' => [
                'hideByName' => ['Domains Divider', 'Domains Divider 2', 'Domain Search'],
            ],
            'billing' => [
                'hideByName' => ['Billing Divider'],
            ],
            'support' => [
                'hideByLabel' => ['downloads'],
            ],
        ];

        foreach ($navTweaks as $parentLabel => $tweaks) {
            $parentItem = findChildByLabel($primaryNavbar, $parentLabel);
            if (!$parentItem) {
                continue;
            }
            applyNavTweaks($parentItem, $tweaks);
        }
    } catch (\Throwable $e) {
        if (function_exists('logActivity')) {
            logActivity('services-menu-categories hook error: ' . $e->getMessage());
        }
    }
});

// The "Hello, {name}!" account dropdown is a separate menu from
// Home/Services/Domains/Billing — WHMCS builds it from its own
// ClientAreaSecondaryNavbar hook point, alongside Support and Open
// Ticket.
add_hook('ClientAreaSecondaryNavbar', 1, function ($secondaryNavbar) {
    try {
        if (!is_object($secondaryNavbar) || !method_exists($secondaryNavbar, 'getChildren')) {
            return;
        }

        renameAccountGreeting($secondaryNavbar);
    } catch (\Throwable $e) {
        if (function_exists('logActivity')) {
            logActivity('services-menu-categories secondary-navbar hook error: ' . $e->getMessage());
        }
    }
});

/**
 * Renames a direct child of $navbar whose label matches $label,
 * case-insensitive — for items that are themselves the target
 * ("Home"), as opposed to applyNavTweaks() below, which renames
 * children of an already-found parent ("Order New Services" under
 * "Services").
 */
function renameTopLevelByLabel($navbar, $label, $newLabel)
{
    $item = findChildByLabel($navbar, $label);
    if ($item && method_exists($item, 'setLabel')) {
        $item->setLabel($newLabel);
    }
}

/**
 * WHMCS labels the account dropdown "Hello, {name}!" — the name is
 * per-user, so it cannot be matched as a fixed string the way every
 * other rename in this file is. Matches by the "Hello" lead-in
 * instead and swaps only that word for "Profile", keeping whatever
 * name WHMCS filled in: "Hello, Arif!" -> "Profile Arif!".
 */
function renameAccountGreeting($navbar)
{
    foreach ($navbar->getChildren() as $item) {
        if (!method_exists($item, 'getLabel') || !method_exists($item, 'setLabel')) {
            continue;
        }

        $label = trim($item->getLabel());
        if (stripos($label, 'hello') === 0) {
            $item->setLabel(preg_replace('/^hello,?\s*/i', 'Profile ', $label));
            return;
        }
    }
}

/**
 * Forces "My Services" to the very top of the Services dropdown, and
 * drops "Order New Services" ("Order/Add Services", after this file's
 * own rename) from the dropdown entirely — a direct request: the
 * client only wants a way to see what they already have, not a menu
 * entry for buying more, once the category links below already cover
 * ordering.
 *
 * REVISION: the first version of this function called setOrder(1) /
 * setOrder(2) directly on the two EXISTING stock items and left it at
 * that — setOrder() is real and documented
 * (developers.whmcs.com/themes/navigation/), but confirmed live
 * against an actual install (see the screenshot behind that commit),
 * it had no visible effect: both items still rendered AFTER every
 * category, in whatever position WHMCS's own core menu-building gave
 * them before this hook ever ran. The categories addProductCategories()
 * appends below, by contrast, DO land in the right relative order
 * (matching tblproductgroups.order) — the difference being that they
 * are built fresh via addChild() with setOrder() called on the brand
 * new item, never mutated after the fact. That points at WHMCS/KnpMenu
 * only consulting order at the moment a child is inserted into its
 * parent, not re-sorting the collection when an already-present
 * item's order is changed later.
 *
 * "My Services" acts on that: rather than reordering it in place, it
 * is removed and re-added as a fresh child — the same
 * addChild()-then-setOrder() sequence already proven to work for the
 * categories — carrying over its own uri/label/icon so nothing about
 * the link itself changes, only its position.
 *
 * "Order New Services" needs none of that, since removing it has no
 * position to get right — see removeChildByLabel() below.
 */
function pinServicesTopItems($servicesItem)
{
    if (!$servicesItem) {
        return;
    }

    moveChildToFront($servicesItem, 'my services', null, 1);
    removeChildByLabel($servicesItem, 'order new services');
}

/**
 * Removes $parentItem's child labeled $originalLabel (case-insensitive)
 * and re-adds it as a brand new child carrying the same uri/icon, an
 * explicit setOrder($order), and $newLabel if given (null keeps the
 * original label untouched — used for "My Services", which nothing
 * else in this file renames).
 *
 * Logs every branch, including success, the same way
 * addProductCategories() already does: the first version of this
 * pinning logic failed silently and left nothing in the Activity Log
 * to show whether it had even found its target, which is exactly the
 * gap this function closes for its own replacement.
 */
function moveChildToFront($parentItem, $originalLabel, $newLabel, $order)
{
    if (!method_exists($parentItem, 'getChildren') || !method_exists($parentItem, 'removeChild')
        || !method_exists($parentItem, 'addChild')) {
        if (function_exists('logActivity')) {
            logActivity("services-menu-categories: moveChildToFront('$originalLabel') skipped — parent item missing getChildren/removeChild/addChild");
        }
        return;
    }

    $original = findChildByLabel($parentItem, $originalLabel);
    if (!$original) {
        if (function_exists('logActivity')) {
            logActivity("services-menu-categories: moveChildToFront('$originalLabel') — no child matched this label, nothing moved");
        }
        return;
    }

    $name = method_exists($original, 'getName') ? $original->getName() : null;
    $uri = method_exists($original, 'getUri') ? $original->getUri() : null;
    $label = $newLabel !== null ? $newLabel : (method_exists($original, 'getLabel') ? $original->getLabel() : $originalLabel);
    $icon = (method_exists($original, 'hasIcon') && $original->hasIcon() && method_exists($original, 'getIcon'))
        ? $original->getIcon()
        : null;

    if (!$name || !$uri) {
        if (function_exists('logActivity')) {
            logActivity("services-menu-categories: moveChildToFront('$originalLabel') — matched child but getName()/getUri() came back empty, leaving it in place rather than risk removing it with nothing to re-add");
        }
        return;
    }

    try {
        $parentItem->removeChild($name);

        $newChild = $parentItem->addChild($name, [
            'label' => $label,
            'uri' => $uri,
        ]);

        if ($newChild && $icon && method_exists($newChild, 'setIcon')) {
            $newChild->setIcon($icon);
        }

        if ($newChild && method_exists($newChild, 'setOrder')) {
            $newChild->setOrder($order);
        }

        if (function_exists('logActivity')) {
            logActivity("services-menu-categories: moveChildToFront('$originalLabel') — re-added as '$label' at order $order");
        }
    } catch (\Throwable $e) {
        if (function_exists('logActivity')) {
            logActivity("services-menu-categories: moveChildToFront('$originalLabel') failed: " . $e->getMessage());
        }
    }
}

/**
 * Removes $parentItem's child labeled $label (case-insensitive) —
 * matched by getLabel(), the same convention every lookup in this
 * file uses, not a guessed internal name.
 *
 * Logs every branch for the same reason moveChildToFront() does: a
 * silent no-op here would look identical to "already removed" the
 * next time someone checks the live menu, with nothing in the
 * Activity Log to tell the two apart.
 */
function removeChildByLabel($parentItem, $label)
{
    if (!method_exists($parentItem, 'getChildren') || !method_exists($parentItem, 'removeChild')) {
        if (function_exists('logActivity')) {
            logActivity("services-menu-categories: removeChildByLabel('$label') skipped — parent item missing getChildren/removeChild");
        }
        return;
    }

    $child = findChildByLabel($parentItem, $label);
    if (!$child) {
        if (function_exists('logActivity')) {
            logActivity("services-menu-categories: removeChildByLabel('$label') — no child matched this label, nothing to remove");
        }
        return;
    }

    $name = method_exists($child, 'getName') ? $child->getName() : null;
    if (!$name) {
        if (function_exists('logActivity')) {
            logActivity("services-menu-categories: removeChildByLabel('$label') — matched child but getName() came back empty, leaving it in place rather than guess at an identifier to remove");
        }
        return;
    }

    try {
        $parentItem->removeChild($name);

        if (function_exists('logActivity')) {
            logActivity("services-menu-categories: removeChildByLabel('$label') — removed");
        }
    } catch (\Throwable $e) {
        if (function_exists('logActivity')) {
            logActivity("services-menu-categories: removeChildByLabel('$label') failed: " . $e->getMessage());
        }
    }
}

/**
 * First top-level child of $navbar whose label matches, case-insensitive.
 */
function findChildByLabel($navbar, $label)
{
    if (!method_exists($navbar, 'getChildren')) {
        return null;
    }
    foreach ($navbar->getChildren() as $item) {
        if (method_exists($item, 'getLabel') && strtolower(trim($item->getLabel())) === $label) {
            return $item;
        }
    }
    return null;
}

/**
 * Appends one child per row in tblproductgroups to $servicesItem,
 * tagged ho-nav-category-item — the CSS hook that draws the divider
 * between the stock Services children and these, in
 * css/hostorio-layout.css.
 */
function addProductCategories($servicesItem)
{
    // Each of these three used to return silently. Hiding and renaming
    // (removeChild(), setLabel()) were confirmed working on a real
    // install while categories still never appeared, which means one
    // of exactly these three guards is the cause — but a silent
    // return never reaches the try/catch in the caller, so it never
    // wrote anything to the Activity Log, and checking that log
    // taught us nothing. Logging each one directly is how we find out
    // which, instead of guessing a fourth time.
    if (!$servicesItem) {
        if (function_exists('logActivity')) {
            logActivity('services-menu-categories: Services item not found — findChildByLabel() did not match a top-level nav item labeled "services"');
        }
        return;
    }

    if (!method_exists($servicesItem, 'addChild')) {
        if (function_exists('logActivity')) {
            logActivity('services-menu-categories: addChild() not available on ' . get_class($servicesItem) . ' — categories skipped');
        }
        return;
    }

    $groups = Capsule::table('tblproductgroups')
        ->where('hidden', 0)
        ->orderBy('order', 'asc')
        ->get();

    if (!$groups || !count($groups)) {
        if (function_exists('logActivity')) {
            logActivity('services-menu-categories: tblproductgroups query returned 0 visible groups — categories skipped');
        }
        return;
    }

    // WHMCS\View\Menu\Item's constructor turned out to require a
    // Knp\Menu\FactoryInterface (confirmed via Reflection against a
    // real install — see git history for how that was found, since
    // this class ships ionCube-encoded and its source cannot be read
    // directly). That is not a WHMCS detail, it is KnpMenu itself:
    // WHMCS's menu system is built on knplabs/knp-menu, a public,
    // documented open-source library. There is no ::create() because
    // KnpMenu's own design never expects one — a factory is not
    // something calling code builds by hand.
    //
    // KnpMenu's actual convention is addChild($name, array $options),
    // called on the PARENT: the parent already holds a working
    // factory, and builds + returns the fully constructed child for
    // you. That is what runs below in place of the old
    // itemClass::create()->setLabel()->setUri()->setClass() chain,
    // which could never have worked — it never had a factory to give
    // the class it was trying to construct.
    $added = 0;
    // Starts at 3, not 2: order=1 is "My Services", pinned by
    // pinServicesTopItems() before this function runs. There is no
    // order=2 item any more — "Order New Services" used to hold that
    // slot before pinServicesTopItems() started removing it outright
    // — but categories still start one past "My Services" rather than
    // filling the gap, so a later change that brings order=2 back
    // does not have to touch this number too. Assigning 3, 4, 5, ...
    // here — in the same order this query already sorted the groups
    // (tblproductgroups.order ascending, the admin-configured order)
    // — is what fixes categories rendering alphabetically instead of
    // matching that order: see the comment on pinServicesTopItems()
    // for why setOrder() is needed at all rather than relying on
    // insertion order.
    $order = 3;
    foreach ($groups as $group) {
        if (empty($group->name) || empty($group->id)) {
            continue;
        }

        try {
            $child = $servicesItem->addChild($group->name, [
                'label' => $group->name,
                'uri' => 'cart.php?gid=' . (int) $group->id,
            ]);

            // setClass() is proven working (the Order Hosting rename
            // uses the same method, on a different item, on this same
            // install) — kept as a normal call, not another guarded
            // silent skip. ho-nav-category-item is the CSS hook that
            // draws the divider between the stock Services children
            // and these, in css/hostorio-layout.css.
            if ($child && method_exists($child, 'setClass')) {
                $child->setClass('ho-nav-category-item');
            }

            if ($child && method_exists($child, 'setOrder')) {
                $child->setOrder($order);
            }
            $order++;

            $added++;
        } catch (\Throwable $e) {
            if (function_exists('logActivity')) {
                logActivity('services-menu-categories: addChild("' . $group->name . '", ...) failed: ' . $e->getMessage());
            }
        }
    }

    if (function_exists('logActivity')) {
        logActivity("services-menu-categories: added $added categor" . ($added === 1 ? 'y' : 'ies') . ' under Services');
    }
}

/**
 * Applies hideByName / hideByLabel / renameByLabel (see $navTweaks
 * above) to $parentItem's own children.
 */
function applyNavTweaks($parentItem, $tweaks)
{
    if (!method_exists($parentItem, 'getChildren')) {
        return;
    }

    $hideByName = $tweaks['hideByName'] ?? [];
    $hideByLabel = $tweaks['hideByLabel'] ?? [];
    $renameByLabel = $tweaks['renameByLabel'] ?? [];

    foreach ($parentItem->getChildren() as $child) {
        if (!method_exists($child, 'getName') || !method_exists($child, 'getLabel')) {
            continue;
        }

        $label = strtolower(trim($child->getLabel()));

        if (in_array($child->getName(), $hideByName) || in_array($label, $hideByLabel)) {
            if (method_exists($parentItem, 'removeChild')) {
                $parentItem->removeChild($child->getName());
            }
            continue;
        }

        if (isset($renameByLabel[$label]) && method_exists($child, 'setLabel')) {
            $child->setLabel($renameByLabel[$label]);
        }
    }
}
