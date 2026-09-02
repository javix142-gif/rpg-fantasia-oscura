extends SceneTree

const CELL_SIZE := 64
const DIRECTIONS: Array[String] = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
const ROUTE_LINES: Array[Array] = [
	[Vector2(480, 454), Vector2(370, 400)],
	[Vector2(370, 400), Vector2(370, 330), Vector2(365, 270), Vector2(655, 280)],
	[Vector2(480, 454), Vector2(400, 450), Vector2(400, 270), Vector2(700, 270), Vector2(820, 342), Vector2(808, 342)],
	[Vector2(480, 454), Vector2(370, 400), Vector2(330, 400), Vector2(260, 480)]
]

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var evidence_dir := ProjectSettings.globalize_path("res://../art/debug")
	DirAccess.make_dir_recursive_absolute(evidence_dir)
	var player_ok := _write_player_contact_sheet(evidence_dir.path_join("p13_player_contact_sheet.png"))
	var host := Node2D.new()
	root.add_child(host)
	var world := VillageWorld.new()
	host.add_child(world)
	await process_frame
	var collision_ok := _write_collision_map(world, evidence_dir.path_join("p13_collision_map.png"))
	host.queue_free()
	print("P13_EVIDENCE_GENERATION=%s" % ("PASS" if player_ok and collision_ok else "FAIL"))
	quit(0 if player_ok and collision_ok else 1)

func _write_player_contact_sheet(output_path: String) -> bool:
	var source := Image.load_from_file(ProjectSettings.globalize_path("res://assets/p1_1/player_sheet.png"))
	if source == null:
		return false
	var width := 16 + 2 * CELL_SIZE + 14 + 4 * CELL_SIZE + 16
	var height := 24 + DIRECTIONS.size() * (CELL_SIZE + 8)
	var output := Image.create(width, height, false, Image.FORMAT_RGBA8)
	output.fill(Color("#101820"))
	# Warm top band = idle samples; green top band = walk samples. Direction
	# rows are ordered N, NE, E, SE, S, SW, W, NW as in the runtime contract.
	_fill_rect(output, Rect2i(12, 6, 2 * CELL_SIZE, 5), Color("#d0a45b"))
	_fill_rect(output, Rect2i(12 + 2 * CELL_SIZE + 14, 6, 4 * CELL_SIZE, 5), Color("#6e9a78"))
	for row in range(DIRECTIONS.size()):
		var y := 24 + row * (CELL_SIZE + 8)
		_fill_rect(output, Rect2i(8, y - 2, width - 16, CELL_SIZE + 4), Color(0.08, 0.12, 0.15, 0.92))
		for column in range(2):
			var idle := source.get_region(Rect2i(column * CELL_SIZE, row * CELL_SIZE, CELL_SIZE, CELL_SIZE))
			output.blit_rect(idle, Rect2i(Vector2i.ZERO, idle.get_size()), Vector2i(12 + column * CELL_SIZE, y))
		for column in range(4):
			var walk := source.get_region(Rect2i((column + 2) * CELL_SIZE, row * CELL_SIZE, CELL_SIZE, CELL_SIZE))
			output.blit_rect(walk, Rect2i(Vector2i.ZERO, walk.get_size()), Vector2i(12 + 2 * CELL_SIZE + 14 + column * CELL_SIZE, y))
		_fill_rect(output, Rect2i(12 + 2 * CELL_SIZE + 6, y + 2, 2, CELL_SIZE - 4), Color("#d0a45b"))
	return output.save_png(output_path) == OK

func _write_collision_map(world: VillageWorld, output_path: String) -> bool:
	var background := Image.load_from_file(ProjectSettings.globalize_path("res://assets/p1_1/liria_scene.png"))
	if background == null:
		return false
	background.convert(Image.FORMAT_RGBA8)
	for spec in world.collision_catalog():
		var solid := Color(0.88, 0.23, 0.22, 0.54)
		var border := Color(1.0, 0.72, 0.33, 0.92)
		if String(spec.get("category", "")) == "fountain":
			solid = Color(0.27, 0.76, 0.86, 0.52)
			border = Color(0.70, 0.94, 0.95, 0.92)
		elif String(spec.get("category", "")) in ["tree", "garden"]:
			solid = Color(0.34, 0.70, 0.34, 0.48)
			border = Color(0.78, 0.94, 0.46, 0.92)
		if String(spec.get("type", "")) == "circle":
			var center: Vector2 = spec.get("center", Vector2.ZERO)
			_draw_circle(background, center, float(spec.get("radius", 0.0)), solid, border)
		else:
			var center: Vector2 = spec.get("center", Vector2.ZERO)
			var size: Vector2 = spec.get("size", Vector2.ZERO)
			_draw_rect(background, Rect2(center - size * 0.5, size), solid, border)
	for npc in world.npcs:
		_draw_circle(background, npc.global_position, 34.0, Color(0.25, 0.48, 0.91, 0.16), Color(0.48, 0.75, 1.0, 0.84))
	for route in ROUTE_LINES:
		for index in range(route.size() - 1):
			_draw_line(background, route[index], route[index + 1], Color(0.38, 0.92, 0.48, 0.78), 2.0)
	_draw_circle(background, Vector2(480, 454), 7.0, Color(0.96, 0.76, 0.20, 0.56), Color(1.0, 0.93, 0.50, 0.96))
	return background.save_png(output_path) == OK

func _fill_rect(image: Image, rect: Rect2i, color: Color) -> void:
	var left := maxi(0, rect.position.x)
	var top := maxi(0, rect.position.y)
	var right := mini(image.get_width(), rect.end.x)
	var bottom := mini(image.get_height(), rect.end.y)
	for y in range(top, bottom):
		for x in range(left, right):
			image.set_pixel(x, y, color)

func _draw_rect(image: Image, rect: Rect2, fill: Color, border: Color) -> void:
	_fill_rect(image, Rect2i(rect.position, rect.size), fill)
	var top_left := Vector2i(floori(rect.position.x), floori(rect.position.y))
	var bottom_right := Vector2i(ceili(rect.end.x), ceili(rect.end.y))
	for x in range(top_left.x, bottom_right.x + 1):
		_blend_pixel(image, Vector2i(x, top_left.y), border)
		_blend_pixel(image, Vector2i(x, bottom_right.y), border)
	for y in range(top_left.y, bottom_right.y + 1):
		_blend_pixel(image, Vector2i(top_left.x, y), border)
		_blend_pixel(image, Vector2i(bottom_right.x, y), border)

func _draw_circle(image: Image, center: Vector2, radius: float, fill: Color, border: Color) -> void:
	var origin := Vector2i(floori(center.x), floori(center.y))
	var radius_i := ceili(radius)
	for y in range(-radius_i, radius_i + 1):
		for x in range(-radius_i, radius_i + 1):
			var distance := Vector2(x, y).length()
			if distance <= radius:
				_blend_pixel(image, origin + Vector2i(x, y), fill)
				if distance >= radius - 1.7:
					_blend_pixel(image, origin + Vector2i(x, y), border)

func _draw_line(image: Image, start: Vector2, finish: Vector2, color: Color, width: float) -> void:
	var distance := start.distance_to(finish)
	var steps := maxi(1, ceili(distance))
	for step in range(steps + 1):
		var point := start.lerp(finish, float(step) / float(steps))
		var radius := ceili(width * 0.5)
		for y in range(-radius, radius + 1):
			for x in range(-radius, radius + 1):
				_blend_pixel(image, Vector2i(floori(point.x) + x, floori(point.y) + y), color)

func _blend_pixel(image: Image, point: Vector2i, color: Color) -> void:
	if point.x < 0 or point.y < 0 or point.x >= image.get_width() or point.y >= image.get_height():
		return
	var base := image.get_pixelv(point)
	image.set_pixelv(point, base.lerp(Color(color, 1.0), color.a))
