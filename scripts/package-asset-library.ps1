$ErrorActionPreference = "Stop"

$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$packageJson = Get-Content -Raw (Join-Path $root "package.json") | ConvertFrom-Json
$version = $packageJson.version
$distDir = Join-Path $root "dist"
$listingDir = Join-Path $distDir "asset-library-listing"
$assetDir = Join-Path $distDir "store-assets"
$releaseAssetDir = Join-Path $distDir "release-assets"
$addonDir = Join-Path $root "addons\addon_auditor"
$iconPath = Join-Path $addonDir "icon.png"

if (-not (Test-Path -LiteralPath $iconPath)) {
  throw "Missing Asset Library icon: $iconPath"
}

& (Join-Path $PSScriptRoot "create-assets.ps1")

if (Test-Path -LiteralPath $listingDir) {
  Remove-Item -LiteralPath $listingDir -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $listingDir | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $listingDir "images") | Out-Null

Copy-Item -LiteralPath $iconPath -Destination (Join-Path $listingDir "images\icon.png")
Copy-Item -LiteralPath (Join-Path $assetDir "cover-1600x1200.png") -Destination (Join-Path $listingDir "images\cover-1600x1200.png")
Copy-Item -LiteralPath (Join-Path $assetDir "demo-report-1280x800.png") -Destination (Join-Path $listingDir "images\demo-report-1280x800.png")

$commit = (& git -C $root rev-parse HEAD).Trim()
$dirty = (@(& git -C $root status --short) -join "`n").Trim()
$aheadCount = 0
try {
  $aheadOutput = (@(& git -C $root rev-list --count "@{u}..HEAD" 2>$null) -join "").Trim()
  if ($aheadOutput) {
    $aheadCount = [int]$aheadOutput
  }
} catch {
  $aheadCount = 0
}
$downloadCommitOverride = $env:GK_ASSET_LIBRARY_DOWNLOAD_COMMIT
if ($downloadCommitOverride -and $downloadCommitOverride -notmatch "^[0-9a-fA-F]{40}$") {
  throw "GK_ASSET_LIBRARY_DOWNLOAD_COMMIT must be a 40-character Git commit SHA."
}
$downloadCommit = if ($downloadCommitOverride) {
  $downloadCommitOverride.ToLowerInvariant()
} elseif ($dirty -or $aheadCount -gt 0) {
  "PUSHED_RELEASE_COMMIT_REQUIRED"
} else {
  $commit
}
$iconUrl = "https://raw.githubusercontent.com/Grind-Knight/godot-addon-auditor/main/addons/addon_auditor/icon.png"
$coverUrl = "https://raw.githubusercontent.com/Grind-Knight/godot-addon-auditor/main/media/cover-1600x1200.png"
$demoUrl = "https://raw.githubusercontent.com/Grind-Knight/godot-addon-auditor/main/media/demo-report-1280x800.png"
$repoUrl = "https://github.com/Grind-Knight/godot-addon-auditor"
$issuesUrl = "$repoUrl/issues"
$releaseUrl = "$repoUrl/releases/tag/v$version"

$description = @"
Godot Add-on Auditor is a free Godot 4 editor add-on and CLI for checking editor plugins before a release or Asset Library upload.

It scans plugin.cfg metadata, plugin script and icon paths, editor plugin script basics, missing add-on README/license files, and noisy folders such as .godot, .import, .git, node_modules, and .vs. Use the editor dock for quick local checks, or run the CLI in CI and release scripts for repeatable validation.

Version $version keeps the Godot editor add-on install path and command-line workflow aligned for free GitHub and Asset Library distribution.

Free source and downloads: $repoUrl
Optional support: https://ko-fi.com/grindknight
"@

Set-Content -LiteralPath (Join-Path $listingDir "description.txt") -Value $description.Trim() -Encoding UTF8

$fields = [ordered]@{
  asset_name = "Godot Add-on Auditor"
  category = "Tools"
  godot_version = "4.x"
  version = $version
  repository_host = "GitHub"
  repository_url = $repoUrl
  issues_url = $issuesUrl
  download_commit = $downloadCommit
  icon_url = $iconUrl
  license = "MIT"
  description_file = "description.txt"
  preview_images = @(
    $coverUrl,
    $demoUrl
  )
  release_url = $releaseUrl
}

$fields | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $listingDir "fields.json") -Encoding UTF8

$readme = @"
# Godot Asset Library Listing Kit

Use these public-safe fields after the release commit is pushed.

- Asset name: Godot Add-on Auditor
- Category: Tools
- Godot version: 4.x
- Version: $version
- Repository URL: $repoUrl
- Issues URL: $issuesUrl
- Download commit: $downloadCommit
- Icon URL: $iconUrl
- License: MIT
- Preview image 1: $coverUrl
- Preview image 2: $demoUrl

If `download_commit` is `PUSHED_RELEASE_COMMIT_REQUIRED`, commit and push the current changes, then regenerate this kit before submission.

The repository uses the MIT license, so the Asset Library license field should also be set to MIT.
"@

Set-Content -LiteralPath (Join-Path $listingDir "README.md") -Value $readme.Trim() -Encoding UTF8

$post = @"
I released Godot Add-on Auditor $version, a free Godot 4 editor add-on and CLI that helps plugin authors catch packaging issues before publishing. This update standardizes the project and bundled add-on license to MIT, and it now warns when a declared plugin icon points outside the project or is missing from the package.

Free source and download: $releaseUrl
"@

Set-Content -LiteralPath (Join-Path $listingDir "ko-fi-post.txt") -Value $post.Trim() -Encoding UTF8

if (-not $downloadCommitOverride -and ($dirty -or $aheadCount -gt 0)) {
  Write-Warning "Working tree has unpushed or uncommitted changes. Push a release commit and regenerate this kit before Asset Library submission."
}

Write-Output "Created Asset Library listing kit in $listingDir"
