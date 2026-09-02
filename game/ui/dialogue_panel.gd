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
	custom_minimum_size = Vector2(0, 136)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.045, 0.05, 0.075, 0.97)
	panel_style.border_color = Color("#c29b5b")
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(9)
	panel_style.content_margin_left = 10
	panel_style.content_margin_right = 10
	panel_style.content_margin_top = 8
	panel_style.content_margin_bottom = 8
	add_theme_stylebox_override("panel", panel_style)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_bottom", 5)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	margin.add_child(column)
	speaker_label = Label.new()
	speaker_label.add_theme_color_override("font_color", Color("#f0bf5a"))
	speaker_label.add_theme_font_size_override("font_size", 14)
	speaker_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	speaker_label.custom_minimum_size = Vector2(0, 18)
	column.add_child(speaker_label)
	text_label = Label.new()
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.add_theme_color_override("font_color", Color("#fff4da"))
	text_label.add_theme_font_size_override("font_size", 12)
	text_label.custom_minimum_size = Vector2(0, 42)
	text_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	text_label.max_lines_visible = 3
	column.add_child(text_label)
	choices_box = VBoxContainer.new()
	choices_box.add_theme_constant_override("separation", 3)
	column.add_child(choices_box)
	continue_button = Button.new()
	continue_button.text = "Continuar"
	continue_button.custom_minimum_size = Vector2(112, 30)
	continue_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	continue_button.focus_mode = Control.FOCUS_NONE
	continue_button.pressed.connect(_on_continue)
	column.add_child(continue_button)
	visible = false

func open_actor(actor_id: String) -> bool:
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
	visible = true
	_render(node)
	return true

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
		button.custom_minimum_size = Vector2(0, 30)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.focus_mode = Control.FOCUS_NONE
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
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
	if not visible:
		return
	visible = false
	closed.emit()
