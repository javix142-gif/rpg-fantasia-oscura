from pathlib import Path
import re

PATH = Path(__file__).resolve().parents[1] / "v03.gd"
text = PATH.read_text(encoding="utf-8")
original = text

if "const SaveSystem = preload(" in text:
    print("stabilization already applied")
    raise SystemExit(0)

PRELOADS = '''const SaveSystem = preload("res://systems/persistence/save_system.gd")
const GameState = preload("res://core/game_state.gd")
const WorldGenerator = preload("res://world/world_generator.gd")
const SpatialIndex = preload("res://world/spatial_index.gd")
const InventorySystem = preload("res://systems/inventory/inventory_system.gd")
const InteractionSystem = preload("res://systems/interaction/interaction_system.gd")
const CombatSystem = preload("res://systems/combat/combat_system.gd")
const EnemySystem = preload("res://systems/enemies/enemy_system.gd")
const HarvestSystem = preload("res://systems/interaction/harvest_system.gd")
const BuildingSystem = preload("res://systems/building/building_system.gd")
const InputActions = preload("res://systems/input/input_actions.gd")
const DayWeatherSystem = preload("res://systems/environment/day_weather_system.gd")
const WorldRenderer = preload("res://ui/world_renderer.gd")
'''

text = text.replace("extends Node2D\n", "extends Node2D\n\n" + PRELOADS + "\n", 1)
if text == original:
    raise RuntimeError("failed to insert preloads")

STATE = '''
var spatial_index: RefCounted = SpatialIndex.new()
var save_dirty := false
var save_blocked := false
var save_block_reason := ""
var last_dirty_reason := ""
const DEBUG_ALLOW_NEW_WORLD_SHORTCUT := false
'''
anchor = "var sound_cursor := 0\n"
if anchor not in text:
    raise RuntimeError("sound_cursor anchor missing")
text = text.replace(anchor, anchor + STATE, 1)


def replace_func(name: str, block: str):
    global text
    pattern = re.compile(rf"(?ms)^func {re.escape(name)}\([^\n]*\)(?: -> [^:]+)?:\n.*?(?=^func |\Z)")
    matches = list(pattern.finditer(text))
    if len(matches) != 1:
        raise RuntimeError(f"expected exactly one function {name}, found {len(matches)}")
    text = text[:matches[0].start()] + block.rstrip() + "\n\n" + text[matches[0].end():]

replace_func("_ready", '''func _ready() -> void:
	get_viewport().set_embedding_subwindows(false)
	InputActions.ensure_actions()
	_setup_audio()
	var load_result: Dictionary = SaveSystem.load_state()
	if bool(load_result.get("ok", false)) and GameState.apply(self, load_result.get("data", {})):
		_setup_noise()
		_refresh_chunks(true)
		save_dirty = false
		var source := String(load_result.get("source", "primary"))
		if source == "backup" and FileAccess.file_exists(SaveSystem.PRIMARY_PATH):
			save_blocked = true
			save_block_reason = "primary_invalid_backup_loaded"
			_set_major("Backup cargado. Save primario inválido protegido.", 3.2)
		elif source == "backup":
			_set_major("Backup recuperado", 2.0)
		else:
			_set_major("Partida v0.3 cargada", 1.5)
	elif String(load_result.get("error", "")) == "save_missing":
		_new_world(true)
	else:
		# Nunca sobrescribir automáticamente un save que existe pero no valida.
		save_blocked = true
		save_block_reason = String(load_result.get("error", "invalid_save"))
		_new_world(false)
		_set_major("SAVE INVÁLIDO PROTEGIDO · sesión sin guardado", 4.0)
	set_process(true)
	queue_redraw()''')

replace_func("_new_world", '''func _new_world(persist_initial: bool = true) -> void:
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
	spatial_index.rebuild(buildings)
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
	_mark_dirty("new_world")
	_set_major("Un claro seguro. Reune recursos antes de salir.", 3.0)
	if persist_initial and not save_blocked:
		_save_game(true)''')

replace_func("_setup_noise", '''func _setup_noise() -> void:
	var noise: Dictionary = WorldGenerator.setup_noise(world_seed)
	biome_noise = noise["biome"]
	detail_noise = noise["detail"]
	rng.seed = world_seed''')

replace_func("_process", '''func _process(delta: float) -> void:
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
		DayWeatherSystem.change_weather(self)
	if save_timer <= 0.0:
		save_timer = 12.0
		_save_game(false)
	queue_redraw()''')

replace_func("_update_time", '''func _update_time(delta: float) -> void:
	DayWeatherSystem.update_time(self, delta)''')

replace_func("_update_movement", '''func _update_movement(delta: float) -> void:
	if menu_mode != "":
		is_moving = false
		is_sprinting = false
		joystick_vec = Vector2.ZERO
		_regen_stamina(delta, 8.0)
		return
	var move: Vector2 = InputActions.movement_vector()
	if joystick_vec.length() > 0.08:
		move = joystick_vec
	if move.length() > 1.0:
		move = move.normalized()
	is_moving = move.length() > 0.08
	var multiplier := _action_move_multiplier()
	if is_moving and multiplier > 0.0:
		if combat_state == "idle" and harvest_timer <= 0.0:
			facing = _cardinal(move)
		var wants_sprint := (joystick_vec.length() > 0.88 or InputActions.sprint_pressed()) and multiplier >= 0.99
		is_sprinting = wants_sprint and stamina > 2.0
		var speed := SPRINT_SPEED if is_sprinting else WALK_SPEED
		if is_sprinting:
			stamina = maxf(0.0, stamina - SPRINT_DRAIN * delta)
			stamina_regen_lock = STAMINA_REGEN_DELAY
		else:
			_regen_stamina(delta, 9.0)
		var before := player_pos
		var delta_move := move * speed * multiplier * delta
		player_pos = _move_with_world_collisions(player_pos, delta_move, PLAYER_RADIUS)
		if player_pos.distance_squared_to(before) > 0.0001:
			_mark_dirty("player_position")
	else:
		is_sprinting = false
		_regen_stamina(delta, 12.0)
	if player_pos.distance_to(spawn_pos) > 28.0:
		tutorial_moved = true
	_refresh_chunks(false)''')

replace_func("_update_survival", '''func _update_survival(delta: float) -> void:
	DayWeatherSystem.update_survival(self, delta)''')

replace_func("_respawn", '''func _respawn() -> void:
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
	_mark_dirty("respawn")
	_set_major("Has caído. Regresas al claro.", 2.6)
	_play_sound("hurt")''')

replace_func("_refresh_chunks", '''func _refresh_chunks(force: bool) -> void:
	var cc := _chunk_coord(player_pos)
	if not force and cc == current_chunk:
		return
	current_chunk = cc
	var current_key := _chunk_key(cc)
	if not explored_chunks.has(current_key):
		explored_chunks[current_key] = true
		_mark_dirty("exploration")
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
			loaded_chunks.erase(key)''')

# World generation delegation.
replace_func("_chunk_coord", '''func _chunk_coord(pos: Vector2) -> Vector2i:
	return WorldGenerator.chunk_coord(pos)''')
replace_func("_chunk_key", '''func _chunk_key(coord: Vector2i) -> String:
	return WorldGenerator.chunk_key(coord)''')
replace_func("_parse_chunk_key", '''func _parse_chunk_key(key: String) -> Vector2i:
	return WorldGenerator.parse_chunk_key(key)''')
replace_func("_chunk_seed", '''func _chunk_seed(coord: Vector2i) -> int:
	return WorldGenerator.chunk_seed(world_seed, coord)''')
replace_func("_generate_chunk", '''func _generate_chunk(coord: Vector2i) -> Dictionary:
	return WorldGenerator.generate_chunk(world_seed, coord, _chunk_state(_chunk_key(coord)), biome_noise)''')
replace_func("_resource_kind", '''func _resource_kind(biome: String, roll: float, safe: bool) -> String:
	return WorldGenerator.resource_kind(biome, roll, safe)''')
replace_func("_resource_max_hp", '''func _resource_max_hp(kind: String) -> float:
	return WorldGenerator.resource_max_hp(kind)''')
replace_func("_biome_value", '''func _biome_value(pos: Vector2) -> float:
	return WorldGenerator.biome_value(pos, biome_noise)''')
replace_func("_biome_at", '''func _biome_at(pos: Vector2) -> String:
	return WorldGenerator.biome_at(pos, biome_noise)''')
replace_func("_terrain_color", '''func _terrain_color(pos: Vector2) -> Color:
	return WorldGenerator.terrain_color(pos, biome_noise, detail_noise)''')
replace_func("_tile_hash", '''func _tile_hash(x: int, y: int) -> int:
	return WorldGenerator.tile_hash(world_seed, x, y)''')

# Combat delegation.
replace_func("_request_attack", '''func _request_attack() -> void:
	CombatSystem.request_attack(self)''')
replace_func("_start_attack", '''func _start_attack() -> void:
	CombatSystem.start_attack(self)''')
replace_func("_update_combat", '''func _update_combat(delta: float) -> void:
	CombatSystem.update(self, delta)''')
replace_func("_resolve_player_attack", '''func _resolve_player_attack() -> void:
	CombatSystem.resolve_player_attack(self)''')

# Enemy AI delegation; keep public host helpers used by modules/drawing.
replace_func("_update_enemies", '''func _update_enemies(delta: float) -> void:
	EnemySystem.update(self, delta)''')
replace_func("_damage_player", '''func _damage_player(damage: float, label: String) -> void:
	EnemySystem.damage_player(self, damage, label)''')
replace_func("_kill_enemy", '''func _kill_enemy(e: Dictionary) -> void:
	EnemySystem.kill_enemy(self, e)''')
for name in ["_enemy_return_home", "_enemy_common_awareness", "_enemy_move", "_update_wolf", "_update_stalker", "_update_raider", "_enemy_idle_patrol"]:
    # Functions are no longer runtime responsibilities; remove them completely.
    replace_func(name, "")

# Interaction / harvesting.
replace_func("_interact", '''func _interact() -> void:
	InteractionSystem.interact(self)''')
replace_func("_nearest_resource", '''func _nearest_resource(max_dist: float) -> Dictionary:
	return InteractionSystem.nearest_resource(self, max_dist)''')
replace_func("_nearest_chest", '''func _nearest_chest(max_dist: float) -> int:
	return InteractionSystem.nearest_chest(self, max_dist)''')
replace_func("_start_harvest", '''func _start_harvest(r: Dictionary) -> void:
	HarvestSystem.start(self, r)''')
replace_func("_update_harvest", '''func _update_harvest(delta: float) -> void:
	HarvestSystem.update(self, delta)''')
replace_func("_cancel_harvest", '''func _cancel_harvest(text: String) -> void:
	HarvestSystem.cancel(self, text)''')
replace_func("_finish_harvest", '''func _finish_harvest() -> void:
	HarvestSystem.finish(self)''')
replace_func("_collect_resource", '''func _collect_resource(r: Dictionary) -> void:
	HarvestSystem.collect(self, r)''')

# Inventory / chest / crafting.
replace_func("_craft_item", '''func _craft_item(kind: String) -> void:
	InventorySystem.craft_item(self, kind)''')
replace_func("_toggle_tool", '''func _toggle_tool(kind: String) -> void:
	InventorySystem.toggle_tool(self, kind)''')
replace_func("_eat", '''func _eat() -> void:
	InventorySystem.eat(self)''')
replace_func("_use_bandage", '''func _use_bandage() -> void:
	InventorySystem.use_bandage(self)''')
replace_func("_chest_transfer", '''func _chest_transfer(item: String, to_chest: bool) -> void:
	InventorySystem.chest_transfer(self, item, to_chest, false)''')
replace_func("_chest_transfer_all", '''func _chest_transfer_all(to_chest: bool) -> void:
	InventorySystem.chest_transfer_all(self, to_chest)''')
replace_func("_can_pay", '''func _can_pay(cost: Dictionary) -> bool:
	return InventorySystem.can_pay(self, cost)''')
replace_func("_pay", '''func _pay(cost: Dictionary) -> void:
	InventorySystem.pay(self, cost)''')

# Building placement.
replace_func("_select_build", '''func _select_build(kind: String) -> void:
	BuildingSystem.select_build(self, kind)''')
replace_func("_snap_build_pos", '''func _snap_build_pos(pos: Vector2) -> Vector2:
	return BuildingSystem.snap_build_pos(pos)''')
replace_func("_set_placement_from_screen", '''func _set_placement_from_screen(screen_pos: Vector2) -> void:
	BuildingSystem.set_placement_from_screen(self, screen_pos)''')
replace_func("_placement_valid", '''func _placement_valid(pos: Vector2) -> bool:
	return BuildingSystem.placement_valid(self, pos)''')
replace_func("_place_build", '''func _place_build() -> void:
	BuildingSystem.place_build(self)''')
replace_func("_cancel_placement", '''func _cancel_placement() -> void:
	BuildingSystem.cancel_placement(self)''')

# Context hint is derived by the interaction contract.
replace_func("_update_context_hint", '''func _update_context_hint() -> void:
	contextual_hint = InteractionSystem.interaction_label(self)''')

# Safe persistence wrappers + dirty state.
replace_func("_save_game", '''func _mark_dirty(reason: String = "") -> void:
	save_dirty = true
	if reason != "":
		last_dirty_reason = reason

func _save_game(force: bool = false) -> bool:
	if save_blocked:
		return false
	if not force and not save_dirty:
		return true
	var result: Dictionary = SaveSystem.save_state(GameState.snapshot(self))
	if bool(result.get("ok", false)):
		save_dirty = false
		return true
	if String(result.get("error", "")) == "primary_invalid_preserved":
		save_blocked = true
		save_block_reason = String(result.get("detail", "invalid_primary"))
		_set_major("Save inválido protegido · guardado bloqueado", 3.5)
	return false''')
replace_func("_load_game", '''func _load_game() -> bool:
	var result: Dictionary = SaveSystem.load_state()
	if not bool(result.get("ok", false)):
		return false
	return GameState.apply(self, result.get("data", {}))''')

# Nearby building lookup instead of global building scan.
replace_func("_position_blocked", '''func _position_blocked(pos: Vector2, radius: float) -> bool:
	var cc := _chunk_coord(pos)
	for y in range(cc.y - 1, cc.y + 2):
		for x in range(cc.x - 1, cc.x + 2):
			var key := _chunk_key(Vector2i(x, y))
			if not loaded_chunks.has(key):
				continue
			var chunk: Dictionary = loaded_chunks[key]
			for r_variant in chunk["resources"]:
				var r: Dictionary = r_variant
				var rr := _resource_collision_radius(String(r["type"]))
				if rr > 0.0 and (r["pos"] as Vector2).distance_squared_to(pos) < (rr + radius) * (rr + radius):
					return true
	for b_variant in spatial_index.nearby_buildings(buildings, pos, 72.0):
		var b: Dictionary = b_variant
		if _building_blocks_circle(b, pos, radius):
			return true
	return false''')

# Y-sorted entity drawing while retaining procedural sprite methods.
replace_func("_draw", '''func _draw() -> void:
	_draw_terrain()
	WorldRenderer.draw_entities(self)
	_draw_particles()
	_draw_weather()
	_draw_hud()
	if placement_type != "":
		_draw_placement_preview()
	if menu_mode != "":
		_draw_menu()
	_draw_floaters()''')
for name in ["_draw_resources", "_draw_buildings", "_draw_enemies"]:
    replace_func(name, "")

# Centralize keyboard actions, leave mobile/touch branch unchanged.
pattern = re.compile(r"(?ms)(^func _input\(event: InputEvent\) -> void:\n)(\tif event is InputEventKey.*?)(?=\tif event is InputEventScreenTouch:)")
matches = list(pattern.finditer(text))
if len(matches) != 1:
    raise RuntimeError(f"input key block expected once, found {len(matches)}")
keyboard = '''\tif event is InputEventKey and event.pressed and not event.echo:
		var action := InputActions.event_action(event)
		match action:
			"attack": _request_attack()
			"interact": _interact()
			"inventory": _open_backpack("inventory")
			"craft": _open_backpack("craft")
			"build": _open_backpack("build")
			"map": _open_map()
			"eat": _eat()
			"bandage": _use_bandage()
			"cancel":
				if placement_type != "": _cancel_placement()
				else: _close_menu()
			_:
				# Nuevo mundo por teclado queda deliberadamente deshabilitado para proteger saves.
				if DEBUG_ALLOW_NEW_WORLD_SHORTCUT and event.keycode == KEY_N:
					_set_major("Nuevo mundo debug bloqueado en build estable", 2.0)
'''
m = matches[0]
text = text[:m.start(2)] + keyboard + text[m.end(2):]

# Header clarifies new responsibility.
text = text.replace("# Ceniza Salvaje v0.3 — Core Survival Pass\n# Objetivo: game feel, restricciones, economia, inventario/equipamiento,\n# construccion movil, cofres, colisiones, zona segura, mapa y onboarding.\n",
                    "# Ceniza Salvaje v0.3 — Runtime Orchestrator estabilizado\n# Coordina sistemas modulares; conserva dibujo procedural y UI del vertical slice.\n", 1)

if text == original:
    raise RuntimeError("no changes produced")
PATH.write_text(text, encoding="utf-8")
print(f"v03.gd lines before={len(original.splitlines())} after={len(text.splitlines())}")
print("stabilization transform complete")
