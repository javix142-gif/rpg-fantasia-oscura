class_name VillageWorld
extends Node2D

signal npc_created(npc: VillageNpc)

const WORLD_SIZE := Vector2(960, 640)
var npcs: Array[VillageNpc] = []
var tile_layer: TileMapLayer

func _ready() -> void:
	name = "LiriaNormal"
	_create_tile_layer()
	_create_render_layers()
	_create_npcs()
	_create_boundaries()
	queue_redraw()

func _create_tile_layer() -> void:
	# New tilemaps use TileMapLayer even while the P1 kit remains procedural.
	tile_layer = TileMapLayer.new()
	tile_layer.name = "GroundTileMapLayer"
	tile_layer.z_index = -20
	add_child(tile_layer)

func _create_render_layers() -> void:
	for layer_name in ["PathsLayer", "DecorationLayer", "CollisionLayer", "ForegroundLayer"]:
		var layer := Node2D.new()
		layer.name = layer_name
		add_child(layer)

func _create_boundaries() -> void:
	for spec in [Rect2(480, 28, 880, 20), Rect2(480, 612, 880, 20), Rect2(28, 320, 20, 560), Rect2(932, 320, 20, 560)]:
		var body := StaticBody2D.new()
		var shape_node := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = spec.size
		shape_node.shape = shape
		shape_node.position = spec.position
		body.add_child(shape_node)
		add_child(body)

func _create_npcs() -> void:
	_add_npc("NPC_IRIA", "Iria", "iria", Vector2(400, 292), Color("#567f69"), Color("#b9574e"), "arco")
	_add_npc("NPC_HALVEN", "Halven", "halven", Vector2(700, 235), Color("#69718a"), Color("#bc8a55"), "bastón")
	_add_npc("NPC_SMITH", "Bram", "smith", Vector2(270, 430), Color("#8b5545"), Color("#e0a84f"), "yunque")
	_add_npc("NPC_MERCHANT", "Nella", "merchant", Vector2(770, 425), Color("#5e6f95"), Color("#e3aa4d"), "fruta")
	_add_npc("NPC_FRIEND", "Tomas", "friend", Vector2(550, 500), Color("#9b6853"), Color("#6e9b74"), "amigo")
	var ambient := [
		["NPC_VILLAGER_A", "Mara", Vector2(155, 270), Color("#7b6382"), Color("#db9d63")],
		["NPC_VILLAGER_B", "Oren", Vector2(230, 520), Color("#52738b"), Color("#d6b16d")],
		["NPC_VILLAGER_C", "Lio", Vector2(620, 330), Color("#9a6d52"), Color("#779b62")],
		["NPC_VILLAGER_D", "Sela", Vector2(860, 300), Color("#8c5f76"), Color("#d0a44e")],
		["NPC_VILLAGER_E", "Perrin", Vector2(470, 555), Color("#536e83"), Color("#b8774f")],
		["NPC_VILLAGER_F", "Yara", Vector2(870, 520), Color("#6f8960"), Color("#c76d58")]
	]
	for item in ambient:
		_add_npc(String(item[0]), String(item[1]), "villager", item[2], item[3], item[4])

func _add_npc(actor_id: String, display_name: String, role: String, position: Vector2, body_color: Color, accent: Color, accessory: String = "") -> void:
	var npc := VillageNpc.new()
	npc.setup(actor_id, display_name, role, position, body_color, accent, accessory)
	add_child(npc)
	npcs.append(npc)
	npc_created.emit(npc)

func get_nearest_npc(position: Vector2, radius: float) -> VillageNpc:
	var nearest: VillageNpc = null
	var best := radius
	for npc in npcs:
		var distance := position.distance_to(npc.global_position)
		if distance < best:
			best = distance
			nearest = npc
	return nearest

func _draw() -> void:
	# Rich, compact Liria composition: grass, paths, plaza, homes, market, smithy,
	# gardens, trees and props are authored as reusable deterministic modules.
	draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color("#5f914f"), true)
	for patch in [Rect2(55, 80, 230, 145), Rect2(705, 70, 190, 130), Rect2(70, 445, 180, 120), Rect2(735, 470, 150, 100)]:
		draw_rect(patch, Color("#6fa256"), true)
	# dirt routes
	draw_rect(Rect2(430, 50, 100, 540), Color("#bc8b54"), true)
	draw_rect(Rect2(55, 325, 850, 70), Color("#bc8b54"), true)
	draw_rect(Rect2(340, 180, 260, 250), Color("#d2a261"), true)
	# path highlights
	for x in range(80, 900, 48):
		draw_circle(Vector2(x, 360 + sin(float(x)) * 6.0), 2.0, Color("#e2bd79"))
	# plaza and fountain
	draw_circle(Vector2(480, 305), 92, Color("#d8c49b"))
	draw_circle(Vector2(480, 305), 79, Color("#ad9c82"))
	draw_circle(Vector2(480, 305), 61, Color("#6aa2ad"))
	draw_circle(Vector2(480, 305), 49, Color("#4f8797"))
	draw_rect(Rect2(470, 257, 20, 50), Color("#d9d0b5"), true)
	draw_circle(Vector2(480, 253), 13, Color("#d9d0b5"))
	draw_line(Vector2(480, 252), Vector2(458, 274), Color("#bde3db"), 3)
	draw_line(Vector2(480, 252), Vector2(502, 274), Color("#bde3db"), 3)
	# buildings
	_house(Rect2(74, 112, 194, 145), "CASA A", Color("#e3c994"), Color("#b64f43"))
	_house(Rect2(705, 102, 184, 140), "CASA B", Color("#d7b67c"), Color("#5e708a"))
	_house(Rect2(624, 158, 162, 112), "HALVEN", Color("#c39a6a"), Color("#9b4c43"))
	_smithy(Rect2(170, 405, 198, 114))
	_market(Rect2(710, 370, 170, 110))
	# gardens / crops
	_garden(Rect2(62, 470, 135, 70))
	_garden(Rect2(755, 520, 108, 48))
	# trees, hedges, lamps and props
	_tree(Vector2(120, 74), 1.0)
	_tree(Vector2(310, 105), 0.78)
	_tree(Vector2(870, 80), 0.92)
	_tree(Vector2(905, 455), 0.78)
	_tree(Vector2(300, 580), 0.7)
	_bush(Vector2(380, 112), 1.0)
	_bush(Vector2(575, 105), 0.8)
	_lamp(Vector2(365, 350))
	_lamp(Vector2(595, 350))
	_lamp(Vector2(660, 390))
	_bench(Vector2(515, 400))
	_barrel(Vector2(315, 405))
	_barrel(Vector2(850, 365))
	_fence(Vector2(230, 560), 100)
	# tiny floral accents
	for flower in [Vector2(65, 290), Vector2(95, 300), Vector2(290, 310), Vector2(650, 300), Vector2(890, 275), Vector2(685, 520)]:
		_flower_patch(flower)

func _house(rect: Rect2, label: String, wall: Color, roof: Color) -> void:
	draw_rect(rect, Color("#553f39"), true)
	draw_rect(rect.grow(-5), wall, true)
	var roof_points := PackedVector2Array([Vector2(rect.position.x - 10, rect.position.y + 15), Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y - 42), Vector2(rect.end.x + 10, rect.position.y + 15)])
	draw_colored_polygon(roof_points, roof)
	draw_polyline(PackedVector2Array([roof_points[0], roof_points[1], roof_points[2]]), Color("#f1c46a"), 3)
	draw_rect(Rect2(rect.position.x + rect.size.x * 0.45, rect.end.y - 58, 28, 58), Color("#714536"), true)
	draw_rect(Rect2(rect.position.x + 25, rect.position.y + 54, 28, 25), Color("#6a9eb0"), true)
	draw_rect(Rect2(rect.end.x - 54, rect.position.y + 54, 28, 25), Color("#6a9eb0"), true)
	draw_string(ThemeDB.fallback_font, Vector2(rect.position.x + 8, rect.position.y + 24), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#fff0c0"))

func _smithy(rect: Rect2) -> void:
	draw_rect(rect, Color("#5a4039"), true)
	draw_rect(rect.grow(-5), Color("#9e684b"), true)
	draw_colored_polygon(PackedVector2Array([Vector2(rect.position.x - 8, rect.position.y + 14), Vector2(rect.position.x + rect.size.x * .5, rect.position.y - 34), Vector2(rect.end.x + 8, rect.position.y + 14)]), Color("#a6453d"))
	draw_circle(Vector2(rect.position.x + 56, rect.position.y + 72), 21, Color("#e8793d"))
	draw_circle(Vector2(rect.position.x + 56, rect.position.y + 72), 12, Color("#ffd27a"))
	draw_rect(Rect2(rect.position.x + 108, rect.position.y + 74, 32, 10), Color("#444c57"), true)
	draw_rect(Rect2(rect.position.x + 119, rect.position.y + 56, 10, 18), Color("#444c57"), true)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(10, 23), "HERRERÍA", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#fff0c0"))

func _market(rect: Rect2) -> void:
	draw_rect(Rect2(rect.position.x + 12, rect.position.y + 42, rect.size.x - 24, 56), Color("#6b493d"), true)
	draw_colored_polygon(PackedVector2Array([Vector2(rect.position.x, rect.position.y + 48), Vector2(rect.position.x + rect.size.x * .5, rect.position.y - 10), Vector2(rect.end.x, rect.position.y + 48)]), Color("#58758f"))
	for x in range(int(rect.position.x + 28), int(rect.end.x - 10), 28):
		draw_circle(Vector2(x, rect.position.y + 67), 8, Color("#d95b45" if x % 2 == 0 else "#e8b746"))
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(15, 35), "MERCADO", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#fff0c0"))

func _garden(rect: Rect2) -> void:
	draw_rect(rect, Color("#8a633e"), true)
	for y in range(int(rect.position.y + 12), int(rect.end.y), 20):
		draw_line(Vector2(rect.position.x + 8, y), Vector2(rect.end.x - 8, y), Color("#5d8c49"), 5)
		for x in range(int(rect.position.x + 16), int(rect.end.x - 10), 24):
			draw_circle(Vector2(x, y - 2), 3, Color("#e8c54e"))

func _tree(pos: Vector2, scale_value: float) -> void:
	draw_rect(Rect2(pos + Vector2(-7, 20) * scale_value, Vector2(14, 38) * scale_value), Color("#664737"), true)
	for offset in [Vector2(-20, 0), Vector2(0, -12), Vector2(21, 2), Vector2(0, 13)]:
		draw_circle(pos + offset * scale_value, 28 * scale_value, Color("#315f45"))
		draw_circle(pos + (offset + Vector2(-4, -4)) * scale_value, 22 * scale_value, Color("#5f9a4b"))

func _bush(pos: Vector2, scale_value: float) -> void:
	draw_circle(pos, 17 * scale_value, Color("#376a45"))
	draw_circle(pos + Vector2(15, 3) * scale_value, 14 * scale_value, Color("#4f874a"))
	draw_circle(pos + Vector2(-13, 4) * scale_value, 13 * scale_value, Color("#6ca551"))

func _lamp(pos: Vector2) -> void:
	draw_line(pos + Vector2(0, 22), pos + Vector2(0, -17), Color("#4d3e3a"), 4)
	draw_circle(pos + Vector2(0, -21), 8, Color("#f4bd51"))
	draw_circle(pos + Vector2(0, -21), 4, Color("#fff0a2"))

func _bench(pos: Vector2) -> void:
	draw_rect(Rect2(pos, Vector2(45, 7)), Color("#825239"), true)
	draw_rect(Rect2(pos + Vector2(0, 12), Vector2(45, 6)), Color("#a66a45"), true)
	draw_line(pos + Vector2(7, 18), pos + Vector2(4, 31), Color("#513c36"), 3)
	draw_line(pos + Vector2(38, 18), pos + Vector2(41, 31), Color("#513c36"), 3)

func _barrel(pos: Vector2) -> void:
	draw_circle(pos, 15, Color("#7b4d37"))
	draw_arc(pos, 14, 0, TAU, 20, Color("#d09a50"), 3)
	draw_line(pos + Vector2(-12, -5), pos + Vector2(12, -5), Color("#4b3b37"), 3)
	draw_line(pos + Vector2(-12, 6), pos + Vector2(12, 6), Color("#4b3b37"), 3)

func _fence(pos: Vector2, width: float) -> void:
	draw_line(pos, pos + Vector2(width, 0), Color("#754a35"), 6)
	for x in range(0, int(width) + 1, 24):
		draw_line(pos + Vector2(x, -12), pos + Vector2(x, 12), Color("#a8734a"), 5)

func _flower_patch(pos: Vector2) -> void:
	for offset in [Vector2.ZERO, Vector2(9, -3), Vector2(-7, 4)]:
		draw_circle(pos + offset, 3, Color("#f5d66d"))
		draw_circle(pos + offset + Vector2(3, 0), 2, Color("#f3eee0"))
