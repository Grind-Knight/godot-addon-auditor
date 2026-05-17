#!/usr/bin/env node
import { auditProject, formatReport } from "./auditor.mjs";
import { readFileSync } from "node:fs";

const args = process.argv.slice(2);
const version = JSON.parse(readFileSync(new URL("../package.json", import.meta.url), "utf8")).version;
const versionRequested = takeFlag(args, "--version") || takeFlag(args, "-v");
const json = takeFlag(args, "--json");
const addonDir = takeOption(args, "--addon-dir");
const help = takeFlag(args, "--help") || takeFlag(args, "-h");

if (versionRequested) {
  console.log(version);
  process.exit(0);
}

if (help) {
  console.log(`Usage: godot-addon-auditor <project-root> [--addon-dir addons/my_addon] [--json] [--version]

Checks Godot 4 add-ons for common release and Asset Library packaging issues.
Exits with code 1 when blocking errors are found.`);
  process.exit(0);
}

const unexpectedFlag = args.find((arg) => arg.startsWith("-"));
if (unexpectedFlag) {
  console.error(`Unknown option: ${unexpectedFlag}`);
  console.error("Run godot-addon-auditor --help for usage.");
  process.exit(2);
}

const projectRoot = args[0] ?? ".";
const report = auditProject(projectRoot, { addonDir });

if (json) {
  console.log(JSON.stringify(report, null, 2));
} else {
  console.log(formatReport(report));
}

process.exitCode = report.summary.errors > 0 ? 1 : 0;

function takeFlag(values, flag) {
  const index = values.indexOf(flag);
  if (index === -1) {
    return false;
  }

  values.splice(index, 1);
  return true;
}

function takeOption(values, flag) {
  const index = values.indexOf(flag);
  if (index === -1) {
    return null;
  }

  const value = values[index + 1];
  if (!value || value.startsWith("-")) {
    console.error(`Missing value for ${flag}.`);
    console.error("Run godot-addon-auditor --help for usage.");
    process.exit(2);
  }

  values.splice(index, 2);
  return value;
}
