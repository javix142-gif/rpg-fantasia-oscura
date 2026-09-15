extends Node2D

const SCREEN := Vector2(640.0, 360.0)
const CENTER := Vector2(320.0, 180.0)
const TILE := 64.0
const WORLD_LIMIT := 1600.0
const SAVE_PATH := "user://ceniza_salvaje_save.json"
const JOY_CENTER := Vector2(88.0, 286.0)
const JOY_RADIUS := 54.0

const CRAFTS := ["hacha", "pico", "venda"]
const BUILDS := ["fogata", "muro", "cofre"]
const WEATHER := ["despejado", "lluvia", "niebla"]

var world_seed: int = 0
var rng := RandomNumberGenerator.new()
var player_pos := Vector2.ZERO
var facing := Vector2.RIGHT
var hp := 100.0
var hunger := 100.0
var stamina := 100.0
var day_clock := 0.28
var day_number := 1
var weather := "despejado"
var weather_timer := 45.0
var save_timer := 15.0
var attack_timer := 0.0
var message := ""
var message_timer := 0.0
var joystick_touch := -1
var joystick_vec := Vector2.ZERO
var mouse_joystick := false
var craft_index := 0
var build_index := 0

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
var resources: Array = []
var removed_ids: Array = []
var enemies: Array = []
var buildings: Array = []

func _ready() -> void:
	get_viewport().set_embedding_subwindows(false)
	if FileAccess.file_exists(SAVE_PATH):
		if not _load_game():
			_new_world()
	else:
		_new_world()
	set_process(true)
	queue_redraw()

func _new_world() -> void:
	world_seed = abs(int(Time.get_unix_time_from_system() * 1000.0)) % 2147480000
	if world_seed == 0:
		world_seed = 142857
	player_pos = Vector2.ZERO
	facing = Vector2.RIGHT
	hp = 100.0
	hunger = 100.0
	stamina = 100.0
	day_clock = 0.28
	day_number = 1
	weather = "despejado"
	inventory = {
		"madera": 0, "piedra": 0, "fibra": 0, "comida": 1, "mineral": 0,
		"hacha": 0, "pico": 0, "venda": 0,
	}
	removed_ids.clear()
	buildings.clear()
	_generate_world()
	_set_message("Nueva semilla: %d. Recolecta, fabrica y sobrevive." % world_seed, 5.0)
	_save_game()

func _generate_world() -> void:
	rng.seed = world_seed
	resources.clear()
	enemies.clear()
	var forced := [
		["rama", Vector2(42, 28)], ["rama", Vector2(-52, 15)],
		["piedra", Vector2(32, -48)], ["piedra", Vector2(-38, -56)],
		["fibra", Vector2(70, -18)], ["fibra", Vector2(-72, 48)],
		["baya", Vector2(18, 72)],
	]
	var next_id := 0
	for item in forced:
		resources.append({"id": next_id, "type": item[0], "pos": item[1]})
		next_id += 1
	for i in range(190):
		var p := Vector2(rng.randf_range(-1480.0, 1480.0), rng.randf_range(-1480.0, 1480.0))
		if p.length() < 110.0:
			p += Vector2(160.0, 120.0)
		var biome := _biome_at(p)
		var roll := rng.randf()
		var kind := "rama"
		if biome == "bosque":
			kind = "arbol" if roll < 0.52 else ("fibra" if roll < 0.75 else ("baya" if roll < 0.90 else "piedra"))
		elif biome == "pradera":
			kind = "fibra" if roll < 0.36 else ("baya" if roll < 0.62 else ("piedra" if roll < 0.82 else "rama"))
		else:
			kind = "piedra" if roll < 0.43 else ("mineral" if roll < 0.70 else ("rama" if roll < 0.84 else "fibra"))
		resources.append({"id": next_id, "type": kind, "pos": p})
		next_id += 1
	var enemy_types := ["lobo", "acechador", "saqueador"]
	for i in range(18):
		var angle := rng.randf_range(0.0, TAU)
		var dist := rng.randf_range(280.0, 1380.0)
		var ep := Vector2(cos(angle), sin(angle)) * dist
		enemies.append({
			"type": enemy_types[i % 3], "pos": ep, "hp": 32.0 + float(i % 3) * 12.0,
			"max_hp": 32.0 + float(i % 3) * 12.0, "alive": true, "cooldown": 0.0,
		})

func _process(delta: float) -> void:
	attack_timer = max(0.0, attack_timer - delta)
	message_timer = max(0.0, message_timer - delta)
	weather_timer -= delta
	save_timer -= delta
	_update_time(delta)
	_update_movement(delta)
	_update_enemies(delta)
	_update_survival(delta)
	if weather_timer <= 0.0:
		weather_timer = 55.0 + rng.randf_range(-12.0, 18.0)
		weather = WEATHER[rng.randi_range(0, WEATHER.size() - 1)]
		_set_message("El tiempo cambia: %s" % weather, 2.5)
	if save_timer <= 0.0:
		save_timer = 15.0
		_save_game()
	queue_redraw()

func _update_time(delta: float) -> void:
	var old := day_clock
	day_clock += delta / 180.0
	if day_clock >= 1.0:
		day_clock -= 1.0
		day_number += 1
		_set_message("Día %d" % day_number, 2.0)
	if old < 0.75 and day_clock >= 0.75:
		_set_message("Cae la noche. Los enemigos son más agresivos.", 3.0)

func _update_movement(delta: float) -> void:
	var move := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): move.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): move.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): move.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): move.y += 1.0
	if joystick_vec.length() > 0.08:
		move = joystick_vec
	if move.length() > 1.0:
		move = move.normalized()
	if move.length() > 0.08:
		facing = move.normalized()
		var speed := 105.0
		if Input.is_key_pressed(KEY_SHIFT) and stamina > 2.0:
			speed = 155.0
			stamina = max(0.0, stamina - delta * 14.0)
		else:
			stamina = min(100.0, stamina + delta * 8.0)
		player_pos += move * speed * delta
		player_pos.x = clamp(player_pos.x, -WORLD_LIMIT, WORLD_LIMIT)
		player_pos.y = clamp(player_pos.y, -WORLD_LIMIT, WORLD_LIMIT)
	else:
		stamina = min(100.0, stamina + delta * 10.0)

func _update_survival(delta: float) -> void:
	hunger = max(0.0, hunger - delta * 0.30)
	if hunger <= 0.0:
		hp -= delta * 2.0
	for b in buildings:
		if b.get("type", "") == "fogata" and Vector2(b["pos"]).distance_to(player_pos) < 72.0:
			if day_clock > 0.72 or day_clock < 0.18:
				hp = min(100.0, hp + delta * 0.65)
	if hp <= 0.0:
		_respawn()

func _update_enemies(delta: float) -> void:
	var night_bonus := 1.28 if (day_clock > 0.72 or day_clock < 0.18) else 1.0
	for e in enemies:
		if not bool(e.get("alive", true)):
			continue
		e["cooldown"] = max(0.0, float(e.get("cooldown", 0.0)) - delta)
		var ep: Vector2 = e["pos"]
		var distance := ep.distance_to(player_pos)
		if distance < 205.0:
			var dir := ep.direction_to(player_pos)
			var speed := 38.0
			if e["type"] == "lobo": speed = 52.0
			elif e["type"] == "saqueador": speed = 34.0
			e["pos"] = ep + dir * speed * night_bonus * delta
			if distance < 24.0 and float(e["cooldown"]) <= 0.0:
				e["cooldown"] = 1.15
				var damage := 7.0 if e["type"] == "lobo" else (9.0 if e["type"] == "acechador" else 11.0)
				hp -= damage
				_set_message("%s te golpea: -%d PV" % [String(e["type"]).capitalize(), int(damage)], 1.4)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_E: _interact()
			KEY_SPACE: _attack()
			KEY_C: _craft_selected()
			KEY_B: _build_selected()
			KEY_Q: _cycle_craft()
			KEY_R: _cycle_build()
			KEY_F: _eat()
			KEY_H: _use_bandage()
			KEY_N: _new_world()
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_down(event.index, event.position)
		else:
			_touch_up(event.index)
	elif event is InputEventScreenDrag and event.index == joystick_touch:
		_update_joystick(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_mouse_down(event.position)
		else:
			mouse_joystick = false
			joystick_vec = Vector2.ZERO
	elif event is InputEventMouseMotion and mouse_joystick:
		_update_joystick(event.position)

func _touch_down(index: int, pos: Vector2) -> void:
	if pos.distance_to(JOY_CENTER) <= JOY_RADIUS * 1.35:
		joystick_touch = index
		_update_joystick(pos)
		return
	_handle_button(pos)

func _touch_up(index: int) -> void:
	if index == joystick_touch:
		joystick_touch = -1
		joystick_vec = Vector2.ZERO

func _mouse_down(pos: Vector2) -> void:
	if pos.distance_to(JOY_CENTER) <= JOY_RADIUS * 1.35:
		mouse_joystick = true
		_update_joystick(pos)
	else:
		_handle_button(pos)

func _update_joystick(pos: Vector2) -> void:
	var delta := pos - JOY_CENTER
	joystick_vec = delta / JOY_RADIUS
	if joystick_vec.length() > 1.0:
		joystick_vec = joystick_vec.normalized()

func _handle_button(pos: Vector2) -> void:
	if pos.distance_to(Vector2(570, 300)) < 34.0: _attack()
	elif pos.distance_to(Vector2(500, 310)) < 34.0: _interact()
	elif pos.distance_to(Vector2(570, 230)) < 34.0: _craft_selected()
	elif pos.distance_to(Vector2(500, 240)) < 34.0: _build_selected()
	elif Rect2(510, 6, 58, 24).has_point(pos): _cycle_craft()
	elif Rect2(573, 6, 61, 24).has_point(pos): _cycle_build()

func _interact() -> void:
	var nearest_building = null
	var nearest_dist := 99999.0
	for b in buildings:
		if b.get("type", "") != "cofre": continue
		var d := Vector2(b["pos"]).distance_to(player_pos)
		if d < 46.0 and d < nearest_dist:
			nearest_dist = d
			nearest_building = b
	if nearest_building != null:
		_chest_exchange(nearest_building)
		return
	var target = null
	nearest_dist = 99999.0
	for r in resources:
		if int(r["id"]) in removed_ids: continue
		var d := Vector2(r["pos"]).distance_to(player_pos)
		if d < 52.0 and d < nearest_dist:
			nearest_dist = d
			target = r
	if target == null:
		_set_message("No hay recursos o cofres al alcance.", 1.5)
		return
	_collect_resource(target)

func _collect_resource(r: Dictionary) -> void:
	var kind := String(r["type"])
	var amount := 1
	match kind:
		"arbol":
			amount = 4 if int(inventory["hacha"]) > 0 else 2
			inventory["madera"] += amount
		"rama":
			inventory["madera"] += 2
			amount = 2
		"piedra":
			amount = 4 if int(inventory["pico"]) > 0 else 2
			inventory["piedra"] += amount
		"fibra":
			inventory["fibra"] += 2
			amount = 2
		"baya":
			inventory["comida"] += 2
			amount = 2
		"mineral":
			amount = 3 if int(inventory["pico"]) > 0 else 1
			inventory["mineral"] += amount
	if not int(r["id"]) in removed_ids:
		removed_ids.append(int(r["id"]))
	_set_message("Recolectado: %s x%d" % [kind, amount], 1.4)

func _attack() -> void:
	if attack_timer > 0.0:
		return
	attack_timer = 0.48
	var best = null
	var best_dist := 99999.0
	for e in enemies:
		if not bool(e.get("alive", true)): continue
		var d := Vector2(e["pos"]).distance_to(player_pos)
		if d < 58.0 and d < best_dist:
			best_dist = d
			best = e
	if best == null:
		_set_message("Atacas al aire.", 0.8)
		return
	var damage := 12.0 + (8.0 if int(inventory["hacha"]) > 0 else 0.0)
	best["hp"] = float(best["hp"]) - damage
	if float(best["hp"]) <= 0.0:
		best["alive"] = false
		inventory["comida"] += 1
		if String(best["type"]) == "saqueador": inventory["mineral"] += 1
		_set_message("Derrotaste a %s. Botín recogido." % String(best["type"]), 2.0)
	else:
		_set_message("Golpe: -%d PV" % int(damage), 0.9)

func _cycle_craft() -> void:
	craft_index = (craft_index + 1) % CRAFTS.size()
	_set_message("Receta: %s" % CRAFTS[craft_index], 1.0)

func _cycle_build() -> void:
	build_index = (build_index + 1) % BUILDS.size()
	_set_message("Construcción: %s" % BUILDS[build_index], 1.0)

func _craft_selected() -> void:
	var item: String = String(CRAFTS[craft_index])
	if item == "hacha":
		if not _spend({"madera": 5, "piedra": 3}): return
		inventory["hacha"] = 1
	elif item == "pico":
		if not _spend({"madera": 4, "piedra": 5}): return
		inventory["pico"] = 1
	elif item == "venda":
		if not _spend({"fibra": 3}): return
		inventory["venda"] += 1
	_set_message("Fabricado: %s" % item, 1.8)

func _build_selected() -> void:
	var item: String = String(BUILDS[build_index])
	var cost := {"madera": 6, "piedra": 4}
	if item == "muro": cost = {"madera": 5}
	elif item == "cofre": cost = {"madera": 8, "piedra": 2}
	if not _spend(cost): return
	var target := player_pos + facing * 64.0
	target = Vector2(round(target.x / 16.0) * 16.0, round(target.y / 16.0) * 16.0)
	for b in buildings:
		if Vector2(b["pos"]).distance_to(target) < 24.0:
			_refund(cost)
			_set_message("Ese lugar está ocupado.", 1.5)
			return
	var entry := {"type": item, "pos": target}
	if item == "cofre":
		entry["storage"] = {"madera": 0, "piedra": 0, "comida": 0, "mineral": 0}
	buildings.append(entry)
	_set_message("Construido: %s" % item, 1.8)
	_save_game()

func _spend(cost: Dictionary) -> bool:
	for key in cost:
		if int(inventory.get(key, 0)) < int(cost[key]):
			_set_message("Faltan materiales para la acción.", 1.5)
			return false
	for key in cost:
		inventory[key] = int(inventory[key]) - int(cost[key])
	return true

func _refund(cost: Dictionary) -> void:
	for key in cost:
		inventory[key] = int(inventory.get(key, 0)) + int(cost[key])

func _chest_exchange(chest: Dictionary) -> void:
	var storage: Dictionary = chest.get("storage", {"madera": 0, "piedra": 0, "comida": 0, "mineral": 0})
	var stored_total := 0
	for key in storage: stored_total += int(storage[key])
	if stored_total > 0:
		for key in storage:
			inventory[key] = int(inventory.get(key, 0)) + int(storage[key])
			storage[key] = 0
		_set_message("Retiraste el contenido del cofre.", 1.7)
	else:
		var moved := 0
		for key in ["madera", "piedra", "comida", "mineral"]:
			var n := int(inventory.get(key, 0)) / 2
			if n > 0:
				inventory[key] -= n
				storage[key] = int(storage.get(key, 0)) + n
				moved += n
		if moved > 0: _set_message("Guardaste la mitad de tus recursos.", 1.7)
		else: _set_message("El cofre está vacío y no tienes qué guardar.", 1.7)
	chest["storage"] = storage
	_save_game()

func _eat() -> void:
	if int(inventory["comida"]) <= 0:
		_set_message("No tienes comida.", 1.2)
		return
	inventory["comida"] -= 1
	hunger = min(100.0, hunger + 32.0)
	hp = min(100.0, hp + 4.0)
	_set_message("Comes y recuperas energía.", 1.4)

func _use_bandage() -> void:
	if int(inventory["venda"]) <= 0:
		_set_message("No tienes vendas.", 1.2)
		return
	inventory["venda"] -= 1
	hp = min(100.0, hp + 28.0)
	_set_message("Usas una venda: +28 PV", 1.4)

func _respawn() -> void:
	hp = 70.0
	hunger = 55.0
	stamina = 100.0
	player_pos = Vector2.ZERO
	_set_message("Has caído. Despiertas junto al punto inicial.", 4.0)
	_save_game()

func _biome_at(p: Vector2) -> String:
	var cx := int(floor(p.x / 260.0))
	var cy := int(floor(p.y / 260.0))
	var n: int = absi((cx * 73856093) ^ (cy * 19349663) ^ world_seed)
	var v: int = n % 100
	if v < 42: return "bosque"
	if v < 73: return "pradera"
	return "cenizal"

func _biome_color(name: String) -> Color:
	if name == "bosque": return Color("#244a35")
	if name == "pradera": return Color("#5b6f3b")
	return Color("#5a4d4a")

func _to_screen(world: Vector2) -> Vector2:
	return world - player_pos + CENTER

func _draw() -> void:
	_draw_world()
	_draw_resources()
	_draw_buildings()
	_draw_enemies()
	_draw_player()
	_draw_lighting_and_weather()
	_draw_hud()
	_draw_touch_controls()

func _draw_world() -> void:
	var first_x := int(floor((player_pos.x - CENTER.x) / TILE)) - 1
	var first_y := int(floor((player_pos.y - CENTER.y) / TILE)) - 1
	for y in range(first_y, first_y + 9):
		for x in range(first_x, first_x + 13):
			var wp := Vector2(float(x) * TILE, float(y) * TILE)
			var c := _biome_color(_biome_at(wp + Vector2(TILE * 0.5, TILE * 0.5)))
			var variation := float(absi((x * 92821) ^ (y * 68917) ^ world_seed) % 7) / 100.0
			c = c.lightened(variation)
			draw_rect(Rect2(_to_screen(wp), Vector2(TILE + 1.0, TILE + 1.0)), c)
			if ((x + y + world_seed) % 5) == 0:
				var sp := _to_screen(wp) + Vector2(12 + absi(x * 13) % 38, 12 + absi(y * 17) % 38)
				draw_circle(sp, 1.5, Color(1, 1, 1, 0.11))

func _draw_resources() -> void:
	for r in resources:
		if int(r["id"]) in removed_ids: continue
		var sp := _to_screen(r["pos"])
		if sp.x < -30 or sp.x > 670 or sp.y < -30 or sp.y > 390: continue
		var kind := String(r["type"])
		match kind:
			"arbol":
				draw_rect(Rect2(sp + Vector2(-3, 2), Vector2(6, 15)), Color("#6b4329"))
				draw_circle(sp + Vector2(0, -5), 12, Color("#2c6b42"))
			"rama":
				draw_line(sp + Vector2(-7, 4), sp + Vector2(8, -3), Color("#9b6a42"), 3)
			"piedra":
				draw_circle(sp, 7, Color("#8f9798"))
			"fibra":
				for dx in [-5.0, 0.0, 5.0]: draw_line(sp + Vector2(dx, 6), sp + Vector2(dx * 0.6, -7), Color("#86b85e"), 2)
			"baya":
				draw_circle(sp, 6, Color("#315f37")); draw_circle(sp + Vector2(-3, -2), 2.5, Color("#c64d67")); draw_circle(sp + Vector2(3, 1), 2.5, Color("#d55870"))
			"mineral":
				draw_circle(sp, 7, Color("#555a64")); draw_circle(sp + Vector2(2, -2), 3, Color("#b27855"))

func _draw_buildings() -> void:
	for b in buildings:
		var sp := _to_screen(b["pos"])
		if sp.x < -50 or sp.x > 690 or sp.y < -50 or sp.y > 410: continue
		match String(b["type"]):
			"fogata":
				draw_line(sp + Vector2(-9, 7), sp + Vector2(9, -3), Color("#6d4c37"), 4)
				draw_line(sp + Vector2(-8, -3), sp + Vector2(9, 7), Color("#6d4c37"), 4)
				draw_circle(sp + Vector2(0, -6), 7, Color("#ee923a"))
				draw_circle(sp + Vector2(0, -8), 3.5, Color("#ffd463"))
			"muro":
				draw_rect(Rect2(sp + Vector2(-18, -8), Vector2(36, 16)), Color("#78563c"))
				for x in [-12.0, 0.0, 12.0]: draw_line(sp + Vector2(x, -8), sp + Vector2(x, 8), Color("#4f3729"), 1)
			"cofre":
				draw_rect(Rect2(sp + Vector2(-13, -8), Vector2(26, 17)), Color("#8b5c2f"))
				draw_line(sp + Vector2(-13, -1), sp + Vector2(13, -1), Color("#d0a052"), 2)
				draw_rect(Rect2(sp + Vector2(-2, -2), Vector2(4, 6)), Color("#e2c067"))

func _draw_enemies() -> void:
	for e in enemies:
		if not bool(e.get("alive", true)): continue
		var sp := _to_screen(e["pos"])
		if sp.x < -30 or sp.x > 670 or sp.y < -30 or sp.y > 390: continue
		var color := Color("#b04a4a")
		if e["type"] == "acechador": color = Color("#7d4aa3")
		elif e["type"] == "saqueador": color = Color("#a57942")
		draw_circle(sp, 9, Color(0.08, 0.06, 0.07, 0.6))
		draw_circle(sp + Vector2(0, -2), 7, color)
		draw_circle(sp + Vector2(-2, -3), 1.1, Color.WHITE)
		var ratio: float = clampf(float(e["hp"]) / float(e["max_hp"]), 0.0, 1.0)
		draw_rect(Rect2(sp + Vector2(-10, -15), Vector2(20, 2)), Color(0.15, 0.05, 0.05, 0.9))
		draw_rect(Rect2(sp + Vector2(-10, -15), Vector2(20 * ratio, 2)), Color("#e65b55"))

func _draw_player() -> void:
	draw_circle(CENTER + Vector2(2, 5), 10, Color(0, 0, 0, 0.35))
	draw_circle(CENTER, 8, Color("#d7c1a1"))
	draw_line(CENTER, CENTER + facing * 13.0, Color("#f3e2c2"), 3)
	draw_circle(CENTER + facing * 7.0, 2, Color("#fff0cb"))

func _draw_lighting_and_weather() -> void:
	var darkness := 0.0
	if day_clock > 0.72:
		darkness = remap(day_clock, 0.72, 1.0, 0.18, 0.62)
	elif day_clock < 0.20:
		darkness = remap(day_clock, 0.0, 0.20, 0.62, 0.0)
	if darkness > 0.01:
		draw_rect(Rect2(Vector2.ZERO, SCREEN), Color(0.02, 0.035, 0.10, darkness))
	if weather == "lluvia":
		var t := int(Time.get_ticks_msec() / 30)
		for i in range(34):
			var x := float((i * 47 + t * 3) % 670) - 15.0
			var y := float((i * 83 + t * 7) % 390) - 15.0
			draw_line(Vector2(x, y), Vector2(x - 5, y + 12), Color(0.65, 0.78, 0.92, 0.45), 1)
	elif weather == "niebla":
		draw_rect(Rect2(Vector2.ZERO, SCREEN), Color(0.78, 0.80, 0.77, 0.16))

func _draw_hud() -> void:
	var font: Font = ThemeDB.fallback_font
	draw_rect(Rect2(6, 6, 500, 55), Color(0.035, 0.045, 0.05, 0.78))
	_draw_bar(Vector2(12, 12), 118, hp, Color("#cf4b4b"), "PV")
	_draw_bar(Vector2(12, 28), 118, hunger, Color("#d49a43"), "HAM")
	_draw_bar(Vector2(12, 44), 118, stamina, Color("#5aa9c9"), "RES")
	var inv_text := "Mad %d  Pie %d  Fib %d  Com %d  Min %d" % [inventory["madera"], inventory["piedra"], inventory["fibra"], inventory["comida"], inventory["mineral"]]
	draw_string(font, Vector2(140, 21), inv_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#f2eee2"))
	var tools := "Hacha:%s  Pico:%s  Venda:%d" % [("sí" if inventory["hacha"] else "no"), ("sí" if inventory["pico"] else "no"), inventory["venda"]]
	draw_string(font, Vector2(140, 38), tools, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#d7ddcf"))
	var state := "Día %d · %s · %s · seed %d" % [day_number, weather, _biome_at(player_pos), world_seed]
	draw_string(font, Vector2(140, 54), state, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#c5cbbb"))
	_draw_small_button(Rect2(510, 6, 58, 24), "REC:%s" % String(CRAFTS[craft_index]).substr(0, 3).to_upper())
	_draw_small_button(Rect2(573, 6, 61, 24), "CON:%s" % String(BUILDS[build_index]).substr(0, 3).to_upper())
	var recipe := _recipe_text()
	draw_string(font, Vector2(512, 45), recipe, HORIZONTAL_ALIGNMENT_LEFT, 124, 9, Color("#e9e2c9"))
	if message_timer > 0.0 and not message.is_empty():
		var width: float = minf(490.0, maxf(210.0, float(message.length()) * 6.0 + 20.0))
		draw_rect(Rect2(CENTER.x - width * 0.5, 72, width, 24), Color(0.02, 0.025, 0.03, 0.82))
		draw_string(font, Vector2(CENTER.x - width * 0.5 + 9, 89), message, HORIZONTAL_ALIGNMENT_CENTER, width - 18, 11, Color.WHITE)
	var help := "WASD/mover · E/recolectar · ESP/atacar · C/fabricar · B/construir · F/comer · H/venda · Q/R/cambiar"
	draw_rect(Rect2(115, 338, 414, 18), Color(0.02, 0.025, 0.03, 0.62))
	draw_string(font, Vector2(120, 351), help, HORIZONTAL_ALIGNMENT_LEFT, 404, 8, Color("#cbd0ca"))

func _draw_bar(pos: Vector2, width: float, value: float, color: Color, label: String) -> void:
	draw_rect(Rect2(pos, Vector2(width, 10)), Color(0.10, 0.11, 0.12, 0.95))
	draw_rect(Rect2(pos + Vector2(1, 1), Vector2((width - 2) * clamp(value / 100.0, 0.0, 1.0), 8)), color)
	draw_string(ThemeDB.fallback_font, pos + Vector2(4, 8), "%s %d" % [label, int(value)], HORIZONTAL_ALIGNMENT_LEFT, width - 8, 8, Color.WHITE)

func _draw_small_button(rect: Rect2, text: String) -> void:
	draw_rect(rect, Color(0.12, 0.14, 0.15, 0.88))
	draw_rect(rect, Color(0.72, 0.75, 0.70, 0.55), false, 1)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(3, 16), text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 6, 8, Color.WHITE)

func _draw_touch_controls() -> void:
	draw_circle(JOY_CENTER, JOY_RADIUS, Color(0.05, 0.06, 0.07, 0.34))
	draw_arc(JOY_CENTER, JOY_RADIUS, 0, TAU, 40, Color(0.82, 0.86, 0.82, 0.35), 2)
	var knob := JOY_CENTER + joystick_vec * 29.0
	draw_circle(knob, 20, Color(0.75, 0.80, 0.75, 0.45))
	_draw_action_button(Vector2(570, 300), "A", Color("#9e4c49"))
	_draw_action_button(Vector2(500, 310), "E", Color("#527c5b"))
	_draw_action_button(Vector2(570, 230), "C", Color("#6e629c"))
	_draw_action_button(Vector2(500, 240), "B", Color("#8c7147"))

func _draw_action_button(center: Vector2, label: String, color: Color) -> void:
	draw_circle(center, 27, Color(color.r, color.g, color.b, 0.58))
	draw_arc(center, 27, 0, TAU, 28, Color(1, 1, 1, 0.45), 2)
	draw_string(ThemeDB.fallback_font, center + Vector2(-12, 6), label, HORIZONTAL_ALIGNMENT_CENTER, 24, 14, Color.WHITE)

func _recipe_text() -> String:
	var c: String = String(CRAFTS[craft_index])
	if c == "hacha": return "5 mad + 3 pie"
	if c == "pico": return "4 mad + 5 pie"
	return "3 fibra"

func _set_message(text: String, seconds: float = 1.8) -> void:
	message = text
	message_timer = seconds

func _save_game() -> void:
	var building_data: Array = []
	for b in buildings:
		var item := {"type": b.get("type", ""), "pos": [float(b["pos"].x), float(b["pos"].y)]}
		if b.get("type", "") == "cofre": item["storage"] = b.get("storage", {})
		building_data.append(item)
	var data := {
		"version": 1, "seed": world_seed,
		"player": [player_pos.x, player_pos.y], "hp": hp, "hunger": hunger,
		"day_clock": day_clock, "day_number": day_number, "weather": weather,
		"inventory": inventory, "removed": removed_ids, "buildings": building_data,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))

func _load_game() -> bool:
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null: return false
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY: return false
	if not parsed.has("seed") or not parsed.has("player"): return false
	world_seed = int(parsed.get("seed", 142857))
	_generate_world()
	var p: Array = parsed.get("player", [0.0, 0.0])
	if p.size() >= 2: player_pos = Vector2(float(p[0]), float(p[1]))
	hp = float(parsed.get("hp", 100.0))
	hunger = float(parsed.get("hunger", 100.0))
	day_clock = float(parsed.get("day_clock", 0.28))
	day_number = int(parsed.get("day_number", 1))
	weather = String(parsed.get("weather", "despejado"))
	var inv = parsed.get("inventory", {})
	for key in inventory:
		if inv.has(key): inventory[key] = int(inv[key])
	removed_ids = []
	for id_value in parsed.get("removed", []): removed_ids.append(int(id_value))
	buildings.clear()
	for saved_b in parsed.get("buildings", []):
		var bp: Array = saved_b.get("pos", [0.0, 0.0])
		var b := {"type": saved_b.get("type", "muro"), "pos": Vector2(float(bp[0]), float(bp[1]))}
		if b["type"] == "cofre": b["storage"] = saved_b.get("storage", {"madera": 0, "piedra": 0, "comida": 0, "mineral": 0})
		buildings.append(b)
	_set_message("Partida cargada · seed %d" % world_seed, 3.0)
	return true

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		_save_game()
