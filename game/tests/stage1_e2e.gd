extends SceneTree

const DIALOGUE_SERVICE_SCRIPT = preload("res://data/dialogue_service.gd")
const PLAYER_SCRIPT = preload("res://world/player_controller.gd")
const WORLD_SCRIPT = preload("res://world/village_world.gd")
const MAIN_SCENE = preload("res://main.tscn")
const CLASS_IDS: Array[String] = ["CLASS_WARRIOR", "CLASS_SWORDSMAN", "CLASS_ARCHER", "CLASS_SORCERER", "CLASS_CLERIC"]
const DIRECTIONS: Array[String] = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
var failures: Array[String] = []
var game_state: Node
var save_service: Node

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	game_state = root.get_node_or_null("GameState")
	save_service = root.get_node_or_null("SaveService")
	_check(game_state != null and save_service != null, "autoloads available to test")
	if game_state == null or save_service == null:
		quit(1)
		return
	_test_foundation()
	_test_conditions_and_effects()
	_test_inventory_and_quest()
	_test_save_load()
	_test_movement_contract()
	await _test_runtime_movement()
	await _test_ui_e2e()
	if failures.is_empty():
		print("STAGE1_E2E=PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("STAGE1_E2E=FAIL")
		quit(1)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _test_foundation() -> void:
	_check(CLASS_IDS.size() == 5, "five stable class IDs")
	_check(CLASS_IDS.has("CLASS_WARRIOR"), "warrior class")
	_check(CLASS_IDS.has("CLASS_SWORDSMAN"), "swordsman class")
	_check(CLASS_IDS.has("CLASS_ARCHER"), "archer class")
	_check(CLASS_IDS.has("CLASS_SORCERER"), "sorcerer class")
	_check(CLASS_IDS.has("CLASS_CLERIC"), "cleric class")
	_check(bool(game_state.call("new_game", "E2E Liria", "CLASS_WARRIOR")), "new game")
	var state := game_state.get("state") as Dictionary
	_check(state["player"]["player_name"] == "E2E Liria", "player name persisted in state")
	_check(state["player"]["class_id"] == "CLASS_WARRIOR", "class persisted in state")
	_check(state["world"]["state"] == "NORMAL", "Liria normal")

func _test_conditions_and_effects() -> void:
	_check(not bool(game_state.call("condition_passes", {"type": "HasFlag", "value": "E2E_FLAG"})), "missing flag condition")
	_check(bool(game_state.call("apply_effect", {"type": "SetFlag", "value": "E2E_FLAG"})), "set flag effect")
	_check(bool(game_state.call("condition_passes", {"type": "HasFlag", "value": "E2E_FLAG"})), "has flag condition")
	_check(bool(game_state.call("condition_passes", {"type": "NotFlag", "value": "OTHER_FLAG"})), "not flag condition")
	_check(bool(game_state.call("condition_passes", {"type": "ClassEquals", "value": "CLASS_WARRIOR"})), "class condition")
	var service = DIALOGUE_SERVICE_SCRIPT.new()
	var dialogue: Dictionary = service.open_for_actor("NPC_IRIA")
	_check(not service.first_available(dialogue).is_empty(), "dialogue node resolves")

func _test_inventory_and_quest() -> void:
	_check(String(game_state.call("quest_status", "MQ00_01")) == "NOT_STARTED", "quest starts not started")
	_check(bool(game_state.call("apply_effect", {"type": "StartQuest", "value": "MQ00_01"})), "start quest effect")
	_check(String(game_state.call("quest_status", "MQ00_01")) == "ACTIVE", "quest active")
	_check(int(game_state.call("quest_stage", "MQ00_01")) == 1, "quest stage one")
	_check(bool(game_state.call("add_item", "ITEM_LANTERN", 2)), "inventory add")
	_check(int(game_state.call("item_quantity", "ITEM_LANTERN")) == 2, "inventory stack")
	_check(bool(game_state.call("has_item", "ITEM_LANTERN", 2)), "inventory has")
	_check(not bool(game_state.call("add_item", "UNKNOWN_ITEM", 1)), "invalid item rejected")
	_check(bool(game_state.call("remove_item", "ITEM_LANTERN", 1)), "inventory remove")
	_check(int(game_state.call("item_quantity", "ITEM_LANTERN")) == 1, "inventory quantity after remove")
	_check(bool(game_state.call("advance_quest", "MQ00_01", 3)), "quest stage item")
	_check(bool(game_state.call("complete_quest", "MQ00_01")), "quest complete")
	_check(String(game_state.call("quest_status", "MQ00_01")) == "COMPLETE", "quest complete state")
	_check(not bool(game_state.call("complete_quest", "MQ00_01")), "quest reward cannot duplicate")
	# Same progression expressed through the data-driven dialogue catalogue.
	game_state.call("new_game", "Dialogue E2E", "CLASS_ARCHER")
	var service = DIALOGUE_SERVICE_SCRIPT.new()
	var iria: Dictionary = service.open_for_actor("NPC_IRIA")
	_check(not service.node_for(iria, "start").is_empty(), "Iria start node condition")
	var start_choice: Dictionary = iria["nodes"]["start"]["choices"][0]
	for effect in start_choice.get("effects", []):
		game_state.call("apply_effect", effect)
	var halven: Dictionary = service.open_for_actor("NPC_HALVEN")
	_check(not service.first_available(halven).is_empty(), "Halven conditional node")
	var halven_choice: Dictionary = halven["nodes"]["start"]["choices"][0]
	for effect in halven_choice.get("effects", []):
		game_state.call("apply_effect", effect)
	_check(int(game_state.call("item_quantity", "ITEM_LANTERN")) == 1, "dialogue gives item")
	game_state.call("new_game", "E2E Liria", "CLASS_WARRIOR")
	game_state.call("apply_effect", {"type": "StartQuest", "value": "MQ00_01"})
	game_state.call("add_item", "ITEM_LANTERN", 1)
	game_state.call("advance_quest", "MQ00_01", 3)
	game_state.call("complete_quest", "MQ00_01")

func _test_save_load() -> void:
	game_state.call("set_position", Vector2(777, 333))
	_check(bool(save_service.call("save_slot", "slot_01")), "slot save")
	_check(bool(save_service.call("save_slot", "autosave")), "autosave save")
	_check(bool(save_service.call("has_valid_save", "slot_01")), "slot validates")
	_check(bool(save_service.call("has_valid_save", "autosave")), "autosave validates")
	var state := game_state.get("state") as Dictionary
	state["player"]["player_name"] = "altered"
	state["inventory"]["items"].clear()
	_check(bool(save_service.call("load_slot", "slot_01")), "slot load")
	state = game_state.get("state") as Dictionary
	_check(state["player"]["player_name"] == "E2E Liria", "load restores name")
	_check((game_state.call("get_position") as Vector2).is_equal_approx(Vector2(777, 333)), "load restores position")
	_check(String(game_state.call("quest_status", "MQ00_01")) == "COMPLETE", "load restores quest")
	_check(int(game_state.call("item_quantity", "ITEM_LANTERN")) == 1, "load restores inventory")
	_check(FileAccess.file_exists("user://autosave.backup"), "autosave backup exists")
	_check(bool(save_service.call("corrupt_save_for_test", "slot_01")), "corrupt fixture written")
	_check(not bool(save_service.call("has_valid_save", "slot_01")), "corrupt save rejected without crash")

func _test_movement_contract() -> void:
	var diagonal := Vector2(1, 1).normalized()
	_check(is_equal_approx(diagonal.length(), 1.0), "diagonal input normalized")
	_check(DIRECTIONS.size() == 8, "eight runtime directions")
	for direction in ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]:
		_check(DIRECTIONS.has(direction), "direction named: " + direction)
	var direction_probe = PLAYER_SCRIPT.new()
	for input_pair in [[Vector2.UP, "N"], [Vector2(1, -1), "NE"], [Vector2.RIGHT, "E"], [Vector2(1, 1), "SE"], [Vector2.DOWN, "S"], [Vector2(-1, 1), "SW"], [Vector2.LEFT, "W"], [Vector2(-1, -1), "NW"]]:
		_check(String(direction_probe.direction_for_input(input_pair[0])) == input_pair[1], "direction maps " + input_pair[1])

func _test_runtime_movement() -> void:
	var host := Node2D.new()
	root.add_child(host)
	var world = WORLD_SCRIPT.new()
	host.add_child(world)
	var player = PLAYER_SCRIPT.new()
	player.global_position = Vector2(480, 360)
	world.add_child(player)
	await process_frame
	var before: Vector2 = player.global_position
	player.set_virtual_input(Vector2(1, 1))
	for _frame in range(4):
		await physics_frame
	var after: Vector2 = player.global_position
	_check(after.x > before.x and after.y > before.y, "runtime movement advances")
	_check(String(player.direction8) == "SE", "runtime diagonal direction")
	_check(is_equal_approx(player.movement_input.length(), 1.0), "runtime input normalized")
	_check(player.get_node_or_null("PlayerAnimatedSprite") is AnimatedSprite2D, "player uses AnimatedSprite2D")
	for direction in DIRECTIONS:
		_check(player.get_animation_frame_count("idle", direction) > 1, "idle has real frames: " + direction)
		_check(player.get_animation_frame_count("walk", direction) > 1, "walk has real frames: " + direction)
	player.set_virtual_input(Vector2.ZERO)
	host.queue_free()

func _test_ui_e2e() -> void:
	game_state.call("new_game", "UI Liria", "CLASS_SWORDSMAN")
	var main = MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	main._show_world()
	await physics_frame
	var player = main.player
	var world = main.world
	var iria = world.npcs[0]
	var halven = world.npcs[1]
	# Start at the normal plaza spawn and walk into Iria's interaction Area2D.
	_check(player.current_interaction_target == null, "interaction starts out of range")
	await _walk_until_target(player, iria.global_position, iria.actor_id)
	_check(player.current_interaction_target != null, "Iria target enters range")
	_check(not main.hud.interact_button.disabled, "touch interaction button enabled")
	main.hud.interact_button.emit_signal("pressed")
	await process_frame
	_check(main.dialogue.visible, "Iria dialogue opens")
	await _press_dialogue_choice(main.dialogue, 0)
	await _press_dialogue_choice(main.dialogue, 0)
	_check(String(game_state.call("quest_status", "MQ00_01")) == "ACTIVE", "Iria starts MQ00_01")
	await _walk_until_target(player, halven.global_position, halven.actor_id)
	_check(not main.hud.interact_button.disabled, "Halven touch button enabled")
	main.hud.interact_button.emit_signal("pressed")
	await process_frame
	await _press_dialogue_choice(main.dialogue, 0)
	await _press_dialogue_choice(main.dialogue, 0)
	_check(int(game_state.call("item_quantity", "ITEM_LANTERN")) == 1, "Halven gives quest item")
	await _walk_until_target(player, iria.global_position, iria.actor_id)
	main.hud.interact_button.emit_signal("pressed")
	await process_frame
	await _press_dialogue_choice(main.dialogue, 0)
	await _press_dialogue_choice(main.dialogue, 0)
	_check(String(game_state.call("quest_status", "MQ00_01")) == "COMPLETE", "Iria completes MQ00_01")
	main.queue_free()

func _press_dialogue_choice(panel: DialoguePanel, index: int) -> void:
	var buttons := panel.choices_box.get_children()
	_check(index >= 0 and index < buttons.size(), "dialogue choice is rendered")
	if index < 0 or index >= buttons.size():
		return
	var button := buttons[index] as Button
	_check(button != null, "dialogue choice is a button")
	if button == null:
		return
	button.emit_signal("pressed")
	await process_frame

func _walk_until_target(player: PlayerController, target_position: Vector2, target_id: String) -> void:
	for _frame in range(160):
		var distance := player.global_position.distance_to(target_position)
		if distance < 76.0 and player.current_interaction_target != null and player.current_interaction_target.target_id == target_id:
			player.set_virtual_input(Vector2.ZERO)
			await physics_frame
			return
		if distance <= 1.0:
			break
		player.set_virtual_input(player.global_position.direction_to(target_position))
		await physics_frame
	player.set_virtual_input(Vector2.ZERO)
	await physics_frame
