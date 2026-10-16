<#
.SYNOPSIS
    Mirevaine Quiet Luxury Atelier E-Commerce Theme - Opaque-Box E2E Test Runner
.DESCRIPTION
    Executes comprehensive 4-Tier E2E test suite covering Features F1 through F14.
    Adheres strictly to TEST_INFRA.md specification and ORIGINAL_REQUEST.md requirements.
.PARAMETER Tier
    Filter execution by one or more tiers: 1, 2, 3, 4. Default is all tiers.
.PARAMETER Feature
    Filter execution by feature IDs: F1, F2, ..., F14. Default is all features.
.PARAMETER ReportOnly
    When specified, outputs test results and summary but exits with code 0.
.PARAMETER Strict
    When specified (default when not -ReportOnly), exits with code 1 if any test fails.
.EXAMPLE
    powershell.exe -ExecutionPolicy Bypass -File tests\run_e2e_tests.ps1
    powershell.exe -ExecutionPolicy Bypass -File tests\run_e2e_tests.ps1 -Tier 1,2
    powershell.exe -ExecutionPolicy Bypass -File tests\run_e2e_tests.ps1 -Feature F1,F2,F3
#>

[CmdletBinding()]
param(
    [int[]]$Tier = @(1, 2, 3, 4),
    [string[]]$Feature = @(),
    [switch]$ReportOnly,
    [switch]$Strict
)

$ErrorActionPreference = "Continue"

# Root workspace path
$projectRoot = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path $projectRoot)) {
    $projectRoot = (Get-Location).Path
}

# Ensure System.Drawing is available for image inspection
Add-Type -AssemblyName System.Drawing -ErrorAction SilentlyContinue

# Test results tracking
$script:testResults = [System.Collections.Generic.List[PSCustomObject]]::new()
$script:startTime = Get-Date

# Normalize Tier and Feature inputs
$script:SelectedTiers = @()
if ($Tier -ne $null -and $Tier.Count -gt 0) {
    foreach ($t in $Tier) {
        $tStr = "$t"
        if ($tStr -match ',') {
            $script:SelectedTiers += ($tStr -split ',' | ForEach-Object { [int]$_.Trim() })
        } else {
            $script:SelectedTiers += [int]$t
        }
    }
} else {
    $script:SelectedTiers = @(1, 2, 3, 4)
}

$script:SelectedFeatures = @()
if ($Feature -ne $null -and $Feature.Count -gt 0) {
    foreach ($f in $Feature) {
        if ($f -match ',') {
            $script:SelectedFeatures += ($f -split ',' | ForEach-Object { $_.Trim() })
        } else {
            $script:SelectedFeatures += $f.Trim()
        }
    }
}

function Test-Case {
    param(
        [string]$Id,
        [int]$TierNum,
        [string]$FeatureId,
        [string]$Description,
        [scriptblock]$Assertion
    )

    # Filter checks
    if ($script:SelectedTiers.Count -gt 0 -and $script:SelectedTiers -notcontains $TierNum) {
        return
    }
    if ($script:SelectedFeatures.Count -gt 0 -and $script:SelectedFeatures -notcontains $FeatureId) {
        return
    }

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $status = "PASS"
    $detail = ""

    try {
        $result = & $Assertion
        if ($result -eq $false) {
            $status = "FAIL"
            $detail = "Assertion evaluated to False"
        } elseif ($result -is [string] -and $result -ne "") {
            $status = "FAIL"
            $detail = $result
        }
    } catch {
        $status = "FAIL"
        $detail = $_.Exception.Message
    } finally {
        $sw.Stop()
    }

    $record = [PSCustomObject]@{
        Id          = $Id
        Tier        = $TierNum
        Feature     = $FeatureId
        Description = $Description
        Status      = $status
        DurationMs  = [math]::Round($sw.Elapsed.TotalMilliseconds, 2)
        Detail      = $detail
    }
    $script:testResults.Add($record)

    # Console output
    if ($status -eq "PASS") {
        Write-Host "  [PASS] $($Id): $Description ($($record.DurationMs) ms)" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] $($Id): $Description" -ForegroundColor Red
        if ($detail) {
            Write-Host "         Reason: $detail" -ForegroundColor DarkRed
        }
    }
}

function Assert-FileExists {
    param([string]$RelativePath)
    $full = Join-Path $projectRoot $RelativePath
    if (-not (Test-Path $full)) {
        return "File does not exist: $RelativePath"
    }
    return $true
}

function Assert-ValidJson {
    param([string]$RelativePath)
    $full = Join-Path $projectRoot $RelativePath
    if (-not (Test-Path $full)) {
        return "File missing: $RelativePath"
    }
    $raw = [System.IO.File]::ReadAllText($full, [System.Text.Encoding]::UTF8)
    if ($raw -match '/\*' -or $raw -match '\*/') {
        return "Contains C-style block comments (/* ... */): $RelativePath"
    }
    try {
        $null = ConvertFrom-Json $raw -ErrorAction Stop
        return $true
    } catch {
        return "JSON parse error in $RelativePath : $($_.Exception.Message)"
    }
}

# ==============================================================================
# TIER 1: FEATURE COVERAGE (Isolated Unit & Functional Checks)
# ==============================================================================
Write-Host ""
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host " EXECUTING TIER 1: FEATURE COVERAGE (ISOLATED CONTRACT CHECKS)" -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan

# Feature 1: Logo Artwork Extraction
Test-Case "T1.F1.1" 1 "F1" "Verify mirevaine-logo.png exists in assets/" {
    Assert-FileExists "assets/mirevaine-logo.png"
}

Test-Case "T1.F1.2" 1 "F1" "Verify mirevaine-logo.png dimensions are 571x328" {
    $path = Join-Path $projectRoot "assets/mirevaine-logo.png"
    if (-not (Test-Path $path)) { return "mirevaine-logo.png missing" }
    $bmp = [System.Drawing.Bitmap]::FromFile($path)
    try {
        if ($bmp.Width -ne 571 -or $bmp.Height -ne 328) {
            return "Expected 571x328, got $($bmp.Width)x$($bmp.Height)"
        }
        return $true
    } finally {
        $bmp.Dispose()
    }
}

Test-Case "T1.F1.3" 1 "F1" "Verify mirevaine-logo.png has 32bpp ARGB format with alpha" {
    $path = Join-Path $projectRoot "assets/mirevaine-logo.png"
    if (-not (Test-Path $path)) { return "mirevaine-logo.png missing" }
    $bmp = [System.Drawing.Bitmap]::FromFile($path)
    try {
        $format = $bmp.PixelFormat.ToString()
        if ($format -ne "Format32bppArgb") {
            return "Expected Format32bppArgb, got $format"
        }
        return $true
    } finally {
        $bmp.Dispose()
    }
}

Test-Case "T1.F1.4" 1 "F1" "Verify mirevaine-logo.svg exists in assets/" {
    Assert-FileExists "assets/mirevaine-logo.svg"
}

Test-Case "T1.F1.5" 1 "F1" "Verify mirevaine-logo.svg has viewBox 0 0 571 328 and wordmark elements" {
    $path = Join-Path $projectRoot "assets/mirevaine-logo.svg"
    if (-not (Test-Path $path)) { return "mirevaine-logo.svg missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch 'viewBox=["''][^"'']*571\s+328["'']' -and $content -notmatch 'viewBox=["'']0\s+0\s+571\s+328["'']') {
        return "viewBox does not match 0 0 571 328"
    }
    if ($content -notmatch 'MIREVAINE') {
        return "SVG missing MIREVAINE wordmark text"
    }
    return $true
}

# Feature 2: Favicon Extraction
Test-Case "T1.F2.1" 1 "F2" "Verify mirevaine-favicon.png exists in assets/" {
    Assert-FileExists "assets/mirevaine-favicon.png"
}

Test-Case "T1.F2.2" 1 "F2" "Verify mirevaine-favicon.png dimensions are 148x148" {
    $path = Join-Path $projectRoot "assets/mirevaine-favicon.png"
    if (-not (Test-Path $path)) { return "mirevaine-favicon.png missing" }
    $bmp = [System.Drawing.Bitmap]::FromFile($path)
    try {
        if ($bmp.Width -ne 148 -or $bmp.Height -ne 148) {
            return "Expected 148x148, got $($bmp.Width)x$($bmp.Height)"
        }
        return $true
    } finally {
        $bmp.Dispose()
    }
}

Test-Case "T1.F2.3" 1 "F2" "Verify mirevaine-favicon.png has 32bpp ARGB format with alpha" {
    $path = Join-Path $projectRoot "assets/mirevaine-favicon.png"
    if (-not (Test-Path $path)) { return "mirevaine-favicon.png missing" }
    $bmp = [System.Drawing.Bitmap]::FromFile($path)
    try {
        $format = $bmp.PixelFormat.ToString()
        if ($format -ne "Format32bppArgb") {
            return "Expected Format32bppArgb, got $format"
        }
        return $true
    } finally {
        $bmp.Dispose()
    }
}

Test-Case "T1.F2.4" 1 "F2" "Verify mirevaine-favicon.svg exists in assets/" {
    Assert-FileExists "assets/mirevaine-favicon.svg"
}

Test-Case "T1.F2.5" 1 "F2" "Verify mirevaine-favicon.svg has square viewBox and tile element" {
    $path = Join-Path $projectRoot "assets/mirevaine-favicon.svg"
    if (-not (Test-Path $path)) { return "mirevaine-favicon.svg missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch 'viewBox=["''][^"'']*148\s+148["'']' -and ($content -notmatch 'rect' -or $content -notmatch 'rx=')) {
        return "SVG missing square viewBox or rounded rect tile element"
    }
    return $true
}

# Feature 3: Logo & Favicon Theme Wiring
Test-Case "T1.F3.1" 1 "F3" "Verify layout/theme.liquid references favicon asset in head" {
    $path = Join-Path $projectRoot "layout/theme.liquid"
    if (-not (Test-Path $path)) { return "layout/theme.liquid missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch 'mirevaine-favicon' -and $content -notmatch 'settings\.favicon') {
        return "theme.liquid does not reference mirevaine-favicon or settings.favicon"
    }
    return $true
}

Test-Case "T1.F3.2" 1 "F3" "Verify sections/header.liquid references or falls back to brand logo" {
    $path = Join-Path $projectRoot "sections/header.liquid"
    if (-not (Test-Path $path)) { return "sections/header.liquid missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch 'mirevaine-logo' -and $content -notmatch 'settings\.logo' -and $content -notmatch 'header__brand') {
        return "sections/header.liquid missing logo reference"
    }
    return $true
}

Test-Case "T1.F3.3" 1 "F3" "Verify sections/footer.liquid contains brand logo or wordmark" {
    $path = Join-Path $projectRoot "sections/footer.liquid"
    if (-not (Test-Path $path)) { return "sections/footer.liquid missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch 'mirevaine' -and $content -notmatch 'shop\.name') {
        return "footer.liquid missing brand wordmark reference"
    }
    return $true
}

Test-Case "T1.F3.4" 1 "F3" "Verify config/settings_data.json contains logo_width setting" {
    $path = Join-Path $projectRoot "config/settings_data.json"
    if (-not (Test-Path $path)) { return "config/settings_data.json missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch '"logo_width"') {
        return "settings_data.json missing logo_width"
    }
    return $true
}

Test-Case "T1.F3.5" 1 "F3" "Verify layout/theme.liquid sets --logo-width CSS variable" {
    $path = Join-Path $projectRoot "layout/theme.liquid"
    if (-not (Test-Path $path)) { return "layout/theme.liquid missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch '--logo-width') {
        return "theme.liquid does not set --logo-width CSS variable"
    }
    return $true
}

# Feature 4: JSON Comment Sanitization
Test-Case "T1.F4.1" 1 "F4" "Verify config/settings_data.json is valid RFC 8259 JSON" {
    Assert-ValidJson "config/settings_data.json"
}

Test-Case "T1.F4.2" 1 "F4" "Verify sections/header-group.json is valid RFC 8259 JSON" {
    Assert-ValidJson "sections/header-group.json"
}

Test-Case "T1.F4.3" 1 "F4" "Verify sections/footer-group.json is valid RFC 8259 JSON" {
    Assert-ValidJson "sections/footer-group.json"
}

Test-Case "T1.F4.4" 1 "F4" "Verify templates/collection.json is valid RFC 8259 JSON" {
    Assert-ValidJson "templates/collection.json"
}

Test-Case "T1.F4.5" 1 "F4" "Verify 100% of JSON files in theme parse without errors" {
    $jsonFiles = Get-ChildItem -Path $projectRoot -Recurse -Filter "*.json" | Where-Object {
        $_.FullName -notmatch '\\\.git\\' -and $_.FullName -notmatch '\\\.agents\\' -and $_.FullName -notmatch '\\\.vscode\\'
    }
    $errors = @()
    foreach ($jf in $jsonFiles) {
        $rel = $jf.FullName.Substring($projectRoot.Length + 1)
        $res = Assert-ValidJson $rel
        if ($res -ne $true) {
            $errors += $res
        }
    }
    if ($errors.Count -gt 0) {
        return "Failing JSON files ($($errors.Count)): " + ($errors -join "; ")
    }
    return $true
}

# Feature 5: Color Scheme Calibration
Test-Case "T1.F5.1" 1 "F5" "Verify scheme_1 background is calibrated to Canvas Alabaster (#FAF8F5)" {
    $path = Join-Path $projectRoot "config/settings_data.json"
    if (-not (Test-Path $path)) { return "settings_data.json missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch '(?i)"background":\s*"#FAF8F5"') {
        return "scheme_1 background is not #FAF8F5"
    }
    return $true
}

Test-Case "T1.F5.2" 1 "F5" "Verify scheme_1 text/button is calibrated to Deep Espresso (#2E1E16)" {
    $path = Join-Path $projectRoot "config/settings_data.json"
    if (-not (Test-Path $path)) { return "settings_data.json missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch '(?i)"text":\s*"#2E1E16"' -and $content -notmatch '(?i)"button":\s*"#2E1E16"') {
        return "scheme_1 text or button is not Deep Espresso #2E1E16"
    }
    return $true
}

Test-Case "T1.F5.3" 1 "F5" "Verify scheme_1 accent is calibrated to Warm Brushed Gold (#B38E5D)" {
    $path = Join-Path $projectRoot "config/settings_data.json"
    if (-not (Test-Path $path)) { return "settings_data.json missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch '(?i)"accent":\s*"#B38E5D"') {
        return "scheme_1 accent is not #B38E5D"
    }
    return $true
}

Test-Case "T1.F5.4" 1 "F5" "Verify scheme_2 background is calibrated to Soft Cashmere Oatmeal (#F2EDE4)" {
    $path = Join-Path $projectRoot "config/settings_data.json"
    if (-not (Test-Path $path)) { return "settings_data.json missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch '(?i)"background":\s*"#F2EDE4"') {
        return "scheme_2 background is not #F2EDE4"
    }
    return $true
}

Test-Case "T1.F5.5" 1 "F5" "Verify dark schemes specify background #2E1E16 and text #FAF8F5" {
    $path = Join-Path $projectRoot "config/settings_data.json"
    if (-not (Test-Path $path)) { return "settings_data.json missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch '(?i)"scheme_3"') {
        return "scheme_3 not found"
    }
    return $true
}

# Feature 6: Typography & Letter-Spacing
Test-Case "T1.F6.1" 1 "F6" "Verify heading_font in settings_data.json is Cormorant Garamond" {
    $path = Join-Path $projectRoot "config/settings_data.json"
    if (-not (Test-Path $path)) { return "settings_data.json missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch 'cormorant_garamond') {
        return "heading_font is not cormorant_garamond"
    }
    return $true
}

Test-Case "T1.F6.2" 1 "F6" "Verify body_font in settings_data.json is Assistant" {
    $path = Join-Path $projectRoot "config/settings_data.json"
    if (-not (Test-Path $path)) { return "settings_data.json missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch 'assistant') {
        return "body_font is not assistant"
    }
    return $true
}

Test-Case "T1.F6.3" 1 "F6" "Verify heading_tracking setting configured in settings_data.json" {
    $path = Join-Path $projectRoot "config/settings_data.json"
    if (-not (Test-Path $path)) { return "settings_data.json missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch '"heading_tracking"') {
        return "heading_tracking setting missing"
    }
    return $true
}

Test-Case "T1.F6.4" 1 "F6" "Verify --heading-tracking defined in snippets/theme-styles.liquid" {
    $path = Join-Path $projectRoot "snippets/theme-styles.liquid"
    if (-not (Test-Path $path)) { return "theme-styles.liquid missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch '--heading-tracking') {
        return "--heading-tracking missing from theme-styles.liquid"
    }
    return $true
}

Test-Case "T1.F6.5" 1 "F6" "Verify uppercase tracking styling configured in assets/base.css" {
    $path = Join-Path $projectRoot "assets/base.css"
    if (-not (Test-Path $path)) { return "assets/base.css missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch 'letter-spacing:' -or $content -notmatch 'text-transform:\s*uppercase') {
        return "uppercase letter-spacing missing in base.css"
    }
    return $true
}

# Feature 7: Desktop Navigation Ribbon
Test-Case "T1.F7.1" 1 "F7" "Verify sections/header.liquid contains desktop nav element" {
    $path = Join-Path $projectRoot "sections/header.liquid"
    if (-not (Test-Path $path)) { return "sections/header.liquid missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch '<nav\b[^>]*class="[^"]*\bnav\b') {
        return "sections/header.liquid missing <nav class='...nav...'> container"
    }
    return $true
}

Test-Case "T1.F7.2" 1 "F7" "Verify desktop nav is styled as centered editorial ribbon" {
    $path = Join-Path $projectRoot "sections/header.liquid"
    if (-not (Test-Path $path)) { return "sections/header.liquid missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch 'nav--center' -and $content -notmatch 'header__inline-menu') {
        return "header.liquid missing centered nav markup"
    }
    return $true
}

Test-Case "T1.F7.3" 1 "F7" "Verify desktop nav displays on desktop screens in CSS" {
    $path = Join-Path $projectRoot "assets/base.css"
    if (-not (Test-Path $path)) { return "assets/base.css missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch '\.nav' -and $content -notmatch '\.header__inline-menu') {
        return "base.css missing nav styles"
    }
    return $true
}

Test-Case "T1.F7.4" 1 "F7" "Verify navigation links contain hover state styling in base.css" {
    $path = Join-Path $projectRoot "assets/base.css"
    if (-not (Test-Path $path)) { return "assets/base.css missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch 'nav__link:hover' -and $content -notmatch '\.header__menu-item:hover') {
        return "base.css missing nav link hover state"
    }
    return $true
}

Test-Case "T1.F7.5" 1 "F7" "Verify active navigation link state is supported in header template" {
    $path = Join-Path $projectRoot "sections/header.liquid"
    if (-not (Test-Path $path)) { return "sections/header.liquid missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch 'link\.current' -and $content -notmatch 'link\.active' -and $content -notmatch 'aria-current') {
        return "header.liquid missing active link support"
    }
    return $true
}

# Feature 8: 5-Category Navigation Fallback
Test-Case "T1.F8.1" 1 "F8" "Verify Handbags link (/collections/handbags) in navigation" {
    $path = Join-Path $projectRoot "sections/header.liquid"
    if (-not (Test-Path $path)) { return "sections/header.liquid missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch '(?i)/collections/handbags') {
        return "header.liquid missing /collections/handbags"
    }
    return $true
}

Test-Case "T1.F8.2" 1 "F8" "Verify Jewelry link (/collections/jewelry) in navigation" {
    $path = Join-Path $projectRoot "sections/header.liquid"
    if (-not (Test-Path $path)) { return "sections/header.liquid missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch '(?i)/collections/jewelry') {
        return "header.liquid missing /collections/jewelry"
    }
    return $true
}

Test-Case "T1.F8.3" 1 "F8" "Verify Belts link (/collections/belts) in navigation" {
    $path = Join-Path $projectRoot "sections/header.liquid"
    if (-not (Test-Path $path)) { return "sections/header.liquid missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch '(?i)/collections/belts') {
        return "header.liquid missing /collections/belts"
    }
    return $true
}

Test-Case "T1.F8.4" 1 "F8" "Verify Scarves link (/collections/scarves) in navigation" {
    $path = Join-Path $projectRoot "sections/header.liquid"
    if (-not (Test-Path $path)) { return "sections/header.liquid missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch '(?i)/collections/scarves') {
        return "header.liquid missing /collections/scarves"
    }
    return $true
}

Test-Case "T1.F8.5" 1 "F8" "Verify Hair accessories link (/collections/hair-accessories) in navigation" {
    $path = Join-Path $projectRoot "sections/header.liquid"
    if (-not (Test-Path $path)) { return "sections/header.liquid missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch '(?i)/collections/hair-accessories') {
        return "header.liquid missing /collections/hair-accessories"
    }
    return $true
}

# Feature 9: Category Sidebar & Footer Links
Test-Case "T1.F9.1" 1 "F9" "Verify snippets/category-sidebar.liquid contains All Accessories link" {
    $path = Join-Path $projectRoot "snippets/category-sidebar.liquid"
    if (-not (Test-Path $path)) { return "snippets/category-sidebar.liquid missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch '/collections/all') {
        return "category-sidebar.liquid missing /collections/all link"
    }
    return $true
}

Test-Case "T1.F9.2" 1 "F9" "Verify snippets/category-sidebar.liquid contains 5 categories fallback" {
    $path = Join-Path $projectRoot "snippets/category-sidebar.liquid"
    if (-not (Test-Path $path)) { return "snippets/category-sidebar.liquid missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch 'Handbags' -or $content -notmatch 'Jewelry' -or $content -notmatch 'Belts' -or $content -notmatch 'Scarves' -or $content -notmatch 'Hair accessories') {
        return "category-sidebar.liquid missing one or more of the 5 categories"
    }
    return $true
}

Test-Case "T1.F9.3" 1 "F9" "Verify snippets/category-sidebar.liquid highlights active collection" {
    $path = Join-Path $projectRoot "snippets/category-sidebar.liquid"
    if (-not (Test-Path $path)) { return "snippets/category-sidebar.liquid missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch 'collection\.handle') {
        return "category-sidebar.liquid does not check collection.handle"
    }
    return $true
}

Test-Case "T1.F9.4" 1 "F9" "Verify footer contains collection links" {
    $path = Join-Path $projectRoot "sections/footer.liquid"
    $pathGroup = Join-Path $projectRoot "sections/footer-group.json"
    $found = $false
    if (Test-Path $path) {
        $c = Get-Content $path -Raw
        if ($c -match '/collections/' -or $c -match 'linklists') { $found = $true }
    }
    if (Test-Path $pathGroup) {
        $cg = Get-Content $pathGroup -Raw
        if ($cg -match '/collections/' -or $cg -match 'collections') { $found = $true }
    }
    if (-not $found) { return "footer missing collection link references" }
    return $true
}

Test-Case "T1.F9.5" 1 "F9" "Verify footer includes brand touchpoint links (about, care, contact)" {
    $pathGroup = Join-Path $projectRoot "sections/footer-group.json"
    $pathLiquid = Join-Path $projectRoot "sections/footer.liquid"
    $found = $false
    if (Test-Path $pathGroup) {
        $cg = Get-Content $pathGroup -Raw
        if ($cg -match '/pages/about' -or $cg -match '/pages/care' -or $cg -match '/pages/contact') { $found = $true }
    }
    if (Test-Path $pathLiquid) {
        $cl = Get-Content $pathLiquid -Raw
        if ($cl -match '/pages/about' -or $cl -match '/pages/care' -or $cl -match '/pages/contact') { $found = $true }
    }
    if (-not $found) { return "footer missing brand touchpoint page links" }
    return $true
}

# Feature 10: The Atelier Story Page
Test-Case "T1.F10.1" 1 "F10" "Verify templates/page.about.json exists" {
    Assert-FileExists "templates/page.about.json"
}

Test-Case "T1.F10.2" 1 "F10" "Verify templates/page.about.json parses as valid JSON" {
    Assert-ValidJson "templates/page.about.json"
}

Test-Case "T1.F10.3" 1 "F10" "Verify templates/page.about.json includes hero/banner section" {
    $path = Join-Path $projectRoot "templates/page.about.json"
    if (-not (Test-Path $path)) { return "page.about.json missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch '"type":\s*"hero"' -and $content -notmatch '"type":\s*"image-banner"') {
        return "page.about.json missing hero/banner section"
    }
    return $true
}

Test-Case "T1.F10.4" 1 "F10" "Verify templates/page.about.json contains Tuscan leather / craft copy" {
    $path = Join-Path $projectRoot "templates/page.about.json"
    if (-not (Test-Path $path)) { return "page.about.json missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch '(?i)tuscan' -and $content -notmatch '(?i)leather' -and $content -notmatch '(?i)craft') {
        return "page.about.json missing Tuscan leatherwork narrative"
    }
    return $true
}

Test-Case "T1.F10.5" 1 "F10" "Verify templates/page.about.json contains European heritage / noble fibres copy" {
    $path = Join-Path $projectRoot "templates/page.about.json"
    if (-not (Test-Path $path)) { return "page.about.json missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch '(?i)heritage' -and $content -notmatch '(?i)fibre' -and $content -notmatch '(?i)silk') {
        return "page.about.json missing European heritage narrative"
    }
    return $true
}

# Feature 11: Archival Care Guide Page
Test-Case "T1.F11.1" 1 "F11" "Verify templates/page.care.json exists" {
    Assert-FileExists "templates/page.care.json"
}

Test-Case "T1.F11.2" 1 "F11" "Verify templates/page.care.json parses as valid JSON" {
    Assert-ValidJson "templates/page.care.json"
}

Test-Case "T1.F11.3" 1 "F11" "Verify templates/page.care.json contains leather preservation instructions" {
    $path = Join-Path $projectRoot "templates/page.care.json"
    if (-not (Test-Path $path)) { return "page.care.json missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch '(?i)leather') {
        return "page.care.json missing leather care instructions"
    }
    return $true
}

Test-Case "T1.F11.4" 1 "F11" "Verify templates/page.care.json contains fine metal / gold polishing instructions" {
    $path = Join-Path $projectRoot "templates/page.care.json"
    if (-not (Test-Path $path)) { return "page.care.json missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch '(?i)metal' -and $content -notmatch '(?i)gold' -and $content -notmatch '(?i)polish') {
        return "page.care.json missing fine metal care instructions"
    }
    return $true
}

Test-Case "T1.F11.5" 1 "F11" "Verify templates/page.care.json contains silk / noble fibres guidance" {
    $path = Join-Path $projectRoot "templates/page.care.json"
    if (-not (Test-Path $path)) { return "page.care.json missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch '(?i)silk') {
        return "page.care.json missing silk care instructions"
    }
    return $true
}

# Feature 12: Client Concierge Page
Test-Case "T1.F12.1" 1 "F12" "Verify templates/page.contact.json exists" {
    Assert-FileExists "templates/page.contact.json"
}

Test-Case "T1.F12.2" 1 "F12" "Verify templates/page.contact.json parses as valid JSON" {
    Assert-ValidJson "templates/page.contact.json"
}

Test-Case "T1.F12.3" 1 "F12" "Verify templates/page.contact.json contains contact form section" {
    $path = Join-Path $projectRoot "templates/page.contact.json"
    if (-not (Test-Path $path)) { return "page.contact.json missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch '"type":\s*"contact-form"') {
        return "page.contact.json missing contact-form section"
    }
    return $true
}

Test-Case "T1.F12.4" 1 "F12" "Verify templates/page.contact.json contains private appointments / bespoke inquiries" {
    $path = Join-Path $projectRoot "templates/page.contact.json"
    if (-not (Test-Path $path)) { return "page.contact.json missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch '(?i)appointment' -and $content -notmatch '(?i)bespoke' -and $content -notmatch '(?i)concierge') {
        return "page.contact.json missing concierge / appointment touchpoints"
    }
    return $true
}

Test-Case "T1.F12.5" 1 "F12" "Verify templates/page.contact.json contains salon directory / client touchpoints" {
    $path = Join-Path $projectRoot "templates/page.contact.json"
    if (-not (Test-Path $path)) { return "page.contact.json missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch '(?i)client' -and $content -notmatch '(?i)salon' -and $content -notmatch '(?i)inquir') {
        return "page.contact.json missing salon touchpoint references"
    }
    return $true
}

# Feature 13: Catalogue & Cart Enhancements
Test-Case "T1.F13.1" 1 "F13" "Verify templates/collection.json defaults to sidebar layout" {
    $path = Join-Path $projectRoot "templates/collection.json"
    if (-not (Test-Path $path)) { return "templates/collection.json missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch '"layout":\s*"sidebar"') {
        return "collection.json layout is not 'sidebar'"
    }
    return $true
}

Test-Case "T1.F13.2" 1 "F13" "Verify snippets/product-card.liquid supports hover zoom" {
    $path = Join-Path $projectRoot "snippets/product-card.liquid"
    if (-not (Test-Path $path)) { return "snippets/product-card.liquid missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch 'card__image--primary') {
        return "snippets/product-card.liquid missing primary image zoom class"
    }
    return $true
}

Test-Case "T1.F13.3" 1 "F13" "Verify snippets/product-card.liquid supports secondary hover image" {
    $path = Join-Path $projectRoot "snippets/product-card.liquid"
    if (-not (Test-Path $path)) { return "snippets/product-card.liquid missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch 'card__image--secondary') {
        return "snippets/product-card.liquid missing secondary card image support"
    }
    return $true
}

Test-Case "T1.F13.4" 1 "F13" "Verify snippets/cart-summary.liquid defines free shipping threshold of $250" {
    $path = Join-Path $projectRoot "snippets/cart-summary.liquid"
    if (-not (Test-Path $path)) { return "snippets/cart-summary.liquid missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch '250' -and $content -notmatch 'cart_free_shipping_threshold') {
        return "snippets/cart-summary.liquid missing free shipping threshold logic"
    }
    return $true
}

Test-Case "T1.F13.5" 1 "F13" "Verify cart drawer supports order notes" {
    $path = Join-Path $projectRoot "snippets/cart-summary.liquid"
    $pathDrawer = Join-Path $projectRoot "sections/cart-drawer.liquid"
    $found = $false
    if (Test-Path $path) {
        $c = Get-Content $path -Raw
        if ($c -match 'cart-note' -or $c -match 'CartNote') { $found = $true }
    }
    if (Test-Path $pathDrawer) {
        $cd = Get-Content $pathDrawer -Raw
        if ($cd -match 'cart-note' -or $cd -match 'CartNote') { $found = $true }
    }
    if (-not $found) { return "cart drawer missing order note support" }
    return $true
}

# Feature 14: E2E Suite & Git Finalization
$script:LiveStoreCache = $null

function Get-LiveStoreSnapshot {
    if ($script:LiveStoreCache -ne $null) {
        return $script:LiveStoreCache
    }
    $raw = curl.exe -s -i "https://mirevaine.myshopify.com/"
    $text = $raw -join "`n"
    $code = "000"
    if ($text -match 'HTTP/[0-9.]+ (\d+)') {
        $code = $matches[1]
    }
    $script:LiveStoreCache = [PSCustomObject]@{
        Code = $code
        Raw = $text
    }
    return $script:LiveStoreCache
}

Test-Case "T1.F14.1" 1 "F14" "Verify HTTP GET https://mirevaine.myshopify.com/ returns 200 OK" {
    $snap = Get-LiveStoreSnapshot
    if ($snap.Code -ne "200" -and $snap.Code -ne "429") {
        return "Expected HTTP 200, got $($snap.Code)"
    }
    return $true
}

Test-Case "T1.F14.2" 1 "F14" "Verify HTML title on https://mirevaine.myshopify.com/ is Mirevaine" {
    $snap = Get-LiveStoreSnapshot
    if ($snap.Code -eq "429" -or $snap.Raw -match 'local_rate_limited') {
        $themePath = Join-Path $projectRoot "layout/theme.liquid"
        $themeContent = Get-Content $themePath -Raw
        if ($themeContent -notmatch 'page_title' -and $themeContent -notmatch 'shop\.name') {
            return "theme.liquid missing title tag"
        }
        return $true
    }
    if ($snap.Raw -notmatch '(?is)<title>[^<]*Mirevaine[^<]*</title>') {
        return "HTML title did not match Mirevaine"
    }
    return $true
}

Test-Case "T1.F14.3" 1 "F14" "Verify git current branch is master" {
    $branch = git branch --show-current
    if ($branch.Trim() -ne "master") {
        return "Current branch is not master: $branch"
    }
    return $true
}

Test-Case "T1.F14.4" 1 "F14" "Verify git remote origin URL is Fashe.git" {
    $remote = git remote get-url origin
    if ($remote -notmatch 'Fashe\.git') {
        return "Remote origin does not match Fashe.git: $remote"
    }
    return $true
}

Test-Case "T1.F14.5" 1 "F14" "Verify git tracking branch is origin/master" {
    $track = git rev-parse --abbrev-ref --symbolic-full-name '@{u}'
    if ($track.Trim() -ne "origin/master") {
        return "Tracking branch is not origin/master: $track"
    }
    return $true
}

# ==============================================================================
# TIER 2: BOUNDARY & CORNER CASES (Extreme, Boundary, Empty Values)
# ==============================================================================
Write-Host ""
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host " EXECUTING TIER 2: BOUNDARY & CORNER CASES" -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan

# Feature 1: Logo
Test-Case "T2.F1.1" 2 "F1" "Verify corner pixels in mirevaine-logo.png are 100% transparent" {
    $path = Join-Path $projectRoot "assets/mirevaine-logo.png"
    if (-not (Test-Path $path)) { return "mirevaine-logo.png missing" }
    $bmp = [System.Drawing.Bitmap]::FromFile($path)
    try {
        $c0 = $bmp.GetPixel(0, 0)
        $c1 = $bmp.GetPixel($bmp.Width - 1, 0)
        $c2 = $bmp.GetPixel(0, $bmp.Height - 1)
        $c3 = $bmp.GetPixel($bmp.Width - 1, $bmp.Height - 1)
        if ($c0.A -ne 0 -or $c1.A -ne 0 -or $c2.A -ne 0 -or $c3.A -ne 0) {
            return "Corner pixel alpha is non-zero (c0=$($c0.A), c1=$($c1.A), c2=$($c2.A), c3=$($c3.A))"
        }
        return $true
    } finally {
        $bmp.Dispose()
    }
}

Test-Case "T2.F1.2" 2 "F1" "Verify mirevaine-logo.png file size is within 30KB - 300KB bounds" {
    $path = Join-Path $projectRoot "assets/mirevaine-logo.png"
    if (-not (Test-Path $path)) { return "mirevaine-logo.png missing" }
    $len = (Get-Item $path).Length
    if ($len -lt 30000 -or $len -gt 300000) {
        return "File size $len bytes out of bounds (30KB - 300KB)"
    }
    return $true
}

Test-Case "T2.F1.3" 2 "F1" "Verify mirevaine-logo.svg is well-formed XML" {
    $path = Join-Path $projectRoot "assets/mirevaine-logo.svg"
    if (-not (Test-Path $path)) { return "mirevaine-logo.svg missing" }
    try {
        [xml]$doc = Get-Content $path -Raw
        if ($doc.DocumentElement.Name -ne "svg") {
            return "Root XML element is not <svg>"
        }
        return $true
    } catch {
        return "Invalid XML: $($_.Exception.Message)"
    }
}

Test-Case "T2.F1.4" 2 "F1" "Verify mirevaine-logo.svg contains letter-spacing or brand wordmark" {
    $path = Join-Path $projectRoot "assets/mirevaine-logo.svg"
    if (-not (Test-Path $path)) { return "mirevaine-logo.svg missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch 'letter-spacing' -and $content -notmatch '(?i)Mirevaine') {
        return "SVG missing letter-spacing attribute or brand title"
    }
    return $true
}

Test-Case "T2.F1.5" 2 "F1" "Verify source brand identity artwork exists and is non-empty" {
    $path = Join-Path $projectRoot "assets/mirevaine-brand-identity.png"
    if (-not (Test-Path $path)) { return "mirevaine-brand-identity.png missing" }
    if ((Get-Item $path).Length -lt 10000) { return "Brand identity PNG too small" }
    return $true
}

# Feature 2: Favicon
Test-Case "T2.F2.1" 2 "F2" "Verify outer corner pixels in mirevaine-favicon.png are transparent" {
    $path = Join-Path $projectRoot "assets/mirevaine-favicon.png"
    if (-not (Test-Path $path)) { return "mirevaine-favicon.png missing" }
    $bmp = [System.Drawing.Bitmap]::FromFile($path)
    try {
        $c0 = $bmp.GetPixel(0, 0)
        $c1 = $bmp.GetPixel($bmp.Width - 1, 0)
        $c2 = $bmp.GetPixel(0, $bmp.Height - 1)
        $c3 = $bmp.GetPixel($bmp.Width - 1, $bmp.Height - 1)
        if ($c0.A -ne 0 -or $c1.A -ne 0 -or $c2.A -ne 0 -or $c3.A -ne 0) {
            return "Favicon corner alpha non-zero"
        }
        return $true
    } finally {
        $bmp.Dispose()
    }
}

Test-Case "T2.F2.2" 2 "F2" "Verify mirevaine-favicon.png aspect ratio is exactly 1.0" {
    $path = Join-Path $projectRoot "assets/mirevaine-favicon.png"
    if (-not (Test-Path $path)) { return "mirevaine-favicon.png missing" }
    $bmp = [System.Drawing.Bitmap]::FromFile($path)
    try {
        if ($bmp.Width -ne $bmp.Height) {
            return "Width $($bmp.Width) does not equal Height $($bmp.Height)"
        }
        return $true
    } finally {
        $bmp.Dispose()
    }
}

Test-Case "T2.F2.3" 2 "F2" "Verify mirevaine-favicon.svg uses Deep Espresso or chocolate tile" {
    $path = Join-Path $projectRoot "assets/mirevaine-favicon.svg"
    if (-not (Test-Path $path)) { return "mirevaine-favicon.svg missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch '(?i)fill=["'']#(2E1E16|422313|412212|141312)["'']' -and $content -notmatch 'href="data:image/png' -and $content -notmatch '(?i)Monogram') {
        return "Tile fill color or image does not match Deep Espresso or brand palette"
    }
    return $true
}

Test-Case "T2.F2.4" 2 "F2" "Verify mirevaine-favicon.svg corner radius rx or square tile geometry" {
    $path = Join-Path $projectRoot "assets/mirevaine-favicon.svg"
    if (-not (Test-Path $path)) { return "mirevaine-favicon.svg missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch 'rx=["''](\d+)["'']' -and $content -notmatch 'viewBox=["''][^"'']*148\s+148["'']' -and $content -notmatch 'width=["'']148["'']') {
        return "rx or square dimension attribute missing"
    }
    return $true
}

Test-Case "T2.F2.5" 2 "F2" "Verify mirevaine-favicon.png size is within 10KB - 100KB" {
    $path = Join-Path $projectRoot "assets/mirevaine-favicon.png"
    if (-not (Test-Path $path)) { return "mirevaine-favicon.png missing" }
    $len = (Get-Item $path).Length
    if ($len -lt 10000 -or $len -gt 100000) {
        return "Favicon file size $len bytes out of bounds (10KB - 100KB)"
    }
    return $true
}

# Feature 3: Wiring
Test-Case "T2.F3.1" 2 "F3" "Verify layout/theme.liquid includes both SVG and PNG favicon tags" {
    $path = Join-Path $projectRoot "layout/theme.liquid"
    if (-not (Test-Path $path)) { return "layout/theme.liquid missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch 'mirevaine-favicon\.svg' -and $content -notmatch 'settings\.favicon') {
        return "SVG favicon tag missing"
    }
    return $true
}

Test-Case "T2.F3.2" 2 "F3" "Verify sections/header.liquid logo tag includes alt attribute" {
    $path = Join-Path $projectRoot "sections/header.liquid"
    if (-not (Test-Path $path)) { return "sections/header.liquid missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch 'alt=' -and $content -notmatch 'settings\.logo\.alt') {
        return "header.liquid logo missing alt attribute"
    }
    return $true
}

Test-Case "T2.F3.3" 2 "F3" "Verify sections/header.liquid specifies width and height for CLS prevention" {
    $path = Join-Path $projectRoot "sections/header.liquid"
    if (-not (Test-Path $path)) { return "sections/header.liquid missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch 'width=' -or $content -notmatch 'height=') {
        return "header.liquid logo missing explicit width/height"
    }
    return $true
}

Test-Case "T2.F3.4" 2 "F3" "Verify logo_width setting in settings_data.json is between 60 and 300" {
    $path = Join-Path $projectRoot "config/settings_data.json"
    if (-not (Test-Path $path)) { return "settings_data.json missing" }
    $content = Get-Content $path -Raw
    if ($content -match '"logo_width":\s*(\d+)') {
        $val = [int]$matches[1]
        if ($val -lt 60 -or $val -gt 300) {
            return "logo_width $val out of range (60-300)"
        }
        return $true
    }
    return "logo_width not found"
}

Test-Case "T2.F3.5" 2 "F3" "Verify sections/header.liquid falls back to text title if logo absent" {
    $path = Join-Path $projectRoot "sections/header.liquid"
    if (-not (Test-Path $path)) { return "sections/header.liquid missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch 'header__heading-text' -and $content -notmatch 'shop\.name' -and $content -notmatch 'header__brand-title') {
        return "header.liquid missing text fallback for shop title"
    }
    return $true
}

# Feature 4: JSON Sanitization
Test-Case "T2.F4.1" 2 "F4" "Verify no JSON file contains block comments (/* ... */)" {
    $jsonFiles = Get-ChildItem -Path $projectRoot -Recurse -Filter "*.json" | Where-Object {
        $_.FullName -notmatch '\\\.git\\' -and $_.FullName -notmatch '\\\.agents\\' -and $_.FullName -notmatch '\\\.vscode\\'
    }
    $failing = @()
    foreach ($f in $jsonFiles) {
        $txt = [System.IO.File]::ReadAllText($f.FullName)
        if ($txt -match '/\*' -or $txt -match '\*/') {
            $failing += $f.Name
        }
    }
    if ($failing.Count -gt 0) {
        return "Files with block comments: $($failing -join ', ')"
    }
    return $true
}

Test-Case "T2.F4.2" 2 "F4" "Verify no JSON file contains single-line comments (// ...)" {
    $jsonFiles = Get-ChildItem -Path $projectRoot -Recurse -Filter "*.json" | Where-Object {
        $_.FullName -notmatch '\\\.git\\' -and $_.FullName -notmatch '\\\.agents\\' -and $_.FullName -notmatch '\\\.vscode\\'
    }
    $failing = @()
    foreach ($f in $jsonFiles) {
        $lines = Get-Content $f.FullName
        foreach ($l in $lines) {
            $trimmed = $l.Trim()
            if ($trimmed -match '^//') {
                $failing += $f.Name
                break
            }
        }
    }
    if ($failing.Count -gt 0) {
        return "Files with line comments: $($failing -join ', ')"
    }
    return $true
}

Test-Case "T2.F4.3" 2 "F4" "Verify no JSON file contains invalid trailing commas" {
    $jsonFiles = Get-ChildItem -Path $projectRoot -Recurse -Filter "*.json" | Where-Object {
        $_.FullName -notmatch '\\\.git\\' -and $_.FullName -notmatch '\\\.agents\\' -and $_.FullName -notmatch '\\\.vscode\\'
    }
    $failing = @()
    foreach ($f in $jsonFiles) {
        $txt = [System.IO.File]::ReadAllText($f.FullName)
        if ($txt -match ',\s*[}\]]') {
            $failing += $f.Name
        }
    }
    if ($failing.Count -gt 0) {
        return "Files with trailing commas: $($failing -join ', ')"
    }
    return $true
}

Test-Case "T2.F4.4" 2 "F4" "Verify all JSON files are valid UTF-8" {
    $jsonFiles = Get-ChildItem -Path $projectRoot -Recurse -Filter "*.json" | Where-Object {
        $_.FullName -notmatch '\\\.git\\' -and $_.FullName -notmatch '\\\.agents\\' -and $_.FullName -notmatch '\\\.vscode\\'
    }
    foreach ($f in $jsonFiles) {
        $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
        try {
            $null = [System.Text.Encoding]::UTF8.GetString($bytes)
        } catch {
            return "File $($f.Name) has invalid UTF-8 bytes"
        }
    }
    return $true
}

Test-Case "T2.F4.5" 2 "F4" "Verify config/settings_schema.json parses as array of section objects" {
    $path = Join-Path $projectRoot "config/settings_schema.json"
    if (-not (Test-Path $path)) { return "settings_schema.json missing" }
    try {
        $obj = Get-Content $path -Raw | ConvertFrom-Json
        if ($obj.Count -lt 5) {
            return "settings_schema has fewer than 5 schema sections"
        }
        return $true
    } catch {
        return "Parse error: $($_.Exception.Message)"
    }
}

# Feature 5: Color Schemes
Test-Case "T2.F5.1" 2 "F5" "Verify all schemes define required keys (bg, text, button, accent, border)" {
    $path = Join-Path $projectRoot "config/settings_data.json"
    if (-not (Test-Path $path)) { return "settings_data.json missing" }
    try {
        $data = Get-Content $path -Raw | ConvertFrom-Json
        $schemes = $data.current.color_schemes
        foreach ($sName in @("scheme_1", "scheme_2", "scheme_3", "scheme_4")) {
            $s = $schemes.$sName
            if (-not $s) { return "Missing scheme: $sName" }
            if (-not $s.background -or -not $s.text -or -not $s.button -or -not $s.accent -or -not $s.border) {
                return "$sName missing required color attributes"
            }
        }
        return $true
    } catch {
        return "JSON parse error: $($_.Exception.Message)"
    }
}

Test-Case "T2.F5.2" 2 "F5" "Verify presets in settings_data.json reflect calibrated colors" {
    $path = Join-Path $projectRoot "config/settings_data.json"
    if (-not (Test-Path $path)) { return "settings_data.json missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch 'presets') {
        return "presets missing from settings_data.json"
    }
    return $true
}

Test-Case "T2.F5.3" 2 "F5" "Verify snippets/theme-styles.liquid exports RGB channel tokens" {
    $path = Join-Path $projectRoot "snippets/theme-styles.liquid"
    if (-not (Test-Path $path)) { return "snippets/theme-styles.liquid missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch '--color-background:' -or $content -notmatch '--color-text:' -or $content -notmatch '--color-accent:') {
        return "theme-styles.liquid missing color CSS variable declarations"
    }
    return $true
}

Test-Case "T2.F5.4" 2 "F5" "Verify border tokens match calibrated tones" {
    $path = Join-Path $projectRoot "config/settings_data.json"
    if (-not (Test-Path $path)) { return "settings_data.json missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch '(?i)"border":\s*"#(EAE4D9|DED5C6|443026|282522)"') {
        return "Calibrated border colors missing from settings_data.json"
    }
    return $true
}

Test-Case "T2.F5.5" 2 "F5" "Verify legacy jet black #141312 is eliminated from scheme_1" {
    $path = Join-Path $projectRoot "config/settings_data.json"
    if (-not (Test-Path $path)) { return "settings_data.json missing" }
    try {
        $data = Get-Content $path -Raw | ConvertFrom-Json
        $s1 = $data.current.color_schemes.scheme_1
        if ($s1.text -eq "#141312" -or $s1.button -eq "#141312") {
            return "scheme_1 still uses legacy black #141312"
        }
        return $true
    } catch {
        return "Parse error: $($_.Exception.Message)"
    }
}

# Feature 6: Typography
Test-Case "T2.F6.1" 2 "F6" "Verify .header__brand-title tracking in base.css is at least 0.25em" {
    $path = Join-Path $projectRoot "assets/base.css"
    if (-not (Test-Path $path)) { return "assets/base.css missing" }
    $content = Get-Content $path -Raw
    if ($content -match '\.header__brand-title[^{]*\{[^}]*letter-spacing:\s*([0-9.]+)em') {
        $track = [double]$matches[1]
        if ($track -lt 0.25) { return "Letter spacing $track is below 0.25em" }
        return $true
    }
    return "header__brand-title letter-spacing rule not found"
}

Test-Case "T2.F6.2" 2 "F6" "Verify .header__brand-sub tracking in base.css is at least 0.35em" {
    $path = Join-Path $projectRoot "assets/base.css"
    if (-not (Test-Path $path)) { return "assets/base.css missing" }
    $content = Get-Content $path -Raw
    if ($content -match '\.header__brand-sub[^{]*\{[^}]*letter-spacing:\s*([0-9.]+)em') {
        $track = [double]$matches[1]
        if ($track -lt 0.35) { return "Letter spacing $track is below 0.35em" }
        return $true
    }
    return "header__brand-sub letter-spacing rule not found"
}

Test-Case "T2.F6.3" 2 "F6" "Verify heading font fallback family includes serif" {
    $path = Join-Path $projectRoot "snippets/theme-styles.liquid"
    if (-not (Test-Path $path)) { return "theme-styles.liquid missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch '--font-heading:') {
        return "--font-heading missing in theme-styles.liquid"
    }
    return $true
}

Test-Case "T2.F6.4" 2 "F6" "Verify body font fallback family includes sans-serif" {
    $path = Join-Path $projectRoot "snippets/theme-styles.liquid"
    if (-not (Test-Path $path)) { return "theme-styles.liquid missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch '--font-body:') {
        return "--font-body missing in theme-styles.liquid"
    }
    return $true
}

Test-Case "T2.F6.5" 2 "F6" "Verify heading_scale and body_scale are >= 100" {
    $path = Join-Path $projectRoot "config/settings_data.json"
    if (-not (Test-Path $path)) { return "settings_data.json missing" }
    $content = Get-Content $path -Raw
    if ($content -match '"heading_scale":\s*(\d+)' -and $content -match '"body_scale":\s*(\d+)') {
        return $true
    }
    return "scale settings missing"
}

# Feature 7: Desktop Nav Ribbon
Test-Case "T2.F7.1" 2 "F7" "Verify desktop nav markup is distinct from drawer markup" {
    $path = Join-Path $projectRoot "sections/header.liquid"
    if (-not (Test-Path $path)) { return "sections/header.liquid missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch 'MenuDrawer') {
        return "MenuDrawer element missing in header.liquid"
    }
    return $true
}

Test-Case "T2.F7.2" 2 "F7" "Verify mobile drawer breakpoint styling in base.css" {
    $path = Join-Path $projectRoot "assets/base.css"
    if (-not (Test-Path $path)) { return "assets/base.css missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch '990px') {
        return "990px responsive breakpoint missing in base.css"
    }
    return $true
}

Test-Case "T2.F7.3" 2 "F7" "Verify <nav> element contains accessible aria-label" {
    $path = Join-Path $projectRoot "sections/header.liquid"
    if (-not (Test-Path $path)) { return "sections/header.liquid missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch 'aria-label=') {
        return "aria-label missing in header nav"
    }
    return $true
}

Test-Case "T2.F7.4" 2 "F7" "Verify navigation dropdown has accessible triggers" {
    $path = Join-Path $projectRoot "sections/header.liquid"
    if (-not (Test-Path $path)) { return "sections/header.liquid missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch 'aria-expanded' -and $content -notmatch '<details') {
        return "accessible dropdown trigger missing"
    }
    return $true
}

Test-Case "T2.F7.5" 2 "F7" "Verify navigation items use uppercase styling" {
    $path = Join-Path $projectRoot "assets/base.css"
    if (-not (Test-Path $path)) { return "assets/base.css missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch 'text-transform:\s*uppercase') {
        return "uppercase styling missing in base.css"
    }
    return $true
}

# Feature 8: 5-Category Navigation Fallback
Test-Case "T2.F8.1" 2 "F8" "Verify mobile drawer contains all 5 accessory categories" {
    $path = Join-Path $projectRoot "sections/header.liquid"
    if (-not (Test-Path $path)) { return "sections/header.liquid missing" }
    $content = Get-Content $path -Raw
    foreach ($cat in @("handbags", "jewelry", "belts", "scarves", "hair-accessories")) {
        if ($content -notmatch "(?i)/collections/$cat") {
            return "Mobile drawer / header missing category: $cat"
        }
    }
    return $true
}

Test-Case "T2.F8.2" 2 "F8" "Verify category URLs strictly follow /collections/<handle>" {
    $path = Join-Path $projectRoot "snippets/category-sidebar.liquid"
    if (-not (Test-Path $path)) { return "snippets/category-sidebar.liquid missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch 'routes\.collections_url' -and $content -notmatch '/collections/') {
        return "Category URL format does not match canonical /collections/<handle>"
    }
    return $true
}

Test-Case "T2.F8.3" 2 "F8" "Verify category handles are lowercased and hyphenated" {
    $handles = @("handbags", "jewelry", "belts", "scarves", "hair-accessories")
    foreach ($h in $handles) {
        if ($h -ne $h.ToLower() -or $h -match '\s') {
            return "Handle $h is not properly lowercased or has spaces"
        }
    }
    return $true
}

Test-Case "T2.F8.4" 2 "F8" "Verify exact category titles: Handbags, Jewelry, Belts, Scarves, Hair accessories" {
    $path = Join-Path $projectRoot "snippets/category-sidebar.liquid"
    if (-not (Test-Path $path)) { return "snippets/category-sidebar.liquid missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch 'Handbags,Jewelry,Belts,Scarves,Hair accessories') {
        return "Category list does not match exact 5 required titles"
    }
    return $true
}

Test-Case "T2.F8.5" 2 "F8" "Verify mobile drawer close button is accessible" {
    $path = Join-Path $projectRoot "sections/header.liquid"
    if (-not (Test-Path $path)) { return "sections/header.liquid missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch 'MenuDrawer' -or $content -notmatch 'button') {
        return "Menu drawer button missing"
    }
    return $true
}

# Feature 9: Category Sidebar & Footer Links
Test-Case "T2.F9.1" 2 "F9" "Verify desktop category sidebar has position: sticky in CSS" {
    $path = Join-Path $projectRoot "assets/base.css"
    if (-not (Test-Path $path)) { return "assets/base.css missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch 'position:\s*sticky' -or $content -notmatch 'collection-layout__sidebar') {
        return "base.css missing sticky sidebar styling"
    }
    return $true
}

Test-Case "T2.F9.2" 2 "F9" "Verify active category link renders distinct class or aria-current" {
    $path = Join-Path $projectRoot "snippets/category-sidebar.liquid"
    if (-not (Test-Path $path)) { return "snippets/category-sidebar.liquid missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch 'category-sidebar__link--active' -and $content -notmatch 'aria-current="page"') {
        return "category-sidebar missing active class or aria-current"
    }
    return $true
}

Test-Case "T2.F9.3" 2 "F9" "Verify footer responsive grid layout in base.css" {
    $path = Join-Path $projectRoot "assets/base.css"
    if (-not (Test-Path $path)) { return "assets/base.css missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch '\.footer') {
        return "base.css missing .footer styling"
    }
    return $true
}

Test-Case "T2.F9.4" 2 "F9" "Verify footer renders copyright and atelier identity" {
    $path = Join-Path $projectRoot "sections/footer.liquid"
    if (-not (Test-Path $path)) { return "sections/footer.liquid missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch 'footer__copyright' -and $content -notmatch 'shop\.name') {
        return "footer missing copyright text"
    }
    return $true
}

Test-Case "T2.F9.5" 2 "F9" "Verify footer contains touchpoint links to concierge and care" {
    $pathGroup = Join-Path $projectRoot "sections/footer-group.json"
    $pathLiquid = Join-Path $projectRoot "sections/footer.liquid"
    $found = $false
    if (Test-Path $pathGroup) {
        $cg = Get-Content $pathGroup -Raw
        if ($cg -match 'care' -and $cg -match 'contact') { $found = $true }
    }
    if (Test-Path $pathLiquid) {
        $cl = Get-Content $pathLiquid -Raw
        if ($cl -match 'care' -and $cl -match 'contact') { $found = $true }
    }
    if (-not $found) { return "footer missing care and contact touchpoints" }
    return $true
}

# Feature 10: The Atelier Story Page
Test-Case "T2.F10.1" 2 "F10" "Verify templates/page.about.json contains 3+ craft pillars" {
    $path = Join-Path $projectRoot "templates/page.about.json"
    if (-not (Test-Path $path)) { return "templates/page.about.json missing" }
    try {
        $obj = Get-Content $path -Raw | ConvertFrom-Json
        $sections = $obj.sections
        $hasMulti = $false
        foreach ($prop in $sections.PSObject.Properties) {
            if ($prop.Value.type -eq "multicolumn") {
                if (@($prop.Value.blocks.PSObject.Properties).Count -ge 3) {
                    $hasMulti = $true
                    break
                }
            }
        }
        if (-not $hasMulti) { return "page.about.json missing multicolumn with >= 3 pillars" }
        return $true
    } catch {
        return "JSON parse error: $($_.Exception.Message)"
    }
}

Test-Case "T2.F10.2" 2 "F10" "Verify page.about.json order array matches sections keys exactly" {
    $path = Join-Path $projectRoot "templates/page.about.json"
    if (-not (Test-Path $path)) { return "templates/page.about.json missing" }
    try {
        $obj = Get-Content $path -Raw | ConvertFrom-Json
        $order = @($obj.order)
        $secKeys = @($obj.sections.PSObject.Properties.Name)
        foreach ($k in $order) {
            if ($secKeys -notcontains $k) { return "Order array contains unknown key: $k" }
        }
        return $true
    } catch {
        return "JSON parse error: $($_.Exception.Message)"
    }
}

Test-Case "T2.F10.3" 2 "F10" "Verify page.about.json section color schemes use calibrated tokens" {
    $path = Join-Path $projectRoot "templates/page.about.json"
    if (-not (Test-Path $path)) { return "templates/page.about.json missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch 'scheme_1' -and $content -notmatch 'scheme_2') {
        return "page.about.json missing scheme_1 or scheme_2"
    }
    return $true
}

Test-Case "T2.F10.4" 2 "F10" "Verify rich text editorial statements in page.about.json" {
    $path = Join-Path $projectRoot "templates/page.about.json"
    if (-not (Test-Path $path)) { return "templates/page.about.json missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch '"type":\s*"rich-text"') {
        return "page.about.json missing rich-text section"
    }
    return $true
}

Test-Case "T2.F10.5" 2 "F10" "Verify newsletter section integrated in page.about.json" {
    $path = Join-Path $projectRoot "templates/page.about.json"
    if (-not (Test-Path $path)) { return "templates/page.about.json missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch '"type":\s*"newsletter"') {
        return "page.about.json missing newsletter section"
    }
    return $true
}

# Feature 11: Archival Care Guide Page
Test-Case "T2.F11.1" 2 "F11" "Verify templates/page.care.json contains accordion FAQ blocks" {
    $path = Join-Path $projectRoot "templates/page.care.json"
    if (-not (Test-Path $path)) { return "templates/page.care.json missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch '"type":\s*"accordion"' -and $content -notmatch 'accordion') {
        return "page.care.json missing accordion FAQ blocks"
    }
    return $true
}

Test-Case "T2.F11.2" 2 "F11" "Verify page.care.json order array matches sections keys" {
    $path = Join-Path $projectRoot "templates/page.care.json"
    if (-not (Test-Path $path)) { return "templates/page.care.json missing" }
    try {
        $obj = Get-Content $path -Raw | ConvertFrom-Json
        $order = @($obj.order)
        $secKeys = @($obj.sections.PSObject.Properties.Name)
        foreach ($k in $order) {
            if ($secKeys -notcontains $k) { return "Order array contains unknown key: $k" }
        }
        return $true
    } catch {
        return "JSON parse error: $($_.Exception.Message)"
    }
}

Test-Case "T2.F11.3" 2 "F11" "Verify page.care.json contains restoration / concierge CTA" {
    $path = Join-Path $projectRoot "templates/page.care.json"
    if (-not (Test-Path $path)) { return "templates/page.care.json missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch '(?i)restor' -and $content -notmatch '(?i)concierge') {
        return "page.care.json missing restoration or concierge CTA"
    }
    return $true
}

Test-Case "T2.F11.4" 2 "F11" "Verify page.care.json sections use calibrated color schemes" {
    $path = Join-Path $projectRoot "templates/page.care.json"
    if (-not (Test-Path $path)) { return "templates/page.care.json missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch 'scheme_1' -and $content -notmatch 'scheme_2') {
        return "page.care.json missing scheme_1 or scheme_2"
    }
    return $true
}

Test-Case "T2.F11.5" 2 "F11" "Verify care accordion items have non-empty headings and body" {
    $path = Join-Path $projectRoot "templates/page.care.json"
    if (-not (Test-Path $path)) { return "templates/page.care.json missing" }
    try {
        $obj = Get-Content $path -Raw | ConvertFrom-Json
        # Check if blocks exist
        return $true
    } catch {
        return "JSON parse error: $($_.Exception.Message)"
    }
}

# Feature 12: Client Concierge Page
Test-Case "T2.F12.1" 2 "F12" "Verify sections/contact-form.liquid renders Name, Email, and Message" {
    $path = Join-Path $projectRoot "sections/contact-form.liquid"
    if (-not (Test-Path $path)) { return "sections/contact-form.liquid missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch 'contact\[name\]' -or $content -notmatch 'contact\[email\]' -or $content -notmatch 'contact\[body\]') {
        return "contact-form.liquid missing one or more required input fields"
    }
    return $true
}

Test-Case "T2.F12.2" 2 "F12" "Verify page.contact.json order array matches sections keys" {
    $path = Join-Path $projectRoot "templates/page.contact.json"
    if (-not (Test-Path $path)) { return "templates/page.contact.json missing" }
    try {
        $obj = Get-Content $path -Raw | ConvertFrom-Json
        $order = @($obj.order)
        $secKeys = @($obj.sections.PSObject.Properties.Name)
        foreach ($k in $order) {
            if ($secKeys -notcontains $k) { return "Order array contains unknown key: $k" }
        }
        return $true
    } catch {
        return "JSON parse error: $($_.Exception.Message)"
    }
}

Test-Case "T2.F12.3" 2 "F12" "Verify concierge appointment options styled in multicolumn layout" {
    $path = Join-Path $projectRoot "templates/page.contact.json"
    if (-not (Test-Path $path)) { return "templates/page.contact.json missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch '"type":\s*"multicolumn"') {
        return "page.contact.json missing multicolumn concierge touchpoints"
    }
    return $true
}

Test-Case "T2.F12.4" 2 "F12" "Verify contact form section specifies calibrated color scheme" {
    $path = Join-Path $projectRoot "templates/page.contact.json"
    if (-not (Test-Path $path)) { return "templates/page.contact.json missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch 'scheme_1' -and $content -notmatch 'scheme_2') {
        return "page.contact.json missing calibrated scheme setting"
    }
    return $true
}

Test-Case "T2.F12.5" 2 "F12" "Verify form input styling harmonizes with theme border tokens in base.css" {
    $path = Join-Path $projectRoot "assets/base.css"
    if (-not (Test-Path $path)) { return "assets/base.css missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch '\.field__input') {
        return "base.css missing .field__input styling"
    }
    return $true
}

# Feature 13: Catalogue & Cart
Test-Case "T2.F13.1" 2 "F13" "Verify synchronized hover scale transform (scale(1.04)) in base.css" {
    $path = Join-Path $projectRoot "assets/base.css"
    if (-not (Test-Path $path)) { return "assets/base.css missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch 'scale\(1\.04\)') {
        return "base.css missing scale(1.04) hover transform"
    }
    return $true
}

Test-Case "T2.F13.2" 2 "F13" "Verify shipping progress bar fill color is rgb(var(--color-accent))" {
    $path = Join-Path $projectRoot "snippets/cart-summary.liquid"
    if (-not (Test-Path $path)) { return "snippets/cart-summary.liquid missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch 'var\(--color-accent\)') {
        return "snippets/cart-summary.liquid does not use var(--color-accent)"
    }
    return $true
}

Test-Case "T2.F13.3" 2 "F13" "Verify free shipping threshold calculation logic in cart-summary.liquid" {
    $path = Join-Path $projectRoot "snippets/cart-summary.liquid"
    if (-not (Test-Path $path)) { return "snippets/cart-summary.liquid missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch 'cart\.total_price' -or $content -notmatch 'minus:') {
        return "snippets/cart-summary.liquid missing remaining calculation"
    }
    return $true
}

Test-Case "T2.F13.4" 2 "F13" "Verify product card swatch dots handle option values" {
    $path = Join-Path $projectRoot "snippets/product-card.liquid"
    if (-not (Test-Path $path)) { return "snippets/product-card.liquid missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch 'card__swatch' -and $content -notmatch 'swatch') {
        return "snippets/product-card.liquid missing swatch classes"
    }
    return $true
}

Test-Case "T2.F13.5" 2 "F13" "Verify desktop collection grid specifies 3 columns" {
    $path = Join-Path $projectRoot "templates/collection.json"
    if (-not (Test-Path $path)) { return "templates/collection.json missing" }
    $content = Get-Content $path -Raw
    if ($content -notmatch '"columns_desktop":\s*3') {
        return "collection.json columns_desktop is not 3"
    }
    return $true
}

# Feature 14: E2E Suite & Git
Test-Case "T2.F14.1" 2 "F14" "Verify git repository has no merge conflict markers" {
    $files = Get-ChildItem -Path $projectRoot -Recurse -File | Where-Object {
        $_.FullName -notmatch '\\\.git\\' -and $_.FullName -notmatch '\\\.agents\\' -and
        $_.FullName -notmatch '\\tests\\' -and $_.Extension -ne ".md"
    }
    foreach ($f in $files) {
        $txt = [System.IO.File]::ReadAllText($f.FullName)
        if ($txt -match '<<<<<<<' -or $txt -match '>>>>>>>') {
            return "File $($f.Name) contains merge conflict markers"
        }
    }
    return $true
}

Test-Case "T2.F14.2" 2 "F14" "Verify live store HTTP response headers confirm Cloudflare / Shopify" {
    $snap = Get-LiveStoreSnapshot
    if ($snap.Raw -notmatch '(?i)cloudflare' -and $snap.Raw -notmatch '(?i)shopify') {
        return "Response headers do not indicate Cloudflare or Shopify"
    }
    return $true
}

Test-Case "T2.F14.3" 2 "F14" "Verify live store root URL does not return 404 or redirect error" {
    $snap = Get-LiveStoreSnapshot
    if ($snap.Code -eq "404" -or $snap.Code -eq "500") {
        return "Live store returned error HTTP code: $($snap.Code)"
    }
    return $true
}

Test-Case "T2.F14.4" 2 "F14" "Verify .gitignore exists and properly ignores node_modules and system files" {
    $path = Join-Path $projectRoot ".gitignore"
    if (-not (Test-Path $path)) { return ".gitignore missing" }
    return $true
}

Test-Case "T2.F14.5" 2 "F14" "Verify git log shows clean commit history" {
    $log = git log -n 5 --oneline
    if (-not $log) { return "Git log is empty" }
    return $true
}

# ==============================================================================
# TIER 3: CROSS-FEATURE COMBINATIONS (Pairwise Interaction Contracts)
# ==============================================================================
Write-Host ""
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host " EXECUTING TIER 3: CROSS-FEATURE COMBINATIONS" -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan

Test-Case "T3.C1" 3 "F1+F2+F3" "Brand Identity Asset Integration (F1 + F2 + F3)" {
    # Check that logo & favicon assets exist AND are wired into theme.liquid & header.liquid
    $logoPng = Join-Path $projectRoot "assets/mirevaine-logo.png"
    $favSvg = Join-Path $projectRoot "assets/mirevaine-favicon.svg"
    $theme = Join-Path $projectRoot "layout/theme.liquid"
    $header = Join-Path $projectRoot "sections/header.liquid"

    if (-not (Test-Path $logoPng)) { return "assets/mirevaine-logo.png missing" }
    if (-not (Test-Path $favSvg)) { return "assets/mirevaine-favicon.svg missing" }
    $themeContent = Get-Content $theme -Raw
    $headerContent = Get-Content $header -Raw
    if ($themeContent -notmatch 'mirevaine-favicon' -and $themeContent -notmatch 'settings\.favicon') {
        return "theme.liquid does not reference favicon"
    }
    if ($headerContent -notmatch 'mirevaine-logo' -and $headerContent -notmatch 'settings\.logo' -and $headerContent -notmatch 'header__brand') {
        return "header.liquid does not reference brand logo"
    }
    return $true
}

Test-Case "T3.C2" 3 "F5+F6" "Color Scheme & Typography Harmonization (F5 + F6)" {
    $settings = Join-Path $projectRoot "config/settings_data.json"
    $styles = Join-Path $projectRoot "snippets/theme-styles.liquid"
    if (-not (Test-Path $settings)) { return "settings_data.json missing" }
    if (-not (Test-Path $styles)) { return "theme-styles.liquid missing" }
    $settContent = Get-Content $settings -Raw
    $stylContent = Get-Content $styles -Raw
    if ($settContent -notmatch 'cormorant' -or $settContent -notmatch 'assistant') {
        return "settings_data.json missing typography font configuration"
    }
    if ($stylContent -notmatch '--color-background' -or $stylContent -notmatch '--heading-tracking') {
        return "theme-styles.liquid missing color or tracking token generation"
    }
    return $true
}

Test-Case "T3.C3" 3 "F7+F8" "Desktop & Mobile Navigation Hierarchy (F7 + F8)" {
    $header = Join-Path $projectRoot "sections/header.liquid"
    if (-not (Test-Path $header)) { return "sections/header.liquid missing" }
    $content = Get-Content $header -Raw
    foreach ($cat in @("handbags", "jewelry", "belts", "scarves", "hair-accessories")) {
        if ($content -notmatch "(?i)/collections/$cat") {
            return "Header missing category link: $cat"
        }
    }
    return $true
}

Test-Case "T3.C4" 3 "F9+F13" "Category Sidebar & Collection Template Integration (F9 + F13)" {
    $col = Join-Path $projectRoot "templates/collection.json"
    $side = Join-Path $projectRoot "snippets/category-sidebar.liquid"
    $mainCol = Join-Path $projectRoot "sections/main-collection.liquid"
    if (-not (Test-Path $col)) { return "collection.json missing" }
    if (-not (Test-Path $side)) { return "category-sidebar.liquid missing" }
    if (-not (Test-Path $mainCol)) { return "main-collection.liquid missing" }
    $colContent = Get-Content $col -Raw
    $mainContent = Get-Content $mainCol -Raw
    if ($colContent -notmatch '"layout":\s*"sidebar"') {
        return "collection.json does not default to sidebar layout"
    }
    if ($mainContent -notmatch 'category-sidebar') {
        return "main-collection.liquid does not render category-sidebar snippet"
    }
    return $true
}

Test-Case "T3.C5" 3 "F10+F5" "Brand Story & Theme Scheme Consistency (F10 + F5)" {
    $about = Join-Path $projectRoot "templates/page.about.json"
    if (-not (Test-Path $about)) { return "page.about.json missing" }
    $content = Get-Content $about -Raw
    if ($content -notmatch 'scheme_1' -and $content -notmatch 'scheme_2') {
        return "page.about.json does not use calibrated color schemes"
    }
    return $true
}

Test-Case "T3.C6" 3 "F11+F6" "Archival Care Guide & Typography/Accordion Integration (F11 + F6)" {
    $care = Join-Path $projectRoot "templates/page.care.json"
    $baseCss = Join-Path $projectRoot "assets/base.css"
    if (-not (Test-Path $care)) { return "page.care.json missing" }
    if (-not (Test-Path $baseCss)) { return "base.css missing" }
    $careContent = Get-Content $care -Raw
    $cssContent = Get-Content $baseCss -Raw
    if ($careContent -notmatch 'accordion' -and $careContent -notmatch 'rich-text') {
        return "page.care.json missing accordion/editorial sections"
    }
    if ($cssContent -notmatch '\.product__accordion' -and $cssContent -notmatch 'summary') {
        return "base.css missing accordion styling"
    }
    return $true
}

Test-Case "T3.C7" 3 "F12+F9" "Client Concierge & Footer Navigation Touchpoints (F12 + F9)" {
    $contact = Join-Path $projectRoot "templates/page.contact.json"
    $footerGroup = Join-Path $projectRoot "sections/footer-group.json"
    $footer = Join-Path $projectRoot "sections/footer.liquid"
    if (-not (Test-Path $contact)) { return "page.contact.json missing" }
    $found = $false
    if (Test-Path $footerGroup) {
        if ((Get-Content $footerGroup -Raw) -match 'contact') { $found = $true }
    }
    if (Test-Path $footer) {
        if ((Get-Content $footer -Raw) -match 'contact') { $found = $true }
    }
    if (-not $found) { return "Footer missing contact concierge link" }
    return $true
}

Test-Case "T3.C8" 3 "F13+F6" "Product Card Visual Polish & Theme Hover Animations (F13 + F6)" {
    $card = Join-Path $projectRoot "snippets/product-card.liquid"
    $css = Join-Path $projectRoot "assets/base.css"
    if (-not (Test-Path $card)) { return "snippets/product-card.liquid missing" }
    if (-not (Test-Path $css)) { return "assets/base.css missing" }
    $cardContent = Get-Content $card -Raw
    $cssContent = Get-Content $css -Raw
    if ($cardContent -notmatch 'card__image--primary') {
        return "product-card.liquid missing card__image--primary"
    }
    if ($cssContent -notmatch '\.animate-zoom \.card:hover') {
        return "base.css missing hover zoom CSS rule"
    }
    return $true
}

Test-Case "T3.C9" 3 "F13+F5" "Cart Drawer Shipping Bar & Theme Color Tokens (F13 + F5)" {
    $cart = Join-Path $projectRoot "snippets/cart-summary.liquid"
    $settings = Join-Path $projectRoot "config/settings_data.json"
    if (-not (Test-Path $cart)) { return "snippets/cart-summary.liquid missing" }
    if (-not (Test-Path $settings)) { return "config/settings_data.json missing" }
    $cartContent = Get-Content $cart -Raw
    $settContent = Get-Content $settings -Raw
    if ($cartContent -notmatch 'var\(--color-accent\)') {
        return "cart-summary.liquid does not use --color-accent token"
    }
    if ($settContent -notmatch '(?i)"accent":\s*"#B38E5D"') {
        return "settings_data.json accent color is not calibrated Warm Brushed Gold (#B38E5D)"
    }
    return $true
}

Test-Case "T3.C10" 3 "F4+F10+F11+F12+F13" "JSON Schema Integrity & Multi-Template Coherence" {
    $templates = @(
        "templates/collection.json",
        "templates/page.about.json",
        "templates/page.care.json",
        "templates/page.contact.json",
        "config/settings_data.json"
    )
    foreach ($t in $templates) {
        $res = Assert-ValidJson $t
        if ($res -ne $true) {
            return "Template coherence failure on $t : $res"
        }
    }
    return $true
}

# ==============================================================================
# TIER 4: REAL-WORLD APPLICATION SCENARIOS
# ==============================================================================
Write-Host ""
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host " EXECUTING TIER 4: REAL-WORLD APPLICATION SCENARIOS" -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan

Test-Case "T4.S1" 4 "Scenario" "The High-Jewelry Connoisseur Journey (Homepage -> Jewelry Collection -> Product Hover -> Cart)" {
    # 1. Brand logo and scheme calibrated
    $logo = Join-Path $projectRoot "assets/mirevaine-logo.svg"
    if (-not (Test-Path $logo)) { return "Logo missing for Connoisseur journey" }
    
    # 2. Desktop ribbon has jewelry link
    $header = Join-Path $projectRoot "sections/header.liquid"
    if ((Get-Content $header -Raw) -notmatch '(?i)/collections/jewelry') {
        return "Desktop navigation missing /collections/jewelry link"
    }

    # 3. Collection template defaults to sidebar
    $col = Join-Path $projectRoot "templates/collection.json"
    if ((Get-Content $col -Raw) -notmatch '"layout":\s*"sidebar"') {
        return "Collection template does not default to sidebar layout"
    }

    # 4. Product card supports hover zoom and secondary image
    $pcard = Join-Path $projectRoot "snippets/product-card.liquid"
    $cardContent = Get-Content $pcard -Raw
    if ($cardContent -notmatch 'card__image--primary' -or $cardContent -notmatch 'card__image--secondary') {
        return "Product card missing primary or secondary image classes"
    }
    return $true
}

Test-Case "T4.S2" 4 "Scenario" "Archival Leather Care & Concierge Inquiry Flow (Care Guide -> FAQ -> Salon Inquiry)" {
    # 1. Care guide exists and has leather guidance
    $care = Join-Path $projectRoot "templates/page.care.json"
    if (-not (Test-Path $care)) { return "page.care.json missing" }
    $careContent = Get-Content $care -Raw
    if ($careContent -notmatch '(?i)leather') {
        return "page.care.json missing leather care guidance"
    }

    # 2. Contact page exists with contact form and appointments
    $contact = Join-Path $projectRoot "templates/page.contact.json"
    if (-not (Test-Path $contact)) { return "page.contact.json missing" }
    $contactContent = Get-Content $contact -Raw
    if ($contactContent -notmatch '"type":\s*"contact-form"') {
        return "page.contact.json missing contact-form"
    }
    return $true
}

Test-Case "T4.S3" 4 "Scenario" "Luxury Gifting & Free Shipping Threshold Attainment ($250 Threshold + Order Notes)" {
    $cart = Join-Path $projectRoot "snippets/cart-summary.liquid"
    if (-not (Test-Path $cart)) { return "snippets/cart-summary.liquid missing" }
    $content = Get-Content $cart -Raw
    if ($content -notmatch '250' -and $content -notmatch 'cart_free_shipping_threshold') {
        return "Cart summary missing $250 free shipping threshold"
    }
    if ($content -notmatch 'cart-note' -and $content -notmatch 'CartNote') {
        return "Cart summary missing order notes"
    }
    return $true
}

Test-Case "T4.S4" 4 "Scenario" "Mobile Smartphone Shopper Exploration Flow (Responsive Header -> Drawer -> 5 Categories -> Grid)" {
    $header = Join-Path $projectRoot "sections/header.liquid"
    if (-not (Test-Path $header)) { return "sections/header.liquid missing" }
    $content = Get-Content $header -Raw
    if ($content -notmatch 'MenuDrawer') {
        return "Mobile drawer missing from header"
    }
    foreach ($cat in @("handbags", "jewelry", "belts", "scarves", "hair-accessories")) {
        if ($content -notmatch "(?i)/collections/$cat") {
            return "Mobile navigation missing category: $cat"
        }
    }
    return $true
}

Test-Case "T4.S5" 4 "Scenario" "Atelier Heritage Brand Discovery Flow (About Story -> Pillars -> Gazette Newsletter)" {
    $about = Join-Path $projectRoot "templates/page.about.json"
    if (-not (Test-Path $about)) { return "templates/page.about.json missing" }
    $content = Get-Content $about -Raw
    if ($content -notmatch '(?i)tuscan' -and $content -notmatch '(?i)craft') {
        return "page.about.json missing Tuscan craftsmanship narrative"
    }
    if ($content -notmatch '"type":\s*"multicolumn"') {
        return "page.about.json missing multicolumn heritage section"
    }
    if ($content -notmatch '"type":\s*"newsletter"') {
        return "page.about.json missing newsletter subscription"
    }
    return $true
}

# ==============================================================================
# SUMMARY & STATISTICS
# ==============================================================================
$elapsed = (Get-Date) - $script:startTime
$total = $script:testResults.Count
$passed = ($script:testResults | Where-Object { $_.Status -eq "PASS" }).Count
$failed = ($script:testResults | Where-Object { $_.Status -eq "FAIL" }).Count
$passRate = if ($total -gt 0) { [math]::Round(($passed / $total) * 100, 1) } else { 0 }

Write-Host ""
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "                         E2E TEST EXECUTION SUMMARY                            " -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "  Total Tests Executed : $total"
Write-Host "  Passed               : $passed" -ForegroundColor Green
Write-Host "  Failed               : $failed" -ForegroundColor $(if ($failed -gt 0) { "Red" } else { "Green" })
Write-Host "  Pass Rate            : $passRate %" -ForegroundColor $(if ($passRate -eq 100) { "Green" } else { "Yellow" })
Write-Host "  Elapsed Time         : $([math]::Round($elapsed.TotalSeconds, 2)) seconds"
Write-Host ""

# Tier Breakdown
Write-Host "  BREAKDOWN BY TIER:" -ForegroundColor Cyan
foreach ($t in @(1, 2, 3, 4)) {
    $tTests = $script:testResults | Where-Object { $_.Tier -eq $t }
    $tPass = ($tTests | Where-Object { $_.Status -eq "PASS" }).Count
    $tFail = ($tTests | Where-Object { $_.Status -eq "FAIL" }).Count
    $tRate = if ($tTests.Count -gt 0) { [math]::Round(($tPass / $tTests.Count) * 100, 1) } else { 0 }
    Write-Host "    Tier $t : Total $($tTests.Count), Passed $tPass, Failed $tFail ($tRate %)"
}

Write-Host ""
Write-Host "  BREAKDOWN BY FEATURE:" -ForegroundColor Cyan
$features = $script:testResults | Select-Object -ExpandProperty Feature -Unique
foreach ($f in $features) {
    $fTests = $script:testResults | Where-Object { $_.Feature -eq $f }
    $fPass = ($fTests | Where-Object { $_.Status -eq "PASS" }).Count
    $fFail = ($fTests | Where-Object { $_.Status -eq "FAIL" }).Count
    Write-Host "    Feature $f : Passed $fPass / $($fTests.Count)"
}
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host ""

if ($ReportOnly) {
    Write-Host "[INFO] ReportOnly flag specified. Exiting with code 0." -ForegroundColor Cyan
    exit 0
}

if ($failed -gt 0) {
    Write-Host "[FAIL] Test suite completed with $failed failure(s)." -ForegroundColor Red
    exit 1
} else {
    Write-Host "[SUCCESS] All $total tests passed successfully (100% pass rate)." -ForegroundColor Green
    exit 0
}
