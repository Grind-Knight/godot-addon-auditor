$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$packageJson = Get-Content -Raw (Join-Path $root "package.json") | ConvertFrom-Json
$version = $packageJson.version
$distDir = Join-Path $root "dist"
$assetDir = Join-Path $distDir "store-assets"
$assetOutDir = Join-Path $distDir "release-assets"
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
if (Test-Path $assetOutDir) {
  Remove-Item -LiteralPath $assetOutDir -Recurse -Force
}

New-Item -ItemType Directory -Force -Path $distDir | Out-Null
New-Item -ItemType Directory -Force -Path $assetOutDir | Out-Null

$skipDirs = @("dist", "node_modules", ".git", ".godot", ".import", ".npm-cache")
$skipFilePatterns = @("*.internal.md", "PRIVATE_*.md")

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

    $skipFile = $false
    foreach ($pattern in $skipFilePatterns) {
      if ($item.Name -like $pattern) {
        $skipFile = $true
        break
      }
    }
    if ($skipFile) {
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

Copy-Item -LiteralPath (Join-Path $assetDir "cover-1600x1200.png") -Destination (Join-Path $assetOutDir "cover-1600x1200.png")
Copy-Item -LiteralPath (Join-Path $assetDir "demo-report-1280x800.png") -Destination (Join-Path $assetOutDir "demo-report-1280x800.png")

Write-Output "Created $packagePath"
Write-Output "Created $checksumPath"
Write-Output "Created release assets in $assetOutDir"
