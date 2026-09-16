class_name CSSaveSystem
extends RefCounted

const SAVE_VERSION := 4
const LEGACY_VERSION := 3
const PRIMARY_PATH := "user://ceniza_salvaje_v03_save.json"
const TEMP_PATH := "user://ceniza_salvaje_v03_save.tmp"
const BACKUP_PATH := "user://ceniza_salvaje_v03_save.bak"

static func validate_state(data: Variant) -> Dictionary:
	if not data is Dictionary:
		return {"ok": false, "error": "save_not_dictionary"}
	var d: Dictionary = data
	var version: int = int(d.get("version", 0))
	if version != SAVE_VERSION and version != LEGACY_VERSION:
		return {"ok": false, "error": "unsupported_version", "version": version}
	if int(d.get("seed", 0)) == 0:
		return {"ok": false, "error": "invalid_seed"}
	var player: Variant = d.get("player", [])
	var spawn: Variant = d.get("spawn", [])
	if not player is Array or player.size() < 2:
		return {"ok": false, "error": "invalid_player"}
	if not spawn is Array or spawn.size() < 2:
		return {"ok": false, "error": "invalid_spawn"}
	if not d.get("inventory", {}) is Dictionary:
		return {"ok": false, "error": "invalid_inventory"}
	if not d.get("chunk_mods", {}) is Dictionary:
		return {"ok": false, "error": "invalid_chunk_mods"}
	if not d.get("buildings", []) is Array:
		return {"ok": false, "error": "invalid_buildings"}
	return {"ok": true, "version": version}

static func parse_and_validate(text: String) -> Dictionary:
	var parser := JSON.new()
	var parse_error: Error = parser.parse(text)
	if parse_error != OK:
		return {
			"ok": false,
			"error": "invalid_json",
			"detail": parser.get_error_message(),
			"line": parser.get_error_line(),
		}
	var parsed: Variant = parser.data
	var verdict: Dictionary = validate_state(parsed)
	if not bool(verdict.get("ok", false)):
		return verdict
	return {"ok": true, "data": _migrate(parsed), "version": int((parsed as Dictionary).get("version", 0))}

static func load_state(primary_path: String = PRIMARY_PATH, backup_path: String = BACKUP_PATH) -> Dictionary:
	if FileAccess.file_exists(primary_path):
		var primary: Dictionary = parse_and_validate(FileAccess.get_file_as_string(primary_path))
		if bool(primary.get("ok", false)):
			primary["source"] = "primary"
			return primary
		if FileAccess.file_exists(backup_path):
			var backup: Dictionary = parse_and_validate(FileAccess.get_file_as_string(backup_path))
			if bool(backup.get("ok", false)):
				backup["source"] = "backup"
				backup["primary_error"] = primary.get("error", "invalid_primary")
				return backup
		return {"ok": false, "error": primary.get("error", "invalid_primary"), "primary_exists": true, "backup_valid": false}
	if FileAccess.file_exists(backup_path):
		var backup_only: Dictionary = parse_and_validate(FileAccess.get_file_as_string(backup_path))
		if bool(backup_only.get("ok", false)):
			backup_only["source"] = "backup"
			backup_only["primary_missing"] = true
			return backup_only
	return {"ok": false, "error": "save_missing", "primary_exists": false, "backup_valid": false}

static func save_state(state: Dictionary, primary_path: String = PRIMARY_PATH, backup_path: String = BACKUP_PATH, temp_path: String = TEMP_PATH) -> Dictionary:
	var to_write: Dictionary = state.duplicate(true)
	to_write["version"] = SAVE_VERSION
	var verdict: Dictionary = validate_state(to_write)
	if not bool(verdict.get("ok", false)):
		return {"ok": false, "error": "state_validation_failed", "detail": verdict.get("error", "unknown")}
	var payload: String = JSON.stringify(to_write)
	var serialized: Dictionary = parse_and_validate(payload)
	if not bool(serialized.get("ok", false)):
		return {"ok": false, "error": "serialization_validation_failed", "detail": serialized.get("error", "unknown")}

	if not _write_text(temp_path, payload):
		return {"ok": false, "error": "temp_write_failed"}
	var temp_check: Dictionary = parse_and_validate(FileAccess.get_file_as_string(temp_path))
	if not bool(temp_check.get("ok", false)):
		_safe_remove(temp_path)
		return {"ok": false, "error": "temp_validation_failed", "detail": temp_check.get("error", "unknown")}

	var original_bytes := PackedByteArray()
	var had_primary: bool = FileAccess.file_exists(primary_path)
	if had_primary:
		var current_check: Dictionary = parse_and_validate(FileAccess.get_file_as_string(primary_path))
		if not bool(current_check.get("ok", false)):
			_safe_remove(temp_path)
			return {"ok": false, "error": "primary_invalid_preserved", "detail": current_check.get("error", "unknown")}
		original_bytes = FileAccess.get_file_as_bytes(primary_path)
		if not _write_bytes(backup_path, original_bytes):
			_safe_remove(temp_path)
			return {"ok": false, "error": "backup_write_failed"}
		var backup_check: Dictionary = parse_and_validate(FileAccess.get_file_as_string(backup_path))
		if not bool(backup_check.get("ok", false)):
			_safe_remove(temp_path)
			return {"ok": false, "error": "backup_validation_failed"}

	var temp_bytes: PackedByteArray = FileAccess.get_file_as_bytes(temp_path)
	if not _write_bytes(primary_path, temp_bytes):
		_safe_remove(temp_path)
		return {"ok": false, "error": "primary_write_failed"}
	var final_check: Dictionary = parse_and_validate(FileAccess.get_file_as_string(primary_path))
	if not bool(final_check.get("ok", false)):
		if had_primary and not original_bytes.is_empty():
			_write_bytes(primary_path, original_bytes)
		_safe_remove(temp_path)
		return {"ok": false, "error": "primary_postwrite_validation_failed"}
	_safe_remove(temp_path)
	return {"ok": true, "version": SAVE_VERSION, "backup_created": had_primary}

static func _migrate(data: Dictionary) -> Dictionary:
	var migrated: Dictionary = data.duplicate(true)
	var version: int = int(migrated.get("version", 0))
	if version == LEGACY_VERSION:
		migrated["version"] = SAVE_VERSION
		if not migrated.has("save_meta"):
			migrated["save_meta"] = {"migrated_from": LEGACY_VERSION}
	return migrated

static func _write_text(path: String, text: String) -> bool:
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(text)
	f.flush()
	f.close()
	return FileAccess.file_exists(path)

static func _write_bytes(path: String, bytes: PackedByteArray) -> bool:
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_buffer(bytes)
	f.flush()
	f.close()
	return FileAccess.file_exists(path)

static func _safe_remove(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
