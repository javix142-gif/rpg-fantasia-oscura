class_name CSBuildingSystem
extends RefCounted

static func select_build(host: Node, kind: String) -> void:
	if not host.BUILD_RECIPES.has(kind): return
	var recipe: Dictionary = host.BUILD_RECIPES[kind]
	if not host._can_pay(recipe["cost"]):
		host._spawn_floater(host.CENTER + Vector2(0, 82), "FALTAN MATERIALES", Color("ed7d78")); host._play_sound("error"); return
	host.menu_mode = ""; host.placement_type = kind; host.placement_rotation = 0
	host.placement_pos = snap_build_pos(host.player_pos + host.facing * 72.0)
	host._set_major("Mueve el fantasma y confirma", 1.6); host._play_sound("ui")

static func snap_build_pos(pos: Vector2) -> Vector2:
	return Vector2(round(pos.x / 16.0) * 16.0, round(pos.y / 16.0) * 16.0)

static func set_placement_from_screen(host: Node, screen_pos: Vector2) -> void:
	var world: Vector2 = host.player_pos + (screen_pos - host.CENTER)
	var offset: Vector2 = world - host.player_pos
	if offset.length() > host.BUILD_RANGE: offset = offset.normalized() * host.BUILD_RANGE
	host.placement_pos = snap_build_pos(host.player_pos + offset)

static func placement_valid(host: Node, pos: Vector2) -> bool:
	if pos.distance_to(host.player_pos) < 34.0 or pos.distance_to(host.player_pos) > host.BUILD_RANGE + 2.0: return false
	var test_build: Dictionary = {"type": host.placement_type, "pos": pos, "rot": host.placement_rotation}
	if host._building_blocks_circle(test_build, host.player_pos, host.PLAYER_RADIUS + 2.0): return false
	var nearby: Array = host.spatial_index.nearby_buildings(host.buildings, pos, 54.0) if host.spatial_index != null else host.buildings
	for b_variant in nearby:
		var b: Dictionary = b_variant
		if (b["pos"] as Vector2).distance_to(pos) < 52.0: return false
	var cc: Vector2i = host._chunk_coord(pos)
	for y in range(cc.y - 1, cc.y + 2):
		for x in range(cc.x - 1, cc.x + 2):
			var key: String = host._chunk_key(Vector2i(x, y))
			if not host.loaded_chunks.has(key): continue
			var chunk: Dictionary = host.loaded_chunks[key]
			for r_variant in chunk["resources"]:
				var r: Dictionary = r_variant
				var rr: float = host._resource_collision_radius(String(r["type"]))
				if rr > 0.0 and (r["pos"] as Vector2).distance_to(pos) < rr + 22.0: return false
	return true

static func place_build(host: Node) -> void:
	if host.placement_type == "": return
	var recipe: Dictionary = host.BUILD_RECIPES[host.placement_type]
	var cost: Dictionary = recipe["cost"]
	if not placement_valid(host, host.placement_pos):
		host._spawn_floater(host._world_to_screen(host.placement_pos) + Vector2(0, -22), "BLOQUEADO", Color("ef7777")); host._play_sound("error"); return
	if not host._can_pay(cost):
		host._spawn_floater(host.CENTER + Vector2(0, 82), "FALTAN MATERIALES", Color("ed7d78")); host.placement_type = ""; return
	host._pay(cost)
	var chest_store: Dictionary = {"madera": 0, "piedra": 0, "fibra": 0, "comida": 0, "mineral": 0, "venda": 0}
	var building: Dictionary = {"type": host.placement_type, "pos": host.placement_pos, "rot": host.placement_rotation, "chest": chest_store}
	host.buildings.append(building)
	if host.spatial_index != null: host.spatial_index.register_building(host.buildings.size() - 1, building)
	host._mark_dirty("building_placed"); host._spawn_particles(host.placement_pos, Color("d7c39a"), 16)
	host._set_major("Construido: %s" % String(recipe["name"]), 1.4); host._play_sound("build")
	host.placement_type = ""; host.placement_drag_touch = -1; host._save_game()

static func cancel_placement(host: Node) -> void:
	host.placement_type = ""; host.placement_drag_touch = -1; host.placement_mouse_drag = false; host._play_sound("ui")
