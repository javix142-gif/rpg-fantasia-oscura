class_name PlayerController
extends CharacterBody2D

signal direction_changed(direction: String)

const SPEED: float = 124.0
const DIRECTIONS: Array[String] = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]

var movement_input: Vector2 = Vector2.ZERO
var virtual_input: Vector2 = Vector2.ZERO
var direction8: String = "S"
var _sprite: Sprite2D
var _step_clock: float = 0.0

func _ready() -> void:
	z_index = 20
	var shadow := Polygon2D.new()
	shadow.polygon = PackedVector2Array([Vector2(-17, -3), Vector2(-12, -8), Vector2(12, -8), Vector2(17, -3), Vector2(12, 2), Vector2(-12, 2)])
	shadow.color = Color(0.08, 0.06, 0.08, 0.35)
	shadow.position = Vector2(0, 1)
	add_child(shadow)
	_sprite = Sprite2D.new()
	_sprite.texture = load("res://assets/p1/player_master.png") as Texture2D
	_sprite.centered = true
	_sprite.position = Vector2(0, -30)
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_sprite)
	var collider := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 11.0
	capsule.height = 18.0
	collider.shape = capsule
	collider.position = Vector2(0, -8)
	add_child(collider)
	queue_redraw()

func set_virtual_input(value: Vector2) -> void:
	virtual_input = value

func _physics_process(delta: float) -> void:
	var keyboard := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	movement_input = virtual_input if virtual_input.length_squared() > 0.01 else keyboard
	if movement_input.length_squared() > 1.0:
		movement_input = movement_input.normalized()
	velocity = movement_input * SPEED
	move_and_slide()
	global_position.x = clampf(global_position.x, 52.0, 908.0)
	global_position.y = clampf(global_position.y, 74.0, 586.0)
	if movement_input.length_squared() > 0.01:
		var next_direction := _direction_from_vector(movement_input)
		if next_direction != direction8:
			direction8 = next_direction
			direction_changed.emit(direction8)
		_step_clock += delta
		_sprite.position.y = -30.0 + sin(_step_clock * 10.0) * 1.3
		_sprite.flip_h = direction8 in ["W", "NW", "SW"]
	else:
		_step_clock += delta * 0.35
		_sprite.position.y = -30.0 + sin(_step_clock * 3.0) * 0.5
	queue_redraw()

func _direction_from_vector(value: Vector2) -> String:
	var angle := value.angle()
	var index := int(round((angle + PI / 2.0) / (PI / 4.0))) % 8
	if index < 0:
		index += 8
	return DIRECTIONS[index]

func snapshot_position() -> Vector2:
	return global_position

func direction_for_input(value: Vector2) -> String:
	return _direction_from_vector(value.normalized())
