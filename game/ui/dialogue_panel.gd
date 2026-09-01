class_name DialoguePanel
extends PanelContainer

signal closed

var service := Stage1DialogueService.new()
var active_dialogue: Dictionary = {}
var current_node_id: String = ""
var speaker_label: Label
var text_label: Label
var choices_box: VBoxContainer
var continue_button: Button

func _state_node() -> Node:
	return get_node_or_null("/root/GameState")

func _ready() -> void:
	custom_minimum_size = Vector2(420, 100)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	margin.add_child(column)
	speaker_label = Label.new()
	speaker_label.add_theme_color_override("font_color", Color("#f0bf5a"))
	speaker_label.add_theme_font_size_override("font_size", 15)
	column.add_child(speaker_label)
	text_label = Label.new()
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.add_theme_color_override("font_color", Color("#fff4da"))
	text_label.add_theme_font_size_override("font_size", 13)
	text_label.custom_minimum_size = Vector2(0, 38)
	column.add_child(text_label)
	choices_box = VBoxContainer.new()
	choices_box.add_theme_constant_override("separation", 3)
	column.add_child(choices_box)
	continue_button = Button.new()
	continue_button.text = "Continuar"
	continue_button.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	continue_button.pressed.connect(_on_continue)
	column.add_child(continue_button)
	visible = false

func open_actor(actor_id: String) -> void:
	active_dialogue = service.open_for_actor(actor_id)
	if active_dialogue.is_empty():
		return
	var node: Dictionary = {}
	var state := _state_node()
	var quest_status := String(state.call("quest_status", "MQ00_01"))
	if actor_id == "NPC_IRIA" and quest_status == "COMPLETE":
		node = service.node_for(active_dialogue, "complete")
	if actor_id == "NPC_IRIA" and bool(state.call("has_flag", "MQ00_01_ITEM_RECEIVED")) and quest_status == "ACTIVE":
		node = service.node_for(active_dialogue, "return")
	if node.is_empty():
		node = service.first_available(active_dialogue)
	if node.is_empty() and actor_id == "NPC_HALVEN":
		node = service.node_for(active_dialogue, "quiet")
	if node.is_empty():
		return
	current_node_id = _find_node_id(node)
	visible = true
	_render(node)

func _find_node_id(target: Dictionary) -> String:
	for key in active_dialogue.get("nodes", {}).keys():
		if active_dialogue["nodes"][key] == target:
			return String(key)
	return String(active_dialogue.get("start", ""))

func _render(node: Dictionary) -> void:
	speaker_label.text = String(node.get("speaker", ""))
	text_label.text = String(node.get("text", ""))
	for child in choices_box.get_children():
		child.queue_free()
	var choices: Array = node.get("choices", [])
	continue_button.visible = choices.is_empty()
	for choice in choices:
		var button := Button.new()
		button.text = String(choice.get("text", "Continuar"))
		button.custom_minimum_size = Vector2(0, 28)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_on_choice.bind(choice))
		choices_box.add_child(button)

func _on_choice(choice: Dictionary) -> void:
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
	_close()

func _close() -> void:
	visible = false
	closed.emit()
