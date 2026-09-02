extends SceneTree

const MAIN_SCENE = preload("res://main.tscn")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var state := root.get_node_or_null("GameState")
	_check(state != null, "GameState autoload available")
	if state == null:
		quit(1)
		return
	state.call("new_game", "P1.3 Quest", "CLASS_WARRIOR")
	var main = MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	main._show_world()
	await process_frame
	await physics_frame
	var iria: VillageNpc = main.world.get_npc("NPC_IRIA")
	var halven: VillageNpc = main.world.get_npc("NPC_HALVEN")
	_check(main.hud.quest_target == iria, "stage 0 target is Iria")
	_check(iria.quest_marker.marker_kind == "!", "Iria has the stage 0 marker")
	_check(main.hud.quest_objective.text == "Habla con Iria en la plaza.", "stage 0 objective is actionable")

	state.call("start_quest", "MQ00_01")
	await process_frame
	_check(main.hud.quest_target == halven, "stage 1 target is Halven")
	_check(halven.quest_marker.marker_kind == "!", "Halven has the delivery marker")
	_check(main.hud.quest_objective.text == "Visita a Halven, al este de la plaza.", "stage 1 objective names destination")

	state.call("add_item", "ITEM_LANTERN", 1)
	state.call("set_flag", "MQ00_01_ITEM_RECEIVED", true)
	state.call("advance_quest", "MQ00_01", 3)
	await process_frame
	_check(main.hud.quest_target == iria, "stage 3 target returns to Iria")
	_check(iria.quest_marker.marker_kind == "?", "Iria uses the return marker")
	_check(main.hud.quest_objective.text == "Regresa con Iria y entrega la linterna.", "stage 3 objective names return and delivery")

	main.player.global_position = Vector2(48, 48)
	main.hud.refresh_quest()
	_check(main.hud.quest_arrow_panel.visible, "offscreen target guidance is visible")
	_check(not main.hud.quest_arrow_label.text.is_empty(), "offscreen guidance names target")

	_check(bool(state.call("complete_quest", "MQ00_01")), "quest can enter complete state")
	state.call("remove_item", "ITEM_LANTERN", 1)
	await process_frame
	_check(main.hud.quest_target == null, "complete quest removes target marker")
	_check(iria.quest_marker.marker_kind.is_empty() and halven.quest_marker.marker_kind.is_empty(), "complete quest clears all markers")
	_check(main.hud.quest_objective.text == "Explora Liria.", "complete quest leaves a clear next activity")
	main.queue_free()
	if failures.is_empty():
		print("P13_QUEST_GUIDANCE_CONTRACT=PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("P13_QUEST_GUIDANCE_CONTRACT=FAIL")
	quit(1)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
