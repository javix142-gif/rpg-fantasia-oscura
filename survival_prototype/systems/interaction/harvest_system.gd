class_name CSHarvestSystem
extends RefCounted

static func start(host: Node, r: Dictionary) -> void:
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
	if needed_tool != "" and host.equipped_tool != needed_tool:
		host._spawn_floater(host._world_to_screen(r["pos"]) + Vector2(0, -18), "Requiere %s" % needed_tool, Color("f0b36b"))
		host._play_sound("error")
		return
	if host.stamina < cost:
		host._spawn_floater(host.CENTER + Vector2(0, -28), "SIN ENERGÍA", Color("7dcce5"))
		host._play_sound("error")
		return
	host.stamina = maxf(0.0, host.stamina - cost)
	host.stamina_regen_lock = host.STAMINA_REGEN_DELAY
	host.harvest_target = r
	host.harvest_duration = duration
	host.harvest_timer = duration
	host.harvest_cost = cost
	host.harvest_started_pos = host.player_pos
	host.harvest_kind = kind
	var rp: Vector2 = r["pos"]
	if rp.distance_to(host.player_pos) > 0.1:
		host.facing = host._cardinal(host.player_pos.direction_to(rp))
	host._mark_dirty("harvest_stamina")
	host._play_sound("harvest")

static func update(host: Node, delta: float) -> void:
	if host.harvest_timer <= 0.0:
		return
	if host.harvest_target.is_empty():
		host.harvest_timer = 0.0
		return
	var target_pos: Vector2 = host.harvest_target["pos"]
	if target_pos.distance_to(host.player_pos) > 48.0 or host.player_pos.distance_to(host.harvest_started_pos) > 20.0:
		cancel(host, "Interacción cancelada")
		return
	host.harvest_timer -= delta
	if host.harvest_timer <= 0.0:
		finish(host)

static func cancel(host: Node, text: String) -> void:
	host.harvest_timer = 0.0
	host.harvest_target = {}
	host.harvest_kind = ""
	if text != "":
		host._spawn_floater(host.CENTER + Vector2(0, -26), text, Color(0.8, 0.82, 0.78, 0.72))

static func finish(host: Node) -> void:
	if host.harvest_target.is_empty():
		return
	var r: Dictionary = host.harvest_target
	var kind := String(r["type"])
	r["hp"] = float(r["hp"]) - 1.0
	r["shake"] = 0.28
	var mod := host._chunk_state(String(r["chunk"]))
	var hp_state: Dictionary = mod["resource_hp"]
	hp_state[str(int(r["id"]))] = maxf(0.0, float(r["hp"]))
	host._mark_dirty("resource_hp")
	host._spawn_particles(r["pos"], host._resource_particle_color(kind), 8)
	if float(r["hp"]) <= 0.0:
		collect(host, r)
	else:
		host._spawn_floater(host._world_to_screen(r["pos"]) + Vector2(0, -20), "%d/%d" % [int(r["hp"]), int(r["max_hp"])], Color("e2bd72"))
	host.harvest_timer = 0.0
	host.harvest_target = {}
	host.harvest_kind = ""

static func collect(host: Node, r: Dictionary) -> void:
	var kind := String(r["type"])
	var amount := 1
	var inv_key := ""
	match kind:
		"arbol":
			amount = 3
			inv_key = "madera"
		"rama":
			inv_key = "madera"
			host.tutorial_got_branch = true
		"roca":
			amount = 2
			inv_key = "piedra"
		"piedra_suelta":
			inv_key = "piedra"
			host.tutorial_got_stone = true
		"fibra": inv_key = "fibra"
		"baya": inv_key = "comida"
		"mineral": inv_key = "mineral"
	if inv_key != "":
		host.inventory[inv_key] = int(host.inventory.get(inv_key, 0)) + amount
	var mod := host._chunk_state(String(r["chunk"]))
	var removed: Array = mod["removed_resources"]
	var rid := int(r["id"])
	if not rid in removed:
		removed.append(rid)
	var hp_state: Dictionary = mod["resource_hp"]
	hp_state.erase(str(rid))
	if host.loaded_chunks.has(String(r["chunk"])):
		var chunk: Dictionary = host.loaded_chunks[String(r["chunk"])]
		var resources: Array = chunk["resources"]
		resources.erase(r)
	host._mark_dirty("resource_collected")
	host._spawn_floater(host._world_to_screen(r["pos"]) + Vector2(0, -17), "+%d %s" % [amount, host._material_short(inv_key)], Color("9ee493"))
	host._play_sound("collect")
