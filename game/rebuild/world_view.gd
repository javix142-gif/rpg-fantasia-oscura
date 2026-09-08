class_name RebuildWorldView
extends Node2D

const WORLD_SIZE := Vector2(960, 640)

var zone_id: String = "liria"
var fx: Array[Dictionary] = []
var portal_active: bool = false
var _time: float = 0.0

const PALETTES := {
	"liria": [Color("#314b3d"), Color("#60734e"), Color("#806f54"), Color("#c49b62")],
	"liria_ruinas": [Color("#302c30"), Color("#544a46"), Color("#6f5645"), Color("#a65f43")],
	"camino": [Color("#1f302a"), Color("#39483a"), Color("#554b3c"), Color("#7c6c4d")],
	"ceniza": [Color("#3d3731"), Color("#5b5144"), Color("#766650"), Color("#b18b58")],
	"ruina_exterior": [Color("#252c32"), Color("#4b5151"), Color("#73766d"), Color("#a5aa97")],
	"ruina_interior": [Color("#171a24"), Color("#303444"), Color("#53566a"), Color("#79a0a5")]
}

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
	var changed := false
	for item in fx:
		item["time"] = float(item["time"]) - delta
		changed = true
	for i in range(fx.size() - 1, -1, -1):
		if float(fx[i]["time"]) <= 0.0:
			fx.remove_at(i)
	if changed or zone_id == "liria_ruinas" or zone_id == "ceniza":
		queue_redraw()

func get_blockers() -> Array[Rect2]:
	match zone_id:
		"liria", "liria_ruinas":
			return [
				Rect2(76, 76, 190, 105), Rect2(357, 70, 194, 108), Rect2(680, 82, 190, 104),
				Rect2(86, 424, 170, 105), Rect2(688, 420, 176, 108), Rect2(435, 300, 90, 70)
			]
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
	var p: Array = PALETTES.get(zone_id, PALETTES["liria"])
	draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), p[0], true)
	_draw_tile_texture(p[1], p[0])
	match zone_id:
		"liria": _draw_liria(p, false)
		"liria_ruinas": _draw_liria(p, true)
		"camino": _draw_camino(p)
		"ceniza": _draw_ceniza(p)
		"ruina_exterior": _draw_ruina_exterior(p)
		"ruina_interior": _draw_ruina_interior(p)
	if portal_active:
		_draw_portal(Vector2(895, 320), p[3])
	_draw_fx()

func _draw_tile_texture(base: Color, dark: Color) -> void:
	for y in range(0, 640, 32):
		for x in range(0, 960, 32):
			var parity := int(x / 32 + y / 32) % 2
			var alt := base.lightened(0.035) if parity == 0 else base
			draw_rect(Rect2(x, y, 32, 32), alt, true)
	for y in range(16, 640, 64):
		for x in range(16, 960, 96):
			draw_circle(Vector2(x, y), 1.5, dark.lightened(0.15))

func _draw_liria(_p: Array, ruined: bool) -> void:
	draw_rect(Rect2(0, 268, 960, 104), Color("#86765e") if not ruined else Color("#665b53"), true)
	draw_rect(Rect2(398, 0, 164, 640), Color("#82715b") if not ruined else Color("#62564f"), true)
	_draw_house(Rect2(76, 76, 190, 105), Color("#9b744d"), Color("#5a4033"), ruined)
	_draw_house(Rect2(357, 70, 194, 108), Color("#8f6948"), Color("#4a3730"), ruined)
	_draw_house(Rect2(680, 82, 190, 104), Color("#a27b50"), Color("#5d4432"), ruined)
	_draw_house(Rect2(86, 424, 170, 105), Color("#8d6f52"), Color("#4c3c33"), ruined)
	_draw_house(Rect2(688, 420, 176, 108), Color("#916b4f"), Color("#503a31"), ruined)
	_draw_fountain(Vector2(480, 335), ruined)
	for pos in [Vector2(55, 215), Vector2(300, 205), Vector2(625, 210), Vector2(910, 220), Vector2(300, 520), Vector2(610, 525), Vector2(915, 500)]:
		_draw_tree(pos, ruined)
	_draw_market(Vector2(740, 250), ruined)
	if ruined:
		for pos in [Vector2(210, 300), Vector2(330, 360), Vector2(585, 275), Vector2(755, 355), Vector2(520, 465)]: _draw_debris(pos)
		for pos in [Vector2(145, 190), Vector2(742, 190), Vector2(810, 405)]: _draw_smoke(pos)

func _draw_camino(_p: Array) -> void:
	var road := PackedVector2Array([Vector2(0, 315), Vector2(160, 275), Vector2(315, 340), Vector2(470, 290), Vector2(650, 350), Vector2(800, 292), Vector2(960, 320)])
	draw_polyline(road, Color("#756650"), 94.0, true)
	draw_polyline(road, Color("#9a8766"), 4.0, true)
	for pos in [Vector2(80, 135), Vector2(155, 485), Vector2(355, 125), Vector2(470, 505), Vector2(620, 145), Vector2(835, 485), Vector2(900, 130)]: _draw_tree(pos, true)
	for pos in [Vector2(245, 225), Vector2(585, 410), Vector2(770, 210)]: _draw_rock(pos)
	_draw_waystone(Vector2(480, 244))

func _draw_ceniza(_p: Array) -> void:
	draw_rect(Rect2(0, 275, 960, 95), Color("#77644e"), true)
	_draw_house(Rect2(70, 82, 182, 106), Color("#80654e"), Color("#46392f"), false)
	_draw_house(Rect2(350, 74, 205, 115), Color("#735e4c"), Color("#40342d"), false)
	_draw_house(Rect2(692, 90, 174, 103), Color("#84684e"), Color("#48392f"), false)
	_draw_house(Rect2(90, 444, 165, 98), Color("#765f4b"), Color("#41342d"), false)
	_draw_house(Rect2(688, 436, 170, 100), Color("#80664d"), Color("#45372e"), false)
	for pos in [Vector2(300, 230), Vector2(625, 230), Vector2(300, 440), Vector2(620, 450)]: _draw_brazier(pos)
	_draw_market(Vector2(450, 247), false)
	for pos in [Vector2(45, 200), Vector2(900, 210), Vector2(310, 560), Vector2(620, 560)]: _draw_dead_shrub(pos)

func _draw_ruina_exterior(_p: Array) -> void:
	draw_rect(Rect2(120, 105, 720, 430), Color("#5c615d"), true)
	draw_rect(Rect2(145, 130, 670, 380), Color("#343b3e"), true)
	for pos in [Vector2(145, 160), Vector2(815, 160), Vector2(145, 470), Vector2(815, 470), Vector2(480, 105)]: _draw_column(pos)
	for pos in [Vector2(300, 235), Vector2(660, 235), Vector2(300, 430), Vector2(660, 430)]: _draw_rune(pos)
	draw_rect(Rect2(405, 92, 150, 40), Color("#171b20"), true)
	draw_line(Vector2(430, 112), Vector2(530, 112), Color("#a7d2cb"), 3)

func _draw_ruina_interior(_p: Array) -> void:
	draw_rect(Rect2(45, 45, 870, 550), Color("#252936"), true)
	for x in range(100, 900, 80): draw_line(Vector2(x, 45), Vector2(x, 595), Color(0.22, 0.25, 0.33, 0.55), 1)
	for y in range(85, 590, 80): draw_line(Vector2(45, y), Vector2(915, y), Color(0.22, 0.25, 0.33, 0.55), 1)
	for i in range(5):
		var ang := -PI * 0.5 + TAU * float(i) / 5.0
		_draw_rune(Vector2(480, 320) + Vector2(cos(ang), sin(ang)) * 170.0)
	draw_circle(Vector2(480, 320), 92, Color("#10131b"))
	draw_arc(Vector2(480, 320), 112, 0, TAU, 64, Color("#6f969a"), 3)
	_draw_altar(Vector2(480, 320))

func _draw_house(rect: Rect2, wall: Color, roof: Color, ruined: bool) -> void:
	draw_rect(rect, wall.darkened(0.18), true)
	draw_rect(Rect2(rect.position + Vector2(8, 16), rect.size - Vector2(16, 22)), wall, true)
	var roof_poly := PackedVector2Array([rect.position + Vector2(-8, 18), rect.position + Vector2(rect.size.x * 0.5, -10), rect.position + Vector2(rect.size.x + 8, 18), rect.position + Vector2(rect.size.x, 43), rect.position + Vector2(0, 43)])
	draw_colored_polygon(roof_poly, roof)
	var door := Rect2(rect.position.x + rect.size.x * 0.5 - 14, rect.end.y - 36, 28, 36)
	draw_rect(door, Color("#362b26"), true)
	draw_rect(Rect2(rect.position.x + 25, rect.position.y + 55, 24, 20), Color("#b8c7a9"), true)
	draw_rect(Rect2(rect.end.x - 49, rect.position.y + 55, 24, 20), Color("#b8c7a9"), true)
	if ruined:
		draw_line(rect.position + Vector2(10, 30), rect.position + Vector2(55, 70), Color("#211e1e"), 5)
		draw_line(rect.position + Vector2(rect.size.x - 15, 20), rect.position + Vector2(rect.size.x - 55, 75), Color("#211e1e"), 4)

func _draw_tree(pos: Vector2, dead: bool) -> void:
	var trunk := Color("#4d392d")
	draw_rect(Rect2(pos.x - 7, pos.y, 14, 34), trunk, true)
	if dead:
		draw_line(pos + Vector2(0, 4), pos + Vector2(-18, -24), trunk, 5)
		draw_line(pos + Vector2(0, -3), pos + Vector2(20, -30), trunk, 4)
	else:
		draw_circle(pos + Vector2(0, -16), 30, Color("#314f39"))
		draw_circle(pos + Vector2(-20, -4), 20, Color("#3e6042"))
		draw_circle(pos + Vector2(20, -5), 21, Color("#446b47"))

func _draw_fountain(pos: Vector2, ruined: bool) -> void:
	draw_circle(pos, 48, Color("#4d5556")); draw_circle(pos, 38, Color("#6a8e92") if not ruined else Color("#3f494a")); draw_circle(pos, 13, Color("#81817a"))
	if ruined: draw_line(pos + Vector2(-42, -10), pos + Vector2(38, 20), Color("#272828"), 5)

func _draw_market(pos: Vector2, ruined: bool) -> void:
	for i in range(3):
		var x := pos.x + i * 54
		draw_rect(Rect2(x, pos.y, 42, 24), Color("#694a32"), true)
		draw_rect(Rect2(x - 3, pos.y - 22, 48, 20), Color("#8a4e3e") if not ruined else Color("#4b403b"), true)
		draw_line(Vector2(x, pos.y), Vector2(x, pos.y + 34), Color("#3a2b23"), 3); draw_line(Vector2(x + 42, pos.y), Vector2(x + 42, pos.y + 34), Color("#3a2b23"), 3)

func _draw_debris(pos: Vector2) -> void:
	for off in [Vector2(-14, 3), Vector2(4, -8), Vector2(15, 7), Vector2(-3, 14)]: draw_rect(Rect2(pos + off, Vector2(13, 8)), Color("#665448"), true)

func _draw_smoke(pos: Vector2) -> void:
	var wobble := sin(_time * 1.4 + pos.x) * 4.0
	draw_circle(pos + Vector2(wobble, -18), 18, Color(0.18, 0.18, 0.2, 0.28)); draw_circle(pos + Vector2(-wobble, -42), 13, Color(0.2, 0.2, 0.22, 0.20))

func _draw_rock(pos: Vector2) -> void:
	draw_colored_polygon(PackedVector2Array([pos + Vector2(-25, 15), pos + Vector2(-15, -14), pos + Vector2(10, -22), pos + Vector2(27, 5), pos + Vector2(19, 20)]), Color("#4c504a"))

func _draw_waystone(pos: Vector2) -> void:
	draw_rect(Rect2(pos.x - 12, pos.y - 35, 24, 70), Color("#5f615a"), true); draw_line(pos + Vector2(-6, -18), pos + Vector2(6, 18), Color("#849795"), 2)

func _draw_brazier(pos: Vector2) -> void:
	draw_rect(Rect2(pos.x - 11, pos.y, 22, 16), Color("#392d29"), true); draw_circle(pos + Vector2(0, -6), 10 + sin(_time * 6.0) * 2, Color("#c66d37")); draw_circle(pos + Vector2(0, -8), 5, Color("#e6b65d"))

func _draw_dead_shrub(pos: Vector2) -> void:
	for ang in [-1.1, -0.55, 0.0, 0.55, 1.1]: draw_line(pos, pos + Vector2(sin(ang), -cos(ang)) * 22, Color("#65503e"), 3)

func _draw_column(pos: Vector2) -> void:
	draw_rect(Rect2(pos.x - 15, pos.y - 42, 30, 84), Color("#8e938a"), true); draw_rect(Rect2(pos.x - 22, pos.y - 46, 44, 9), Color("#aeb3a8"), true); draw_rect(Rect2(pos.x - 22, pos.y + 36, 44, 9), Color("#6e746d"), true)

func _draw_rune(pos: Vector2) -> void:
	draw_circle(pos, 20, Color(0.2, 0.28, 0.31, 0.55))
	for i in range(5):
		var a := -PI * 0.5 + TAU * float(i) / 5.0; var b := -PI * 0.5 + TAU * float((i + 2) % 5) / 5.0
		draw_line(pos + Vector2(cos(a), sin(a)) * 13, pos + Vector2(cos(b), sin(b)) * 13, Color("#7fb0ad"), 2)

func _draw_altar(pos: Vector2) -> void:
	draw_rect(Rect2(pos.x - 34, pos.y - 20, 68, 40), Color("#1a2028"), true); draw_rect(Rect2(pos.x - 44, pos.y - 28, 88, 10), Color("#555b61"), true)

func _draw_portal(pos: Vector2, color: Color) -> void:
	var pulse := 18.0 + sin(_time * 4.0) * 4.0
	draw_circle(pos, pulse, Color(color.r, color.g, color.b, 0.18)); draw_arc(pos, pulse + 7.0, 0, TAU, 32, color, 3); draw_line(pos + Vector2(0, -24), pos + Vector2(0, 24), color.lightened(0.2), 2)

func _draw_fx() -> void:
	for item in fx:
		var kind := String(item["kind"]); var pos: Vector2 = item["pos"]; var t := clamp(float(item["time"]) / maxf(float(item["max"]), 0.001), 0.0, 1.0)
		match kind:
			"slash": draw_arc(pos, 38 + (1.0 - t) * 10, -1.2, 1.2, 14, Color(0.95, 0.85, 0.55, t), 5)
			"hit":
				for a in range(8):
					var ang := TAU * float(a) / 8.0
					draw_line(pos, pos + Vector2(cos(ang), sin(ang)) * (18 + 18 * (1.0 - t)), Color(1.0, 0.55, 0.35, t), 3)
			"dodge":
				for i in range(4): draw_circle(pos + Vector2(i * 8 - 12, 4), 7 + i * 2, Color(0.7, 0.7, 0.65, 0.15 * t))
			"heal": draw_arc(pos, 22 + 20 * (1.0 - t), 0, TAU, 32, Color(0.45, 0.9, 0.58, t), 4)
			"boss": draw_arc(pos, 52 + 18 * (1.0 - t), 0, TAU, 48, Color(0.6, 0.86, 0.9, t), 5)
