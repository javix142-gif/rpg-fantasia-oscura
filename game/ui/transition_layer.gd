class_name Stage1TransitionLayer
extends ColorRect

signal transition_finished

const DEFAULT_DURATION := 0.32
var location_label: Label
var _transition_tween: Tween

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color = Color(0.0, 0.0, 0.0, 1.0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 500
	location_label = Stage1Theme.label("", Stage1Theme.FONT_HEADING, Stage1Theme.COLOR_TEXT)
	location_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	location_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	location_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	location_label.offset_left = -150.0
	location_label.offset_top = -28.0
	location_label.offset_right = 150.0
	location_label.offset_bottom = 28.0
	location_label.modulate.a = 0.0
	location_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(location_label)

func fade_to_black(duration: float = DEFAULT_DURATION) -> void:
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	color.a = 0.0
	location_label.modulate.a = 0.0
	_kill_tween()
	_transition_tween = create_tween()
	_transition_tween.tween_property(self, "color:a", 1.0, maxf(0.05, duration))
	_transition_tween.tween_callback(func() -> void: transition_finished.emit())

func fade_from_black(duration: float = DEFAULT_DURATION, location: String = "") -> void:
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	color.a = 1.0
	location_label.text = location
	location_label.modulate.a = 1.0 if not location.is_empty() else 0.0
	_kill_tween()
	_transition_tween = create_tween()
	_transition_tween.tween_property(self, "color:a", 0.0, maxf(0.05, duration))
	if not location.is_empty():
		_transition_tween.tween_interval(0.08)
		_transition_tween.tween_property(location_label, "modulate:a", 0.0, maxf(0.10, duration * 0.5))
	_transition_tween.tween_callback(_finish_fade_from_black)

func _finish_fade_from_black() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_finished.emit()

func _kill_tween() -> void:
	if _transition_tween != null and _transition_tween.is_valid():
		_transition_tween.kill()
	_transition_tween = null
