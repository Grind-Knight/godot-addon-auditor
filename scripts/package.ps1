$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$packageJson = Get-Content -Raw (Join-Path $root "package.json") | ConvertFrom-Json
$version = $packageJson.version
$distDir = Join-Path $root "dist"
$assetDir = Join-Path $distDir "store-assets"
$kitDir = Join-Path $distDir "listing-kit"
$packagePath = Join-Path $distDir "godot-addon-auditor-$version.zip"
$checksumPath = "$packagePath.sha256"

& (Join-Path $PSScriptRoot "test.ps1")
& (Join-Path $PSScriptRoot "create-assets.ps1")

if (Test-Path $packagePath) {
  Remove-Item -LiteralPath $packagePath -Force
}
if (Test-Path $checksumPath) {
  Remove-Item -LiteralPath $checksumPath -Force
}
if (Test-Path $kitDir) {
  Remove-Item -LiteralPath $kitDir -Recurse -Force
}

New-Item -ItemType Directory -Force -Path $distDir | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $kitDir "assets") | Out-Null

$skipDirs = @("dist", "node_modules", ".git", ".godot", ".import", ".npm-cache")

function Add-ZipFile($zip, $sourcePath, $entryName) {
  $entry = $zip.CreateEntry($entryName.Replace("\", "/"), [System.IO.Compression.CompressionLevel]::Optimal)
  $entryStream = $entry.Open()
  $fileStream = [System.IO.File]::OpenRead($sourcePath)
  try {
    $fileStream.CopyTo($entryStream)
  } finally {
    $fileStream.Dispose()
    $entryStream.Dispose()
  }
}

function Get-CompatibleRelativePath($baseDir, $targetPath) {
  $baseFull = [System.IO.Path]::GetFullPath($baseDir)
  if (-not $baseFull.EndsWith([System.IO.Path]::DirectorySeparatorChar)) {
    $baseFull += [System.IO.Path]::DirectorySeparatorChar
  }

  $baseUri = New-Object System.Uri($baseFull)
  $targetUri = New-Object System.Uri([System.IO.Path]::GetFullPath($targetPath))
  return [System.Uri]::UnescapeDataString($baseUri.MakeRelativeUri($targetUri).ToString()).Replace("/", "\")
}

function Add-ZipDirectory($zip, $baseDir, $currentDir) {
  foreach ($item in Get-ChildItem -LiteralPath $currentDir -Force) {
    if ($item.PSIsContainer) {
      if ($skipDirs -contains $item.Name) {
        continue
      }
      Add-ZipDirectory $zip $baseDir $item.FullName
      continue
    }

    $relative = Get-CompatibleRelativePath $baseDir $item.FullName
    Add-ZipFile $zip $item.FullName $relative
  }
}

$zip = [System.IO.Compression.ZipFile]::Open($packagePath, [System.IO.Compression.ZipArchiveMode]::Create)
try {
  Add-ZipDirectory $zip $root $root
} finally {
  $zip.Dispose()
}

$hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $packagePath).Hash.ToLowerInvariant()
Set-Content -LiteralPath $checksumPath -Value "$hash  godot-addon-auditor-$version.zip" -Encoding UTF8

Copy-Item -LiteralPath (Join-Path $assetDir "cover-1600x1200.png") -Destination (Join-Path $kitDir "assets\cover-1600x1200.png")
Copy-Item -LiteralPath (Join-Path $assetDir "demo-report-1280x800.png") -Destination (Join-Path $kitDir "assets\demo-report-1280x800.png")
Copy-Item -LiteralPath (Join-Path $root "README.md") -Destination (Join-Path $kitDir "README.md")
Copy-Item -LiteralPath (Join-Path $root "LISTING_DRAFT.md") -Destination (Join-Path $kitDir "LISTING_DRAFT.md")
Copy-Item -LiteralPath (Join-Path $root "RELEASE_CHECKLIST.md") -Destination (Join-Path $kitDir "RELEASE_CHECKLIST.md")
Copy-Item -LiteralPath (Join-Path $root "CHANGELOG.md") -Destination (Join-Path $kitDir "CHANGELOG.md")
Copy-Item -LiteralPath $packagePath -Destination (Join-Path $kitDir "godot-addon-auditor-$version.zip")
Copy-Item -LiteralPath $checksumPath -Destination (Join-Path $kitDir "godot-addon-auditor-$version.zip.sha256")

$checklist = @"
# Godot Add-on Auditor Listing Kit

Version: $version
Publisher: Grind Knight

## Included

- godot-addon-auditor-$version.zip - Free GitHub release package.
- godot-addon-auditor-$version.zip.sha256 - SHA-256 checksum for release verification.
- README.md - install, usage, support, and limitation notes.
- LISTING_DRAFT.md - GitHub/Godot/itch listing copy.
- RELEASE_CHECKLIST.md - local verification, publishing path, and Ko-fi post draft.
- CHANGELOG.md - release notes.
- assets/cover-1600x1200.png - primary product cover.
- assets/demo-report-1280x800.png - demo report visual.

## Verification

- npm test passed during packaging.
- Product images were regenerated during packaging.
- SHA-256 checksum: $hash
- The release package excludes dist, node_modules, .git, .godot, .import, and .npm-cache.
- The product is free and uses Ko-fi only as optional support: https://ko-fi.com/grindknight.

## Next Publishing Step

Create a public GitHub repository/release, attach the ZIP, then use the GitHub release URL in any Godot Asset Library, itch.io, or Ko-fi post copy.
"@

Set-Content -LiteralPath (Join-Path $kitDir "SUBMISSION_CHECKLIST.md") -Value $checklist -Encoding UTF8

Write-Output "Created $packagePath"
Write-Output "Created $checksumPath"
Write-Output "Created listing kit in $kitDir"
