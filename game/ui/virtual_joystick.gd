class_name Stage1VirtualJoystick
extends Control

signal value_changed(value: Vector2)

const DEADZONE := 0.14
var value: Vector2 = Vector2.ZERO
var _active := false
var _pointer_id := -1

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(108, 108)
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and not _active:
			_active = true
			_pointer_id = event.index
			_update_from_position(event.position)
		elif not event.pressed and _active and event.index == _pointer_id:
			_release()
	elif event is InputEventScreenDrag and _active and event.index == _pointer_id:
		_update_from_position(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_active = true
			_pointer_id = -2
			_update_from_position(event.position)
		else:
			_release()
	elif event is InputEventMouseMotion and _active and _pointer_id == -2:
		_update_from_position(event.position)

func _update_from_position(position: Vector2) -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.38
	var delta := position - center
	if delta.length() > radius:
		delta = delta.normalized() * radius
	var next := delta / radius
	if next.length() < DEADZONE:
		next = Vector2.ZERO
	value = next
	value_changed.emit(value)
	queue_redraw()

func _release() -> void:
	_active = false
	_pointer_id = -1
	value = Vector2.ZERO
	value_changed.emit(value)
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.42
	draw_circle(center, radius, Color(0.08, 0.09, 0.13, 0.62))
	draw_arc(center, radius, 0, TAU, 32, Color("#d0a85a"), 2)
	draw_circle(center + value * radius * 0.62, radius * 0.42, Color(0.32, 0.47, 0.58, 0.88))
	draw_arc(center + value * radius * 0.62, radius * 0.42, 0, TAU, 24, Color("#f4d37e"), 2)
