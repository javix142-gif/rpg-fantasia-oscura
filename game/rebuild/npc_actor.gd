class_name RebuildNpc
extends Node2D

var npc_id := ""
var display_name := ""
var role := "villager"
var body_color := Color("#6f7d68")
var accent_color := Color("#c89b63")
var _time := 0.0
var quest_marker := ""

func setup(id: String, label: String, npc_role: String, color: Color, accent: Color) -> void:
	npc_id = id
	display_name = label
	role = npc_role
	body_color = color
	accent_color = accent
	name = "NPC_" + id

func _ready() -> void:
	z_index = 15
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func set_marker(value: String) -> void:
	quest_marker = value
	queue_redraw()

func _draw() -> void:
	var bob := sin(_time * 2.2 + global_position.x * 0.01) * 1.2
	draw_circle(Vector2(0, 1), 13, Color(0.04,0.04,0.05,0.30))
	draw_rect(Rect2(-9, -29 + bob, 18, 24), body_color, true)
	draw_rect(Rect2(-7, -39 + bob, 14, 12), Color("#c9a37c"), true)
	draw_rect(Rect2(-10, -18 + bob, 5, 18), body_color.darkened(0.25), true)
	draw_rect(Rect2(5, -18 + bob, 5, 18), body_color.darkened(0.25), true)
	draw_rect(Rect2(-8, -5 + bob, 6, 6), accent_color, true)
	draw_rect(Rect2(2, -5 + bob, 6, 6), accent_color, true)
	if role == "merchant":
		draw_rect(Rect2(8, -25 + bob, 9, 13), Color("#735137"), true)
	elif role == "archivist":
		draw_line(Vector2(10, -31 + bob), Vector2(17, -8 + bob), Color("#80684b"), 3)
	if quest_marker != "":
		draw_circle(Vector2(0, -56 + bob), 11, Color("#22262c"))
		draw_string(ThemeDB.fallback_font, Vector2(-4, -51 + bob), quest_marker, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#f0cf70"))
