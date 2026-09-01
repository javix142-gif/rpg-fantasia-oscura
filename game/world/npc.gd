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
var _sprite: Sprite2D

func setup(new_id: String, new_name: String, new_role: String, spawn_position: Vector2, color: Color, accent: Color, new_accessory: String = "") -> void:
	actor_id = new_id
	display_name = new_name
	role = new_role
	body_color = color
	accent_color = accent
	accessory = new_accessory
	global_position = spawn_position

func _ready() -> void:
	z_index = 0
	_build_shadow()
	_build_sprite()
	_build_interaction_target()

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

func prompt_text() -> String:
	return "Hablar con " + display_name

func interaction_data() -> Dictionary:
	return {"id": actor_id, "prompt": prompt_text(), "action": "dialogue"}
