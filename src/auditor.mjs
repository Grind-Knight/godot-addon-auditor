import { existsSync, readdirSync, readFileSync, statSync } from "node:fs";
import path from "node:path";

const REQUIRED_PLUGIN_KEYS = ["name", "description", "author", "version", "script"];
const BLOCKED_PACKAGE_DIRS = new Set([".git", ".godot", ".import", ".vs", "node_modules"]);

export function parsePluginConfig(text) {
  const sections = {};
  let currentSection = null;

  for (const rawLine of text.split(/\r?\n/)) {
    const line = rawLine.trim();
    if (!line || line.startsWith(";") || line.startsWith("#")) {
      continue;
    }

    const sectionMatch = line.match(/^\[([^\]]+)\]$/);
    if (sectionMatch) {
      currentSection = sectionMatch[1].trim();
      sections[currentSection] = sections[currentSection] ?? {};
      continue;
    }

    const keyMatch = line.match(/^([^=]+)=(.*)$/);
    if (!keyMatch || !currentSection) {
      continue;
    }

    const key = keyMatch[1].trim();
    const value = unwrapConfigValue(keyMatch[2].trim());
    sections[currentSection][key] = value;
  }

  return sections;
}

export function auditProject(projectRoot, options = {}) {
  const root = path.resolve(projectRoot);
  const items = [];

  if (!existsSync(root) || !statSync(root).isDirectory()) {
    return buildReport(root, [], [
      error("PROJECT_ROOT_MISSING", `Project root does not exist or is not a directory: ${root}`, root)
    ]);
  }

  const addonRoots = findAddonRoots(root, options.addonDir);
  if (addonRoots.length === 0) {
    items.push(error("NO_PLUGIN_CFG", "No Godot add-on plugin.cfg files were found under an addons folder.", root));
  }

  for (const addonRoot of addonRoots) {
    items.push(...auditAddon(root, addonRoot));
  }

  items.push(...auditPackageNoise(root));
  return buildReport(root, addonRoots, items);
}

export function formatReport(report) {
  const lines = [];
  lines.push(`Godot Add-on Auditor`);
  lines.push(`Project: ${report.projectRoot}`);
  lines.push(`Add-ons found: ${report.addons.length}`);
  lines.push(`Errors: ${report.summary.errors}  Warnings: ${report.summary.warnings}  Notes: ${report.summary.info}`);
  lines.push("");

  if (report.items.length === 0) {
    lines.push("No issues found.");
    return lines.join("\n");
  }

  for (const item of report.items) {
    const location = item.path ? ` (${item.path})` : "";
    lines.push(`[${item.level.toUpperCase()}] ${item.code}: ${item.message}${location}`);
  }

  return lines.join("\n");
}

export function formatGitHubAnnotations(report) {
  return report.items
    .map((item) => {
      const command = item.level === "error" ? "error" : item.level === "warning" ? "warning" : "notice";
      const file = item.path ? ` file=${escapeWorkflowProperty(item.path)},` : " ";
      return `::${command}${file}title=${escapeWorkflowProperty(item.code)}::${escapeWorkflowMessage(item.message)}`;
    })
    .join("\n");
}

function auditAddon(projectRoot, addonRoot) {
  const items = [];
  const configPath = path.join(addonRoot, "plugin.cfg");
  const relativeAddon = normalizePath(path.relative(projectRoot, addonRoot));

  if (!existsSync(configPath)) {
    items.push(error("PLUGIN_CFG_MISSING", "Add-on folder is missing plugin.cfg.", relativeAddon));
    return items;
  }

  const config = parsePluginConfig(readFileSync(configPath, "utf8"));
  const plugin = config.plugin ?? {};

  for (const key of REQUIRED_PLUGIN_KEYS) {
    if (!plugin[key] || String(plugin[key]).trim() === "") {
      items.push(error("PLUGIN_KEY_MISSING", `plugin.cfg is missing plugin/${key}.`, normalizePath(path.relative(projectRoot, configPath))));
    }
  }

  if (plugin.version && !/^\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?$/.test(plugin.version)) {
    items.push(warning("VERSION_FORMAT", "plugin/version should use a clear release version such as 0.1.0.", normalizePath(path.relative(projectRoot, configPath))));
  }

  const scriptPath = resolvePluginScript(projectRoot, addonRoot, plugin.script);
  if (plugin.script && !scriptPath) {
    items.push(error("PLUGIN_SCRIPT_PATH", `plugin/script points outside this project or uses an unsupported path: ${plugin.script}`, normalizePath(path.relative(projectRoot, configPath))));
  } else if (scriptPath && !existsSync(scriptPath)) {
    items.push(error("PLUGIN_SCRIPT_MISSING", `plugin/script file was not found: ${plugin.script}`, normalizePath(path.relative(projectRoot, scriptPath))));
  } else if (scriptPath) {
    const scriptText = readFileSync(scriptPath, "utf8");
    if (!scriptText.match(/^\s*@tool\b/m)) {
      items.push(warning("PLUGIN_SCRIPT_TOOL", "Editor plugin scripts should usually include @tool so they run in the editor.", normalizePath(path.relative(projectRoot, scriptPath))));
    }
    if (!scriptText.match(/^\s*extends\s+EditorPlugin\b/m)) {
      items.push(warning("PLUGIN_SCRIPT_EXTENDS", "Editor plugin scripts should extend EditorPlugin.", normalizePath(path.relative(projectRoot, scriptPath))));
    }
  }

  if (!existsSync(path.join(addonRoot, "README.md"))) {
    items.push(warning("ADDON_README_MISSING", "Add a README.md inside the add-on folder for Asset Library users.", relativeAddon));
  }

  if (!existsSync(path.join(addonRoot, "LICENSE.md")) && !existsSync(path.join(addonRoot, "LICENSE"))) {
    items.push(warning("ADDON_LICENSE_MISSING", "Add a license file inside the add-on folder for Asset Library users.", relativeAddon));
  }

  if (!existsSync(path.join(projectRoot, "README.md"))) {
    items.push(info("PROJECT_README_MISSING", "A root README.md helps GitHub users understand install and support paths.", normalizePath(path.relative(projectRoot, projectRoot))));
  }

  return items;
}

function auditPackageNoise(projectRoot) {
  const items = [];
  const found = [];
  walk(projectRoot, (entryPath, dirent) => {
    if (!dirent.isDirectory()) {
      return true;
    }

    if (BLOCKED_PACKAGE_DIRS.has(dirent.name)) {
      found.push(normalizePath(path.relative(projectRoot, entryPath)));
      return false;
    }

    return true;
  });

  for (const blocked of found) {
    items.push(warning("PACKAGE_NOISE", `Exclude ${blocked} from release ZIPs and Asset Library uploads.`, blocked));
  }

  return items;
}

function findAddonRoots(projectRoot, addonDir) {
  if (addonDir) {
    const explicit = path.resolve(projectRoot, addonDir);
    return existsSync(path.join(explicit, "plugin.cfg")) ? [explicit] : [];
  }

  const addonsRoot = path.join(projectRoot, "addons");
  if (!existsSync(addonsRoot) || !statSync(addonsRoot).isDirectory()) {
    return [];
  }

  return readdirSync(addonsRoot, { withFileTypes: true })
    .filter((entry) => entry.isDirectory())
    .map((entry) => path.join(addonsRoot, entry.name))
    .filter((addonRoot) => existsSync(path.join(addonRoot, "plugin.cfg")));
}

function resolvePluginScript(projectRoot, addonRoot, scriptValue) {
  if (!scriptValue) {
    return null;
  }

  let resolved;
  if (scriptValue.startsWith("res://")) {
    resolved = path.resolve(projectRoot, scriptValue.slice("res://".length));
  } else if (path.isAbsolute(scriptValue)) {
    return null;
  } else {
    resolved = path.resolve(addonRoot, scriptValue);
  }

  const relative = path.relative(projectRoot, resolved);
  if (relative.startsWith("..") || path.isAbsolute(relative)) {
    return null;
  }

  return resolved;
}

function buildReport(projectRoot, addonRoots, items) {
  return {
    projectRoot,
    addons: addonRoots.map((addonRoot) => normalizePath(path.relative(projectRoot, addonRoot))),
    summary: {
      errors: items.filter((item) => item.level === "error").length,
      warnings: items.filter((item) => item.level === "warning").length,
      info: items.filter((item) => item.level === "info").length
    },
    items
  };
}

function unwrapConfigValue(value) {
  const quoted = value.match(/^"(.*)"$/);
  if (quoted) {
    return quoted[1].replace(/\\"/g, "\"");
  }
  return value;
}

function walk(dir, visit) {
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const entryPath = path.join(dir, entry.name);
    const shouldDescend = visit(entryPath, entry);
    if (entry.isDirectory() && shouldDescend !== false) {
      walk(entryPath, visit);
    }
  }
}

function error(code, message, itemPath) {
  return issue("error", code, message, itemPath);
}

function warning(code, message, itemPath) {
  return issue("warning", code, message, itemPath);
}

function info(code, message, itemPath) {
  return issue("info", code, message, itemPath);
}

function issue(level, code, message, itemPath) {
  return {
    level,
    code,
    message,
    path: itemPath ? normalizePath(itemPath) : ""
  };
}

function normalizePath(input) {
  return input.replace(/\\/g, "/");
}

function escapeWorkflowProperty(value) {
  return String(value)
    .replace(/%/g, "%25")
    .replace(/\r/g, "%0D")
    .replace(/\n/g, "%0A")
    .replace(/:/g, "%3A")
    .replace(/,/g, "%2C");
}

function escapeWorkflowMessage(value) {
  return String(value)
    .replace(/%/g, "%25")
    .replace(/\r/g, "%0D")
    .replace(/\n/g, "%0A");
}
