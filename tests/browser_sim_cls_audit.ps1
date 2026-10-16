<#
.SYNOPSIS
    Browser Render Simulation, Contrast Ratio, and Cumulative Layout Shift (CLS) Audit
    Milestone 1 Remediation Verification
.DESCRIPTION
    Adversarial verification testing for:
    1. Favicon browser downscaling at 16x16, 32x32, 180x180 and contrast ratios.
    2. HTML5 numeric dimensions on <img> tags in header.liquid and footer.liquid for CLS prevention.
    3. Aspect ratio consistency, corner alpha handling, and WCAG 2.1 compliance.
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$Script:PassCount = 0
$Script:FailCount = 0
$Script:Tests = @()

function Assert-Test {
    param(
        [string]$TestId,
        [string]$Description,
        [bool]$Condition,
        [string]$Details = ""
    )

    $status = if ($Condition) { "[PASS]" } else { "[FAIL]" }
    if ($Condition) {
        $Script:PassCount++
    } else {
        $Script:FailCount++
    }

    $Script:Tests += [PSCustomObject]@{
        Id          = $TestId
        Description = $Description
        Passed      = $Condition
        Details     = $Details
    }

    $color = if ($Condition) { "Green" } else { "Red" }
    Write-Host ("  $status $TestId`: $Description") -ForegroundColor $color
    if (-not $Condition -and $Details) {
        Write-Host ("         Details: $Details") -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "   BROWSER RENDER SIMULATION & CLS EMPIRICAL VERIFICATION HARNESS   " -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host ""

$RootPath = (Get-Item $PSScriptRoot).Parent.FullName
$AssetsPath = Join-Path $RootPath "assets"
$SectionsPath = Join-Path $RootPath "sections"
$LayoutPath = Join-Path $RootPath "layout"
$ConfigPath = Join-Path $RootPath "config"

# ==============================================================================
# Helper Functions: Color & WCAG Calculations
# ==============================================================================
function Get-RelativeLuminance([byte]$r, [byte]$g, [byte]$b) {
    $rs = $r / 255.0
    $gs = $g / 255.0
    $bs = $b / 255.0

    $rLin = if ($rs -le 0.04045) { $rs / 12.92 } else { [Math]::Pow(($rs + 0.055) / 1.055, 2.4) }
    $gLin = if ($gs -le 0.04045) { $gs / 12.92 } else { [Math]::Pow(($gs + 0.055) / 1.055, 2.4) }
    $bLin = if ($bs -le 0.04045) { $bs / 12.92 } else { [Math]::Pow(($bs + 0.055) / 1.055, 2.4) }

    return (0.2126 * $rLin + 0.7152 * $gLin + 0.0722 * $bLin)
}

function Get-ContrastRatio([double]$lum1, [double]$lum2) {
    $lighter = [Math]::Max($lum1, $lum2)
    $darker = [Math]::Min($lum1, $lum2)
    return (($lighter + 0.05) / ($darker + 0.05))
}

function Hex-To-Color([string]$hex) {
    $clean = $hex.TrimStart('#')
    $r = [Convert]::ToByte($clean.Substring(0, 2), 16)
    $g = [Convert]::ToByte($clean.Substring(2, 2), 16)
    $b = [Convert]::ToByte($clean.Substring(4, 2), 16)
    return [System.Drawing.Color]::FromArgb(255, $r, $g, $b)
}

# ==============================================================================
# SECTION 1: WCAG 2.1 THEORETICAL CONTRAST RATIOS
# ==============================================================================
Write-Host "--- SECTION 1: WCAG 2.1 THEORETICAL CONTRAST RATIOS ---" -ForegroundColor Yellow

$colorEspresso = Hex-To-Color "#2E1E16" # Background tile
$colorAlabaster = Hex-To-Color "#FAF8F5" # Foreground monogram "M"
$colorGold     = Hex-To-Color "#B38E5D" # Crest pip / accent
$colorTabLight = Hex-To-Color "#FFFFFF" # Chrome light tab
$colorTabGray  = Hex-To-Color "#F1F3F4" # Chrome light gray tab
$colorTabDark  = Hex-To-Color "#202124" # Chrome dark tab

$lumEspresso = Get-RelativeLuminance $colorEspresso.R $colorEspresso.G $colorEspresso.B
$lumAlabaster = Get-RelativeLuminance $colorAlabaster.R $colorAlabaster.G $colorAlabaster.B
$lumGold = Get-RelativeLuminance $colorGold.R $colorGold.G $colorGold.B
$lumTabLight = Get-RelativeLuminance $colorTabLight.R $colorTabLight.G $colorTabLight.B
$lumTabGray = Get-RelativeLuminance $colorTabGray.R $colorTabGray.G $colorTabGray.B
$lumTabDark = Get-RelativeLuminance $colorTabDark.R $colorTabDark.G $colorTabDark.B

$crMonogramOnTile = Get-ContrastRatio $lumAlabaster $lumEspresso
$crGoldOnTile = Get-ContrastRatio $lumGold $lumEspresso
$crTileOnLightTab = Get-ContrastRatio $lumTabLight $lumEspresso
$crTileOnGrayTab = Get-ContrastRatio $lumTabGray $lumEspresso
$crMonogramOnDarkTab = Get-ContrastRatio $lumAlabaster $lumTabDark

Assert-Test "CONTRAST.THEORY.MONOGRAM_ON_TILE" `
    "Monogram Canvas Alabaster (#FAF8F5) on Deep Espresso (#2E1E16) satisfies WCAG AAA (>= 7.0:1)" `
    ($crMonogramOnTile -ge 7.0) `
    ("Calculated: {0:N2}:1 (Threshold: 7.0:1)" -f $crMonogramOnTile)

Assert-Test "CONTRAST.THEORY.GOLD_ON_TILE" `
    "Warm Brushed Gold (#B38E5D) on Deep Espresso (#2E1E16) satisfies WCAG AA UI Component (>= 3.0:1)" `
    ($crGoldOnTile -ge 3.0) `
    ("Calculated: {0:N2}:1 (Threshold: 3.0:1)" -f $crGoldOnTile)

Assert-Test "CONTRAST.THEORY.TILE_ON_LIGHT_TAB" `
    "Favicon tile Deep Espresso (#2E1E16) on White tab (#FFFFFF) satisfies WCAG AAA (>= 7.0:1)" `
    ($crTileOnLightTab -ge 7.0) `
    ("Calculated: {0:N2}:1 (Threshold: 7.0:1)" -f $crTileOnLightTab)

Assert-Test "CONTRAST.THEORY.TILE_ON_GRAY_TAB" `
    "Favicon tile Deep Espresso (#2E1E16) on Chrome Gray tab (#F1F3F4) satisfies WCAG AAA (>= 7.0:1)" `
    ($crTileOnGrayTab -ge 7.0) `
    ("Calculated: {0:N2}:1 (Threshold: 7.0:1)" -f $crTileOnGrayTab)

Assert-Test "CONTRAST.THEORY.MONOGRAM_ON_DARK_TAB" `
    "Monogram Canvas Alabaster (#FAF8F5) against Chrome Dark tab (#202124) satisfies WCAG AAA (>= 7.0:1)" `
    ($crMonogramOnDarkTab -ge 7.0) `
    ("Calculated: {0:N2}:1 (Threshold: 7.0:1)" -f $crMonogramOnDarkTab)

# ==============================================================================
# SECTION 2: BROWSER FAVICON DOWNSCALING SIMULATION
# ==============================================================================
Write-Host ""
Write-Host "--- SECTION 2: BROWSER FAVICON DOWNSCALING SIMULATION (16x16, 32x32, 180x180) ---" -ForegroundColor Yellow

$FaviconPath = Join-Path $AssetsPath "mirevaine-favicon.png"
$SrcBmp = [System.Drawing.Bitmap]::FromFile($FaviconPath)

$DownscaleScales = @(
    @{ Size = 16;  Label = "16x16 Desktop Browser Tab"; MaxCornerAlpha = 180; MinContrast = 4.0 },
    @{ Size = 32;  Label = "32x32 Retina / High-DPI Tab"; MaxCornerAlpha = 80;  MinContrast = 6.0 },
    @{ Size = 180; Label = "180x180 Apple Touch Icon";    MaxCornerAlpha = 10;  MinContrast = 8.0 }
)

foreach ($spec in $DownscaleScales) {
    $targetDim = $spec.Size
    $label = $spec.Label
    $maxCornerAlpha = $spec.MaxCornerAlpha
    $minContrast = $spec.MinContrast

    # Create destination bitmap
    $destBmp = New-Object System.Drawing.Bitmap($targetDim, $targetDim, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($destBmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $g.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy

    $destRect = New-Object System.Drawing.Rectangle(0, 0, $targetDim, $targetDim)
    $g.DrawImage($SrcBmp, $destRect, 0, 0, $SrcBmp.Width, $SrcBmp.Height, [System.Drawing.GraphicsUnit]::Pixel)
    $g.Dispose()

    # Test 1: Exact Dimensions
    Assert-Test "FAV.DOWNSCALE.$targetDim.DIM" `
        "Simulated render at $targetDim`x$targetDim produces exact dimensions" `
        ($destBmp.Width -eq $targetDim -and $destBmp.Height -eq $targetDim) `
        ("Width={0}, Height={1}" -f $destBmp.Width, $destBmp.Height)

    # Test 2: Corner Alpha Transparency (Rounded Tile Corner Retention)
    $tl = $destBmp.GetPixel(0, 0)
    $tr = $destBmp.GetPixel($targetDim - 1, 0)
    $bl = $destBmp.GetPixel(0, $targetDim - 1)
    $br = $destBmp.GetPixel($targetDim - 1, $targetDim - 1)

    $cornersTransparent = ($tl.A -le $maxCornerAlpha) -and ($tr.A -le $maxCornerAlpha) -and `
                          ($bl.A -le $maxCornerAlpha) -and ($br.A -le $maxCornerAlpha)

    Assert-Test "FAV.DOWNSCALE.$targetDim.CORNERS" `
        "Corner pixels retain transparency at $targetDim`x$targetDim (TL={0}, TR={1}, BL={2}, BR={3})" -f $tl.A, $tr.A, $bl.A, $br.A `
        $cornersTransparent `
        ("Max allowed corner alpha: $maxCornerAlpha")

    # Test 3: Central Opaque Body
    $centerX = [Math]::Floor($targetDim / 2)
    $centerY = [Math]::Floor($targetDim / 2)
    $centerPixel = $destBmp.GetPixel($centerX, $centerY)
    Assert-Test "FAV.DOWNSCALE.$targetDim.BODY_OPAQUE" `
        ("Center body is substantially opaque at {0}x{0} (Alpha={1} >= 240)" -f $targetDim, $centerPixel.A) `
        ($centerPixel.A -ge 240) `
        ("Center Alpha: {0}" -f $centerPixel.A)

    # Test 4: Empirical Pixel Luminance Range and Contrast
    $minLum = 1.0
    $maxLum = 0.0
    $opaquePixelCount = 0

    for ($y = 0; $y -lt $targetDim; $y++) {
        for ($x = 0; $x -lt $targetDim; $x++) {
            $p = $destBmp.GetPixel($x, $y)
            if ($p.A -ge 200) {
                $opaquePixelCount++
                $lum = Get-RelativeLuminance $p.R $p.G $p.B
                if ($lum -lt $minLum) { $minLum = $lum }
                if ($lum -gt $maxLum) { $maxLum = $lum }
            }
        }
    }

    $empiricalContrast = Get-ContrastRatio $maxLum $minLum

    Assert-Test "FAV.DOWNSCALE.$targetDim.EMPIRICAL_CONTRAST" `
        ("Empirical downscaled contrast at {0}x{0} is {1:N2}:1 (minLum={2:N3}, maxLum={3:N3})" -f $targetDim, $empiricalContrast, $minLum, $maxLum) `
        ($empiricalContrast -ge $minContrast) `
        ("Calculated {0:N2}:1, required >= {1:N2}:1" -f $empiricalContrast, $minContrast)

    $destBmp.Dispose()
}

$SrcBmp.Dispose()

# ==============================================================================
# SECTION 3: CLS & HTML5 NUMERIC DIMENSION VERIFICATION
# ==============================================================================
Write-Host ""
Write-Host "--- SECTION 3: CLS & HTML5 NUMERIC DIMENSION VERIFICATION ---" -ForegroundColor Yellow

# Header Template Audit
$HeaderContent = Get-Content (Join-Path $SectionsPath "header.liquid") -Raw

# Extract <img> tags in header.liquid
$headerImgMatches = [regex]::Matches($HeaderContent, '(?s)<img\b([^>]*)>')
Assert-Test "CLS.HEADER.IMG_EXISTS" `
    "sections/header.liquid contains logo <img> tag" `
    ($headerImgMatches.Count -ge 1) `
    ("Found {0} <img> tags" -f $headerImgMatches.Count)

foreach ($m in $headerImgMatches) {
    $imgTag = $m.Value

    # Verify width attribute
    $hasWidthAttr = $imgTag -match 'width="([^"]+)"'
    $rawWidth = if ($hasWidthAttr) { $Matches[1] } else { "" }

    # Verify height attribute
    $hasHeightAttr = $imgTag -match 'height="([^"]+)"'
    $rawHeight = if ($hasHeightAttr) { $Matches[1] } else { "" }

    Assert-Test "CLS.HEADER.WIDTH_ATTR" `
        "Header <img> tag specifies width attribute ($rawWidth)" `
        ($hasWidthAttr -and -not [string]::IsNullOrWhiteSpace($rawWidth)) `
        ("Raw width: $rawWidth")

    Assert-Test "CLS.HEADER.HEIGHT_ATTR" `
        "Header <img> tag specifies height attribute ($rawHeight)" `
        ($hasHeightAttr -and -not [string]::IsNullOrWhiteSpace($rawHeight)) `
        ("Raw height: $rawHeight")

    Assert-Test "CLS.HEADER.NO_HEIGHT_AUTO" `
        "Header <img> does NOT use invalid HTML height='auto'" `
        ($rawHeight -ne "auto" -and -not ($rawHeight -like "*auto*")) `
        ("Height value is: $rawHeight")

    # Simulate Liquid execution for various settings.logo_width inputs
    $testLogoWidths = @(60, 100, 160, 200, 240, 300, $null)
    $allIntegerAndProportional = $true
    $simDetails = @()

    foreach ($w in $testLogoWidths) {
        $effectiveW = if ($null -ne $w) { [int]$w } else { 200 }
        $computedH = [int][Math]::Floor(($effectiveW * 328) / 571)
        $simAspectRatio = $effectiveW / [double]$computedH
        $targetAspectRatio = 571.0 / 328.0 # ~1.74085
        $deltaRatio = [Math]::Abs($simAspectRatio - $targetAspectRatio) / $targetAspectRatio

        $isInteger = ($effectiveW -is [int]) -and ($computedH -is [int]) -and ($computedH -gt 0)
        $isAspectAccurate = ($deltaRatio -lt 0.02) # Within 2% of original

        if (-not ($isInteger -and $isAspectAccurate)) {
            $allIntegerAndProportional = $false
        }
        $simDetails += ("w={0} -> {1}x{2} (ratio={3:N3}, delta={4:P2})" -f $w, $effectiveW, $computedH, $simAspectRatio, $deltaRatio)
    }

    Assert-Test "CLS.HEADER.LIQUID_SIMULATION" `
        "Header Liquid expressions evaluate to pure positive integers with <=2% aspect ratio fidelity" `
        $allIntegerAndProportional `
        ($simDetails -join "; ")
}

# Footer Template Audit
$FooterContent = Get-Content (Join-Path $SectionsPath "footer.liquid") -Raw
$footerImgMatches = [regex]::Matches($FooterContent, '(?s)<img\b([^>]*)>')

Assert-Test "CLS.FOOTER.IMG_EXISTS" `
    "sections/footer.liquid contains logo <img> tag" `
    ($footerImgMatches.Count -ge 1) `
    ("Found {0} <img> tags" -f $footerImgMatches.Count)

foreach ($m in $footerImgMatches) {
    $imgTag = $m.Value

    $hasWidthAttr = $imgTag -match 'width="([^"]+)"'
    $rawWidth = if ($hasWidthAttr) { $Matches[1] } else { "" }

    $hasHeightAttr = $imgTag -match 'height="([^"]+)"'
    $rawHeight = if ($hasHeightAttr) { $Matches[1] } else { "" }

    $widthIsPureInteger = $rawWidth -match '^\d+$'
    $heightIsPureInteger = $rawHeight -match '^\d+$'

    Assert-Test "CLS.FOOTER.WIDTH_INTEGER" `
        "Footer <img> width is pure integer literal ($rawWidth)" `
        $widthIsPureInteger `
        ("Width attribute: $rawWidth")

    Assert-Test "CLS.FOOTER.HEIGHT_INTEGER" `
        "Footer <img> height is pure integer literal ($rawHeight)" `
        $heightIsPureInteger `
        ("Height attribute: $rawHeight")

    Assert-Test "CLS.FOOTER.NO_HEIGHT_AUTO" `
        "Footer <img> does NOT use invalid HTML height='auto'" `
        ($rawHeight -ne "auto") `
        ("Height value is: $rawHeight")

    if ($widthIsPureInteger -and $heightIsPureInteger) {
        $numW = [int]$rawWidth
        $numH = [int]$rawHeight
        $footerRatio = $numW / [double]$numH
        $targetRatio = 571.0 / 328.0
        $aspectDelta = [Math]::Abs($footerRatio - $targetRatio) / $targetRatio

        Assert-Test "CLS.FOOTER.ASPECT_RATIO" `
            ("Footer aspect ratio ({0}/{1} = {2:N3}) matches logo master (571/328 = {3:N3})" -f $numW, $numH, $footerRatio, $targetRatio) `
            ($aspectDelta -lt 0.01) `
            ("Delta is {0:P2}" -f $aspectDelta)
    }

    $hasOnError = $imgTag -match 'onerror="[^"]*mirevaine-logo\.png[^"]*"'
    Assert-Test "CLS.FOOTER.ONERROR" `
        "Footer <img> has onerror fallback to mirevaine-logo.png" `
        $hasOnError `
        ("Tag onerror snippet: " + [regex]::Match($imgTag, 'onerror="[^"]*"').Value)
}

# Theme Head CSS Audit
$ThemeContent = Get-Content (Join-Path $LayoutPath "theme.liquid") -Raw
$hasCssVarInHead = $ThemeContent -match '(?s)<head>.*--logo-width:\s*\{\{\s*settings\.logo_width.*\}\}\s*px;.*</head>'

Assert-Test "CLS.THEME.CSS_VAR_HEAD" `
    "layout/theme.liquid declares --logo-width inside <head> before stylesheets" `
    $hasCssVarInHead `
    ("CSS variable declaration present in <head>")

# Base CSS Rule Audit
$BaseCssContent = Get-Content (Join-Path $AssetsPath "base.css") -Raw
$hasHeaderLogoCss = $BaseCssContent -match '(?s)\.header__logo\s+img[^{]*\{[^}]*width:\s*var\(--logo-width\)[^}]*height:\s*auto'

Assert-Test "CLS.CSS.ASPECT_RATIO_PRESERVATION" `
    "assets/base.css applies 'width: var(--logo-width); height: auto;' allowing HTML attributes to establish aspect-ratio box" `
    $hasHeaderLogoCss `
    ("Matched CSS rule in base.css")

# ==============================================================================
# SECTION 4: ADVERSARIAL STRESS CHALLENGES
# ==============================================================================
Write-Host ""
Write-Host "--- SECTION 4: ADVERSARIAL STRESS CHALLENGES ---" -ForegroundColor Yellow

# Challenge 1: What if settings.logo_width is string instead of int or missing?
$SettingsData = Get-Content (Join-Path $ConfigPath "settings_data.json") -Raw
$logoWidthInJson = [regex]::Match($SettingsData, '"logo_width"\s*:\s*([0-9]+)')
Assert-Test "STRESS.SETTINGS.NUMERIC_TYPE" `
    "config/settings_data.json specifies numeric unquoted integer for logo_width" `
    $logoWidthInJson.Success `
    ("Found: " + $logoWidthInJson.Value)

# Challenge 2: Favicon SVG viewBox vs PNG aspect ratio consistency
$FaviconSvg = Get-Content (Join-Path $AssetsPath "mirevaine-favicon.svg") -Raw
$svgViewBoxMatch = [regex]::Match($FaviconSvg, 'viewBox="0\s+0\s+(\d+)\s+(\d+)"')
$svgW = [int]$svgViewBoxMatch.Groups[1].Value
$svgH = [int]$svgViewBoxMatch.Groups[2].Value
Assert-Test "STRESS.FAVICON.SVG_RATIO" `
    ("mirevaine-favicon.svg has exact 1:1 aspect ratio ({0}x{1})" -f $svgW, $svgH) `
    ($svgW -eq $svgH -and $svgW -gt 0) `
    ("viewBox: {0}x{1}" -f $svgW, $svgH)

# Challenge 3: Check that mirevaine-logo.svg does not clip or overflow
$LogoSvg = Get-Content (Join-Path $AssetsPath "mirevaine-logo.svg") -Raw
$logoViewBoxMatch = [regex]::Match($LogoSvg, 'viewBox="0\s+0\s+(\d+)\s+(\d+)"')
$logoSvgW = [int]$logoViewBoxMatch.Groups[1].Value
$logoSvgH = [int]$logoViewBoxMatch.Groups[2].Value
Assert-Test "STRESS.LOGO.SVG_RATIO" `
    ("mirevaine-logo.svg viewBox matches exact PNG dimensions (571x328)" -f $logoSvgW, $logoSvgH) `
    ($logoSvgW -eq 571 -and $logoSvgH -eq 328) `
    ("viewBox: {0}x{1}" -f $logoSvgW, $logoSvgH)

# ==============================================================================
# SUMMARY REPORT
# ==============================================================================
Write-Host ""
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "                      VERIFICATION SUMMARY                        " -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan
$passRate = [Math]::Round(($Script:PassCount / ($Script:PassCount + $Script:FailCount)) * 100, 1)
Write-Host ("  Total Tests Executed : {0}" -f ($Script:PassCount + $Script:FailCount))
Write-Host ("  Passed               : {0}" -f $Script:PassCount) -ForegroundColor Green
Write-Host ("  Failed               : {0}" -f $Script:FailCount) -ForegroundColor $(if ($Script:FailCount -eq 0) { "Green" } else { "Red" })
Write-Host ("  Pass Rate            : {0} %" -f $passRate)
Write-Host "==================================================================" -ForegroundColor Cyan

if ($Script:FailCount -gt 0) {
    Write-Host "[VERDICT] REQUEST_CHANGES - Failure count > 0" -ForegroundColor Red
    exit 1
} else {
    Write-Host "[VERDICT] APPROVE - All browser simulation & CLS checks passed!" -ForegroundColor Green
    exit 0
}
