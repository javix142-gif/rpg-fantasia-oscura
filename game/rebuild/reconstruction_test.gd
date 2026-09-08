extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS ", label)
	else:
		print("FAIL ", label)
		failures.append(label)

func _run() -> void:
	var packed: PackedScene = load("res://rebuild/main.tscn") as PackedScene
	_check(packed != null, "scene_load")
	if packed == null:
		quit(1)
		return
	var main: Variant = packed.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	_check(main != null, "main_instance")
	_check(main.player != null, "player_created")
	_check(main.world != null, "world_created")
	_check(main.hud != null, "hud_created")
	main.start_new_game()
	await process_frame
	var initial: Dictionary = main.debug_state()
	_check(String(initial.get("zone", "")) == "liria", "f2_base_liria")
	_check(int(initial.get("npc_count", 0)) >= 4, "liria_npcs")
	_check(int(initial.get("blockers", 0)) >= 5, "m5_liria_visual_collision_data")
	var sprite: AnimatedSprite2D = main.player.get_node_or_null("AnimatedSprite") as AnimatedSprite2D
	_check(sprite != null, "m4_player_animated_sprite")
	if sprite != null:
		_check(sprite.sprite_frames.has_animation("attack_S"), "m4_attack_animation")
		_check(sprite.sprite_frames.has_animation("dodge_S"), "m4_dodge_animation")
		_check(sprite.sprite_frames.has_animation("hit_S"), "m4_hit_animation")
		_check(sprite.sprite_frames.has_animation("death_S"), "m4_death_animation")
	_check(bool(main.player.request_attack()), "f2_melee_request")
	_check(String(main.player.state) == "attack", "f2_melee_state")
	main.player._action_timer = 0.0
	main.player._set_state("idle", true)
	_check(bool(main.player.request_dodge()), "f2_dodge_request")
	_check(float(main.player.invulnerable) > 0.0, "f2_dodge_iframes")
	main.player._action_timer = 0.0
	main.player._set_state("idle", true)
	# The dodge test above intentionally creates i-frames. End that isolated
	# condition before validating ordinary damage; otherwise the damage check
	# would be testing dodge immunity rather than the normal hit path.
	main.player.invulnerable = 0.0
	var before_hp: int = int(main.player.hp)
	main.player.take_damage(12, main.player.global_position + Vector2(20, 0))
	_check(int(main.player.hp) == before_hp - 12, "f2_damage")
	main.player.invulnerable = 0.0
	var healed: int = int(main.player.heal(35))
	_check(healed > 0, "f2_heal")
	main.event_locked = true
	_check(not bool(main.call("_save_game", true)), "f3_save_blocked_during_event")
	main.event_locked = false
	var zones: Array[String] = ["liria_ruinas", "camino", "ceniza", "ruina_exterior", "ruina_interior"]
	for zone: String in zones:
		main.debug_load_zone(zone)
		await process_frame
		var state: Dictionary = main.debug_state()
		_check(String(state.get("zone", "")) == zone, "zone_" + zone)
		_check(int(state.get("blockers", 0)) > 0, "m5_blockers_" + zone)
	_check(main.enemies.size() == 1, "f4_boss_spawned")
	if main.enemies.size() == 1:
		var boss: Variant = main.enemies[0]
		_check(bool(boss.is_boss), "f4_boss_flag")
		boss.hp = int(boss.max_hp) / 2
		boss._physics_process(0.016)
		_check(int(boss.phase) == 2, "f4_boss_phase2")
	var hud_root: Control = main.hud.root as Control
	_check(hud_root != null, "m6_safe_hud_root")
	var joystick: Control = hud_root.get_node_or_null("Joystick") as Control if hud_root != null else null
	_check(joystick != null, "m6_joystick_present")
	if joystick != null:
		var inside: bool = joystick.position.x >= 0.0 and joystick.position.y >= 0.0 and joystick.position.x + joystick.size.x <= 640.0 and joystick.position.y + joystick.size.y <= 360.0
		_check(inside, "m6_joystick_in_viewport")
	_check(bool(main.call("_save_game", true)), "f5_save")
	_check(FileAccess.file_exists("user://reconstructed_slice_v1.json"), "f5_save_file")
	if failures.is_empty():
		print("RECONSTRUCTION_M4_M6_TEST=PASS")
		quit(0)
	else:
		print("RECONSTRUCTION_M4_M6_TEST=FAIL count=", failures.size())
		quit(1)
