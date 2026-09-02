class_name QuestMarker
extends Node2D

var marker_kind: String = ""
var _clock := 0.0
var _label: Label

func _ready() -> void:
	z_index = 30
	_label = Label.new()
	_label.position = Vector2(-8.0, -13.0)
	_label.size = Vector2(16.0, 18.0)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 13)
	_label.add_theme_color_override("font_color", Stage1Theme.COLOR_TEXT)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	set_marker("")

func set_marker(kind: String) -> void:
	marker_kind = kind
	if _label != null:
		_label.text = kind
		_label.visible = not kind.is_empty()
	queue_redraw()

func _process(delta: float) -> void:
	if marker_kind.is_empty():
		return
	_clock += delta
	var pulse := 1.0 + sin(_clock * 4.0) * 0.06
	scale = Vector2(pulse, pulse)
	queue_redraw()

func _draw() -> void:
	if marker_kind.is_empty():
		return
	var glow := Color(0.87, 0.67, 0.32, 0.20)
	var fill := Color(0.12, 0.16, 0.18, 0.94)
	draw_circle(Vector2.ZERO, 12.0, glow)
	draw_circle(Vector2.ZERO, 8.0, fill)
	draw_arc(Vector2.ZERO, 8.0, 0.0, TAU, 20, Stage1Theme.COLOR_BORDER_FOCUS, 1.2)
