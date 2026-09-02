class_name P12CollisionDebugView
extends Node2D

## Test-only overlay. Production scenes keep CollisionLayer invisible; this
## view makes the maintained visual/physical catalog inspectable in captures.

var world: VillageWorld
var _colors := {
	"boundary": Color("#d46b6b"),
	"house": Color("#e0a254"),
	"smithy": Color("#d9b56c"),
	"market": Color("#d9b56c"),
	"fountain": Color("#5fc3d5"),
	"fence": Color("#c98b5b"),
	"tree": Color("#7fba62"),
	"prop": Color("#c89c65")
}

func setup(target: VillageWorld) -> void:
	world = target
	z_index = 90
	queue_redraw()

func _process(_delta: float) -> void:
	if world != null:
		queue_redraw()

func _draw() -> void:
	if world == null:
		return
	for spec in world.collision_catalog():
		var color: Color = _colors.get(String(spec.get("category", "prop")), Color("#ffffff"))
		color.a = 0.88
		var center: Vector2 = spec.get("center", Vector2.ZERO)
		if String(spec.get("type", "")) == "circle":
			draw_circle(center, float(spec.get("radius", 0.0)), Color(color, 0.18), false, 2.0)
			draw_arc(center, float(spec.get("radius", 0.0)), 0.0, TAU, 32, color, 2.0)
		else:
			var rect_size: Vector2 = spec.get("size", Vector2.ZERO)
			draw_rect(Rect2(center - rect_size * 0.5, rect_size), Color(color, 0.18), false, 2.0)
			draw_line(center - Vector2(3, 0), center + Vector2(3, 0), color, 1.0)
			draw_line(center - Vector2(0, 3), center + Vector2(0, 3), color, 1.0)
