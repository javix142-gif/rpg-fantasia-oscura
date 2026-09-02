class_name LiriaAmbientFx
extends Node2D

## One low-cost draw node provides a few readable motion cues without a
## particle system or shader. All positions are authored in Liria's 960x640
## world space and remain deterministic for screenshots and tests.

var _clock := 0.0

func _ready() -> void:
	name = "AmbientFX"
	z_index = 8
	set_process(true)

func _process(delta: float) -> void:
	_clock += delta
	queue_redraw()

func _draw() -> void:
	_draw_fountain()
	_draw_forge()
	_draw_smoke(Vector2(161, 61), 0.0)
	_draw_smoke(Vector2(456, 50), 1.7)
	_draw_market_cloth()
	_draw_fireflies()

func _draw_fountain() -> void:
	var water := Color(0.36, 0.82, 0.88, 0.62)
	var phase := fmod(_clock * 1.8, 1.0)
	var radius := 19.0 + phase * 11.0
	var alpha := 0.48 - phase * 0.35
	draw_arc(Vector2(480, 350), radius, 0.0, TAU, 24, Color(water, alpha), 1.2)
	draw_arc(Vector2(480, 350), radius + 9.0, 0.2, 2.8, 18, Color(water, alpha * 0.65), 1.0)
	var sparkle := Vector2(466.0 + sin(_clock * 2.2) * 9.0, 334.0 + cos(_clock * 2.6) * 3.0)
	draw_circle(sparkle, 1.5, Color(0.82, 0.96, 0.90, 0.78))

func _draw_forge() -> void:
	var flame_origin := Vector2(501, 170)
	var sway := sin(_clock * 5.0) * 3.0
	var outer := PackedVector2Array([
		flame_origin + Vector2(-8, 8),
		flame_origin + Vector2(-4 + sway, -9),
		flame_origin + Vector2(1, 0),
		flame_origin + Vector2(6 - sway, -13),
		flame_origin + Vector2(9, 9)
	])
	draw_colored_polygon(outer, Color(0.91, 0.42, 0.16, 0.84))
	draw_circle(flame_origin + Vector2(0, 2), 5.0, Color(1.0, 0.77, 0.26, 0.88))

func _draw_smoke(origin: Vector2, offset: float) -> void:
	for index in range(3):
		var t := _clock * 0.34 + offset + float(index) * 0.8
		var point := origin + Vector2(sin(t) * 4.0, -fmod(t, 2.4) * 8.0 - float(index) * 6.0)
		var alpha := 0.16 - float(index) * 0.035
		draw_circle(point, 4.5 + float(index), Color(0.86, 0.88, 0.78, alpha))

func _draw_market_cloth() -> void:
	var sway := sin(_clock * 2.0) * 3.0
	draw_line(Vector2(760, 101), Vector2(786 + sway, 108), Color(0.21, 0.30, 0.34, 0.64), 2.0)
	draw_line(Vector2(785 + sway, 108), Vector2(801 + sway, 103), Color(0.88, 0.70, 0.40, 0.72), 1.0)

func _draw_fireflies() -> void:
	for index in range(4):
		var t := _clock * (0.8 + float(index) * 0.07) + float(index) * 1.6
		var point := Vector2(344 + index * 104, 392 + sin(t) * 9.0 + (index % 2) * 25)
		var alpha := 0.26 + (sin(t * 2.0) + 1.0) * 0.15
		draw_circle(point, 1.4, Color(0.95, 0.82, 0.43, alpha))
