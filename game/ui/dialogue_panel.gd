class_name DialoguePanel
extends PanelContainer

signal closed

const TYPEWRITER_CHARS_PER_SECOND := 120.0
const DIALOGUE_ANIMATION_TIME := 0.16

var service := Stage1DialogueService.new()
var active_dialogue: Dictionary = {}
var current_node_id: String = ""
var speaker_label: Label
var text_label: Label
var portrait: TextureRect
var choices_box: VBoxContainer
var continue_button: Button
var _typed_characters := 0.0
var _typing := false
var _closing := false

func _state_node() -> Node:
	return get_node_or_null("/root/GameState")

func _ready() -> void:
	custom_minimum_size = Vector2(0, 150)
	mouse_filter = Control.MOUSE_FILTER_STOP
	Stage1Theme.apply_panel(self, Color(0.045, 0.05, 0.075, 0.98), Stage1Theme.COLOR_BORDER_FOCUS, true)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_bottom", 5)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	margin.add_child(column)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	column.add_child(header)
	portrait = TextureRect.new()
	portrait.custom_minimum_size = Vector2(42, 42)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(portrait)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 1)
	header.add_child(copy)
	speaker_label = Stage1Theme.label("", Stage1Theme.FONT_HEADING, Stage1Theme.COLOR_TEXT_GOLD)
	speaker_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	speaker_label.custom_minimum_size = Vector2(0, 18)
	copy.add_child(speaker_label)
	text_label = Stage1Theme.label("", Stage1Theme.FONT_BODY, Stage1Theme.COLOR_TEXT)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.custom_minimum_size = Vector2(0, 45)
	text_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	text_label.max_lines_visible = 4
	text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(text_label)
	choices_box = VBoxContainer.new()
	choices_box.add_theme_constant_override("separation", 2)
	column.add_child(choices_box)
	continue_button = Stage1Theme.compact_button("Continuar", Vector2(112, 28), true)
	continue_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	continue_button.pressed.connect(_on_continue)
	column.add_child(continue_button)
	visible = false

func _process(delta: float) -> void:
	if not visible or not _typing:
		return
	_typed_characters += delta * TYPEWRITER_CHARS_PER_SECOND
	var total := text_label.text.length()
	text_label.visible_characters = mini(int(_typed_characters), total)
	if _typed_characters >= float(total):
		_typing = false
		text_label.visible_characters = -1

func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventScreenTouch or event is InputEventMouseButton):
		return
	var pressed: bool = bool(event.pressed)
	if not pressed:
		return
	if _typing:
		_finish_text()
	elif choices_box.get_child_count() == 0:
		_close()
	accept_event()

func open_actor(actor_id: String) -> bool:
	if _closing:
		return false
	active_dialogue = service.open_for_actor(actor_id)
	if active_dialogue.is_empty():
		return false
	var node: Dictionary = {}
	var state := _state_node()
	var quest_status := String(state.call("quest_status", "MQ00_01"))
	if actor_id == "NPC_IRIA":
		match quest_status:
			"COMPLETE":
				node = service.node_for(active_dialogue, "complete")
			"ACTIVE":
				if bool(state.call("has_flag", "MQ00_01_ITEM_RECEIVED")) and bool(state.call("has_item", "ITEM_LANTERN", 1)):
					node = service.node_for(active_dialogue, "return")
				else:
					node = service.node_for(active_dialogue, "started")
			_: node = service.node_for(active_dialogue, "start")
	if node.is_empty():
		node = service.first_available(active_dialogue)
	if node.is_empty() and actor_id == "NPC_HALVEN":
		node = service.node_for(active_dialogue, "quiet")
	if node.is_empty():
		return false
	current_node_id = _find_node_id(node)
	_set_portrait(actor_id)
	visible = true
	_closing = false
	modulate = Color(1.0, 1.0, 1.0, 0.0)
	scale = Vector2(0.985, 0.985)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, DIALOGUE_ANIMATION_TIME)
	tween.tween_property(self, "scale", Vector2.ONE, DIALOGUE_ANIMATION_TIME)
	_render(node)
	return true

func _set_portrait(actor_id: String) -> void:
	var indices := {"NPC_IRIA": 0, "NPC_HALVEN": 1, "NPC_SMITH": 2, "NPC_MERCHANT": 3, "NPC_FRIEND": 4}
	var index := int(indices.get(actor_id, 4))
	var sheet := load("res://assets/p1_1/npc_sheet.png") as Texture2D
	var frame := AtlasTexture.new()
	frame.atlas = sheet
	frame.region = Rect2(index * 64, 0, 64, 64)
	portrait.texture = frame

func _find_node_id(target: Dictionary) -> String:
	for key in active_dialogue.get("nodes", {}).keys():
		if active_dialogue["nodes"][key] == target:
			return String(key)
	return String(active_dialogue.get("start", ""))

func _render(node: Dictionary) -> void:
	speaker_label.text = String(node.get("speaker", ""))
	text_label.text = String(node.get("text", ""))
	_typed_characters = 0.0
	text_label.visible_characters = 0
	_typing = not text_label.text.is_empty()
	for child in choices_box.get_children():
		child.queue_free()
	var choices: Array = node.get("choices", [])
	continue_button.visible = choices.is_empty()
	for choice in choices:
		var button := Stage1Theme.compact_button(String(choice.get("text", "Continuar")), Vector2(0, 27))
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		button.pressed.connect(_on_choice.bind(choice))
		choices_box.add_child(button)

func _finish_text() -> void:
	_typing = false
	_typed_characters = float(text_label.text.length())
	text_label.visible_characters = -1

func _on_choice(choice: Dictionary) -> void:
	if _closing:
		return
	_finish_text()
	for effect in choice.get("effects", []):
		_state_node().call("apply_effect", effect)
	var next := String(choice.get("next", ""))
	if next.is_empty():
		_close()
		return
	var node := service.node_for(active_dialogue, next)
	if node.is_empty():
		_close()
		return
	current_node_id = next
	_render(node)

func _on_continue() -> void:
	if _typing:
		_finish_text()
		return
	_close()

func _close() -> void:
	if not visible or _closing:
		return
	_closing = true
	_typing = false
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, DIALOGUE_ANIMATION_TIME)
	tween.tween_property(self, "scale", Vector2(0.985, 0.985), DIALOGUE_ANIMATION_TIME)
	tween.set_parallel(false)
	tween.tween_callback(_finish_close)

func _finish_close() -> void:
	visible = false
	modulate = Color.WHITE
	scale = Vector2.ONE
	_closing = false
	closed.emit()
