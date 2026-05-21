@tool
extends EditorPlugin

const REQUIRED_PLUGIN_KEYS := ["name", "description", "author", "version", "script"]
const BLOCKED_PACKAGE_DIRS := [".git", ".godot", ".import", ".vs", "node_modules"]

var _dock: VBoxContainer
var _output: TextEdit

func _enter_tree() -> void:
	_dock = VBoxContainer.new()
	_dock.name = "Add-on Auditor"

	var title := Label.new()
	title.text = "Godot Add-on Auditor"
	_dock.add_child(title)

	var scan_button := Button.new()
	scan_button.text = "Scan add-ons"
	scan_button.pressed.connect(_scan_project)
	_dock.add_child(scan_button)

	_output = TextEdit.new()
	_output.editable = false
	_output.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_output.custom_minimum_size = Vector2(360, 360)
	_dock.add_child(_output)

	add_control_to_dock(DOCK_SLOT_RIGHT_UL, _dock)
	_scan_project()

func _exit_tree() -> void:
	if _dock:
		remove_control_from_docks(_dock)
		_dock.free()
		_dock = null

func _scan_project() -> void:
	var issues: Array[String] = []
	var addons := _find_addons()

	if addons.is_empty():
		issues.append("[ERROR] No plugin.cfg files were found under res://addons.")

	for addon_path in addons:
		issues.append_array(_audit_addon(addon_path))

	issues.append_array(_audit_package_noise())

	if issues.is_empty():
		_output.text = "No issues found.\n\nAdd-ons scanned: %d" % addons.size()
	else:
		_output.text = "Add-ons scanned: %d\nIssues found: %d\n\n%s" % [addons.size(), issues.size(), "\n".join(issues)]

func _find_addons() -> Array[String]:
	var addons: Array[String] = []
	var addon_dirs := DirAccess.get_directories_at("res://addons")
	for directory in addon_dirs:
		var addon_path := "res://addons/%s" % directory
		if FileAccess.file_exists("%s/plugin.cfg" % addon_path):
			addons.append(addon_path)
	return addons

func _audit_addon(addon_path: String) -> Array[String]:
	var issues: Array[String] = []
	var config_path := "%s/plugin.cfg" % addon_path
	var plugin := _parse_plugin_section(FileAccess.get_file_as_string(config_path))

	for key in REQUIRED_PLUGIN_KEYS:
		if not plugin.has(key) or String(plugin[key]).strip_edges().is_empty():
			issues.append("[ERROR] %s is missing plugin/%s." % [config_path, key])

	if plugin.has("version") and not _looks_like_semver(String(plugin["version"])):
		issues.append("[WARNING] %s plugin/version should use a release version such as 0.1.0." % config_path)

	if plugin.has("script"):
		var script_path := _resolve_plugin_script(addon_path, String(plugin["script"]))
		if script_path.is_empty():
			issues.append("[ERROR] %s plugin/script points outside the project or uses an unsupported path." % config_path)
		elif not FileAccess.file_exists(script_path):
			issues.append("[ERROR] plugin/script file was not found: %s" % script_path)
		else:
			var script_text := FileAccess.get_file_as_string(script_path)
			if not script_text.contains("@tool"):
				issues.append("[WARNING] %s should usually include @tool." % script_path)
			if not script_text.contains("extends EditorPlugin"):
				issues.append("[WARNING] %s should extend EditorPlugin." % script_path)

	if not FileAccess.file_exists("%s/README.md" % addon_path):
		issues.append("[WARNING] Add a README.md inside %s for Asset Library users." % addon_path)

	if not FileAccess.file_exists("%s/LICENSE.md" % addon_path) and not FileAccess.file_exists("%s/LICENSE" % addon_path):
		issues.append("[WARNING] Add a license file inside %s for Asset Library users." % addon_path)

	return issues

func _audit_package_noise() -> Array[String]:
	var issues: Array[String] = []
	for directory in BLOCKED_PACKAGE_DIRS:
		if DirAccess.dir_exists_absolute("res://%s" % directory):
			issues.append("[WARNING] Exclude res://%s from release ZIPs and Asset Library uploads." % directory)
	return issues

func _parse_plugin_section(text: String) -> Dictionary:
	var plugin := {}
	var in_plugin := false

	for raw_line in text.split("\n"):
		var line := raw_line.strip_edges()
		if line.is_empty() or line.begins_with(";") or line.begins_with("#"):
			continue
		if line.begins_with("[") and line.ends_with("]"):
			in_plugin = line == "[plugin]"
			continue
		if not in_plugin:
			continue

		var separator := line.find("=")
		if separator == -1:
			continue
		var key := line.substr(0, separator).strip_edges()
		var value := line.substr(separator + 1).strip_edges()
		plugin[key] = _unwrap_config_value(value)

	return plugin

func _resolve_plugin_script(addon_path: String, script_value: String) -> String:
	if script_value.is_empty() or script_value.is_absolute_path():
		return ""
	if script_value.begins_with("res://"):
		return script_value
	var resolved := addon_path.path_join(script_value).simplify_path()
	return resolved if resolved.begins_with("res://") else ""

func _unwrap_config_value(value: String) -> String:
	if value.begins_with("\"") and value.ends_with("\"") and value.length() >= 2:
		return value.substr(1, value.length() - 2).replace("\\\"", "\"")
	return value

func _looks_like_semver(value: String) -> bool:
	var parts := value.split(".")
	if parts.size() < 3:
		return false
	for index in range(3):
		if not parts[index].is_valid_int():
			return false
	return true
