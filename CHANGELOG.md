# Changelog

## 0.2.0 - 2026-05-21

- Added a Godot 4 editor add-on wrapper with an in-editor scan dock.
- Added Asset Library listing kit generation with public-safe listing fields, description copy, images, and Ko-fi post copy.
- Added a square plugin icon for Godot and Asset Library submissions.

## 0.1.2 - 2026-05-20

- Added a Windows GitHub Actions workflow that runs `npm test` on pushes to `main` and pull requests.

## 0.1.1 - 2026-05-17

- Added `--github-annotations` output for GitHub Actions workflows.
- Added CLI validation so `--json` and `--github-annotations` cannot be requested together.
- Added tests for annotation formatting and the new CLI output mode.

## 0.1.0 - 2026-05-17

- Added the first Godot Add-on Auditor CLI.
- Added checks for `plugin.cfg` metadata, plugin script paths, missing README/license files inside add-on folders, editor-plugin script shape, and noisy package directories.
- Added explicit CLI handling for `--version`, unknown options, and missing `--addon-dir` values.
- Added SHA-256 checksum generation for the release ZIP and listing kit.
- Added good and bad sample projects for deterministic tests.
- Added package and listing-kit scripts for free GitHub release preparation.
