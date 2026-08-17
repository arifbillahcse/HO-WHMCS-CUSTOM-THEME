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
 *    automatically, with no further edits.
 *
 * 2. Applies a small set of per-item tweaks to the Services and
 *    Support dropdowns — see $navTweaks below. Hides "View Available
 *    Addons" (Services) and "Downloads" (Support); renames "Order New
 *    Services" to "Order Hosting". To add another later, add an entry
 *    under the right parent's label in $navTweaks; nothing else in
 *    this file needs to change.
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
        addProductCategories($servicesItem);

        // Parent label => tweaks applied to that parent's own children.
        // hideByName matches a child's exact, confirmed getName();
        // hideByLabel and renameByLabel match case-insensitively
        // against getLabel(), lower-cased, on the left of each pair.
        $navTweaks = [
            'services' => [
                'hideByName' => ['View Available Addons', 'Services Divider'],
                'renameByLabel' => [
                    'order new services' => 'Order Hosting',
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

    $itemClass = get_class($servicesItem);
    if (!method_exists($itemClass, 'create')) {
        if (function_exists('logActivity')) {
            logActivity('services-menu-categories: ' . $itemClass . '::create() not available — categories skipped');
        }
        return;
    }

    $added = 0;
    foreach ($groups as $group) {
        if (empty($group->name) || empty($group->id)) {
            continue;
        }

        $child = $itemClass::create()
            ->setLabel($group->name)
            ->setUri('cart.php?gid=' . (int) $group->id)
            ->setClass('ho-nav-category-item');

        $servicesItem->addChild($child);
        $added++;
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
