class_name CSSpatialIndex
extends RefCounted

const CHUNK_SIZE := 512.0
var buildings_by_chunk: Dictionary = {}

func rebuild(buildings: Array) -> void:
	buildings_by_chunk.clear()
	for i in range(buildings.size()):
		register_building(i, buildings[i])

func register_building(index: int, building: Dictionary) -> void:
	var key := _chunk_key(_chunk_coord(building.get("pos", Vector2.ZERO)))
	if not buildings_by_chunk.has(key):
		buildings_by_chunk[key] = []
	var bucket: Array = buildings_by_chunk[key]
	if not index in bucket:
		bucket.append(index)

func nearby_indices(pos: Vector2, radius: float) -> Array:
	var result: Array = []
	var min_c := _chunk_coord(pos - Vector2(radius, radius))
	var max_c := _chunk_coord(pos + Vector2(radius, radius))
	for y in range(min_c.y, max_c.y + 1):
		for x in range(min_c.x, max_c.x + 1):
			var key := _chunk_key(Vector2i(x, y))
			if not buildings_by_chunk.has(key):
				continue
			for idx in buildings_by_chunk[key]:
				if not idx in result:
					result.append(idx)
	return result

func nearest_of_type(buildings: Array, pos: Vector2, max_dist: float, kind: String) -> int:
	var best := -1
	var nearest := max_dist + 1.0
	for idx_variant in nearby_indices(pos, max_dist):
		var idx := int(idx_variant)
		if idx < 0 or idx >= buildings.size():
			continue
		var b: Dictionary = buildings[idx]
		if String(b.get("type", "")) != kind:
			continue
		var bp: Vector2 = b.get("pos", Vector2.ZERO)
		var d := bp.distance_to(pos)
		if d <= max_dist and d < nearest:
			nearest = d
			best = idx
	return best

func nearby_buildings(buildings: Array, pos: Vector2, radius: float) -> Array:
	var result: Array = []
	for idx_variant in nearby_indices(pos, radius):
		var idx := int(idx_variant)
		if idx >= 0 and idx < buildings.size():
			result.append(buildings[idx])
	return result

static func _chunk_coord(pos: Vector2) -> Vector2i:
	return Vector2i(int(floor(pos.x / CHUNK_SIZE)), int(floor(pos.y / CHUNK_SIZE)))

static func _chunk_key(coord: Vector2i) -> String:
	return "%d,%d" % [coord.x, coord.y]
