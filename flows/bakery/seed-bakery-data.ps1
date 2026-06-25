#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Seed demo data for Hempel Sweet Bakery: products, contacts, orders, and order lines.
.DESCRIPTION
    Idempotent — skips records that already exist by name.
    Run from the repo root: pwsh flows/bakery/seed-bakery-data.ps1
#>

$ErrorActionPreference = 'Stop'

$root = $PSScriptRoot
while ($root -and -not (Test-Path (Join-Path $root "helpers.psm1"))) {
    $root = Split-Path $root -Parent
}
if (-not $root) { throw "Cannot find helpers.psm1" }
Import-Module (Join-Path $root "helpers.psm1") -Force

$conn  = Get-DataverseHeaders -SolutionName "HempelSweetBakery" -EnvPath (Join-Path $root ".env")
$base  = $conn.BaseUrl
$hdrs  = $conn.Headers

function Upsert-Record {
    param([string]$Entity, [string]$IdField, [string]$FilterField, [string]$FilterValue, [hashtable]$Body)
    $encoded  = [System.Uri]::EscapeDataString($FilterValue)
    $existing = Invoke-RestMethod -Uri "$base/${Entity}?`$filter=$FilterField eq '$encoded'&`$select=$IdField" -Headers $hdrs
    if ($existing.value.Count -gt 0) {
        $id = $existing.value[0]."$IdField"
        Write-Host "  SKIP $Entity '$FilterValue' (exists: $id)" -ForegroundColor DarkGray
        return $id
    }
    $json = $Body | ConvertTo-Json -Depth 5
    $resp = Invoke-WebRequest -Method POST -Uri "$base/$Entity" -Headers $hdrs -Body $json -UseBasicParsing
    $id   = [regex]::Match($resp.Headers['OData-EntityId'], '[0-9a-f-]{36}').Value
    Write-Host "  CREATED $Entity '$FilterValue': $id" -ForegroundColor Green
    return $id
}

# ── 1. Products ──────────────────────────────────────────────────────────────
Write-Host "`n=== Products ===" -ForegroundColor Cyan
$products = @(
    @{ pda_name="Sourdough Loaf";     pda_category=100000000; pda_price=6.50;  pda_available=$true;  pda_allergens="gluten";          pda_dailystock=20; pda_description="Classic slow-fermented sourdough with a crispy crust." },
    @{ pda_name="Rye and Seed Loaf";   pda_category=100000000; pda_price=7.00;  pda_available=$true;  pda_allergens="gluten, seeds";    pda_dailystock=15; pda_description="Dense rye loaf packed with sunflower and pumpkin seeds." },
    @{ pda_name="Baguette";           pda_category=100000000; pda_price=3.50;  pda_available=$true;  pda_allergens="gluten";          pda_dailystock=30; pda_description="Traditional French-style baguette, baked twice daily." },
    @{ pda_name="Croissant";          pda_category=100000001; pda_price=4.00;  pda_available=$true;  pda_allergens="gluten, dairy, eggs"; pda_dailystock=25; pda_description="Buttery, flaky croissant. Best eaten warm." },
    @{ pda_name="Almond Danish";      pda_category=100000001; pda_price=4.50;  pda_available=$true;  pda_allergens="gluten, nuts, dairy, eggs"; pda_dailystock=20; pda_description="Puff pastry filled with almond cream and topped with flaked almonds." },
    @{ pda_name="Cinnamon Roll";      pda_category=100000001; pda_price=4.00;  pda_available=$true;  pda_allergens="gluten, dairy, eggs"; pda_dailystock=18; pda_description="Soft roll with cinnamon sugar filling and cream cheese glaze." },
    @{ pda_name="Birthday Cake";      pda_category=100000002; pda_price=35.00; pda_available=$true;  pda_allergens="gluten, dairy, eggs"; pda_dailystock=5;  pda_description="6-inch celebration cake with vanilla sponge and buttercream. Custom inscription available." },
    @{ pda_name="Chocolate Brownie";  pda_category=100000003; pda_price=3.50;  pda_available=$true;  pda_allergens="gluten, dairy, eggs"; pda_dailystock=40; pda_description="Fudgy dark chocolate brownie. Contains 70% cocoa." },
    @{ pda_name="Shortbread Cookies"; pda_category=100000003; pda_price=5.00;  pda_available=$true;  pda_allergens="gluten, dairy";   pda_dailystock=50; pda_description="Box of 6 melt-in-your-mouth butter shortbread cookies." },
    @{ pda_name="Flat White";         pda_category=100000004; pda_price=4.00;  pda_available=$true;  pda_allergens="dairy";           pda_dailystock=999; pda_description="Double-shot espresso with velvety steamed milk." }
)

$productIds = @{}
foreach ($p in $products) {
    $body = $p.Clone()
    $id = Upsert-Record -Entity "pda_products" -IdField "pda_productid" -FilterField "pda_name" -FilterValue $p.pda_name -Body $body
    $productIds[$p.pda_name] = $id
}

# ── 2. Contacts ──────────────────────────────────────────────────────────────
Write-Host "`n=== Contacts ===" -ForegroundColor Cyan
$contacts = @(
    @{ firstname="Emma";   lastname="Jensen";   emailaddress1="emma.jensen@demo.com";   mobilephone="+45 21 34 56 78" },
    @{ firstname="Lars";   lastname="Nielsen";  emailaddress1="lars.nielsen@demo.com";   mobilephone="+45 31 22 44 55" },
    @{ firstname="Sophie"; lastname="Andersen"; emailaddress1="sophie.andersen@demo.com"; mobilephone="+45 40 11 22 33" }
)

$contactIds = @{}
foreach ($c in $contacts) {
    $fullname = "$($c.firstname) $($c.lastname)"
    $existing = Invoke-RestMethod -Uri "$base/contacts?`$filter=emailaddress1 eq '$($c.emailaddress1)'&`$select=contactid" -Headers $hdrs
    if ($existing.value.Count -gt 0) {
        $id = $existing.value[0].contactid
        Write-Host "  SKIP contact '$fullname' (exists: $id)" -ForegroundColor DarkGray
    } else {
        $json = $c | ConvertTo-Json
        $resp = Invoke-WebRequest -Method POST -Uri "$base/contacts" -Headers $hdrs -Body $json -UseBasicParsing
        $id   = [regex]::Match($resp.Headers['OData-EntityId'], '[0-9a-f-]{36}').Value
        Write-Host "  CREATED contact '$fullname': $id" -ForegroundColor Green
    }
    $contactIds[$fullname] = $id
}

# ── 3. Orders + Lines ────────────────────────────────────────────────────────
Write-Host "`n=== Orders ===" -ForegroundColor Cyan

$now = (Get-Date).ToUniversalTime().ToString("o")

$ordersData = @(
    @{
        name      = "ORD-0001"
        contact   = "Emma Jensen"
        status    = 100000002   # Ready for Pickup
        fulfilment= 100000000   # Pickup
        pickupdate= "2026-06-02"
        total     = 0
        notes     = "Please slice the sourdough loaf."
        lines     = @(
            @{ product="Sourdough Loaf";     qty=2 },
            @{ product="Cinnamon Roll";      qty=3 },
            @{ product="Flat White";         qty=2 }
        )
    },
    @{
        name      = "ORD-0002"
        contact   = "Lars Nielsen"
        status    = 100000000   # Submitted
        fulfilment= 100000001   # Delivery
        pickupdate= "2026-06-03"
        total     = 0
        notes     = ""
        lines     = @(
            @{ product="Rye and Seed Loaf";   qty=1 },
            @{ product="Almond Danish";      qty=4 },
            @{ product="Shortbread Cookies"; qty=2 }
        )
    },
    @{
        name      = "ORD-0003"
        contact   = "Sophie Andersen"
        status    = 100000001   # Baking
        fulfilment= 100000000   # Pickup
        pickupdate= "2026-06-02"
        total     = 0
        notes     = "Nut allergy — please confirm no cross-contamination."
        lines     = @(
            @{ product="Birthday Cake";      qty=1 },
            @{ product="Croissant";          qty=6 },
            @{ product="Flat White";         qty=3 }
        )
    }
)

foreach ($o in $ordersData) {
    # Check if order exists
    $existingOrder = Invoke-RestMethod -Uri "$base/pda_orders?`$filter=pda_name eq '$($o.name)'&`$select=pda_orderid" -Headers $hdrs
    if ($existingOrder.value.Count -gt 0) {
        Write-Host "  SKIP order '$($o.name)'" -ForegroundColor DarkGray
        continue
    }

    $contactId = $contactIds[$o.contact]
    $orderBody = @{
        pda_name        = $o.name
        pda_orderdate   = $now
        pda_status      = $o.status
        pda_fulfilment  = $o.fulfilment
        pda_pickupdate  = $o.pickupdate
        pda_notes       = $o.notes
        "pda_CustomerId@odata.bind" = "/contacts($contactId)"
    }
    $json = $orderBody | ConvertTo-Json
    $resp = Invoke-WebRequest -Method POST -Uri "$base/pda_orders" -Headers $hdrs -Body $json -UseBasicParsing
    $orderId = [regex]::Match($resp.Headers['OData-EntityId'], '[0-9a-f-]{36}').Value
    Write-Host "  CREATED order '$($o.name)': $orderId" -ForegroundColor Green

    $orderTotal = 0.0
    foreach ($line in $o.lines) {
        $productId = $productIds[$line.product]
        # Get price from the product we just created
        $prodData = Invoke-RestMethod -Uri "$base/pda_products($productId)?`$select=pda_price" -Headers $hdrs
        $unitPrice = [double]$prodData.pda_price
        $lineTotal = [Math]::Round($unitPrice * $line.qty, 2)
        $orderTotal += $lineTotal

        $lineName = "$($line.qty)x $($line.product)"
        $lineBody = @{
            pda_name       = $lineName
            pda_quantity   = $line.qty
            pda_unitprice  = $unitPrice
            pda_linetotal  = $lineTotal
            "pda_OrderId@odata.bind"   = "/pda_orders($orderId)"
            "pda_ProductId@odata.bind" = "/pda_products($productId)"
        }
        $lineJson = $lineBody | ConvertTo-Json
        Invoke-RestMethod -Method POST -Uri "$base/pda_orderlines" -Headers $hdrs -Body $lineJson | Out-Null
        Write-Host "    + line '$lineName' @ $unitPrice × $($line.qty) = $lineTotal" -ForegroundColor Gray
    }

    # Patch total back onto the order
    $patchHeaders = $hdrs.Clone(); $patchHeaders["If-Match"] = "*"
    $patchBody = @{ pda_total = [Math]::Round($orderTotal, 2) } | ConvertTo-Json
    Invoke-RestMethod -Method PATCH -Uri "$base/pda_orders($orderId)" -Headers $patchHeaders -Body $patchBody | Out-Null
    Write-Host "  ORDER TOTAL: $([Math]::Round($orderTotal,2))" -ForegroundColor Cyan
}

Write-Host "`n✓ Seed data complete." -ForegroundColor Green
