class_name PlayerController
extends CharacterBody2D

signal direction_changed(direction: String)
signal interaction_target_changed(target: InteractionTarget)
signal interaction_requested(target: InteractionTarget)

const SPEED: float = 124.0
const ACTOR_VISUAL_SCALE := 0.90
const DIRECTIONS: Array[String] = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
# The atlas is authored with one stable 64x64 row per direction.  Direction
# changes are driven by the same vector that drives movement; no runtime
# mirroring is performed, so the sword and feet cannot detach from the body.
const DIRECTION_ROWS: Dictionary = {"N": 0, "NE": 1, "E": 2, "SE": 3, "S": 4, "SW": 5, "W": 6, "NW": 7}
const DIRECTION_VECTORS: Dictionary = {
	"N": Vector2(0, -1),
	"NE": Vector2(1, -1),
	"E": Vector2(1, 0),
	"SE": Vector2(1, 1),
	"S": Vector2(0, 1),
	"SW": Vector2(-1, 1),
	"W": Vector2(-1, 0),
	"NW": Vector2(-1, -1)
}

var movement_input: Vector2 = Vector2.ZERO
var virtual_input: Vector2 = Vector2.ZERO
var direction8: String = "S"
var current_interaction_target: InteractionTarget
var _sprite: AnimatedSprite2D
var _interaction_sensor: Area2D
var _interaction_targets: Array[InteractionTarget] = []

func _ready() -> void:
	z_index = 20
	collision_layer = 1
	collision_mask = 1
	_build_shadow()
	_build_animated_sprite()
	_build_collision()
	_build_interaction_sensor()
	_update_animation(false)

func _build_shadow() -> void:
	var shadow := Polygon2D.new()
	shadow.name = "FootShadow"
	shadow.polygon = PackedVector2Array([Vector2(-17, -3), Vector2(-12, -8), Vector2(12, -8), Vector2(17, -3), Vector2(12, 2), Vector2(-12, 2)])
	shadow.color = Color(0.08, 0.06, 0.08, 0.35)
	shadow.position = Vector2(0, 1)
	shadow.z_index = -1
	add_child(shadow)

func _build_animated_sprite() -> void:
	_sprite = AnimatedSprite2D.new()
	_sprite.name = "PlayerAnimatedSprite"
	# Player and NPC sheets share the same 52x54 fit envelope. A restrained
	# display scale keeps the protagonist readable without making it feel
	# imported from a different perspective or pixel density.
	_sprite.position = Vector2(0, -28)
	_sprite.scale = Vector2.ONE * ACTOR_VISUAL_SCALE
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var sheet := load("res://assets/p1_1/player_sheet.png") as Texture2D
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	for direction in DIRECTIONS:
		var row := int(DIRECTION_ROWS[direction])
		var idle_name := "idle_" + direction
		var walk_name := "walk_" + direction
		frames.add_animation(idle_name)
		frames.set_animation_speed(idle_name, 3.0)
		frames.set_animation_loop(idle_name, true)
		frames.add_animation(walk_name)
		frames.set_animation_speed(walk_name, 8.0)
		frames.set_animation_loop(walk_name, true)
		for column in [0, 1]:
			frames.add_frame(idle_name, _atlas_frame(sheet, column, row))
		for column in [2, 3, 4, 5]:
			frames.add_frame(walk_name, _atlas_frame(sheet, column, row))
	_sprite.sprite_frames = frames
	_sprite.centered = true
	add_child(_sprite)

func _atlas_frame(sheet: Texture2D, column: int, row: int) -> AtlasTexture:
	var frame := AtlasTexture.new()
	frame.atlas = sheet
	frame.region = Rect2(column * 64, row * 64, 64, 64)
	return frame

func _build_collision() -> void:
	var collider := CollisionShape2D.new()
	collider.name = "BodyCollision"
	var capsule := CapsuleShape2D.new()
	capsule.radius = 11.0
	capsule.height = 18.0
	collider.shape = capsule
	collider.position = Vector2(0, -8)
	add_child(collider)

func _build_interaction_sensor() -> void:
	_interaction_sensor = Area2D.new()
	_interaction_sensor.name = "InteractionSensor"
	_interaction_sensor.collision_layer = 0
	_interaction_sensor.collision_mask = 2
	_interaction_sensor.monitoring = true
	var sensor_shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 54.0
	sensor_shape.shape = circle
	sensor_shape.position = Vector2(0, -8)
	_interaction_sensor.add_child(sensor_shape)
	_interaction_sensor.area_entered.connect(_on_interaction_area_entered)
	_interaction_sensor.area_exited.connect(_on_interaction_area_exited)
	add_child(_interaction_sensor)

func set_virtual_input(value: Vector2) -> void:
	virtual_input = value if value.length_squared() <= 1.0 else value.normalized()

func _physics_process(_delta: float) -> void:
	var keyboard: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	movement_input = virtual_input if virtual_input.length_squared() > 0.01 else keyboard
	if movement_input.length_squared() > 1.0:
		movement_input = movement_input.normalized()
	velocity = movement_input * SPEED
	move_and_slide()
	if movement_input.length_squared() > 0.01:
		var next_direction := _direction_from_vector(movement_input)
		if next_direction != direction8:
			direction8 = next_direction
			direction_changed.emit(direction8)
	_update_animation(movement_input.length_squared() > 0.01)
	_refresh_interaction_target()

func _update_animation(moving: bool) -> void:
	if _sprite == null:
		return
	var animation_name := ("walk_" if moving else "idle_") + direction8
	if _sprite.animation != animation_name:
		_sprite.play(animation_name)
	elif not _sprite.is_playing():
		_sprite.play()
	# The processed sheet contains explicit rows for all directions; no runtime
	# flip is needed, so sword, cape and feet retain one stable pivot.
	_sprite.flip_h = false

func _direction_from_vector(value: Vector2) -> String:
	if value.length_squared() <= 0.0001:
		return direction8
	var normalized := value.normalized()
	var best_direction := direction8
	var best_dot := -INF
	for direction in DIRECTIONS:
		var axis: Vector2 = DIRECTION_VECTORS[direction]
		var dot := normalized.dot(axis.normalized())
		if dot > best_dot:
			best_dot = dot
			best_direction = direction
	return best_direction

func _on_interaction_area_entered(area: Area2D) -> void:
	var target := area as InteractionTarget
	if target == null or _interaction_targets.has(target):
		return
	_interaction_targets.append(target)
	_refresh_interaction_target()

func _on_interaction_area_exited(area: Area2D) -> void:
	var target := area as InteractionTarget
	if target == null:
		return
	_interaction_targets.erase(target)
	_refresh_interaction_target()

func _refresh_interaction_target() -> void:
	var selected: InteractionTarget
	var best_distance := INF
	for target in _interaction_targets:
		if not is_instance_valid(target):
			continue
		var distance := global_position.distance_to(target.global_position)
		if distance < best_distance:
			best_distance = distance
			selected = target
	if selected != current_interaction_target:
		current_interaction_target = selected
		interaction_target_changed.emit(current_interaction_target)

func request_interaction() -> bool:
	_refresh_interaction_target()
	if current_interaction_target == null:
		return false
	current_interaction_target.activate()
	interaction_requested.emit(current_interaction_target)
	return true

func get_interaction_prompt() -> String:
	return current_interaction_target.prompt if current_interaction_target != null else ""

func get_animation_frame_count(kind: String, direction: String) -> int:
	if _sprite == null or _sprite.sprite_frames == null:
		return 0
	return _sprite.sprite_frames.get_frame_count(kind + "_" + direction)

func snapshot_position() -> Vector2:
	return global_position

func direction_for_input(value: Vector2) -> String:
	return _direction_from_vector(value.normalized())
