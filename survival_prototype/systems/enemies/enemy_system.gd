class_name CSEnemySystem
extends RefCounted

static func update(host: Node, delta: float) -> void:
	var night_bonus := 1.12 if (host.day_clock > 0.72 or host.day_clock < 0.18) else 1.0
	for key_variant in host.loaded_chunks.keys():
		var chunk: Dictionary = host.loaded_chunks[key_variant]
		var enemies: Array = chunk["enemies"]
		for e_variant in enemies:
			var e: Dictionary = e_variant
			if not bool(e.get("alive", true)):
				continue
			e["hit_flash"] = maxf(0.0, float(e["hit_flash"]) - delta)
			var kb: Vector2 = e["knockback"]
			if kb.length() > 1.0:
				e["pos"] = host._move_with_world_collisions(e["pos"], kb * delta, 8.0)
				e["knockback"] = kb.move_toward(Vector2.ZERO, 260.0 * delta)
			if host.player_pos.length() < host.SAFE_RADIUS and (e["pos"] as Vector2).length() > host.SAFE_RADIUS:
				_enemy_return_home(host, e, delta, night_bonus)
				continue
			match String(e["type"]):
				"lobo": _update_wolf(host, e, enemies, delta, night_bonus)
				"acechador": _update_stalker(host, e, enemies, delta, night_bonus)
				_: _update_raider(host, e, enemies, delta, night_bonus)

static func damage_player(host: Node, damage: float, label: String) -> void:
	host.hp -= damage
	host.hurt_stagger = 0.10
	host.stamina_regen_lock = host.STAMINA_REGEN_DELAY
	host.screen_shake = 0.16
	host._mark_dirty("player_damage")
	host._spawn_floater(host.CENTER + Vector2(0, -28), "-%d PV" % int(damage), Color("ff7272"))
	host._spawn_particles(host.player_pos, Color("d95763"), 9)
	host.contextual_hint = label
	host._play_sound("hurt")

static func kill_enemy(host: Node, e: Dictionary) -> void:
	e["alive"] = false
	var mod := host._chunk_state(String(e["chunk"]))
	var killed: Array = mod["killed_enemies"]
	var eid := int(e["id"])
	if not eid in killed:
		killed.append(eid)
	var kind := String(e["type"])
	if kind == "lobo":
		host.inventory["comida"] += 1
		host._spawn_floater(host._world_to_screen(e["pos"]) + Vector2(0, -18), "+1 comida", Color("9ee493"))
	elif kind == "acechador":
		host.inventory["fibra"] += 1
		host._spawn_floater(host._world_to_screen(e["pos"]) + Vector2(0, -18), "+1 fibra", Color("9ee493"))
	else:
		host.inventory["mineral"] += 1
		host._spawn_floater(host._world_to_screen(e["pos"]) + Vector2(0, -18), "+1 mineral", Color("9ee493"))
	host._mark_dirty("enemy_killed")
	host._spawn_particles(e["pos"], Color("a85c65"), 18)
	host._play_sound("kill")

static func _enemy_return_home(host: Node, e: Dictionary, delta: float, speed_mul: float) -> void:
	e["state"] = "return"
	var ep: Vector2 = e["pos"]
	var home: Vector2 = e["home"]
	if ep.distance_to(home) < 12.0:
		e["state"] = "idle"
		return
	var dir := ep.direction_to(home)
	e["pos"] = _enemy_move(host, e, dir * 48.0 * speed_mul * delta, 8.0, [])

static func _enemy_common_awareness(host: Node, e: Dictionary, aggro: float, deaggro: float) -> bool:
	var ep: Vector2 = e["pos"]
	var d := ep.distance_to(host.player_pos)
	var alerted := bool(e.get("alerted", false))
	if not alerted and d <= aggro:
		e["alerted"] = true
		return true
	if alerted and d >= deaggro:
		e["alerted"] = false
		e["state"] = "return"
		return false
	return alerted

static func _enemy_move(host: Node, e: Dictionary, delta_move: Vector2, radius: float, peers: Array) -> Vector2:
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
	var proposed := delta_move + sep * host.get_process_delta_time()
	var moved := host._move_with_world_collisions(ep, proposed, radius)
	# Evitación simple: si un edificio bloquea casi todo el avance, probar un paso lateral.
	if proposed.length() > 0.8 and moved.distance_to(ep) < proposed.length() * 0.22:
		var side := Vector2(-proposed.y, proposed.x).normalized()
		if int(e.get("id", 0)) % 2 != 0:
			side = -side
		var sidestep := side * proposed.length() * 0.9
		var sidemove := host._move_with_world_collisions(ep, sidestep, radius)
		if sidemove.distance_to(ep) > moved.distance_to(ep):
			moved = sidemove
	return moved

static func _update_wolf(host: Node, e: Dictionary, peers: Array, delta: float, speed_mul: float) -> void:
	var aware := _enemy_common_awareness(host, e, 225.0, 345.0)
	var state := String(e["state"])
	var ep: Vector2 = e["pos"]
	var d := ep.distance_to(host.player_pos)
	if not aware:
		_enemy_idle_patrol(host, e, peers, delta, 34.0)
		return
	e["state_timer"] = maxf(0.0, float(e["state_timer"]) - delta)
	match state:
		"idle", "patrol", "return":
			e["state"] = "circle"
			e["state_timer"] = 0.48
		"circle":
			var radial := ep.direction_to(host.player_pos)
			var side := Vector2(-radial.y, radial.x) * (1.0 if int(e["id"]) % 2 == 0 else -1.0)
			var dir := (radial * 0.34 + side * 0.94).normalized()
			e["pos"] = _enemy_move(host, e, dir * 72.0 * speed_mul * delta, 8.0, peers)
			if float(e["state_timer"]) <= 0.0 or d < 55.0:
				e["state"] = "windup"
				e["state_timer"] = 0.28
				e["attack_dir"] = ep.direction_to(host.player_pos)
				e["has_hit"] = false
				host._play_sound("warn")
		"windup":
			if float(e["state_timer"]) <= 0.0:
				e["state"] = "charge"
				e["state_timer"] = 0.34
		"charge":
			var dir: Vector2 = e["attack_dir"]
			e["pos"] = _enemy_move(host, e, dir * 150.0 * speed_mul * delta, 8.0, peers)
			if not bool(e["has_hit"]) and (e["pos"] as Vector2).distance_to(host.player_pos) < 23.0:
				e["has_hit"] = true
				damage_player(host, 8.0, "El lobo embiste")
			if float(e["state_timer"]) <= 0.0:
				e["state"] = "recovery"
				e["state_timer"] = 0.68
		"recovery":
			if float(e["state_timer"]) <= 0.0:
				e["state"] = "circle"
				e["state_timer"] = 0.55

static func _update_stalker(host: Node, e: Dictionary, peers: Array, delta: float, speed_mul: float) -> void:
	var aware := _enemy_common_awareness(host, e, 235.0, 355.0)
	var state := String(e["state"])
	var ep: Vector2 = e["pos"]
	var d := ep.distance_to(host.player_pos)
	if not aware:
		_enemy_idle_patrol(host, e, peers, delta, 28.0)
		return
	e["state_timer"] = maxf(0.0, float(e["state_timer"]) - delta)
	match state:
		"idle", "patrol", "return":
			e["state"] = "stalk"
			e["state_timer"] = 0.8
		"stalk":
			var dir := Vector2.ZERO
			if d > 118.0:
				dir = ep.direction_to(host.player_pos)
			elif d < 82.0:
				dir = host.player_pos.direction_to(ep)
			else:
				var radial := ep.direction_to(host.player_pos)
				dir = Vector2(-radial.y, radial.x) * (1.0 if int(e["id"]) % 2 == 0 else -1.0)
			e["pos"] = _enemy_move(host, e, dir.normalized() * 60.0 * speed_mul * delta, 8.0, peers)
			if float(e["state_timer"]) <= 0.0 and d < 145.0:
				e["state"] = "windup"
				e["state_timer"] = 0.46
				e["attack_dir"] = ep.direction_to(host.player_pos)
				e["has_hit"] = false
				host._play_sound("warn")
		"windup":
			if float(e["state_timer"]) > 0.22:
				e["attack_dir"] = ep.direction_to(host.player_pos)
			if float(e["state_timer"]) <= 0.0:
				e["state"] = "pounce"
				e["state_timer"] = 0.23
		"pounce":
			var pdir: Vector2 = e["attack_dir"]
			e["pos"] = _enemy_move(host, e, pdir * 178.0 * speed_mul * delta, 8.0, peers)
			if not bool(e["has_hit"]) and (e["pos"] as Vector2).distance_to(host.player_pos) < 24.0:
				e["has_hit"] = true
				damage_player(host, 10.0, "El acechador salta")
			if float(e["state_timer"]) <= 0.0:
				e["state"] = "recovery"
				e["state_timer"] = 0.88
		"recovery":
			var away := host.player_pos.direction_to(e["pos"])
			e["pos"] = _enemy_move(host, e, away * 38.0 * delta, 8.0, peers)
			if float(e["state_timer"]) <= 0.0:
				e["state"] = "stalk"
				e["state_timer"] = 0.75

static func _update_raider(host: Node, e: Dictionary, peers: Array, delta: float, speed_mul: float) -> void:
	var aware := _enemy_common_awareness(host, e, 215.0, 335.0)
	var state := String(e["state"])
	var ep: Vector2 = e["pos"]
	var d := ep.distance_to(host.player_pos)
	if not aware:
		_enemy_idle_patrol(host, e, peers, delta, 24.0)
		return
	e["state_timer"] = maxf(0.0, float(e["state_timer"]) - delta)
	match state:
		"idle", "patrol", "return": e["state"] = "chase"
		"chase":
			if d > 40.0:
				e["pos"] = _enemy_move(host, e, ep.direction_to(host.player_pos) * 58.0 * speed_mul * delta, 9.0, peers)
			else:
				e["state"] = "windup"
				e["state_timer"] = 0.66
				e["has_hit"] = false
				host._play_sound("warn")
		"windup":
			if float(e["state_timer"]) <= 0.0:
				e["state"] = "strike"
				e["state_timer"] = 0.12
				if d < 52.0:
					e["has_hit"] = true
					damage_player(host, 13.0, "Golpe pesado del saqueador")
		"strike":
			if float(e["state_timer"]) <= 0.0:
				e["state"] = "recovery"
				e["state_timer"] = 0.96
		"recovery":
			if float(e["state_timer"]) <= 0.0:
				e["state"] = "chase"

static func _enemy_idle_patrol(host: Node, e: Dictionary, peers: Array, delta: float, speed: float) -> void:
	var ep: Vector2 = e["pos"]
	var home: Vector2 = e["home"]
	e["state_timer"] = maxf(0.0, float(e["state_timer"]) - delta)
	if ep.distance_to(home) > 75.0:
		e["pos"] = _enemy_move(host, e, ep.direction_to(home) * speed * delta, 8.0, peers)
		return
	if float(e["state_timer"]) <= 0.0:
		e["state_timer"] = 0.9 + fmod(float(e["id"]) * 0.37 + float(e["phase"]), 1.1)
		var a := float(e["phase"]) + host.anim_clock * 0.13
		e["attack_dir"] = Vector2(cos(a), sin(a))
	var dir: Vector2 = e.get("attack_dir", Vector2.ZERO)
	e["pos"] = _enemy_move(host, e, dir * speed * 0.35 * delta, 8.0, peers)
