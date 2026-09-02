extends SceneTree

const PLAYER_SCRIPT = preload("res://world/player_controller.gd")
const WORLD_SCRIPT = preload("res://world/village_world.gd")
const DIRECTIONS: Array[String] = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
const INPUTS: Dictionary = {
	"N": Vector2(0, -1),
	"NE": Vector2(1, -1),
	"E": Vector2(1, 0),
	"SE": Vector2(1, 1),
	"S": Vector2(0, 1),
	"SW": Vector2(-1, 1),
	"W": Vector2(-1, 0),
	"NW": Vector2(-1, -1)
}

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var state := root.get_node_or_null("GameState")
	_check(state != null, "GameState autoload available")
	if state == null:
		quit(1)
		return
	state.call("new_game", "P1.2 Player", "CLASS_WARRIOR")
	var host := Node2D.new()
	root.add_child(host)
	var world = WORLD_SCRIPT.new()
	host.add_child(world)
	var player = PLAYER_SCRIPT.new()
	player.global_position = state.call("get_position")
	world.add_child(player)
	await process_frame
	await physics_frame
	_test_sheet_integrity()
	_test_runtime_facing(player)
	host.queue_free()
	if failures.is_empty():
		print("P12_PLAYER_CONTRACT=PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("P12_PLAYER_CONTRACT=FAIL")
	quit(1)

func _test_sheet_integrity() -> void:
	var path := ProjectSettings.globalize_path("res://assets/p1_1/player_sheet.png")
	var image := Image.load_from_file(path)
	_check(image != null, "player atlas loads")
	if image == null:
		return
	_check(image.get_format() == Image.FORMAT_RGBA8, "player atlas is RGBA8")
	_check(image.get_width() == 384 and image.get_height() == 512, "player atlas is 6x8 cells")
	for row in range(8):
		for column in range(6):
			var frame := image.get_region(Rect2i(column * 64, row * 64, 64, 64))
			var used := frame.get_used_rect()
			_check(used.size.x > 0 and used.size.y > 0, "frame has pixels r%d c%d" % [row, column])
			_check(used.size.y >= 50, "frame is not vertically split r%d c%d" % [row, column])
			_check(used.position.y <= 8 and used.end.y >= 58, "frame keeps common foot canvas r%d c%d" % [row, column])
			for y in range(64):
				for x in range(64):
					var alpha := frame.get_pixel(x, y).a
					_check(alpha < 0.001 or alpha > 0.999, "alpha is binary r%d c%d" % [row, column])
					if not failures.is_empty() and failures.back().begins_with("alpha is binary"):
						return

func _test_runtime_facing(player: PlayerController) -> void:
	var sprite := player.get_node_or_null("PlayerAnimatedSprite") as AnimatedSprite2D
	_check(sprite != null, "player uses the animated sprite node")
	if sprite == null:
		return
	for direction in DIRECTIONS:
		_check(player.get_animation_frame_count("idle", direction) == 2, "idle has two frames: " + direction)
		_check(player.get_animation_frame_count("walk", direction) == 4, "walk has four frames: " + direction)
		player.set_virtual_input(INPUTS[direction])
		await physics_frame
		_check(player.direction8 == direction, "movement facing maps to " + direction)
		_check(sprite.animation == "walk_" + direction, "animation row maps to " + direction)
		_check(not sprite.flip_h, "runtime mirroring disabled: " + direction)
	player.set_virtual_input(Vector2.ZERO)
	await physics_frame
	_check(sprite.animation == "idle_" + player.direction8, "idle preserves last facing")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
