extends SceneTree

const SaveSystem = preload("res://systems/persistence/save_system.gd")

func _initialize() -> void:
	if OS.get_environment("CENIZA_CLOSURE_TEST") != "1":
		printerr("Refusing corruption test outside isolated closure environment")
		quit(90)
		return
	var meta_variant: Variant = JSON.parse_string(FileAccess.get_file_as_string("user://corrupt_expected.json"))
	if not meta_variant is Dictionary:
		printerr("Missing corruption metadata")
		quit(2)
		return
	var meta: Dictionary = meta_variant
	var corrupt_before := _sha256(SaveSystem.PRIMARY_PATH)
	if corrupt_before != String(meta["corrupt_sha"]):
		printerr("Primary changed before recovery test")
		quit(2)
		return
	var packed: PackedScene = load("res://main.tscn")
	var game: Node = packed.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.set_process(false)
	var load_result: Dictionary = SaveSystem.load_state()
	if not bool(load_result.get("ok", false)) or String(load_result.get("source", "")) != "backup":
		printerr("Backup fallback did not validate")
		quit(2)
		return
	if not bool(game.save_blocked) or String(game.save_block_reason) != "primary_invalid_backup_loaded":
		printerr("Runtime did not protect invalid primary")
		quit(2)
		return
	var attempted_save: bool = bool(game._save_game(true))
	if attempted_save:
		printerr("Blocked session unexpectedly wrote save")
		quit(2)
		return
	var corrupt_after := _sha256(SaveSystem.PRIMARY_PATH)
	if corrupt_after != corrupt_before:
		printerr("Corrupt primary was overwritten")
		quit(2)
		return
	if _sha256(SaveSystem.BACKUP_PATH) != String(meta["backup_sha"]):
		printerr("Backup changed unexpectedly")
		quit(2)
		return
	print("SAVE_CORRUPTO=PASS")
	print("PRIMARY_CORRUPT_PRESERVED_SHA256=%s" % corrupt_after)
	print("BACKUP_FALLBACK=PASS")
	print("BLOCKED_WRITE=PASS")
	quit(0)

func _sha256(path: String) -> String:
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes(path)
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(bytes)
	return ctx.finish().hex_encode()
