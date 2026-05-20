# Release Checklist

## Local Verification

- Run `npm test`.
- Run `npm run assets`.
- Run `npm run package`.
- Confirm `dist/godot-addon-auditor-0.1.1.zip` exists.
- Confirm `dist/godot-addon-auditor-0.1.1.zip.sha256` exists and matches the release ZIP.
- Confirm `dist/listing-kit/assets/cover-1600x1200.png` exists.
- Confirm `node src/cli.mjs examples/good-project` exits successfully.
- Confirm `node src/cli.mjs examples/bad-project` exits with errors.
- Confirm `node src/cli.mjs examples/bad-project --github-annotations` prints GitHub Actions annotations and exits with errors.

## Free Product Requirements

- Target user: Godot 4 add-on authors.
- Pain point: release and Asset Library packaging mistakes.
- Free delivery path: GitHub source and release ZIP.
- Donation strategy: optional Ko-fi link, secondary to the free download.
- Likely platforms: GitHub Releases first; Godot Asset Library and itch.io later if useful.
- Support expectation: best-effort GitHub Issues.

## Publishing Path

1. Create a public GitHub repository under Grind Knight.
2. Push the source and tag `v0.1.1`.
3. Attach `dist/godot-addon-auditor-0.1.1.zip` to the GitHub release.
4. Attach `dist/godot-addon-auditor-0.1.1.zip.sha256` so users can verify the download.
5. Use `LISTING_DRAFT.md` for release/listing copy.
6. Use `dist/listing-kit/assets/cover-1600x1200.png` as the first product image.
7. Draft a first-person Ko-fi post with the GitHub release URL.

## Ko-fi Post Draft

I'm releasing Godot Add-on Auditor, a free command-line checker for Godot 4 add-on authors. It catches common release issues like missing `plugin.cfg` fields, broken plugin script paths, missing add-on README/license files, and noisy folders before you package or submit an add-on.

The tool is free, runs outside the Godot editor, and now includes GitHub Actions annotation output for CI workflows.

Download/source: [add GitHub release URL]
