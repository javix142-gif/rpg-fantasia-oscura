class_name CSGameState
extends RefCounted

static func snapshot(host: Node) -> Dictionary:
	var building_data: Array = []
	for b_variant in host.buildings:
		var b: Dictionary = b_variant
		var pos: Vector2 = b["pos"]
		building_data.append({
			"type": b["type"],
			"pos": [pos.x, pos.y],
			"rot": int(b.get("rot", 0)),
			"chest": (b.get("chest", {}) as Dictionary).duplicate(true),
		})
	var explored: Array = []
	for key_variant in host.explored_chunks.keys():
		explored.append(String(key_variant))
	explored.sort()
	return {
		"version": 4,
		"seed": host.world_seed,
		"player": [host.player_pos.x, host.player_pos.y],
		"spawn": [host.spawn_pos.x, host.spawn_pos.y],
		"hp": host.hp,
		"hunger": host.hunger,
		"stamina": host.stamina,
		"day_clock": host.day_clock,
		"day_number": host.day_number,
		"weather": host.weather,
		"inventory": host.inventory.duplicate(true),
		"owned_tools": host.owned_tools.duplicate(true),
		"equipped_tool": host.equipped_tool,
		"equipped_weapon": host.equipped_weapon,
		"chunk_mods": host.chunk_mods.duplicate(true),
		"buildings": building_data,
		"explored_chunks": explored,
		"tutorial": {
			"step": host.tutorial_step,
			"done": host.tutorial_done,
			"moved": host.tutorial_moved,
			"branch": host.tutorial_got_branch,
			"stone": host.tutorial_got_stone,
			"bag": host.tutorial_opened_bag,
			"axe": host.tutorial_crafted_axe,
		},
	}

static func apply(host: Node, data: Dictionary) -> bool:
	var seed := int(data.get("seed", 0))
	if seed == 0:
		return false
	var pp = data.get("player", [0.0, 0.0])
	var sp = data.get("spawn", [0.0, 0.0])
	if not pp is Array or pp.size() < 2 or not sp is Array or sp.size() < 2:
		return false
	host.world_seed = seed
	host.player_pos = Vector2(float(pp[0]), float(pp[1]))
	host.spawn_pos = Vector2(float(sp[0]), float(sp[1]))
	host.hp = float(data.get("hp", 100.0))
	host.hunger = float(data.get("hunger", 100.0))
	host.stamina = float(data.get("stamina", 100.0))
	host.day_clock = float(data.get("day_clock", 0.28))
	host.day_number = int(data.get("day_number", 1))
	host.weather = String(data.get("weather", "despejado"))
	var inv: Dictionary = data.get("inventory", {})
	for k_variant in host.inventory.keys():
		var k := String(k_variant)
		host.inventory[k] = int(inv.get(k, host.inventory[k]))
	var tools: Dictionary = data.get("owned_tools", {})
	host.owned_tools["hacha"] = bool(tools.get("hacha", false))
	host.owned_tools["pico"] = bool(tools.get("pico", false))
	host.equipped_tool = String(data.get("equipped_tool", ""))
	host.equipped_weapon = String(data.get("equipped_weapon", "espada_oxidada"))
	host.chunk_mods = _normalize_chunk_mods(data.get("chunk_mods", {}))
	host.buildings.clear()
	for raw_variant in data.get("buildings", []):
		var raw: Dictionary = raw_variant
		var arr: Array = raw.get("pos", [0.0, 0.0])
		var store: Dictionary = (raw.get("chest", {}) as Dictionary).duplicate(true)
		for item_variant in host.MATERIAL_ORDER:
			var item := String(item_variant)
			if not store.has(item):
				store[item] = 0
		host.buildings.append({
			"type": raw.get("type", "fogata"),
			"pos": Vector2(float(arr[0]), float(arr[1])),
			"rot": int(raw.get("rot", 0)),
			"chest": store,
		})
	host.explored_chunks.clear()
	for key_variant in data.get("explored_chunks", []):
		host.explored_chunks[String(key_variant)] = true
	var tut: Dictionary = data.get("tutorial", {})
	host.tutorial_step = int(tut.get("step", 0))
	host.tutorial_done = bool(tut.get("done", false))
	host.tutorial_moved = bool(tut.get("moved", false))
	host.tutorial_got_branch = bool(tut.get("branch", false))
	host.tutorial_got_stone = bool(tut.get("stone", false))
	host.tutorial_opened_bag = bool(tut.get("bag", false))
	host.tutorial_crafted_axe = bool(tut.get("axe", false))
	host.combat_state = "idle"
	host.combat_timer = 0.0
	host.attack_buffered = false
	host.harvest_target = {}
	host.harvest_timer = 0.0
	host.menu_mode = ""
	host.placement_type = ""
	host.loaded_chunks.clear()
	host.current_chunk = Vector2i(999999, 999999)
	if host.spatial_index != null:
		host.spatial_index.rebuild(host.buildings)
	return true

static func _normalize_chunk_mods(raw_mods: Variant) -> Dictionary:
	var normalized: Dictionary = {}
	if not raw_mods is Dictionary:
		return normalized
	for key_variant in (raw_mods as Dictionary).keys():
		var key := String(key_variant)
		var raw_variant: Variant = (raw_mods as Dictionary)[key_variant]
		if not raw_variant is Dictionary:
			continue
		var raw: Dictionary = raw_variant
		var removed: Array = []
		for id_variant in raw.get("removed_resources", []):
			removed.append(int(id_variant))
		var killed: Array = []
		for id_variant in raw.get("killed_enemies", []):
			killed.append(int(id_variant))
		var hp_state: Dictionary = {}
		var raw_hp: Variant = raw.get("resource_hp", {})
		if raw_hp is Dictionary:
			for hp_key_variant in (raw_hp as Dictionary).keys():
				var hp_key := String(hp_key_variant)
				hp_state[hp_key] = float((raw_hp as Dictionary)[hp_key_variant])
		normalized[key] = {
			"removed_resources": removed,
			"resource_hp": hp_state,
			"killed_enemies": killed,
		}
	return normalized
