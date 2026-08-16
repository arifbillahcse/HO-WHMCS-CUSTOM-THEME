<?php
/**
 * Hostorio — product categories under Services for logged-in clients
 *
 * DEPLOYMENT: this file does NOT run from inside the theme. Copy it to
 * {WHMCS root}/includes/hooks/services-menu-categories.php on the
 * server — WHMCS only auto-loads hooks from that directory, never from
 * templates/<theme>/. It is committed here, in the theme repo, purely
 * so the source is version-controlled alongside the theme it serves.
 *
 * WHAT IT DOES: logged-out visitors see every hosting category under
 * "Store" (Web Hosting, VPS, Business Email, ...) because WHMCS builds
 * that dropdown from the live product-group list. Logged-in clients
 * only see "My Services / Order New Services / View Available Addons"
 * under "Services" instead — the same category list is not there. This
 * hook appends it, reading tblproductgroups directly so a category
 * added in Admin -> Products/Services -> Product Groups appears here
 * automatically, with no further edits.
 *
 * NOT LIVE-TESTED: everything else in this theme was verified by
 * actually rendering it through Smarty. This hook runs against WHMCS's
 * own PHP classes (WHMCS\View\Menu\Item, WHMCS\Database\Capsule), and
 * there is no WHMCS install available to run it against here, so this
 * could not be verified the same way. It is written defensively —
 * wrapped in try/catch, checks before every method call — specifically
 * so that if an assumption about that API is wrong on this WHMCS
 * version, the hook fails silently (the Services menu just looks as it
 * did before) rather than breaking the client area. If the categories
 * do not appear after deploying, check the WHMCS activity/error log
 * for "services-menu-categories" rather than assuming the site is
 * broken. Removing the file from includes/hooks/ instantly and safely
 * reverts this — it touches no database state.
 */

use WHMCS\Database\Capsule;

add_hook('ClientAreaPrimaryNavbar', 1, function ($primaryNavbar) {
    try {
        if (!is_object($primaryNavbar) || !method_exists($primaryNavbar, 'getChildren')) {
            return;
        }

        // Matched by label ('Services'), not by internal name. This
        // theme's other panel/menu fixes found more than once that the
        // internal getName() value is not the text WHMCS prints on
        // screen and is not safe to guess — the label is the one
        // thing confirmed directly from a real page.
        $servicesItem = null;
        foreach ($primaryNavbar->getChildren() as $item) {
            if (!method_exists($item, 'getLabel')) {
                continue;
            }
            if (strtolower(trim($item->getLabel())) === 'services') {
                $servicesItem = $item;
                break;
            }
        }

        if (!$servicesItem || !method_exists($servicesItem, 'addChild')) {
            return;
        }

        $groups = Capsule::table('tblproductgroups')
            ->where('hidden', 0)
            ->orderBy('order', 'asc')
            ->get();

        if (!$groups || !count($groups)) {
            return;
        }

        $itemClass = get_class($servicesItem);
        if (!method_exists($itemClass, 'create')) {
            return;
        }

        foreach ($groups as $group) {
            if (empty($group->name) || empty($group->id)) {
                continue;
            }

            $child = $itemClass::create()
                ->setLabel($group->name)
                ->setUri('cart.php?gid=' . (int) $group->id);

            $servicesItem->addChild($child);
        }
    } catch (\Throwable $e) {
        if (function_exists('logActivity')) {
            logActivity('services-menu-categories hook error: ' . $e->getMessage());
        }
    }
});
