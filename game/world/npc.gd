class_name VillageNpc
extends Node2D

signal interacted(actor_id: String)

var actor_id: String = ""
var display_name: String = ""
var role: String = "villager"
var body_color: Color = Color("#537b69")
var accent_color: Color = Color("#e5b45a")
var accessory: String = ""
var _label: Label

func setup(new_id: String, new_name: String, new_role: String, position: Vector2, color: Color, accent: Color, new_accessory: String = "") -> void:
	actor_id = new_id
	display_name = new_name
	role = new_role
	body_color = color
	accent_color = accent
	accessory = new_accessory
	global_position = position

func _ready() -> void:
	z_index = 10
	_label = Label.new()
	_label.text = display_name
	_label.position = Vector2(-44, -78)
	_label.size = Vector2(88, 18)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 10)
	_label.add_theme_color_override("font_color", Color("#f8e9bc"))
	_label.add_theme_color_override("font_shadow_color", Color(0.05, 0.04, 0.06, 0.85))
	_label.add_theme_constant_override("shadow_offset_x", 1)
	_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(_label)
	queue_redraw()

func prompt_text() -> String:
	return "Hablar con " + display_name

func interaction_data() -> Dictionary:
	return {"id": actor_id, "prompt": prompt_text(), "action": "dialogue"}

func _draw() -> void:
	# Procedural placeholder keeps the same 64 px cell and feet pivot as the master.
	_draw_ellipse_custom(Vector2(0, 1), Vector2(16, 5), Color(0.08, 0.06, 0.08, 0.32))
	draw_rect(Rect2(-12, -45, 24, 33), body_color, true)
	draw_rect(Rect2(-15, -42, 30, 7), accent_color, true)
	draw_circle(Vector2(0, -55), 11, Color("#e3ad7a"))
	draw_circle(Vector2(0, -58), 12, accent_color.darkened(0.25))
	draw_rect(Rect2(-15, -13, 11, 12), Color("#513b36"), true)
	draw_rect(Rect2(4, -13, 11, 12), Color("#513b36"), true)
	draw_line(Vector2(-12, -32), Vector2(-20, -20), body_color.darkened(0.25), 4)
	draw_line(Vector2(12, -32), Vector2(20, -20), body_color.darkened(0.25), 4)
	if role == "merchant":
		draw_circle(Vector2(18, -20), 4, Color("#d64f42"))
		draw_circle(Vector2(23, -18), 3, Color("#e9bd3f"))
	elif role == "smith":
		draw_rect(Rect2(17, -28, 8, 13), Color("#6d7892"), true)
		draw_line(Vector2(21, -28), Vector2(27, -36), Color("#e0b968"), 3)
	elif role == "halven":
		draw_line(Vector2(17, -18), Vector2(17, -55), Color("#a26f4b"), 3)
		draw_circle(Vector2(17, -57), 3, Color("#e8c06a"))
	elif role == "iria":
		draw_arc(Vector2(15, -33), 12, -1.2, 1.2, 8, Color("#c48a57"), 3)
		draw_line(Vector2(23, -43), Vector2(31, -22), Color("#7b4e3b"), 2)

func _draw_ellipse_custom(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(20):
		var angle := TAU * float(i) / 20.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)
