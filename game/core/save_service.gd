extends Node

signal save_completed(slot: String, success: bool)

const VALID_SLOTS: Array[String] = ["slot_01", "slot_02", "slot_03", "autosave"]

func _path(slot: String) -> String:
	return "user://" + slot + ".save"

func _backup_path(slot: String) -> String:
	return "user://" + slot + ".backup"

func _valid_slot(slot: String) -> bool:
	return VALID_SLOTS.has(slot)

func has_valid_save(slot: String = "autosave") -> bool:
	if not _valid_slot(slot) or not FileAccess.file_exists(_path(slot)):
		return false
	var file := FileAccess.open(_path(slot), FileAccess.READ)
	if file == null:
		return false
	var data: Variant = _parse_json(file.get_as_text())
	return GameState.validate_payload(data)

func save_slot(slot: String = "slot_01") -> bool:
	if not _valid_slot(slot) or not GameState.has_profile():
		save_completed.emit(slot, false)
		return false
	var payload := GameState.to_serialized()
	var json := JSON.stringify(payload)
	var temporary := _path(slot) + ".tmp"
	var temp_file := FileAccess.open(temporary, FileAccess.WRITE)
	if temp_file == null:
		save_completed.emit(slot, false)
		return false
	temp_file.store_string(json)
	temp_file.close()
	var verify := FileAccess.open(temporary, FileAccess.READ)
	var verified: Variant = _parse_json(verify.get_as_text()) if verify != null else null
	if not GameState.validate_payload(verified):
		save_completed.emit(slot, false)
		return false
	if FileAccess.file_exists(_path(slot)):
		_copy_file(_path(slot), _backup_path(slot))
	var source := FileAccess.open(temporary, FileAccess.READ)
	var destination := FileAccess.open(_path(slot), FileAccess.WRITE)
	if source == null or destination == null:
		save_completed.emit(slot, false)
		return false
	destination.store_string(source.get_as_text())
	destination.close()
	source.close()
	if slot == "autosave" and not FileAccess.file_exists(_backup_path(slot)):
		_copy_file(_path(slot), _backup_path(slot))
	save_completed.emit(slot, true)
	if get_node_or_null("/root/EventBus") != null:
		get_node("/root/EventBus").save_changed.emit()
	return true

func load_slot(slot: String = "slot_01") -> bool:
	if not has_valid_save(slot):
		return false
	var file := FileAccess.open(_path(slot), FileAccess.READ)
	var data: Variant = _parse_json(file.get_as_text())
	return GameState.load_serialized(data)

func corrupt_save_for_test(slot: String = "autosave") -> bool:
	if not _valid_slot(slot):
		return false
	var file := FileAccess.open(_path(slot), FileAccess.WRITE)
	if file == null:
		return false
	file.store_string("{not valid json")
	return true

func _copy_file(from_path: String, to_path: String) -> bool:
	var source := FileAccess.open(from_path, FileAccess.READ)
	var destination := FileAccess.open(to_path, FileAccess.WRITE)
	if source == null or destination == null:
		return false
	destination.store_buffer(source.get_buffer(source.get_length()))
	destination.close()
	source.close()
	return true

func _parse_json(text: String) -> Variant:
	var parser := JSON.new()
	if parser.parse(text) != OK:
		return null
	return parser.data
