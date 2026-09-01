class_name Stage1SafeAreaContainer
extends MarginContainer

## Safe-area equivalent implemented as a project node, not a presumed native
## Godot control. It keeps thumb controls inside Android cutout insets.

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_resolve_margins()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_resolve_margins()

func _resolve_margins() -> void:
	var viewport_size := get_viewport_rect().size
	var safe := DisplayServer.get_display_safe_area()
	var window_size := DisplayServer.window_get_size()
	if safe.size.x <= 0 or safe.size.y <= 0 or window_size.x <= 0 or window_size.y <= 0:
		add_theme_constant_override("margin_left", 8)
		add_theme_constant_override("margin_top", 6)
		add_theme_constant_override("margin_right", 8)
		add_theme_constant_override("margin_bottom", 6)
		return
	# DisplayServer reports physical pixels while the project layout is the
	# 640x360 content scale. Convert the insets to the current viewport before
	# applying them, so notches and gesture bars remain outside touch controls.
	var scale_x := viewport_size.x / float(window_size.x)
	var scale_y := viewport_size.y / float(window_size.y)
	var left := clampi(roundi(float(safe.position.x) * scale_x), 8, 48)
	var top := clampi(roundi(float(safe.position.y) * scale_y), 6, 36)
	var right := clampi(roundi(float(window_size.x - (safe.position.x + safe.size.x)) * scale_x), 8, 48)
	var bottom := clampi(roundi(float(window_size.y - (safe.position.y + safe.size.y)) * scale_y), 6, 36)
	add_theme_constant_override("margin_left", left)
	add_theme_constant_override("margin_top", top)
	add_theme_constant_override("margin_right", right)
	add_theme_constant_override("margin_bottom", bottom)
