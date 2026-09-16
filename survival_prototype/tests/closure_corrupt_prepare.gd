extends SceneTree

const SaveSystem = preload("res://systems/persistence/save_system.gd")

func _initialize() -> void:
	if OS.get_environment("CENIZA_CLOSURE_TEST") != "1":
		printerr("Refusing corruption test outside isolated closure environment")
		quit(90)
		return
	var packed: PackedScene = load("res://main.tscn")
	var game: Node = packed.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.set_process(false)
	game.inventory["madera"] = 77
	game._mark_dirty("corrupt_prepare_a")
	if not bool(game._save_game(true)):
		printerr("Could not create first valid primary")
		quit(2)
		return
	game.inventory["madera"] = 78
	game._mark_dirty("corrupt_prepare_b")
	if not bool(game._save_game(true)):
		printerr("Could not rotate backup")
		quit(2)
		return
	if not FileAccess.file_exists(SaveSystem.BACKUP_PATH):
		printerr("Backup was not created")
		quit(2)
		return
	var valid_primary_sha := _sha256(SaveSystem.PRIMARY_PATH)
	var backup_sha := _sha256(SaveSystem.BACKUP_PATH)
	var f := FileAccess.open(SaveSystem.PRIMARY_PATH, FileAccess.WRITE)
	if f == null:
		printerr("Cannot open isolated primary for corruption")
		quit(2)
		return
	f.store_string("{ intentionally-corrupt-primary ")
	f.close()
	var corrupt_sha := _sha256(SaveSystem.PRIMARY_PATH)
	var meta := {
		"valid_primary_sha": valid_primary_sha,
		"backup_sha": backup_sha,
		"corrupt_sha": corrupt_sha,
		"seed": int(game.world_seed),
	}
	var mf := FileAccess.open("user://corrupt_expected.json", FileAccess.WRITE)
	if mf == null:
		printerr("Cannot write corruption metadata")
		quit(2)
		return
	mf.store_string(JSON.stringify(meta))
	mf.close()
	print("CORRUPT_PREPARE=PASS")
	print("VALID_PRIMARY_SHA256=%s" % valid_primary_sha)
	print("BACKUP_SHA256=%s" % backup_sha)
	print("CORRUPT_PRIMARY_SHA256=%s" % corrupt_sha)
	quit(0)

func _sha256(path: String) -> String:
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes(path)
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(bytes)
	return ctx.finish().hex_encode()
