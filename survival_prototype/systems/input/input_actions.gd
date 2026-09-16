class_name CSInputActions
extends RefCounted

static func movement_vector() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")

static func sprint_pressed() -> bool:
	return Input.is_action_pressed("sprint")

static func event_action(event: InputEvent) -> String:
	if not event is InputEventKey or not event.pressed or event.echo:
		return ""
	if event.is_action_pressed("attack"): return "attack"
	if event.is_action_pressed("interact"): return "interact"
	if event.is_action_pressed("inventory"): return "inventory"
	if event.is_action_pressed("craft_menu"): return "craft"
	if event.is_action_pressed("build_menu"): return "build"
	if event.is_action_pressed("map"): return "map"
	if event.is_action_pressed("eat"): return "eat"
	if event.is_action_pressed("bandage"): return "bandage"
	if event.is_action_pressed("cancel"): return "cancel"
	return ""
