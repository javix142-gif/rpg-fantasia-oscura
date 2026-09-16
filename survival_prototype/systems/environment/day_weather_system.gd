class_name CSDayWeatherSystem
extends RefCounted

static func update_time(host: Node, delta: float) -> void:
	var old_clock := host.day_clock
	host.day_clock += delta / 230.0
	if host.day_clock >= 1.0:
		host.day_clock -= 1.0
		host.day_number += 1
		host._mark_dirty("day")
		host._set_major("Día %d" % host.day_number, 1.6)
	if old_clock < 0.74 and host.day_clock >= 0.74:
		host._set_major("Cae la noche", 1.6)

static func update_survival(host: Node, delta: float) -> void:
	var old_hunger := host.hunger
	var old_hp := host.hp
	host.hunger = maxf(0.0, host.hunger - delta * 0.18)
	if host.hunger <= 0.0:
		host.hp -= delta * 1.6
	var nearby: Array = host.buildings
	if host.spatial_index != null:
		nearby = host.spatial_index.nearby_buildings(host.buildings, host.player_pos, 84.0)
	for b_variant in nearby:
		var b: Dictionary = b_variant
		if String(b.get("type", "")) == "fogata":
			var bp: Vector2 = b["pos"]
			if bp.distance_to(host.player_pos) < 76.0 and (host.day_clock > 0.72 or host.day_clock < 0.18):
				host.hp = minf(100.0, host.hp + delta * 0.5)
	if absf(host.hunger - old_hunger) >= 0.5 or absf(host.hp - old_hp) >= 0.5:
		host._mark_dirty("survival")
	if host.hp <= 0.0:
		host._respawn()

static func change_weather(host: Node) -> void:
	host.weather_timer = 55.0 + host.rng.randf_range(-10.0, 18.0)
	host.weather = host.WEATHER[host.rng.randi_range(0, host.WEATHER.size() - 1)]
	host._mark_dirty("weather")
	host._set_major("Cambia el tiempo: %s" % host.weather, 1.7)
	host._play_sound("weather")
