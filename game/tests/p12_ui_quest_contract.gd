extends SceneTree

const MAIN_SCENE = preload("res://main.tscn")

var failures: Array[String] = []
var game_state: Node

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	game_state = root.get_node_or_null("GameState")
	_check(game_state != null, "GameState autoload available")
	if game_state == null:
		quit(1)
		return
	game_state.call("new_game", "P1.2 UI", "CLASS_WARRIOR")
	var main = MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	_check(main.mode == "menu", "title screen opens first")
	main._show_world()
	await process_frame
	await physics_frame
	_check(main.dialogue.get_parent() == main.hud.root_control, "dialogue lives inside safe content")
	_check(main.dialogue.get_global_rect().size.x > 0.0, "dialogue has a laid out width")
	var player: PlayerController = main.player
	var iria: VillageNpc = main.world.get_npc("NPC_IRIA")
	await _walk_to(player, iria.global_position, iria.actor_id)
	_check(not main.hud.interact_button.disabled, "Iria interaction is reachable")
	main.hud.interact_button.emit_signal("pressed")
	await process_frame
	_check(main.dialogue.visible, "short dialogue opens")
	_check(not main.hud.joystick.visible and not main.hud.interact_button.visible, "touch controls hide during dialogue")
	_check(not main.hud.quest_panel.visible and not main.hud.actions.visible, "quest/actions hide during dialogue")
	await _press_choice(main.dialogue, 0)
	_check(String(game_state.call("quest_status", "MQ00_01")) == "ACTIVE", "dialogue starts MQ00_01")
	await _press_choice(main.dialogue, 0)
	_check(not main.dialogue.visible, "dialogue closes from terminal choice")
	_check(main.hud.joystick.visible and main.hud.interact_button.visible, "touch controls return after dialogue")
	_check(main.hud.quest_panel.visible and main.hud.actions.visible, "quest/actions return after dialogue")
	main.queue_free()
	if failures.is_empty():
		print("P12_UI_QUEST_CONTRACT=PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("P12_UI_QUEST_CONTRACT=FAIL")
	quit(1)

func _walk_to(player: PlayerController, target_position: Vector2, target_id: String) -> void:
	for _frame in range(180):
		if player.current_interaction_target != null and player.current_interaction_target.target_id == target_id and player.global_position.distance_to(target_position) < 76.0:
			player.set_virtual_input(Vector2.ZERO)
			await physics_frame
			return
		player.set_virtual_input(player.global_position.direction_to(target_position))
		await physics_frame
	player.set_virtual_input(Vector2.ZERO)
	await physics_frame

func _press_choice(panel: DialoguePanel, index: int) -> void:
	var buttons := panel.choices_box.get_children()
	_check(index >= 0 and index < buttons.size(), "dialogue choice is rendered")
	if index < 0 or index >= buttons.size():
		return
	var button := buttons[index] as Button
	_check(button != null, "dialogue choice is a touch button")
	if button == null:
		return
	button.emit_signal("pressed")
	await process_frame
	await create_timer(0.22).timeout

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
