class_name CSCombatSystem
extends RefCounted

static func request_attack(host: Node) -> void:
	if host.menu_mode != "" or host.placement_type != "" or host.harvest_timer > 0.0 or host.hurt_stagger > 0.0:
		return
	if host.combat_state != "idle":
		host.attack_buffered = true
		return
	start_attack(host)

static func start_attack(host: Node) -> void:
	if host.stamina < host.ATTACK_COST:
		host._spawn_floater(host.CENTER + Vector2(0, -28), "SIN ENERGÍA", Color("7dcce5"))
		host._play_sound("error")
		return
	host.stamina = maxf(0.0, host.stamina - host.ATTACK_COST)
	host.stamina_regen_lock = host.STAMINA_REGEN_DELAY
	host.combat_state = "windup"
	host.combat_timer = host.ATTACK_WINDUP
	host.attack_hit_done = false
	host._mark_dirty("combat_stamina")
	host._play_sound("attack")

static func update(host: Node, delta: float) -> void:
	if host.combat_state == "idle":
		return
	host.combat_timer -= delta
	if host.combat_timer > 0.0:
		return
	match host.combat_state:
		"windup":
			host.combat_state = "active"
			host.combat_timer = host.ATTACK_ACTIVE
			if not host.attack_hit_done:
				host.attack_hit_done = true
				resolve_player_attack(host)
		"active":
			host.combat_state = "recovery"
			host.combat_timer = host.ATTACK_RECOVERY
		"recovery":
			host.combat_state = "idle"
			host.combat_timer = 0.0
			if host.attack_buffered:
				host.attack_buffered = false
				start_attack(host)

static func resolve_player_attack(host: Node) -> void:
	var best: Dictionary = {}
	var best_dist: float = 99999.0
	var cc: Vector2i = host._chunk_coord(host.player_pos)
	for y in range(cc.y - 1, cc.y + 2):
		for x in range(cc.x - 1, cc.x + 2):
			var key: String = host._chunk_key(Vector2i(x, y))
			if not host.loaded_chunks.has(key):
				continue
			var chunk: Dictionary = host.loaded_chunks[key]
			for e_variant in chunk["enemies"]:
				var e: Dictionary = e_variant
				if not bool(e.get("alive", true)):
					continue
				var ep: Vector2 = e["pos"]
				var dv: Vector2 = ep - host.player_pos
				var d: float = dv.length()
				if d <= host.ATTACK_RANGE and d < best_dist and (d < 0.5 or host.facing.dot(dv.normalized()) >= host.ATTACK_DOT):
					best = e
					best_dist = d
	if best.is_empty():
		host._spawn_floater(host.CENTER + host.facing * 34.0, "·", Color(0.9, 0.9, 0.8, 0.45))
		return
	var damage: float = 12.0
	best["hp"] = float(best["hp"]) - damage
	best["hit_flash"] = 0.16
	var dir: Vector2 = host.player_pos.direction_to(best["pos"])
	best["knockback"] = dir * 82.0
	host.screen_shake = 0.08
	host._spawn_particles(best["pos"], Color("f3d37a"), 9)
	host._spawn_floater(host._world_to_screen(best["pos"]) + Vector2(0, -18), "-%d" % int(damage), Color("ffd76a"))
	host._play_sound("hit")
	if float(best["hp"]) <= 0.0:
		host._kill_enemy(best)
