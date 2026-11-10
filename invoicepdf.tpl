<?php

/**
 * Hostorio invoice PDF
 *
 * Redesigned from WHMCS's stock invoicepdf.tpl per a design review done
 * first as an HTML mockup (not guessed against this file directly,
 * since TCPDF has no live preview here to check coordinates against).
 * Everything that reads invoice DATA — the items loop, the tax rows,
 * the transactions loop (credit/debit notes, reference truncation),
 * the notes block — is untouched from stock, byte-for-byte: only
 * fonts/colours/layout changed, via the same $pdf (TCPDF) calls stock
 * already used. NOT LIVE-RENDERED against a real WHMCS+TCPDF install
 * (no instance available here) — generate a real test invoice after
 * deploying and check it; minor coordinate nudges may be needed once
 * it's seen on an actual PDF, same caution as
 * hooks/services-menu-categories.php's own docblock gives for its
 * unverified WHMCS API calls.
 *
 * Layout (all coordinates in mm, A4 portrait, 15mm side margins —
 * matching the Cell(180, ...) width stock already used, 210 - 15 - 15):
 *   - Logo top-left, company name/phone/email/address stacked below it
 *   - A bordered box top-right: invoice title, a small coloured status
 *     badge, then invoice/due dates — replacing stock's giant rotated
 *     ribbon with something that reads at a glance without tilting
 *     your head, while reusing its exact status->colour mapping
 *   - A full-width navy "Amount Due" band
 *   - Invoiced To, unboxed, directly below — same stock field logic
 *   - Items / Transaction Ledger tables, same stock PHP, rethemed
 *     colours only
 */

$marginX = 15;
$contentW = 180; // 210mm (A4) - 15mm - 15mm, same width stock's Cell(180, ...) calls already assumed.

$navy = [1, 37, 125];     // --ho-navy
$orange = [255, 120, 0];  // --ho-orange
$textMuted = [107, 114, 128];
$textLabel = [156, 163, 175];
$borderMuted = [229, 231, 235];

// Logo
$logoFilename = 'placeholder.png';
if (file_exists(ROOTDIR . '/assets/img/logo.png')) {
    $logoFilename = 'logo.png';
} elseif (file_exists(ROOTDIR . '/assets/img/logo.jpg')) {
    $logoFilename = 'logo.jpg';
} elseif (file_exists(ROOTDIR . '/assets/img/logo.jpeg')) {
    $logoFilename = 'logo.jpeg';
}
$pdf->Image(ROOTDIR . '/assets/img/' . $logoFilename, $marginX, 15, 58);

/**
 * Status badge colour, text and language key — lifted directly from
 * stock's own ribbon logic (same branches, same Lang::trans() keys),
 * only the drawing at the bottom swapped for a small rounded pill
 * instead of a full-width rotated banner.
 */
if ($status == 'Draft') {
    $statusFill = [200, 200, 200];
} elseif ($status == 'Paid') {
    $statusFill = [151, 223, 74];
} elseif ($status == 'Cancelled') {
    $statusFill = [200, 200, 200];
} elseif ($status == 'Refunded') {
    $statusFill = [131, 182, 218];
} elseif ($status == 'Collections') {
    $statusFill = [3, 3, 2];
} else {
    $statusFill = $orange;
}
if ($status == 'Payment Pending') {
    $statusLabel = strtoupper(Lang::trans('invoices' . str_replace(' ', '', $status)));
} else {
    $statusLabel = strtoupper(Lang::trans('invoices' . strtolower($status)));
}

// Company details — stacked under the logo, left-aligned (stock had
// these right-aligned, independent of the logo). $companyaddress is
// stock's own array of pre-formatted lines; untouched here.
$pdf->SetXY($marginX, 46);
$pdf->SetFont($pdfFont, 'B', 11);
$pdf->SetTextColor(31, 41, 55);
$pdf->Cell(110, 4.5, $companyname, 0, 1, 'L');
$pdf->SetFont($pdfFont, '', 9);
$pdf->SetTextColor($textMuted[0], $textMuted[1], $textMuted[2]);
foreach ($companyaddress as $addressLine) {
    $pdf->SetX($marginX);
    $pdf->Cell(110, 4.5, trim($addressLine), 0, 1, 'L');
}
if ($taxCode) {
    $pdf->SetX($marginX);
    $pdf->Cell(110, 4.5, $taxIdLabel . ': ' . trim($taxCode), 0, 1, 'L');
}

// Invoice meta box — bordered, top-right, same width class as the
// two-column tables below (75mm + 105mm doesn't need to match those;
// this box only needs to clear the company block on the left).
$boxX = 120;
$boxY = 15;
$boxW = $marginX + $contentW - $boxX; // flush with the same right edge the tables below use
$boxH = 46;

$pdf->SetDrawColor($borderMuted[0], $borderMuted[1], $borderMuted[2]);
$pdf->SetLineWidth(0.3);
$pdf->RoundedRect($boxX, $boxY, $boxW, $boxH, 2, '1111', 'D');

$pdf->SetXY($boxX + 6, $boxY + 6);
$pdf->SetFont($pdfFont, 'B', 13);
$pdf->SetTextColor($navy[0], $navy[1], $navy[2]);
$pdf->Cell($boxW - 12, 6, $pagetitle, 0, 1, 'L');

// Status badge, top-right corner of the box.
$badgeW = $pdf->GetStringWidth($statusLabel) + 10;
$pdf->SetFillColor($statusFill[0], $statusFill[1], $statusFill[2]);
$pdf->RoundedRect($boxX + $boxW - $badgeW - 6, $boxY + 6, $badgeW, 7, 3.5, '1111', 'F');
$pdf->SetXY($boxX + $boxW - $badgeW - 6, $boxY + 7.3);
$pdf->SetFont($pdfFont, 'B', 8);
$pdf->SetTextColor(255);
$pdf->Cell($badgeW, 4.5, $statusLabel, 0, 0, 'C');

$pdf->SetDrawColor($borderMuted[0], $borderMuted[1], $borderMuted[2]);
$pdf->Line($boxX + 6, $boxY + 19, $boxX + $boxW - 6, $boxY + 19);

$pdf->SetFont($pdfFont, '', 9);
$pdf->SetXY($boxX + 6, $boxY + 23);
$pdf->SetTextColor($textMuted[0], $textMuted[1], $textMuted[2]);
$pdf->Cell(($boxW - 12) / 2, 5, Lang::trans('invoicesdatecreated'), 0, 0, 'L');
$pdf->SetTextColor(31, 41, 55);
$pdf->Cell(($boxW - 12) / 2, 5, $datecreated, 0, 1, 'R');
$pdf->SetX($boxX + 6);
$pdf->SetTextColor($textMuted[0], $textMuted[1], $textMuted[2]);
$pdf->Cell(($boxW - 12) / 2, 5, Lang::trans('invoicesdatedue'), 0, 0, 'L');
$pdf->SetTextColor(31, 41, 55);
$pdf->Cell(($boxW - 12) / 2, 5, $duedate, 0, 1, 'R');

$pdf->SetTextColor(0);

// Amount Due band — full width, navy, below whichever of the logo
// column / meta box runs lower.
$bandY = max($pdf->GetY(), $boxY + $boxH) + 8;
$pdf->SetFillColor($navy[0], $navy[1], $navy[2]);
$pdf->RoundedRect($marginX, $bandY, $contentW, 22, 3, '1111', 'F');

$pdf->SetXY($marginX + 8, $bandY + 4);
$pdf->SetFont($pdfFont, 'B', 8);
$pdf->SetTextColor(255);
$pdf->Cell(100, 4, strtoupper(Lang::trans('invoicesbalance')), 0, 1, 'L');
$pdf->SetX($marginX + 8);
$pdf->SetFont($pdfFont, 'B', 18);
$pdf->Cell(100, 8, $invoiceamount, 0, 1, 'L');

$pdf->SetXY($marginX + $contentW - 80, $bandY + 5);
$pdf->SetFont($pdfFont, '', 8);
$pdf->Cell(72, 4, Lang::trans('invoicesdatedue'), 0, 1, 'R');
$pdf->SetX($marginX + $contentW - 80);
$pdf->SetFont($pdfFont, 'B', 10);
$pdf->Cell(72, 5, $duedate, 0, 1, 'R');

$pdf->SetTextColor(0);
$pdf->SetY($bandY + 22 + 8);

$startpage = $pdf->GetPage();

// Clients Details — same stock field logic (companyname/attn, address
// lines, tax id, custom fields), untouched; only the label above it
// is styled (small, muted, uppercase) instead of plain bold black.
$addressypos = $pdf->GetY();
$pdf->SetX($marginX);
$pdf->SetFont($pdfFont, 'B', 8);
$pdf->SetTextColor($textLabel[0], $textLabel[1], $textLabel[2]);
$pdf->Cell(0, 4, strtoupper(Lang::trans('invoicesinvoicedto')), 0, 1);
$pdf->SetTextColor(0);
$pdf->SetFont($pdfFont, 'B', 10);
$pdf->SetX($marginX);
if ($clientsdetails["companyname"]) {
    $pdf->Cell(0, 4.5, $clientsdetails["companyname"], 0, 1, 'L');
    $pdf->SetFont($pdfFont, '', 9);
    $pdf->SetX($marginX);
    $pdf->Cell(0, 4.5, Lang::trans('invoicesattn') . ': ' . $clientsdetails["firstname"] . ' ' . $clientsdetails["lastname"], 0, 1, 'L');
} else {
    $pdf->Cell(0, 4.5, $clientsdetails["firstname"] . " " . $clientsdetails["lastname"], 0, 1, 'L');
    $pdf->SetFont($pdfFont, '', 9);
}
$pdf->SetX($marginX);
$pdf->Cell(0, 4.5, $clientsdetails["address1"], 0, 1, 'L');
if ($clientsdetails["address2"]) {
    $pdf->SetX($marginX);
    $pdf->Cell(0, 4.5, $clientsdetails["address2"], 0, 1, 'L');
}
$pdf->SetX($marginX);
$pdf->Cell(0, 4.5, $clientsdetails["city"] . ", " . $clientsdetails["state"] . ", " . $clientsdetails["postcode"], 0, 1, 'L');
$pdf->SetX($marginX);
$pdf->Cell(0, 4.5, $clientsdetails["country"], 0, 1, 'L');
if (array_key_exists('tax_id', $clientsdetails) && $clientsdetails['tax_id']) {
    $pdf->SetX($marginX);
    $pdf->Cell(0, 4.5, $taxIdLabel . ': ' . $clientsdetails['tax_id'], 0, 1, 'L');
}
if ($customfields) {
    $pdf->Ln();
    foreach ($customfields as $customfield) {
        $pdf->SetX($marginX);
        $pdf->Cell(0, 4.5, $customfield['fieldname'] . ': ' . $customfield['value'], 0, 1, 'L');
    }
}
$pdf->Ln(8);

# QR Code — unchanged from stock.
if (!empty($invoiceQrHtml)) {
    $pdf->SetXY(15, $pdf->GetY() - 40);
    $pdf->writeHTML($invoiceQrHtml, true, false, false, false, '');
    $pdf->Ln(5);
}

# Invoice Items — same stock loop/variables; navy header + orange-tint
# total row instead of stock's flat grey, same convention the ledger
# table below also uses.
$tblhtml = '<table width="100%" cellspacing="0" cellpadding="3" border="0">
    <tr style="background-color:#01257D;font-weight:bold;color:#ffffff;">
        <td width="80%">' . Lang::trans('invoicesdescription') . '</td>
        <td width="20%" align="right">' . Lang::trans('quotelinetotal') . '</td>
    </tr>';
foreach ($invoiceitems as $item) {
    $tblhtml .= '
    <tr style="background-color:#ffffff;">
        <td align="left">' . nl2br($item['description']) . '<br /></td>
        <td align="right">' . $item['amount'] . '</td>
    </tr>';
}
$tblhtml .= '
    <tr style="background-color:#ffffff;color:#6b7280;">
        <td align="right">' . Lang::trans('invoicessubtotal') . '</td>
        <td align="right">' . $subtotal . '</td>
    </tr>';
if ($taxname) {
    $tblhtml .= '
    <tr style="background-color:#ffffff;color:#6b7280;">
        <td align="right">' . $taxrate . '% ' . $taxname . '</td>
        <td align="right">' . $tax . '</td>
    </tr>';
}
if ($taxname2) {
    $tblhtml .= '
    <tr style="background-color:#ffffff;color:#6b7280;">
        <td align="right">' . $taxrate2 . '% ' . $taxname2 . '</td>
        <td align="right">' . $tax2 . '</td>
    </tr>';
}
$tblhtml .= '
    <tr style="background-color:#FFF4EB;font-weight:bold;color:#01257D;">
        <td align="right">' . Lang::trans('invoicestotal') . '</td>
        <td align="right">' . $invoiceamount . '</td>
    </tr>
</table>';

$pdf->writeHTML($tblhtml, true, false, false, false, '');

$pdf->Ln(5);

# Transactions — same stock loop (credit/debit note labelling,
# reference truncation), styling only: smaller, muted, quiet relative
# to the items table above it.
$pdf->SetFont($pdfFont, 'B', 10);
$pdf->SetTextColor($textMuted[0], $textMuted[1], $textMuted[2]);
$pdf->SetX($marginX);
$pdf->Cell(0, 4, strtoupper(Lang::trans('billing.ledger.title')), 0, 1);
$pdf->SetTextColor(0);

$pdf->Ln(3);

$pdf->SetFont($pdfFont, '', 9);

$tblhtml = '<table width="100%" cellspacing="0" cellpadding="2" border="0">
    <tr style="color:#9ca3af;font-weight:bold;">
        <td width="15%">' . Lang::trans('billing.ledger.date') . '</td>
        <td width="30%">' . Lang::trans('billing.ledger.type') . '</td>
        <td width="35%">' . Lang::trans('billing.ledger.reference') . '</td>
        <td width="20%" align="right">' . Lang::trans('invoicestransamount') . '</td>
    </tr>';

if (!count($transactions)) {
    $tblhtml .= '
    <tr>
        <td colspan="4" align="center" style="color:#9ca3af;">' . Lang::trans('invoicestransnonefound') . '</td>
    </tr>';
} else {
    foreach ($transactions AS $trans) {
        $reference = $trans['referenceId'];

        if ($trans['isCreditNote']) {
            $reference = Lang::trans('billing.creditnote') . ' ' . $reference;
        } elseif ($trans['isDebitNote']) {
            $reference = Lang::trans('billing.debitnote') . ' ' . $reference;
        } elseif ($reference) {
            $maxLength = 36;
            if (strlen($reference) > $maxLength) {
                $ellipsis = '...';
                $half = floor(($maxLength - strlen($ellipsis)) / 2);
                $reference = substr($reference, 0, $half)
                    . $ellipsis
                    . substr($reference, -$half, $half);
            }
        }

        $reference = trim($reference);

        $tblhtml .= '
        <tr>
            <td align="left">' . $trans['date'] . '</td>
            <td align="left">' . ($trans['gateway'] ? $trans['gateway'] . ' &mdash; ' : '') . $trans['typeLabel'] . '</td>
            <td align="left">' . $reference . '</td>
            <td align="right">' . $trans['amount'] . '</td>
        </tr>';
    }
}
$tblhtml .= '
    <tr style="font-weight:bold;">
        <td colspan="3" align="right">' . Lang::trans('invoicesbalance') . '</td>
        <td align="right">' . $balance . '</td>
    </tr>
</table>';

$pdf->writeHTML($tblhtml, true, false, false, false, '');

# Notes — unchanged from stock.
if ($notes) {
    $pdf->Ln(5);
    $pdf->SetFont($pdfFont, '', 8);
    $pdf->MultiCell(170, 5, Lang::trans('invoicesnotes') . ': ' . $notes);
}

# Footer — thank-you line + generation date.
$pdf->Ln(8);
$pdf->SetDrawColor($borderMuted[0], $borderMuted[1], $borderMuted[2]);
$pdf->Line($marginX, $pdf->GetY(), $marginX + $contentW, $pdf->GetY());
$pdf->Ln(4);
$pdf->SetFont($pdfFont, '', 8);
$pdf->SetTextColor($textMuted[0], $textMuted[1], $textMuted[2]);
$pdf->Cell($contentW, 4, Lang::trans('invoicepdfgenerated') . ' ' . getTodaysDate(1), '', '', 'C');
$pdf->SetTextColor(0);

/**
 * Invoice footer
 */
