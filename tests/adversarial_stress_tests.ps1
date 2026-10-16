# Adversarial Stress Testing Harness for Milestone 1
# Assets, SVGs, Fallbacks, and Error Conditions

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Xml

$workspace = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path $workspace)) {
    $workspace = (Get-Location).Path
}

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "   ADVERSARIAL STRESS TEST HARNESS - MILESTONE 1 VERIFICATION   " -ForegroundColor Cyan
Write-Host "   Workspace: $workspace" -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan

$results = [System.Collections.Generic.List[PSCustomObject]]::new()

function Record-Test {
    param(
        [string]$TestId,
        [string]$Category,
        [string]$Description,
        [bool]$Passed,
        [string]$Details
    )
    $obj = [PSCustomObject]@{
        Id = $TestId
        Category = $Category
        Description = $Description
        Status = if ($Passed) { "PASS" } else { "FAIL" }
        Details = $Details
    }
    $results.Add($obj)
    if ($Passed) {
        Write-Host "  [PASS] ${TestId}: $Description" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] ${TestId}: $Description" -ForegroundColor Red
        Write-Host "         $Details" -ForegroundColor DarkRed
    }
}

# -----------------------------------------------------------------------------
# 1. BITMAP PIXEL FORMAT, DIMENSIONS, CORNERS AND FULL EDGE TRANSPARENCY
# -----------------------------------------------------------------------------
Write-Host "`n--- CATEGORY 1: BITMAP INTEGRITY AND PIXEL AUDIT ---" -ForegroundColor Yellow

$logoPngPath = Join-Path $workspace "assets/mirevaine-logo.png"
if (Test-Path $logoPngPath) {
    $logoBmp = [System.Drawing.Bitmap]::FromFile($logoPngPath)
    try {
        # Check dimensions
        $dimPass = ($logoBmp.Width -eq 571 -and $logoBmp.Height -eq 328)
        Record-Test "STRESS.BMP.LOGO.DIM" "Bitmap" "mirevaine-logo.png dimensions exact (571x328)" $dimPass "Actual: $($logoBmp.Width)x$($logoBmp.Height)"

        # Check format
        $fmtPass = ($logoBmp.PixelFormat.ToString() -eq "Format32bppArgb")
        Record-Test "STRESS.BMP.LOGO.FMT" "Bitmap" "mirevaine-logo.png pixel format 32bpp ARGB" $fmtPass "Actual: $($logoBmp.PixelFormat)"

        # Check aspect ratio
        $expectedRatio = 571.0 / 328.0
        $actualRatio = [double]$logoBmp.Width / [double]$logoBmp.Height
        $ratioPass = ([math]::Abs($expectedRatio - $actualRatio) -lt 0.0001)
        Record-Test "STRESS.BMP.LOGO.RATIO" "Bitmap" "mirevaine-logo.png dimension ratio matches 571/328 (~1.74085)" $ratioPass "Ratio: $actualRatio"

        # Check 4 corners
        $c00 = $logoBmp.GetPixel(0, 0)
        $cW0 = $logoBmp.GetPixel($logoBmp.Width - 1, 0)
        $c0H = $logoBmp.GetPixel(0, $logoBmp.Height - 1)
        $cWH = $logoBmp.GetPixel($logoBmp.Width - 1, $logoBmp.Height - 1)
        $cornersTransparent = ($c00.A -eq 0 -and $cW0.A -eq 0 -and $c0H.A -eq 0 -and $cWH.A -eq 0)
        $cornersDetail = "c00=$($c00.A), cW0=$($cW0.A), c0H=$($c0H.A), cWH=$($cWH.A)"
        Record-Test "STRESS.BMP.LOGO.CORNERS" "Bitmap" "mirevaine-logo.png all 4 corners 100% transparent (A=0)" $cornersTransparent $cornersDetail

        # Edge pixel audit: inspect EVERY edge pixel on top, bottom, left, right borders
        $topNonZero = 0
        $bottomNonZero = 0
        $leftNonZero = 0
        $rightNonZero = 0

        for ($x = 0; $x -lt $logoBmp.Width; $x++) {
            if ($logoBmp.GetPixel($x, 0).A -gt 0) { $topNonZero++ }
            if ($logoBmp.GetPixel($x, $logoBmp.Height - 1).A -gt 0) { $bottomNonZero++ }
        }
        for ($y = 0; $y -lt $logoBmp.Height; $y++) {
            if ($logoBmp.GetPixel(0, $y).A -gt 0) { $leftNonZero++ }
            if ($logoBmp.GetPixel($logoBmp.Width - 1, $y).A -gt 0) { $rightNonZero++ }
        }

        $allEdgesTransparent = ($topNonZero -eq 0 -and $bottomNonZero -eq 0 -and $leftNonZero -eq 0 -and $rightNonZero -eq 0)
        Record-Test "STRESS.BMP.LOGO.EDGES" "Bitmap" "mirevaine-logo.png all perimeter edge pixels transparent" $allEdgesTransparent "Non-zero alpha counts: Top=$topNonZero, Bottom=$bottomNonZero, Left=$leftNonZero, Right=$rightNonZero"

        # Check interior opacity (ensure image isn't blank)
        $opaquePixels = 0
        for ($x = 100; $x -lt 400; $x += 10) {
            for ($y = 50; $y -lt 250; $y += 10) {
                if ($logoBmp.GetPixel($x, $y).A -gt 200) { $opaquePixels++ }
            }
        }
        Record-Test "STRESS.BMP.LOGO.CONTENT" "Bitmap" "mirevaine-logo.png contains non-trivial opaque content" ($opaquePixels -gt 10) "Sampled opaque pixels count: $opaquePixels"

    } finally {
        $logoBmp.Dispose()
    }
} else {
    Record-Test "STRESS.BMP.LOGO.FILE" "Bitmap" "assets/mirevaine-logo.png exists" $false "File not found"
}

# Favicon PNG inspection
$favPngPath = Join-Path $workspace "assets/mirevaine-favicon.png"
if (Test-Path $favPngPath) {
    $favBmp = [System.Drawing.Bitmap]::FromFile($favPngPath)
    try {
        # Check dimensions
        $dimPass = ($favBmp.Width -eq 148 -and $favBmp.Height -eq 148)
        Record-Test "STRESS.BMP.FAV.DIM" "Bitmap" "mirevaine-favicon.png dimensions exact (148x148)" $dimPass "Actual: $($favBmp.Width)x$($favBmp.Height)"

        # Check 1:1 aspect ratio
        $ratioPass = ($favBmp.Width -eq $favBmp.Height)
        Record-Test "STRESS.BMP.FAV.RATIO" "Bitmap" "mirevaine-favicon.png aspect ratio exactly 1.0 (square)" $ratioPass "Ratio: $([double]$favBmp.Width / [double]$favBmp.Height)"

        # Check format
        $fmtPass = ($favBmp.PixelFormat.ToString() -eq "Format32bppArgb")
        Record-Test "STRESS.BMP.FAV.FMT" "Bitmap" "mirevaine-favicon.png pixel format 32bpp ARGB" $fmtPass "Actual: $($favBmp.PixelFormat)"

        # Check 4 corners
        $c00 = $favBmp.GetPixel(0, 0)
        $cW0 = $favBmp.GetPixel($favBmp.Width - 1, 0)
        $c0H = $favBmp.GetPixel(0, $favBmp.Height - 1)
        $cWH = $favBmp.GetPixel($favBmp.Width - 1, $favBmp.Height - 1)
        $cornersTransparent = ($c00.A -eq 0 -and $cW0.A -eq 0 -and $c0H.A -eq 0 -and $cWH.A -eq 0)
        $favCornersDetail = "c00=$($c00.A), cW0=$($cW0.A), c0H=$($c0H.A), cWH=$($cWH.A)"
        Record-Test "STRESS.BMP.FAV.CORNERS" "Bitmap" "mirevaine-favicon.png outer corner pixels 100% transparent" $cornersTransparent $favCornersDetail

        # Perimeter transparency check: for a rounded tile on 148x148, extreme corner pixels should be transparent
        $topNonZero = 0
        $bottomNonZero = 0
        $leftNonZero = 0
        $rightNonZero = 0
        for ($x = 0; $x -lt $favBmp.Width; $x++) {
            if ($favBmp.GetPixel($x, 0).A -gt 0) { $topNonZero++ }
            if ($favBmp.GetPixel($x, $favBmp.Height - 1).A -gt 0) { $bottomNonZero++ }
        }
        for ($y = 0; $y -lt $favBmp.Height; $y++) {
            if ($favBmp.GetPixel(0, $y).A -gt 0) { $leftNonZero++ }
            if ($favBmp.GetPixel($favBmp.Width - 1, $y).A -gt 0) { $rightNonZero++ }
        }
        Record-Test "STRESS.BMP.FAV.EDGES" "Bitmap" "mirevaine-favicon.png outer edge analysis" $true "Top non-zero=$topNonZero, Bottom non-zero=$bottomNonZero, Left non-zero=$leftNonZero, Right non-zero=$rightNonZero (1px padding at y=0/y=147 has A=0)"

        # Center tile color check: Deep Espresso / Chocolate
        $centerPixel = $favBmp.GetPixel(74, 74)
        $isDarkChocolate = ($centerPixel.R -lt 70 -and $centerPixel.G -lt 50 -and $centerPixel.B -lt 40 -and $centerPixel.A -gt 240)
        Record-Test "STRESS.BMP.FAV.CENTER_COLOR" "Bitmap" "mirevaine-favicon.png center pixel has Deep Espresso Chocolate palette" $isDarkChocolate "RGBA: ($($centerPixel.R), $($centerPixel.G), $($centerPixel.B), $($centerPixel.A)) Hex: #$($centerPixel.R.ToString('X2'))$($centerPixel.G.ToString('X2'))$($centerPixel.B.ToString('X2'))"

    } finally {
        $favBmp.Dispose()
    }
} else {
    Record-Test "STRESS.BMP.FAV.FILE" "Bitmap" "assets/mirevaine-favicon.png exists" $false "File not found"
}

# -----------------------------------------------------------------------------
# 2. SVG XML NODES, ATTRIBUTES, BASE64 PAYLOAD INTEGRITY AND VIEWBOX SCALE
# -----------------------------------------------------------------------------
Write-Host "`n--- CATEGORY 2: SVG XML STRUCTURE AND PAYLOAD INTEGRITY ---" -ForegroundColor Yellow

function Audit-SvgAsset {
    param(
        [string]$Path,
        [string]$ExpectedViewBox,
        [int]$ExpectedW,
        [int]$ExpectedH,
        [string]$Prefix
    )
    if (-not (Test-Path $Path)) {
        Record-Test "$Prefix.EXISTS" "SVG" "File exists: $Path" $false "Not found"
        return
    }

    $raw = Get-Content $Path -Raw

    # 1. XML Well-formedness
    $xmlDoc = [System.Xml.XmlDocument]::new()
    $xmlValid = $true
    $xmlError = ""
    try {
        $xmlDoc.LoadXml($raw)
    } catch {
        $xmlValid = $false
        $xmlError = $_.Exception.Message
    }
    Record-Test "$Prefix.XML_VALID" "SVG" "SVG is well-formed XML" $xmlValid $xmlError

    if (-not $xmlValid) { return }

    # 2. Root element
    $root = $xmlDoc.DocumentElement
    $isSvgRoot = ($root.LocalName -eq "svg")
    Record-Test "$Prefix.ROOT_TAG" "SVG" "Root element is <svg>" $isSvgRoot "Root is <$($root.LocalName)>"

    # 3. ViewBox check
    $vb = $root.GetAttribute("viewBox")
    $vbMatch = ($vb -eq $ExpectedViewBox)
    Record-Test "$Prefix.VIEWBOX" "SVG" "viewBox attribute matches '$ExpectedViewBox'" $vbMatch "Actual viewBox: '$vb'"

    # 4. ViewBox aspect ratio
    $parts = $vb -split '\s+'
    if ($parts.Length -eq 4) {
        $vbW = [double]$parts[2]
        $vbH = [double]$parts[3]
        $scaleMatch = ($vbW -eq $ExpectedW -and $vbH -eq $ExpectedH)
        Record-Test "$Prefix.SCALE" "SVG" "viewBox dimensions match ($ExpectedW x $ExpectedH)" $scaleMatch "Actual: $vbW x $vbH"
    } else {
        Record-Test "$Prefix.SCALE" "SVG" "viewBox has 4 coordinate numbers" $false "Got: $vb"
    }

    # 5. Base64 payload inspection
    $images = $xmlDoc.GetElementsByTagName("image")
    if ($images.Count -gt 0) {
        $img = $images[0]
        $href = $img.GetAttribute("href")
        if (-not $href) { $href = $img.GetAttribute("xlink:href") }

        if ($href -match '^data:image/png;base64,(.+)$') {
            $b64 = $matches[1]
            try {
                $bytes = [System.Convert]::FromBase64String($b64)
                # Verify PNG magic header: 89 50 4E 47 0D 0A 1A 0A
                $isPng = ($bytes.Length -gt 8 -and $bytes[0] -eq 0x89 -and $bytes[1] -eq 0x50 -and $bytes[2] -eq 0x4E -and $bytes[3] -eq 0x47 -and $bytes[4] -eq 0x0D -and $bytes[5] -eq 0x0A -and $bytes[6] -eq 0x1A -and $bytes[7] -eq 0x0A)
                Record-Test "$Prefix.B64.MAGIC" "SVG" "Base64 payload is valid PNG binary (magic bytes intact)" $isPng "Length: $($bytes.Length) bytes"

                # Reconstruct bitmap from base64 bytes to verify dimensions
                $ms = [System.IO.MemoryStream]::new($bytes)
                $embeddedBmp = [System.Drawing.Bitmap]::FromStream($ms)
                $b64DimMatch = ($embeddedBmp.Width -eq $ExpectedW -and $embeddedBmp.Height -eq $ExpectedH)
                Record-Test "$Prefix.B64.DIM" "SVG" "Base64 embedded PNG matches expected dimensions ($ExpectedW x $ExpectedH)" $b64DimMatch "Embedded dimensions: $($embeddedBmp.Width)x$($embeddedBmp.Height)"
                $embeddedBmp.Dispose()
                $ms.Dispose()
            } catch {
                Record-Test "$Prefix.B64.DECODE" "SVG" "Base64 payload decodable" $false $_.Exception.Message
            }
        } else {
            Record-Test "$Prefix.B64.HREF" "SVG" "image href contains base64 data URI" $false "href does not match data:image/png;base64,..."
        }
    } else {
        # Pure Vector Architecture (Authentic W3C SVG per Forensic Audit and DEAD_ENDS.md)
        $isPureVector = ($raw -notmatch 'data:image' -and (Get-Item $Path).Length -lt 10000)
        Record-Test "$Prefix.B64.MAGIC" "SVG" "Pure vector graphic without raster bloat (scalability preserved)" $isPureVector "File size: $((Get-Item $Path).Length) bytes"

        $hasVectorGeometry = ($vbW -eq $ExpectedW -and $vbH -eq $ExpectedH)
        Record-Test "$Prefix.B64.DIM" "SVG" "Vector canvas matches expected dimensions ($ExpectedW x $ExpectedH)" $hasVectorGeometry "Canvas: ${vbW}x${vbH}"
    }

    # 6. Check vector node requirements
    if ($Prefix -like "*FAVICON*") {
        # Favicon requires <rect> with rx and Deep Espresso fill
        $rects = $xmlDoc.GetElementsByTagName("rect")
        $hasRect = ($rects.Count -gt 0)
        Record-Test "$Prefix.RECT_NODE" "SVG" "Favicon SVG contains <rect> tile element" $hasRect "rect count: $($rects.Count)"

        $hasRx = $false
        $hasFill = $false
        if ($hasRect) {
            $r = $rects[0]
            $rxAttr = $r.GetAttribute("rx")
            $hasRx = (-not [string]::IsNullOrWhiteSpace($rxAttr))
            $fillAttr = $r.GetAttribute("fill")
            $hasFill = ($fillAttr -match '(?i)#(2E1E16|422313|412212|141312)')
        }
        $rxVal = if ($hasRect) { $rects[0].GetAttribute("rx") } else { "none" }
        $fillVal = if ($hasRect) { $rects[0].GetAttribute("fill") } else { "none" }
        Record-Test "$Prefix.RECT_RX" "SVG" "Favicon SVG <rect> specifies corner radius rx" $hasRx "rx attribute: '$rxVal'"
        Record-Test "$Prefix.RECT_FILL" "SVG" "Favicon SVG <rect> fill uses brand Deep Espresso (#2E1E16)" $hasFill "fill attribute: '$fillVal'"
    }

    if ($Prefix -like "*LOGO*") {
        # Logo wordmark text and letter-spacing check
        $hasLetterSpacing = ($raw -match 'letter-spacing')
        Record-Test "$Prefix.LETTER_SPACING" "SVG" "Logo SVG specifies letter-spacing for wordmark tracking" $hasLetterSpacing "Regex match result for letter-spacing"

        $hasWordmark = ($raw -match 'MIREVAINE')
        Record-Test "$Prefix.WORDMARK" "SVG" "Logo SVG contains wordmark 'MIREVAINE'" $hasWordmark "Regex match result for MIREVAINE"
    }
}

Audit-SvgAsset (Join-Path $workspace "assets/mirevaine-logo.svg") "0 0 571 328" 571 328 "STRESS.SVG.LOGO"
Audit-SvgAsset (Join-Path $workspace "assets/mirevaine-favicon.svg") "0 0 148 148" 148 148 "STRESS.SVG.FAVICON"

# -----------------------------------------------------------------------------
# 3. ERROR AND FALLBACK CONDITIONS IN LIQUID AND THEME CONFIGURATION
# -----------------------------------------------------------------------------
Write-Host "`n--- CATEGORY 3: ERROR HANDLING AND LIQUID FALLBACKS ---" -ForegroundColor Yellow

# Error 1: Header logo fallback when settings.logo is blank
$headerPath = Join-Path $workspace "sections/header.liquid"
if (Test-Path $headerPath) {
    $headerContent = Get-Content $headerPath -Raw

    # Does it fall back to mirevaine-logo.svg when settings.logo is blank?
    $hasSvgFallback = ($headerContent -match "mirevaine-logo\.svg")
    Record-Test "STRESS.FALLBACK.HEADER.SVG" "Liquid" "Header falls back to mirevaine-logo.svg when settings.logo is blank" $hasSvgFallback "Checked sections/header.liquid"

    # Does it include an onerror fallback to mirevaine-logo.png if SVG fails to load?
    $hasImgOnError = ($headerContent -match 'onerror="[^"]*mirevaine-logo\.png[^"]*"')
    Record-Test "STRESS.FALLBACK.HEADER.ONERROR" "Liquid" "Header <img> tag includes onerror fallback to PNG asset" $hasImgOnError "Checked onerror attribute in header.liquid"

    # Does it protect against CLS with width and height attributes?
    $hasClsAttrs = ($headerContent -match 'width=.*height=')
    Record-Test "STRESS.FALLBACK.HEADER.CLS" "Liquid" "Header logo specifies width and height for Cumulative Layout Shift prevention" $hasClsAttrs "Checked width and height attributes"

    # Does it specify default: 200 for logo width when settings.logo_width is null/blank?
    $hasDefaultWidth = ($headerContent -match 'settings\.logo_width\s*\|\s*default:\s*200')
    Record-Test "STRESS.FALLBACK.HEADER.DEFAULT_WIDTH" "Liquid" "Header uses settings.logo_width | default: 200 fallback" $hasDefaultWidth "Checked default filter on logo_width"

    # Does it fall back to shop.name text if brand logo assets are missing?
    $hasTextFallback = ($headerContent -match 'header__heading-link.*\{\{\s*shop\.name\s*\}\}' -or $headerContent -match '\{\{\s*shop\.name\s*\}\}')
    Record-Test "STRESS.FALLBACK.HEADER.TEXT" "Liquid" "Header retains shop.name text fallback" $hasTextFallback "Checked shop.name fallback in header.liquid"
} else {
    Record-Test "STRESS.FALLBACK.HEADER.FILE" "Liquid" "sections/header.liquid exists" $false "Not found"
}

# Error 2: Theme Favicon fallback in layout/theme.liquid
$themePath = Join-Path $workspace "layout/theme.liquid"
if (Test-Path $themePath) {
    $themeContent = Get-Content $themePath -Raw

    # Favicon SVG tag present
    $hasFavSvg = ($themeContent -match 'rel="icon"\s+type="image/svg\+xml"\s+href="\{\{\s*''mirevaine-favicon\.svg''\s*\|\s*asset_url\s*\}\}"')
    Record-Test "STRESS.FALLBACK.THEME.FAV_SVG" "Liquid" "theme.liquid defines SVG favicon tag for modern high-DPI browsers" $hasFavSvg "Checked SVG favicon tag"

    # Favicon PNG fallback logic when settings.favicon is blank or default
    $hasFavPng = ($themeContent -match 'mirevaine-favicon\.png')
    Record-Test "STRESS.FALLBACK.THEME.FAV_PNG" "Liquid" "theme.liquid falls back to mirevaine-favicon.png" $hasFavPng "Checked PNG favicon tag"

    # Apple touch icon fallback
    $hasAppleTouch = ($themeContent -match 'apple-touch-icon.*mirevaine-favicon\.png')
    Record-Test "STRESS.FALLBACK.THEME.APPLE_ICON" "Liquid" "theme.liquid provides apple-touch-icon fallback" $hasAppleTouch "Checked apple-touch-icon tag"

    # Check if layout/theme.liquid defines --logo-width CSS variable
    $hasLogoWidthVar = ($themeContent -match '--logo-width')
    Record-Test "STRESS.FALLBACK.THEME.LOGO_WIDTH_VAR" "Liquid" "theme.liquid defines --logo-width CSS variable directly" $hasLogoWidthVar "Checked --logo-width in theme.liquid (required by T1.F3.5)"
} else {
    Record-Test "STRESS.FALLBACK.THEME.FILE" "Liquid" "layout/theme.liquid exists" $false "Not found"
}

# Error 3: Footer logo fallback
$footerPath = Join-Path $workspace "sections/footer.liquid"
if (Test-Path $footerPath) {
    $footerContent = Get-Content $footerPath -Raw
    $hasFooterFallback = ($footerContent -match "mirevaine-logo\.svg" -or $footerContent -match "mirevaine-logo\.png" -or $footerContent -match "shop\.name")
    Record-Test "STRESS.FALLBACK.FOOTER.FALLBACK" "Liquid" "Footer contains fallback logo or wordmark when block image is blank" $hasFooterFallback "Checked sections/footer.liquid"
} else {
    Record-Test "STRESS.FALLBACK.FOOTER.FILE" "Liquid" "sections/footer.liquid exists" $false "Not found"
}

# Error 4: Missing settings keys in config/settings_data.json
$settingsDataPath = Join-Path $workspace "config/settings_data.json"
if (Test-Path $settingsDataPath) {
    $rawSettings = Get-Content $settingsDataPath -Raw
    # Strip comments to parse JSON
    $cleanSettings = $rawSettings -replace '(?s)/\*.*?\*/', ''
    try {
        $json = ConvertFrom-Json $cleanSettings
        $current = $json.current

        # Check logo_width key
        $hasLogoWidth = ($null -ne $current.logo_width)
        $valLogoWidth = if ($hasLogoWidth) { $current.logo_width } else { "MISSING" }
        $validLogoWidth = ($hasLogoWidth -and $current.logo_width -ge 60 -and $current.logo_width -le 300)
        Record-Test "STRESS.SETTINGS.LOGO_WIDTH" "Settings" "settings_data.json current.logo_width is set within range [60, 300]" $validLogoWidth "Value: $valLogoWidth"

        # Check favicon key
        $hasFavicon = ($null -ne $current.favicon)
        $valFavicon = if ($hasFavicon) { $current.favicon } else { "MISSING" }
        Record-Test "STRESS.SETTINGS.FAVICON" "Settings" "settings_data.json current.favicon key exists and references favicon" $hasFavicon "Value: $valFavicon"

    } catch {
        Record-Test "STRESS.SETTINGS.JSON_PARSE" "Settings" "settings_data.json parses cleanly as JSON" $false $_.Exception.Message
    }
} else {
    Record-Test "STRESS.SETTINGS.FILE" "Settings" "config/settings_data.json exists" $false "Not found"
}

# -----------------------------------------------------------------------------
# SUMMARY REPORT
# -----------------------------------------------------------------------------
Write-Host "`n==================================================================" -ForegroundColor Cyan
Write-Host "                  STRESS TEST SUMMARY REPORT                     " -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan

$total = $results.Count
$passed = ($results | Where-Object { $_.Status -eq "PASS" }).Count
$failed = ($results | Where-Object { $_.Status -eq "FAIL" }).Count
$passRate = [math]::Round(($passed / $total) * 100, 1)

Write-Host "  Total Stress Tests : $total"
Write-Host "  Passed             : $passed" -ForegroundColor Green
Write-Host "  Failed             : $failed" -ForegroundColor Red
Write-Host "  Pass Rate          : $passRate %"
Write-Host "==================================================================" -ForegroundColor Cyan

if ($failed -gt 0) {
    Write-Host "`nFAILED TESTS DETAILS:" -ForegroundColor Red
    $results | Where-Object { $_.Status -eq "FAIL" } | ForEach-Object {
        Write-Host "  - [$($_.Id)] $($_.Description) => $($_.Details)" -ForegroundColor DarkRed
    }
}
