$ErrorActionPreference = "Stop"

$root = Resolve-Path (Join-Path $PSScriptRoot "..")
Push-Location $root
try {
  node test/auditor.test.mjs
} finally {
  Pop-Location
}
