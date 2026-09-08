class_name RebuildPlayer
extends CharacterBody2D

signal attack_window(position: Vector2, facing: Vector2)
signal hp_changed(current: int, maximum: int)
signal died
signal dodge_started(position: Vector2)

const SPEED := 132.0
const DODGE_SPEED := 310.0
const MAX_HP := 100
const SHEET := preload("res://assets/p1_1/player_sheet.png")
const DIR_NAMES := ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
const DIR_VECS := [Vector2(0.0,-1.0), Vector2(0.70710678,-0.70710678), Vector2(1.0,0.0), Vector2(0.70710678,0.70710678), Vector2(0.0,1.0), Vector2(-0.70710678,0.70710678), Vector2(-1.0,0.0), Vector2(-0.70710678,-0.70710678)]

var hp: int = MAX_HP
var virtual_input := Vector2.ZERO
var facing := Vector2.DOWN
var input_locked := false
var invulnerable: float = 0.0
var attack_cooldown: float = 0.0
var dodge_cooldown: float = 0.0
var state: String = "idle"
var _action_timer: float = 0.0
var _attack_fired := false
var _sprite: AnimatedSprite2D
var _shadow: Polygon2D
var _trail_alpha := 0.0

func _ready() -> void:
	z_index = 20
	collision_layer = 2
	collision_mask = 1
	_build_visual()
	_build_collision()
	set_physics_process(true)

func _build_visual() -> void:
	_shadow = Polygon2D.new()
	_shadow.polygon = PackedVector2Array([Vector2(-14, 0), Vector2(-9, -5), Vector2(9, -5), Vector2(14, 0), Vector2(9, 4), Vector2(-9, 4)])
	_shadow.color = Color(0.04, 0.04, 0.05, 0.38)
	_shadow.position = Vector2(0, 2)
	_shadow.z_index = -1
	add_child(_shadow)
	_sprite = AnimatedSprite2D.new()
	_sprite.name = "AnimatedSprite"
	_sprite.position = Vector2(0, -27)
	_sprite.scale = Vector2.ONE * 0.9
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for row in range(8):
		var d: String = DIR_NAMES[row]
		_add_anim(frames, "idle_" + d, row, [0,1], 3.0, true)
		_add_anim(frames, "walk_" + d, row, [2,3,4,5], 8.0, true)
		_add_anim(frames, "attack_" + d, row, [1,2,4,5], 14.0, false)
		_add_anim(frames, "dodge_" + d, row, [5,4,3,2], 16.0, false)
		_add_anim(frames, "hit_" + d, row, [0,1], 12.0, false)
		_add_anim(frames, "death_" + d, row, [1,0], 5.0, false)
	_sprite.sprite_frames = frames
	add_child(_sprite)
	_play_state_animation()

func _add_anim(frames: SpriteFrames, name: String, row: int, columns: Array, fps: float, looped: bool) -> void:
	frames.add_animation(name)
	frames.set_animation_speed(name, fps)
	frames.set_animation_loop(name, looped)
	for col in columns:
		var atlas := AtlasTexture.new()
		atlas.atlas = SHEET
		atlas.region = Rect2(int(col) * 64, row * 64, 64, 64)
		frames.add_frame(name, atlas)

func _build_collision() -> void:
	var node := CollisionShape2D.new()
	var shape := CapsuleShape2D.new()
	shape.radius = 10.0
	shape.height = 19.0
	node.shape = shape
	node.position = Vector2(0, -8)
	add_child(node)

func set_virtual_input(value: Vector2) -> void:
	virtual_input = value.limit_length(1.0)

func _physics_process(delta: float) -> void:
	invulnerable = maxf(0.0, invulnerable - delta)
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	dodge_cooldown = maxf(0.0, dodge_cooldown - delta)
	_trail_alpha = maxf(0.0, _trail_alpha - delta * 3.5)
	if state == "dead":
		velocity = Vector2.ZERO
		queue_redraw()
		return
	if _action_timer > 0.0:
		_action_timer -= delta
		_process_action_state()
		move_and_slide()
		queue_redraw()
		return
	if input_locked:
		velocity = Vector2.ZERO
		_set_state("idle")
		queue_redraw()
		return
	if Input.is_action_just_pressed("attack"):
		request_attack()
	if Input.is_action_just_pressed("dodge"):
		request_dodge()
	var keyboard := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var move_input := virtual_input if virtual_input.length_squared() > 0.01 else keyboard
	move_input = move_input.limit_length(1.0)
	if move_input.length_squared() > 0.01:
		facing = move_input.normalized()
		velocity = move_input * SPEED
		_set_state("walk")
	else:
		velocity = Vector2.ZERO
		_set_state("idle")
	move_and_slide()
	global_position.x = clampf(global_position.x, 24.0, 936.0)
	global_position.y = clampf(global_position.y, 24.0, 616.0)
	queue_redraw()

func request_attack() -> bool:
	if input_locked or state == "dead" or attack_cooldown > 0.0 or _action_timer > 0.0:
		return false
	attack_cooldown = 0.34
	_action_timer = 0.30
	_attack_fired = false
	velocity = Vector2.ZERO
	_set_state("attack", true)
	return true

func request_dodge() -> bool:
	if input_locked or state == "dead" or dodge_cooldown > 0.0 or _action_timer > 0.0:
		return false
	dodge_cooldown = 0.72
	invulnerable = 0.38
	_action_timer = 0.24
	_trail_alpha = 0.8
	var d := facing.normalized() if facing.length_squared() > 0.01 else Vector2.DOWN
	velocity = d * DODGE_SPEED
	_set_state("dodge", true)
	dodge_started.emit(global_position)
	return true

func _process_action_state() -> void:
	if state == "attack":
		velocity = Vector2.ZERO
		if not _attack_fired and _action_timer <= 0.19:
			_attack_fired = true
			attack_window.emit(global_position + facing.normalized() * 30.0, facing.normalized())
	elif state == "dodge":
		velocity *= 0.90
	elif state == "hit":
		velocity *= 0.82
	if _action_timer <= 0.0 and state != "dead":
		_set_state("idle", true)

func take_damage(amount: int, source_position: Vector2 = Vector2.ZERO) -> bool:
	if state == "dead" or invulnerable > 0.0:
		return false
	hp = maxi(0, hp - amount)
	hp_changed.emit(hp, MAX_HP)
	if hp <= 0:
		state = "dead"
		_action_timer = 1.0
		velocity = Vector2.ZERO
		_play_state_animation()
		var tween := create_tween()
		tween.tween_property(_sprite, "rotation", PI * 0.5, 0.35)
		tween.parallel().tween_property(_sprite, "modulate:a", 0.2, 0.35)
		tween.tween_callback(func(): died.emit())
		return true
	invulnerable = 0.42
	_action_timer = 0.18
	_set_state("hit", true)
	if source_position != Vector2.ZERO:
		var knock := (global_position - source_position).normalized()
		velocity = knock * 95.0
	var flash := create_tween()
	flash.tween_property(_sprite, "modulate", Color(1.0, 0.35, 0.28, 1.0), 0.05)
	flash.tween_property(_sprite, "modulate", Color.WHITE, 0.10)
	if OS.has_feature("android"):
		Input.vibrate_handheld(28)
	return true

func heal(amount: int) -> int:
	if hp <= 0:
		return 0
	var before := hp
	hp = mini(MAX_HP, hp + amount)
	hp_changed.emit(hp, MAX_HP)
	return hp - before

func respawn(position: Vector2) -> void:
	hp = MAX_HP
	global_position = position
	velocity = Vector2.ZERO
	state = "idle"
	_action_timer = 0.0
	invulnerable = 1.0
	_sprite.rotation = 0.0
	_sprite.modulate = Color.WHITE
	hp_changed.emit(hp, MAX_HP)
	_play_state_animation()

func _set_state(next: String, force: bool = false) -> void:
	if not force and state == next:
		return
	state = next
	_play_state_animation()

func _play_state_animation() -> void:
	if _sprite == null:
		return
	var d := _direction_name(facing)
	var anim := state + "_" + d
	if not _sprite.sprite_frames.has_animation(anim):
		anim = "idle_" + d
	_sprite.play(anim)

func _direction_name(v: Vector2) -> String:
	if v.length_squared() < 0.01:
		return "S"
	var n := v.normalized()
	var best := 0
	var best_dot := -2.0
	for i in range(DIR_VECS.size()):
		var d := n.dot(DIR_VECS[i])
		if d > best_dot:
			best_dot = d
			best = i
	return DIR_NAMES[best]

func _draw() -> void:
	if _trail_alpha > 0.0:
		draw_circle(-facing.normalized() * 22.0 + Vector2(0, -8), 16, Color(0.65, 0.72, 0.74, 0.14 * _trail_alpha))
	if state == "attack":
		var angle := facing.angle()
		var progress := clampf((0.30 - _action_timer) / 0.30, 0.0, 1.0)
		var start := angle - 1.2 + progress * 0.35
		var finish := angle + 0.4 + progress * 0.85
		draw_arc(Vector2(0, -11), 34, start, finish, 12, Color("#f1cf77"), 4)
		draw_line(Vector2(0, -11), Vector2(0, -11) + Vector2.from_angle(angle) * 39, Color("#d8d7cc"), 3)
