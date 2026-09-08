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
	var packed := load("res://rebuild/main.tscn") as PackedScene
	_check(packed != null, "scene_load")
	if packed == null:
		quit(1); return
	var main = packed.instantiate()
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
	_check(initial["zone"] == "liria", "f2_base_liria")
	_check(int(initial["npc_count"]) >= 4, "liria_npcs")
	_check(int(initial["blockers"]) >= 5, "m5_liria_visual_collision_data")
	var sprite := main.player.get_node_or_null("AnimatedSprite") as AnimatedSprite2D
	_check(sprite != null, "m4_player_animated_sprite")
	if sprite != null:
		_check(sprite.sprite_frames.has_animation("attack_S"), "m4_attack_animation")
		_check(sprite.sprite_frames.has_animation("dodge_S"), "m4_dodge_animation")
		_check(sprite.sprite_frames.has_animation("hit_S"), "m4_hit_animation")
		_check(sprite.sprite_frames.has_animation("death_S"), "m4_death_animation")
	_check(main.player.request_attack(), "f2_melee_request")
	_check(main.player.state == "attack", "f2_melee_state")
	main.player._action_timer = 0.0
	main.player._set_state("idle", true)
	_check(main.player.request_dodge(), "f2_dodge_request")
	_check(main.player.invulnerable > 0.0, "f2_dodge_iframes")
	main.player._action_timer = 0.0
	main.player._set_state("idle", true)
	var before_hp: int = main.player.hp
	main.player.take_damage(12, main.player.global_position + Vector2(20,0))
	_check(main.player.hp == before_hp - 12, "f2_damage")
	main.player.invulnerable = 0.0
	var healed := main.player.heal(35)
	_check(healed > 0, "f2_heal")
	main.event_locked = true
	_check(not bool(main.call("_save_game", true)), "f3_save_blocked_during_event")
	main.event_locked = false
	for zone in ["liria_ruinas", "camino", "ceniza", "ruina_exterior", "ruina_interior"]:
		main.debug_load_zone(zone)
		await process_frame
		var state: Dictionary = main.debug_state()
		_check(state["zone"] == zone, "zone_" + zone)
		_check(int(state["blockers"]) > 0, "m5_blockers_" + zone)
	_check(main.enemies.size() == 1, "f4_boss_spawned")
	if main.enemies.size() == 1:
		var boss = main.enemies[0]
		_check(boss.is_boss, "f4_boss_flag")
		boss.hp = boss.max_hp / 2
		boss._physics_process(0.016)
		_check(boss.phase == 2, "f4_boss_phase2")
	var hud_root := main.hud.root as Control
	_check(hud_root != null, "m6_safe_hud_root")
	var joystick := hud_root.get_node_or_null("Joystick") as Control
	_check(joystick != null, "m6_joystick_present")
	if joystick != null:
		_check(joystick.position.x >= 0 and joystick.position.y >= 0 and joystick.position.x + joystick.size.x <= 640 and joystick.position.y + joystick.size.y <= 360, "m6_joystick_in_viewport")
	_check(main.call("_save_game", true), "f5_save")
	_check(FileAccess.file_exists("user://reconstructed_slice_v1.json"), "f5_save_file")
	if failures.is_empty():
		print("RECONSTRUCTION_M4_M6_TEST=PASS")
		quit(0)
	else:
		print("RECONSTRUCTION_M4_M6_TEST=FAIL count=", failures.size())
		quit(1)
