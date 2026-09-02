extends SceneTree

const WORLD_SCRIPT = preload("res://world/village_world.gd")
const PLAYER_SCRIPT = preload("res://world/player_controller.gd")
const REQUIRED_COLLISIONS: Array[String] = [
	"FOUNTAIN_BASIN",
	"HOUSE_MAIN_REAR",
	"HOUSE_MAIN_WEST_WALL",
	"HOUSE_MAIN_EAST_WALL",
	"SMITHY_REAR",
	"SMITHY_WEST_WALL",
	"MARKET_REAR",
	"MARKET_COUNTER",
	"FENCE_WEST_TOP",
	"FENCE_EAST_TOP_WEST",
	"TREE_ORCHARD_TRUNK",
	"TREE_NORTH_TRUNK",
	"TREE_EAST_TRUNK",
	"GARDEN_WEST_RAISED_BED",
	"GARDEN_EAST_BEDS_NORTH",
	"PROP_WEST_BARREL",
	"PROP_SMITHY_ANVIL",
	"PROP_MARKET_CRATE"
]
const REQUIRED_LAYERS: Array[String] = ["Ground", "AuthoredBackground", "WorldProps", "WorldCollision", "Foreground", "Interactables", "NPC", "AmbientFX"]
const ROUTES: Dictionary = {
	"SPAWN_TO_IRIA": [[Vector2(480, 454), Vector2(370, 400)]],
	"IRIA_TO_HALVEN": [[Vector2(370, 400), Vector2(370, 330)], [Vector2(370, 330), Vector2(365, 270)], [Vector2(365, 270), Vector2(655, 280)]],
	"HALVEN_TO_IRIA": [[Vector2(655, 280), Vector2(365, 270)], [Vector2(365, 270), Vector2(370, 330)], [Vector2(370, 330), Vector2(370, 400)]],
	"PLAZA_TO_SMITHY": [[Vector2(480, 454), Vector2(370, 330)], [Vector2(370, 330), Vector2(365, 270)], [Vector2(365, 270), Vector2(570, 262)]],
	"PLAZA_TO_MARKET": [[Vector2(480, 454), Vector2(400, 450)], [Vector2(400, 450), Vector2(400, 270)], [Vector2(400, 270), Vector2(700, 270)], [Vector2(700, 270), Vector2(820, 342)], [Vector2(820, 342), Vector2(808, 342)]],
	"PLAZA_TO_HUERTA": [[Vector2(480, 454), Vector2(370, 400)], [Vector2(370, 400), Vector2(330, 400)], [Vector2(330, 400), Vector2(260, 480)]]
}

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var host := Node2D.new()
	root.add_child(host)
	var world = WORLD_SCRIPT.new()
	host.add_child(world)
	await process_frame
	await physics_frame
	_check_layers(world)
	var catalog: Array[Dictionary] = world.collision_catalog()
	_test_catalog(catalog)
	_test_no_absurd_overlaps(catalog)
	_test_routes(catalog)
	var player = PLAYER_SCRIPT.new()
	player.global_position = Vector2(480, 454)
	world.add_child(player)
	await physics_frame
	_test_landmark_queries(world, player)
	host.queue_free()
	if failures.is_empty():
		print("P13_WORLD_PHYSICS_CONTRACT=PASS objects=%d routes=%d" % [catalog.size(), ROUTES.size()])
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("P13_WORLD_PHYSICS_CONTRACT=FAIL")
	quit(1)

func _check_layers(world: VillageWorld) -> void:
	for layer_name in REQUIRED_LAYERS:
		_check(world.get_node_or_null(layer_name) != null, "world layer exists: " + layer_name)
	_check(world.get_node_or_null("WorldCollision") == world.collision_layer, "WorldCollision owns physical footprints")
	_check(world.get_node_or_null("Foreground/ForegroundAccents") != null, "foreground depth accents exist")
	_check(world.get_node_or_null("AmbientFX/AmbientFX") != null, "ambient FX layer is populated")

func _test_catalog(catalog: Array[Dictionary]) -> void:
	var ids: Dictionary = {}
	for spec in catalog:
		var collision_id := String(spec.get("id", ""))
		_check(not collision_id.is_empty() and not ids.has(collision_id), "collision IDs are unique")
		ids[collision_id] = true
		_check(String(spec.get("category", "")) in ["boundary", "house", "smithy", "market", "fountain", "fence", "tree", "garden", "prop"], "collision category is explicit")
		_check((String(spec.get("type", "")) == "circle" and float(spec.get("radius", 0.0)) > 0.0) or (String(spec.get("type", "")) == "rect" and (spec.get("size", Vector2.ZERO) as Vector2).x > 0.0), "collision footprint has size: " + collision_id)
	for required in REQUIRED_COLLISIONS:
		_check(ids.has(required), "collision catalog contains " + required)
	_check(catalog.size() >= 35, "map has maintained boundaries, landmarks and garden footprints")

func _test_no_absurd_overlaps(catalog: Array[Dictionary]) -> void:
	for first_index in range(catalog.size()):
		var first := catalog[first_index]
		if String(first.get("id", "")).begins_with("PERIMETER"):
			continue
		var first_rect := _footprint_rect(first)
		for second_index in range(first_index + 1, catalog.size()):
			var second := catalog[second_index]
			if String(second.get("id", "")).begins_with("PERIMETER"):
				continue
			var overlap := first_rect.intersection(_footprint_rect(second)).get_area()
			if overlap > 28.0 and not _expected_join(first, second):
				_check(false, "solid footprints do not overlap absurdly: %s/%s" % [first.get("id", ""), second.get("id", "")])

func _expected_join(first: Dictionary, second: Dictionary) -> bool:
	var first_category := String(first.get("category", ""))
	var second_category := String(second.get("category", ""))
	if first_category == second_category and first_category in ["house", "smithy", "market", "fence", "garden"]:
		return true
	# A prop/trunk can touch the building footprint it belongs to. This is a
	# deliberate visual seam, not an overlapping corridor.
	return (first_category in ["prop", "tree"] and second_category in ["house", "smithy", "market"]) or (second_category in ["prop", "tree"] and first_category in ["house", "smithy", "market"])

func _test_routes(catalog: Array[Dictionary]) -> void:
	for route_name in ROUTES.keys():
		var segments: Array = ROUTES[route_name]
		for segment in segments:
			var start: Vector2 = segment[0]
			var finish: Vector2 = segment[1]
			_check(_corridor_is_clear(start, finish, catalog), "critical route is clear: " + String(route_name))

func _corridor_is_clear(start: Vector2, finish: Vector2, catalog: Array[Dictionary]) -> bool:
	for step in range(41):
		var point := start.lerp(finish, float(step) / 40.0)
		for spec in catalog:
			if String(spec.get("id", "")).begins_with("PERIMETER"):
				continue
			if _point_hits_footprint(point, spec, 15.0):
				return false
	return true

func _point_hits_footprint(point: Vector2, spec: Dictionary, padding: float) -> bool:
	if String(spec.get("type", "")) == "circle":
		return point.distance_to(spec.get("center", Vector2.ZERO)) <= float(spec.get("radius", 0.0)) + padding
	var size: Vector2 = spec.get("size", Vector2.ZERO)
	var rect := Rect2(spec.get("center", Vector2.ZERO) - size * 0.5, size).grow(padding)
	return rect.has_point(point)

func _footprint_rect(spec: Dictionary) -> Rect2:
	var center: Vector2 = spec.get("center", Vector2.ZERO)
	if String(spec.get("type", "")) == "circle":
		var radius := float(spec.get("radius", 0.0))
		return Rect2(center - Vector2.ONE * radius, Vector2.ONE * radius * 2.0)
	var size: Vector2 = spec.get("size", Vector2.ZERO)
	return Rect2(center - size * 0.5, size)

func _test_landmark_queries(world: VillageWorld, player: PlayerController) -> void:
	var required_probe_ids := ["FOUNTAIN_BASIN", "HOUSE_MAIN_REAR", "SMITHY_REAR", "MARKET_REAR", "GARDEN_WEST_RAISED_BED"]
	var space := player.get_world_2d().direct_space_state
	for collision_id in required_probe_ids:
		var spec := _find_spec(world.collision_catalog(), collision_id)
		if spec.is_empty():
			continue
		var query := PhysicsShapeQueryParameters2D.new()
		if String(spec.get("type", "")) == "circle":
			var circle := CircleShape2D.new()
			circle.radius = minf(float(spec.get("radius", 8.0)), 12.0)
			query.shape = circle
		else:
			var rectangle := RectangleShape2D.new()
			var size: Vector2 = spec.get("size", Vector2(8, 8))
			rectangle.size = Vector2(minf(size.x, 12.0), minf(size.y, 12.0))
			query.shape = rectangle
		query.transform = Transform2D(0.0, spec.get("center", Vector2.ZERO))
		query.collision_mask = 1
		query.exclude = [player.get_rid()]
		var hits := space.intersect_shape(query, 32)
		var found := false
		for hit in hits:
			var collider := hit.get("collider") as Node
			if collider != null and String(collider.get_meta("collision_id", "")) == collision_id:
				found = true
				break
		_check(found, "physics layer exposes " + collision_id)

func _find_spec(catalog: Array[Dictionary], collision_id: String) -> Dictionary:
	for spec in catalog:
		if String(spec.get("id", "")) == collision_id:
			return spec
	return {}

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
