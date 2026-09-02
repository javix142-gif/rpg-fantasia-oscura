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
var prompt_label: Label
var inventory_panel: PanelContainer
var inventory_text: Label
var toast_label: Label
var joystick: Stage1VirtualJoystick
var interact_button: Button
var menu_panel: PanelContainer
var player: PlayerController
var dialogue_mode := false

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
	visible = true

func _panel(color: Color, border: Color = Color("#8b6a46")) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(2)
	style.corner_radius_top_left = 7
	style.corner_radius_top_right = 7
	style.corner_radius_bottom_left = 7
	style.corner_radius_bottom_right = 7
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _label(text: String, size: int, color: Color) -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", color)
	return result

func _button(text: String, minimum_size: Vector2, emphasized: bool = false) -> Button:
	var result := Button.new()
	result.text = text
	result.custom_minimum_size = minimum_size
	result.focus_mode = Control.FOCUS_NONE
	result.add_theme_font_size_override("font_size", 11 if not emphasized else 12)
	result.add_theme_color_override("font_color", Color("#fff1cb"))
	result.add_theme_color_override("font_hover_color", Color("#fff8e8"))
	result.add_theme_color_override("font_pressed_color", Color("#fff8e8"))
	result.add_theme_color_override("font_disabled_color", Color(0.7, 0.7, 0.7, 0.55))
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#293344") if not emphasized else Color("#6f5232")
	normal.border_color = Color("#607086") if not emphasized else Color("#d3ab61")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(6)
	normal.content_margin_left = 8
	normal.content_margin_right = 8
	var hover := normal.duplicate()
	hover.bg_color = Color("#3b4c5e") if not emphasized else Color("#906b3b")
	var pressed := normal.duplicate()
	pressed.bg_color = Color("#1f2734") if not emphasized else Color("#513b25")
	var disabled := normal.duplicate()
	disabled.bg_color = Color(0.15, 0.17, 0.21, 0.6)
	disabled.border_color = Color(0.36, 0.38, 0.42, 0.45)
	result.add_theme_stylebox_override("normal", normal)
	result.add_theme_stylebox_override("hover", hover)
	result.add_theme_stylebox_override("pressed", pressed)
	result.add_theme_stylebox_override("disabled", disabled)
	return result

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
	status_panel = _panel(Color(0.06, 0.07, 0.1, 0.90))
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
	name_label = _label("Aventurero", 12, Color("#ffe8ad"))
	column.add_child(name_label)
	class_label = _label("Nivel 1", 9, Color("#bac3d6"))
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
	bg.corner_radius_top_left = 3
	bg.corner_radius_top_right = 3
	bg.corner_radius_bottom_left = 3
	bg.corner_radius_bottom_right = 3
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.corner_radius_top_left = 3
	fill.corner_radius_top_right = 3
	fill.corner_radius_bottom_left = 3
	fill.corner_radius_bottom_right = 3
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	return bar

func _build_quest() -> void:
	quest_panel = _panel(Color(0.07, 0.08, 0.12, 0.88), Color("#9f7b4b"))
	_anchor(quest_panel, 0.5, 0.0, 0.5, 0.0, [-128.0, 8.0, 128.0, 66.0])
	root_control.add_child(quest_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 1)
	quest_panel.add_child(column)
	column.add_child(_label("OBJETIVO", 8, Color("#9bb39b")))
	quest_title = _label("Un día cualquiera", 12, Color("#f0bf5a"))
	column.add_child(quest_title)
	quest_objective = _label("Habla con Iria en la plaza.", 10, Color("#f5ecd0"))
	quest_objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(quest_objective)

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
	menu_panel = _panel(Color(0.06, 0.07, 0.1, 0.96), Color("#c29b5b"))
	_anchor(menu_panel, 1.0, 0.0, 1.0, 0.0, [-184.0, 48.0, -8.0, 154.0])
	root_control.add_child(menu_panel)
	var menu_column := VBoxContainer.new()
	menu_column.add_theme_constant_override("separation", 4)
	menu_panel.add_child(menu_column)
	menu_column.add_child(_label("Menú", 13, Color("#f0bf5a")))
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
	interact_button = _button("Hablar", Vector2(112, 50), true)
	interact_button.name = "InteractionButton"
	_anchor(interact_button, 1.0, 1.0, 1.0, 1.0, [-122.0, -60.0, -10.0, -10.0])
	interact_button.pressed.connect(func() -> void: interact_pressed.emit())
	root_control.add_child(interact_button)
	prompt_label = _label("", 10, Color("#ffe9a8"))
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	prompt_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_anchor(prompt_label, 0.40, 1.0, 1.0, 1.0, [0.0, -90.0, -12.0, -66.0])
	root_control.add_child(prompt_label)
	toast_label = _label("", 11, Color("#ffe9a8"))
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_anchor(toast_label, 0.25, 1.0, 0.75, 1.0, [0.0, -40.0, 0.0, -14.0])
	root_control.add_child(toast_label)

func _build_inventory() -> void:
	inventory_panel = _panel(Color(0.06, 0.07, 0.1, 0.96), Color("#c29b5b"))
	_anchor(inventory_panel, 0.5, 0.5, 0.5, 0.5, [-160.0, -116.0, 160.0, 116.0])
	root_control.add_child(inventory_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	inventory_panel.add_child(column)
	column.add_child(_label("Bolsa", 16, Color("#f0bf5a")))
	inventory_text = _label("", 11, Color("#f7eed5"))
	inventory_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(inventory_text)
	var close := _button("Cerrar", Vector2(0, 30))
	close.pressed.connect(func() -> void: inventory_panel.visible = false)
	column.add_child(close)
	inventory_panel.visible = false

func set_player(target: PlayerController) -> void:
	player = target
	if joystick != null and not joystick.value_changed.is_connected(_on_joystick_value):
		joystick.value_changed.connect(_on_joystick_value)
	_refresh_profile()

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
	_refresh_profile()
	var state := _state_node()
	var status := String(state.call("quest_status", "MQ00_01"))
	match status:
		"NOT_STARTED":
			quest_objective.text = "Habla con Iria en la plaza."
		"ACTIVE":
			quest_objective.text = "Visita a Halven, al este de la plaza." if int(state.call("quest_stage", "MQ00_01")) < 3 else "Regresa con Iria y entrega la linterna."
		"COMPLETE":
			quest_objective.text = "La mañana sigue en calma."
	quest_title.text = "Un día cualquiera"

func notify(message: String) -> void:
	toast_label.text = message
	var timer := get_tree().create_timer(2.2)
	timer.timeout.connect(func() -> void:
		if toast_label != null:
			toast_label.text = ""
	)
