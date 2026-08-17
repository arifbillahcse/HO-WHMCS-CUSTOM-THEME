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
 *    "My Services" (order=1) and "Order New Services" (order=2) above
 *    these, and each category gets its own setOrder() (3, 4, 5, ...)
 *    in the same sequence as tblproductgroups.order (the admin-
 *    configured order) — without that, everything after the two
 *    pinned items rendered alphabetically instead.
 *
 * 2. Applies a small set of per-item tweaks to the Services and
 *    Support dropdowns — see $navTweaks below. Hides "View Available
 *    Addons" (Services) and "Downloads" (Support); renames "Order New
 *    Services" to "Order/Add Services". To add another later, add an
 *    entry under the right parent's label in $navTweaks; nothing else
 *    in this file needs to change.
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

        // Pins "My Services" (order=1) and "Order New Services" (order=2)
        // to the top before addProductCategories() appends the category
        // links below them — must run first so the categories' own
        // setOrder() calls (3, 4, 5, ...) start after these two, not
        // collide with them.
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
        $navTweaks = [
            'services' => [
                'hideByName' => ['View Available Addons', 'Services Divider'],
                'renameByLabel' => [
                    'order new services' => 'Order/Add Services',
                ],
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
 * Forces "My Services" and "Order New Services" to the very top of the
 * Services dropdown via setOrder() — a real, documented method on
 * WHMCS\View\Menu\Item (developers.whmcs.com/themes/navigation/), not
 * a guess. Needed because the product categories addProductCategories()
 * appends below were rendering ABOVE these two stock items and in
 * alphabetical order rather than the admin-configured
 * tblproductgroups.order — every child getting an explicit setOrder()
 * (these two here, the categories in addProductCategories()) pins the
 * final position outright instead of relying on whatever WHMCS falls
 * back to when no order is set.
 */
function pinServicesTopItems($servicesItem)
{
    if (!$servicesItem) {
        return;
    }

    $myServices = findChildByLabel($servicesItem, 'my services');
    if ($myServices && method_exists($myServices, 'setOrder')) {
        $myServices->setOrder(1);
    }

    // Matched by its original label — this runs before the
    // 'order new services' => 'Order/Add Services' rename in
    // $navTweaks, but setOrder() acts on the item object itself, so
    // the order sticks regardless of what the label becomes after.
    $orderServices = findChildByLabel($servicesItem, 'order new services');
    if ($orderServices && method_exists($orderServices, 'setOrder')) {
        $orderServices->setOrder(2);
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
    // 1 and 2 are reserved for "My Services" / "Order New Services",
    // pinned by pinServicesTopItems() before this function runs.
    // Assigning 3, 4, 5, ... here — in the same order this query
    // already sorted the groups (tblproductgroups.order ascending,
    // the admin-configured order) — is what fixes categories
    // rendering alphabetically instead of matching that order: see
    // the comment on pinServicesTopItems() for why setOrder() is
    // needed at all rather than relying on insertion order.
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
