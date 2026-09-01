extends SceneTree

## Deterministic P1 asset processor. It deliberately handles only pixels,
## canvas and hashes; artistic defects are never "fixed" in code.

const MANIFEST_REL := "../art/ASSET_MANIFEST.json"
const MASTER_SOURCE_REL := "../art/source/p1/selected/character_master_source.png"
const LIRIA_SOURCE_REL := "../art/source/p1/selected/liria_environment_source.png"
const PLAYER_OUTPUT_REL := "assets/p1/player_master.png"
const PORTRAIT_OUTPUT_REL := "assets/p1/player_portrait.png"
const LIRIA_OUTPUT_REL := "assets/p1/liria_kit.png"

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
	if not _write_actor_canvas(master, player_out, Vector2i(64, 64), Vector2i(56, 58)):
		return false
	if not _write_portrait_canvas(master, portrait_out):
		return false
	if not _write_nearest(liria, liria_out, Vector2i(768, 512)):
		return false
	return _refresh_manifest_hashes()

func _write_actor_canvas(source: Image, output_path: String, canvas_size: Vector2i, fit_size: Vector2i) -> bool:
	var used := source.get_used_rect()
	if used.size.x <= 0 or used.size.y <= 0:
		used = Rect2i(Vector2i.ZERO, source.get_size())
	var cropped := source.get_region(used)
	var scale := minf(float(fit_size.x) / float(cropped.get_width()), float(fit_size.y) / float(cropped.get_height()))
	var scaled_size := Vector2i(maxi(1, roundi(cropped.get_width() * scale)), maxi(1, roundi(cropped.get_height() * scale)))
	cropped.resize(scaled_size.x, scaled_size.y, Image.INTERPOLATE_NEAREST)
	var canvas := Image.create(canvas_size.x, canvas_size.y, false, Image.FORMAT_RGBA8)
	canvas.fill(Color(0, 0, 0, 0))
	var dest := Vector2i((canvas_size.x - scaled_size.x) / 2, canvas_size.y - scaled_size.y - 4)
	canvas.blit_rect(cropped, Rect2i(Vector2i.ZERO, scaled_size), dest)
	return canvas.save_png(output_path) == OK

func _write_portrait_canvas(source: Image, output_path: String) -> bool:
	var used := source.get_used_rect()
	if used.size.x <= 0 or used.size.y <= 0:
		used = Rect2i(Vector2i.ZERO, source.get_size())
	# Portraits keep face and shoulders; the full-body master remains the sprite source.
	var portrait_height := maxi(1, int(float(used.size.y) * 0.68))
	var cropped := source.get_region(Rect2i(used.position, Vector2i(used.size.x, portrait_height)))
	var scale := minf(86.0 / float(cropped.get_width()), 86.0 / float(cropped.get_height()))
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
	for id in ["ASSET_PLAYER_BASE", "PORTRAIT_PLAYER", "ASSET_LIRIA_KIT"]:
		if not assets.has(id):
			return false
		var entry: Dictionary = assets[id]
		var output_abs := repo_root.path_join(String(entry["output_path"]))
		entry["output_sha256"] = FileAccess.get_sha256(output_abs)
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
			if String(entry.get("type", "")) in ["character_master", "portrait"]:
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
