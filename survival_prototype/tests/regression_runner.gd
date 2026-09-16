extends SceneTree

const Runtime = preload("res://v03.gd")
const SaveSystem = preload("res://systems/persistence/save_system.gd")

var passed: int = 0
var failed: int = 0
var failures: Array[String] = []

func _init() -> void:
	_run("deterministic_same_seed_chunk", _test_deterministic_same_seed_chunk)
	_run("deterministic_different_seed_changes_chunk", _test_different_seed_changes_chunk)
	_run("chunk_removed_resource_persists", _test_chunk_removed_resource)
	_run("chunk_partial_hp_persists", _test_chunk_partial_hp)
	_run("chunk_killed_enemy_persists", _test_chunk_killed_enemy)
	_run("crafting_cost_regression", _test_crafting_costs)
	_run("save_roundtrip", _test_save_roundtrip)
	_run("corrupt_primary_preserved", _test_corrupt_primary_preserved)
	_run("backup_fallback", _test_backup_fallback)
	_run("building_roundtrip", _test_building_roundtrip)
	_run("chest_roundtrip", _test_chest_roundtrip)
	_run("save_version_migration_v3", _test_v3_migration)
	print("REGRESSION_RESULT=%d/%d PASS" % [passed, passed + failed])
	if failed > 0:
		for item in failures:
			push_error(item)
		quit(1)
	else:
		quit(0)

func _run(name: String, test_callable: Callable) -> void:
	var ok: bool = false
	var result: Variant = test_callable.call()
	if result is bool:
		ok = result
	if ok:
		passed += 1
		print("PASS ", name)
	else:
		failed += 1
		failures.append("FAIL %s" % name)
		print("FAIL ", name)

func _new_runtime(seed: int = 424242) -> Node:
	var host: Node = Runtime.new()
	host.world_seed = seed
	host._setup_noise()
	return host

func _chunk_signature(chunk: Dictionary) -> String:
	var parts: Array[String] = []
	for r_variant in chunk["resources"]:
		var r: Dictionary = r_variant
		var p: Vector2 = r["pos"]
		parts.append("r:%d:%s:%.3f:%.3f:%.2f" % [int(r["id"]), String(r["type"]), p.x, p.y, float(r["hp"])])
	for e_variant in chunk["enemies"]:
		var e: Dictionary = e_variant
		var p: Vector2 = e["pos"]
		parts.append("e:%d:%s:%.3f:%.3f:%.2f" % [int(e["id"]), String(e["type"]), p.x, p.y, float(e["hp"])])
	return "|".join(parts)

func _test_deterministic_same_seed_chunk() -> bool:
	var a: Node = _new_runtime(424242)
	var b: Node = _new_runtime(424242)
	var sa: String = _chunk_signature(a._generate_chunk(Vector2i(3, -2)))
	var sb: String = _chunk_signature(b._generate_chunk(Vector2i(3, -2)))
	a.free(); b.free()
	return sa == sb and not sa.is_empty()

func _test_different_seed_changes_chunk() -> bool:
	var a: Node = _new_runtime(424242)
	var b: Node = _new_runtime(424243)
	var sa: String = _chunk_signature(a._generate_chunk(Vector2i(3, -2)))
	var sb: String = _chunk_signature(b._generate_chunk(Vector2i(3, -2)))
	a.free(); b.free()
	return sa != sb

func _test_chunk_removed_resource() -> bool:
	var h: Node = _new_runtime()
	h.chunk_mods["0,0"] = {"removed_resources": [100], "resource_hp": {}, "killed_enemies": []}
	var chunk: Dictionary = h._generate_chunk(Vector2i.ZERO)
	for r_variant in chunk["resources"]:
		if int((r_variant as Dictionary)["id"]) == 100:
			h.free(); return false
	h.free(); return true

func _test_chunk_partial_hp() -> bool:
	var h: Node = _new_runtime()
	h.chunk_mods["0,0"] = {"removed_resources": [], "resource_hp": {"140": 2.0}, "killed_enemies": []}
	var chunk: Dictionary = h._generate_chunk(Vector2i.ZERO)
	for r_variant in chunk["resources"]:
		var r: Dictionary = r_variant
		if int(r["id"]) == 140:
			var ok: bool = is_equal_approx(float(r["hp"]), 2.0)
			h.free(); return ok
	h.free(); return false

func _test_chunk_killed_enemy() -> bool:
	var h: Node = _new_runtime()
	var key: String = String(h._chunk_key(Vector2i(2, 2)))
	h.chunk_mods[key] = {"removed_resources": [], "resource_hp": {}, "killed_enemies": [0]}
	var chunk: Dictionary = h._generate_chunk(Vector2i(2, 2))
	for e_variant in chunk["enemies"]:
		if int((e_variant as Dictionary)["id"]) == 0:
			h.free(); return false
	h.free(); return true

func _test_crafting_costs() -> bool:
	var h: Node = _new_runtime()
	h.inventory = {"madera": 4, "piedra": 3, "fibra": 3, "comida": 0, "mineral": 0, "venda": 0}
	var axe_cost: Dictionary = h.CRAFT_RECIPES["hacha"]["cost"]
	if not h._can_pay(axe_cost): h.free(); return false
	h._pay(axe_cost)
	var ok: bool = int(h.inventory["madera"]) == 0 and int(h.inventory["piedra"]) == 0
	h.free(); return ok

func _sample_state(seed: int = 424242) -> Dictionary:
	return {
		"version": 4, "seed": seed, "player": [12.0, -8.0], "spawn": [0.0, 0.0],
		"hp": 81.0, "hunger": 67.0, "stamina": 44.0, "day_clock": 0.5, "day_number": 3,
		"weather": "lluvia", "inventory": {"madera": 8, "piedra": 5, "fibra": 4, "comida": 2, "mineral": 1, "venda": 1},
		"owned_tools": {"hacha": true, "pico": false}, "equipped_tool": "hacha", "equipped_weapon": "espada_oxidada",
		"chunk_mods": {"0,0": {"removed_resources": [100], "resource_hp": {"140": 2.0}, "killed_enemies": []}},
		"buildings": [{"type": "cofre", "pos": [32.0, 48.0], "rot": 1, "chest": {"madera": 5, "piedra": 2, "fibra": 0, "comida": 1, "mineral": 0, "venda": 0}}],
		"explored_chunks": ["0,0", "1,0"], "tutorial": {"step": 4, "done": false, "moved": true, "branch": true, "stone": true, "bag": true, "axe": false}
	}

func _paths(prefix: String) -> Dictionary:
	return {"p": "user://%s.json" % prefix, "b": "user://%s.bak" % prefix, "t": "user://%s.tmp" % prefix}

func _cleanup(paths: Dictionary) -> void:
	for path_variant in paths.values():
		var path: String = String(path_variant)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _write_text(path: String, text: String) -> void:
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text); f.close()

func _test_save_roundtrip() -> bool:
	var p: Dictionary = _paths("cs_test_roundtrip"); _cleanup(p)
	var state: Dictionary = _sample_state()
	var wr: Dictionary = SaveSystem.save_state(state, p.p, p.b, p.t)
	var rd: Dictionary = SaveSystem.load_state(p.p, p.b)
	var ok: bool = bool(wr.get("ok", false)) and bool(rd.get("ok", false)) and int((rd.data as Dictionary)["seed"]) == 424242 and (rd.data as Dictionary)["inventory"] == state["inventory"]
	_cleanup(p); return ok

func _test_corrupt_primary_preserved() -> bool:
	var p: Dictionary = _paths("cs_test_corrupt"); _cleanup(p)
	var corrupt: String = "{broken-json:"
	_write_text(p.p, corrupt)
	var wr: Dictionary = SaveSystem.save_state(_sample_state(), p.p, p.b, p.t)
	var still: String = FileAccess.get_file_as_string(p.p)
	var ok: bool = not bool(wr.get("ok", false)) and String(wr.get("error", "")) == "primary_invalid_preserved" and still == corrupt
	_cleanup(p); return ok

func _test_backup_fallback() -> bool:
	var p: Dictionary = _paths("cs_test_backup"); _cleanup(p)
	var first: Dictionary = _sample_state(111111)
	var second: Dictionary = _sample_state(222222)
	if not bool(SaveSystem.save_state(first, p.p, p.b, p.t).get("ok", false)): _cleanup(p); return false
	if not bool(SaveSystem.save_state(second, p.p, p.b, p.t).get("ok", false)): _cleanup(p); return false
	_write_text(p.p, "corrupt")
	var rd: Dictionary = SaveSystem.load_state(p.p, p.b)
	var ok: bool = bool(rd.get("ok", false)) and String(rd.get("source", "")) == "backup" and int((rd.data as Dictionary)["seed"]) == 111111
	_cleanup(p); return ok

func _test_building_roundtrip() -> bool:
	var p: Dictionary = _paths("cs_test_building"); _cleanup(p)
	var state: Dictionary = _sample_state()
	SaveSystem.save_state(state, p.p, p.b, p.t)
	var rd: Dictionary = SaveSystem.load_state(p.p, p.b)
	var buildings: Array = (rd.data as Dictionary)["buildings"]
	var b: Dictionary = buildings[0]
	var ok: bool = String(b["type"]) == "cofre" and int(b["rot"]) == 1 and b["pos"] == [32.0, 48.0]
	_cleanup(p); return ok

func _test_chest_roundtrip() -> bool:
	var p: Dictionary = _paths("cs_test_chest"); _cleanup(p)
	SaveSystem.save_state(_sample_state(), p.p, p.b, p.t)
	var rd: Dictionary = SaveSystem.load_state(p.p, p.b)
	var chest: Dictionary = ((rd.data as Dictionary)["buildings"] as Array)[0]["chest"]
	var ok: bool = int(chest["madera"]) == 5 and int(chest["piedra"]) == 2 and int(chest["comida"]) == 1
	_cleanup(p); return ok

func _test_v3_migration() -> bool:
	var legacy: Dictionary = _sample_state()
	legacy["version"] = 3
	var parsed: Dictionary = SaveSystem.parse_and_validate(JSON.stringify(legacy))
	return bool(parsed.get("ok", false)) and int((parsed.data as Dictionary)["version"]) == 4
