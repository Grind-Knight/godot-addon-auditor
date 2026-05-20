# Godot Add-on Auditor

Godot Add-on Auditor is a free command-line checker for Godot 4 add-on authors who want to catch common release and Asset Library packaging issues before uploading a ZIP or publishing a GitHub release.

It checks the parts that are easy to miss when finishing an editor plugin: `plugin.cfg` metadata, script paths, editor-plugin script basics, README/license files inside the add-on folder, and noisy folders that should not ship in release archives.

## Who It Helps

- Target user: indie Godot 4 plugin authors, jam-tool builders, and small teams preparing a free add-on for GitHub or the Godot Asset Library.
- Pain point: release mistakes such as missing `plugin/description`, broken `plugin/script`, forgotten license files, or accidental `.godot`/`.import` folders can slow down review and confuse users.
- Free delivery path: GitHub source plus a downloadable release ZIP.
- Optional support: if this saves you time, you can support future free tools at https://ko-fi.com/grindknight.

## Install And Run

From this folder:

```powershell
npm test
node src/cli.mjs path\to\your\godot-project
```

JSON output is available for scripts:

```powershell
node src/cli.mjs path\to\your\godot-project --json
```

GitHub Actions annotation output is available for CI logs:

```powershell
node src/cli.mjs path\to\your\godot-project --github-annotations
```

To audit one explicit add-on folder:

```powershell
node src/cli.mjs path\to\your\godot-project --addon-dir addons\my_addon
```

The CLI exits with code `1` when blocking errors are found, so it can be added to a release script or CI check.

To print the installed tool version:

```powershell
node src/cli.mjs --version
```

## What It Checks

- Finds Godot add-ons under `addons/*/plugin.cfg`.
- Requires `plugin/name`, `plugin/description`, `plugin/author`, `plugin/version`, and `plugin/script`.
- Verifies that `plugin/script` resolves inside the project and exists.
- Warns when the plugin script does not include `@tool` or `extends EditorPlugin`.
- Warns when the add-on folder does not include its own `README.md` and license file.
- Warns when release-noise folders such as `.git`, `.godot`, `.import`, `.vs`, or `node_modules` are present under the audited project.
- Can print GitHub Actions annotations for CI workflows.

## Supported Godot Version

The checks are aimed at Godot 4.x editor plugins. The tool does not run the Godot editor or parse GDScript deeply; it only performs deterministic file and metadata checks that work outside the editor.

## Known Limitations

- It does not replace testing the plugin inside Godot.
- It does not submit anything to the Godot Asset Library.
- It does not validate every possible `plugin.cfg` field or license type.
- It assumes a normal `addons/<addon_name>/plugin.cfg` layout unless `--addon-dir` is provided.

## Package

```powershell
npm run assets
npm run package
```

Packaging creates:

- `dist/godot-addon-auditor-0.1.1.zip`
- `dist/godot-addon-auditor-0.1.1.zip.sha256`
- `dist/listing-kit/` with listing copy, release checklist, and product images

## Release And Listing Path

- Primary source and release host: GitHub.
- Likely listing platforms: GitHub Releases first, then the Godot Asset Library once a public repository/release URL exists.
- Account prerequisites: GitHub credentials for the source/release repo; Godot Asset Library account if submitting the add-on as a helper utility.
- Review constraints: Godot Asset Library submissions should include a clean add-on folder, README, license, versioned source URL, and a useful image.
- Support expectation: best-effort issue triage through GitHub Issues. No paid support tier is offered.

Godot Add-on Auditor is fully usable for free. The Ko-fi link is optional and only supports building more free game-development tools.
