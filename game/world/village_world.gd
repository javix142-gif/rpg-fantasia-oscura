class_name VillageWorld
extends Node2D

signal npc_created(npc: VillageNpc)

const WORLD_SIZE := Vector2(960, 640)
var npcs: Array[VillageNpc] = []
var tile_layer: TileMapLayer
var visual_scene: Sprite2D
var collision_layer: Node2D
var world_props_layer: Node2D
var foreground_layer: Node2D
var interactables_layer: Node2D
var npc_layer: Node2D
var ambient_fx_layer: Node2D
var _collision_catalog: Array[Dictionary] = []

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
	tile_layer.name = "Ground"
	tile_layer.set_meta("layer_role", "ground")
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
	visual_scene.name = "AuthoredBackground"
	visual_scene.set_meta("legacy_scene_name", "LiriaAuthoredScene")
	visual_scene.texture = load("res://assets/p1_1/liria_scene.png") as Texture2D
	visual_scene.centered = false
	visual_scene.position = Vector2.ZERO
	visual_scene.z_index = -10
	visual_scene.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(visual_scene)

func _create_render_layers() -> void:
	var paths_layer := Node2D.new()
	paths_layer.name = "PathsLayer"
	add_child(paths_layer)
	world_props_layer = Node2D.new()
	world_props_layer.name = "WorldProps"
	world_props_layer.y_sort_enabled = true
	add_child(world_props_layer)
	collision_layer = Node2D.new()
	collision_layer.name = "WorldCollision"
	collision_layer.set_meta("legacy_layer_name", "CollisionLayer")
	add_child(collision_layer)
	foreground_layer = Node2D.new()
	foreground_layer.name = "Foreground"
	foreground_layer.y_sort_enabled = true
	add_child(foreground_layer)
	interactables_layer = Node2D.new()
	interactables_layer.name = "Interactables"
	add_child(interactables_layer)
	npc_layer = Node2D.new()
	npc_layer.name = "NPC"
	npc_layer.y_sort_enabled = true
	add_child(npc_layer)
	ambient_fx_layer = Node2D.new()
	ambient_fx_layer.name = "AmbientFX"
	add_child(ambient_fx_layer)
	var foreground_accents := LiriaForeground.new()
	foreground_layer.add_child(foreground_accents)
	var ambient_fx := LiriaAmbientFx.new()
	ambient_fx_layer.add_child(ambient_fx)

func _create_boundaries() -> void:
	_add_rect_blocker("PERIMETER_NORTH", Vector2(480, -8), Vector2(960, 32), "boundary")
	_add_rect_blocker("PERIMETER_SOUTH", Vector2(480, 648), Vector2(960, 32), "boundary")
	_add_rect_blocker("PERIMETER_WEST", Vector2(-8, 320), Vector2(32, 640), "boundary")
	_add_rect_blocker("PERIMETER_EAST", Vector2(968, 320), Vector2(32, 640), "boundary")

func _create_scene_collisions() -> void:
	# The authored scene is a single visual background.  These footprints live
	# in a separate physical layer and cover only walls, trunks, fence rails and
	# solid props; roofs, canopies, water and foliage remain visual decoration.
	# Splitting buildings into wall segments leaves their visible door fronts
	# readable instead of creating one large invisible rectangle.
	_add_rect_blocker("HOUSE_MAIN_REAR", Vector2(192, 118), Vector2(226, 54), "house")
	_add_rect_blocker("HOUSE_MAIN_WEST_WALL", Vector2(110, 198), Vector2(66, 112), "house")
	_add_rect_blocker("HOUSE_MAIN_EAST_WALL", Vector2(276, 198), Vector2(66, 112), "house")
	_add_rect_blocker("HOUSE_MAIN_THRESHOLD", Vector2(193, 263), Vector2(88, 16), "house")

	_add_rect_blocker("SMITHY_REAR", Vector2(510, 100), Vector2(224, 50), "smithy")
	_add_rect_blocker("SMITHY_WEST_WALL", Vector2(427, 166), Vector2(56, 90), "smithy")
	_add_rect_blocker("SMITHY_EAST_WALL", Vector2(594, 166), Vector2(56, 90), "smithy")
	_add_rect_blocker("SMITHY_THRESHOLD", Vector2(510, 219), Vector2(86, 14), "smithy")

	_add_rect_blocker("MARKET_REAR", Vector2(808, 132), Vector2(204, 52), "market")
	_add_rect_blocker("MARKET_COUNTER", Vector2(808, 218), Vector2(206, 34), "market")

	_add_circle_blocker("FOUNTAIN_BASIN", Vector2(480, 350), 47.0, "fountain")

	_add_rect_blocker("FENCE_WEST_TOP", Vector2(126, 420), Vector2(196, 10), "fence")
	_add_rect_blocker("FENCE_WEST_LEFT", Vector2(34, 500), Vector2(10, 152), "fence")
	_add_rect_blocker("FENCE_WEST_RIGHT", Vector2(346, 500), Vector2(10, 152), "fence")
	_add_rect_blocker("FENCE_WEST_BOTTOM", Vector2(190, 576), Vector2(306, 10), "fence")
	# Leave a visible west-side gate into the garden so the plaza route does not
	# become an arbitrary invisible wall around the fountain.
	_add_rect_blocker("FENCE_EAST_TOP_WEST", Vector2(540, 426), Vector2(100, 10), "fence")
	_add_rect_blocker("FENCE_EAST_TOP_EAST", Vector2(752, 426), Vector2(176, 10), "fence")
	# The upper-left corner is the visible garden entrance. Starting this rail at
	# y=500 leaves the authored plaza-to-gate corridor open instead of trapping
	# the normal spawn behind an invisible vertical wall.
	_add_rect_blocker("FENCE_EAST_LEFT", Vector2(438, 570), Vector2(10, 142), "fence")
	_add_rect_blocker("FENCE_EAST_RIGHT", Vector2(850, 500), Vector2(10, 142), "fence")
	_add_rect_blocker("FENCE_EAST_BOTTOM", Vector2(644, 578), Vector2(402, 10), "fence")
	# Raised beds are solid only on their visible wooden/crop footprints. The
	# open soil corridors and gates remain traversable for the route tests.
	_add_rect_blocker("GARDEN_WEST_RAISED_BED", Vector2(126, 469), Vector2(78, 22), "garden")
	_add_rect_blocker("GARDEN_WEST_TOOL_SHED", Vector2(70, 440), Vector2(26, 26), "garden")
	_add_rect_blocker("GARDEN_EAST_BEDS_NORTH", Vector2(705, 468), Vector2(154, 24), "garden")
	_add_rect_blocker("GARDEN_EAST_BEDS_SOUTH", Vector2(695, 533), Vector2(176, 24), "garden")

	_add_circle_blocker("TREE_ORCHARD_TRUNK", Vector2(91, 383), 18.0, "tree")
	_add_circle_blocker("TREE_NORTH_TRUNK", Vector2(566, 82), 18.0, "tree")
	_add_circle_blocker("TREE_EAST_TRUNK", Vector2(836, 384), 18.0, "tree")

	_add_circle_blocker("PROP_WEST_BARREL", Vector2(337, 244), 12.0, "prop")
	_add_circle_blocker("PROP_SMITHY_BARREL", Vector2(638, 214), 12.0, "prop")
	_add_rect_blocker("PROP_SMITHY_ANVIL", Vector2(565, 215), Vector2(42, 20), "prop")
	_add_rect_blocker("PROP_MARKET_CRATE", Vector2(891, 224), Vector2(24, 20), "prop")

func _add_rect_blocker(collision_id: String, center: Vector2, size: Vector2, category: String) -> void:
	if collision_layer == null:
		return
	var body := StaticBody2D.new()
	body.name = "Collider_" + collision_id
	body.collision_layer = 1
	body.collision_mask = 1
	body.set_meta("collision_id", collision_id)
	body.set_meta("collision_category", category)
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	shape_node.shape = shape
	shape_node.name = "Footprint"
	shape_node.position = center
	body.add_child(shape_node)
	collision_layer.add_child(body)
	_collision_catalog.append({"id": collision_id, "type": "rect", "center": center, "size": size, "category": category})

func _add_circle_blocker(collision_id: String, center: Vector2, radius: float, category: String) -> void:
	if collision_layer == null:
		return
	var body := StaticBody2D.new()
	body.name = "Collider_" + collision_id
	body.collision_layer = 1
	body.collision_mask = 1
	body.set_meta("collision_id", collision_id)
	body.set_meta("collision_category", category)
	var shape_node := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = radius
	shape_node.shape = shape
	shape_node.name = "Footprint"
	shape_node.position = center
	body.add_child(shape_node)
	collision_layer.add_child(body)
	_collision_catalog.append({"id": collision_id, "type": "circle", "center": center, "radius": radius, "category": category})

func collision_catalog() -> Array[Dictionary]:
	return _collision_catalog.duplicate(true)

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
	npc_layer.add_child(npc)
	npcs.append(npc)
	npc_created.emit(npc)

func update_quest_markers(status: String, stage: int) -> VillageNpc:
	var target_id := ""
	var marker_kind := ""
	match status:
		"NOT_STARTED":
			target_id = "NPC_IRIA"
			marker_kind = "!"
		"ACTIVE":
			if stage < 3:
				target_id = "NPC_HALVEN"
				marker_kind = "!"
			else:
				target_id = "NPC_IRIA"
				marker_kind = "?"
	for npc in npcs:
		npc.set_quest_marker(marker_kind if npc.actor_id == target_id else "")
	return get_npc(target_id)

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
