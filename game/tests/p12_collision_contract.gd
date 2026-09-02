extends SceneTree

const PLAYER_SCRIPT = preload("res://world/player_controller.gd")
const WORLD_SCRIPT = preload("res://world/village_world.gd")

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
	"PROP_WEST_BARREL",
	"PROP_SMITHY_BARREL",
	"PROP_SMITHY_ANVIL",
	"PROP_MARKET_CRATE"
]

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var state := root.get_node_or_null("GameState")
	_check(state != null, "GameState autoload available")
	if state == null:
		quit(1)
		return
	state.call("new_game", "P1.2 Collision", "CLASS_WARRIOR")
	var host := Node2D.new()
	root.add_child(host)
	var world = WORLD_SCRIPT.new()
	host.add_child(world)
	var player = PLAYER_SCRIPT.new()
	player.global_position = state.call("get_position")
	host.add_child(player)
	await process_frame
	await physics_frame
	var catalog: Array[Dictionary] = world.collision_catalog()
	_test_catalog(catalog)
	_test_physics_queries(catalog, player)
	await _test_fountain_slide(player)
	host.queue_free()
	if failures.is_empty():
		print("P12_COLLISION_CONTRACT=PASS objects=%d" % catalog.size())
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("P12_COLLISION_CONTRACT=FAIL")
	quit(1)

func _test_catalog(catalog: Array[Dictionary]) -> void:
	var ids: Dictionary = {}
	for spec in catalog:
		ids[String(spec.get("id", ""))] = true
		_check(String(spec.get("category", "")) in ["boundary", "house", "smithy", "market", "fountain", "fence", "tree", "prop"], "collision category is explicit")
	for collision_id in REQUIRED_COLLISIONS:
		_check(ids.has(collision_id), "collision catalog contains " + collision_id)
	_check(catalog.size() >= 25, "map has perimeter plus maintained footprints")

func _test_physics_queries(catalog: Array[Dictionary], player: PlayerController) -> void:
	var space := player.get_world_2d().direct_space_state
	for spec in catalog:
		var collision_id := String(spec.get("id", ""))
		if collision_id.begins_with("PERIMETER"):
			continue
		var query := PhysicsShapeQueryParameters2D.new()
		var probe_size := Vector2(4, 4)
		if String(spec.get("type", "")) == "circle":
			var circle := CircleShape2D.new()
			circle.radius = minf(float(spec.get("radius", 8.0)), 12.0)
			query.shape = circle
		else:
			var rectangle := RectangleShape2D.new()
			var size: Vector2 = spec.get("size", probe_size)
			rectangle.size = Vector2(minf(size.x, 12.0), minf(size.y, 12.0))
			query.shape = rectangle
		var center: Vector2 = spec.get("center", Vector2.ZERO)
		query.transform = Transform2D(0.0, center)
		query.collision_mask = 1
		query.exclude = [player.get_rid()]
		var hits := space.intersect_shape(query, 32)
		var found := false
		for hit in hits:
			var collider := hit.get("collider") as Node
			if collider != null and String(collider.get_meta("collision_id", "")) == collision_id:
				found = true
				break
		_check(found, "physics query finds " + collision_id)

func _test_fountain_slide(player: PlayerController) -> void:
	player.global_position = Vector2(480, 454)
	player.set_virtual_input(Vector2.UP)
	for _frame in range(28):
		await physics_frame
	player.set_virtual_input(Vector2.ZERO)
	await physics_frame
	_check(player.global_position.y > 394.0, "fountain basin blocks the direct approach")
	_check(player.global_position.distance_to(Vector2(480, 350)) > 45.0, "player remains outside fountain footprint")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
