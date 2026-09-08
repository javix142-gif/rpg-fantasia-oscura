class_name RebuildEnemy
extends CharacterBody2D

signal died(enemy: RebuildEnemy, reward_coins: int)
signal attack_landed(position: Vector2, damage: int, radius: float)
signal telegraph(position: Vector2, radius: float)

var target: RebuildPlayer
var max_hp: int = 55
var hp: int = 55
var damage: int = 12
var speed: float = 74.0
var reward_coins: int = 3
var is_boss := false
var phase := 1
var home := Vector2.ZERO
var state := "idle"
var _timer := 0.0
var _cooldown := 0.0
var _hit_flash := 0.0
var _bob := 0.0
var _dead := false

func setup(player: RebuildPlayer, boss: bool = false) -> void:
	target = player
	is_boss = boss
	if boss:
		max_hp = 220
		hp = max_hp
		damage = 18
		speed = 58.0
		reward_coins = 20
	else:
		hp = max_hp

func _ready() -> void:
	home = global_position
	z_index = 18
	collision_layer = 4
	collision_mask = 1
	var node := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 18.0 if is_boss else 12.0
	node.shape = shape
	node.position = Vector2(0, -7)
	add_child(node)
	set_physics_process(true)
	queue_redraw()

func _physics_process(delta: float) -> void:
	if _dead:
		return
	_bob += delta
	_cooldown = maxf(0.0, _cooldown - delta)
	_hit_flash = maxf(0.0, _hit_flash - delta)
	if is_boss and phase == 1 and hp <= max_hp / 2:
		phase = 2
		speed = 76.0
		damage = 22
	if _timer > 0.0:
		_timer -= delta
		_process_state()
		queue_redraw()
		return
	if target == null or target.state == "dead":
		velocity = Vector2.ZERO
		state = "idle"
		queue_redraw()
		return
	var distance := global_position.distance_to(target.global_position)
	var leash := 500.0 if is_boss else 310.0
	if global_position.distance_to(home) > leash:
		velocity = (home - global_position).normalized() * speed
		state = "return"
	elif distance <= (78.0 if is_boss else 42.0) and _cooldown <= 0.0:
		_start_attack()
	elif distance < (520.0 if is_boss else 240.0):
		velocity = (target.global_position - global_position).normalized() * speed
		state = "chase"
	else:
		velocity = Vector2.ZERO
		state = "idle"
	move_and_slide()
	queue_redraw()

func _start_attack() -> void:
	velocity = Vector2.ZERO
	state = "telegraph"
	_timer = 0.32 if is_boss else 0.20
	_cooldown = 1.05 if is_boss else 0.88
	telegraph.emit(global_position, 86.0 if is_boss else 40.0)

func _process_state() -> void:
	velocity = Vector2.ZERO
	if state == "telegraph" and _timer <= 0.0:
		state = "attack"
		_timer = 0.12
		attack_landed.emit(global_position, damage, 86.0 if is_boss else 42.0)
	elif state == "attack" and _timer <= 0.0:
		state = "idle"
		_timer = 0.0

func take_damage(amount: int, source: Vector2) -> bool:
	if _dead:
		return false
	hp = maxi(0, hp - amount)
	_hit_flash = 0.14
	if hp <= 0:
		_die()
		return true
	var knock := (global_position - source).normalized()
	global_position += knock * (8.0 if is_boss else 14.0)
	queue_redraw()
	return true

func _die() -> void:
	_dead = true
	state = "dead"
	collision_layer = 0
	collision_mask = 0
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.18, 0.72), 0.10)
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.tween_callback(func():
		died.emit(self, reward_coins)
		queue_free()
	)

func hp_ratio() -> float:
	return float(hp) / float(max_hp)

func _draw() -> void:
	var yoff := sin(_bob * (5.0 if state == "chase" else 2.6)) * 2.0
	var flash := Color("#fff0d2") if _hit_flash > 0.0 else Color.WHITE
	if is_boss:
		_draw_boss(yoff, flash)
	else:
		_draw_grunt(yoff, flash)
	if state == "telegraph":
		var r := 86.0 if is_boss else 40.0
		var pulse := 0.45 + 0.35 * sin(_timer * 40.0)
		draw_circle(Vector2(0, -7), r, Color(0.72, 0.22, 0.19, 0.10 * pulse))
		draw_arc(Vector2(0, -7), r, 0, TAU, 40, Color(0.95, 0.38, 0.24, pulse), 3)
	if is_boss:
		draw_rect(Rect2(-40, -67, 80, 7), Color(0.08, 0.08, 0.10, 0.88), true)
		draw_rect(Rect2(-38, -65, 76 * hp_ratio(), 3), Color("#b64c45") if phase == 1 else Color("#78a4aa"), true)

func _draw_grunt(yoff: float, flash: Color) -> void:
	var body := Color("#6f3f45") * flash
	var accent := Color("#b87155") * flash
	draw_rect(Rect2(-11, -31 + yoff, 22, 26), body, true)
	draw_rect(Rect2(-8, -42 + yoff, 16, 13), Color("#8c6260") * flash, true)
	draw_rect(Rect2(-14, -20 + yoff, 7, 20), Color("#463238") * flash, true)
	draw_rect(Rect2(7, -20 + yoff, 7, 20), Color("#463238") * flash, true)
	draw_rect(Rect2(-12, -4 + yoff, 8, 6), accent, true)
	draw_rect(Rect2(4, -4 + yoff, 8, 6), accent, true)
	if state == "attack":
		draw_line(Vector2(11, -27 + yoff), Vector2(29, -13 + yoff), Color("#d4c7a5"), 4)

func _draw_boss(yoff: float, flash: Color) -> void:
	var body := (Color("#3b4351") if phase == 1 else Color("#334c53")) * flash
	var metal := Color("#181d25") * flash
	var rune := Color("#7fb1b2") if phase == 2 else Color("#a47b63")
	draw_rect(Rect2(-24, -55 + yoff, 48, 48), body, true)
	draw_rect(Rect2(-19, -70 + yoff, 38, 18), Color("#555b67") * flash, true)
	draw_rect(Rect2(-31, -46 + yoff, 12, 36), metal, true)
	draw_rect(Rect2(19, -46 + yoff, 12, 36), metal, true)
	draw_rect(Rect2(-21, -8 + yoff, 14, 11), metal, true)
	draw_rect(Rect2(7, -8 + yoff, 14, 11), metal, true)
	for i in range(5):
		var a := -PI * 0.5 + TAU * float(i) / 5.0
		draw_circle(Vector2(cos(a), sin(a)) * 13 + Vector2(0, -31 + yoff), 2.4, rune)
	if state == "attack":
		draw_arc(Vector2(0, -26 + yoff), 48, -0.8, 0.8, 16, rune, 6)
