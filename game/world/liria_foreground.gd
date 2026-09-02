class_name LiriaForeground
extends Node2D

## Selective depth accents. The authored background remains intact; these
## front rails/eaves are drawn only where the player can cross behind them.

func _ready() -> void:
	name = "ForegroundAccents"
	z_index = 30
	queue_redraw()

func _draw() -> void:
	var rail := Color(0.31, 0.20, 0.12, 0.92)
	var rail_light := Color(0.72, 0.49, 0.27, 0.84)
	# West garden front fence, following the authored perspective.
	_draw_rail(Vector2(47, 548), Vector2(184, 576), rail, rail_light)
	_draw_rail(Vector2(184, 576), Vector2(335, 548), rail, rail_light)
	# East garden front edge.
	_draw_rail(Vector2(448, 566), Vector2(646, 579), rail, rail_light)
	_draw_rail(Vector2(646, 579), Vector2(848, 551), rail, rail_light)
	# A narrow eave accent gives the main house doorway a readable front edge.
	draw_line(Vector2(147, 285), Vector2(236, 285), Color(0.25, 0.16, 0.12, 0.80), 3.0)

func _draw_rail(start: Vector2, finish: Vector2, dark: Color, light: Color) -> void:
	draw_line(start, finish, dark, 5.0)
	draw_line(start + Vector2(0, -4), finish + Vector2(0, -4), light, 2.0)
	var length := start.distance_to(finish)
	var count := maxi(2, int(length / 42.0))
	for index in range(count + 1):
		var point := start.lerp(finish, float(index) / float(count))
		draw_line(point + Vector2(0, -13), point + Vector2(0, 7), dark, 3.0)
