class_name Stage1Hud
extends CanvasLayer

const P1_CLASS_NAMES: Dictionary = {"CLASS_WARRIOR":"Guerrero", "CLASS_SWORDSMAN":"Espadachín", "CLASS_ARCHER":"Arquero", "CLASS_SORCERER":"Hechicero", "CLASS_CLERIC":"Clérigo"}

signal interact_pressed
signal inventory_pressed
signal save_pressed
signal load_pressed
signal menu_pressed

var root_control: Control
var status_panel: PanelContainer
var quest_panel: PanelContainer
var actions: HBoxContainer
var name_label: Label
var class_label: Label
var hp_bar: ProgressBar
var mp_bar: ProgressBar
var quest_title: Label
var quest_objective: Label
var quest_arrow_panel: PanelContainer
var quest_arrow_label: Label
var prompt_label: Label
var inventory_panel: PanelContainer
var inventory_text: Label
var toast_label: Label
var feedback_panel: PanelContainer
var feedback_title: Label
var feedback_detail: Label
var joystick: Stage1VirtualJoystick
var interact_button: Button
var menu_panel: PanelContainer
var player: PlayerController
var quest_world: VillageWorld
var quest_target: VillageNpc
var dialogue_mode := false
var _quest_signature := ""
var _pending_feedback_title := ""
var _pending_feedback_detail := ""
var _feedback_serial := 0
var _toast_serial := 0

func _state_node() -> Node:
	return get_node_or_null("/root/GameState")

func _ready() -> void:
	root_control = Control.new()
	root_control.name = "SafeContent"
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var safe_area := Stage1SafeAreaContainer.new()
	safe_area.name = "SafeArea"
	safe_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(safe_area)
	safe_area.add_child(root_control)
	_build_status()
	_build_quest()
	_build_actions()
	_build_inventory()
	_build_feedback()
	visible = true

func _panel(color: Color, border: Color = Stage1Theme.COLOR_BORDER) -> PanelContainer:
	var panel := PanelContainer.new()
	Stage1Theme.apply_panel(panel, color, border)
	return panel

func _label(text: String, size: int, color: Color) -> Label:
	return Stage1Theme.label(text, size, color)

func _button(text: String, minimum_size: Vector2, emphasized: bool = false) -> Button:
	return Stage1Theme.button(text, minimum_size, emphasized)

func _anchor(control: Control, left: float, top: float, right: float, bottom: float, offsets: Array[float]) -> void:
	control.anchor_left = left
	control.anchor_top = top
	control.anchor_right = right
	control.anchor_bottom = bottom
	control.offset_left = offsets[0]
	control.offset_top = offsets[1]
	control.offset_right = offsets[2]
	control.offset_bottom = offsets[3]

func _build_status() -> void:
	status_panel = _panel(Color(0.06, 0.08, 0.10, 0.92))
	_anchor(status_panel, 0.0, 0.0, 0.0, 0.0, [8.0, 8.0, 206.0, 80.0])
	root_control.add_child(status_panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 7)
	status_panel.add_child(row)
	var portrait := TextureRect.new()
	portrait.texture = load("res://assets/p1/player_portrait.png") as Texture2D
	portrait.custom_minimum_size = Vector2(48, 48)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	row.add_child(portrait)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 1)
	row.add_child(column)
	name_label = _label("Aventurero", Stage1Theme.FONT_HEADING, Stage1Theme.COLOR_TEXT_GOLD)
	column.add_child(name_label)
	class_label = _label("Nivel 1", Stage1Theme.FONT_SMALL, Stage1Theme.COLOR_TEXT_MUTED)
	column.add_child(class_label)
	hp_bar = _bar(Color("#bd4a4a"), 100, 92)
	column.add_child(hp_bar)
	mp_bar = _bar(Color("#4e83b9"), 40, 92)
	column.add_child(mp_bar)

func _bar(color: Color, max_value: float, width: float) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(width, 7)
	bar.max_value = max_value
	bar.value = max_value
	bar.show_percentage = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("#252638")
	bg.set_corner_radius_all(3)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	return bar

func _build_quest() -> void:
	quest_panel = _panel(Color(0.06, 0.08, 0.10, 0.92), Color("#9f7b4b"))
	_anchor(quest_panel, 0.5, 0.0, 0.5, 0.0, [-132.0, 8.0, 132.0, 66.0])
	root_control.add_child(quest_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 1)
	quest_panel.add_child(column)
	column.add_child(_label("OBJETIVO", Stage1Theme.FONT_SMALL, Stage1Theme.COLOR_TEXT_GREEN))
	quest_title = _label("Un día cualquiera", Stage1Theme.FONT_BODY + 1, Stage1Theme.COLOR_TEXT_GOLD)
	column.add_child(quest_title)
	quest_objective = _label("Habla con Iria en la plaza.", Stage1Theme.FONT_BODY, Stage1Theme.COLOR_TEXT)
	quest_objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quest_objective.max_lines_visible = 2
	column.add_child(quest_objective)
	quest_arrow_panel = _panel(Color(0.06, 0.08, 0.10, 0.88), Color("#6e8b78"))
	_anchor(quest_arrow_panel, 0.5, 0.0, 0.5, 0.0, [-58.0, 70.0, 58.0, 96.0])
	root_control.add_child(quest_arrow_panel)
	quest_arrow_label = _label("", Stage1Theme.FONT_BODY, Stage1Theme.COLOR_TEXT_GREEN)
	quest_arrow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quest_arrow_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	quest_arrow_panel.add_child(quest_arrow_label)
	quest_arrow_panel.visible = false

func _build_actions() -> void:
	actions = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 5)
	_anchor(actions, 1.0, 0.0, 1.0, 0.0, [-178.0, 8.0, -8.0, 42.0])
	root_control.add_child(actions)
	var inventory := _button("Bolsa", Vector2(76, 34))
	inventory.pressed.connect(func() -> void: inventory_pressed.emit())
	actions.add_child(inventory)
	var menu := _button("☰", Vector2(42, 34), true)
	menu.tooltip_text = "Menú"
	menu.pressed.connect(func() -> void: menu_pressed.emit())
	actions.add_child(menu)
	menu_panel = _panel(Color(0.06, 0.07, 0.1, 0.97), Color("#c29b5b"))
	_anchor(menu_panel, 1.0, 0.0, 1.0, 0.0, [-184.0, 48.0, -8.0, 154.0])
	root_control.add_child(menu_panel)
	var menu_column := VBoxContainer.new()
	menu_column.add_theme_constant_override("separation", 4)
	menu_panel.add_child(menu_column)
	menu_column.add_child(_label("Menú", Stage1Theme.FONT_HEADING, Stage1Theme.COLOR_TEXT_GOLD))
	var save := _button("Guardar partida", Vector2(0, 30))
	save.pressed.connect(func() -> void:
		menu_panel.visible = false
		save_pressed.emit())
	menu_column.add_child(save)
	var load := _button("Cargar partida", Vector2(0, 30))
	load.pressed.connect(func() -> void:
		menu_panel.visible = false
		load_pressed.emit())
	menu_column.add_child(load)
	var close := _button("Cerrar", Vector2(0, 30))
	close.pressed.connect(func() -> void: menu_panel.visible = false)
	menu_column.add_child(close)
	menu_panel.visible = false
	joystick = Stage1VirtualJoystick.new()
	joystick.name = "VirtualJoystick"
	_anchor(joystick, 0.0, 1.0, 0.0, 1.0, [10.0, -112.0, 122.0, -8.0])
	root_control.add_child(joystick)
	interact_button = _button("Hablar", Vector2(112, 46), true)
	interact_button.name = "InteractionButton"
	_anchor(interact_button, 1.0, 1.0, 1.0, 1.0, [-122.0, -60.0, -10.0, -10.0])
	interact_button.pressed.connect(func() -> void: interact_pressed.emit())
	root_control.add_child(interact_button)
	prompt_label = _label("", Stage1Theme.FONT_BODY, Stage1Theme.COLOR_TEXT_GOLD)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	prompt_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_anchor(prompt_label, 0.40, 1.0, 1.0, 1.0, [0.0, -88.0, -12.0, -66.0])
	root_control.add_child(prompt_label)
	toast_label = _label("", Stage1Theme.FONT_BODY, Stage1Theme.COLOR_TEXT_GOLD)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_anchor(toast_label, 0.25, 1.0, 0.75, 1.0, [0.0, -40.0, 0.0, -14.0])
	root_control.add_child(toast_label)

func _build_inventory() -> void:
	inventory_panel = _panel(Color(0.06, 0.07, 0.1, 0.97), Color("#c29b5b"))
	_anchor(inventory_panel, 0.5, 0.5, 0.5, 0.5, [-160.0, -116.0, 160.0, 116.0])
	root_control.add_child(inventory_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	inventory_panel.add_child(column)
	column.add_child(_label("Bolsa", 16, Stage1Theme.COLOR_TEXT_GOLD))
	inventory_text = _label("", Stage1Theme.FONT_BODY, Stage1Theme.COLOR_TEXT)
	inventory_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(inventory_text)
	var close := _button("Cerrar", Vector2(0, 30))
	close.pressed.connect(func() -> void: inventory_panel.visible = false)
	column.add_child(close)
	inventory_panel.visible = false

func _build_feedback() -> void:
	feedback_panel = _panel(Color(0.05, 0.08, 0.09, 0.95), Color("#9d8652"))
	_anchor(feedback_panel, 0.5, 0.0, 0.5, 0.0, [-150.0, 104.0, 150.0, 154.0])
	root_control.add_child(feedback_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	feedback_panel.add_child(column)
	feedback_title = _label("", Stage1Theme.FONT_SMALL, Stage1Theme.COLOR_TEXT_GOLD)
	feedback_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(feedback_title)
	feedback_detail = _label("", Stage1Theme.FONT_BODY, Stage1Theme.COLOR_TEXT)
	feedback_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback_detail.max_lines_visible = 2
	column.add_child(feedback_detail)
	feedback_panel.visible = false

func set_player(target: PlayerController) -> void:
	player = target
	if joystick != null and not joystick.value_changed.is_connected(_on_joystick_value):
		joystick.value_changed.connect(_on_joystick_value)
	_refresh_profile()

func set_quest_world(target: VillageWorld) -> void:
	quest_world = target
	refresh_quest()

func _on_joystick_value(value: Vector2) -> void:
	if player != null:
		player.set_virtual_input(value)

func set_interaction_prompt(text: String) -> void:
	prompt_label.text = text
	interact_button.disabled = text.is_empty()

func set_dialogue_mode(active: bool) -> void:
	dialogue_mode = active
	if quest_panel != null:
		quest_panel.visible = not active
	if quest_arrow_panel != null:
		quest_arrow_panel.visible = not active and quest_arrow_panel.visible
	if actions != null:
		actions.visible = not active
	if joystick != null:
		joystick.visible = not active
	if interact_button != null:
		interact_button.visible = not active
	if prompt_label != null:
		prompt_label.visible = not active
	if active:
		if menu_panel != null:
			menu_panel.visible = false
		if inventory_panel != null:
			inventory_panel.visible = false
		if feedback_panel != null:
			feedback_panel.visible = false
	elif not _pending_feedback_title.is_empty():
		_show_quest_feedback(_pending_feedback_title, _pending_feedback_detail)
		_pending_feedback_title = ""
		_pending_feedback_detail = ""

func toggle_menu() -> void:
	if dialogue_mode:
		return
	menu_panel.visible = not menu_panel.visible

func toggle_inventory() -> void:
	if dialogue_mode:
		return
	inventory_panel.visible = not inventory_panel.visible
	_refresh_inventory()

func _refresh_inventory() -> void:
	var state := _state_node().get("state") as Dictionary
	var items: Dictionary = state.get("inventory", {}).get("items", {})
	if items.is_empty():
		inventory_text.text = "La bolsa está vacía."
		return
	var lines: Array[String] = []
	for id in items.keys():
		var item_name := "Linterna de Halven" if id == "ITEM_LANTERN" else "Ficha de Liria"
		lines.append("• %s × %d" % [item_name, int(items[id])])
	inventory_text.text = "\n".join(lines) + "\n\nObjetos de misión"

func _refresh_profile() -> void:
	var state := _state_node().get("state") as Dictionary
	var class_id := String(state.get("player", {}).get("class_id", ""))
	name_label.text = String(state.get("player", {}).get("player_name", "Aventurero"))
	class_label.text = "Nivel 1 · " + String(P1_CLASS_NAMES.get(class_id, "Clase"))

func refresh_quest() -> void:
	var state := _state_node()
	if state == null or quest_objective == null:
		return
	_refresh_profile()
	var status := String(state.call("quest_status", "MQ00_01"))
	var stage := int(state.call("quest_stage", "MQ00_01"))
	var objective := _objective_for(status, stage)
	quest_objective.text = objective
	quest_title.text = "Un día cualquiera"
	var signature := "%s:%d:%d" % [status, stage, int(state.call("item_quantity", "ITEM_LANTERN"))]
	if signature != _quest_signature:
		var first_update := _quest_signature.is_empty()
		_quest_signature = signature
		var title := "NUEVO OBJETIVO"
		if status == "COMPLETE":
			title = "MISIÓN COMPLETADA"
		var detail := "Explora Liria." if status == "COMPLETE" else objective
		if dialogue_mode:
			_pending_feedback_title = title
			_pending_feedback_detail = detail
		elif not (first_update and status == "NOT_STARTED"):
			_show_quest_feedback(title, detail)
	if quest_world != null:
		quest_target = quest_world.update_quest_markers(status, stage)
	_update_target_guidance()

func _objective_for(status: String, stage: int) -> String:
	match status:
		"NOT_STARTED": return "Habla con Iria en la plaza."
		"ACTIVE": return "Visita a Halven, al este de la plaza." if stage < 3 else "Regresa con Iria y entrega la linterna."
		"COMPLETE": return "Explora Liria."
	return ""

func _update_target_guidance() -> void:
	if quest_arrow_panel == null:
		return
	if dialogue_mode or quest_target == null or player == null:
		quest_arrow_panel.visible = false
		return
	var viewport_size := get_viewport().get_visible_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		quest_arrow_panel.visible = false
		return
	# Use the player-relative world distance rather than the current canvas
	# transform. This remains stable during camera smoothing and on wide 20:9
	# devices while still expressing the same on-screen visibility contract.
	var delta := quest_target.global_position - player.global_position
	var target_visible := absf(delta.x) <= viewport_size.x * 0.46 and absf(delta.y) <= viewport_size.y * 0.40
	quest_arrow_panel.visible = not target_visible
	if target_visible:
		return
	var symbol := "→"
	if absf(delta.y) > absf(delta.x):
		symbol = "↓" if delta.y > 0.0 else "↑"
	else:
		symbol = "→" if delta.x > 0.0 else "←"
	quest_arrow_label.text = symbol + "  " + quest_target.display_name

func _show_quest_feedback(title: String, detail: String) -> void:
	if feedback_panel == null or dialogue_mode:
		return
	_feedback_serial += 1
	var serial := _feedback_serial
	feedback_title.text = title
	feedback_detail.text = detail
	feedback_panel.visible = true
	feedback_panel.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(feedback_panel, "modulate:a", 1.0, 0.16)
	var timer := get_tree().create_timer(1.9)
	timer.timeout.connect(func() -> void:
		if feedback_panel != null and serial == _feedback_serial:
			var fade := create_tween()
			fade.tween_property(feedback_panel, "modulate:a", 0.0, 0.18)
			fade.tween_callback(func() -> void:
				if feedback_panel != null and serial == _feedback_serial:
					feedback_panel.visible = false
			)
	)

func notify(message: String) -> void:
	_toast_serial += 1
	var serial := _toast_serial
	toast_label.text = message
	var timer := get_tree().create_timer(2.2)
	timer.timeout.connect(func() -> void:
		if toast_label != null and serial == _toast_serial:
			toast_label.text = ""
	)
