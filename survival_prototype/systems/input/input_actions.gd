class_name CSInputActions
extends RefCounted

const KEY_BINDINGS := {
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"move_up": [KEY_W, KEY_UP],
	"move_down": [KEY_S, KEY_DOWN],
	"sprint": [KEY_SHIFT],
	"attack": [KEY_SPACE],
	"interact": [KEY_E],
	"inventory": [KEY_I, KEY_TAB],
	"craft_menu": [KEY_C],
	"build_menu": [KEY_B],
	"map": [KEY_M],
	"eat": [KEY_F],
	"bandage": [KEY_H],
	"cancel": [KEY_ESCAPE],
}

static func ensure_actions() -> void:
	for action_variant in KEY_BINDINGS.keys():
		var action := StringName(action_variant)
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		if not InputMap.action_get_events(action).is_empty():
			continue
		for code_variant in KEY_BINDINGS[action_variant]:
			var event := InputEventKey.new()
			event.keycode = int(code_variant)
			InputMap.action_add_event(action, event)

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
