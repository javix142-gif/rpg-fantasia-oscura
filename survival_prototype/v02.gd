extends Node2D

const SCREEN := Vector2(640.0, 360.0)
const CENTER := Vector2(320.0, 180.0)
const TILE_SIZE := 32.0
const CHUNK_SIZE := 512.0
const ACTIVE_RADIUS := 2
const SAVE_PATH := "user://ceniza_salvaje_v02_save.json"
const JOY_CENTER := Vector2(88.0, 286.0)
const JOY_RADIUS := 48.0
const ATTACK_CENTER := Vector2(580.0, 300.0)
const INTERACT_CENTER := Vector2(510.0, 310.0)
const CRAFT_CENTER := Vector2(580.0, 230.0)
const BUILD_CENTER := Vector2(510.0, 240.0)

const CRAFT_ORDER := ["hacha", "pico", "venda"]
const BUILD_ORDER := ["fogata", "muro", "cofre"]
const WEATHER := ["despejado", "lluvia", "niebla"]

const CRAFT_RECIPES := {
	"hacha": {"name": "Hacha de piedra", "cost": {"madera": 5, "piedra": 3}, "desc": "Tala árboles más rápido"},
	"pico": {"name": "Pico de piedra", "cost": {"madera": 4, "piedra": 6}, "desc": "Extrae roca y mineral"},
	"venda": {"name": "Vendaje", "cost": {"fibra": 2}, "desc": "Recupera 28 PV"},
}
const BUILD_RECIPES := {
	"fogata": {"name": "Fogata", "cost": {"madera": 3, "piedra": 5}, "desc": "Luz y recuperación nocturna"},
	"muro": {"name": "Muro de madera", "cost": {"madera": 6}, "desc": "Cobertura básica"},
	"cofre": {"name": "Cofre", "cost": {"madera": 8}, "desc": "Almacenamiento local"},
}

var world_seed: int = 0
var biome_noise: FastNoiseLite
var detail_noise: FastNoiseLite
var rng := RandomNumberGenerator.new()
var player_pos := Vector2.ZERO
var facing := Vector2.DOWN
var hp := 100.0
var hunger := 100.0
var stamina := 100.0
var day_clock := 0.28
var day_number := 1
var weather := "despejado"
var weather_timer := 52.0
var save_timer := 15.0
var anim_clock := 0.0
var player_action := "idle"
var action_timer := 0.0
var action_duration := 0.0
var hurt_timer := 0.0
var is_moving := false
var message := ""
var message_timer := 0.0
var current_chunk := Vector2i(999999, 999999)
var loaded_chunks: Dictionary = {}
var chunk_mods: Dictionary = {}
var buildings: Array = []
var particles: Array = []
var floaters: Array = []
var screen_shake := 0.0
var joystick_touch := -1
var joystick_vec := Vector2.ZERO
var mouse_joystick := false
var menu_mode := ""
var placement_type := ""
var placement_rotation := 0
var sound_players: Array[AudioStreamPlayer] = []
var sounds: Dictionary = {}
var sound_cursor := 0

var inventory := {
	"madera": 0,
	"piedra": 0,
	"fibra": 0,
	"comida": 1,
	"mineral": 0,
	"hacha": 0,
	"pico": 0,
	"venda": 0,
}

func _ready() -> void:
	get_viewport().set_embedding_subwindows(false)
	_setup_audio()
	if FileAccess.file_exists(SAVE_PATH) and _load_game():
		_setup_noise()
		_refresh_chunks(true)
		_set_message("Partida v0.2 cargada", 2.0)
	else:
		_new_world()
	set_process(true)
	queue_redraw()

func _new_world() -> void:
	world_seed = absi(int(Time.get_unix_time_from_system() * 1000.0)) % 2147480000
	if world_seed == 0:
		world_seed = 142857
	player_pos = Vector2.ZERO
	facing = Vector2.DOWN
	hp = 100.0
	hunger = 100.0
	stamina = 100.0
	day_clock = 0.28
	day_number = 1
	weather = "despejado"
	inventory = {"madera": 0, "piedra": 0, "fibra": 0, "comida": 1, "mineral": 0, "hacha": 0, "pico": 0, "venda": 0}
	chunk_mods.clear()
	buildings.clear()
	loaded_chunks.clear()
	current_chunk = Vector2i(999999, 999999)
	_setup_noise()
	_refresh_chunks(true)
	_set_message("Nuevo mundo. Explora, fabrica y construye.", 4.0)
	_save_game()

func _setup_noise() -> void:
	biome_noise = FastNoiseLite.new()
	biome_noise.seed = world_seed
	biome_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	biome_noise.frequency = 0.0014
	detail_noise = FastNoiseLite.new()
	detail_noise.seed = world_seed ^ 0x5A17C9
	detail_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	detail_noise.frequency = 0.018
	rng.seed = world_seed

func _process(delta: float) -> void:
	anim_clock += delta
	action_timer = maxf(0.0, action_timer - delta)
	hurt_timer = maxf(0.0, hurt_timer - delta)
	message_timer = maxf(0.0, message_timer - delta)
	screen_shake = maxf(0.0, screen_shake - delta)
	weather_timer -= delta
	save_timer -= delta
	_update_time(delta)
	_update_movement(delta)
	_update_enemies(delta)
	_update_survival(delta)
	_update_fx(delta)
	if action_timer <= 0.0 and player_action != "idle":
		player_action = "walk" if is_moving else "idle"
	if weather_timer <= 0.0:
		weather_timer = 55.0 + rng.randf_range(-10.0, 18.0)
		weather = WEATHER[rng.randi_range(0, WEATHER.size() - 1)]
		_set_message("El tiempo cambia: %s" % weather, 2.2)
		_play_sound("weather")
	if save_timer <= 0.0:
		save_timer = 15.0
		_save_game()
	queue_redraw()

func _update_time(delta: float) -> void:
	var old_clock := day_clock
	day_clock += delta / 210.0
	if day_clock >= 1.0:
		day_clock -= 1.0
		day_number += 1
		_set_message("Día %d" % day_number, 1.8)
	if old_clock < 0.74 and day_clock >= 0.74:
		_set_message("Cae la noche", 2.0)

func _update_movement(delta: float) -> void:
	if menu_mode != "":
		is_moving = false
		joystick_vec = Vector2.ZERO
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
	if is_moving:
		facing = _cardinal(move)
		var speed := 108.0
		if Input.is_key_pressed(KEY_SHIFT) and stamina > 3.0:
			speed = 154.0
			stamina = maxf(0.0, stamina - delta * 15.0)
		else:
			stamina = minf(100.0, stamina + delta * 7.0)
		player_pos += move * speed * delta
		if action_timer <= 0.0:
			player_action = "walk"
	else:
		stamina = minf(100.0, stamina + delta * 10.0)
		if action_timer <= 0.0:
			player_action = "idle"
	_refresh_chunks(false)

func _cardinal(v: Vector2) -> Vector2:
	if absf(v.x) > absf(v.y):
		return Vector2.RIGHT if v.x > 0.0 else Vector2.LEFT
	return Vector2.DOWN if v.y > 0.0 else Vector2.UP

func _update_survival(delta: float) -> void:
	hunger = maxf(0.0, hunger - delta * 0.24)
	if hunger <= 0.0:
		hp -= delta * 1.8
	for b in buildings:
		if String(b.get("type", "")) == "fogata":
			var bp: Vector2 = b["pos"]
			if bp.distance_to(player_pos) < 76.0 and (day_clock > 0.72 or day_clock < 0.18):
				hp = minf(100.0, hp + delta * 0.7)
	if hp <= 0.0:
		_respawn()

func _respawn() -> void:
	hp = 65.0
	hunger = 55.0
	stamina = 100.0
	player_pos = Vector2.ZERO
	loaded_chunks.clear()
	current_chunk = Vector2i(999999, 999999)
	_refresh_chunks(true)
	_set_message("Has caído. Regresas al origen.", 3.0)
	_play_sound("hurt")

func _refresh_chunks(force: bool) -> void:
	var cc := _chunk_coord(player_pos)
	if not force and cc == current_chunk:
		return
	current_chunk = cc
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
	var count := 15 + local_rng.randi_range(0, 5)
	for i in range(count):
		if i in removed:
			continue
		var pos := origin + Vector2(local_rng.randf_range(20.0, CHUNK_SIZE - 20.0), local_rng.randf_range(20.0, CHUNK_SIZE - 20.0))
		var kind := _resource_kind(_biome_at(pos), local_rng.randf())
		var max_hp := _resource_max_hp(kind)
		var hp_key := str(i)
		var saved_hp := float(hp_state.get(hp_key, max_hp))
		resources.append({"id": i, "chunk": key, "type": kind, "pos": pos, "hp": saved_hp, "max_hp": max_hp, "shake": 0.0})
	if coord == Vector2i.ZERO:
		var forced := [
			[100, "rama", Vector2(54, 18)], [101, "rama", Vector2(-58, 22)],
			[102, "piedra", Vector2(38, -52)], [103, "piedra", Vector2(-44, -50)],
			[104, "fibra", Vector2(76, -28)], [105, "fibra", Vector2(-74, 52)],
			[106, "baya", Vector2(24, 76)], [107, "arbol", Vector2(-112, -20)]
		]
		for item in forced:
			var fid := int(item[0])
			if fid in removed:
				continue
			var kind := String(item[1])
			var max_hp := _resource_max_hp(kind)
			var hp_key := str(fid)
			resources.append({"id": fid, "chunk": key, "type": kind, "pos": item[2], "hp": float(hp_state.get(hp_key, max_hp)), "max_hp": max_hp, "shake": 0.0})
	var enemy_count := 1 + local_rng.randi_range(0, 1)
	for i in range(enemy_count):
		if i in killed:
			continue
		var ep := origin + Vector2(local_rng.randf_range(60.0, CHUNK_SIZE - 60.0), local_rng.randf_range(60.0, CHUNK_SIZE - 60.0))
		if coord == Vector2i.ZERO and ep.distance_to(Vector2.ZERO) < 260.0:
			ep += Vector2(280.0, 210.0)
		var types := ["lobo", "acechador", "saqueador"]
		var kind := types[local_rng.randi_range(0, types.size() - 1)]
		var max_hp := 34.0 if kind == "lobo" else (42.0 if kind == "acechador" else 50.0)
		enemies.append({"id": i, "chunk": key, "type": kind, "pos": ep, "hp": max_hp, "max_hp": max_hp, "alive": true, "cooldown": 0.0, "hit_flash": 0.0, "knockback": Vector2.ZERO, "phase": local_rng.randf_range(0.0, 10.0)})
	return {"coord": coord, "resources": resources, "enemies": enemies}

func _chunk_state(key: String) -> Dictionary:
	if not chunk_mods.has(key):
		chunk_mods[key] = {"removed_resources": [], "resource_hp": {}, "killed_enemies": []}
	return chunk_mods[key]

func _resource_kind(biome: String, roll: float) -> String:
	if biome == "bosque":
		if roll < 0.48: return "arbol"
		if roll < 0.66: return "fibra"
		if roll < 0.82: return "baya"
		if roll < 0.93: return "rama"
		return "piedra"
	if biome == "pradera":
		if roll < 0.31: return "fibra"
		if roll < 0.53: return "baya"
		if roll < 0.72: return "piedra"
		if roll < 0.88: return "rama"
		return "arbol"
	if roll < 0.38: return "piedra"
	if roll < 0.63: return "mineral"
	if roll < 0.82: return "rama"
	return "fibra"

func _resource_max_hp(kind: String) -> float:
	match kind:
		"arbol": return 4.0
		"piedra": return 3.0
		"mineral": return 4.0
		_: return 1.0

func _biome_value(pos: Vector2) -> float:
	return biome_noise.get_noise_2d(pos.x, pos.y)

func _biome_at(pos: Vector2) -> String:
	var n := _biome_value(pos)
	if n < -0.22: return "cenizal"
	if n < 0.27: return "pradera"
	return "bosque"

func _terrain_color(pos: Vector2) -> Color:
	var n := _biome_value(pos)
	var ash := Color("665d5d")
	var meadow := Color("64784a")
	var forest := Color("315a4b")
	var c := ash
	if n < -0.28:
		c = ash
	elif n < -0.14:
		c = ash.lerp(meadow, smoothstep(-0.28, -0.14, n))
	elif n < 0.20:
		c = meadow
	elif n < 0.34:
		c = meadow.lerp(forest, smoothstep(0.20, 0.34, n))
	else:
		c = forest
	var d := detail_noise.get_noise_2d(pos.x, pos.y) * 0.055
	return Color(clampf(c.r + d, 0.0, 1.0), clampf(c.g + d, 0.0, 1.0), clampf(c.b + d, 0.0, 1.0), 1.0)

func _update_enemies(delta: float) -> void:
	var night_bonus := 1.22 if (day_clock > 0.72 or day_clock < 0.18) else 1.0
	for key_variant in loaded_chunks.keys():
		var chunk: Dictionary = loaded_chunks[key_variant]
		var enemies: Array = chunk["enemies"]
		for e_variant in enemies:
			var e: Dictionary = e_variant
			if not bool(e.get("alive", true)):
				continue
			e["cooldown"] = maxf(0.0, float(e["cooldown"]) - delta)
			e["hit_flash"] = maxf(0.0, float(e["hit_flash"]) - delta)
			var kb: Vector2 = e["knockback"]
			if kb.length() > 1.0:
				e["pos"] = (e["pos"] as Vector2) + kb * delta
				e["knockback"] = kb.move_toward(Vector2.ZERO, 260.0 * delta)
			var ep: Vector2 = e["pos"]
			var distance := ep.distance_to(player_pos)
			if distance < 235.0:
				var dir := ep.direction_to(player_pos)
				var speed := 52.0 if e["type"] == "lobo" else (40.0 if e["type"] == "acechador" else 34.0)
				e["pos"] = ep + dir * speed * night_bonus * delta
				if distance < 25.0 and float(e["cooldown"]) <= 0.0:
					e["cooldown"] = 1.15
					var damage := 7.0 if e["type"] == "lobo" else (9.0 if e["type"] == "acechador" else 11.0)
					hp -= damage
					hurt_timer = 0.18
					screen_shake = 0.14
					_spawn_floater(CENTER + Vector2(0, -24), "-%d" % int(damage), Color("ff7373"))
					_spawn_particles(player_pos, Color("d95763"), 8)
					_set_message("%s te golpea" % String(e["type"]).capitalize(), 1.0)
					_play_sound("hurt")

func _attack() -> void:
	if menu_mode != "" or placement_type != "" or action_timer > 0.05:
		return
	player_action = "attack"
	action_duration = 0.34
	action_timer = action_duration
	_play_sound("attack")
	var best: Dictionary = {}
	var best_dist := 99999.0
	for key_variant in loaded_chunks.keys():
		var chunk: Dictionary = loaded_chunks[key_variant]
		for e_variant in chunk["enemies"]:
			var e: Dictionary = e_variant
			if not bool(e.get("alive", true)): continue
			var ep: Vector2 = e["pos"]
			var delta := ep - player_pos
			var d := delta.length()
			if d <= 64.0 and d < best_dist and (d < 1.0 or facing.dot(delta.normalized()) > -0.15):
				best = e
				best_dist = d
	if best.is_empty():
		_set_message("Atacas al aire", 0.8)
		return
	var damage := 13.0 + (3.0 if int(inventory["hacha"]) > 0 else 0.0)
	best["hp"] = float(best["hp"]) - damage
	best["hit_flash"] = 0.16
	var dir := player_pos.direction_to(best["pos"])
	best["knockback"] = dir * 110.0
	screen_shake = 0.09
	_spawn_particles(best["pos"], Color("f3d37a"), 10)
	_spawn_floater(_world_to_screen(best["pos"]) + Vector2(0, -18), "-%d" % int(damage), Color("ffd76a"))
	_play_sound("hit")
	if float(best["hp"]) <= 0.0:
		_kill_enemy(best)

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
	elif kind == "acechador":
		inventory["fibra"] += 2
	else:
		inventory["mineral"] += 1
	_spawn_particles(e["pos"], Color("a85c65"), 18)
	_set_message("Derrotaste a %s. Botín recogido." % kind, 1.6)
	_play_sound("kill")

func _interact() -> void:
	if menu_mode != "" or placement_type != "":
		return
	for b_variant in buildings:
		var b: Dictionary = b_variant
		if String(b.get("type", "")) == "cofre":
			var bp: Vector2 = b["pos"]
			if bp.distance_to(player_pos) < 48.0:
				_chest_exchange(b)
				return
	var target: Dictionary = {}
	var nearest := 99999.0
	for key_variant in loaded_chunks.keys():
		var chunk: Dictionary = loaded_chunks[key_variant]
		for r_variant in chunk["resources"]:
			var r: Dictionary = r_variant
			var rp: Vector2 = r["pos"]
			var d := rp.distance_to(player_pos)
			if d < 58.0 and d < nearest:
				nearest = d
				target = r
	if target.is_empty():
		_set_message("Acércate a un recurso o cofre", 1.2)
		return
	_harvest(target)

func _harvest(r: Dictionary) -> void:
	player_action = "harvest"
	action_duration = 0.42
	action_timer = action_duration
	var kind := String(r["type"])
	var damage := 1.0
	if kind == "arbol" and int(inventory["hacha"]) > 0: damage = 2.0
	if (kind == "piedra" or kind == "mineral") and int(inventory["pico"]) > 0: damage = 2.0
	r["hp"] = float(r["hp"]) - damage
	r["shake"] = 0.28
	var mod := _chunk_state(String(r["chunk"]))
	var hp_state: Dictionary = mod["resource_hp"]
	hp_state[str(int(r["id"]))] = maxf(0.0, float(r["hp"]))
	_spawn_particles(r["pos"], _resource_particle_color(kind), 8)
	_play_sound("harvest")
	if float(r["hp"]) <= 0.0:
		_collect_resource(r)
	else:
		_set_message("%s %d/%d" % [kind.capitalize(), int(r["hp"]), int(r["max_hp"])], 0.9)

func _collect_resource(r: Dictionary) -> void:
	var kind := String(r["type"])
	var amount := 1
	match kind:
		"arbol":
			amount = 5 if int(inventory["hacha"]) > 0 else 3
			inventory["madera"] += amount
		"rama":
			amount = 2
			inventory["madera"] += amount
		"piedra":
			amount = 4 if int(inventory["pico"]) > 0 else 2
			inventory["piedra"] += amount
		"fibra":
			amount = 2
			inventory["fibra"] += amount
		"baya":
			amount = 2
			inventory["comida"] += amount
		"mineral":
			amount = 3 if int(inventory["pico"]) > 0 else 1
			inventory["mineral"] += amount
	var mod := _chunk_state(String(r["chunk"]))
	var removed: Array = mod["removed_resources"]
	var rid := int(r["id"])
	if not rid in removed:
		removed.append(rid)
	var hp_state: Dictionary = mod["resource_hp"]
	hp_state.erase(str(rid))
	var chunk: Dictionary = loaded_chunks[String(r["chunk"])]
	var resources: Array = chunk["resources"]
	resources.erase(r)
	_spawn_floater(_world_to_screen(r["pos"]) + Vector2(0, -16), "+%d" % amount, Color("9ee493"))
	_set_message("Recolectado: %s x%d" % [kind, amount], 1.1)
	_play_sound("collect")

func _resource_particle_color(kind: String) -> Color:
	if kind == "arbol" or kind == "rama": return Color("b27a4b")
	if kind == "piedra": return Color("9aa0a6")
	if kind == "mineral": return Color("6fd0d8")
	if kind == "baya": return Color("d94c79")
	return Color("79a65a")

func _open_menu(mode: String) -> void:
	if placement_type != "": return
	menu_mode = "" if menu_mode == mode else mode
	joystick_vec = Vector2.ZERO
	_play_sound("ui")

func _craft_item(kind: String) -> void:
	var recipe: Dictionary = CRAFT_RECIPES[kind]
	var cost: Dictionary = recipe["cost"]
	if not _can_pay(cost):
		_set_message("Faltan materiales", 1.4)
		_play_sound("error")
		return
	_pay(cost)
	inventory[kind] += 1
	_set_message("Fabricado: %s" % String(recipe["name"]), 1.4)
	_play_sound("craft")

func _select_build(kind: String) -> void:
	var recipe: Dictionary = BUILD_RECIPES[kind]
	if not _can_pay(recipe["cost"]):
		_set_message("Faltan materiales para %s" % String(recipe["name"]), 1.4)
		_play_sound("error")
		return
	menu_mode = ""
	placement_type = kind
	placement_rotation = 0
	_set_message("Coloca la estructura: verde = válido", 2.0)

func _placement_pos() -> Vector2:
	var raw := player_pos + facing * 72.0
	return Vector2(round(raw.x / 16.0) * 16.0, round(raw.y / 16.0) * 16.0)

func _placement_valid(pos: Vector2) -> bool:
	if pos.distance_to(player_pos) < 42.0: return false
	for b_variant in buildings:
		var b: Dictionary = b_variant
		var bp: Vector2 = b["pos"]
		if bp.distance_to(pos) < 46.0: return false
	for key_variant in loaded_chunks.keys():
		var chunk: Dictionary = loaded_chunks[key_variant]
		for r_variant in chunk["resources"]:
			var r: Dictionary = r_variant
			var rp: Vector2 = r["pos"]
			if rp.distance_to(pos) < 32.0: return false
	return true

func _place_build() -> void:
	if placement_type == "": return
	var recipe: Dictionary = BUILD_RECIPES[placement_type]
	var cost: Dictionary = recipe["cost"]
	var pos := _placement_pos()
	if not _placement_valid(pos):
		_set_message("Ubicación bloqueada", 1.0)
		_play_sound("error")
		return
	if not _can_pay(cost):
		_set_message("Ya no tienes los materiales", 1.0)
		placement_type = ""
		return
	_pay(cost)
	buildings.append({"type": placement_type, "pos": pos, "rot": placement_rotation, "chest": {"madera": 0, "piedra": 0, "fibra": 0, "comida": 0, "mineral": 0}})
	_spawn_particles(pos, Color("d7c39a"), 16)
	_set_message("Construido: %s" % String(recipe["name"]), 1.4)
	_play_sound("build")
	placement_type = ""
	_save_game()

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

func _eat() -> void:
	if int(inventory["comida"]) <= 0:
		_set_message("No tienes comida", 1.0)
		return
	inventory["comida"] -= 1
	hunger = minf(100.0, hunger + 34.0)
	_play_sound("collect")

func _use_bandage() -> void:
	if int(inventory["venda"]) <= 0:
		_set_message("No tienes vendajes", 1.0)
		return
	inventory["venda"] -= 1
	hp = minf(100.0, hp + 28.0)
	_play_sound("collect")

func _chest_exchange(chest: Dictionary) -> void:
	var store: Dictionary = chest["chest"]
	if int(store.get("madera", 0)) > 0:
		store["madera"] -= 1
		inventory["madera"] += 1
		_set_message("Cofre: recuperas 1 madera", 1.2)
	elif int(inventory["madera"]) > 0:
		inventory["madera"] -= 1
		store["madera"] = int(store.get("madera", 0)) + 1
		_set_message("Cofre: guardas 1 madera", 1.2)
	else:
		_set_message("Cofre vacío", 1.0)
	_play_sound("ui")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_E: _interact()
			KEY_SPACE: _attack()
			KEY_C: _open_menu("craft")
			KEY_B: _open_menu("build")
			KEY_F: _eat()
			KEY_H: _use_bandage()
			KEY_ESCAPE:
				menu_mode = ""
				placement_type = ""
			KEY_N: _new_world()
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_down(event.index, event.position)
		else:
			_touch_up(event.index)
	elif event is InputEventScreenDrag and event.index == joystick_touch:
		_update_joystick(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed: _mouse_down(event.position)
		else:
			mouse_joystick = false
			joystick_vec = Vector2.ZERO
	elif event is InputEventMouseMotion and mouse_joystick:
		_update_joystick(event.position)

func _touch_down(index: int, pos: Vector2) -> void:
	if menu_mode != "":
		_handle_menu_touch(pos)
		return
	if placement_type != "":
		_handle_placement_touch(pos)
		return
	if pos.distance_to(JOY_CENTER) <= JOY_RADIUS * 1.45:
		joystick_touch = index
		_update_joystick(pos)
		return
	_handle_action_touch(pos)

func _touch_up(index: int) -> void:
	if index == joystick_touch:
		joystick_touch = -1
		joystick_vec = Vector2.ZERO

func _mouse_down(pos: Vector2) -> void:
	if menu_mode != "":
		_handle_menu_touch(pos)
	elif placement_type != "":
		_handle_placement_touch(pos)
	elif pos.distance_to(JOY_CENTER) <= JOY_RADIUS * 1.45:
		mouse_joystick = true
		_update_joystick(pos)
	else:
		_handle_action_touch(pos)

func _update_joystick(pos: Vector2) -> void:
	var delta := pos - JOY_CENTER
	joystick_vec = delta / JOY_RADIUS
	if joystick_vec.length() > 1.0:
		joystick_vec = joystick_vec.normalized()

func _handle_action_touch(pos: Vector2) -> void:
	if pos.distance_to(ATTACK_CENTER) < 38.0: _attack()
	elif pos.distance_to(INTERACT_CENTER) < 38.0: _interact()
	elif pos.distance_to(CRAFT_CENTER) < 38.0: _open_menu("craft")
	elif pos.distance_to(BUILD_CENTER) < 38.0: _open_menu("build")

func _handle_menu_touch(pos: Vector2) -> void:
	if Rect2(500, 48, 34, 30).has_point(pos):
		menu_mode = ""
		return
	var order: Array = CRAFT_ORDER if menu_mode == "craft" else BUILD_ORDER
	for i in range(order.size()):
		var row := Rect2(118, 92 + i * 68, 404, 58)
		if row.has_point(pos):
			var kind := String(order[i])
			if menu_mode == "craft": _craft_item(kind)
			else: _select_build(kind)
			return

func _handle_placement_touch(pos: Vector2) -> void:
	if pos.distance_to(ATTACK_CENTER) < 39.0:
		_place_build()
	elif pos.distance_to(INTERACT_CENTER) < 39.0:
		placement_rotation = (placement_rotation + 1) % 4
		_play_sound("ui")
	elif pos.distance_to(CRAFT_CENTER) < 39.0:
		placement_type = ""
		_play_sound("ui")

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
		f["pos"] = (f["pos"] as Vector2) + Vector2(0, -20.0 * delta)
		if float(f["life"]) <= 0.0:
			floaters.remove_at(i)

func _spawn_particles(world_pos: Vector2, color: Color, count: int) -> void:
	for i in range(count):
		particles.append({"pos": world_pos, "vel": Vector2(rng.randf_range(-55.0, 55.0), rng.randf_range(-65.0, 22.0)), "life": rng.randf_range(0.24, 0.52), "color": color, "size": rng.randf_range(2.0, 4.0)})

func _spawn_floater(screen_pos: Vector2, text: String, color: Color) -> void:
	floaters.append({"pos": screen_pos, "text": text, "color": color, "life": 0.72})

func _set_message(text: String, seconds: float) -> void:
	message = text
	message_timer = seconds

func _world_to_screen(pos: Vector2) -> Vector2:
	var shake := Vector2.ZERO
	if screen_shake > 0.0:
		shake = Vector2(rng.randf_range(-2.0, 2.0), rng.randf_range(-2.0, 2.0)) * minf(1.0, screen_shake * 8.0)
	return pos - player_pos + CENTER + shake

func _draw() -> void:
	_draw_terrain()
	_draw_buildings()
	_draw_resources()
	_draw_enemies()
	_draw_player(CENTER)
	_draw_particles()
	_draw_weather()
	_draw_hud()
	if placement_type != "": _draw_placement_preview()
	if menu_mode != "": _draw_menu()
	_draw_floaters()

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
			var c := _terrain_color(wp + Vector2(16, 16))
			draw_rect(Rect2(sp, Vector2(TILE_SIZE + 1.0, TILE_SIZE + 1.0)), c)
			_draw_ground_detail(tx, ty, sp, _biome_at(wp + Vector2(16, 16)))

func _tile_hash(x: int, y: int) -> int:
	return absi(world_seed ^ (x * 92837111) ^ (y * 689287499))

func _draw_ground_detail(tx: int, ty: int, sp: Vector2, biome: String) -> void:
	var h := _tile_hash(tx, ty)
	if h % 7 != 0: return
	if biome == "bosque":
		draw_line(sp + Vector2(8, 24), sp + Vector2(9, 18), Color("527d58"), 2.0)
		draw_line(sp + Vector2(12, 25), sp + Vector2(11, 19), Color("466c4d"), 2.0)
	elif biome == "pradera":
		draw_circle(sp + Vector2(13, 18), 1.5, Color("d6c76b"))
		draw_line(sp + Vector2(13, 21), sp + Vector2(13, 17), Color("789353"), 1.0)
	else:
		draw_line(sp + Vector2(7, 22), sp + Vector2(13, 17), Color("817777"), 1.0)
		draw_line(sp + Vector2(13, 17), sp + Vector2(17, 20), Color("817777"), 1.0)

func _draw_resources() -> void:
	for key_variant in loaded_chunks.keys():
		var chunk: Dictionary = loaded_chunks[key_variant]
		for r_variant in chunk["resources"]:
			var r: Dictionary = r_variant
			var rp: Vector2 = r["pos"]
			if rp.distance_to(player_pos) > 430.0: continue
			var sp := _world_to_screen(rp)
			var shake := sin(anim_clock * 55.0) * 3.0 if float(r["shake"]) > 0.0 else 0.0
			sp.x += shake
			_draw_resource_sprite(String(r["type"]), sp)
			if float(r["hp"]) < float(r["max_hp"]):
				_draw_small_bar(sp + Vector2(-11, -24), 22.0, float(r["hp"]) / float(r["max_hp"]), Color("d99d54"))

func _draw_resource_sprite(kind: String, p: Vector2) -> void:
	match kind:
		"arbol":
			draw_rect(Rect2(p + Vector2(-3, -3), Vector2(6, 20)), Color("70462e"))
			draw_rect(Rect2(p + Vector2(-13, -22), Vector2(26, 10)), Color("234b36"))
			draw_rect(Rect2(p + Vector2(-17, -14), Vector2(34, 11)), Color("2e6342"))
			draw_rect(Rect2(p + Vector2(-10, -28), Vector2(20, 8)), Color("39754c"))
		"piedra":
			draw_colored_polygon(PackedVector2Array([p + Vector2(-13, 7), p + Vector2(-10, -7), p + Vector2(-2, -13), p + Vector2(10, -8), p + Vector2(14, 7)]), Color("7e8789"))
			draw_rect(Rect2(p + Vector2(-7, -8), Vector2(7, 3)), Color("a9b0b0"))
		"rama":
			draw_line(p + Vector2(-11, 6), p + Vector2(11, -4), Color("9a653f"), 4.0)
			draw_line(p + Vector2(1, 1), p + Vector2(5, -7), Color("9a653f"), 2.0)
		"fibra":
			for x in [-7.0, -2.0, 3.0, 8.0]: draw_line(p + Vector2(x, 8), p + Vector2(x - 2, -9), Color("8eaa59"), 2.0)
		"baya":
			draw_circle(p, 11.0, Color("356342"))
			draw_circle(p + Vector2(-6, -4), 2.5, Color("d54f78"))
			draw_circle(p + Vector2(5, -2), 2.5, Color("e15b82"))
			draw_circle(p + Vector2(2, 5), 2.5, Color("c84269"))
		"mineral":
			draw_colored_polygon(PackedVector2Array([p + Vector2(-12, 8), p + Vector2(-8, -4), p + Vector2(0, -9), p + Vector2(12, 6)]), Color("596b70"))
			draw_colored_polygon(PackedVector2Array([p + Vector2(-4, 2), p + Vector2(-1, -16), p + Vector2(4, -3), p + Vector2(7, 5)]), Color("65d1da"))
			draw_colored_polygon(PackedVector2Array([p + Vector2(3, 5), p + Vector2(8, -10), p + Vector2(12, 6)]), Color("8ce8e8"))

func _draw_enemies() -> void:
	for key_variant in loaded_chunks.keys():
		var chunk: Dictionary = loaded_chunks[key_variant]
		for e_variant in chunk["enemies"]:
			var e: Dictionary = e_variant
			if not bool(e["alive"]): continue
			var ep: Vector2 = e["pos"]
			if ep.distance_to(player_pos) > 430.0: continue
			var sp := _world_to_screen(ep)
			_draw_enemy_sprite(e, sp)
			_draw_small_bar(sp + Vector2(-13, -22), 26.0, float(e["hp"]) / float(e["max_hp"]), Color("d85c62"))

func _draw_enemy_sprite(e: Dictionary, p: Vector2) -> void:
	var flash := float(e["hit_flash"]) > 0.0
	var phase := anim_clock * 7.0 + float(e["phase"])
	var bob := sin(phase) * 1.5
	var kind := String(e["type"])
	if kind == "lobo":
		var body := Color.WHITE if flash else Color("696d72")
		draw_rect(Rect2(p + Vector2(-12, -6 + bob), Vector2(19, 10)), body)
		draw_rect(Rect2(p + Vector2(6, -9 + bob), Vector2(9, 8)), body.lightened(0.07))
		draw_colored_polygon(PackedVector2Array([p + Vector2(7, -8 + bob), p + Vector2(9, -15 + bob), p + Vector2(12, -8 + bob)]), body)
		draw_line(p + Vector2(-12, -2 + bob), p + Vector2(-18, -8 + bob), body, 3.0)
		var step := 2.0 if sin(phase) > 0.0 else -2.0
		draw_line(p + Vector2(-7, 3 + bob), p + Vector2(-7 + step, 10), body.darkened(0.15), 3.0)
		draw_line(p + Vector2(5, 3 + bob), p + Vector2(5 - step, 10), body.darkened(0.15), 3.0)
		draw_circle(p + Vector2(12, -6 + bob), 1.3, Color("e6d66f"))
	elif kind == "acechador":
		var c := Color.WHITE if flash else Color("49365f")
		draw_circle(p + Vector2(0, -9 + bob), 6.0, c.lightened(0.12))
		draw_colored_polygon(PackedVector2Array([p + Vector2(-10, 12), p + Vector2(-7, -5 + bob), p + Vector2(7, -5 + bob), p + Vector2(11, 12)]), c)
		draw_circle(p + Vector2(-2, -10 + bob), 1.2, Color("b679d6"))
		draw_circle(p + Vector2(3, -10 + bob), 1.2, Color("b679d6"))
	else:
		var c := Color.WHITE if flash else Color("844b44")
		draw_rect(Rect2(p + Vector2(-6, -10 + bob), Vector2(12, 11)), Color("b08a6c") if not flash else Color.WHITE)
		draw_rect(Rect2(p + Vector2(-8, 1 + bob), Vector2(16, 14)), c)
		draw_rect(Rect2(p + Vector2(-11, -13 + bob), Vector2(22, 4)), Color("4f3b35"))
		draw_line(p + Vector2(8, 4 + bob), p + Vector2(16, -3 + bob), Color("d2d7d7"), 2.0)

func _draw_player(p: Vector2) -> void:
	var bob := 0.0
	var step := 0.0
	if is_moving:
		bob = sin(anim_clock * 12.0) * 1.5
		step = 2.0 if sin(anim_clock * 12.0) > 0.0 else -2.0
	var body := Color("5f7f5e")
	if hurt_timer > 0.0 and int(anim_clock * 25.0) % 2 == 0:
		body = Color.WHITE
	# sombra
	draw_ellipse(p + Vector2(0, 13), Vector2(11, 4), Color(0.0, 0.0, 0.0, 0.26))
	# piernas
	draw_rect(Rect2(p + Vector2(-6 + step, 6 + bob), Vector2(4, 8)), Color("463a35"))
	draw_rect(Rect2(p + Vector2(2 - step, 6 + bob), Vector2(4, 8)), Color("463a35"))
	# torso y capa
	draw_rect(Rect2(p + Vector2(-8, -7 + bob), Vector2(16, 15)), body)
	draw_rect(Rect2(p + Vector2(-10, -3 + bob), Vector2(3, 12)), Color("405844"))
	# cabeza
	draw_rect(Rect2(p + Vector2(-6, -17 + bob), Vector2(12, 10)), Color("c6a77e"))
	draw_rect(Rect2(p + Vector2(-7, -19 + bob), Vector2(14, 4)), Color("6a4b3a"))
	# indicador de dirección facial
	var eye := facing * 3.0
	draw_rect(Rect2(p + Vector2(-1, -13 + bob) + eye, Vector2(2, 2)), Color("2d2b2a"))
	if player_action == "attack": _draw_attack_anim(p + Vector2(0, bob))
	elif player_action == "harvest": _draw_harvest_anim(p + Vector2(0, bob))

func draw_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(16):
		var a := TAU * float(i) / 16.0
		pts.append(center + Vector2(cos(a) * radius.x, sin(a) * radius.y))
	draw_colored_polygon(pts, color)

func _draw_attack_anim(p: Vector2) -> void:
	var progress := 1.0 - action_timer / maxf(action_duration, 0.01)
	var base := facing.angle()
	var angle := base + lerpf(-1.05, 1.05, progress)
	var hand := p + facing * 7.0
	var tip := hand + Vector2(cos(angle), sin(angle)) * 24.0
	draw_line(hand, tip, Color("e2e6e6"), 3.0)
	draw_line(hand, hand + Vector2(cos(angle), sin(angle)) * 8.0, Color("8d633e"), 4.0)
	draw_arc(p, 26.0, base - 1.05, base + 1.05, 12, Color(1.0, 0.9, 0.55, 0.42), 2.0)

func _draw_harvest_anim(p: Vector2) -> void:
	var progress := 1.0 - action_timer / maxf(action_duration, 0.01)
	var base := facing.angle()
	var angle := base + lerpf(-0.85, 0.65, progress)
	var hand := p + facing * 5.0
	var tip := hand + Vector2(cos(angle), sin(angle)) * 22.0
	draw_line(hand, tip, Color("855b3c"), 4.0)
	var head_dir := Vector2(cos(angle + PI * 0.5), sin(angle + PI * 0.5))
	draw_line(tip - head_dir * 5.0, tip + head_dir * 5.0, Color("aeb6b7"), 4.0)

func _draw_buildings() -> void:
	for b_variant in buildings:
		var b: Dictionary = b_variant
		var bp: Vector2 = b["pos"]
		if bp.distance_to(player_pos) > 440.0: continue
		_draw_building_sprite(String(b["type"]), _world_to_screen(bp), int(b.get("rot", 0)), false, true)

func _draw_building_sprite(kind: String, p: Vector2, rot: int, preview: bool, valid: bool) -> void:
	var alpha := 0.62 if preview else 1.0
	var tint := Color(0.55, 1.0, 0.58, alpha) if valid else Color(1.0, 0.35, 0.35, alpha)
	if kind == "fogata":
		var stone := Color("8c8b86") if not preview else tint
		for i in range(6):
			var a := TAU * float(i) / 6.0
			draw_circle(p + Vector2(cos(a), sin(a)) * 10.0, 4.0, stone)
		var flicker := sin(anim_clock * 12.0) * 2.0
		draw_colored_polygon(PackedVector2Array([p + Vector2(-6, 3), p + Vector2(0, -16 - flicker), p + Vector2(7, 3)]), Color(1.0, 0.48, 0.15, alpha))
		draw_colored_polygon(PackedVector2Array([p + Vector2(-3, 3), p + Vector2(1, -9 - flicker), p + Vector2(4, 3)]), Color(1.0, 0.82, 0.28, alpha))
	elif kind == "muro":
		var c := Color("8b633f") if not preview else tint
		var size := Vector2(42, 12) if rot % 2 == 0 else Vector2(12, 42)
		draw_rect(Rect2(p - size * 0.5, size), c)
		if rot % 2 == 0:
			for x in [-14.0, 0.0, 14.0]: draw_line(p + Vector2(x, -6), p + Vector2(x, 6), c.lightened(0.18), 2.0)
		else:
			for y in [-14.0, 0.0, 14.0]: draw_line(p + Vector2(-6, y), p + Vector2(6, y), c.lightened(0.18), 2.0)
	else:
		var c := Color("9b6b3e") if not preview else tint
		draw_rect(Rect2(p + Vector2(-14, -9), Vector2(28, 19)), c)
		draw_rect(Rect2(p + Vector2(-14, -10), Vector2(28, 5)), c.lightened(0.18))
		draw_rect(Rect2(p + Vector2(-2, -3), Vector2(4, 7)), Color("d0b15b") if not preview else tint)

func _draw_placement_preview() -> void:
	var pos := _placement_pos()
	var valid := _placement_valid(pos)
	_draw_building_sprite(placement_type, _world_to_screen(pos), placement_rotation, true, valid)
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(420, 332, 214, 24), Color(0.03, 0.04, 0.04, 0.82))
	draw_string(font, Vector2(428, 349), "✓ colocar   ↻ rotar   ✕ cancelar", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	_draw_action_button(ATTACK_CENTER, "check")
	_draw_action_button(INTERACT_CENTER, "rotate")
	_draw_action_button(CRAFT_CENTER, "cancel")

func _draw_particles() -> void:
	for p_variant in particles:
		var p: Dictionary = p_variant
		var sp := _world_to_screen(p["pos"])
		var life := clampf(float(p["life"]) / 0.52, 0.0, 1.0)
		var c: Color = p["color"]
		c.a = life
		draw_rect(Rect2(sp - Vector2.ONE * float(p["size"]) * 0.5, Vector2.ONE * float(p["size"])), c)

func _draw_weather() -> void:
	var night := 0.0
	if day_clock > 0.68:
		night = smoothstep(0.68, 0.82, day_clock) * 0.46
	elif day_clock < 0.18:
		night = (1.0 - smoothstep(0.04, 0.18, day_clock)) * 0.46
	if night > 0.01:
		draw_rect(Rect2(Vector2.ZERO, SCREEN), Color(0.03, 0.06, 0.12, night))
	if weather == "niebla":
		draw_rect(Rect2(Vector2.ZERO, SCREEN), Color(0.72, 0.76, 0.75, 0.18))
	elif weather == "lluvia":
		for i in range(32):
			var x := fposmod(float(i * 73) + anim_clock * 145.0, 680.0) - 20.0
			var y := fposmod(float(i * 47) + anim_clock * 205.0, 400.0) - 20.0
			draw_line(Vector2(x, y), Vector2(x - 5, y + 13), Color(0.65, 0.82, 0.95, 0.46), 1.0)

func _draw_hud() -> void:
	var font := ThemeDB.fallback_font
	# panel superior compacto
	draw_rect(Rect2(8, 7, 624, 50), Color(0.03, 0.04, 0.04, 0.79))
	_draw_bar(Vector2(16, 14), 112.0, hp / 100.0, Color("df5e5e"), "♥")
	_draw_bar(Vector2(16, 29), 112.0, hunger / 100.0, Color("d6a84f"), "●")
	_draw_bar(Vector2(16, 44), 112.0, stamina / 100.0, Color("5bb6d4"), "⚡")
	var x := 145.0
	for item in ["madera", "piedra", "fibra", "comida", "mineral"]:
		_draw_inventory_chip(Vector2(x, 17), item, int(inventory[item]))
		x += 64.0
	draw_string(font, Vector2(473, 25), "Día %d" % day_number, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("f0e8d5"))
	draw_string(font, Vector2(473, 42), "%s · %s" % [weather, _biome_at(player_pos)], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("c6d0c8"))
	draw_string(font, Vector2(573, 54), "v0.2", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("8ea49a"))
	# joystick
	draw_circle(JOY_CENTER, JOY_RADIUS, Color(0.05, 0.07, 0.07, 0.34))
	draw_arc(JOY_CENTER, JOY_RADIUS, 0, TAU, 48, Color(0.82, 0.87, 0.82, 0.58), 2.0)
	var knob := JOY_CENTER + joystick_vec * 24.0
	draw_circle(knob, 18.0, Color(0.72, 0.80, 0.74, 0.72))
	if placement_type == "":
		_draw_action_button(ATTACK_CENTER, "sword")
		_draw_action_button(INTERACT_CENTER, "hand")
		_draw_action_button(CRAFT_CENTER, "bag")
		_draw_action_button(BUILD_CENTER, "hammer")
	if message_timer > 0.0:
		var w := minf(390.0, 120.0 + float(message.length()) * 7.0)
		draw_rect(Rect2(CENTER.x - w * 0.5, 66, w, 29), Color(0.02, 0.025, 0.025, 0.87))
		draw_string(font, Vector2(CENTER.x - w * 0.5 + 12, 86), message, HORIZONTAL_ALIGNMENT_LEFT, w - 24.0, 13, Color.WHITE)

func _draw_bar(pos: Vector2, width: float, ratio: float, color: Color, icon: String) -> void:
	var font := ThemeDB.fallback_font
	draw_string(font, pos + Vector2(0, 9), icon, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
	draw_rect(Rect2(pos + Vector2(15, 1), Vector2(width, 8)), Color(0.08, 0.09, 0.09, 0.9))
	draw_rect(Rect2(pos + Vector2(15, 1), Vector2(width * clampf(ratio, 0.0, 1.0), 8)), color)

func _draw_inventory_chip(pos: Vector2, kind: String, amount: int) -> void:
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(pos, Vector2(58, 28)), Color(0.10, 0.12, 0.11, 0.72))
	_draw_material_icon(pos + Vector2(11, 14), kind)
	draw_string(font, pos + Vector2(23, 18), str(amount), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)

func _draw_material_icon(p: Vector2, kind: String) -> void:
	match kind:
		"madera": draw_line(p + Vector2(-5, 4), p + Vector2(5, -4), Color("a56d43"), 4.0)
		"piedra": draw_circle(p, 6.0, Color("8e9698"))
		"fibra":
			draw_line(p + Vector2(-4, 5), p + Vector2(-2, -5), Color("86a559"), 2.0)
			draw_line(p + Vector2(2, 5), p + Vector2(4, -5), Color("86a559"), 2.0)
		"comida": draw_circle(p, 5.0, Color("d64f72"))
		"mineral": draw_colored_polygon(PackedVector2Array([p + Vector2(-5, 5), p + Vector2(0, -7), p + Vector2(5, 5)]), Color("72d1d8"))

func _draw_action_button(center: Vector2, icon: String) -> void:
	draw_circle(center, 31.0, Color(0.10, 0.12, 0.12, 0.66))
	draw_arc(center, 31.0, 0, TAU, 32, Color(0.82, 0.86, 0.83, 0.72), 2.0)
	match icon:
		"sword":
			draw_line(center + Vector2(-8, 9), center + Vector2(10, -10), Color("d9dddd"), 4.0)
			draw_line(center + Vector2(-10, 5), center + Vector2(-4, 11), Color("9e7249"), 3.0)
		"hand":
			draw_circle(center + Vector2(0, 4), 7.0, Color("d2b188"))
			for x in [-7.0, -2.0, 3.0, 8.0]: draw_line(center + Vector2(x, 2), center + Vector2(x - 1, -9), Color("d2b188"), 3.0)
		"bag":
			draw_rect(Rect2(center + Vector2(-10, -7), Vector2(20, 17)), Color("9b7448"))
			draw_arc(center + Vector2(0, -6), 7.0, PI, TAU, 12, Color("d1b47d"), 2.0)
		"hammer":
			draw_line(center + Vector2(-7, 10), center + Vector2(7, -7), Color("8c623f"), 4.0)
			draw_rect(Rect2(center + Vector2(1, -12), Vector2(15, 7)), Color("aeb3b4"))
		"check":
			draw_line(center + Vector2(-11, 1), center + Vector2(-3, 10), Color("87dc82"), 4.0)
			draw_line(center + Vector2(-3, 10), center + Vector2(13, -10), Color("87dc82"), 4.0)
		"rotate":
			draw_arc(center, 12.0, -2.4, 2.2, 20, Color("a7d4e6"), 3.0)
			draw_colored_polygon(PackedVector2Array([center + Vector2(9, -8), center + Vector2(17, -7), center + Vector2(12, 0)]), Color("a7d4e6"))
		"cancel":
			draw_line(center + Vector2(-9, -9), center + Vector2(9, 9), Color("e77b7b"), 4.0)
			draw_line(center + Vector2(9, -9), center + Vector2(-9, 9), Color("e77b7b"), 4.0)

func _draw_menu() -> void:
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(96, 42, 448, 268), Color(0.035, 0.045, 0.042, 0.96))
	draw_rect(Rect2(102, 48, 436, 256), Color(0.09, 0.115, 0.10, 0.96), false, 2.0)
	var title := "FABRICACIÓN" if menu_mode == "craft" else "CONSTRUIR"
	draw_string(font, Vector2(118, 72), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("f3e9cf"))
	draw_rect(Rect2(500, 48, 34, 30), Color("543b3b"))
	draw_string(font, Vector2(511, 69), "×", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
	var order: Array = CRAFT_ORDER if menu_mode == "craft" else BUILD_ORDER
	for i in range(order.size()):
		var kind := String(order[i])
		var recipe: Dictionary = CRAFT_RECIPES[kind] if menu_mode == "craft" else BUILD_RECIPES[kind]
		var rect := Rect2(118, 92 + i * 68, 404, 58)
		var can := _can_pay(recipe["cost"])
		draw_rect(rect, Color(0.12, 0.15, 0.13, 0.96))
		draw_rect(rect, Color("6c8d6c") if can else Color("775757"), false, 2.0)
		draw_string(font, rect.position + Vector2(12, 20), String(recipe["name"]), HORIZONTAL_ALIGNMENT_LEFT, 185, 14, Color.WHITE)
		draw_string(font, rect.position + Vector2(12, 39), String(recipe["desc"]), HORIZONTAL_ALIGNMENT_LEFT, 205, 10, Color("b9c4ba"))
		_draw_cost_line(rect.position + Vector2(220, 12), recipe["cost"])
		var button_text := "FABRICAR" if menu_mode == "craft" else "COLOCAR"
		draw_rect(Rect2(rect.position + Vector2(308, 15), Vector2(84, 29)), Color("46674b") if can else Color("4e4646"))
		draw_string(font, rect.position + Vector2(317, 35), button_text, HORIZONTAL_ALIGNMENT_CENTER, 66, 11, Color.WHITE)
	if menu_mode == "craft":
		draw_string(font, Vector2(118, 296), "Herramientas: hacha %d · pico %d · vendas %d" % [inventory["hacha"], inventory["pico"], inventory["venda"]], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("d2dbc8"))

func _draw_cost_line(pos: Vector2, cost: Dictionary) -> void:
	var font := ThemeDB.fallback_font
	var y := 0.0
	for k_variant in cost.keys():
		var k := String(k_variant)
		var need := int(cost[k])
		var have := int(inventory.get(k, 0))
		var c := Color("9cdb8c") if have >= need else Color("ef7d78")
		draw_string(font, pos + Vector2(0, y + 11), "%s %d/%d" % [k.capitalize(), have, need], HORIZONTAL_ALIGNMENT_LEFT, 84, 10, c)
		y += 14.0

func _draw_small_bar(pos: Vector2, width: float, ratio: float, color: Color) -> void:
	draw_rect(Rect2(pos, Vector2(width, 3)), Color(0.05, 0.05, 0.05, 0.8))
	draw_rect(Rect2(pos, Vector2(width * clampf(ratio, 0.0, 1.0), 3)), color)

func _draw_floaters() -> void:
	var font := ThemeDB.fallback_font
	for f_variant in floaters:
		var f: Dictionary = f_variant
		var c: Color = f["color"]
		c.a = clampf(float(f["life"]) / 0.72, 0.0, 1.0)
		draw_string(font, f["pos"], String(f["text"]), HORIZONTAL_ALIGNMENT_CENTER, 60, 13, c)

func _setup_audio() -> void:
	for i in range(3):
		var p := AudioStreamPlayer.new()
		add_child(p)
		sound_players.append(p)
	sounds = {
		"ui": _make_tone(520.0, 0.045, 0.13),
		"attack": _make_tone(220.0, 0.07, 0.16),
		"hit": _make_tone(150.0, 0.075, 0.20),
		"hurt": _make_tone(105.0, 0.12, 0.20),
		"harvest": _make_tone(310.0, 0.065, 0.15),
		"collect": _make_tone(690.0, 0.07, 0.13),
		"craft": _make_tone(760.0, 0.10, 0.14),
		"build": _make_tone(420.0, 0.12, 0.16),
		"kill": _make_tone(820.0, 0.13, 0.16),
		"weather": _make_tone(260.0, 0.10, 0.09),
		"error": _make_tone(120.0, 0.08, 0.16),
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
	if not sounds.has(name) or sound_players.is_empty(): return
	var p := sound_players[sound_cursor % sound_players.size()]
	sound_cursor += 1
	p.stream = sounds[name]
	p.play()

func _save_game() -> void:
	var building_data: Array = []
	for b_variant in buildings:
		var b: Dictionary = b_variant
		var pos: Vector2 = b["pos"]
		building_data.append({"type": b["type"], "pos": [pos.x, pos.y], "rot": int(b.get("rot", 0)), "chest": b.get("chest", {})})
	var data := {
		"version": 2,
		"seed": world_seed,
		"player": [player_pos.x, player_pos.y],
		"hp": hp,
		"hunger": hunger,
		"stamina": stamina,
		"day_clock": day_clock,
		"day_number": day_number,
		"weather": weather,
		"inventory": inventory,
		"chunk_mods": chunk_mods,
		"buildings": building_data,
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
	if int(data.get("version", 0)) != 2:
		return false
	world_seed = int(data.get("seed", 0))
	if world_seed == 0: return false
	var pp: Array = data.get("player", [0.0, 0.0])
	player_pos = Vector2(float(pp[0]), float(pp[1]))
	hp = float(data.get("hp", 100.0))
	hunger = float(data.get("hunger", 100.0))
	stamina = float(data.get("stamina", 100.0))
	day_clock = float(data.get("day_clock", 0.28))
	day_number = int(data.get("day_number", 1))
	weather = String(data.get("weather", "despejado"))
	var inv: Dictionary = data.get("inventory", {})
	for k in inventory.keys():
		inventory[k] = int(inv.get(k, inventory[k]))
	chunk_mods = data.get("chunk_mods", {})
	buildings.clear()
	for raw_variant in data.get("buildings", []):
		var raw: Dictionary = raw_variant
		var arr: Array = raw.get("pos", [0.0, 0.0])
		buildings.append({"type": raw.get("type", "fogata"), "pos": Vector2(float(arr[0]), float(arr[1])), "rot": int(raw.get("rot", 0)), "chest": raw.get("chest", {})})
	return true
