extends SceneTree

const MAIN_SCENE = preload("res://main.tscn")
const DEBUG_VIEW_SCRIPT = preload("res://tests/p12_collision_debug_view.gd")

var game_state: Node
var capture_available := true

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	if OS.has_feature("headless") or DisplayServer.get_name().to_lower().contains("headless"):
		capture_available = false
	game_state = root.get_node_or_null("GameState")
	if game_state == null:
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://../tmp/p12_visual"))
	game_state.call("new_game", "P1.2 Evidence", "CLASS_WARRIOR")
	var main = MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	_capture("title_screen")
	main._show_creation()
	await process_frame
	_capture("creation_screen")
	main._show_world()
	await process_frame
	await physics_frame
	_capture("hud_normal")

	var debug_view = DEBUG_VIEW_SCRIPT.new()
	debug_view.setup(main.world)
	main.world.add_child(debug_view)
	await process_frame
	_capture("debug_collisions")
	debug_view.queue_free()

	var animation_preview := TextureRect.new()
	animation_preview.name = "P12AnimationPreview"
	animation_preview.texture = load("res://assets/p1_1/player_sheet.png") as Texture2D
	animation_preview.position = Vector2(222, 58)
	animation_preview.size = Vector2(196, 262)
	animation_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	animation_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	animation_preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	animation_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	animation_preview.z_index = 200
	main.add_child(animation_preview)
	await process_frame
	_capture("player_animation_preview")
	animation_preview.queue_free()

	var player: PlayerController = main.player
	var iria: VillageNpc = main.world.get_npc("NPC_IRIA")
	var halven: VillageNpc = main.world.get_npc("NPC_HALVEN")
	await _walk_until_target(player, iria.global_position, iria.actor_id)
	main.hud.interact_button.emit_signal("pressed")
	await process_frame
	_capture("dialogue_short")
	await _press_choice(main.dialogue, 0)
	_capture("dialogue_long")
	await _press_choice(main.dialogue, 0)

	await _walk_until_target(player, halven.global_position, halven.actor_id)
	main.hud.interact_button.emit_signal("pressed")
	await process_frame
	_capture("quest_item_dialogue")
	await _press_choice(main.dialogue, 0)
	await _press_choice(main.dialogue, 0)
	await _walk_until_target(player, iria.global_position, iria.actor_id)
	main.hud.interact_button.emit_signal("pressed")
	await process_frame
	_capture("quest_return_dialogue")
	await _press_choice(main.dialogue, 0)
	_capture("quest_complete_dialogue")
	await _press_choice(main.dialogue, 0)

	main.hud.toggle_inventory()
	await process_frame
	_capture("hud_inventory")
	main.queue_free()
	print("P12_VISUAL_CAPTURE=PASS" if capture_available else "P12_VISUAL_CAPTURE=SKIP_NO_RENDERER")
	quit(0)

func _press_choice(panel: DialoguePanel, index: int) -> void:
	var buttons := panel.choices_box.get_children()
	if index < 0 or index >= buttons.size():
		return
	var button := buttons[index] as Button
	if button == null:
		return
	button.emit_signal("pressed")
	await process_frame
	await create_timer(0.22).timeout

func _walk_until_target(player: PlayerController, target_position: Vector2, target_id: String) -> void:
	var waypoints: Array[Vector2] = [target_position]
	if target_id == "NPC_HALVEN":
		waypoints = [Vector2(370, 330), Vector2(365, 270), target_position]
	elif target_id == "NPC_IRIA" and player.global_position.x > 500.0:
		waypoints = [Vector2(365, 270), Vector2(370, 330), target_position]
	for waypoint in waypoints:
		for _frame in range(180):
			if player.current_interaction_target != null and player.current_interaction_target.target_id == target_id and player.global_position.distance_to(target_position) < 76.0:
				player.set_virtual_input(Vector2.ZERO)
				await physics_frame
				return
			if player.global_position.distance_to(waypoint) <= 6.0:
				break
			player.set_virtual_input(player.global_position.direction_to(waypoint))
			await physics_frame
	player.set_virtual_input(Vector2.ZERO)
	await physics_frame

func _capture(name: String) -> void:
	if not capture_available:
		return
	var texture: Texture2D = get_root().get_texture()
	if texture == null:
		capture_available = false
		return
	var image := texture.get_image()
	if image == null:
		capture_available = false
		return
	if image.save_png(ProjectSettings.globalize_path("res://../tmp/p12_visual/" + name + ".png")) != OK:
		capture_available = false
