# Godot Add-on Auditor

Godot Add-on Auditor is a free Godot 4 editor add-on and command-line checker for add-on authors who want to catch common release and Asset Library packaging issues before uploading a ZIP or publishing a GitHub release.

It checks the parts that are easy to miss when finishing an editor plugin: `plugin.cfg` metadata, script paths, editor-plugin script basics, README/license files inside the add-on folder, and noisy folders that should not ship in release archives. Use the editor dock for quick manual checks, or use the CLI in CI and release scripts.

## Who It Helps

- Target user: indie Godot 4 plugin authors, jam-tool builders, and small teams preparing a free add-on for GitHub or the Godot Asset Library.
- Pain point: release mistakes such as missing `plugin/description`, broken `plugin/script`, forgotten license files, or accidental `.godot`/`.import` folders can slow down review and confuse users.
- Free delivery path: GitHub source, downloadable release ZIP, and Godot Asset Library listing materials.
- Optional support: if this tool helps, you can support future free tools at https://ko-fi.com/grindknight.

## Install The Godot Add-on

Copy `addons/addon_auditor` into a Godot 4 project, then enable **Godot Add-on Auditor** from **Project > Project Settings > Plugins**.

The add-on adds an **Add-on Auditor** dock that scans the current project for plugin metadata, script path, README/license, and package-noise issues.

## Install And Run The CLI

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
- It does not validate every possible `plugin.cfg` field or license type.
- It assumes a normal `addons/<addon_name>/plugin.cfg` layout unless `--addon-dir` is provided.

## Package

```powershell
npm run assets
npm run package
```

Packaging creates:

- `dist/godot-addon-auditor-0.2.1.zip`
- `dist/godot-addon-auditor-0.2.1.zip.sha256`
- `dist/asset-library-listing/`

To rebuild only the Asset Library submission materials:

```powershell
npm run package:asset-library
```

## CI

GitHub Actions runs `npm test` on Windows for pushes to `main` and pull requests so release checks stay aligned with the packaged CLI workflow.

Godot Add-on Auditor is fully usable for free.
