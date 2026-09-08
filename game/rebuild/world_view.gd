class_name RebuildWorldView
extends Node2D

const WORLD_SIZE: Vector2 = Vector2(960, 640)

var zone_id: String = "liria"
var fx: Array[Dictionary] = []
var portal_active: bool = false
var _time: float = 0.0

func _ready() -> void:
	z_index = -10
	set_process(true)
	queue_redraw()

func set_zone(next_zone: String) -> void:
	zone_id = next_zone
	portal_active = false
	fx.clear()
	queue_redraw()

func set_portal_active(value: bool) -> void:
	portal_active = value
	queue_redraw()

func spawn_fx(kind: String, position: Vector2, duration: float = 0.35) -> void:
	fx.append({"kind": kind, "pos": position, "time": duration, "max": duration})
	queue_redraw()

func _process(delta: float) -> void:
	_time += delta
	for item: Dictionary in fx:
		item["time"] = float(item.get("time", 0.0)) - delta
	for index: int in range(fx.size() - 1, -1, -1):
		if float(fx[index].get("time", 0.0)) <= 0.0:
			fx.remove_at(index)
	if not fx.is_empty() or zone_id == "liria_ruinas" or zone_id == "ceniza":
		queue_redraw()

func get_blockers() -> Array[Rect2]:
	match zone_id:
		"liria", "liria_ruinas":
			return [Rect2(76, 76, 190, 105), Rect2(357, 70, 194, 108), Rect2(680, 82, 190, 104), Rect2(86, 424, 170, 105), Rect2(688, 420, 176, 108), Rect2(435, 300, 90, 70)]
		"camino":
			return [Rect2(0, 0, 960, 95), Rect2(0, 535, 960, 105), Rect2(220, 95, 90, 98), Rect2(610, 442, 110, 93)]
		"ceniza":
			return [Rect2(70, 82, 182, 106), Rect2(350, 74, 205, 115), Rect2(692, 90, 174, 103), Rect2(90, 444, 165, 98), Rect2(688, 436, 170, 100)]
		"ruina_exterior":
			return [Rect2(100, 70, 90, 240), Rect2(770, 70, 90, 240), Rect2(100, 430, 90, 135), Rect2(770, 430, 90, 135), Rect2(390, 86, 180, 76)]
		"ruina_interior":
			return [Rect2(0, 0, 960, 45), Rect2(0, 595, 960, 45), Rect2(0, 0, 45, 640), Rect2(915, 0, 45, 640)]
	return []

func _draw() -> void:
	var palette: Array[Color] = _palette_for_zone(zone_id)
	draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), palette[0], true)
	_draw_ground(palette[1], palette[0])
	match zone_id:
		"liria":
			_draw_liria(false)
		"liria_ruinas":
			_draw_liria(true)
		"camino":
			_draw_camino()
		"ceniza":
			_draw_ceniza()
		"ruina_exterior":
			_draw_ruina_exterior()
		"ruina_interior":
			_draw_ruina_interior()
	if portal_active:
		_draw_portal(Vector2(895, 320), palette[3])
	_draw_fx()

func _palette_for_zone(id: String) -> Array[Color]:
	match id:
		"liria": return [Color("#314b3d"), Color("#60734e"), Color("#806f54"), Color("#c49b62")]
		"liria_ruinas": return [Color("#302c30"), Color("#544a46"), Color("#6f5645"), Color("#a65f43")]
		"camino": return [Color("#1f302a"), Color("#39483a"), Color("#554b3c"), Color("#7c6c4d")]
		"ceniza": return [Color("#3d3731"), Color("#5b5144"), Color("#766650"), Color("#b18b58")]
		"ruina_exterior": return [Color("#252c32"), Color("#4b5151"), Color("#73766d"), Color("#a5aa97")]
		"ruina_interior": return [Color("#171a24"), Color("#303444"), Color("#53566a"), Color("#79a0a5")]
	return [Color("#20242a"), Color("#3c4448"), Color("#777777"), Color("#c0c0c0")]

func _draw_ground(base: Color, dark: Color) -> void:
	for y: int in range(0, 640, 32):
		for x: int in range(0, 960, 32):
			var parity: int = int(x / 32 + y / 32) % 2
			var cell: Color = base.lightened(0.035) if parity == 0 else base
			draw_rect(Rect2(x, y, 32, 32), cell, true)
	for y: int in range(16, 640, 64):
		for x: int in range(16, 960, 96):
			draw_circle(Vector2(x, y), 1.5, dark.lightened(0.15))

func _draw_liria(ruined: bool) -> void:
	var road: Color = Color("#665b53") if ruined else Color("#86765e")
	draw_rect(Rect2(0, 268, 960, 104), road, true)
	draw_rect(Rect2(398, 0, 164, 640), road.darkened(0.04), true)
	_draw_house(Rect2(76, 76, 190, 105), ruined)
	_draw_house(Rect2(357, 70, 194, 108), ruined)
	_draw_house(Rect2(680, 82, 190, 104), ruined)
	_draw_house(Rect2(86, 424, 170, 105), ruined)
	_draw_house(Rect2(688, 420, 176, 108), ruined)
	draw_circle(Vector2(480, 335), 48, Color("#4d5556"))
	draw_circle(Vector2(480, 335), 36, Color("#3f494a") if ruined else Color("#6a8e92"))
	for tree_pos: Vector2 in [Vector2(55, 215), Vector2(300, 205), Vector2(625, 210), Vector2(910, 220), Vector2(300, 520), Vector2(610, 525), Vector2(915, 500)]:
		_draw_tree(tree_pos, ruined)
	if ruined:
		for rubble: Vector2 in [Vector2(210, 300), Vector2(330, 360), Vector2(585, 275), Vector2(755, 355), Vector2(520, 465)]:
			draw_circle(rubble, 12, Color("#4a4039"))

func _draw_camino() -> void:
	var road: PackedVector2Array = PackedVector2Array([Vector2(0, 315), Vector2(160, 275), Vector2(315, 340), Vector2(470, 290), Vector2(650, 350), Vector2(800, 292), Vector2(960, 320)])
	draw_polyline(road, Color("#756650"), 94.0, true)
	draw_polyline(road, Color("#9a8766"), 4.0, true)
	for tree_pos: Vector2 in [Vector2(80, 135), Vector2(155, 485), Vector2(355, 125), Vector2(470, 505), Vector2(620, 145), Vector2(835, 485), Vector2(900, 130)]:
		_draw_tree(tree_pos, true)

func _draw_ceniza() -> void:
	draw_rect(Rect2(0, 275, 960, 95), Color("#77644e"), true)
	for rect: Rect2 in [Rect2(70, 82, 182, 106), Rect2(350, 74, 205, 115), Rect2(692, 90, 174, 103), Rect2(90, 444, 165, 98), Rect2(688, 436, 170, 100)]:
		_draw_house(rect, false)
	for brazier: Vector2 in [Vector2(300, 230), Vector2(625, 230), Vector2(300, 440), Vector2(620, 450)]:
		draw_circle(brazier, 9, Color("#d78b45"))

func _draw_ruina_exterior() -> void:
	draw_rect(Rect2(120, 105, 720, 430), Color("#5c615d"), true)
	draw_rect(Rect2(145, 130, 670, 380), Color("#343b3e"), true)
	for column: Vector2 in [Vector2(145, 160), Vector2(815, 160), Vector2(145, 470), Vector2(815, 470), Vector2(480, 105)]:
		draw_rect(Rect2(column - Vector2(12, 32), Vector2(24, 64)), Color("#777b75"), true)

func _draw_ruina_interior() -> void:
	draw_rect(Rect2(45, 45, 870, 550), Color("#252936"), true)
	for x: int in range(100, 900, 80):
		draw_line(Vector2(x, 45), Vector2(x, 595), Color(0.22, 0.25, 0.33, 0.55), 1)
	for y: int in range(85, 590, 80):
		draw_line(Vector2(45, y), Vector2(915, y), Color(0.22, 0.25, 0.33, 0.55), 1)
	draw_circle(Vector2(480, 320), 92, Color("#10131b"))
	draw_arc(Vector2(480, 320), 112, 0, TAU, 64, Color("#6f969a"), 3)

func _draw_house(rect: Rect2, ruined: bool) -> void:
	var wall: Color = Color("#7a6250") if not ruined else Color("#514943")
	var roof: Color = Color("#49372f") if not ruined else Color("#302d2d")
	draw_rect(rect, wall, true)
	var roof_poly: PackedVector2Array = PackedVector2Array([rect.position + Vector2(-8, 18), rect.position + Vector2(rect.size.x * 0.5, -10), rect.position + Vector2(rect.size.x + 8, 18), rect.position + Vector2(rect.size.x, 43), rect.position + Vector2(0, 43)])
	draw_colored_polygon(roof_poly, roof)
	var door: Rect2 = Rect2(rect.position.x + rect.size.x * 0.5 - 14, rect.end.y - 36, 28, 36)
	draw_rect(door, Color("#362b26"), true)

func _draw_tree(pos: Vector2, dead: bool) -> void:
	var trunk: Color = Color("#4d392d")
	draw_rect(Rect2(pos.x - 7, pos.y, 14, 34), trunk, true)
	if dead:
		draw_line(pos + Vector2(0, 4), pos + Vector2(-18, -24), trunk, 5)
		draw_line(pos + Vector2(0, -3), pos + Vector2(20, -30), trunk, 4)
	else:
		draw_circle(pos + Vector2(0, -16), 30, Color("#314f39"))
		draw_circle(pos + Vector2(-20, -4), 20, Color("#3e6042"))
		draw_circle(pos + Vector2(20, -5), 21, Color("#446b47"))

func _draw_portal(pos: Vector2, color: Color) -> void:
	var pulse: float = 18.0 + sin(_time * 4.0) * 4.0
	draw_circle(pos, pulse, Color(color.r, color.g, color.b, 0.18))
	draw_arc(pos, pulse + 7.0, 0, TAU, 32, color, 3)
	draw_line(pos + Vector2(0, -24), pos + Vector2(0, 24), color.lightened(0.2), 2)

func _draw_fx() -> void:
	for item: Dictionary in fx:
		var kind: String = String(item.get("kind", ""))
		var pos: Vector2 = item.get("pos", Vector2.ZERO) as Vector2
		var maximum: float = maxf(float(item.get("max", 0.001)), 0.001)
		var ratio: float = clampf(float(item.get("time", 0.0)) / maximum, 0.0, 1.0)
		match kind:
			"slash": draw_arc(pos, 38.0 + (1.0 - ratio) * 10.0, -1.2, 1.2, 14, Color(0.95, 0.85, 0.55, ratio), 5)
			"hit": draw_circle(pos, 14.0 + (1.0 - ratio) * 12.0, Color(1.0, 0.55, 0.35, 0.35 * ratio))
			"dodge": draw_circle(pos, 16.0, Color(0.7, 0.7, 0.65, 0.18 * ratio))
			"heal": draw_arc(pos, 22.0 + 20.0 * (1.0 - ratio), 0, TAU, 32, Color(0.45, 0.9, 0.58, ratio), 4)
			"boss": draw_arc(pos, 52.0 + 18.0 * (1.0 - ratio), 0, TAU, 48, Color(0.6, 0.86, 0.9, ratio), 5)
