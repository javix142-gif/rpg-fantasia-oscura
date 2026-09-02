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
	state.call("new_game", "P1.3 Player", "CLASS_WARRIOR")
	_test_sheet()
	var host := Node2D.new()
	root.add_child(host)
	var world = WORLD_SCRIPT.new()
	host.add_child(world)
	var player = PLAYER_SCRIPT.new()
	player.global_position = Vector2(480, 454)
	world.add_child(player)
	await process_frame
	await physics_frame
	_test_runtime(player)
	await _test_directions(player)
	player.set_virtual_input(Vector2.ZERO)
	host.queue_free()
	if failures.is_empty():
		print("P13_PLAYER_VISUAL_CONTRACT=PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("P13_PLAYER_VISUAL_CONTRACT=FAIL")
	quit(1)

func _test_sheet() -> void:
	var path := ProjectSettings.globalize_path("res://assets/p1_1/player_sheet.png")
	var image := Image.load_from_file(path)
	_check(image != null, "player atlas loads")
	if image == null:
		return
	_check(image.get_format() == Image.FORMAT_RGBA8, "player atlas is RGBA8")
	_check(image.get_width() == 384 and image.get_height() == 512, "player atlas is 6x8 cells")
	var artifact_pixels := 0
	var minimum_height := 999
	var maximum_height := 0
	for row in range(8):
		for column in range(6):
			var frame := image.get_region(Rect2i(column * 64, row * 64, 64, 64))
			var used := frame.get_used_rect()
			_check(used.size.x > 0 and used.size.y > 0, "frame has pixels r%d c%d" % [row, column])
			_check(used.size.y >= 50, "frame has a stable actor envelope r%d c%d" % [row, column])
			_check(used.position.y <= 8 and used.end.y >= 58, "frame keeps common foot canvas r%d c%d" % [row, column])
			minimum_height = mini(minimum_height, used.size.y)
			maximum_height = maxi(maximum_height, used.size.y)
			artifact_pixels += _alpha_artifacts(frame)
	_check(minimum_height >= 50 and maximum_height - minimum_height <= 6, "directional frames share visible scale")
	print("PLAYER_ALPHA_ARTIFACT_PIXELS=%d" % artifact_pixels)
	_check(artifact_pixels == 0, "player atlas has no partial alpha or transparent RGB residue")
	var npc_path := ProjectSettings.globalize_path("res://assets/p1_1/npc_sheet.png")
	var npc_image := Image.load_from_file(npc_path)
	_check(npc_image != null, "npc atlas loads for scale comparison")
	if npc_image != null:
		var player_used := image.get_region(Rect2i(0, 0, 64, 64)).get_used_rect()
		var npc_used := npc_image.get_region(Rect2i(0, 0, 64, 64)).get_used_rect()
		_check(float(player_used.size.y) / float(maxi(1, npc_used.size.y)) <= 1.35, "player scale remains close to NPC scale")

func _alpha_artifacts(frame: Image) -> int:
	var count := 0
	for y in range(frame.get_height()):
		for x in range(frame.get_width()):
			var pixel := frame.get_pixel(x, y)
			if pixel.a > 0.001 and pixel.a < 0.999:
				count += 1
			elif pixel.a <= 0.001 and maxf(pixel.r, maxf(pixel.g, pixel.b)) > 0.02:
				count += 1
	return count

func _test_runtime(player: PlayerController) -> void:
	var sprite := player.get_node_or_null("PlayerAnimatedSprite") as AnimatedSprite2D
	_check(sprite != null, "player uses AnimatedSprite2D")
	if sprite == null:
		return
	_check(is_equal_approx(sprite.scale.x, PlayerController.ACTOR_VISUAL_SCALE), "player display scale is explicit")
	_check(not sprite.flip_h, "player does not use runtime mirroring")
	for direction in DIRECTIONS:
		_check(player.get_animation_frame_count("idle", direction) == 2, "idle has two stable frames: " + direction)
		_check(player.get_animation_frame_count("walk", direction) == 4, "walk has four stable frames: " + direction)

func _test_directions(player: PlayerController) -> void:
	var sprite := player.get_node_or_null("PlayerAnimatedSprite") as AnimatedSprite2D
	if sprite == null:
		return
	for direction in DIRECTIONS:
		player.set_virtual_input(INPUTS[direction])
		await physics_frame
		_check(player.direction8 == direction, "input and facing agree: " + direction)
		_check(sprite.animation == "walk_" + direction, "walk animation agrees with input: " + direction)
		_check(not sprite.flip_h, "no flip on runtime direction: " + direction)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
