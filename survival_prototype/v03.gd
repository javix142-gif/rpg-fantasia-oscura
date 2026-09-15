extends Node2D

# Ceniza Salvaje v0.3 — Core Survival Pass
# Objetivo: game feel, restricciones, economia, inventario/equipamiento,
# construccion movil, cofres, colisiones, zona segura, mapa y onboarding.

const SCREEN := Vector2(640.0, 360.0)
const CENTER := Vector2(320.0, 180.0)
const TILE_SIZE := 32.0
const CHUNK_SIZE := 512.0
const ACTIVE_RADIUS := 2
const SAFE_RADIUS := 520.0
const SAVE_PATH := "user://ceniza_salvaje_v03_save.json"

const JOY_CENTER := Vector2(82.0, 290.0)
const JOY_RADIUS := 47.0
const ATTACK_CENTER := Vector2(581.0, 302.0)
const INTERACT_CENTER := Vector2(505.0, 312.0)
const BAG_CENTER := Vector2(581.0, 229.0)
const MAP_RECT := Rect2(558.0, 9.0, 72.0, 72.0)

const WALK_SPEED := 76.0
const SPRINT_SPEED := 110.0
const SPRINT_DRAIN := 14.0
const ATTACK_COST := 12.0
const ATTACK_RANGE := 44.0
const ATTACK_DOT := 0.76604444 # cos(40°) -> cono frontal de ~80°
const ATTACK_WINDUP := 0.13
const ATTACK_ACTIVE := 0.10
const ATTACK_RECOVERY := 0.36
const STAMINA_REGEN_DELAY := 0.82
const PLAYER_RADIUS := 8.0
const BUILD_RANGE := 128.0

const WEATHER := ["despejado", "lluvia", "niebla"]
const MATERIAL_ORDER := ["madera", "piedra", "fibra", "comida", "mineral", "venda"]
const CRAFT_ORDER := ["hacha", "pico", "venda"]
const BUILD_ORDER := ["fogata", "muro", "cofre"]

const CRAFT_RECIPES := {
	"hacha": {"name": "Hacha de piedra", "cost": {"madera": 4, "piedra": 3}, "desc": "Permite talar arboles", "unique": true},
	"pico": {"name": "Pico de piedra", "cost": {"madera": 4, "piedra": 5}, "desc": "Permite romper roca y mineral", "unique": true},
	"venda": {"name": "Vendaje", "cost": {"fibra": 3}, "desc": "Recupera 28 PV", "unique": false},
}

const BUILD_RECIPES := {
	"fogata": {"name": "Fogata", "cost": {"madera": 4, "piedra": 4}, "desc": "Refugio nocturno"},
	"muro": {"name": "Muro de madera", "cost": {"madera": 7}, "desc": "Bloquea paso y enemigos"},
	"cofre": {"name": "Cofre", "cost": {"madera": 9}, "desc": "Almacenamiento persistente"},
}

var world_seed: int = 0
var biome_noise: FastNoiseLite
var detail_noise: FastNoiseLite
var rng := RandomNumberGenerator.new()

var player_pos := Vector2.ZERO
var spawn_pos := Vector2.ZERO
var facing := Vector2.DOWN
var hp := 100.0
var hunger := 100.0
var stamina := 100.0
var stamina_regen_lock := 0.0
var hurt_stagger := 0.0
var day_clock := 0.28
var day_number := 1
var weather := "despejado"
var weather_timer := 48.0
var save_timer := 12.0
var anim_clock := 0.0
var is_moving := false
var is_sprinting := false

var combat_state := "idle" # idle/windup/active/recovery
var combat_timer := 0.0
var attack_buffered := false
var attack_hit_done := false

var harvest_target: Dictionary = {}
var harvest_timer := 0.0
var harvest_duration := 0.0
var harvest_cost := 0.0
var harvest_started_pos := Vector2.ZERO
var harvest_kind := ""

var current_chunk := Vector2i(999999, 999999)
var loaded_chunks: Dictionary = {}
var chunk_mods: Dictionary = {}
var explored_chunks: Dictionary = {}
var buildings: Array = []

var inventory := {
	"madera": 0,
	"piedra": 0,
	"fibra": 0,
	"comida": 1,
	"mineral": 0,
	"venda": 0,
}
var owned_tools := {"hacha": false, "pico": false}
var equipped_tool := ""
var equipped_weapon := "espada_oxidada"

var particles: Array = []
var floaters: Array = []
var screen_shake := 0.0
var major_message := ""
var major_message_timer := 0.0
var contextual_hint := ""

var joystick_touch := -1
var joystick_vec := Vector2.ZERO
var mouse_joystick := false

var menu_mode := "" # backpack/chest/map
var menu_tab := "inventory" # inventory/craft/build
var chest_index := -1
var placement_type := ""
var placement_pos := Vector2.ZERO
var placement_rotation := 0
var placement_drag_touch := -1
var placement_mouse_drag := false

var tutorial_step := 0
var tutorial_done := false
var tutorial_moved := false
var tutorial_got_branch := false
var tutorial_got_stone := false
var tutorial_opened_bag := false
var tutorial_crafted_axe := false

var sound_players: Array[AudioStreamPlayer] = []
var sounds: Dictionary = {}
var sound_cursor := 0

func _ready() -> void:
	get_viewport().set_embedding_subwindows(false)
	_setup_audio()
	if FileAccess.file_exists(SAVE_PATH) and _load_game():
		_setup_noise()
		_refresh_chunks(true)
		_set_major("Partida v0.3 cargada", 1.5)
	else:
		_new_world()
	set_process(true)
	queue_redraw()

func _new_world() -> void:
	world_seed = absi(int(Time.get_unix_time_from_system() * 1000.0)) % 2147480000
	if world_seed == 0:
		world_seed = 314159
	spawn_pos = Vector2.ZERO
	player_pos = spawn_pos
	facing = Vector2.DOWN
	hp = 100.0
	hunger = 100.0
	stamina = 100.0
	stamina_regen_lock = 0.0
	day_clock = 0.28
	day_number = 1
	weather = "despejado"
	inventory = {"madera": 0, "piedra": 0, "fibra": 0, "comida": 1, "mineral": 0, "venda": 0}
	owned_tools = {"hacha": false, "pico": false}
	equipped_tool = ""
	equipped_weapon = "espada_oxidada"
	chunk_mods.clear()
	explored_chunks.clear()
	buildings.clear()
	loaded_chunks.clear()
	current_chunk = Vector2i(999999, 999999)
	tutorial_step = 0
	tutorial_done = false
	tutorial_moved = false
	tutorial_got_branch = false
	tutorial_got_stone = false
	tutorial_opened_bag = false
	tutorial_crafted_axe = false
	_setup_noise()
	_refresh_chunks(true)
	_set_major("Un claro seguro. Reune recursos antes de salir.", 3.0)
	_save_game()

func _setup_noise() -> void:
	biome_noise = FastNoiseLite.new()
	biome_noise.seed = world_seed
	biome_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	biome_noise.frequency = 0.00135
	detail_noise = FastNoiseLite.new()
	detail_noise.seed = world_seed ^ 0x5A17C9
	detail_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	detail_noise.frequency = 0.015
	rng.seed = world_seed

func _process(delta: float) -> void:
	anim_clock += delta
	major_message_timer = maxf(0.0, major_message_timer - delta)
	screen_shake = maxf(0.0, screen_shake - delta)
	hurt_stagger = maxf(0.0, hurt_stagger - delta)
	stamina_regen_lock = maxf(0.0, stamina_regen_lock - delta)
	weather_timer -= delta
	save_timer -= delta
	_update_time(delta)
	_update_combat(delta)
	_update_harvest(delta)
	_update_movement(delta)
	_update_enemies(delta)
	_update_survival(delta)
	_update_fx(delta)
	_update_tutorial()
	_update_context_hint()
	if weather_timer <= 0.0:
		weather_timer = 55.0 + rng.randf_range(-10.0, 18.0)
		weather = WEATHER[rng.randi_range(0, WEATHER.size() - 1)]
		_set_major("Cambia el tiempo: %s" % weather, 1.7)
		_play_sound("weather")
	if save_timer <= 0.0:
		save_timer = 12.0
		_save_game()
	queue_redraw()

func _update_time(delta: float) -> void:
	var old_clock := day_clock
	day_clock += delta / 230.0
	if day_clock >= 1.0:
		day_clock -= 1.0
		day_number += 1
		_set_major("Día %d" % day_number, 1.6)
	if old_clock < 0.74 and day_clock >= 0.74:
		_set_major("Cae la noche", 1.6)

func _action_move_multiplier() -> float:
	if hurt_stagger > 0.0:
		return 0.0
	if harvest_timer > 0.0:
		return 0.18
	if combat_state != "idle":
		return 0.30
	return 1.0

func _update_movement(delta: float) -> void:
	if menu_mode != "":
		is_moving = false
		is_sprinting = false
		joystick_vec = Vector2.ZERO
		_regen_stamina(delta, 8.0)
		return
	var move := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): move.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): move.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): move.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): move.y += 1.0
	if joystick_vec.length() > 0.08:
		move = joystick_vec
	if move.length() > 1.0:
		move = move.normalized()
	is_moving = move.length() > 0.08
	var multiplier := _action_move_multiplier()
	if is_moving and multiplier > 0.0:
		if combat_state == "idle" and harvest_timer <= 0.0:
			facing = _cardinal(move)
		var wants_sprint := (joystick_vec.length() > 0.88 or Input.is_key_pressed(KEY_SHIFT)) and multiplier >= 0.99
		is_sprinting = wants_sprint and stamina > 2.0
		var speed := SPRINT_SPEED if is_sprinting else WALK_SPEED
		if is_sprinting:
			stamina = maxf(0.0, stamina - SPRINT_DRAIN * delta)
			stamina_regen_lock = STAMINA_REGEN_DELAY
		else:
			_regen_stamina(delta, 9.0)
		var delta_move := move * speed * multiplier * delta
		player_pos = _move_with_world_collisions(player_pos, delta_move, PLAYER_RADIUS)
	else:
		is_sprinting = false
		_regen_stamina(delta, 12.0)
	if player_pos.distance_to(spawn_pos) > 28.0:
		tutorial_moved = true
	_refresh_chunks(false)

func _regen_stamina(delta: float, rate: float) -> void:
	if stamina_regen_lock <= 0.0 and combat_state == "idle" and harvest_timer <= 0.0:
		stamina = minf(100.0, stamina + rate * delta)

func _cardinal(v: Vector2) -> Vector2:
	if absf(v.x) > absf(v.y):
		return Vector2.RIGHT if v.x > 0.0 else Vector2.LEFT
	return Vector2.DOWN if v.y > 0.0 else Vector2.UP

func _update_survival(delta: float) -> void:
	hunger = maxf(0.0, hunger - delta * 0.18)
	if hunger <= 0.0:
		hp -= delta * 1.6
	for b_variant in buildings:
		var b: Dictionary = b_variant
		if String(b.get("type", "")) == "fogata":
			var bp: Vector2 = b["pos"]
			if bp.distance_to(player_pos) < 76.0 and (day_clock > 0.72 or day_clock < 0.18):
				hp = minf(100.0, hp + delta * 0.5)
	if hp <= 0.0:
		_respawn()

func _respawn() -> void:
	hp = 65.0
	hunger = 55.0
	stamina = 100.0
	player_pos = spawn_pos
	combat_state = "idle"
	harvest_timer = 0.0
	harvest_target = {}
	loaded_chunks.clear()
	current_chunk = Vector2i(999999, 999999)
	_refresh_chunks(true)
	_set_major("Has caído. Regresas al claro.", 2.6)
	_play_sound("hurt")

func _refresh_chunks(force: bool) -> void:
	var cc := _chunk_coord(player_pos)
	if not force and cc == current_chunk:
		return
	current_chunk = cc
	var current_key := _chunk_key(cc)
	explored_chunks[current_key] = true
	var wanted: Dictionary = {}
	for y in range(cc.y - ACTIVE_RADIUS, cc.y + ACTIVE_RADIUS + 1):
		for x in range(cc.x - ACTIVE_RADIUS, cc.x + ACTIVE_RADIUS + 1):
			var c := Vector2i(x, y)
			var key := _chunk_key(c)
			wanted[key] = true
			if not loaded_chunks.has(key):
				loaded_chunks[key] = _generate_chunk(c)
	var existing := loaded_chunks.keys()
	for key_variant in existing:
		var key := String(key_variant)
		if not wanted.has(key):
			loaded_chunks.erase(key)

func _chunk_coord(pos: Vector2) -> Vector2i:
	return Vector2i(int(floor(pos.x / CHUNK_SIZE)), int(floor(pos.y / CHUNK_SIZE)))

func _chunk_key(coord: Vector2i) -> String:
	return "%d,%d" % [coord.x, coord.y]

func _parse_chunk_key(key: String) -> Vector2i:
	var parts := key.split(",")
	if parts.size() != 2:
		return Vector2i.ZERO
	return Vector2i(int(parts[0]), int(parts[1]))

func _chunk_seed(coord: Vector2i) -> int:
	var s := world_seed ^ (coord.x * 73856093) ^ (coord.y * 19349663)
	return absi(s) % 2147480000

func _generate_chunk(coord: Vector2i) -> Dictionary:
	var local_rng := RandomNumberGenerator.new()
	local_rng.seed = _chunk_seed(coord)
	var key := _chunk_key(coord)
	var mod := _chunk_state(key)
	var removed: Array = mod["removed_resources"]
	var hp_state: Dictionary = mod["resource_hp"]
	var killed: Array = mod["killed_enemies"]
	var resources: Array = []
	var enemies: Array = []
	var origin := Vector2(float(coord.x) * CHUNK_SIZE, float(coord.y) * CHUNK_SIZE)

	# Menos densidad que v0.2: 8-12 nodos por chunk, con recursos ligeros frecuentes.
	var count := 8 + local_rng.randi_range(0, 4)
	for i in range(count):
		if i in removed:
			continue
		var pos := origin + Vector2(local_rng.randf_range(24.0, CHUNK_SIZE - 24.0), local_rng.randf_range(24.0, CHUNK_SIZE - 24.0))
		var kind := _resource_kind(_biome_at(pos), local_rng.randf(), pos.length() < SAFE_RADIUS)
		var max_hp := _resource_max_hp(kind)
		var saved_hp := float(hp_state.get(str(i), max_hp))
		resources.append({"id": i, "chunk": key, "type": kind, "pos": pos, "hp": saved_hp, "max_hp": max_hp, "shake": 0.0})

	# Kit inicial determinista dentro del claro: suficientes recursos manuales para las primeras herramientas.
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
			var max_hp := _resource_max_hp(kind)
			resources.append({"id": fid, "chunk": key, "type": kind, "pos": item[2], "hp": float(hp_state.get(str(fid), max_hp)), "max_hp": max_hp, "shake": 0.0})

	# Progresión de amenaza: nunca spawnea dentro del radio seguro. Más lejos puede haber 1-2 enemigos.
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

func _chunk_state(key: String) -> Dictionary:
	if not chunk_mods.has(key):
		chunk_mods[key] = {"removed_resources": [], "resource_hp": {}, "killed_enemies": []}
	return chunk_mods[key]

func _resource_kind(biome: String, roll: float, safe: bool) -> String:
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

func _resource_max_hp(kind: String) -> float:
	match kind:
		"arbol": return 4.0
		"roca": return 4.0
		"mineral": return 5.0
		_: return 1.0

func _biome_value(pos: Vector2) -> float:
	# El claro inicial se mantiene pradera para legibilidad y onboarding.
	if pos.length() < SAFE_RADIUS * 0.88:
		return 0.0
	return biome_noise.get_noise_2d(pos.x, pos.y)

func _biome_at(pos: Vector2) -> String:
	var n := _biome_value(pos)
	if n < -0.22: return "cenizal"
	if n < 0.27: return "pradera"
	return "bosque"

func _terrain_color(pos: Vector2) -> Color:
	var n := _biome_value(pos)
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
	# Variación reducida para que el suelo no parezca una cuadrícula de bloques.
	var d := detail_noise.get_noise_2d(pos.x, pos.y) * 0.026
	if pos.length() < SAFE_RADIUS * 0.72:
		c = c.lerp(Color("728455"), 0.28)
	return Color(clampf(c.r + d, 0.0, 1.0), clampf(c.g + d, 0.0, 1.0), clampf(c.b + d, 0.0, 1.0), 1.0)

# -----------------------------------------------------------------------------
# Colisiones simples y baratas: jugador/enemigos contra recursos sólidos y edificios.
# -----------------------------------------------------------------------------
func _move_with_world_collisions(from: Vector2, delta_move: Vector2, radius: float) -> Vector2:
	var p := from
	var test_x := Vector2(p.x + delta_move.x, p.y)
	if not _position_blocked(test_x, radius):
		p.x = test_x.x
	var test_y := Vector2(p.x, p.y + delta_move.y)
	if not _position_blocked(test_y, radius):
		p.y = test_y.y
	return p

func _position_blocked(pos: Vector2, radius: float) -> bool:
	for key_variant in loaded_chunks.keys():
		var chunk: Dictionary = loaded_chunks[key_variant]
		for r_variant in chunk["resources"]:
			var r: Dictionary = r_variant
			var kind := String(r["type"])
			var rr := _resource_collision_radius(kind)
			if rr > 0.0 and (r["pos"] as Vector2).distance_to(pos) < rr + radius:
				return true
	for b_variant in buildings:
		var b: Dictionary = b_variant
		if _building_blocks_circle(b, pos, radius):
			return true
	return false

func _resource_collision_radius(kind: String) -> float:
	match kind:
		"arbol": return 12.0
		"roca": return 13.0
		"mineral": return 12.0
		_: return 0.0

func _building_blocks_circle(b: Dictionary, pos: Vector2, radius: float) -> bool:
	var kind := String(b.get("type", ""))
	var bp: Vector2 = b["pos"]
	if kind == "fogata":
		return bp.distance_to(pos) < 10.0 + radius
	if kind == "cofre":
		return _circle_rect_overlap(pos, radius, Rect2(bp - Vector2(15, 11), Vector2(30, 22)))
	if kind == "muro":
		var rot := int(b.get("rot", 0))
		var size := Vector2(46, 12) if rot % 2 == 0 else Vector2(12, 46)
		return _circle_rect_overlap(pos, radius, Rect2(bp - size * 0.5, size))
	return false

func _circle_rect_overlap(center: Vector2, radius: float, rect: Rect2) -> bool:
	var closest := Vector2(clampf(center.x, rect.position.x, rect.end.x), clampf(center.y, rect.position.y, rect.end.y))
	return center.distance_squared_to(closest) < radius * radius

# -----------------------------------------------------------------------------
# Combate del jugador: wind-up -> activo -> recovery, stamina, buffer único.
# -----------------------------------------------------------------------------
func _request_attack() -> void:
	if menu_mode != "" or placement_type != "" or harvest_timer > 0.0 or hurt_stagger > 0.0:
		return
	if combat_state != "idle":
		attack_buffered = true
		return
	_start_attack()

func _start_attack() -> void:
	if stamina < ATTACK_COST:
		_spawn_floater(CENTER + Vector2(0, -28), "SIN ENERGÍA", Color("7dcce5"))
		_play_sound("error")
		return
	stamina = maxf(0.0, stamina - ATTACK_COST)
	stamina_regen_lock = STAMINA_REGEN_DELAY
	combat_state = "windup"
	combat_timer = ATTACK_WINDUP
	attack_hit_done = false
	_play_sound("attack")

func _update_combat(delta: float) -> void:
	if combat_state == "idle":
		return
	combat_timer -= delta
	if combat_timer > 0.0:
		return
	match combat_state:
		"windup":
			combat_state = "active"
			combat_timer = ATTACK_ACTIVE
			if not attack_hit_done:
				attack_hit_done = true
				_resolve_player_attack()
		"active":
			combat_state = "recovery"
			combat_timer = ATTACK_RECOVERY
		"recovery":
			combat_state = "idle"
			combat_timer = 0.0
			if attack_buffered:
				attack_buffered = false
				_start_attack()

func _resolve_player_attack() -> void:
	var best: Dictionary = {}
	var best_dist := 99999.0
	for key_variant in loaded_chunks.keys():
		var chunk: Dictionary = loaded_chunks[key_variant]
		for e_variant in chunk["enemies"]:
			var e: Dictionary = e_variant
			if not bool(e.get("alive", true)):
				continue
			var ep: Vector2 = e["pos"]
			var dv := ep - player_pos
			var d := dv.length()
			if d <= ATTACK_RANGE and d < best_dist and (d < 0.5 or facing.dot(dv.normalized()) >= ATTACK_DOT):
				best = e
				best_dist = d
	if best.is_empty():
		_spawn_floater(CENTER + facing * 34.0, "·", Color(0.9, 0.9, 0.8, 0.45))
		return
	var damage := 12.0
	best["hp"] = float(best["hp"]) - damage
	best["hit_flash"] = 0.16
	var dir := player_pos.direction_to(best["pos"])
	best["knockback"] = dir * 82.0
	screen_shake = 0.08
	_spawn_particles(best["pos"], Color("f3d37a"), 9)
	_spawn_floater(_world_to_screen(best["pos"]) + Vector2(0, -18), "-%d" % int(damage), Color("ffd76a"))
	_play_sound("hit")
	if float(best["hp"]) <= 0.0:
		_kill_enemy(best)

# -----------------------------------------------------------------------------
# IA: tres patrones distintos con telegraph/recovery e histéresis.
# -----------------------------------------------------------------------------
func _update_enemies(delta: float) -> void:
	var night_bonus := 1.12 if (day_clock > 0.72 or day_clock < 0.18) else 1.0
	for key_variant in loaded_chunks.keys():
		var chunk: Dictionary = loaded_chunks[key_variant]
		var enemies: Array = chunk["enemies"]
		for e_variant in enemies:
			var e: Dictionary = e_variant
			if not bool(e.get("alive", true)):
				continue
			e["hit_flash"] = maxf(0.0, float(e["hit_flash"]) - delta)
			var kb: Vector2 = e["knockback"]
			if kb.length() > 1.0:
				e["pos"] = _move_with_world_collisions(e["pos"], kb * delta, 8.0)
				e["knockback"] = kb.move_toward(Vector2.ZERO, 260.0 * delta)
			# El claro es un refugio real: enemigos no lo invaden.
			if player_pos.length() < SAFE_RADIUS and (e["pos"] as Vector2).length() > SAFE_RADIUS:
				_enemy_return_home(e, delta, night_bonus)
				continue
			match String(e["type"]):
				"lobo": _update_wolf(e, enemies, delta, night_bonus)
				"acechador": _update_stalker(e, enemies, delta, night_bonus)
				_: _update_raider(e, enemies, delta, night_bonus)

func _enemy_return_home(e: Dictionary, delta: float, speed_mul: float) -> void:
	e["state"] = "return"
	var ep: Vector2 = e["pos"]
	var home: Vector2 = e["home"]
	if ep.distance_to(home) < 12.0:
		e["state"] = "idle"
		return
	var dir := ep.direction_to(home)
	e["pos"] = _enemy_move(e, dir * 48.0 * speed_mul * delta, 8.0, [])

func _enemy_common_awareness(e: Dictionary, aggro: float, deaggro: float) -> bool:
	var ep: Vector2 = e["pos"]
	var d := ep.distance_to(player_pos)
	var alerted := bool(e.get("alerted", false))
	if not alerted and d <= aggro:
		e["alerted"] = true
		return true
	if alerted and d >= deaggro:
		e["alerted"] = false
		e["state"] = "return"
		return false
	return alerted

func _enemy_move(e: Dictionary, delta_move: Vector2, radius: float, peers: Array) -> Vector2:
	var sep := Vector2.ZERO
	var ep: Vector2 = e["pos"]
	for other_variant in peers:
		var other: Dictionary = other_variant
		if other == e or not bool(other.get("alive", true)):
			continue
		var op: Vector2 = other["pos"]
		var d := ep.distance_to(op)
		if d > 0.1 and d < 25.0:
			sep += op.direction_to(ep) * (25.0 - d) * 1.8
	var proposed := delta_move + sep * get_process_delta_time()
	return _move_with_world_collisions(ep, proposed, radius)

func _update_wolf(e: Dictionary, peers: Array, delta: float, speed_mul: float) -> void:
	var aware := _enemy_common_awareness(e, 225.0, 345.0)
	var state := String(e["state"])
	var ep: Vector2 = e["pos"]
	var d := ep.distance_to(player_pos)
	if not aware:
		_enemy_idle_patrol(e, peers, delta, 34.0)
		return
	e["state_timer"] = maxf(0.0, float(e["state_timer"]) - delta)
	match state:
		"idle", "patrol", "return":
			e["state"] = "circle"
			e["state_timer"] = 0.48
		"circle":
			var radial := ep.direction_to(player_pos)
			var side := Vector2(-radial.y, radial.x) * (1.0 if int(e["id"]) % 2 == 0 else -1.0)
			var dir := (radial * 0.34 + side * 0.94).normalized()
			e["pos"] = _enemy_move(e, dir * 72.0 * speed_mul * delta, 8.0, peers)
			if float(e["state_timer"]) <= 0.0 or d < 55.0:
				e["state"] = "windup"
				e["state_timer"] = 0.28
				e["attack_dir"] = ep.direction_to(player_pos)
				e["has_hit"] = false
				_play_sound("warn")
		"windup":
			if float(e["state_timer"]) <= 0.0:
				e["state"] = "charge"
				e["state_timer"] = 0.34
		"charge":
			var dir: Vector2 = e["attack_dir"]
			e["pos"] = _enemy_move(e, dir * 150.0 * speed_mul * delta, 8.0, peers)
			if not bool(e["has_hit"]) and (e["pos"] as Vector2).distance_to(player_pos) < 23.0:
				e["has_hit"] = true
				_damage_player(8.0, "El lobo embiste")
			if float(e["state_timer"]) <= 0.0:
				e["state"] = "recovery"
				e["state_timer"] = 0.68
		"recovery":
			if float(e["state_timer"]) <= 0.0:
				e["state"] = "circle"
				e["state_timer"] = 0.55

func _update_stalker(e: Dictionary, peers: Array, delta: float, speed_mul: float) -> void:
	var aware := _enemy_common_awareness(e, 235.0, 355.0)
	var state := String(e["state"])
	var ep: Vector2 = e["pos"]
	var d := ep.distance_to(player_pos)
	if not aware:
		_enemy_idle_patrol(e, peers, delta, 28.0)
		return
	e["state_timer"] = maxf(0.0, float(e["state_timer"]) - delta)
	match state:
		"idle", "patrol", "return":
			e["state"] = "stalk"
			e["state_timer"] = 0.8
		"stalk":
			var dir := Vector2.ZERO
			if d > 118.0:
				dir = ep.direction_to(player_pos)
			elif d < 82.0:
				dir = player_pos.direction_to(ep)
			else:
				var radial := ep.direction_to(player_pos)
				dir = Vector2(-radial.y, radial.x) * (1.0 if int(e["id"]) % 2 == 0 else -1.0)
			e["pos"] = _enemy_move(e, dir.normalized() * 60.0 * speed_mul * delta, 8.0, peers)
			if float(e["state_timer"]) <= 0.0 and d < 145.0:
				e["state"] = "windup"
				e["state_timer"] = 0.46
				e["attack_dir"] = ep.direction_to(player_pos)
				e["has_hit"] = false
				_play_sound("warn")
		"windup":
			# La dirección se corrige un poco al principio, pero queda bloqueada antes del salto.
			if float(e["state_timer"]) > 0.22:
				e["attack_dir"] = ep.direction_to(player_pos)
			if float(e["state_timer"]) <= 0.0:
				e["state"] = "pounce"
				e["state_timer"] = 0.23
		"pounce":
			var pdir: Vector2 = e["attack_dir"]
			e["pos"] = _enemy_move(e, pdir * 178.0 * speed_mul * delta, 8.0, peers)
			if not bool(e["has_hit"]) and (e["pos"] as Vector2).distance_to(player_pos) < 24.0:
				e["has_hit"] = true
				_damage_player(10.0, "El acechador salta")
			if float(e["state_timer"]) <= 0.0:
				e["state"] = "recovery"
				e["state_timer"] = 0.88
		"recovery":
			# Se retira durante la recuperación para crear un gap claro.
			var away := player_pos.direction_to(e["pos"])
			e["pos"] = _enemy_move(e, away * 38.0 * delta, 8.0, peers)
			if float(e["state_timer"]) <= 0.0:
				e["state"] = "stalk"
				e["state_timer"] = 0.75

func _update_raider(e: Dictionary, peers: Array, delta: float, speed_mul: float) -> void:
	var aware := _enemy_common_awareness(e, 215.0, 335.0)
	var state := String(e["state"])
	var ep: Vector2 = e["pos"]
	var d := ep.distance_to(player_pos)
	if not aware:
		_enemy_idle_patrol(e, peers, delta, 24.0)
		return
	e["state_timer"] = maxf(0.0, float(e["state_timer"]) - delta)
	match state:
		"idle", "patrol", "return":
			e["state"] = "chase"
		"chase":
			if d > 40.0:
				e["pos"] = _enemy_move(e, ep.direction_to(player_pos) * 58.0 * speed_mul * delta, 9.0, peers)
			else:
				e["state"] = "windup"
				e["state_timer"] = 0.66
				e["has_hit"] = false
				_play_sound("warn")
		"windup":
			if float(e["state_timer"]) <= 0.0:
				e["state"] = "strike"
				e["state_timer"] = 0.12
				if d < 52.0:
					e["has_hit"] = true
					_damage_player(13.0, "Golpe pesado del saqueador")
		"strike":
			if float(e["state_timer"]) <= 0.0:
				e["state"] = "recovery"
				e["state_timer"] = 0.96
		"recovery":
			if float(e["state_timer"]) <= 0.0:
				e["state"] = "chase"

func _enemy_idle_patrol(e: Dictionary, peers: Array, delta: float, speed: float) -> void:
	var ep: Vector2 = e["pos"]
	var home: Vector2 = e["home"]
	e["state_timer"] = maxf(0.0, float(e["state_timer"]) - delta)
	if ep.distance_to(home) > 75.0:
		e["pos"] = _enemy_move(e, ep.direction_to(home) * speed * delta, 8.0, peers)
		return
	if float(e["state_timer"]) <= 0.0:
		e["state_timer"] = 0.9 + fmod(float(e["id"]) * 0.37 + float(e["phase"]), 1.1)
		var a := float(e["phase"]) + anim_clock * 0.13
		e["attack_dir"] = Vector2(cos(a), sin(a))
	var dir: Vector2 = e.get("attack_dir", Vector2.ZERO)
	e["pos"] = _enemy_move(e, dir * speed * 0.35 * delta, 8.0, peers)

func _damage_player(damage: float, label: String) -> void:
	hp -= damage
	hurt_stagger = 0.10
	stamina_regen_lock = STAMINA_REGEN_DELAY
	screen_shake = 0.16
	_spawn_floater(CENTER + Vector2(0, -28), "-%d PV" % int(damage), Color("ff7272"))
	_spawn_particles(player_pos, Color("d95763"), 9)
	contextual_hint = label
	_play_sound("hurt")

func _kill_enemy(e: Dictionary) -> void:
	e["alive"] = false
	var mod := _chunk_state(String(e["chunk"]))
	var killed: Array = mod["killed_enemies"]
	var eid := int(e["id"])
	if not eid in killed:
		killed.append(eid)
	var kind := String(e["type"])
	if kind == "lobo":
		inventory["comida"] += 1
		_spawn_floater(_world_to_screen(e["pos"]) + Vector2(0, -18), "+1 comida", Color("9ee493"))
	elif kind == "acechador":
		inventory["fibra"] += 1
		_spawn_floater(_world_to_screen(e["pos"]) + Vector2(0, -18), "+1 fibra", Color("9ee493"))
	else:
		inventory["mineral"] += 1
		_spawn_floater(_world_to_screen(e["pos"]) + Vector2(0, -18), "+1 mineral", Color("9ee493"))
	_spawn_particles(e["pos"], Color("a85c65"), 18)
	_play_sound("kill")

# -----------------------------------------------------------------------------
# Recolección: acción comprometida, sin spam, costes de energía y herramientas.
# -----------------------------------------------------------------------------
func _interact() -> void:
	if menu_mode != "" or placement_type != "" or combat_state != "idle" or hurt_stagger > 0.0:
		return
	if harvest_timer > 0.0:
		return
	var chest := _nearest_chest(46.0)
	if chest >= 0:
		_open_chest(chest)
		return
	var target := _nearest_resource(48.0)
	if target.is_empty():
		_spawn_floater(INTERACT_CENTER + Vector2(-50, -34), "Nada cerca", Color(0.82, 0.84, 0.78, 0.72))
		return
	_start_harvest(target)

func _nearest_resource(max_dist: float) -> Dictionary:
	var best: Dictionary = {}
	var nearest := max_dist + 1.0
	for key_variant in loaded_chunks.keys():
		var chunk: Dictionary = loaded_chunks[key_variant]
		for r_variant in chunk["resources"]:
			var r: Dictionary = r_variant
			var rp: Vector2 = r["pos"]
			var d := rp.distance_to(player_pos)
			if d <= max_dist and d < nearest:
				best = r
				nearest = d
	return best

func _nearest_chest(max_dist: float) -> int:
	var best := -1
	var nearest := max_dist + 1.0
	for i in range(buildings.size()):
		var b: Dictionary = buildings[i]
		if String(b.get("type", "")) != "cofre":
			continue
		var d := (b["pos"] as Vector2).distance_to(player_pos)
		if d <= max_dist and d < nearest:
			nearest = d
			best = i
	return best

func _start_harvest(r: Dictionary) -> void:
	var kind := String(r["type"])
	var needed_tool := ""
	var duration := 0.30
	var cost := 2.0
	if kind == "arbol":
		needed_tool = "hacha"
		duration = 0.65
		cost = 5.0
	elif kind == "roca":
		needed_tool = "pico"
		duration = 0.75
		cost = 6.0
	elif kind == "mineral":
		needed_tool = "pico"
		duration = 0.82
		cost = 7.0
	elif kind == "rama":
		duration = 0.24
	elif kind == "fibra":
		duration = 0.30
	elif kind == "baya":
		duration = 0.30
	elif kind == "piedra_suelta":
		duration = 0.26
	if needed_tool != "" and equipped_tool != needed_tool:
		_spawn_floater(_world_to_screen(r["pos"]) + Vector2(0, -18), "Requiere %s" % needed_tool, Color("f0b36b"))
		_play_sound("error")
		return
	if stamina < cost:
		_spawn_floater(CENTER + Vector2(0, -28), "SIN ENERGÍA", Color("7dcce5"))
		_play_sound("error")
		return
	stamina = maxf(0.0, stamina - cost)
	stamina_regen_lock = STAMINA_REGEN_DELAY
	harvest_target = r
	harvest_duration = duration
	harvest_timer = duration
	harvest_cost = cost
	harvest_started_pos = player_pos
	harvest_kind = kind
	var rp: Vector2 = r["pos"]
	if rp.distance_to(player_pos) > 0.1:
		facing = _cardinal(player_pos.direction_to(rp))
	_play_sound("harvest")

func _update_harvest(delta: float) -> void:
	if harvest_timer <= 0.0:
		return
	if harvest_target.is_empty():
		harvest_timer = 0.0
		return
	var target_pos: Vector2 = harvest_target["pos"]
	if target_pos.distance_to(player_pos) > 48.0 or player_pos.distance_to(harvest_started_pos) > 20.0:
		_cancel_harvest("Interacción cancelada")
		return
	harvest_timer -= delta
	if harvest_timer <= 0.0:
		_finish_harvest()

func _cancel_harvest(text: String) -> void:
	harvest_timer = 0.0
	harvest_target = {}
	harvest_kind = ""
	if text != "":
		_spawn_floater(CENTER + Vector2(0, -26), text, Color(0.8, 0.82, 0.78, 0.72))

func _finish_harvest() -> void:
	if harvest_target.is_empty():
		return
	var r := harvest_target
	var kind := String(r["type"])
	var damage := 1.0
	if kind == "arbol" and equipped_tool == "hacha": damage = 1.0
	if (kind == "roca" or kind == "mineral") and equipped_tool == "pico": damage = 1.0
	r["hp"] = float(r["hp"]) - damage
	r["shake"] = 0.28
	var mod := _chunk_state(String(r["chunk"]))
	var hp_state: Dictionary = mod["resource_hp"]
	hp_state[str(int(r["id"]))] = maxf(0.0, float(r["hp"]))
	_spawn_particles(r["pos"], _resource_particle_color(kind), 8)
	if float(r["hp"]) <= 0.0:
		_collect_resource(r)
	else:
		_spawn_floater(_world_to_screen(r["pos"]) + Vector2(0, -20), "%d/%d" % [int(r["hp"]), int(r["max_hp"])], Color("e2bd72"))
	harvest_timer = 0.0
	harvest_target = {}
	harvest_kind = ""

func _collect_resource(r: Dictionary) -> void:
	var kind := String(r["type"])
	var amount := 1
	var inv_key := ""
	match kind:
		"arbol":
			amount = 3
			inv_key = "madera"
		"rama":
			amount = 1
			inv_key = "madera"
			tutorial_got_branch = true
		"roca":
			amount = 2
			inv_key = "piedra"
		"piedra_suelta":
			amount = 1
			inv_key = "piedra"
			tutorial_got_stone = true
		"fibra":
			amount = 1
			inv_key = "fibra"
		"baya":
			amount = 1
			inv_key = "comida"
		"mineral":
			amount = 1
			inv_key = "mineral"
	if inv_key != "":
		inventory[inv_key] = int(inventory.get(inv_key, 0)) + amount
	var mod := _chunk_state(String(r["chunk"]))
	var removed: Array = mod["removed_resources"]
	var rid := int(r["id"])
	if not rid in removed:
		removed.append(rid)
	var hp_state: Dictionary = mod["resource_hp"]
	hp_state.erase(str(rid))
	if loaded_chunks.has(String(r["chunk"])):
		var chunk: Dictionary = loaded_chunks[String(r["chunk"])]
		var resources: Array = chunk["resources"]
		resources.erase(r)
	_spawn_floater(_world_to_screen(r["pos"]) + Vector2(0, -17), "+%d %s" % [amount, _material_short(inv_key)], Color("9ee493"))
	_play_sound("collect")

func _resource_particle_color(kind: String) -> Color:
	if kind == "arbol" or kind == "rama": return Color("b27a4b")
	if kind == "roca" or kind == "piedra_suelta": return Color("9aa0a6")
	if kind == "mineral": return Color("6fd0d8")
	if kind == "baya": return Color("d94c79")
	return Color("79a65a")

# -----------------------------------------------------------------------------
# Inventario, equipamiento y crafting.
# -----------------------------------------------------------------------------
func _open_backpack(tab: String = "inventory") -> void:
	if placement_type != "":
		return
	menu_mode = "backpack"
	menu_tab = tab
	joystick_vec = Vector2.ZERO
	tutorial_opened_bag = true
	_play_sound("ui")

func _close_menu() -> void:
	menu_mode = ""
	chest_index = -1
	_play_sound("ui")

func _craft_item(kind: String) -> void:
	if not CRAFT_RECIPES.has(kind):
		return
	var recipe: Dictionary = CRAFT_RECIPES[kind]
	if bool(recipe.get("unique", false)) and bool(owned_tools.get(kind, false)):
		_spawn_floater(CENTER + Vector2(0, 82), "YA POSEES ESTE OBJETO", Color("dfb36d"))
		_play_sound("error")
		return
	var cost: Dictionary = recipe["cost"]
	if not _can_pay(cost):
		_spawn_floater(CENTER + Vector2(0, 82), "FALTAN MATERIALES", Color("ed7d78"))
		_play_sound("error")
		return
	_pay(cost)
	if kind == "hacha" or kind == "pico":
		owned_tools[kind] = true
		equipped_tool = kind
		if kind == "hacha":
			tutorial_crafted_axe = true
	else:
		inventory["venda"] = int(inventory["venda"]) + 1
	_set_major("Fabricado: %s" % String(recipe["name"]), 1.4)
	_play_sound("craft")

func _toggle_tool(kind: String) -> void:
	if not bool(owned_tools.get(kind, false)):
		return
	equipped_tool = "" if equipped_tool == kind else kind
	_spawn_floater(CENTER + Vector2(0, 82), "Equipado: %s" % ("manos" if equipped_tool == "" else equipped_tool), Color("b9d6a8"))
	_play_sound("ui")

func _eat() -> void:
	if int(inventory["comida"]) <= 0:
		_spawn_floater(CENTER + Vector2(0, 82), "Sin comida", Color("ed7d78"))
		return
	if hunger >= 99.0:
		_spawn_floater(CENTER + Vector2(0, 82), "No tienes hambre", Color("d6c58d"))
		return
	inventory["comida"] -= 1
	hunger = minf(100.0, hunger + 30.0)
	_spawn_floater(CENTER + Vector2(0, 82), "+30 hambre", Color("e6bb67"))
	_play_sound("collect")

func _use_bandage() -> void:
	if int(inventory["venda"]) <= 0:
		_spawn_floater(CENTER + Vector2(0, 82), "Sin vendajes", Color("ed7d78"))
		return
	if hp >= 99.0:
		_spawn_floater(CENTER + Vector2(0, 82), "PV completos", Color("d6c58d"))
		return
	inventory["venda"] -= 1
	hp = minf(100.0, hp + 28.0)
	_spawn_floater(CENTER + Vector2(0, 82), "+28 PV", Color("8ddd8d"))
	_play_sound("collect")

func _can_pay(cost: Dictionary) -> bool:
	for k_variant in cost.keys():
		var k := String(k_variant)
		if int(inventory.get(k, 0)) < int(cost[k]):
			return false
	return true

func _pay(cost: Dictionary) -> void:
	for k_variant in cost.keys():
		var k := String(k_variant)
		inventory[k] = int(inventory[k]) - int(cost[k])

# -----------------------------------------------------------------------------
# Construcción móvil: ghost independiente, drag, snap, rotación y confirmación.
# -----------------------------------------------------------------------------
func _select_build(kind: String) -> void:
	if not BUILD_RECIPES.has(kind):
		return
	var recipe: Dictionary = BUILD_RECIPES[kind]
	if not _can_pay(recipe["cost"]):
		_spawn_floater(CENTER + Vector2(0, 82), "FALTAN MATERIALES", Color("ed7d78"))
		_play_sound("error")
		return
	menu_mode = ""
	placement_type = kind
	placement_rotation = 0
	placement_pos = _snap_build_pos(player_pos + facing * 72.0)
	_set_major("Mueve el fantasma y confirma", 1.6)
	_play_sound("ui")

func _snap_build_pos(pos: Vector2) -> Vector2:
	return Vector2(round(pos.x / 16.0) * 16.0, round(pos.y / 16.0) * 16.0)

func _set_placement_from_screen(screen_pos: Vector2) -> void:
	var world := player_pos + (screen_pos - CENTER)
	var offset := world - player_pos
	if offset.length() > BUILD_RANGE:
		offset = offset.normalized() * BUILD_RANGE
	placement_pos = _snap_build_pos(player_pos + offset)

func _placement_valid(pos: Vector2) -> bool:
	if pos.distance_to(player_pos) < 34.0 or pos.distance_to(player_pos) > BUILD_RANGE + 2.0:
		return false
	var test_build := {"type": placement_type, "pos": pos, "rot": placement_rotation}
	# Evita solapar al jugador.
	if _building_blocks_circle(test_build, player_pos, PLAYER_RADIUS + 2.0):
		return false
	for b_variant in buildings:
		var b: Dictionary = b_variant
		if (b["pos"] as Vector2).distance_to(pos) < 52.0:
			return false
	for key_variant in loaded_chunks.keys():
		var chunk: Dictionary = loaded_chunks[key_variant]
		for r_variant in chunk["resources"]:
			var r: Dictionary = r_variant
			var rr := _resource_collision_radius(String(r["type"]))
			if rr > 0.0 and (r["pos"] as Vector2).distance_to(pos) < rr + 22.0:
				return false
	return true

func _place_build() -> void:
	if placement_type == "":
		return
	var recipe: Dictionary = BUILD_RECIPES[placement_type]
	var cost: Dictionary = recipe["cost"]
	if not _placement_valid(placement_pos):
		_spawn_floater(_world_to_screen(placement_pos) + Vector2(0, -22), "BLOQUEADO", Color("ef7777"))
		_play_sound("error")
		return
	if not _can_pay(cost):
		_spawn_floater(CENTER + Vector2(0, 82), "FALTAN MATERIALES", Color("ed7d78"))
		placement_type = ""
		return
	_pay(cost)
	var chest_store := {"madera": 0, "piedra": 0, "fibra": 0, "comida": 0, "mineral": 0, "venda": 0}
	buildings.append({"type": placement_type, "pos": placement_pos, "rot": placement_rotation, "chest": chest_store})
	_spawn_particles(placement_pos, Color("d7c39a"), 16)
	_set_major("Construido: %s" % String(recipe["name"]), 1.4)
	_play_sound("build")
	placement_type = ""
	placement_drag_touch = -1
	_save_game()

func _cancel_placement() -> void:
	placement_type = ""
	placement_drag_touch = -1
	placement_mouse_drag = false
	_play_sound("ui")

# -----------------------------------------------------------------------------
# Cofres: UI explícita para inventario <-> almacenamiento.
# -----------------------------------------------------------------------------
func _open_chest(index: int) -> void:
	if index < 0 or index >= buildings.size():
		return
	menu_mode = "chest"
	chest_index = index
	joystick_vec = Vector2.ZERO
	_play_sound("ui")

func _chest_transfer(item: String, to_chest: bool, all_items: bool = false) -> void:
	if chest_index < 0 or chest_index >= buildings.size():
		return
	var chest: Dictionary = buildings[chest_index]
	var store: Dictionary = chest["chest"]
	if to_chest:
		var have := int(inventory.get(item, 0))
		if have <= 0:
			return
		var amount := have if all_items else 1
		inventory[item] = have - amount
		store[item] = int(store.get(item, 0)) + amount
	else:
		var have := int(store.get(item, 0))
		if have <= 0:
			return
		var amount := have if all_items else 1
		store[item] = have - amount
		inventory[item] = int(inventory.get(item, 0)) + amount
	_play_sound("ui")

func _chest_transfer_all(to_chest: bool) -> void:
	for item_variant in MATERIAL_ORDER:
		var item := String(item_variant)
		_chest_transfer(item, to_chest, true)

# -----------------------------------------------------------------------------
# Input móvil/teclado: 3 botones permanentes + minimapa. Placement conserva joystick.
# -----------------------------------------------------------------------------
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE: _request_attack()
			KEY_E: _interact()
			KEY_I, KEY_TAB: _open_backpack("inventory")
			KEY_C: _open_backpack("craft")
			KEY_B: _open_backpack("build")
			KEY_M: _open_map()
			KEY_F: _eat()
			KEY_H: _use_bandage()
			KEY_ESCAPE:
				if placement_type != "": _cancel_placement()
				else: _close_menu()
			KEY_N: _new_world()
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_down(event.index, event.position)
		else:
			_touch_up(event.index)
	elif event is InputEventScreenDrag:
		if event.index == joystick_touch:
			_update_joystick(event.position)
		elif event.index == placement_drag_touch and placement_type != "":
			_set_placement_from_screen(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_mouse_down(event.position)
		else:
			mouse_joystick = false
			placement_mouse_drag = false
			joystick_vec = Vector2.ZERO
	elif event is InputEventMouseMotion:
		if mouse_joystick:
			_update_joystick(event.position)
		elif placement_mouse_drag and placement_type != "":
			_set_placement_from_screen(event.position)

func _touch_down(index: int, pos: Vector2) -> void:
	if menu_mode != "":
		_handle_menu_touch(pos)
		return
	if placement_type != "":
		if pos.distance_to(JOY_CENTER) <= JOY_RADIUS * 1.45:
			joystick_touch = index
			_update_joystick(pos)
			return
		if pos.distance_to(ATTACK_CENTER) < 38.0:
			_place_build()
			return
		if pos.distance_to(INTERACT_CENTER) < 38.0:
			placement_rotation = (placement_rotation + 1) % 4
			_play_sound("ui")
			return
		if pos.distance_to(BAG_CENTER) < 38.0:
			_cancel_placement()
			return
		placement_drag_touch = index
		_set_placement_from_screen(pos)
		return
	if MAP_RECT.has_point(pos):
		_open_map()
		return
	if pos.distance_to(JOY_CENTER) <= JOY_RADIUS * 1.45:
		joystick_touch = index
		_update_joystick(pos)
		return
	if pos.distance_to(ATTACK_CENTER) < 39.0:
		_request_attack()
	elif pos.distance_to(INTERACT_CENTER) < 39.0:
		_interact()
	elif pos.distance_to(BAG_CENTER) < 39.0:
		_open_backpack("inventory")

func _touch_up(index: int) -> void:
	if index == joystick_touch:
		joystick_touch = -1
		joystick_vec = Vector2.ZERO
	if index == placement_drag_touch:
		placement_drag_touch = -1

func _mouse_down(pos: Vector2) -> void:
	if menu_mode != "":
		_handle_menu_touch(pos)
		return
	if placement_type != "":
		if pos.distance_to(JOY_CENTER) <= JOY_RADIUS * 1.45:
			mouse_joystick = true
			_update_joystick(pos)
		elif pos.distance_to(ATTACK_CENTER) < 38.0:
			_place_build()
		elif pos.distance_to(INTERACT_CENTER) < 38.0:
			placement_rotation = (placement_rotation + 1) % 4
		elif pos.distance_to(BAG_CENTER) < 38.0:
			_cancel_placement()
		else:
			placement_mouse_drag = true
			_set_placement_from_screen(pos)
		return
	if MAP_RECT.has_point(pos):
		_open_map()
	elif pos.distance_to(JOY_CENTER) <= JOY_RADIUS * 1.45:
		mouse_joystick = true
		_update_joystick(pos)
	elif pos.distance_to(ATTACK_CENTER) < 39.0:
		_request_attack()
	elif pos.distance_to(INTERACT_CENTER) < 39.0:
		_interact()
	elif pos.distance_to(BAG_CENTER) < 39.0:
		_open_backpack("inventory")

func _update_joystick(pos: Vector2) -> void:
	var dv := pos - JOY_CENTER
	joystick_vec = dv / JOY_RADIUS
	if joystick_vec.length() > 1.0:
		joystick_vec = joystick_vec.normalized()

func _handle_menu_touch(pos: Vector2) -> void:
	if menu_mode == "map":
		if Rect2(552, 28, 38, 30).has_point(pos) or Rect2(0, 0, 640, 360).has_point(pos) and pos.y > 320:
			_close_menu()
		return
	if menu_mode == "chest":
		_handle_chest_touch(pos)
		return
	if menu_mode != "backpack":
		return
	if Rect2(548, 43, 36, 30).has_point(pos):
		_close_menu()
		return
	# Tabs
	if Rect2(96, 64, 142, 32).has_point(pos):
		menu_tab = "inventory"
		_play_sound("ui")
		return
	if Rect2(244, 64, 142, 32).has_point(pos):
		menu_tab = "craft"
		_play_sound("ui")
		return
	if Rect2(392, 64, 142, 32).has_point(pos):
		menu_tab = "build"
		_play_sound("ui")
		return
	if menu_tab == "inventory":
		_handle_inventory_touch(pos)
	elif menu_tab == "craft":
		_handle_craft_touch(pos)
	else:
		_handle_build_touch(pos)

func _handle_inventory_touch(pos: Vector2) -> void:
	# Comida y venda son acciones explícitas; herramientas se equipan/togglean.
	if Rect2(112, 210, 188, 42).has_point(pos):
		_eat()
		return
	if Rect2(326, 210, 188, 42).has_point(pos):
		_use_bandage()
		return
	if Rect2(112, 263, 188, 42).has_point(pos) and bool(owned_tools["hacha"]):
		_toggle_tool("hacha")
		return
	if Rect2(326, 263, 188, 42).has_point(pos) and bool(owned_tools["pico"]):
		_toggle_tool("pico")

func _handle_craft_touch(pos: Vector2) -> void:
	for i in range(CRAFT_ORDER.size()):
		var row := Rect2(112, 108 + i * 62, 412, 52)
		if row.has_point(pos):
			_craft_item(String(CRAFT_ORDER[i]))
			return

func _handle_build_touch(pos: Vector2) -> void:
	for i in range(BUILD_ORDER.size()):
		var row := Rect2(112, 108 + i * 62, 412, 52)
		if row.has_point(pos):
			_select_build(String(BUILD_ORDER[i]))
			return

func _handle_chest_touch(pos: Vector2) -> void:
	if Rect2(548, 43, 36, 30).has_point(pos):
		_close_menu()
		return
	if Rect2(112, 274, 176, 30).has_point(pos):
		_chest_transfer_all(true)
		return
	if Rect2(352, 274, 176, 30).has_point(pos):
		_chest_transfer_all(false)
		return
	for i in range(MATERIAL_ORDER.size()):
		var y := 92.0 + i * 29.0
		var item := String(MATERIAL_ORDER[i])
		if Rect2(276, y, 32, 24).has_point(pos):
			_chest_transfer(item, true, false)
			return
		if Rect2(332, y, 32, 24).has_point(pos):
			_chest_transfer(item, false, false)
			return

func _open_map() -> void:
	if placement_type != "":
		return
	menu_mode = "map"
	joystick_vec = Vector2.ZERO
	_play_sound("ui")

# -----------------------------------------------------------------------------
# Onboarding progresivo, pequeño y persistente.
# -----------------------------------------------------------------------------
func _update_tutorial() -> void:
	if tutorial_done:
		return
	match tutorial_step:
		0:
			if tutorial_moved: tutorial_step = 1
		1:
			if tutorial_got_branch: tutorial_step = 2
		2:
			if tutorial_got_stone: tutorial_step = 3
		3:
			if tutorial_opened_bag: tutorial_step = 4
		4:
			if tutorial_crafted_axe: tutorial_step = 5
		5:
			if player_pos.length() > SAFE_RADIUS + 25.0:
				tutorial_done = true
				_set_major("Tutorial completado. Sobrevive y explora.", 2.2)

func _tutorial_text() -> String:
	if tutorial_done:
		return ""
	match tutorial_step:
		0: return "Mueve el joystick para explorar el claro"
		1: return "Acércate a una rama y toca INTERACTUAR"
		2: return "Recoge una piedra suelta"
		3: return "Abre MOCHILA"
		4: return "En FABRICAR crea y equipa un Hacha"
		5: return "Sal del claro seguro para encontrar enemigos"
	return ""

func _update_context_hint() -> void:
	if menu_mode != "" or placement_type != "":
		contextual_hint = ""
		return
	var chest := _nearest_chest(46.0)
	if chest >= 0:
		contextual_hint = "ABRIR COFRE"
		return
	var r := _nearest_resource(48.0)
	if not r.is_empty():
		var kind := String(r["type"])
		if kind == "arbol": contextual_hint = "TALAR" if equipped_tool == "hacha" else "REQUIERE HACHA"
		elif kind == "roca" or kind == "mineral": contextual_hint = "PICAR" if equipped_tool == "pico" else "REQUIERE PICO"
		else: contextual_hint = "RECOGER"
		return
	contextual_hint = "INTERACTUAR"

func _set_major(text: String, seconds: float) -> void:
	major_message = text
	major_message_timer = seconds

func _world_to_screen(pos: Vector2) -> Vector2:
	var shake := Vector2.ZERO
	if screen_shake > 0.0:
		shake = Vector2(rng.randf_range(-2.0, 2.0), rng.randf_range(-2.0, 2.0)) * minf(1.0, screen_shake * 8.0)
	return pos - player_pos + CENTER + shake

func _screen_to_world(pos: Vector2) -> Vector2:
	return player_pos + (pos - CENTER)

func _draw() -> void:
	_draw_terrain()
	_draw_buildings()
	_draw_resources()
	_draw_enemies()
	_draw_player(CENTER)
	_draw_particles()
	_draw_weather()
	_draw_hud()
	if placement_type != "":
		_draw_placement_preview()
	if menu_mode != "":
		_draw_menu()
	_draw_floaters()

# -----------------------------------------------------------------------------
# Terreno y mundo
# -----------------------------------------------------------------------------
func _draw_terrain() -> void:
	var camera_tl := player_pos - CENTER
	var min_x := int(floor(camera_tl.x / TILE_SIZE)) - 1
	var min_y := int(floor(camera_tl.y / TILE_SIZE)) - 1
	var max_x := min_x + 23
	var max_y := min_y + 15
	for ty in range(min_y, max_y + 1):
		for tx in range(min_x, max_x + 1):
			var wp := Vector2(float(tx) * TILE_SIZE, float(ty) * TILE_SIZE)
			var sp := wp - camera_tl
			var center_wp := wp + Vector2(16, 16)
			var c := _terrain_color(center_wp)
			draw_rect(Rect2(sp, Vector2(TILE_SIZE + 1.0, TILE_SIZE + 1.0)), c)
			_draw_ground_detail(tx, ty, sp, _biome_at(center_wp))
	# Límite del claro solo como pista visual muy tenue.
	if player_pos.length() < SAFE_RADIUS + 380.0:
		var safe_center := _world_to_screen(Vector2.ZERO)
		draw_arc(safe_center, SAFE_RADIUS, 0, TAU, 96, Color(0.75, 0.83, 0.55, 0.16), 2.0)

func _tile_hash(x: int, y: int) -> int:
	return absi(world_seed ^ (x * 92837111) ^ (y * 689287499))

func _draw_ground_detail(tx: int, ty: int, sp: Vector2, biome: String) -> void:
	var h := _tile_hash(tx, ty)
	if h % 4 != 0:
		return
	var offset := Vector2(float(5 + (h % 17)), float(8 + ((h / 17) % 15)))
	if biome == "bosque":
		draw_line(sp + offset + Vector2(-2, 5), sp + offset + Vector2(0, -3), Color(0.32, 0.49, 0.34, 0.72), 1.4)
		draw_line(sp + offset + Vector2(3, 4), sp + offset + Vector2(4, -2), Color(0.28, 0.43, 0.31, 0.65), 1.3)
	elif biome == "pradera":
		draw_circle(sp + offset, 1.3, Color(0.82, 0.75, 0.36, 0.65))
		draw_line(sp + offset + Vector2(0, 3), sp + offset + Vector2(0, -2), Color(0.43, 0.57, 0.30, 0.68), 1.0)
	else:
		draw_line(sp + offset + Vector2(-5, 2), sp + offset + Vector2(1, -3), Color(0.47, 0.43, 0.44, 0.62), 1.0)
		draw_line(sp + offset + Vector2(1, -3), sp + offset + Vector2(5, 1), Color(0.47, 0.43, 0.44, 0.62), 1.0)

func _draw_resources() -> void:
	for key_variant in loaded_chunks.keys():
		var chunk: Dictionary = loaded_chunks[key_variant]
		for r_variant in chunk["resources"]:
			var r: Dictionary = r_variant
			var rp: Vector2 = r["pos"]
			if rp.distance_to(player_pos) > 450.0:
				continue
			var sp := _world_to_screen(rp)
			var shake := sin(anim_clock * 55.0) * 3.0 if float(r["shake"]) > 0.0 else 0.0
			sp.x += shake
			_draw_resource_sprite(String(r["type"]), sp)
			if float(r["hp"]) < float(r["max_hp"]):
				_draw_small_bar(sp + Vector2(-13, -28), 26.0, float(r["hp"]) / float(r["max_hp"]), Color("d99d54"))

func _draw_resource_sprite(kind: String, p: Vector2) -> void:
	match kind:
		"arbol":
			_draw_ellipse_px(p + Vector2(0, 13), Vector2(13, 4), Color(0.0, 0.0, 0.0, 0.20))
			draw_rect(Rect2(p + Vector2(-4, -4), Vector2(8, 24)), Color("74482f"))
			draw_rect(Rect2(p + Vector2(-16, -27), Vector2(32, 12)), Color("244c37"))
			draw_rect(Rect2(p + Vector2(-20, -18), Vector2(40, 13)), Color("2e6543"))
			draw_rect(Rect2(p + Vector2(-12, -34), Vector2(24, 10)), Color("3c7950"))
		"roca":
			_draw_ellipse_px(p + Vector2(0, 8), Vector2(15, 4), Color(0.0, 0.0, 0.0, 0.18))
			draw_colored_polygon(PackedVector2Array([p + Vector2(-16, 9), p + Vector2(-12, -8), p + Vector2(-3, -16), p + Vector2(12, -10), p + Vector2(17, 9)]), Color("7f898b"))
			draw_rect(Rect2(p + Vector2(-8, -10), Vector2(9, 4)), Color("adb4b4"))
		"piedra_suelta":
			draw_circle(p + Vector2(0, 2), 7.0, Color("8b9395"))
			draw_circle(p + Vector2(-2, 0), 3.0, Color("aeb4b4"))
		"rama":
			draw_line(p + Vector2(-13, 7), p + Vector2(13, -5), Color("9c6740"), 4.0)
			draw_line(p + Vector2(1, 1), p + Vector2(6, -8), Color("9c6740"), 2.0)
		"fibra":
			for x in [-9.0, -3.0, 3.0, 9.0]:
				draw_line(p + Vector2(x, 9), p + Vector2(x - 2, -11), Color("91ad5c"), 2.5)
		"baya":
			draw_circle(p, 13.0, Color("356743"))
			draw_circle(p + Vector2(-7, -5), 3.0, Color("d84f79"))
			draw_circle(p + Vector2(6, -3), 3.0, Color("e35d85"))
			draw_circle(p + Vector2(2, 6), 3.0, Color("ca426a"))
		"mineral":
			_draw_ellipse_px(p + Vector2(0, 8), Vector2(14, 4), Color(0.0, 0.0, 0.0, 0.18))
			draw_colored_polygon(PackedVector2Array([p + Vector2(-15, 10), p + Vector2(-10, -5), p + Vector2(0, -11), p + Vector2(15, 8)]), Color("596d72"))
			draw_colored_polygon(PackedVector2Array([p + Vector2(-5, 2), p + Vector2(-1, -18), p + Vector2(5, -4), p + Vector2(8, 6)]), Color("65d5df"))
			draw_colored_polygon(PackedVector2Array([p + Vector2(4, 6), p + Vector2(9, -12), p + Vector2(14, 7)]), Color("8cebed"))

func _draw_buildings() -> void:
	for b_variant in buildings:
		var b: Dictionary = b_variant
		var bp: Vector2 = b["pos"]
		if bp.distance_to(player_pos) > 455.0:
			continue
		_draw_building_sprite(String(b["type"]), _world_to_screen(bp), int(b.get("rot", 0)), false, true)

func _draw_building_sprite(kind: String, p: Vector2, rot: int, preview: bool, valid: bool) -> void:
	var alpha := 0.68 if preview else 1.0
	var tint := Color(0.50, 1.0, 0.55, alpha) if valid else Color(1.0, 0.35, 0.35, alpha)
	if kind == "fogata":
		var stone := Color("8d8c87") if not preview else tint
		for i in range(7):
			var a := TAU * float(i) / 7.0
			draw_circle(p + Vector2(cos(a), sin(a)) * 11.0, 4.0, stone)
		var flicker := sin(anim_clock * 12.0) * 2.0
		var fire_outer := Color(1.0, 0.48, 0.15, alpha) if not preview else tint
		var fire_inner := Color(1.0, 0.82, 0.28, alpha) if not preview else tint
		draw_colored_polygon(PackedVector2Array([p + Vector2(-7, 4), p + Vector2(0, -18 - flicker), p + Vector2(8, 4)]), fire_outer)
		draw_colored_polygon(PackedVector2Array([p + Vector2(-3, 4), p + Vector2(1, -10 - flicker), p + Vector2(4, 4)]), fire_inner)
	elif kind == "muro":
		var c := Color("8e653f") if not preview else tint
		var size := Vector2(46, 12) if rot % 2 == 0 else Vector2(12, 46)
		draw_rect(Rect2(p - size * 0.5, size), c)
		if rot % 2 == 0:
			for x in [-15.0, 0.0, 15.0]: draw_line(p + Vector2(x, -6), p + Vector2(x, 6), c.lightened(0.18), 2.0)
		else:
			for y in [-15.0, 0.0, 15.0]: draw_line(p + Vector2(-6, y), p + Vector2(6, y), c.lightened(0.18), 2.0)
	else:
		var c := Color("9d6c3e") if not preview else tint
		draw_rect(Rect2(p + Vector2(-16, -10), Vector2(32, 21)), c)
		draw_rect(Rect2(p + Vector2(-16, -11), Vector2(32, 6)), c.lightened(0.17))
		draw_rect(Rect2(p + Vector2(-2, -3), Vector2(4, 8)), Color("d5b35c") if not preview else tint)

# -----------------------------------------------------------------------------
# Enemigos y telegraphs
# -----------------------------------------------------------------------------
func _draw_enemies() -> void:
	for key_variant in loaded_chunks.keys():
		var chunk: Dictionary = loaded_chunks[key_variant]
		for e_variant in chunk["enemies"]:
			var e: Dictionary = e_variant
			if not bool(e.get("alive", true)):
				continue
			var ep: Vector2 = e["pos"]
			if ep.distance_to(player_pos) > 455.0:
				continue
			var sp := _world_to_screen(ep)
			_draw_enemy_telegraph(e, sp)
			_draw_enemy_sprite(e, sp)
			_draw_small_bar(sp + Vector2(-16, -28), 32.0, float(e["hp"]) / float(e["max_hp"]), Color("d85c62"))

func _draw_enemy_telegraph(e: Dictionary, p: Vector2) -> void:
	var state := String(e.get("state", "idle"))
	if state != "windup":
		return
	var kind := String(e["type"])
	var c := Color(1.0, 0.34, 0.25, 0.42)
	var radius := 28.0 if kind == "lobo" else (34.0 if kind == "acechador" else 42.0)
	draw_arc(p, radius, 0, TAU, 32, c, 3.0)
	var dir: Vector2 = e.get("attack_dir", p.direction_to(CENTER))
	if dir.length() > 0.1:
		draw_line(p, p + dir.normalized() * radius, Color(1.0, 0.78, 0.34, 0.72), 2.0)

func _draw_enemy_sprite(e: Dictionary, p: Vector2) -> void:
	var flash := float(e["hit_flash"]) > 0.0
	var phase := anim_clock * 7.0 + float(e["phase"])
	var bob := sin(phase) * 1.8
	var kind := String(e["type"])
	if kind == "lobo":
		var body := Color.WHITE if flash else Color("686d72")
		draw_rect(Rect2(p + Vector2(-15, -7 + bob), Vector2(23, 12)), body)
		draw_rect(Rect2(p + Vector2(7, -11 + bob), Vector2(11, 10)), body.lightened(0.07))
		draw_colored_polygon(PackedVector2Array([p + Vector2(8, -10 + bob), p + Vector2(11, -18 + bob), p + Vector2(14, -10 + bob)]), body)
		draw_line(p + Vector2(-14, -2 + bob), p + Vector2(-22, -10 + bob), body, 4.0)
		var step := 3.0 if sin(phase) > 0.0 else -3.0
		draw_line(p + Vector2(-9, 4 + bob), p + Vector2(-9 + step, 13), body.darkened(0.15), 3.5)
		draw_line(p + Vector2(5, 4 + bob), p + Vector2(5 - step, 13), body.darkened(0.15), 3.5)
		draw_circle(p + Vector2(14, -7 + bob), 1.6, Color("e6d66f"))
	elif kind == "acechador":
		var c := Color.WHITE if flash else Color("49365f")
		draw_circle(p + Vector2(0, -12 + bob), 8.0, c.lightened(0.12))
		draw_colored_polygon(PackedVector2Array([p + Vector2(-13, 15), p + Vector2(-9, -6 + bob), p + Vector2(9, -6 + bob), p + Vector2(14, 15)]), c)
		draw_circle(p + Vector2(-3, -13 + bob), 1.5, Color("c482e6"))
		draw_circle(p + Vector2(4, -13 + bob), 1.5, Color("c482e6"))
	else:
		var c := Color.WHITE if flash else Color("844b44")
		draw_rect(Rect2(p + Vector2(-8, -13 + bob), Vector2(16, 14)), Color("b08a6c") if not flash else Color.WHITE)
		draw_rect(Rect2(p + Vector2(-10, 1 + bob), Vector2(20, 18)), c)
		draw_rect(Rect2(p + Vector2(-13, -17 + bob), Vector2(26, 5)), Color("4f3b35"))
		draw_line(p + Vector2(10, 5 + bob), p + Vector2(21, -5 + bob), Color("d2d7d7"), 3.0)

# -----------------------------------------------------------------------------
# Jugador y animaciones
# -----------------------------------------------------------------------------
func _draw_player(p: Vector2) -> void:
	var bob := 0.0
	var step := 0.0
	if is_moving:
		bob = sin(anim_clock * (15.0 if is_sprinting else 10.0)) * 1.7
		step = 2.8 if sin(anim_clock * (15.0 if is_sprinting else 10.0)) > 0.0 else -2.8
	var body := Color("5f815f")
	if hurt_stagger > 0.0 and int(anim_clock * 26.0) % 2 == 0:
		body = Color.WHITE
	_draw_ellipse_px(p + Vector2(0, 15), Vector2(13, 4.5), Color(0.0, 0.0, 0.0, 0.28))
	draw_rect(Rect2(p + Vector2(-7 + step, 6 + bob), Vector2(5, 10)), Color("463a35"))
	draw_rect(Rect2(p + Vector2(2 - step, 6 + bob), Vector2(5, 10)), Color("463a35"))
	draw_rect(Rect2(p + Vector2(-10, -8 + bob), Vector2(20, 17)), body)
	draw_rect(Rect2(p + Vector2(-12, -4 + bob), Vector2(4, 14)), Color("405844"))
	draw_rect(Rect2(p + Vector2(-7, -20 + bob), Vector2(14, 12)), Color("c7a87f"))
	draw_rect(Rect2(p + Vector2(-8, -22 + bob), Vector2(16, 5)), Color("6a4b3a"))
	var eye := facing * 3.5
	draw_rect(Rect2(p + Vector2(-1, -15 + bob) + eye, Vector2(2, 2)), Color("2d2b2a"))
	if combat_state != "idle":
		_draw_attack_anim(p + Vector2(0, bob))
	elif harvest_timer > 0.0:
		_draw_harvest_anim(p + Vector2(0, bob))
	elif equipped_tool != "":
		_draw_equipped_tool(p + Vector2(0, bob), equipped_tool)

func _draw_attack_anim(p: Vector2) -> void:
	var base := facing.angle()
	var progress := 0.0
	if combat_state == "windup":
		progress = 0.10
	elif combat_state == "active":
		progress = 0.35 + (1.0 - combat_timer / ATTACK_ACTIVE) * 0.45
	else:
		progress = 0.88
	var angle := base + lerpf(-0.85, 0.85, clampf(progress, 0.0, 1.0))
	var hand := p + facing * 8.0
	var tip := hand + Vector2(cos(angle), sin(angle)) * 27.0
	draw_line(hand, tip, Color("e4e8e8"), 3.2)
	draw_line(hand, hand + Vector2(cos(angle), sin(angle)) * 9.0, Color("8d633e"), 4.2)
	if combat_state == "active":
		draw_arc(p, ATTACK_RANGE * 0.70, base - 0.70, base + 0.70, 14, Color(1.0, 0.91, 0.56, 0.40), 2.4)

func _draw_harvest_anim(p: Vector2) -> void:
	var progress := 1.0 - harvest_timer / maxf(harvest_duration, 0.01)
	var base := facing.angle()
	var angle := base + lerpf(-0.90, 0.68, progress)
	var hand := p + facing * 6.0
	var tip := hand + Vector2(cos(angle), sin(angle)) * 24.0
	var handle_color := Color("865d3c")
	draw_line(hand, tip, handle_color, 4.0)
	var head_dir := Vector2(cos(angle + PI * 0.5), sin(angle + PI * 0.5))
	if harvest_kind == "rama" or harvest_kind == "fibra" or harvest_kind == "baya" or harvest_kind == "piedra_suelta":
		draw_circle(tip, 4.0, Color("d2b188"))
	else:
		draw_line(tip - head_dir * 6.0, tip + head_dir * 6.0, Color("aeb6b7"), 4.0)

func _draw_equipped_tool(p: Vector2, kind: String) -> void:
	var side := Vector2(-facing.y, facing.x)
	var a := p + side * 9.0 + Vector2(0, 4)
	var b := a + facing * 13.0
	draw_line(a, b, Color("865d3c"), 3.0)
	var head_dir := Vector2(-facing.y, facing.x)
	var head_color := Color("b3bab9") if kind == "pico" else Color("9ea6a6")
	draw_line(b - head_dir * 5.0, b + head_dir * 5.0, head_color, 3.0)

func _draw_ellipse_px(center: Vector2, radius: Vector2, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(18):
		var a := TAU * float(i) / 18.0
		pts.append(center + Vector2(cos(a) * radius.x, sin(a) * radius.y))
	draw_colored_polygon(pts, color)

func _update_fx(delta: float) -> void:
	for key_variant in loaded_chunks.keys():
		var chunk: Dictionary = loaded_chunks[key_variant]
		for r_variant in chunk["resources"]:
			var r: Dictionary = r_variant
			r["shake"] = maxf(0.0, float(r["shake"]) - delta)
	for i in range(particles.size() - 1, -1, -1):
		var p: Dictionary = particles[i]
		p["life"] = float(p["life"]) - delta
		if float(p["life"]) <= 0.0:
			particles.remove_at(i)
			continue
		p["pos"] = (p["pos"] as Vector2) + (p["vel"] as Vector2) * delta
		p["vel"] = (p["vel"] as Vector2) * 0.92
	for i in range(floaters.size() - 1, -1, -1):
		var f: Dictionary = floaters[i]
		f["life"] = float(f["life"]) - delta
		f["pos"] = (f["pos"] as Vector2) + Vector2(0, -18.0 * delta)
		if float(f["life"]) <= 0.0:
			floaters.remove_at(i)

func _spawn_particles(world_pos: Vector2, color: Color, count: int) -> void:
	for i in range(count):
		particles.append({"pos": world_pos, "vel": Vector2(rng.randf_range(-55.0, 55.0), rng.randf_range(-65.0, 22.0)), "life": rng.randf_range(0.24, 0.52), "color": color, "size": rng.randf_range(2.0, 4.0)})

func _spawn_floater(screen_pos: Vector2, text: String, color: Color) -> void:
	floaters.append({"pos": screen_pos, "text": text, "color": color, "life": 0.84})

func _draw_particles() -> void:
	for p_variant in particles:
		var p: Dictionary = p_variant
		var sp := _world_to_screen(p["pos"])
		var life := clampf(float(p["life"]) / 0.52, 0.0, 1.0)
		var c: Color = p["color"]
		c.a = life
		draw_rect(Rect2(sp - Vector2.ONE * float(p["size"]) * 0.5, Vector2.ONE * float(p["size"])), c)

func _draw_floaters() -> void:
	var font := ThemeDB.fallback_font
	for f_variant in floaters:
		var f: Dictionary = f_variant
		var c: Color = f["color"]
		c.a = clampf(float(f["life"]) / 0.84, 0.0, 1.0)
		draw_string(font, f["pos"], String(f["text"]), HORIZONTAL_ALIGNMENT_CENTER, 100, 12, c)

func _draw_weather() -> void:
	var night := 0.0
	if day_clock > 0.68:
		night = smoothstep(0.68, 0.82, day_clock) * 0.46
	elif day_clock < 0.18:
		night = (1.0 - smoothstep(0.04, 0.18, day_clock)) * 0.46
	if night > 0.01:
		draw_rect(Rect2(Vector2.ZERO, SCREEN), Color(0.03, 0.06, 0.12, night))
	if weather == "niebla":
		draw_rect(Rect2(Vector2.ZERO, SCREEN), Color(0.72, 0.76, 0.75, 0.17))
	elif weather == "lluvia":
		for i in range(32):
			var x := fposmod(float(i * 73) + anim_clock * 145.0, 680.0) - 20.0
			var y := fposmod(float(i * 47) + anim_clock * 205.0, 400.0) - 20.0
			draw_line(Vector2(x, y), Vector2(x - 5, y + 13), Color(0.65, 0.82, 0.95, 0.46), 1.0)

# -----------------------------------------------------------------------------
# HUD móvil: legible, tres acciones, stamina funcional, hambre inequívoca y mapa.
# -----------------------------------------------------------------------------
func _draw_hud() -> void:
	var font := ThemeDB.fallback_font
	# Estado superior; deja el minimapa separado a la derecha.
	draw_rect(Rect2(7, 7, 542, 62), Color(0.025, 0.035, 0.032, 0.84))
	_draw_status_bar(Vector2(14, 13), 118.0, hp / 100.0, Color("df5e5e"), "vida")
	_draw_status_bar(Vector2(14, 31), 118.0, hunger / 100.0, Color("d8a64c"), "hambre")
	_draw_status_bar(Vector2(14, 49), 118.0, stamina / 100.0, Color("55b8d6"), "energia")
	var chips := ["madera", "piedra", "fibra", "mineral"]
	var x := 153.0
	for item_variant in chips:
		var item := String(item_variant)
		_draw_inventory_chip(Vector2(x, 15), item, int(inventory[item]))
		x += 65.0
	draw_string(font, Vector2(418, 26), "Día %d" % day_number, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("f0e8d5"))
	draw_string(font, Vector2(418, 43), "%s" % weather, HORIZONTAL_ALIGNMENT_LEFT, 120, 10, Color("c5d0c8"))
	draw_string(font, Vector2(418, 58), "%s · v0.3" % _biome_at(player_pos), HORIZONTAL_ALIGNMENT_LEFT, 125, 10, Color("9fb2a7"))

	_draw_minimap()

	# Joystick con aro externo de sprint: arrastrar hacia el borde activa carrera.
	draw_circle(JOY_CENTER, JOY_RADIUS + 8.0, Color(0.04, 0.055, 0.052, 0.22))
	draw_arc(JOY_CENTER, JOY_RADIUS + 8.0, 0, TAU, 48, Color(0.45, 0.72, 0.76, 0.30), 1.5)
	draw_circle(JOY_CENTER, JOY_RADIUS, Color(0.05, 0.07, 0.07, 0.38))
	draw_arc(JOY_CENTER, JOY_RADIUS, 0, TAU, 48, Color(0.82, 0.87, 0.82, 0.58), 2.0)
	var knob := JOY_CENTER + joystick_vec * 25.0
	draw_circle(knob, 18.0, Color(0.72, 0.80, 0.74, 0.76))
	if is_sprinting:
		draw_arc(JOY_CENTER, JOY_RADIUS + 5.0, -PI * 0.5, -PI * 0.5 + TAU * stamina / 100.0, 32, Color("5bc0dc"), 3.0)

	if placement_type == "":
		_draw_action_button(ATTACK_CENTER, "sword", "ATACAR")
		_draw_action_button(INTERACT_CENTER, "hand", contextual_hint)
		_draw_action_button(BAG_CENTER, "backpack", "MOCHILA")
	else:
		_draw_action_button(ATTACK_CENTER, "check", "COLOCAR")
		_draw_action_button(INTERACT_CENTER, "rotate", "ROTAR")
		_draw_action_button(BAG_CENTER, "cancel", "CANCELAR")

	var tut := _tutorial_text()
	if tut != "" and menu_mode == "":
		var tw := minf(390.0, 150.0 + float(tut.length()) * 5.6)
		draw_rect(Rect2(CENTER.x - tw * 0.5, 78, tw, 28), Color(0.03, 0.045, 0.04, 0.86))
		draw_rect(Rect2(CENTER.x - tw * 0.5, 78, tw, 28), Color("748b58"), false, 1.4)
		draw_string(font, Vector2(CENTER.x - tw * 0.5 + 10, 97), tut, HORIZONTAL_ALIGNMENT_CENTER, tw - 20.0, 11, Color("f1edd8"))

	if major_message_timer > 0.0 and menu_mode == "":
		var w := minf(390.0, 120.0 + float(major_message.length()) * 6.2)
		draw_rect(Rect2(CENTER.x - w * 0.5, 111, w, 28), Color(0.02, 0.025, 0.025, 0.88))
		draw_string(font, Vector2(CENTER.x - w * 0.5 + 10, 130), major_message, HORIZONTAL_ALIGNMENT_CENTER, w - 20.0, 11, Color.WHITE)

func _draw_status_bar(pos: Vector2, width: float, ratio: float, color: Color, kind: String) -> void:
	_draw_status_icon(pos + Vector2(6, 6), kind)
	draw_rect(Rect2(pos + Vector2(15, 1), Vector2(width, 10)), Color(0.075, 0.085, 0.082, 0.95))
	draw_rect(Rect2(pos + Vector2(15, 1), Vector2(width * clampf(ratio, 0.0, 1.0), 10)), color)
	var font := ThemeDB.fallback_font
	draw_string(font, pos + Vector2(20, 10), str(int(round(ratio * 100.0))), HORIZONTAL_ALIGNMENT_LEFT, 34, 8, Color(1,1,1,0.8))

func _draw_status_icon(p: Vector2, kind: String) -> void:
	if kind == "vida":
		draw_circle(p + Vector2(-2.4, -1.5), 3.2, Color("f1d0d0"))
		draw_circle(p + Vector2(2.4, -1.5), 3.2, Color("f1d0d0"))
		draw_colored_polygon(PackedVector2Array([p + Vector2(-5.3, 0), p + Vector2(5.3, 0), p + Vector2(0, 6)]), Color("f1d0d0"))
	elif kind == "hambre":
		# Muslo/carne: hueso claro + pieza anaranjada.
		draw_circle(p + Vector2(-2, 0), 4.8, Color("e8b05a"))
		draw_circle(p + Vector2(2, -2), 3.8, Color("e8b05a"))
		draw_line(p + Vector2(2, 3), p + Vector2(6, 7), Color("eee3c8"), 2.5)
		draw_circle(p + Vector2(7, 8), 2.0, Color("eee3c8"))
	else:
		draw_colored_polygon(PackedVector2Array([p + Vector2(2, -7), p + Vector2(-4, 1), p + Vector2(0, 1), p + Vector2(-2, 8), p + Vector2(6, -1), p + Vector2(2, -1)]), Color("bcebf4"))

func _draw_inventory_chip(pos: Vector2, kind: String, amount: int) -> void:
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(pos, Vector2(59, 42)), Color(0.09, 0.115, 0.105, 0.78))
	_draw_material_icon(pos + Vector2(13, 15), kind)
	draw_string(font, pos + Vector2(25, 18), str(amount), HORIZONTAL_ALIGNMENT_LEFT, 28, 12, Color.WHITE)
	draw_string(font, pos + Vector2(5, 35), _material_short(kind), HORIZONTAL_ALIGNMENT_CENTER, 49, 8, Color("b8c5ba"))

func _material_short(kind: String) -> String:
	match kind:
		"madera": return "MADERA"
		"piedra": return "PIEDRA"
		"fibra": return "FIBRA"
		"comida": return "COMIDA"
		"mineral": return "MINERAL"
		"venda": return "VENDA"
	return kind.to_upper()

func _draw_material_icon(p: Vector2, kind: String) -> void:
	match kind:
		"madera":
			draw_line(p + Vector2(-6, 4), p + Vector2(6, -4), Color("a56d43"), 4.0)
			draw_circle(p + Vector2(-5, 4), 2.0, Color("c28a5d"))
		"piedra":
			draw_colored_polygon(PackedVector2Array([p + Vector2(-7, 4), p + Vector2(-5, -4), p + Vector2(1, -7), p + Vector2(7, 3)]), Color("8e9698"))
		"fibra":
			draw_line(p + Vector2(-5, 6), p + Vector2(-2, -6), Color("86a559"), 2.0)
			draw_line(p + Vector2(2, 6), p + Vector2(5, -6), Color("86a559"), 2.0)
		"comida":
			draw_circle(p + Vector2(-1, -1), 5.0, Color("d67a4f"))
			draw_line(p + Vector2(2, 3), p + Vector2(7, 7), Color("eee3c8"), 2.0)
		"mineral":
			draw_colored_polygon(PackedVector2Array([p + Vector2(-6, 6), p + Vector2(0, -8), p + Vector2(6, 6)]), Color("72d1d8"))
		"venda":
			draw_rect(Rect2(p + Vector2(-7, -4), Vector2(14, 8)), Color("e7e0cf"))
			draw_rect(Rect2(p + Vector2(-2, -4), Vector2(4, 8)), Color("c76a6a"))

func _draw_action_button(center: Vector2, icon: String, label: String) -> void:
	var font := ThemeDB.fallback_font
	draw_circle(center, 32.0, Color(0.075, 0.095, 0.09, 0.78))
	draw_arc(center, 32.0, 0, TAU, 36, Color(0.84, 0.88, 0.84, 0.74), 2.0)
	match icon:
		"sword":
			draw_line(center + Vector2(-10, 10), center + Vector2(11, -11), Color("e0e4e4"), 4.5)
			draw_line(center + Vector2(-11, 5), center + Vector2(-4, 12), Color("a4784e"), 3.5)
		"hand":
			draw_circle(center + Vector2(0, 4), 8.0, Color("d6b58d"))
			for x in [-8.0, -3.0, 2.0, 7.0]: draw_line(center + Vector2(x, 3), center + Vector2(x - 1, -10), Color("d6b58d"), 3.3)
		"backpack":
			draw_rect(Rect2(center + Vector2(-11, -8), Vector2(22, 22)), Color("9c7448"))
			draw_rect(Rect2(center + Vector2(-8, -13), Vector2(16, 8)), Color("b28b5b"))
			draw_arc(center + Vector2(0, -7), 8.0, PI, TAU, 12, Color("dbc28a"), 2.4)
			draw_rect(Rect2(center + Vector2(-5, 2), Vector2(10, 7)), Color("765434"))
		"check":
			draw_line(center + Vector2(-12, 0), center + Vector2(-3, 10), Color("87dc82"), 4.0)
			draw_line(center + Vector2(-3, 10), center + Vector2(14, -11), Color("87dc82"), 4.0)
		"rotate":
			draw_arc(center, 13.0, -2.4, 2.2, 20, Color("a7d4e6"), 3.0)
			draw_colored_polygon(PackedVector2Array([center + Vector2(9, -9), center + Vector2(18, -8), center + Vector2(12, 1)]), Color("a7d4e6"))
		"cancel":
			draw_line(center + Vector2(-10, -10), center + Vector2(10, 10), Color("e77b7b"), 4.0)
			draw_line(center + Vector2(10, -10), center + Vector2(-10, 10), Color("e77b7b"), 4.0)
	var text := label
	if text.length() > 12:
		text = text.substr(0, 12)
	draw_rect(Rect2(center + Vector2(-37, 35), Vector2(74, 14)), Color(0.02, 0.03, 0.03, 0.74))
	draw_string(font, center + Vector2(-35, 46), text, HORIZONTAL_ALIGNMENT_CENTER, 70, 8, Color("e8ece8"))

# -----------------------------------------------------------------------------
# Minimapa / mapa explorado
# -----------------------------------------------------------------------------
func _draw_minimap() -> void:
	var rect := MAP_RECT
	draw_rect(rect, Color(0.025, 0.035, 0.035, 0.90))
	draw_rect(rect, Color("87978d"), false, 1.5)
	var cell := 12.0
	var cc := _chunk_coord(player_pos)
	for dy in range(-2, 3):
		for dx in range(-2, 3):
			var c := cc + Vector2i(dx, dy)
			var key := _chunk_key(c)
			var p := rect.position + Vector2(6 + float(dx + 2) * cell, 6 + float(dy + 2) * cell)
			var col := Color("202827")
			if explored_chunks.has(key):
				col = _map_biome_color(c)
			draw_rect(Rect2(p, Vector2(cell - 1, cell - 1)), col)
	# estructuras cercanas
	for b_variant in buildings:
		var b: Dictionary = b_variant
		var bc := _chunk_coord(b["pos"])
		var rel := bc - cc
		if abs(rel.x) <= 2 and abs(rel.y) <= 2:
			var bp := rect.position + Vector2(6 + float(rel.x + 2) * cell + 5, 6 + float(rel.y + 2) * cell + 5)
			draw_circle(bp, 1.8, _building_map_color(String(b["type"])))
	var player_dot := rect.position + Vector2(6 + 2.0 * cell + 5, 6 + 2.0 * cell + 5)
	draw_colored_polygon(PackedVector2Array([player_dot + Vector2(0,-5), player_dot + Vector2(-4,4), player_dot + Vector2(4,4)]), Color("f4df78"))

func _map_biome_color(coord: Vector2i) -> Color:
	var center := Vector2((float(coord.x) + 0.5) * CHUNK_SIZE, (float(coord.y) + 0.5) * CHUNK_SIZE)
	match _biome_at(center):
		"bosque": return Color("315b45")
		"pradera": return Color("72864f")
		_: return Color("6e6465")

func _building_map_color(kind: String) -> Color:
	if kind == "fogata": return Color("f2a248")
	if kind == "cofre": return Color("d6bb68")
	return Color("b99367")

# -----------------------------------------------------------------------------
# Menús: mochila con inventario/fabricar/construir, cofre y mapa completo.
# -----------------------------------------------------------------------------
func _draw_menu() -> void:
	if menu_mode == "backpack":
		_draw_backpack_menu()
	elif menu_mode == "chest":
		_draw_chest_menu()
	elif menu_mode == "map":
		_draw_full_map()

func _draw_panel(rect: Rect2, title: String) -> void:
	var font := ThemeDB.fallback_font
	draw_rect(rect, Color(0.025, 0.035, 0.032, 0.97))
	draw_rect(rect, Color("738177"), false, 2.0)
	draw_string(font, rect.position + Vector2(18, 28), title, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 80, 18, Color("f1ead5"))

func _draw_backpack_menu() -> void:
	var font := ThemeDB.fallback_font
	var panel := Rect2(80, 34, 480, 292)
	_draw_panel(panel, "MOCHILA")
	_draw_close_button(Vector2(548, 43))
	_draw_tab(Rect2(96, 64, 142, 32), "INVENTARIO", menu_tab == "inventory")
	_draw_tab(Rect2(244, 64, 142, 32), "FABRICAR", menu_tab == "craft")
	_draw_tab(Rect2(392, 64, 142, 32), "CONSTRUIR", menu_tab == "build")
	if menu_tab == "inventory":
		_draw_inventory_tab()
	elif menu_tab == "craft":
		_draw_craft_tab()
	else:
		_draw_build_tab()
	draw_string(font, Vector2(96, 316), "Espada oxidada equipada · Herramienta: %s" % ("manos" if equipped_tool == "" else equipped_tool.capitalize()), HORIZONTAL_ALIGNMENT_LEFT, 440, 9, Color("aeb8b0"))

func _draw_close_button(pos: Vector2) -> void:
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(pos, Vector2(36, 30)), Color("543b3b"))
	draw_string(font, pos + Vector2(10, 21), "×", HORIZONTAL_ALIGNMENT_LEFT, 18, 18, Color.WHITE)

func _draw_tab(rect: Rect2, label: String, selected: bool) -> void:
	var font := ThemeDB.fallback_font
	draw_rect(rect, Color("4e6651") if selected else Color("2e3933"))
	draw_rect(rect, Color("8aa084") if selected else Color("56635b"), false, 1.3)
	draw_string(font, rect.position + Vector2(4, 21), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 8, 10, Color("f0f0e8"))

func _draw_inventory_tab() -> void:
	var font := ThemeDB.fallback_font
	# Materiales en dos filas, con nombre explícito.
	var mats := ["madera", "piedra", "fibra", "mineral"]
	for i in range(mats.size()):
		var item := String(mats[i])
		var col := i % 2
		var row := i / 2
		var rect := Rect2(112 + col * 214, 108 + row * 48, 188, 40)
		_draw_inventory_row(rect, item, int(inventory[item]))
	# Comida / consumible con acción.
	_draw_action_inventory_row(Rect2(112, 210, 188, 42), "comida", int(inventory["comida"]), "COMER")
	_draw_action_inventory_row(Rect2(326, 210, 188, 42), "venda", int(inventory["venda"]), "USAR")
	# Equipo: arma fija + herramienta elegible.
	draw_string(font, Vector2(112, 260), "EQUIPAMIENTO", HORIZONTAL_ALIGNMENT_LEFT, 200, 10, Color("d7ddcf"))
	_draw_equipment_row(Rect2(112, 263, 188, 42), "hacha", bool(owned_tools["hacha"]), equipped_tool == "hacha")
	_draw_equipment_row(Rect2(326, 263, 188, 42), "pico", bool(owned_tools["pico"]), equipped_tool == "pico")
	_draw_weapon_badge(Rect2(112, 306, 402, 0))

func _draw_inventory_row(rect: Rect2, kind: String, amount: int) -> void:
	var font := ThemeDB.fallback_font
	draw_rect(rect, Color("121a17"))
	draw_rect(rect, Color("47564d"), false, 1.0)
	_draw_material_icon(rect.position + Vector2(18, 20), kind)
	draw_string(font, rect.position + Vector2(35, 17), _material_short(kind).capitalize(), HORIZONTAL_ALIGNMENT_LEFT, 100, 11, Color("eef0e7"))
	draw_string(font, rect.position + Vector2(150, 26), str(amount), HORIZONTAL_ALIGNMENT_CENTER, 30, 15, Color.WHITE)

func _draw_action_inventory_row(rect: Rect2, kind: String, amount: int, action: String) -> void:
	var font := ThemeDB.fallback_font
	draw_rect(rect, Color("182019"))
	draw_rect(rect, Color("61745c"), false, 1.3)
	_draw_material_icon(rect.position + Vector2(18, 21), kind)
	draw_string(font, rect.position + Vector2(35, 17), _material_short(kind).capitalize(), HORIZONTAL_ALIGNMENT_LEFT, 80, 11, Color("eef0e7"))
	draw_string(font, rect.position + Vector2(35, 33), "x%d" % amount, HORIZONTAL_ALIGNMENT_LEFT, 45, 10, Color("bdc8bd"))
	draw_rect(Rect2(rect.position + Vector2(116, 7), Vector2(62, 28)), Color("48684b") if amount > 0 else Color("3b403d"))
	draw_string(font, rect.position + Vector2(120, 26), action, HORIZONTAL_ALIGNMENT_CENTER, 54, 10, Color.WHITE)

func _draw_equipment_row(rect: Rect2, kind: String, owned: bool, equipped: bool) -> void:
	var font := ThemeDB.fallback_font
	draw_rect(rect, Color("182019") if owned else Color("111514"))
	draw_rect(rect, Color("6d8b67") if equipped else Color("465048"), false, 1.4)
	_draw_tool_icon(rect.position + Vector2(18, 21), kind)
	var name := "Hacha de piedra" if kind == "hacha" else "Pico de piedra"
	draw_string(font, rect.position + Vector2(36, 17), name, HORIZONTAL_ALIGNMENT_LEFT, 100, 10, Color("eef0e7") if owned else Color("747c78"))
	var state := "EQUIPADA" if equipped else ("EQUIPAR" if owned else "NO POSEES")
	draw_string(font, rect.position + Vector2(36, 33), state, HORIZONTAL_ALIGNMENT_LEFT, 125, 9, Color("9bd18e") if equipped else Color("aeb9b0"))

func _draw_weapon_badge(rect: Rect2) -> void:
	# El arma actual es fija en este pase; se muestra para que el jugador entienda qué lleva equipado.
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(330, 316), "ARMA: Espada oxidada [EQUIPADA]", HORIZONTAL_ALIGNMENT_LEFT, 210, 9, Color("cdd4cc"))

func _draw_tool_icon(p: Vector2, kind: String) -> void:
	draw_line(p + Vector2(-5, 7), p + Vector2(5, -7), Color("8a623f"), 3.0)
	if kind == "hacha":
		draw_colored_polygon(PackedVector2Array([p + Vector2(3,-8), p + Vector2(11,-8), p + Vector2(9,-1), p + Vector2(4,-2)]), Color("aab2b2"))
	else:
		draw_line(p + Vector2(-3,-8), p + Vector2(11,-4), Color("aab2b2"), 3.5)

func _draw_craft_tab() -> void:
	for i in range(CRAFT_ORDER.size()):
		var kind := String(CRAFT_ORDER[i])
		var recipe: Dictionary = CRAFT_RECIPES[kind]
		var rect := Rect2(112, 108 + i * 62, 412, 52)
		var already := bool(recipe.get("unique", false)) and bool(owned_tools.get(kind, false))
		var can := _can_pay(recipe["cost"]) and not already
		draw_rect(rect, Color("18211b"))
		draw_rect(rect, Color("668365") if can else Color("655050"), false, 1.5)
		_draw_tool_or_item_icon(rect.position + Vector2(20, 26), kind)
		var font := ThemeDB.fallback_font
		draw_string(font, rect.position + Vector2(42, 18), String(recipe["name"]), HORIZONTAL_ALIGNMENT_LEFT, 150, 12, Color.WHITE)
		draw_string(font, rect.position + Vector2(42, 36), String(recipe["desc"]), HORIZONTAL_ALIGNMENT_LEFT, 180, 9, Color("b8c2b9"))
		_draw_cost_line(rect.position + Vector2(224, 9), recipe["cost"])
		var text := "POSEÍDO" if already else "FABRICAR"
		draw_rect(Rect2(rect.position + Vector2(318, 12), Vector2(84, 29)), Color("46674b") if can else Color("454a47"))
		draw_string(font, rect.position + Vector2(322, 32), text, HORIZONTAL_ALIGNMENT_CENTER, 76, 9, Color.WHITE if can else Color("9ea59f"))

func _draw_build_tab() -> void:
	for i in range(BUILD_ORDER.size()):
		var kind := String(BUILD_ORDER[i])
		var recipe: Dictionary = BUILD_RECIPES[kind]
		var rect := Rect2(112, 108 + i * 62, 412, 52)
		var can := _can_pay(recipe["cost"])
		draw_rect(rect, Color("18211b"))
		draw_rect(rect, Color("668365") if can else Color("655050"), false, 1.5)
		_draw_building_sprite(kind, rect.position + Vector2(25, 27), 0, false, true)
		var font := ThemeDB.fallback_font
		draw_string(font, rect.position + Vector2(52, 18), String(recipe["name"]), HORIZONTAL_ALIGNMENT_LEFT, 145, 12, Color.WHITE)
		draw_string(font, rect.position + Vector2(52, 36), String(recipe["desc"]), HORIZONTAL_ALIGNMENT_LEFT, 170, 9, Color("b8c2b9"))
		_draw_cost_line(rect.position + Vector2(224, 9), recipe["cost"])
		draw_rect(Rect2(rect.position + Vector2(318, 12), Vector2(84, 29)), Color("46674b") if can else Color("454a47"))
		draw_string(font, rect.position + Vector2(322, 32), "COLOCAR", HORIZONTAL_ALIGNMENT_CENTER, 76, 9, Color.WHITE if can else Color("9ea59f"))

func _draw_tool_or_item_icon(p: Vector2, kind: String) -> void:
	if kind == "venda":
		_draw_material_icon(p, "venda")
	else:
		_draw_tool_icon(p, kind)

func _draw_cost_line(pos: Vector2, cost: Dictionary) -> void:
	var font := ThemeDB.fallback_font
	var y := 0.0
	for k_variant in cost.keys():
		var k := String(k_variant)
		var need := int(cost[k])
		var have := int(inventory.get(k, 0))
		var c := Color("9cdb8c") if have >= need else Color("ef7d78")
		draw_string(font, pos + Vector2(0, y + 10), "%s %d/%d" % [_material_short(k).substr(0, 3), have, need], HORIZONTAL_ALIGNMENT_LEFT, 88, 9, c)
		y += 13.0

func _draw_chest_menu() -> void:
	var panel := Rect2(80, 34, 480, 292)
	_draw_panel(panel, "COFRE")
	_draw_close_button(Vector2(548, 43))
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(112, 80), "TU INVENTARIO", HORIZONTAL_ALIGNMENT_LEFT, 150, 11, Color("dbe2d8"))
	draw_string(font, Vector2(382, 80), "COFRE", HORIZONTAL_ALIGNMENT_LEFT, 120, 11, Color("dbe2d8"))
	if chest_index < 0 or chest_index >= buildings.size():
		return
	var chest: Dictionary = buildings[chest_index]
	var store: Dictionary = chest["chest"]
	for i in range(MATERIAL_ORDER.size()):
		var item := String(MATERIAL_ORDER[i])
		var y := 92.0 + i * 29.0
		draw_rect(Rect2(112, y, 164, 24), Color("151d19"))
		_draw_material_icon(Vector2(126, y + 12), item)
		draw_string(font, Vector2(141, y + 17), "%s  %d" % [_material_short(item).capitalize(), int(inventory.get(item, 0))], HORIZONTAL_ALIGNMENT_LEFT, 125, 10, Color.WHITE)
		draw_rect(Rect2(276, y, 32, 24), Color("425f46"))
		draw_string(font, Vector2(281, y + 17), ">", HORIZONTAL_ALIGNMENT_CENTER, 22, 13, Color.WHITE)
		draw_rect(Rect2(332, y, 32, 24), Color("425f46"))
		draw_string(font, Vector2(337, y + 17), "<", HORIZONTAL_ALIGNMENT_CENTER, 22, 13, Color.WHITE)
		draw_rect(Rect2(364, y, 164, 24), Color("151d19"))
		draw_string(font, Vector2(376, y + 17), "%s  %d" % [_material_short(item).capitalize(), int(store.get(item, 0))], HORIZONTAL_ALIGNMENT_LEFT, 145, 10, Color.WHITE)
	draw_rect(Rect2(112, 274, 176, 30), Color("4b664e"))
	draw_string(font, Vector2(120, 294), "GUARDAR TODO", HORIZONTAL_ALIGNMENT_CENTER, 160, 10, Color.WHITE)
	draw_rect(Rect2(352, 274, 176, 30), Color("4b664e"))
	draw_string(font, Vector2(360, 294), "SACAR TODO", HORIZONTAL_ALIGNMENT_CENTER, 160, 10, Color.WHITE)

func _draw_full_map() -> void:
	var panel := Rect2(50, 26, 540, 308)
	_draw_panel(panel, "MAPA EXPLORADO")
	_draw_close_button(Vector2(552, 28))
	var font := ThemeDB.fallback_font
	if explored_chunks.is_empty():
		draw_string(font, Vector2(180, 180), "Aún no has explorado el mundo", HORIZONTAL_ALIGNMENT_CENTER, 280, 13, Color("d8ded8"))
		return
	var min_c := current_chunk
	var max_c := current_chunk
	for key_variant in explored_chunks.keys():
		var c := _parse_chunk_key(String(key_variant))
		min_c.x = mini(min_c.x, c.x)
		min_c.y = mini(min_c.y, c.y)
		max_c.x = maxi(max_c.x, c.x)
		max_c.y = maxi(max_c.y, c.y)
	# Añade un margen de un chunk desconocido para dar contexto.
	min_c -= Vector2i.ONE
	max_c += Vector2i.ONE
	var cols := max_c.x - min_c.x + 1
	var rows := max_c.y - min_c.y + 1
	var cell := minf(44.0, minf(450.0 / maxf(1.0, float(cols)), 220.0 / maxf(1.0, float(rows))))
	cell = maxf(5.0, cell)
	var map_size := Vector2(float(cols) * cell, float(rows) * cell)
	var origin := Vector2(320, 190) - map_size * 0.5
	for y in range(rows):
		for x in range(cols):
			var c := min_c + Vector2i(x, y)
			var key := _chunk_key(c)
			var rect := Rect2(origin + Vector2(float(x) * cell, float(y) * cell), Vector2(cell - 1.0, cell - 1.0))
			var col := Color("171d1c")
			if explored_chunks.has(key):
				col = _map_biome_color(c)
			draw_rect(rect, col)
	for b_variant in buildings:
		var b: Dictionary = b_variant
		var bc := _chunk_coord(b["pos"])
		if bc.x < min_c.x or bc.x > max_c.x or bc.y < min_c.y or bc.y > max_c.y:
			continue
		var rel := bc - min_c
		var bp := origin + Vector2((float(rel.x) + 0.5) * cell, (float(rel.y) + 0.5) * cell)
		draw_circle(bp, maxf(2.0, cell * 0.12), _building_map_color(String(b["type"])))
	var pr := current_chunk - min_c
	var pp := origin + Vector2((float(pr.x) + 0.5) * cell, (float(pr.y) + 0.5) * cell)
	draw_colored_polygon(PackedVector2Array([pp + Vector2(0,-6), pp + Vector2(-5,5), pp + Vector2(5,5)]), Color("f5df79"))
	draw_string(font, Vector2(78, 318), "▲ jugador   ● fogata   ■ cofre/muro   · toca × o abajo para cerrar", HORIZONTAL_ALIGNMENT_LEFT, 470, 9, Color("b7c1b9"))

func _draw_placement_preview() -> void:
	var valid := _placement_valid(placement_pos)
	_draw_building_sprite(placement_type, _world_to_screen(placement_pos), placement_rotation, true, valid)
	var font := ThemeDB.fallback_font
	var status := "UBICACIÓN VÁLIDA" if valid else "UBICACIÓN BLOQUEADA"
	var c := Color("8fd58a") if valid else Color("ee7777")
	draw_rect(Rect2(218, 78, 204, 25), Color(0.02, 0.03, 0.03, 0.83))
	draw_string(font, Vector2(224, 95), status, HORIZONTAL_ALIGNMENT_CENTER, 192, 10, c)
	draw_string(font, Vector2(205, 118), "Arrastra el fantasma · radio máximo 128 px", HORIZONTAL_ALIGNMENT_CENTER, 230, 9, Color("d9dfd8"))

func _draw_small_bar(pos: Vector2, width: float, ratio: float, color: Color) -> void:
	draw_rect(Rect2(pos, Vector2(width, 4)), Color(0.05, 0.05, 0.05, 0.84))
	draw_rect(Rect2(pos, Vector2(width * clampf(ratio, 0.0, 1.0), 4)), color)

# -----------------------------------------------------------------------------
# Audio procedural mínimo para feedback inmediato.
# -----------------------------------------------------------------------------
func _setup_audio() -> void:
	for i in range(4):
		var p := AudioStreamPlayer.new()
		add_child(p)
		sound_players.append(p)
	sounds = {
		"ui": _make_tone(520.0, 0.045, 0.12),
		"attack": _make_tone(210.0, 0.085, 0.15),
		"hit": _make_tone(145.0, 0.08, 0.19),
		"hurt": _make_tone(100.0, 0.13, 0.20),
		"harvest": _make_tone(300.0, 0.075, 0.14),
		"collect": _make_tone(680.0, 0.07, 0.12),
		"craft": _make_tone(760.0, 0.10, 0.14),
		"build": _make_tone(420.0, 0.12, 0.15),
		"kill": _make_tone(820.0, 0.13, 0.15),
		"weather": _make_tone(260.0, 0.10, 0.08),
		"error": _make_tone(120.0, 0.08, 0.15),
		"warn": _make_tone(390.0, 0.09, 0.11),
	}

func _make_tone(freq: float, duration: float, volume: float) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	var count := int(duration * 22050.0)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in range(count):
		var envelope := 1.0 - float(i) / float(maxi(1, count))
		var sample := int(sin(TAU * freq * float(i) / 22050.0) * 32767.0 * volume * envelope)
		var unsigned_sample := sample if sample >= 0 else sample + 65536
		data[i * 2] = unsigned_sample & 0xFF
		data[i * 2 + 1] = (unsigned_sample >> 8) & 0xFF
	wav.data = data
	return wav

func _play_sound(name: String) -> void:
	if not sounds.has(name) or sound_players.is_empty():
		return
	var p := sound_players[sound_cursor % sound_players.size()]
	sound_cursor += 1
	p.stream = sounds[name]
	p.play()

# -----------------------------------------------------------------------------
# Persistencia v0.3: mundo, chunks modificados, equipamiento, mapa, tutorial y cofres.
# -----------------------------------------------------------------------------
func _save_game() -> void:
	var building_data: Array = []
	for b_variant in buildings:
		var b: Dictionary = b_variant
		var pos: Vector2 = b["pos"]
		building_data.append({
			"type": b["type"],
			"pos": [pos.x, pos.y],
			"rot": int(b.get("rot", 0)),
			"chest": b.get("chest", {})
		})
	var explored: Array = []
	for key_variant in explored_chunks.keys():
		explored.append(String(key_variant))
	var data := {
		"version": 3,
		"seed": world_seed,
		"player": [player_pos.x, player_pos.y],
		"spawn": [spawn_pos.x, spawn_pos.y],
		"hp": hp,
		"hunger": hunger,
		"stamina": stamina,
		"day_clock": day_clock,
		"day_number": day_number,
		"weather": weather,
		"inventory": inventory,
		"owned_tools": owned_tools,
		"equipped_tool": equipped_tool,
		"equipped_weapon": equipped_weapon,
		"chunk_mods": chunk_mods,
		"buildings": building_data,
		"explored_chunks": explored,
		"tutorial": {
			"step": tutorial_step,
			"done": tutorial_done,
			"moved": tutorial_moved,
			"branch": tutorial_got_branch,
			"stone": tutorial_got_stone,
			"bag": tutorial_opened_bag,
			"axe": tutorial_crafted_axe,
		}
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data))
		file.close()

func _load_game() -> bool:
	var text := FileAccess.get_file_as_string(SAVE_PATH)
	var data_variant = JSON.parse_string(text)
	if data_variant == null or not data_variant is Dictionary:
		return false
	var data: Dictionary = data_variant
	if int(data.get("version", 0)) != 3:
		return false
	world_seed = int(data.get("seed", 0))
	if world_seed == 0:
		return false
	var pp: Array = data.get("player", [0.0, 0.0])
	player_pos = Vector2(float(pp[0]), float(pp[1]))
	var sp: Array = data.get("spawn", [0.0, 0.0])
	spawn_pos = Vector2(float(sp[0]), float(sp[1]))
	hp = float(data.get("hp", 100.0))
	hunger = float(data.get("hunger", 100.0))
	stamina = float(data.get("stamina", 100.0))
	day_clock = float(data.get("day_clock", 0.28))
	day_number = int(data.get("day_number", 1))
	weather = String(data.get("weather", "despejado"))
	var inv: Dictionary = data.get("inventory", {})
	for k_variant in inventory.keys():
		var k := String(k_variant)
		inventory[k] = int(inv.get(k, inventory[k]))
	var tools: Dictionary = data.get("owned_tools", {})
	owned_tools["hacha"] = bool(tools.get("hacha", false))
	owned_tools["pico"] = bool(tools.get("pico", false))
	equipped_tool = String(data.get("equipped_tool", ""))
	equipped_weapon = String(data.get("equipped_weapon", "espada_oxidada"))
	chunk_mods = data.get("chunk_mods", {})
	buildings.clear()
	for raw_variant in data.get("buildings", []):
		var raw: Dictionary = raw_variant
		var arr: Array = raw.get("pos", [0.0, 0.0])
		var store: Dictionary = raw.get("chest", {})
		for item_variant in MATERIAL_ORDER:
			var item := String(item_variant)
			if not store.has(item):
				store[item] = 0
		buildings.append({
			"type": raw.get("type", "fogata"),
			"pos": Vector2(float(arr[0]), float(arr[1])),
			"rot": int(raw.get("rot", 0)),
			"chest": store,
		})
	explored_chunks.clear()
	for key_variant in data.get("explored_chunks", []):
		explored_chunks[String(key_variant)] = true
	var tut: Dictionary = data.get("tutorial", {})
	tutorial_step = int(tut.get("step", 0))
	tutorial_done = bool(tut.get("done", false))
	tutorial_moved = bool(tut.get("moved", false))
	tutorial_got_branch = bool(tut.get("branch", false))
	tutorial_got_stone = bool(tut.get("stone", false))
	tutorial_opened_bag = bool(tut.get("bag", false))
	tutorial_crafted_axe = bool(tut.get("axe", false))
	combat_state = "idle"
	combat_timer = 0.0
	attack_buffered = false
	harvest_target = {}
	harvest_timer = 0.0
	menu_mode = ""
	placement_type = ""
	loaded_chunks.clear()
	current_chunk = Vector2i(999999, 999999)
	return true
