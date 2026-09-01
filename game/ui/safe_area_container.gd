class_name Stage1SafeAreaContainer
extends MarginContainer

## Safe-area equivalent implemented as a project node, not a presumed native
## Godot control. It keeps thumb controls inside Android cutout insets.

func _ready() -> void:
	_resolve_margins()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_resolve_margins()

func _resolve_margins() -> void:
	var viewport_size := get_viewport_rect().size
	var safe := DisplayServer.get_display_safe_area()
	if safe.size.x <= 0 or safe.size.y <= 0:
		return
	var scale_x := viewport_size.x / 640.0
	var scale_y := viewport_size.y / 360.0
	add_theme_constant_override("margin_left", maxi(6, roundi(float(safe.position.x) / maxf(0.01, scale_x))))
	add_theme_constant_override("margin_top", maxi(4, roundi(float(safe.position.y) / maxf(0.01, scale_y))))
	add_theme_constant_override("margin_right", maxi(6, roundi(float(640 - (safe.position.x + safe.size.x)) / maxf(0.01, scale_x))))
	add_theme_constant_override("margin_bottom", maxi(4, roundi(float(360 - (safe.position.y + safe.size.y)) / maxf(0.01, scale_y))))
