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
	game_state.call("new_game", "P1.3 Quest Flow", "CLASS_WARRIOR")
	var main = MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	main._show_world()
	await process_frame
	await physics_frame
	var player: PlayerController = main.player
	var world: VillageWorld = main.world
	var iria: VillageNpc = world.get_npc("NPC_IRIA")
	var halven: VillageNpc = world.get_npc("NPC_HALVEN")
	_check(iria != null and halven != null, "quest actors exist")
	if iria == null or halven == null:
		main.queue_free()
		quit(1)
		return

	await _walk_until_target(player, iria.global_position, iria.actor_id)
	_check(player.current_interaction_target != null and player.current_interaction_target.target_id == "NPC_IRIA", "Iria is reachable from spawn")
	main.hud.interact_button.emit_signal("pressed")
	await process_frame
	_check(main.dialogue.visible, "Iria opens the introduction dialogue")
	await _press_choice(main.dialogue, 0)
	_check(String(game_state.call("quest_status", "MQ00_01")) == "ACTIVE", "Iria starts MQ00_01")
	_check(int(game_state.call("quest_stage", "MQ00_01")) == 1, "Iria sets the first objective stage")
	await _press_choice(main.dialogue, 0)
	_check(not main.dialogue.visible, "introduction dialogue closes")

	await _walk_until_target(player, halven.global_position, halven.actor_id)
	_check(player.current_interaction_target != null and player.current_interaction_target.target_id == "NPC_HALVEN", "Halven is reachable through the north corridor")
	main.hud.interact_button.emit_signal("pressed")
	await process_frame
	_check(main.dialogue.visible, "Halven opens the lantern dialogue")
	await _press_choice(main.dialogue, 0)
	_check(int(game_state.call("item_quantity", "ITEM_LANTERN")) == 1, "Halven gives the lantern")
	_check(int(game_state.call("quest_stage", "MQ00_01")) == 3, "lantern delivery stage is explicit")
	_check(main.hud.quest_objective.text == "Regresa con Iria y entrega la linterna.", "tracker immediately explains the return step")
	await _press_choice(main.dialogue, 0)
	_check(not main.dialogue.visible, "Halven dialogue closes")

	await _walk_until_target(player, iria.global_position, iria.actor_id)
	_check(player.current_interaction_target != null and player.current_interaction_target.target_id == "NPC_IRIA", "Iria is reachable again after receiving the lantern")
	main.hud.interact_button.emit_signal("pressed")
	await process_frame
	_check(main.dialogue.visible, "Iria opens the delivery dialogue")
	await _press_choice(main.dialogue, 0)
	_check(String(game_state.call("quest_status", "MQ00_01")) == "COMPLETE", "Iria completes MQ00_01")
	_check(int(game_state.call("item_quantity", "ITEM_LANTERN")) == 0, "delivered lantern is removed from inventory")
	_check(main.dialogue.current_node_id == "complete", "completion feedback dialogue is shown")
	await _press_choice(main.dialogue, 0)
	await create_timer(0.22).timeout
	_check(not main.dialogue.visible, "completion dialogue closes")
	_check(main.hud.quest_objective.text == "Explora Liria.", "completed quest leaves a clear next activity")
	_check(main.hud.feedback_title.text == "MISIÓN COMPLETADA", "completion toast is presented")
	_check(main.hud.feedback_detail.text == "Explora Liria.", "completion toast explains the next activity")
	_check(iria.quest_marker.marker_kind.is_empty(), "Iria marker clears after completion")
	_check(halven.quest_marker.marker_kind.is_empty(), "Halven marker clears after completion")

	var saved_position := player.global_position
	game_state.call("set_position", saved_position)
	var save_service := root.get_node_or_null("SaveService")
	_check(save_service != null and bool(save_service.call("save_slot", "slot_02")), "completed quest saves")
	game_state.call("set_position", Vector2(64, 64))
	_check(save_service != null and bool(save_service.call("load_slot", "slot_02")), "completed quest loads")
	_check((game_state.call("get_position") as Vector2).is_equal_approx(saved_position), "load restores player position")
	_check(String(game_state.call("quest_status", "MQ00_01")) == "COMPLETE", "load preserves completed quest")
	_check(int(game_state.call("item_quantity", "ITEM_LANTERN")) == 0, "load preserves delivered item state")
	main.queue_free()
	if failures.is_empty():
		print("P13_QUEST_FLOW_CONTRACT=PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("P13_QUEST_FLOW_CONTRACT=FAIL")
	quit(1)

func _press_choice(panel: DialoguePanel, index: int) -> void:
	var buttons := panel.choices_box.get_children()
	_check(index >= 0 and index < buttons.size(), "quest dialogue choice is rendered")
	if index < 0 or index >= buttons.size():
		return
	var button := buttons[index] as Button
	_check(button != null, "quest dialogue choice is a button")
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

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
