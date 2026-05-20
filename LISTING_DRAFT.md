# Godot Add-on Auditor Listing Draft

## Title

Godot Add-on Auditor

## Short Description

Free CLI checks Godot 4 add-ons for common release and Asset Library packaging issues before upload.

## Audience

Godot 4 plugin authors, indie game developers, jam-tool builders, students, and small teams preparing free editor add-ons.

## Pain Point

Godot add-on releases are easy to break with a missing `plugin.cfg` field, broken script path, forgotten license, or accidental editor-cache folders in the ZIP. These mistakes are simple to catch before release but tedious to check by hand.

## Full Description

Godot Add-on Auditor is a free command-line checker for Godot 4 add-on authors. It scans a project for `addons/*/plugin.cfg`, validates required plugin metadata, checks that the configured plugin script exists, warns about missing add-on README/license files, and points out folders that should not ship in release packages.

Use it before creating a GitHub release or submitting to the Godot Asset Library. It runs outside the Godot editor, exits with a non-zero status on blocking errors, and can be added to a release script or CI workflow. For GitHub Actions, `--github-annotations` prints workflow annotations so errors and warnings show up directly in CI logs.

## Free Delivery

- GitHub source repository.
- GitHub Release ZIP: `godot-addon-auditor-0.1.1.zip`.
- SHA-256 checksum: `godot-addon-auditor-0.1.1.zip.sha256`.
- No paid upgrade, account, subscription, or gated download.

## Optional Support Copy

Godot Add-on Auditor is free. If it saves you release cleanup time, you can optionally support future free tools at https://ko-fi.com/grindknight.

## Tags And Keywords

godot, godot4, addon, plugin, asset-library, editor-plugin, release-checklist, game-dev, indie-dev, cli

## Screenshots And Media

- `dist/listing-kit/assets/cover-1600x1200.png`
- `dist/listing-kit/assets/demo-report-1280x800.png`

## Listing Platforms

- GitHub Releases: primary download and source-of-truth path.
- Godot Asset Library: possible free utility listing after a public GitHub repo/release exists.
- itch.io: possible free downloadable tool page after GitHub release.

## Account And Review Notes

- GitHub publishing is approved when credentials and a repo path are available.
- Godot Asset Library account is ready, but submission should wait until GitHub source/release is live.
- If an upload surface blocks native file selection, record the local image/package paths for manual attachment.

## Support Expectations

Best-effort GitHub Issues support for broken checks, false positives, and Godot 4 release-readiness updates.
