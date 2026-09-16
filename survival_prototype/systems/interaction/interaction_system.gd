class_name CSInteractionSystem
extends RefCounted

static func can_interact(host: Node) -> bool:
	return host.menu_mode == "" and host.placement_type == "" and host.combat_state == "idle" and host.hurt_stagger <= 0.0 and host.harvest_timer <= 0.0

static func nearest_resource(host: Node, max_dist: float) -> Dictionary:
	var best: Dictionary = {}
	var nearest := max_dist + 1.0
	var cc := host._chunk_coord(host.player_pos)
	for y in range(cc.y - 1, cc.y + 2):
		for x in range(cc.x - 1, cc.x + 2):
			var key := host._chunk_key(Vector2i(x, y))
			if not host.loaded_chunks.has(key):
				continue
			var chunk: Dictionary = host.loaded_chunks[key]
			for r_variant in chunk["resources"]:
				var r: Dictionary = r_variant
				var rp: Vector2 = r["pos"]
				var d := rp.distance_to(host.player_pos)
				if d <= max_dist and d < nearest:
					best = r
					nearest = d
	return best

static func nearest_chest(host: Node, max_dist: float) -> int:
	if host.spatial_index == null:
		return -1
	return host.spatial_index.nearest_of_type(host.buildings, host.player_pos, max_dist, "cofre")

static func interaction_label(host: Node) -> String:
	if host.menu_mode != "" or host.placement_type != "":
		return ""
	var chest := nearest_chest(host, 46.0)
	if chest >= 0:
		return "ABRIR COFRE"
	var r := nearest_resource(host, 48.0)
	if not r.is_empty():
		var kind := String(r["type"])
		if kind == "arbol": return "TALAR" if host.equipped_tool == "hacha" else "REQUIERE HACHA"
		if kind == "roca" or kind == "mineral": return "PICAR" if host.equipped_tool == "pico" else "REQUIERE PICO"
		return "RECOGER"
	return "INTERACTUAR"

static func interact(host: Node) -> void:
	if not can_interact(host):
		return
	var chest := nearest_chest(host, 46.0)
	if chest >= 0:
		host._open_chest(chest)
		return
	var target := nearest_resource(host, 48.0)
	if target.is_empty():
		host._spawn_floater(host.INTERACT_CENTER + Vector2(-50, -34), "Nada cerca", Color(0.82, 0.84, 0.78, 0.72))
		return
	host._start_harvest(target)
