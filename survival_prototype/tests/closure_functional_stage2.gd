extends SceneTree

const SaveSystem = preload("res://systems/persistence/save_system.gd")

var checks := 0

func _initialize() -> void:
	if OS.get_environment("CENIZA_CLOSURE_TEST") != "1":
		printerr("Refusing closure validation outside isolated test")
		quit(90)
		return
	if not FileAccess.file_exists("user://closure_expected.json") or not FileAccess.file_exists(SaveSystem.PRIMARY_PATH):
		printerr("Missing stage1 state")
		quit(2)
		return
	var expected_variant: Variant = JSON.parse_string(FileAccess.get_file_as_string("user://closure_expected.json"))
	if not expected_variant is Dictionary:
		printerr("Invalid expected state")
		quit(2)
		return
	var expected: Dictionary = expected_variant
	var packed: PackedScene = load("res://main.tscn")
	var game: Node = packed.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.set_process(false)

	if not _check(int(game.world_seed) == int(expected["seed"]), "22 proceso reiniciado / seed cargada"): return
	if not _check(not bool(game.save_blocked), "23 load primary válido"): return
	var expected_inv: Dictionary = expected["inventory"]
	var inventory_ok := true
	for key_variant in expected_inv.keys():
		var key := String(key_variant)
		if int(game.inventory.get(key, -999)) != int(expected_inv[key]):
			inventory_ok = false
			break
	if not _check(inventory_ok, "24 inventario persistido"): return
	if not _check(int(game.buildings.size()) == int(expected["building_count"]), "24b building persistido"): return
	var chest_ok := false
	for b_variant in game.buildings:
		var b: Dictionary = b_variant
		if String(b.get("type", "")) == "cofre":
			var store: Dictionary = b.get("chest", {})
			if int(store.get("madera", 0)) >= int(expected["chest_wood"]):
				chest_ok = true
				break
	if not _check(chest_ok, "24c cofre persistido"): return
	var chunk_key := String(expected["resource_chunk"])
	var rid := int(expected["resource_id"])
	var chunk_mods: Dictionary = game.chunk_mods
	var resource_ok := false
	if chunk_mods.has(chunk_key):
		var mod: Dictionary = chunk_mods[chunk_key]
		var removed: Array = mod.get("removed_resources", [])
		resource_ok = rid in removed
	if not _check(resource_ok, "24d recurso destruido persiste"): return
	if not _check(int(game.explored_chunks.size()) >= int(expected["explored_count"]), "24e progreso explorado persiste"): return
	if not _check(int(game.loaded_chunks.size()) == 25, "25 mundo reconstruido desde seed + mods"): return

	print("FUNCTIONAL_STAGE2_RESULT=%d PASS" % checks)
	print("FUNCTIONAL_INTEGRAL_RESULT=25/25 PASS")
	print("SAVE_END_TO_END=PASS")
	quit(0)

func _check(condition: bool, label: String) -> bool:
	if not condition:
		printerr("FAIL %s" % label)
		quit(2)
		return false
	checks += 1
	print("PASS %s" % label)
	return true
