class_name VillageWorld
extends Node2D

signal npc_created(npc: VillageNpc)

const WORLD_SIZE := Vector2(960, 640)
var npcs: Array[VillageNpc] = []
var tile_layer: TileMapLayer
var visual_scene: Sprite2D

func _ready() -> void:
	name = "LiriaNormal"
	y_sort_enabled = true
	_create_tile_layer()
	_create_visual_scene()
	_create_render_layers()
	_create_npcs()
	_create_boundaries()
	_create_scene_collisions()

func _create_tile_layer() -> void:
	# A real TileMapLayer is kept as the extensible ground source. The authored
	# scene sits above it, while later stages can replace individual cells.
	tile_layer = TileMapLayer.new()
	tile_layer.name = "GroundTileMapLayer"
	tile_layer.z_index = -20
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(32, 32)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = load("res://assets/p1_1/liria_ground_tile.png") as Texture2D
	atlas.texture_region_size = Vector2i(32, 32)
	atlas.create_tile(Vector2i.ZERO)
	tile_set.add_source(atlas, 0)
	tile_layer.tile_set = tile_set
	for y in range(20):
		for x in range(30):
			tile_layer.set_cell(Vector2i(x, y), 0, Vector2i.ZERO)
	add_child(tile_layer)

func _create_visual_scene() -> void:
	visual_scene = Sprite2D.new()
	visual_scene.name = "LiriaAuthoredScene"
	visual_scene.texture = load("res://assets/p1_1/liria_scene.png") as Texture2D
	visual_scene.centered = false
	visual_scene.position = Vector2.ZERO
	visual_scene.z_index = -10
	visual_scene.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(visual_scene)

func _create_render_layers() -> void:
	for layer_name in ["PathsLayer", "DecorationLayer", "CollisionLayer", "ForegroundLayer"]:
		var layer := Node2D.new()
		layer.name = layer_name
		layer.y_sort_enabled = layer_name in ["DecorationLayer", "ForegroundLayer"]
		add_child(layer)

func _create_boundaries() -> void:
	for spec in [Rect2(480, 18, 920, 20), Rect2(480, 622, 920, 20), Rect2(18, 320, 20, 600), Rect2(942, 320, 20, 600)]:
		_add_blocker(spec)

func _create_scene_collisions() -> void:
	# Only the physical footprint of structures is blocked; canopies, awnings
	# and foliage remain walkable visual layers.
	for spec in [
		Rect2(88, 96, 230, 176),
		Rect2(406, 76, 226, 150),
		Rect2(704, 112, 220, 166),
		Rect2(72, 438, 188, 54),
		Rect2(760, 438, 156, 54)
	]:
		_add_blocker(spec)

func _add_blocker(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.name = "WorldCollider"
	body.collision_layer = 1
	body.collision_mask = 1
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	shape_node.shape = shape
	shape_node.position = rect.position
	body.add_child(shape_node)
	add_child(body)

func _create_npcs() -> void:
	_add_npc("NPC_IRIA", "Iria", "iria", Vector2(370, 400), Color("#567f69"), Color("#b9574e"), "arco")
	_add_npc("NPC_HALVEN", "Halven", "halven", Vector2(655, 280), Color("#69718a"), Color("#bc8a55"), "bastón")
	_add_npc("NPC_SMITH", "Bram", "smith", Vector2(570, 262), Color("#8b5545"), Color("#e0a84f"), "yunque")
	_add_npc("NPC_MERCHANT", "Nella", "merchant", Vector2(808, 342), Color("#5e6f95"), Color("#e3aa4d"), "fruta")
	_add_npc("NPC_FRIEND", "Tomas", "friend", Vector2(548, 492), Color("#9b6853"), Color("#6e9b74"), "amigo")
	var ambient := [
		["NPC_VILLAGER_A", "Mara", Vector2(176, 342), Color("#7b6382"), Color("#db9d63")],
		["NPC_VILLAGER_B", "Oren", Vector2(286, 520), Color("#52738b"), Color("#d6b16d")],
		["NPC_VILLAGER_C", "Lio", Vector2(352, 300), Color("#9a6d52"), Color("#779b62")],
		["NPC_VILLAGER_D", "Sela", Vector2(872, 310), Color("#8c5f76"), Color("#d0a44e")],
		["NPC_VILLAGER_E", "Perrin", Vector2(470, 548), Color("#536e83"), Color("#b8774f")],
		["NPC_VILLAGER_F", "Yara", Vector2(884, 532), Color("#6f8960"), Color("#c76d58")]
	]
	for item in ambient:
		_add_npc(String(item[0]), String(item[1]), "villager", item[2], item[3], item[4])

func _add_npc(actor_id: String, display_name: String, role: String, spawn_position: Vector2, body_color: Color, accent: Color, accessory: String = "") -> void:
	var npc := VillageNpc.new()
	npc.setup(actor_id, display_name, role, spawn_position, body_color, accent, accessory)
	add_child(npc)
	npcs.append(npc)
	npc_created.emit(npc)

func get_nearest_npc(position: Vector2, radius: float) -> VillageNpc:
	var nearest: VillageNpc
	var best := radius
	for npc in npcs:
		var distance := position.distance_to(npc.global_position)
		if distance < best:
			best = distance
			nearest = npc
	return nearest

func get_npc(actor_id: String) -> VillageNpc:
	for npc in npcs:
		if npc.actor_id == actor_id:
			return npc
	return null
