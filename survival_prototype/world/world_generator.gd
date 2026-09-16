class_name CSWorldGenerator
extends RefCounted

const CHUNK_SIZE := 512.0
const SAFE_RADIUS := 520.0

static func setup_noise(seed: int) -> Dictionary:
	var biome_noise := FastNoiseLite.new()
	biome_noise.seed = seed
	biome_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	biome_noise.frequency = 0.00135
	var detail_noise := FastNoiseLite.new()
	detail_noise.seed = seed ^ 0x5A17C9
	detail_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	detail_noise.frequency = 0.015
	return {"biome": biome_noise, "detail": detail_noise}

static func chunk_coord(pos: Vector2) -> Vector2i:
	return Vector2i(int(floor(pos.x / CHUNK_SIZE)), int(floor(pos.y / CHUNK_SIZE)))

static func chunk_key(coord: Vector2i) -> String:
	return "%d,%d" % [coord.x, coord.y]

static func parse_chunk_key(key: String) -> Vector2i:
	var parts := key.split(",")
	if parts.size() != 2:
		return Vector2i.ZERO
	return Vector2i(int(parts[0]), int(parts[1]))

static func chunk_seed(world_seed: int, coord: Vector2i) -> int:
	var s := world_seed ^ (coord.x * 73856093) ^ (coord.y * 19349663)
	return absi(s) % 2147480000

static func resource_kind(biome: String, roll: float, safe: bool) -> String:
	if safe:
		if roll < 0.30: return "rama"
		if roll < 0.52: return "piedra_suelta"
		if roll < 0.72: return "fibra"
		if roll < 0.86: return "baya"
		return "arbol"
	if biome == "bosque":
		if roll < 0.31: return "arbol"
		if roll < 0.47: return "rama"
		if roll < 0.62: return "fibra"
		if roll < 0.74: return "baya"
		if roll < 0.89: return "roca"
		return "piedra_suelta"
	if biome == "pradera":
		if roll < 0.23: return "fibra"
		if roll < 0.39: return "baya"
		if roll < 0.55: return "piedra_suelta"
		if roll < 0.69: return "rama"
		if roll < 0.84: return "roca"
		return "arbol"
	if roll < 0.25: return "roca"
	if roll < 0.42: return "mineral"
	if roll < 0.62: return "piedra_suelta"
	if roll < 0.82: return "rama"
	return "fibra"

static func resource_max_hp(kind: String) -> float:
	match kind:
		"arbol": return 4.0
		"roca": return 4.0
		"mineral": return 5.0
		_: return 1.0

static func biome_value(pos: Vector2, biome_noise: FastNoiseLite) -> float:
	if pos.length() < SAFE_RADIUS * 0.88:
		return 0.0
	return biome_noise.get_noise_2d(pos.x, pos.y)

static func biome_at(pos: Vector2, biome_noise: FastNoiseLite) -> String:
	var n := biome_value(pos, biome_noise)
	if n < -0.22: return "cenizal"
	if n < 0.27: return "pradera"
	return "bosque"

static func terrain_color(pos: Vector2, biome_noise: FastNoiseLite, detail_noise: FastNoiseLite) -> Color:
	var n := biome_value(pos, biome_noise)
	var ash := Color("665f61")
	var meadow := Color("687b50")
	var forest := Color("345d4d")
	var c := ash
	if n < -0.30:
		c = ash
	elif n < -0.12:
		c = ash.lerp(meadow, smoothstep(-0.30, -0.12, n))
	elif n < 0.19:
		c = meadow
	elif n < 0.36:
		c = meadow.lerp(forest, smoothstep(0.19, 0.36, n))
	else:
		c = forest
	var d := detail_noise.get_noise_2d(pos.x, pos.y) * 0.026
	if pos.length() < SAFE_RADIUS * 0.72:
		c = c.lerp(Color("728455"), 0.28)
	return Color(clampf(c.r + d, 0.0, 1.0), clampf(c.g + d, 0.0, 1.0), clampf(c.b + d, 0.0, 1.0), 1.0)

static func tile_hash(world_seed: int, x: int, y: int) -> int:
	return absi(world_seed ^ (x * 92837111) ^ (y * 689287499))

static func generate_chunk(world_seed: int, coord: Vector2i, mod: Dictionary, biome_noise: FastNoiseLite) -> Dictionary:
	var local_rng := RandomNumberGenerator.new()
	local_rng.seed = chunk_seed(world_seed, coord)
	var key := chunk_key(coord)
	var removed: Array = mod["removed_resources"]
	var hp_state: Dictionary = mod["resource_hp"]
	var killed: Array = mod["killed_enemies"]
	var resources: Array = []
	var enemies: Array = []
	var origin := Vector2(float(coord.x) * CHUNK_SIZE, float(coord.y) * CHUNK_SIZE)

	var count := 8 + local_rng.randi_range(0, 4)
	for i in range(count):
		if i in removed:
			continue
		var pos := origin + Vector2(local_rng.randf_range(24.0, CHUNK_SIZE - 24.0), local_rng.randf_range(24.0, CHUNK_SIZE - 24.0))
		var kind := resource_kind(biome_at(pos, biome_noise), local_rng.randf(), pos.length() < SAFE_RADIUS)
		var max_hp := resource_max_hp(kind)
		var saved_hp := float(hp_state.get(str(i), max_hp))
		resources.append({"id": i, "chunk": key, "type": kind, "pos": pos, "hp": saved_hp, "max_hp": max_hp, "shake": 0.0})

	if coord == Vector2i.ZERO:
		var forced := [
			[100, "rama", Vector2(58, 20)], [101, "rama", Vector2(-62, 26)], [102, "rama", Vector2(92, -42)], [103, "rama", Vector2(-106, 38)],
			[104, "rama", Vector2(132, 72)], [105, "rama", Vector2(-138, -64)], [106, "rama", Vector2(36, 112)], [107, "rama", Vector2(-40, -116)],
			[110, "piedra_suelta", Vector2(42, -58)], [111, "piedra_suelta", Vector2(-46, -62)], [112, "piedra_suelta", Vector2(82, 54)], [113, "piedra_suelta", Vector2(-88, 70)],
			[114, "piedra_suelta", Vector2(122, -90)], [115, "piedra_suelta", Vector2(-126, 92)], [116, "piedra_suelta", Vector2(164, 18)], [117, "piedra_suelta", Vector2(-170, -20)],
			[120, "fibra", Vector2(70, -22)], [121, "fibra", Vector2(-72, 48)], [122, "fibra", Vector2(16, 142)], [123, "fibra", Vector2(-18, -148)],
			[130, "baya", Vector2(28, 82)], [131, "baya", Vector2(-94, -12)], [132, "baya", Vector2(146, -20)],
			[140, "arbol", Vector2(-205, 30)], [141, "arbol", Vector2(208, -72)], [142, "roca", Vector2(190, 118)]
		]
		for item in forced:
			var fid := int(item[0])
			if fid in removed:
				continue
			var kind := String(item[1])
			var max_hp := resource_max_hp(kind)
			resources.append({"id": fid, "chunk": key, "type": kind, "pos": item[2], "hp": float(hp_state.get(str(fid), max_hp)), "max_hp": max_hp, "shake": 0.0})

	var chunk_center := origin + Vector2(CHUNK_SIZE * 0.5, CHUNK_SIZE * 0.5)
	var distance_band := chunk_center.length()
	var enemy_count := 1
	if distance_band > 1500.0 and local_rng.randf() < 0.45:
		enemy_count = 2
	for i in range(enemy_count):
		if i in killed:
			continue
		var ep := origin + Vector2(local_rng.randf_range(54.0, CHUNK_SIZE - 54.0), local_rng.randf_range(54.0, CHUNK_SIZE - 54.0))
		if ep.length() < SAFE_RADIUS + 70.0:
			continue
		var types: Array[String] = ["lobo", "acechador", "saqueador"]
		var kind: String = String(types[local_rng.randi_range(0, types.size() - 1)])
		var max_hp := 34.0 if kind == "lobo" else (42.0 if kind == "acechador" else 58.0)
		enemies.append({
			"id": i, "chunk": key, "type": kind, "pos": ep, "home": ep, "hp": max_hp, "max_hp": max_hp,
			"alive": true, "state": "idle", "state_timer": local_rng.randf_range(0.3, 1.2), "hit_flash": 0.0,
			"knockback": Vector2.ZERO, "phase": local_rng.randf_range(0.0, 10.0), "attack_dir": Vector2.ZERO,
			"has_hit": false, "alerted": false
		})
	return {"coord": coord, "resources": resources, "enemies": enemies}
