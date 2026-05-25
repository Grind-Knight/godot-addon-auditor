import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdtempSync, readFileSync, rmSync, writeFileSync, mkdirSync } from "node:fs";
import os from "node:os";
import path from "node:path";
import { auditProject, formatGitHubAnnotations, parsePluginConfig } from "../src/auditor.mjs";

const packageJson = JSON.parse(readFileSync(new URL("../package.json", import.meta.url), "utf8"));

const parsed = parsePluginConfig(`[plugin]
name="Quick Spawn"
description="Adds a spawn helper"
author="Grind Knight"
version="0.1.0"
script="plugin.gd"
`);

assert.equal(parsed.plugin.name, "Quick Spawn");
assert.equal(parsed.plugin.script, "plugin.gd");

const goodReport = auditProject(path.resolve("examples/good-project"));
assert.equal(goodReport.summary.errors, 0);
assert.equal(goodReport.summary.warnings, 0);
assert.deepEqual(goodReport.addons, ["addons/quick_spawn"]);

const selfAddonReport = auditProject(path.resolve("."), { addonDir: "addons/addon_auditor" });
assert.equal(selfAddonReport.summary.errors, 0);
assert.equal(selfAddonReport.items.filter((item) => item.path.startsWith("addons/addon_auditor")).length, 0);
assert.deepEqual(selfAddonReport.addons, ["addons/addon_auditor"]);

const badReport = auditProject(path.resolve("examples/bad-project"));
assert.ok(badReport.summary.errors >= 2);
assert.ok(badReport.items.some((item) => item.code === "PLUGIN_KEY_MISSING"));
assert.ok(badReport.items.some((item) => item.code === "PLUGIN_SCRIPT_MISSING"));

const annotations = formatGitHubAnnotations(badReport);
assert.match(annotations, /::error file=addons\/broken_tool\/plugin\.cfg,title=PLUGIN_KEY_MISSING::/);
assert.match(annotations, /::error file=addons\/broken_tool\/missing_plugin\.gd,title=PLUGIN_SCRIPT_MISSING::/);

const tempRoot = mkdtempSync(path.join(os.tmpdir(), "godot-addon-auditor-"));
try {
  mkdirSync(path.join(tempRoot, "addons", "escape_test"), { recursive: true });
  writeFileSync(path.join(tempRoot, "addons", "escape_test", "plugin.cfg"), `[plugin]
name="Escape Test"
description="Bad script path"
author="Tester"
version="0.1.0"
script="../../../outside.gd"
`);
  const report = auditProject(tempRoot);
  assert.ok(report.items.some((item) => item.code === "PLUGIN_SCRIPT_PATH"));
} finally {
  rmSync(tempRoot, { recursive: true, force: true });
}

const missingIconRoot = mkdtempSync(path.join(os.tmpdir(), "godot-addon-auditor-"));
try {
  mkdirSync(path.join(missingIconRoot, "addons", "missing_icon"), { recursive: true });
  writeFileSync(path.join(missingIconRoot, "addons", "missing_icon", "plugin.cfg"), `[plugin]
name="Missing Icon"
description="Has an icon path that is not packaged"
author="Tester"
version="0.1.0"
script="plugin.gd"
icon="icon.png"
`);
  writeFileSync(path.join(missingIconRoot, "addons", "missing_icon", "plugin.gd"), `@tool
extends EditorPlugin
`);
  const report = auditProject(missingIconRoot);
  assert.equal(report.summary.errors, 0);
  assert.ok(report.items.some((item) => item.code === "PLUGIN_ICON_MISSING"));
} finally {
  rmSync(missingIconRoot, { recursive: true, force: true });
}

const versionResult = spawnSync(process.execPath, ["src/cli.mjs", "--version"], { encoding: "utf8" });
assert.equal(versionResult.status, 0);
assert.equal(versionResult.stdout.trim(), packageJson.version);

const missingAddonDirResult = spawnSync(process.execPath, ["src/cli.mjs", "--addon-dir"], { encoding: "utf8" });
assert.equal(missingAddonDirResult.status, 2);
assert.match(missingAddonDirResult.stderr, /Missing value for --addon-dir/);

const unknownFlagResult = spawnSync(process.execPath, ["src/cli.mjs", "--bogus"], { encoding: "utf8" });
assert.equal(unknownFlagResult.status, 2);
assert.match(unknownFlagResult.stderr, /Unknown option: --bogus/);

const annotationResult = spawnSync(process.execPath, ["src/cli.mjs", "examples/bad-project", "--github-annotations"], { encoding: "utf8" });
assert.equal(annotationResult.status, 1);
assert.match(annotationResult.stdout, /::error file=addons\/broken_tool\/plugin\.cfg,title=PLUGIN_KEY_MISSING::/);

const conflictingOutputResult = spawnSync(process.execPath, ["src/cli.mjs", "examples/bad-project", "--json", "--github-annotations"], { encoding: "utf8" });
assert.equal(conflictingOutputResult.status, 2);
assert.match(conflictingOutputResult.stderr, /Choose only one machine-readable output mode/);

console.log("auditor tests passed");
