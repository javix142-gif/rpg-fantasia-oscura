extends SceneTree

const MAIN_SCENE = preload("res://main.tscn")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var requested := _requested_size()
	if requested.x > 0 and requested.y > 0:
		root.size = requested
		await process_frame
	var state := root.get_node_or_null("GameState")
	_check(state != null, "GameState autoload available")
	if state == null:
		quit(1)
		return
	state.call("new_game", "P1.3 UI", "CLASS_WARRIOR")
	var main = MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	_check(main.get_node_or_null("LiriaTitleBackground") != null, "title uses full-screen Liria background")
	_check(main.get_node_or_null("TitleReadabilityVeil") != null, "title uses readability veil")
	_check(_title_has_no_keyboard_hint(main), "title has no keyboard-only hint on Android")
	main._show_creation()
	await process_frame
	main._create_profile()
	await create_timer(0.30).timeout
	_check(main.mode == "world", "new game crosses the menu fade into Liria")
	await process_frame
	await physics_frame
	var hud: Stage1Hud = main.hud
	var safe: Control = hud.root_control
	_check(_inside(safe, hud.status_panel), "status panel respects safe bounds")
	_check(_inside(safe, hud.quest_panel), "quest panel respects safe bounds")
	_check(_inside(safe, hud.actions), "actions respect safe bounds")
	_check(_inside(safe, hud.joystick), "joystick respects safe bounds")
	_check(_inside(safe, hud.interact_button), "interaction respects safe bounds")
	_check(hud.interact_button.custom_minimum_size.x >= 100.0, "interaction keeps a comfortable touch target")
	_check(hud.joystick.custom_minimum_size.x >= 90.0, "joystick keeps a comfortable touch target")
	_check(Stage1Theme.FONT_BODY >= 10, "body typography remains readable")
	_check(hud.status_panel.get_theme_stylebox("panel") != null, "status uses shared panel style")
	_check(hud.menu_panel.get_theme_stylebox("panel") != null, "menu uses shared panel style")
	_check(main.get_node_or_null("Stage1Transition") != null, "world entry creates a transition layer")
	await create_timer(0.6).timeout
	var transition := main.get_node_or_null("Stage1Transition") as Stage1TransitionLayer
	_check(transition != null and not transition.visible, "world transition releases its input block")
	var dialogue: DialoguePanel = main.dialogue
	_check(dialogue.open_actor("NPC_IRIA"), "dialogue opens for UI contract")
	await process_frame
	_check(dialogue.portrait.texture != null, "important NPC dialogue has a portrait")
	for child in dialogue.choices_box.get_children():
		var choice := child as Button
		if choice != null:
			_check(choice.custom_minimum_size.y <= 28.0, "dialogue choices remain compact")
	_check(dialogue.get_theme_stylebox("panel") != null, "dialogue uses shared panel style")
	dialogue._close()
	await create_timer(0.22).timeout
	_check(not dialogue.visible, "dialogue exit transition completes")
	main.queue_free()
	if failures.is_empty():
		print("P13_UI_CONTRACT=PASS size=%dx%d" % [int(root.get_visible_rect().size.x), int(root.get_visible_rect().size.y)])
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("P13_UI_CONTRACT=FAIL")
	quit(1)

func _title_has_no_keyboard_hint(main: Node) -> bool:
	for child in main.get_children():
		if child is Label and String((child as Label).text).contains("WASD") and OS.has_feature("android"):
			return false
	return true

func _inside(parent: Control, child: Control) -> bool:
	return parent.get_global_rect().encloses(child.get_global_rect())

func _requested_size() -> Vector2i:
	for argument in OS.get_cmdline_user_args():
		if not String(argument).begins_with("--size="):
			continue
		var parts := String(argument).trim_prefix("--size=").split("x")
		if parts.size() == 2:
			return Vector2i(int(parts[0]), int(parts[1]))
	return Vector2i.ZERO

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
