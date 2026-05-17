$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$distDir = Join-Path $root "dist"
$assetDir = Join-Path $distDir "store-assets"
New-Item -ItemType Directory -Force -Path $assetDir | Out-Null

function New-Brush($hex) {
  return New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml($hex))
}

function Draw-Text($graphics, $text, $font, $brush, $x, $y, $width, $height) {
  $format = New-Object System.Drawing.StringFormat
  $format.Alignment = [System.Drawing.StringAlignment]::Near
  $format.LineAlignment = [System.Drawing.StringAlignment]::Near
  $graphics.DrawString($text, $font, $brush, (New-Object System.Drawing.RectangleF($x, $y, $width, $height)), $format)
  $format.Dispose()
}

function Save-Cover($path) {
  $bitmap = New-Object System.Drawing.Bitmap(1600, 1200)
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

  $background = New-Brush "#f8fafc"
  $ink = New-Brush "#101828"
  $muted = New-Brush "#475467"
  $green = New-Brush "#27ae60"
  $blue = New-Brush "#2563eb"
  $panel = New-Brush "#ffffff"
  $line = New-Brush "#d0d5dd"
  $error = New-Brush "#b42318"
  $warn = New-Brush "#b54708"

  $graphics.FillRectangle($background, 0, 0, 1600, 1200)
  $graphics.FillRectangle($green, 0, 0, 1600, 28)
  $graphics.FillRectangle($blue, 0, 28, 1600, 10)

  $titleFont = New-Object System.Drawing.Font("Segoe UI", 76, [System.Drawing.FontStyle]::Bold)
  $subtitleFont = New-Object System.Drawing.Font("Segoe UI", 34, [System.Drawing.FontStyle]::Regular)
  $labelFont = New-Object System.Drawing.Font("Segoe UI", 26, [System.Drawing.FontStyle]::Bold)
  $bodyFont = New-Object System.Drawing.Font("Consolas", 26, [System.Drawing.FontStyle]::Regular)

  Draw-Text $graphics "Godot Add-on Auditor" $titleFont $ink 96 108 1200 110
  Draw-Text $graphics "Catch plugin.cfg, script path, README, license, and package-noise issues before a Godot 4 add-on release." $subtitleFont $muted 102 234 1240 150

  $graphics.FillRectangle($panel, 104, 455, 1392, 560)
  $pen = New-Object System.Drawing.Pen([System.Drawing.ColorTranslator]::FromHtml("#d0d5dd"), 4)
  $graphics.DrawRectangle($pen, 104, 455, 1392, 560)
  Draw-Text $graphics "Release check preview" $labelFont $ink 152 505 600 46

  $rows = @(
    @{ Mark = "OK"; Color = $green; Text = "addons/quick_spawn/plugin.cfg has required metadata" },
    @{ Mark = "OK"; Color = $green; Text = "plugin.gd exists and extends EditorPlugin" },
    @{ Mark = "WARN"; Color = $warn; Text = "exclude .godot and .import from upload archives" },
    @{ Mark = "ERR"; Color = $error; Text = "broken_tool plugin/script points to missing_plugin.gd" }
  )

  $y = 610
  foreach ($row in $rows) {
    $graphics.FillRectangle($line, 152, $y + 52, 1180, 2)
    Draw-Text $graphics ("[" + $row.Mark + "]") $bodyFont $row.Color 152 $y 130 42
    Draw-Text $graphics $row.Text $bodyFont $ink 300 $y 1000 42
    $y += 92
  }

  Draw-Text $graphics "Free CLI for Godot 4 add-on authors" $labelFont $blue 152 920 720 52

  $bitmap.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)

  $pen.Dispose()
  $titleFont.Dispose()
  $subtitleFont.Dispose()
  $labelFont.Dispose()
  $bodyFont.Dispose()
  $background.Dispose()
  $ink.Dispose()
  $muted.Dispose()
  $green.Dispose()
  $blue.Dispose()
  $panel.Dispose()
  $line.Dispose()
  $error.Dispose()
  $warn.Dispose()
  $graphics.Dispose()
  $bitmap.Dispose()
}

function Save-Demo($path) {
  $bitmap = New-Object System.Drawing.Bitmap(1280, 800)
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

  $background = New-Brush "#ecfdf3"
  $panel = New-Brush "#101828"
  $text = New-Brush "#f9fafb"
  $green = New-Brush "#32d583"
  $warn = New-Brush "#fdb022"
  $red = New-Brush "#f97066"
  $muted = New-Brush "#98a2b3"

  $graphics.FillRectangle($background, 0, 0, 1280, 800)
  $graphics.FillRectangle($panel, 76, 72, 1128, 656)

  $font = New-Object System.Drawing.Font("Consolas", 25, [System.Drawing.FontStyle]::Regular)
  $titleFont = New-Object System.Drawing.Font("Segoe UI", 32, [System.Drawing.FontStyle]::Bold)

  Draw-Text $graphics "Godot Add-on Auditor report" $titleFont $text 124 118 760 52
  Draw-Text $graphics "> node src/cli.mjs examples/bad-project" $font $muted 124 206 980 40
  Draw-Text $graphics "Add-ons found: 1" $font $text 124 278 980 40
  Draw-Text $graphics "Errors: 2  Warnings: 3  Notes: 0" $font $text 124 324 980 40
  Draw-Text $graphics "[ERROR] PLUGIN_KEY_MISSING: plugin.cfg is missing plugin/description." $font $red 124 414 1030 40
  Draw-Text $graphics "[ERROR] PLUGIN_SCRIPT_MISSING: plugin/script file was not found." $font $red 124 462 1030 40
  Draw-Text $graphics "[WARNING] VERSION_FORMAT: use a release version such as 0.1.0." $font $warn 124 510 1030 40
  Draw-Text $graphics "[OK] Fix the issues, re-run the auditor, then package the add-on." $font $green 124 600 1030 40

  $bitmap.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)

  $font.Dispose()
  $titleFont.Dispose()
  $background.Dispose()
  $panel.Dispose()
  $text.Dispose()
  $green.Dispose()
  $warn.Dispose()
  $red.Dispose()
  $muted.Dispose()
  $graphics.Dispose()
  $bitmap.Dispose()
}

Save-Cover (Join-Path $assetDir "cover-1600x1200.png")
Save-Demo (Join-Path $assetDir "demo-report-1280x800.png")

Write-Output "Created product assets in $assetDir"
