extends SceneTree

const MAIN_SCENE = preload("res://main.tscn")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var requested_size := _requested_size()
	if requested_size.x > 0 and requested_size.y > 0:
		root.size = requested_size
		await process_frame
	var state := root.get_node_or_null("GameState")
	if state == null:
		push_error("GameState autoload missing")
		quit(1)
		return
	state.call("new_game", "Layout", "CLASS_WARRIOR")
	var main = MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	main._show_world()
	await process_frame
	await process_frame
	var viewport_size := root.get_visible_rect().size
	_check(viewport_size.x > 0.0 and viewport_size.y > 0.0, "viewport has size")
	if requested_size.x > 0 and requested_size.y > 0:
		_check(is_equal_approx(viewport_size.x / viewport_size.y, float(requested_size.x) / float(requested_size.y)), "requested ratio is applied")
	_check(root.content_scale_aspect == Window.CONTENT_SCALE_ASPECT_EXPAND, "content uses expand aspect")
	var hud: Stage1Hud = main.hud
	var content: Control = hud.root_control
	_check(content.get_global_rect().size.x > 0.0, "safe content is laid out")
	_check(_inside(content, hud.status_panel), "status stays inside safe content")
	_check(_inside(content, hud.joystick), "joystick stays inside safe content")
	_check(_inside(content, hud.interact_button), "interaction stays inside safe content")
	_check(hud.joystick.anchor_left == 0.0 and hud.joystick.anchor_bottom == 1.0, "joystick uses bottom-left anchors")
	_check(hud.interact_button.anchor_right == 1.0 and hud.interact_button.anchor_bottom == 1.0, "interaction uses bottom-right anchors")
	_check(hud.status_panel.anchor_left == 0.0 and hud.status_panel.anchor_top == 0.0, "status uses top-left anchors")
	_check(hud.menu_panel.anchor_right == 1.0 and hud.menu_panel.anchor_top == 0.0, "menu uses top-right anchors")
	main.queue_free()
	if failures.is_empty():
		print("P11_LAYOUT_VALIDATION=PASS ratio=%0.3f" % (viewport_size.x / viewport_size.y))
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("P11_LAYOUT_VALIDATION=FAIL")
	quit(1)

func _inside(parent: Control, child: Control) -> bool:
	var parent_rect := parent.get_global_rect()
	var child_rect := child.get_global_rect()
	return parent_rect.encloses(child_rect)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _requested_size() -> Vector2i:
	for argument in OS.get_cmdline_user_args():
		if not String(argument).begins_with("--size="):
			continue
		var parts := String(argument).trim_prefix("--size=").split("x")
		if parts.size() == 2:
			return Vector2i(int(parts[0]), int(parts[1]))
	return Vector2i.ZERO
