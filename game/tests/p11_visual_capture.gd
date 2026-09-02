extends SceneTree

const MAIN_SCENE = preload("res://main.tscn")

var game_state: Node
var capture_available := true

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	# The CI Godot binary uses the dummy headless renderer. Keep exercising the
	# runtime flow, but do not call ViewportTexture.get_image() there because the
	# dummy backend has no texture RID. A graphical run can capture normally.
	if OS.has_feature("headless") or DisplayServer.get_name().to_lower().contains("headless"):
		capture_available = false
	game_state = root.get_node_or_null("GameState")
	if game_state == null:
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://../tmp/p11_visual"))
	game_state.call("new_game", "Liria", "CLASS_WARRIOR")
	var main = MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	_capture("menu")
	main._show_creation()
	await process_frame
	_capture("creation")
	main._show_world()
	await physics_frame
	await physics_frame
	_capture("liria")
	var player: PlayerController = main.player
	var iria: VillageNpc = main.world.get_npc("NPC_IRIA")
	for _frame in range(40):
		if player.current_interaction_target != null and player.current_interaction_target.target_id == iria.actor_id:
			break
		player.set_virtual_input(player.global_position.direction_to(iria.global_position))
		await physics_frame
	player.set_virtual_input(Vector2.ZERO)
	await physics_frame
	if player.current_interaction_target != null:
		main.hud.interact_button.emit_signal("pressed")
		await process_frame
	_capture("dialogue")
	main.dialogue._close()
	await create_timer(0.22).timeout
	game_state.call("add_item", "ITEM_LANTERN", 1)
	main.hud.toggle_inventory()
	await process_frame
	_capture("inventory")
	main.queue_free()
	print("P11_VISUAL_CAPTURE=PASS" if capture_available else "P11_VISUAL_CAPTURE=SKIP_NO_RENDERER")
	quit(0)

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
	if image.save_png(ProjectSettings.globalize_path("res://../tmp/p11_visual/" + name + ".png")) != OK:
		capture_available = false
