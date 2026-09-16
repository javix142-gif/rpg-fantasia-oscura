extends SceneTree

const SaveSystem = preload("res://systems/persistence/save_system.gd")

var checks := 0
var game: Node

func _initialize() -> void:
	if OS.get_environment("CENIZA_CLOSURE_TEST") != "1":
		printerr("Refusing to touch user:// outside isolated closure test")
		quit(90)
		return
	_cleanup_test_saves()
	var packed: PackedScene = load("res://main.tscn")
	game = packed.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.set_process(false)

	if not _check(int(game.world_seed) != 0 and int(game.loaded_chunks.size()) == 25, "01 iniciar mundo"): return
	var start_pos: Vector2 = game.player_pos
	game.joystick_vec = Vector2(0.65, 0.0)
	game._update_movement(0.40)
	if not _check((game.player_pos as Vector2).distance_to(start_pos) > 1.0, "02 movimiento"): return
	if not _check(InputMap.has_action("attack") and InputMap.has_action("interact") and InputMap.has_action("inventory") and InputMap.has_action("map"), "03 controles principales"): return
	var stamina_before: float = float(game.stamina)
	game.joystick_vec = Vector2.RIGHT
	game._update_movement(0.35)
	if not _check(bool(game.is_sprinting), "04 sprint"): return
	if not _check(float(game.stamina) < stamina_before, "05 stamina"): return
	game.joystick_vec = Vector2.ZERO

	for i in range(1, 4):
		game.player_pos = Vector2(float(i * 620), float((i % 2) * 540))
		game._refresh_chunks(true)
	if not _check(int(game.explored_chunks.size()) >= 4 and int(game.loaded_chunks.size()) == 25, "06 explorar varios chunks"): return

	var initial_biome: String = String(game._biome_at(Vector2.ZERO))
	var biome_target := Vector2.ZERO
	var biome_found := false
	for y in range(-10, 11):
		for x in range(-10, 11):
			var p := Vector2(float(x * 512), float(y * 512))
			var biome: String = String(game._biome_at(p))
			if biome != initial_biome:
				biome_target = p
				biome_found = true
				break
		if biome_found:
			break
	if biome_found:
		game.player_pos = biome_target
		game._refresh_chunks(true)
	if not _check(biome_found and String(game._biome_at(game.player_pos)) != initial_biome, "07 transición de bioma"): return

	game.inventory["madera"] = 40
	game.inventory["piedra"] = 40
	game.inventory["fibra"] = 12
	game.owned_tools["hacha"] = false
	game.owned_tools["pico"] = false
	game._craft_item("hacha")
	game._craft_item("pico")
	if not _check(bool(game.owned_tools["hacha"]) and bool(game.owned_tools["pico"]), "14 crafting"): return
	game._toggle_tool(String(game.equipped_tool))
	game._toggle_tool("hacha")
	if not _check(String(game.equipped_tool) == "hacha", "15 equipamiento"): return

	var resource: Dictionary = _find_multi_hit_resource(game)
	if not _check(not resource.is_empty(), "08 recurso recolectable localizado"): return
	var kind := String(resource["type"])
	game.equipped_tool = "pico" if kind == "roca" or kind == "mineral" else "hacha"
	game.player_pos = (resource["pos"] as Vector2) + Vector2(-24.0, 0.0)
	game.facing = Vector2.RIGHT
	game.stamina = 100.0
	var chunk_key := String(resource["chunk"])
	var resource_id := int(resource["id"])
	game._start_harvest(resource)
	game._update_harvest(float(game.harvest_duration) + 0.02)
	var mod_after_hit: Dictionary = game._chunk_state(chunk_key)
	var hp_state: Dictionary = mod_after_hit["resource_hp"]
	if not _check(hp_state.has(str(resource_id)) and float(hp_state[str(resource_id)]) > 0.0, "09 daño parcial a recurso"): return
	while float(resource.get("hp", 0.0)) > 0.0:
		game.stamina = 100.0
		game._start_harvest(resource)
		game._update_harvest(float(game.harvest_duration) + 0.02)
	var removed: Array = (game._chunk_state(chunk_key) as Dictionary)["removed_resources"]
	if not _check(resource_id in removed, "08b recolección/destrucción persistente"): return

	var enemy: Dictionary = _find_enemy(game)
	if not _check(not enemy.is_empty(), "10 enemigo localizado para combate"): return
	var enemy_pos: Vector2 = enemy["pos"]
	game.player_pos = enemy_pos + Vector2(-30.0, 0.0)
	game.facing = Vector2.RIGHT
	game.menu_mode = ""
	game.placement_type = ""
	game.harvest_timer = 0.0
	game.hurt_stagger = 0.0
	game.combat_state = "idle"
	game.stamina = 100.0
	enemy["hp"] = 12.0
	enemy["alive"] = true
	game._request_attack()
	game._update_combat(float(game.ATTACK_WINDUP) + 0.02)
	if not _check(not bool(enemy.get("alive", true)), "12 enemigo derrotado"): return
	if not _check(String(game.combat_state) == "active" or String(game.combat_state) == "recovery", "10b combate ejecutado"): return
	var hp_before_damage: float = float(game.hp)
	game._damage_player(7.0, "QA daño")
	if not _check(float(game.hp) < hp_before_damage, "11 recibir daño"): return

	game._open_backpack("inventory")
	if not _check(String(game.menu_mode) == "backpack" and String(game.menu_tab) == "inventory", "13 abrir inventario"): return
	game._close_menu()

	game.player_pos = Vector2.ZERO
	game._refresh_chunks(true)
	game.inventory["madera"] = max(30, int(game.inventory["madera"]))
	game.inventory["piedra"] = max(20, int(game.inventory["piedra"]))
	game._select_build("cofre")
	var placement := _find_valid_placement(game)
	if placement != Vector2.INF:
		game.placement_pos = placement
	var buildings_before := int(game.buildings.size())
	game._place_build()
	if not _check(int(game.buildings.size()) == buildings_before + 1, "16 construir"): return
	var chest_idx := int(game.buildings.size()) - 1
	game._open_chest(chest_idx)
	game.inventory["madera"] = int(game.inventory["madera"]) + 3
	var chest: Dictionary = game.buildings[chest_idx]
	var store: Dictionary = chest["chest"]
	var chest_before := int(store.get("madera", 0))
	game._chest_transfer("madera", true, false)
	if not _check(String(game.menu_mode) == "chest" and int(store.get("madera", 0)) == chest_before + 1, "17 usar cofre"): return
	game._close_menu()

	var day_before := int(game.day_number)
	game.day_clock = 0.999
	game._update_time(1.0)
	if not _check(int(game.day_number) == day_before + 1 and float(game.day_clock) < 0.1, "18 ciclo día/noche"): return
	game.weather_timer = 0.0
	game.set_process(true)
	await process_frame
	game.set_process(false)
	if not _check(float(game.weather_timer) > 0.0 and String(game.weather) in game.WEATHER, "19 clima"): return
	game._open_map()
	if not _check(String(game.menu_mode) == "map" and int(game.explored_chunks.size()) >= 4, "20 mapa/exploración"): return
	game._close_menu()

	game._mark_dirty("closure_e2e")
	var save_ok: bool = bool(game._save_game(true))
	if not _check(save_ok and FileAccess.file_exists(SaveSystem.PRIMARY_PATH), "21 guardar"): return

	var expected := {
		"seed": int(game.world_seed),
		"inventory": (game.inventory as Dictionary).duplicate(true),
		"building_count": int(game.buildings.size()),
		"chest_index": chest_idx,
		"chest_wood": int(store.get("madera", 0)),
		"resource_chunk": chunk_key,
		"resource_id": resource_id,
		"explored_count": int(game.explored_chunks.size()),
	}
	var f := FileAccess.open("user://closure_expected.json", FileAccess.WRITE)
	if f == null:
		printerr("FAIL expected state file")
		quit(2)
		return
	f.store_string(JSON.stringify(expected))
	f.close()
	print("FUNCTIONAL_STAGE1_RESULT=%d PASS" % checks)
	print("SAVE_STAGE1_PRIMARY=%s" % ProjectSettings.globalize_path(SaveSystem.PRIMARY_PATH))
	quit(0)

func _find_multi_hit_resource(host: Node) -> Dictionary:
	for attempt in range(12):
		for key_variant in host.loaded_chunks.keys():
			var chunk: Dictionary = host.loaded_chunks[key_variant]
			for r_variant in chunk["resources"]:
				var r: Dictionary = r_variant
				if float(r.get("max_hp", 1.0)) > 1.0:
					return r
		host.player_pos = Vector2(float((attempt + 2) * 640), float((attempt % 3) * 520))
		host._refresh_chunks(true)
	return {}

func _find_enemy(host: Node) -> Dictionary:
	for attempt in range(12):
		for key_variant in host.loaded_chunks.keys():
			var chunk: Dictionary = host.loaded_chunks[key_variant]
			for e_variant in chunk["enemies"]:
				var e: Dictionary = e_variant
				if bool(e.get("alive", true)):
					return e
		host.player_pos = Vector2(float((attempt + 2) * 720), float(700 + (attempt % 2) * 560))
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

func _check(condition: bool, label: String) -> bool:
	if not condition:
		printerr("FAIL %s" % label)
		quit(2)
		return false
	checks += 1
	print("PASS %s" % label)
	return true

func _cleanup_test_saves() -> void:
	for path in [SaveSystem.PRIMARY_PATH, SaveSystem.BACKUP_PATH, SaveSystem.TEMP_PATH, "user://closure_expected.json", "user://corrupt_expected.json"]:
		if FileAccess.file_exists(String(path)):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(String(path)))
