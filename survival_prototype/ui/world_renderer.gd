class_name CSWorldRenderer
extends RefCounted

static func draw_entities(host: Node2D) -> void:
	var entries: Array = []
	for b_variant in host.buildings:
		var b: Dictionary = b_variant
		var bp: Vector2 = b["pos"]
		if bp.distance_to(host.player_pos) <= 455.0:
			entries.append({"y": bp.y, "kind": "building", "data": b})
	for key_variant in host.loaded_chunks.keys():
		var chunk: Dictionary = host.loaded_chunks[key_variant]
		for r_variant in chunk["resources"]:
			var r: Dictionary = r_variant
			var rp: Vector2 = r["pos"]
			if rp.distance_to(host.player_pos) <= 455.0:
				entries.append({"y": rp.y, "kind": "resource", "data": r})
		for e_variant in chunk["enemies"]:
			var e: Dictionary = e_variant
			if not bool(e.get("alive", true)):
				continue
			var ep: Vector2 = e["pos"]
			if ep.distance_to(host.player_pos) <= 455.0:
				entries.append({"y": ep.y, "kind": "enemy", "data": e})
	entries.append({"y": host.player_pos.y, "kind": "player", "data": {}})
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["y"]) < float(b["y"]))
	for entry_variant in entries:
		var entry: Dictionary = entry_variant
		match String(entry["kind"]):
			"building":
				var b: Dictionary = entry["data"]
				host._draw_building_sprite(String(b["type"]), host._world_to_screen(b["pos"]), int(b.get("rot", 0)), false, true)
			"resource":
				var r: Dictionary = entry["data"]
				var rp: Vector2 = r["pos"]
				var sp: Vector2 = host._world_to_screen(rp)
				var shake: float = sin(host.anim_clock * 42.0 + float(r["id"])) * 2.0 * clampf(float(r.get("shake", 0.0)) / 0.28, 0.0, 1.0)
				sp.x += shake
				host._draw_resource_sprite(String(r["type"]), sp)
				if float(r["hp"]) < float(r["max_hp"]):
					host._draw_small_bar(sp + Vector2(-13, -28), 26.0, float(r["hp"]) / float(r["max_hp"]), Color("d99d54"))
			"enemy":
				var e: Dictionary = entry["data"]
				var ep: Vector2 = e["pos"]
				var sp: Vector2 = host._world_to_screen(ep)
				host._draw_enemy_telegraph(e, sp)
				host._draw_enemy_sprite(e, sp)
				host._draw_small_bar(sp + Vector2(-16, -28), 32.0, float(e["hp"]) / float(e["max_hp"]), Color("d85c62"))
			"player":
				host._draw_player(host.CENTER)
