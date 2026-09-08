extends Node2D

const PlayerScript = preload("res://rebuild/player_actor.gd")
const EnemyScript = preload("res://rebuild/enemy_actor.gd")
const NpcScript = preload("res://rebuild/npc_actor.gd")
const WorldScript = preload("res://rebuild/world_view.gd")
const HudScript = preload("res://rebuild/hud_layer.gd")

const SAVE_PATH := "user://reconstructed_slice_v1.json"
const SAVE_VERSION := 1
const ZONES := ["liria", "liria_ruinas", "camino", "ceniza", "ruina_exterior", "ruina_interior"]
const SAFE_SPAWNS := {
	"liria": Vector2(480, 370),
	"liria_ruinas": Vector2(480, 390),
	"camino": Vector2(80, 320),
	"ceniza": Vector2(90, 320),
	"ruina_exterior": Vector2(110, 350),
	"ruina_interior": Vector2(170, 320)
}

var world: RebuildWorldView
var player: RebuildPlayer
var hud: RebuildHud
var actor_layer: Node2D
var collision_layer: Node2D
var enemies: Array[RebuildEnemy] = []
var npcs: Array[RebuildNpc] = []
var zone_id := "liria"
var coins := 0
var potions := 2
var kills := 0
var play_time := 0.0
var event_locked := false
var talked: Dictionary = {}
var ceniza_side_done := false
var current_objective := "Habla con Iria, Halven y Bram."
var _pending_attack := false
var _camera: Camera2D

func _ready() -> void:
	_build_world()
	_build_player()
	_build_hud()
	_build_camera()
	_load_zone("liria", true)
	player.input_locked = true
	hud.show_title(FileAccess.file_exists(SAVE_PATH))
	set_process(true)

func _process(delta: float) -> void:
	if not get_tree().paused:
		play_time += delta
	if player == null or hud == null:
		return
	if Input.is_action_just_pressed("interact"):
		_on_interact()
	if Input.is_action_just_pressed("potion"):
		_use_potion()
	if Input.is_action_just_pressed("save_game"):
		_save_game()
	if Input.is_action_just_pressed("load_game"):
		_load_game()
	_update_context_prompt()

func _build_world() -> void:
	world = WorldScript.new()
	world.name = "WorldView"
	add_child(world)
	collision_layer = Node2D.new()
	collision_layer.name = "GeneratedCollision"
	add_child(collision_layer)
	actor_layer = Node2D.new()
	actor_layer.name = "Actors"
	actor_layer.y_sort_enabled = true
	add_child(actor_layer)

func _build_player() -> void:
	player = PlayerScript.new()
	player.name = "Player"
	actor_layer.add_child(player)
	player.attack_window.connect(_on_attack_window)
	player.hp_changed.connect(_on_player_hp_changed)
	player.died.connect(_on_player_died)
	player.dodge_started.connect(func(pos: Vector2): world.spawn_fx("dodge", pos, 0.35))

func _build_hud() -> void:
	hud = HudScript.new()
	hud.name = "HUD"
	add_child(hud)
	hud.joystick_changed.connect(player.set_virtual_input)
	hud.attack_pressed.connect(func(): player.request_attack())
	hud.dodge_pressed.connect(func(): player.request_dodge())
	hud.interact_pressed.connect(_on_interact)
	hud.potion_pressed.connect(_use_potion)
	hud.save_pressed.connect(_save_game)
	hud.load_pressed.connect(_load_game)
	hud.buy_potion_pressed.connect(_buy_potion)
	hud.new_game_pressed.connect(start_new_game)
	hud.continue_pressed.connect(_load_game)
	hud.dialogue_closed.connect(_on_dialogue_closed)

func _build_camera() -> void:
	_camera = Camera2D.new()
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed = 7.0
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = 960
	_camera.limit_bottom = 640
	player.add_child(_camera)

func start_new_game() -> void:
	coins = 0
	potions = 2
	kills = 0
	play_time = 0.0
	talked.clear()
	ceniza_side_done = false
	_pending_attack = false
	event_locked = false
	_load_zone("liria", true)
	player.respawn(SAFE_SPAWNS["liria"])
	player.input_locked = false
	_save_game(true)

func _clear_zone_nodes() -> void:
	for enemy in enemies:
		if is_instance_valid(enemy): enemy.queue_free()
	enemies.clear()
	for npc in npcs:
		if is_instance_valid(npc): npc.queue_free()
	npcs.clear()
	for child in collision_layer.get_children():
		child.queue_free()

func _load_zone(next_zone: String, reset_position: bool = true) -> void:
	if not ZONES.has(next_zone):
		return
	zone_id = next_zone
	world.set_zone(zone_id)
	_clear_zone_nodes()
	_build_zone_colliders()
	if reset_position and player != null:
		player.global_position = SAFE_SPAWNS[zone_id]
	match zone_id:
		"liria":
			_spawn_liria_npcs()
			current_objective = "Habla con Iria, Halven y Bram." if talked.size() < 3 else "Algo inquieta a la plaza..."
		"liria_ruinas":
			_spawn_wave([Vector2(300,300), Vector2(520,255), Vector2(690,390)])
			current_objective = "Defiende Liria: derrota a la oleada."
		"camino":
			_spawn_wave([Vector2(315,335), Vector2(525,285), Vector2(730,350)])
			current_objective = "Abre paso por el Camino Prohibido."
		"ceniza":
			_spawn_ceniza_npcs()
			world.set_portal_active(true)
			current_objective = "Reabastécete y pregunta por Cyrion."
		"ruina_exterior":
			_spawn_wave([Vector2(420,300), Vector2(655,390)])
			current_objective = "Cruza el atrio de la primera ruina."
		"ruina_interior":
			_spawn_boss()
			current_objective = "Derrota al Guardián de Cyrion."
	_hud_refresh()

func _build_zone_colliders() -> void:
	for i in range(world.get_blockers().size()):
		var rect: Rect2 = world.get_blockers()[i]
		var body := StaticBody2D.new()
		body.name = "Blocker_%02d" % i
		body.collision_layer = 1
		body.collision_mask = 0
		var shape_node := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = rect.size
		shape_node.shape = shape
		shape_node.position = rect.position + rect.size * 0.5
		body.add_child(shape_node)
		collision_layer.add_child(body)
	# Hard world perimeter.
	for spec in [
		[Vector2(480,-10), Vector2(960,20)], [Vector2(480,650), Vector2(960,20)],
		[Vector2(-10,320), Vector2(20,640)], [Vector2(970,320), Vector2(20,640)]
	]:
		var body := StaticBody2D.new(); body.collision_layer = 1
		var node := CollisionShape2D.new(); var shape := RectangleShape2D.new(); shape.size = spec[1]; node.shape = shape; node.position = spec[0]; body.add_child(node); collision_layer.add_child(body)

func _spawn_liria_npcs() -> void:
	_spawn_npc("iria", "Iria", "vecina", Vector2(320,330), Color("#5d7c68"), Color("#c46f61"), "!")
	_spawn_npc("halven", "Halven", "archivist", Vector2(610,300), Color("#68748e"), Color("#c69a61"), "!")
	_spawn_npc("bram", "Bram", "herrero", Vector2(560,410), Color("#8b5d49"), Color("#d2a04f"), "!")
	_spawn_npc("nella", "Nella", "mercader", Vector2(760,345), Color("#675f87"), Color("#d6a95e"))

func _spawn_ceniza_npcs() -> void:
	_spawn_npc("mira", "Mira", "merchant", Vector2(450,320), Color("#7e6250"), Color("#d0a05a"), "!")
	_spawn_npc("sael", "Sael", "guide", Vector2(640,350), Color("#586c70"), Color("#b18d61"), "!")
	_spawn_npc("oren", "Oren", "villager", Vector2(300,390), Color("#6f715f"), Color("#b87555"))

func _spawn_npc(id: String, label: String, role: String, pos: Vector2, body: Color, accent: Color, marker: String = "") -> void:
	var npc: RebuildNpc = NpcScript.new()
	npc.setup(id, label, role, body, accent)
	npc.global_position = pos
	npc.set_marker(marker)
	actor_layer.add_child(npc)
	npcs.append(npc)

func _spawn_wave(positions: Array) -> void:
	for pos in positions:
		_spawn_enemy(pos, false)

func _spawn_boss() -> void:
	_spawn_enemy(Vector2(620,320), true)

func _spawn_enemy(pos: Vector2, boss: bool) -> void:
	var enemy: RebuildEnemy = EnemyScript.new()
	enemy.setup(player, boss)
	enemy.global_position = pos
	enemy.died.connect(_on_enemy_died)
	enemy.attack_landed.connect(_on_enemy_attack)
	enemy.telegraph.connect(func(p: Vector2, _r: float): world.spawn_fx("boss" if boss else "hit", p, 0.28))
	actor_layer.add_child(enemy)
	enemies.append(enemy)

func _on_attack_window(hit_pos: Vector2, facing: Vector2) -> void:
	world.spawn_fx("slash", hit_pos, 0.30)
	var hit_any := false
	for enemy in enemies.duplicate():
		if not is_instance_valid(enemy):
			continue
		var delta := enemy.global_position - player.global_position
		if delta.length() <= (88.0 if enemy.is_boss else 66.0) and delta.normalized().dot(facing) > -0.15:
			enemy.take_damage(25, player.global_position)
			world.spawn_fx("hit", enemy.global_position + Vector2(0,-12), 0.24)
			hit_any = true
	if hit_any and OS.has_feature("android"):
		Input.vibrate_handheld(22)

func _on_enemy_attack(pos: Vector2, amount: int, radius: float) -> void:
	if player.global_position.distance_to(pos) <= radius:
		if player.take_damage(amount, pos):
			world.spawn_fx("hit", player.global_position + Vector2(0,-12), 0.25)

func _on_enemy_died(enemy: RebuildEnemy, reward: int) -> void:
	enemies.erase(enemy)
	coins += reward
	kills += 1
	world.spawn_fx("hit", enemy.global_position, 0.38)
	if kills % 3 == 0:
		potions += 1
	_hud_refresh()
	if enemies.is_empty():
		_on_zone_combat_cleared()

func _on_zone_combat_cleared() -> void:
	world.set_portal_active(true)
	match zone_id:
		"liria_ruinas": current_objective = "La oleada terminó. Cruza la salida este hacia el Camino Prohibido."
		"camino": current_objective = "El camino está libre. Continúa al este hacia Ceniza."
		"ruina_exterior": current_objective = "El atrio está despejado. Entra en la cámara interior."
		"ruina_interior":
			current_objective = "El Guardián ha caído."
			player.input_locked = true
			hud.show_end(play_time, kills, coins)
	_hud_refresh()
	_save_game(true)

func _on_player_hp_changed(_hp: int, _max: int) -> void:
	_hud_refresh()

func _on_player_died() -> void:
	world.spawn_fx("hit", player.global_position, 0.55)
	await get_tree().create_timer(0.65).timeout
	player.respawn(SAFE_SPAWNS[zone_id])
	hud.notify("Has vuelto al último punto seguro.")
	_hud_refresh()

func _on_interact() -> void:
	if event_locked or hud.is_dialogue_open():
		return
	var nearest := _nearest_npc(72.0)
	if nearest != null:
		_interact_npc(nearest)
		return
	if world.portal_active and player.global_position.x > 800.0:
		advance_zone()
		return
	hud.notify("No hay nada que usar aquí.")

func _nearest_npc(radius: float) -> RebuildNpc:
	var nearest: RebuildNpc
	var best := radius
	for npc in npcs:
		if not is_instance_valid(npc): continue
		var d := player.global_position.distance_to(npc.global_position)
		if d < best:
			best = d
			nearest = npc
	return nearest

func _interact_npc(npc: RebuildNpc) -> void:
	if zone_id == "liria":
		match npc.npc_id:
			"iria": hud.show_dialogue("Iria", "El día amaneció demasiado quieto. Habla con los demás y vuelve a la plaza antes del anochecer.")
			"halven": hud.show_dialogue("Halven", "Los archivos mencionan cinco luces sobre Cyrion. Pensé que era una metáfora; ahora ya no estoy seguro.")
			"bram": hud.show_dialogue("Bram", "Los caminos del este están inquietos. Si vas a salir de Liria, afila primero el acero.")
			_: hud.show_dialogue(npc.display_name, "La plaza parece tranquila, pero nadie termina de relajarse.")
		if ["iria","halven","bram"].has(npc.npc_id):
			talked[npc.npc_id] = true
			npc.set_marker("")
		if talked.size() >= 3:
			_pending_attack = true
			current_objective = "Regresa la mirada a la plaza..."
	elif zone_id == "ceniza":
		if npc.npc_id == "mira":
			hud.open_shop()
		elif npc.npc_id == "sael":
			hud.show_dialogue("Sael", "Cyrion no está muerta. Sólo duerme bajo piedra blanca y metal negro. La entrada está al este.")
			if not ceniza_side_done:
				ceniza_side_done = true
				coins += 4
				npc.set_marker("")
				current_objective = "Sigue al este hacia la ruina de Cyrion."
		else:
			hud.show_dialogue(npc.display_name, "Aquí aprendimos a vivir con ceniza en los pulmones y silencio en los caminos.")
	_hud_refresh()

func _on_dialogue_closed() -> void:
	if _pending_attack and zone_id == "liria":
		_pending_attack = false
		_start_attack_event()

func _start_attack_event() -> void:
	event_locked = true
	player.input_locked = true
	hud.notify("¡Campanas de alarma! Algo entra por el este...")
	await get_tree().create_timer(0.75).timeout
	world.spawn_fx("boss", Vector2(770,320), 0.65)
	await get_tree().create_timer(0.35).timeout
	_load_zone("liria_ruinas", true)
	player.respawn(SAFE_SPAWNS["liria_ruinas"])
	player.input_locked = false
	event_locked = false
	_save_game(true)

func advance_zone() -> bool:
	if event_locked or not world.portal_active:
		return false
	var next := ""
	match zone_id:
		"liria_ruinas": next = "camino"
		"camino": next = "ceniza"
		"ceniza": next = "ruina_exterior"
		"ruina_exterior": next = "ruina_interior"
		_: return false
	_load_zone(next, true)
	player.respawn(SAFE_SPAWNS[next])
	_save_game(true)
	return true

func _buy_potion() -> void:
	if coins < 5:
		hud.notify("No tienes suficientes monedas.")
		return
	coins -= 5
	potions += 1
	hud.notify("Compraste una Poción de Vitae.")
	_hud_refresh()

func _use_potion() -> void:
	if potions <= 0:
		hud.notify("No quedan pociones.")
		return
	var healed := player.heal(35)
	if healed <= 0:
		hud.notify("No necesitas curarte ahora.")
		return
	potions -= 1
	world.spawn_fx("heal", player.global_position + Vector2(0,-12), 0.55)
	_hud_refresh()

func _update_context_prompt() -> void:
	if hud == null or player == null:
		return
	var npc := _nearest_npc(72.0)
	if npc != null:
		hud.set_interaction("HABLAR")
	elif world.portal_active and player.global_position.x > 760.0:
		hud.set_interaction("ENTRAR")
	else:
		hud.set_interaction("")

func _hud_refresh() -> void:
	if hud == null or player == null:
		return
	hud.set_stats(player.hp, player.MAX_HP, coins, potions)
	hud.set_objective(zone_id, current_objective)

func _save_game(silent: bool = false) -> bool:
	if event_locked:
		if not silent: hud.notify("No se puede guardar durante una transición narrativa.")
		return false
	var data := {
		"schema_version": SAVE_VERSION,
		"zone": zone_id,
		"pos": [player.global_position.x, player.global_position.y],
		"hp": player.hp,
		"coins": coins,
		"potions": potions,
		"kills": kills,
		"play_time": play_time,
		"talked": talked,
		"ceniza_side_done": ceniza_side_done,
		"objective": current_objective,
		"portal_active": world.portal_active
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		if not silent: hud.notify("No se pudo guardar.")
		return false
	file.store_string(JSON.stringify(data))
	file.close()
	if not silent: hud.notify("Partida guardada.")
	return true

func _load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		hud.notify("No hay partida guardada.")
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null: return false
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		hud.notify("Guardado inválido; inicia una partida nueva.")
		return false
	var data: Dictionary = parsed
	zone_id = String(data.get("zone", "liria"))
	coins = int(data.get("coins", 0))
	potions = int(data.get("potions", 2))
	kills = int(data.get("kills", 0))
	play_time = float(data.get("play_time", 0.0))
	talked = data.get("talked", {}).duplicate(true)
	ceniza_side_done = bool(data.get("ceniza_side_done", false))
	current_objective = String(data.get("objective", "Continúa tu viaje."))
	_load_zone(zone_id, false)
	var pos = data.get("pos", [SAFE_SPAWNS[zone_id].x, SAFE_SPAWNS[zone_id].y])
	player.respawn(Vector2(float(pos[0]), float(pos[1])))
	player.hp = clampi(int(data.get("hp", 100)), 1, 100)
	if bool(data.get("portal_active", false)):
		for enemy in enemies:
			if is_instance_valid(enemy): enemy.queue_free()
		enemies.clear()
		world.set_portal_active(true)
	player.input_locked = false
	_hud_refresh()
	return true

# Deterministic hooks used by headless reconstruction tests.
func debug_load_zone(id: String) -> void:
	_load_zone(id, true)

func debug_state() -> Dictionary:
	return {"zone": zone_id, "enemy_count": enemies.size(), "npc_count": npcs.size(), "coins": coins, "potions": potions, "blockers": world.get_blockers().size()}
