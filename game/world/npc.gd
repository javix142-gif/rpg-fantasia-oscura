class_name VillageNpc
extends Node2D

signal interacted(actor_id: String)

const ROLE_SPRITES: Dictionary = {
	"iria": 0,
	"halven": 1,
	"smith": 2,
	"merchant": 3,
	"friend": 4,
	"villager": 4
}

var actor_id: String = ""
var display_name: String = ""
var role: String = "villager"
var body_color: Color = Color("#537b69")
var accent_color: Color = Color("#e5b45a")
var accessory: String = ""
var interaction_target: InteractionTarget
var quest_marker: QuestMarker
var _sprite: Sprite2D
var _ambient_home_position := Vector2.ZERO
var _ambient_clock := 0.0
var _ambient_timer := 1.2
var _ambient_cycle := 0
var _ambient_state := "IDLE"
var _ambient_phase := 0.0
var _ambient_tween: Tween

func setup(new_id: String, new_name: String, new_role: String, spawn_position: Vector2, color: Color, accent: Color, new_accessory: String = "") -> void:
	actor_id = new_id
	display_name = new_name
	role = new_role
	body_color = color
	accent_color = accent
	accessory = new_accessory
	global_position = spawn_position
	_ambient_home_position = spawn_position
	for character in actor_id:
		_ambient_phase += float(character.unicode_at(0))
	_ambient_phase = fmod(_ambient_phase, 6.0)

func _ready() -> void:
	z_index = 0
	_build_shadow()
	_build_sprite()
	_build_interaction_target()
	_build_quest_marker()
	set_process(true)

func _build_shadow() -> void:
	var shadow := Polygon2D.new()
	shadow.name = "FootShadow"
	shadow.polygon = PackedVector2Array([Vector2(-16, -3), Vector2(-11, -7), Vector2(11, -7), Vector2(16, -3), Vector2(11, 2), Vector2(-11, 2)])
	shadow.color = Color(0.08, 0.06, 0.08, 0.30)
	shadow.position = Vector2(0, 1)
	shadow.z_index = -1
	add_child(shadow)

func _build_sprite() -> void:
	_sprite = Sprite2D.new()
	_sprite.name = "NpcSprite"
	_sprite.position = Vector2(0, -30)
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var sheet := load("res://assets/p1_1/npc_sheet.png") as Texture2D
	var frame := AtlasTexture.new()
	frame.atlas = sheet
	frame.region = Rect2(_sprite_index() * 64, 0, 64, 64)
	_sprite.texture = frame
	add_child(_sprite)

func _build_quest_marker() -> void:
	quest_marker = QuestMarker.new()
	quest_marker.name = "QuestMarker"
	quest_marker.position = Vector2(0, -68)
	add_child(quest_marker)

func _sprite_index() -> int:
	if ROLE_SPRITES.has(role):
		if role != "villager":
			return int(ROLE_SPRITES[role])
	# Ambient villagers reuse the family with a stable role variant.
	var total := 0
	for character in actor_id:
		total += character.unicode_at(0)
	return 4 if total % 2 == 0 else 0

func _build_interaction_target() -> void:
	interaction_target = InteractionTarget.new()
	interaction_target.name = "InteractionArea"
	interaction_target.target_id = actor_id
	interaction_target.prompt = prompt_text()
	interaction_target.action = "dialogue"
	interaction_target.collision_layer = 2
	interaction_target.collision_mask = 0
	interaction_target.monitorable = true
	var range_shape := CollisionShape2D.new()
	var range_circle := CircleShape2D.new()
	range_circle.radius = 34.0
	range_shape.shape = range_circle
	interaction_target.add_child(range_shape)
	interaction_target.activated.connect(_on_activated)
	add_child(interaction_target)

func _on_activated(target_id: String) -> void:
	interacted.emit(target_id)

func set_quest_marker(kind: String) -> void:
	if quest_marker != null:
		quest_marker.set_marker(kind)

func ambient_state() -> String:
	return _ambient_state

func _process(delta: float) -> void:
	_ambient_clock += delta
	if _sprite != null:
		var bob := sin(_ambient_clock * 2.1 + _ambient_phase) * 0.65
		_sprite.position = Vector2(0, -30.0 + bob)
	if role != "villager":
		return
	_ambient_timer -= delta
	if _ambient_timer <= 0.0 and (_ambient_tween == null or not _ambient_tween.is_valid()):
		_start_ambient_cycle()

func _start_ambient_cycle() -> void:
	_ambient_cycle = (_ambient_cycle + 1) % 3
	match _ambient_cycle:
		0:
			_ambient_state = "IDLE"
			_ambient_timer = 1.6 + fmod(_ambient_phase, 1.2)
		1:
			_ambient_state = "LOOK"
			_ambient_timer = 1.0 + fmod(_ambient_phase, 0.9)
		2:
			_ambient_state = "SHORT_WALK"
			_ambient_timer = 2.8 + fmod(_ambient_phase, 1.1)
			var offset := Vector2(sin(_ambient_phase + _ambient_clock) * 16.0, cos(_ambient_phase + _ambient_clock) * 7.0)
			_ambient_tween = create_tween()
			_ambient_tween.tween_property(self, "position", _ambient_home_position + offset, 0.42)
			_ambient_tween.tween_interval(0.5)
			_ambient_tween.tween_property(self, "position", _ambient_home_position, 0.42)
			_ambient_tween.tween_callback(func() -> void: _ambient_tween = null)

func prompt_text() -> String:
	return "Hablar con " + display_name

func interaction_data() -> Dictionary:
	return {"id": actor_id, "prompt": prompt_text(), "action": "dialogue"}
