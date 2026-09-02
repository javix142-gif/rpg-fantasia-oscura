extends SceneTree

## Deterministic P1/P1.1 asset processor. It handles pixels, canvas and
## hashes only; artistic defects are never "fixed" in code.

const MASTER_SOURCE_REL := "../art/source/p1/selected/character_master_source.png"
const LIRIA_SOURCE_REL := "../art/source/p1/selected/liria_environment_source.png"
const PLAYER_OUTPUT_REL := "assets/p1/player_master.png"
const PORTRAIT_OUTPUT_REL := "assets/p1/player_portrait.png"
const LIRIA_OUTPUT_REL := "assets/p1/liria_kit.png"

const P11_PLAYER_SOURCE_REL := "../art/source/p1_1/selected/player_animation_source.png"
const P11_NPC_SOURCE_REL := "../art/source/p1_1/selected/npc_family_source.png"
const P11_LIRIA_SOURCE_REL := "../art/source/p1_1/selected/liria_scene_source.png"
const P11_PLAYER_OUTPUT_REL := "assets/p1_1/player_sheet.png"
const P11_NPC_OUTPUT_REL := "assets/p1_1/npc_sheet.png"
const P11_LIRIA_OUTPUT_REL := "assets/p1_1/liria_scene.png"
const P11_GROUND_OUTPUT_REL := "assets/p1_1/liria_ground_tile.png"

# The selected P1.1 contact sheet is a seven-row source (42 actors), not an
# eight-row source.  The missing compass views are filled from the nearest
# compatible source pose and mirrored into explicit output rows.  Keeping the
# remap here makes the exported atlas deterministic and prevents runtime
# animation code from guessing which frame belongs to a direction.
const P12_PLAYER_DIRECTION_MAP: Array[Dictionary] = [
	{"source_row": 0, "flip_h": false}, # N: back
	{"source_row": 6, "flip_h": false}, # NE: back three-quarter
	{"source_row": 5, "flip_h": true}, # E: mirrored profile
	{"source_row": 3, "flip_h": true}, # SE: front three-quarter
	{"source_row": 4, "flip_h": false}, # S: front
	{"source_row": 1, "flip_h": false}, # SW: front three-quarter
	{"source_row": 5, "flip_h": false}, # W: profile
	{"source_row": 6, "flip_h": true} # NW: mirrored back three-quarter
]

var repo_root: String
var project_root: String

func _initialize() -> void:
	project_root = ProjectSettings.globalize_path("res://").trim_suffix("/")
	repo_root = ProjectSettings.globalize_path("res://../").trim_suffix("/")
	var args := OS.get_cmdline_user_args()
	var ok := _validate() if args.has("--validate") else _process_assets()
	print("ASSET_PIPELINE_" + ("VALIDATION=PASS" if args.has("--validate") and ok else "PROCESS=PASS" if ok else "VALIDATION=FAIL"))
	quit(0 if ok else 1)

func _process_assets() -> bool:
	var source_master := repo_root.path_join(MASTER_SOURCE_REL.trim_prefix("../"))
	var source_liria := repo_root.path_join(LIRIA_SOURCE_REL.trim_prefix("../"))
	var player_out := project_root.path_join(PLAYER_OUTPUT_REL)
	var portrait_out := project_root.path_join(PORTRAIT_OUTPUT_REL)
	var liria_out := project_root.path_join(LIRIA_OUTPUT_REL)
	if not FileAccess.file_exists(source_master) or not FileAccess.file_exists(source_liria):
		push_error("P1 source PNG missing")
		return false
	DirAccess.make_dir_recursive_absolute(player_out.get_base_dir())
	var master := Image.load_from_file(source_master)
	var liria := Image.load_from_file(source_liria)
	if master == null or liria == null:
		push_error("Could not load P1 source PNG")
		return false
	master.convert(Image.FORMAT_RGBA8)
	liria.convert(Image.FORMAT_RGBA8)
	if not _write_actor_canvas(master, player_out, Vector2i(64, 64), Vector2i(52, 54)):
		return false
	if not _write_portrait_canvas(master, portrait_out):
		return false
	if not _write_nearest(liria, liria_out, Vector2i(768, 512)):
		return false
	if not _process_p11_assets():
		return false
	return _refresh_manifest_hashes()

func _process_p11_assets() -> bool:
	var player_source_path := repo_root.path_join(P11_PLAYER_SOURCE_REL.trim_prefix("../"))
	var npc_source_path := repo_root.path_join(P11_NPC_SOURCE_REL.trim_prefix("../"))
	var scene_source_path := repo_root.path_join(P11_LIRIA_SOURCE_REL.trim_prefix("../"))
	for required in [player_source_path, npc_source_path, scene_source_path]:
		if not FileAccess.file_exists(required):
			push_error("P1.1 source PNG missing: " + required)
			return false
	var player_source := Image.load_from_file(player_source_path)
	var npc_source := Image.load_from_file(npc_source_path)
	var scene_source := Image.load_from_file(scene_source_path)
	if player_source == null or npc_source == null or scene_source == null:
		push_error("Could not load P1.1 source PNG")
		return false
	player_source.convert(Image.FORMAT_RGBA8)
	npc_source.convert(Image.FORMAT_RGBA8)
	scene_source.convert(Image.FORMAT_RGBA8)
	var output_dir := project_root.path_join("assets/p1_1")
	DirAccess.make_dir_recursive_absolute(output_dir)
	if not _write_player_sheet(player_source, output_dir.path_join("player_sheet.png")):
		return false
	if not _write_npc_sheet(npc_source, output_dir.path_join("npc_sheet.png")):
		return false
	var scene_out := scene_source.duplicate()
	scene_out.resize(960, 640, Image.INTERPOLATE_NEAREST)
	if scene_out.save_png(output_dir.path_join("liria_scene.png")) != OK:
		return false
	# The TileMapLayer uses a small source tile behind the authored scene. Keeping
	# it real (rather than an empty node) makes the map extensible for later stages.
	var ground := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	ground.fill(Color("#67944f"))
	var grass_patch := scene_source.get_region(Rect2i(0, 0, mini(128, scene_source.get_width()), mini(128, scene_source.get_height())))
	grass_patch.resize(32, 32, Image.INTERPOLATE_NEAREST)
	ground.blit_rect(grass_patch, Rect2i(Vector2i.ZERO, grass_patch.get_size()), Vector2i.ZERO)
	if ground.save_png(output_dir.path_join("liria_ground_tile.png")) != OK:
		return false
	return true

func _write_player_sheet(source: Image, output_path: String) -> bool:
	# The selected source is a six-column by seven-row contact sheet.  Earlier
	# processing assumed eight source rows, which split one actor between rows
	# and shifted all later directions.  Fixed seven-row cells are safe here:
	# each source actor has its own row and the output map below expands it to a
	# complete, explicit eight-direction atlas.
	var columns := 6
	var source_rows := 7
	var output_rows := P12_PLAYER_DIRECTION_MAP.size()
	var output := Image.create(columns * 64, output_rows * 64, false, Image.FORMAT_RGBA8)
	output.fill(Color(0, 0, 0, 0))
	var keyed := source.duplicate()
	_remove_checker_background(keyed)
	var source_regions := _find_character_regions(keyed, columns, source_rows)
	for row in range(output_rows):
		var direction_map: Dictionary = P12_PLAYER_DIRECTION_MAP[row]
		var source_row := int(direction_map["source_row"])
		var flip_h := bool(direction_map["flip_h"])
		for column in range(columns):
			var source_rect: Rect2i = source_regions[source_row * columns + column]
			if source_rect.size.x <= 0 or source_rect.size.y <= 0:
				source_rect = _proportional_rect(keyed, column, columns, source_row, source_rows)
			var frame: Image = keyed.get_region(source_rect)
			if flip_h:
				frame.flip_x()
			var normalized := _normalize_actor(frame, Vector2i(64, 64), Vector2i(52, 54))
			output.blit_rect(normalized, Rect2i(Vector2i.ZERO, normalized.get_size()), Vector2i(column * 64, row * 64))
	return output.save_png(output_path) == OK

func _write_npc_sheet(source: Image, output_path: String) -> bool:
	var output := Image.create(5 * 64, 64, false, Image.FORMAT_RGBA8)
	output.fill(Color(0, 0, 0, 0))
	for column in range(5):
		var source_rect := _proportional_rect(source, column, 5, 0, 1)
		var frame := source.get_region(source_rect)
		var normalized := _normalize_actor(frame, Vector2i(64, 64), Vector2i(52, 54))
		output.blit_rect(normalized, Rect2i(Vector2i.ZERO, normalized.get_size()), Vector2i(column * 64, 0))
	return output.save_png(output_path) == OK

func _proportional_rect(source: Image, column: int, columns: int, row: int, rows: int) -> Rect2i:
	var x0 := roundi(float(column * source.get_width()) / float(columns))
	var x1 := roundi(float((column + 1) * source.get_width()) / float(columns))
	var y0 := roundi(float(row * source.get_height()) / float(rows))
	var y1 := roundi(float((row + 1) * source.get_height()) / float(rows))
	return Rect2i(x0, y0, maxi(1, x1 - x0), maxi(1, y1 - y0))

func _find_character_regions(source: Image, columns: int, rows: int) -> Array[Rect2i]:
	var slots: Array[Rect2i] = []
	for _slot in range(columns * rows):
		slots.append(Rect2i())
	var width := source.get_width()
	var height := source.get_height()
	var visited := PackedByteArray()
	visited.resize(width * height)
	for y in range(height):
		for x in range(width):
			var start_index := y * width + x
			if visited[start_index] == 1 or source.get_pixel(x, y).a < 0.05:
				continue
			var queue: Array[Vector2i] = [Vector2i(x, y)]
			visited[start_index] = 1
			var min_x := x
			var min_y := y
			var max_x := x
			var max_y := y
			var area := 0
			while not queue.is_empty():
				var point: Vector2i = queue.pop_back()
				area += 1
				min_x = mini(min_x, point.x)
				min_y = mini(min_y, point.y)
				max_x = maxi(max_x, point.x)
				max_y = maxi(max_y, point.y)
				for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					var next: Vector2i = point + offset
					if next.x < 0 or next.y < 0 or next.x >= width or next.y >= height:
						continue
					var next_index := next.y * width + next.x
					if visited[next_index] == 1 or source.get_pixelv(next).a < 0.05:
						continue
					visited[next_index] = 1
					queue.push_back(next)
			if area < 100:
				continue
			var rect := Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)
			var center := Vector2(rect.position) + Vector2(rect.size) * 0.5
			var column := clampi(int(floor(center.x / (float(width) / float(columns)))), 0, columns - 1)
			var row := clampi(int(floor(center.y / (float(height) / float(rows)))), 0, rows - 1)
			var slot := row * columns + column
			if slots[slot].size.x <= 0:
				slots[slot] = rect
			else:
				slots[slot] = _merge_rects(slots[slot], rect)
	return slots

func _merge_rects(first: Rect2i, second: Rect2i) -> Rect2i:
	var left := mini(first.position.x, second.position.x)
	var top := mini(first.position.y, second.position.y)
	var right := maxi(first.end.x, second.end.x)
	var bottom := maxi(first.end.y, second.end.y)
	return Rect2i(left, top, right - left, bottom - top)

func _remove_checker_background(image: Image) -> void:
	var width := image.get_width()
	var height := image.get_height()
	var queued := PackedByteArray()
	queued.resize(width * height)
	var queue: Array[Vector2i] = []
	for x in range(width):
		_enqueue_background(image, Vector2i(x, 0), queued, queue)
		_enqueue_background(image, Vector2i(x, height - 1), queued, queue)
	for y in range(height):
		_enqueue_background(image, Vector2i(0, y), queued, queue)
		_enqueue_background(image, Vector2i(width - 1, y), queued, queue)
	while not queue.is_empty():
		var point: Vector2i = queue.pop_back()
		var neighbors := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
		for offset in neighbors:
			var next: Vector2i = point + offset
			if next.x < 0 or next.y < 0 or next.x >= width or next.y >= height:
				continue
			_enqueue_background(image, next, queued, queue)

func _enqueue_background(image: Image, point: Vector2i, queued: PackedByteArray, queue: Array[Vector2i]) -> void:
	var index := point.y * image.get_width() + point.x
	if queued[index] == 1:
		return
	queued[index] = 1
	if _is_checker_pixel(image.get_pixelv(point)):
		image.set_pixelv(point, Color(0, 0, 0, 0))
		queue.push_back(point)

func _is_checker_pixel(color: Color) -> bool:
	if color.a < 0.99:
		return false
	var spread := maxf(color.r, maxf(color.g, color.b)) - minf(color.r, minf(color.g, color.b))
	# The source is an RGB checkerboard with compression/scale variation.  A
	# slightly wider neutral-light threshold removes the fringe pixels attached
	# to the checker without touching the dark outline or the bright sword,
	# which are not connected to the image edge through checker pixels.
	return color.r > 0.74 and color.g > 0.74 and color.b > 0.74 and spread < 0.12

func _normalize_actor(source: Image, canvas_size: Vector2i, fit_size: Vector2i) -> Image:
	var used := source.get_used_rect()
	if used.size.x <= 0 or used.size.y <= 0:
		used = Rect2i(Vector2i.ZERO, source.get_size())
	var cropped := source.get_region(used)
	var scale := minf(float(fit_size.x) / float(maxi(1, cropped.get_width())), float(fit_size.y) / float(maxi(1, cropped.get_height())))
	var scaled_size := Vector2i(maxi(1, roundi(cropped.get_width() * scale)), maxi(1, roundi(cropped.get_height() * scale)))
	cropped.resize(scaled_size.x, scaled_size.y, Image.INTERPOLATE_NEAREST)
	var canvas := Image.create(canvas_size.x, canvas_size.y, false, Image.FORMAT_RGBA8)
	canvas.fill(Color(0, 0, 0, 0))
	var destination := Vector2i((canvas_size.x - scaled_size.x) / 2, canvas_size.y - scaled_size.y - 4)
	canvas.blit_rect(cropped, Rect2i(Vector2i.ZERO, scaled_size), destination)
	_normalize_alpha(canvas)
	return canvas

func _normalize_alpha(image: Image) -> void:
	# Keep actor outputs binary and clear RGB left behind in transparent texels.
	# This avoids interpolation matte/halo bleed on Android without changing the
	# authored palette or applying a blur.
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var pixel := image.get_pixel(x, y)
			if pixel.a < 0.05:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
			elif pixel.a > 0.95:
				image.set_pixel(x, y, Color(pixel.r, pixel.g, pixel.b, 1.0))

func _write_actor_canvas(source: Image, output_path: String, canvas_size: Vector2i, fit_size: Vector2i) -> bool:
	return _normalize_actor(source, canvas_size, fit_size).save_png(output_path) == OK

func _write_portrait_canvas(source: Image, output_path: String) -> bool:
	var used := source.get_used_rect()
	if used.size.x <= 0 or used.size.y <= 0:
		used = Rect2i(Vector2i.ZERO, source.get_size())
	var portrait_height := maxi(1, int(float(used.size.y) * 0.68))
	var cropped := source.get_region(Rect2i(used.position, Vector2i(used.size.x, portrait_height)))
	var scale := minf(86.0 / float(maxi(1, cropped.get_width())), 86.0 / float(maxi(1, cropped.get_height())))
	var scaled_size := Vector2i(maxi(1, roundi(cropped.get_width() * scale)), maxi(1, roundi(cropped.get_height() * scale)))
	cropped.resize(scaled_size.x, scaled_size.y, Image.INTERPOLATE_NEAREST)
	var canvas := Image.create(96, 96, false, Image.FORMAT_RGBA8)
	canvas.fill(Color(0, 0, 0, 0))
	canvas.blit_rect(cropped, Rect2i(Vector2i.ZERO, scaled_size), Vector2i((96 - scaled_size.x) / 2, (96 - scaled_size.y) / 2))
	return canvas.save_png(output_path) == OK

func _write_nearest(source: Image, output_path: String, target_size: Vector2i) -> bool:
	source.resize(target_size.x, target_size.y, Image.INTERPOLATE_NEAREST)
	return source.save_png(output_path) == OK

func _manifest_path() -> String:
	return repo_root.path_join("art/ASSET_MANIFEST.json")

func _load_manifest() -> Dictionary:
	var file := FileAccess.open(_manifest_path(), FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}

func _refresh_manifest_hashes() -> bool:
	var manifest := _load_manifest()
	if manifest.is_empty() or not manifest.has("assets"):
		return false
	var assets: Dictionary = manifest["assets"]
	for id in ["ASSET_PLAYER_BASE", "PORTRAIT_PLAYER", "ASSET_LIRIA_KIT", "ASSET_P11_PLAYER_SHEET", "ASSET_P11_NPC_SHEET", "ASSET_P11_LIRIA_SCENE", "ASSET_P11_LIRIA_GROUND"]:
		if not assets.has(id):
			return false
	for raw_id in assets.keys():
		var id := String(raw_id)
		var entry: Dictionary = assets[id]
		var output_abs := repo_root.path_join(String(entry["output_path"]))
		if FileAccess.file_exists(output_abs):
			entry["output_sha256"] = FileAccess.get_sha256(output_abs)
		var source_rel := String(entry.get("source_path", ""))
		if not source_rel.begins_with("generated:") and FileAccess.file_exists(repo_root.path_join(source_rel)):
			var source_abs := repo_root.path_join(source_rel)
			entry["source_sha256"] = FileAccess.get_sha256(source_abs)
		assets[id] = entry
	manifest["assets"] = assets
	var out := FileAccess.open(_manifest_path(), FileAccess.WRITE)
	if out == null:
		return false
	out.store_string(JSON.stringify(manifest, "\t") + "\n")
	return true

func _validate() -> bool:
	var manifest := _load_manifest()
	if manifest.get("schema_version", 0) != 1 or manifest.get("style_version", "") != "P1_PALETTE_V1" or manifest.get("stage", "") != "P1":
		return false
	var assets: Dictionary = manifest.get("assets", {})
	if assets.is_empty():
		return false
	var seen := {}
	for raw_id in assets.keys():
		var id := String(raw_id)
		if id.is_empty() or seen.has(id):
			return false
		seen[id] = true
		var entry: Dictionary = assets[raw_id]
		for field in ["id", "stage", "status", "type", "source_path", "output_path", "dimensions", "cell_size", "frame_count", "pivot", "processing", "generation_attempts", "provenance", "visual_qa_status"]:
			if not entry.has(field):
				return false
		var output_rel := String(entry["output_path"])
		var output_abs := repo_root.path_join(output_rel)
		if not FileAccess.file_exists(output_abs):
			return false
		var source_rel := String(entry["source_path"])
		if source_rel.begins_with("references/") or source_rel.begins_with("../references/"):
			return false
		if source_rel.begins_with("generated:"):
			continue
		var source_abs := repo_root.path_join(source_rel)
		if not FileAccess.file_exists(source_abs):
			return false
		if entry.get("source_sha256", "") != FileAccess.get_sha256(source_abs):
			return false
		if entry.get("output_sha256", "") != FileAccess.get_sha256(output_abs):
			return false
		if output_rel.ends_with(".png"):
			var image := Image.load_from_file(output_abs)
			var dimensions: Array = entry["dimensions"]
			if image == null or image.get_format() != Image.FORMAT_RGBA8 or image.get_width() != int(dimensions[0]) or image.get_height() != int(dimensions[1]):
				return false
			var pivot: Array = entry["pivot"]
			if float(pivot[0]) < 0.0 or float(pivot[1]) < 0.0 or float(pivot[0]) > float(dimensions[0]) or float(pivot[1]) > float(dimensions[1]):
				return false
			if String(entry.get("type", "")) in ["character_master", "portrait", "player_animation_sheet", "npc_sprite_sheet"]:
				var has_transparent := false
				for y in range(image.get_height()):
					for x in range(image.get_width()):
						if image.get_pixel(x, y).a < 0.999:
							has_transparent = true
							break
					if has_transparent:
						break
				if not has_transparent:
					return false
	return true
