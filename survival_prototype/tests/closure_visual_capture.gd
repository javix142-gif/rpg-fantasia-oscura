extends SceneTree

const SaveSystem = preload("res://systems/persistence/save_system.gd")

var game: Node
var out_dir := ""

func _initialize() -> void:
	out_dir = OS.get_environment("CAPTURE_DIR")
	if out_dir == "":
		printerr("CAPTURE_DIR missing")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(out_dir)
	_cleanup_test_saves()
	await _spawn_game()
	await _shot("01_spawn.png")

	game.player_pos = Vector2(1050.0, 620.0)
	game._refresh_chunks(true)
	game._mark_dirty("visual_exploration")
	game.queue_redraw()
	await _frames(4)
	await _shot("02_exploration.png")

	var enemy: Dictionary = _find_enemy(game)
	if enemy.is_empty():
		printerr("No enemy available for visual capture")
		quit(3)
		return
	var ep: Vector2 = enemy["pos"]
	game.player_pos = ep + Vector2(-55.0, 0.0)
	game.facing = Vector2.RIGHT
	enemy["state"] = "windup"
	enemy["state_timer"] = 0.30
	enemy["alerted"] = true
	enemy["attack_dir"] = Vector2.LEFT
	game.queue_redraw()
	await _frames(4)
	await _shot("03_combat.png")

	game.inventory = {"madera": 18, "piedra": 14, "fibra": 9, "comida": 5, "mineral": 3, "venda": 2}
	game.owned_tools = {"hacha": true, "pico": true}
	game.equipped_tool = "hacha"
	game._open_backpack("craft")
	game.queue_redraw()
	await _frames(4)
	await _shot("04_inventory_crafting.png")
	game._close_menu()

	game.player_pos = Vector2.ZERO
	game._refresh_chunks(true)
	game.inventory["madera"] = 30
	game.inventory["piedra"] = 20
	game._select_build("cofre")
	var placement := _find_valid_placement(game)
	if placement == Vector2.INF:
		printerr("No valid building placement for visual capture")
		quit(4)
		return
	game.placement_pos = placement
	game._place_build()
	game.queue_redraw()
	await _frames(4)
	await _shot("05_building.png")

	game._open_map()
	game.queue_redraw()
	await _frames(4)
	await _shot("06_map.png")
	game._close_menu()
	game._mark_dirty("visual_save")
	if not bool(game._save_game(true)):
		printerr("Visual save failed")
		quit(5)
		return
	game.queue_free()
	await _frames(3)
	await _spawn_game(false)
	game._set_major("Partida v0.3 cargada · persistencia OK", 6.0)
	game.queue_redraw()
	await _frames(4)
	await _shot("07_save_load.png")

	print("VISUAL_CAPTURE=7/7 PASS")
	quit(0)

func _spawn_game(clean: bool = true) -> void:
	var packed: PackedScene = load("res://main.tscn")
	game = packed.instantiate()
	root.add_child(game)
	await _frames(45 if clean else 12)
	game.set_process(false)

func _find_enemy(host: Node) -> Dictionary:
	for attempt in range(10):
		for key_variant in host.loaded_chunks.keys():
			var chunk: Dictionary = host.loaded_chunks[key_variant]
			for e_variant in chunk["enemies"]:
				var e: Dictionary = e_variant
				if bool(e.get("alive", true)):
					return e
		host.player_pos = Vector2(float((attempt + 2) * 650), float(620 + (attempt % 2) * 520))
		host._refresh_chunks(true)
	return {}

func _find_valid_placement(host: Node) -> Vector2:
	var dirs := [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP, Vector2(1, 1).normalized(), Vector2(-1, 1).normalized(), Vector2(-1, -1).normalized(), Vector2(1, -1).normalized()]
	for radius in [64.0, 80.0, 96.0, 112.0, 124.0]:
		for dir_variant in dirs:
			var dir: Vector2 = dir_variant
			var p: Vector2 = host._snap_build_pos((host.player_pos as Vector2) + dir * float(radius))
			if bool(host._placement_valid(p)):
				return p
	return Vector2.INF

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _shot(file_name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_viewport().get_texture().get_image()
	if img == null or img.is_empty():
		printerr("Empty screenshot: %s" % file_name)
		quit(6)
		return
	var path := out_dir.path_join(file_name)
	var err := img.save_png(path)
	if err != OK:
		printerr("Screenshot write failed: %s (%s)" % [path, err])
		quit(6)

func _cleanup_test_saves() -> void:
	for path in [SaveSystem.PRIMARY_PATH, SaveSystem.BACKUP_PATH, SaveSystem.TEMP_PATH]:
		if FileAccess.file_exists(String(path)):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(String(path)))
