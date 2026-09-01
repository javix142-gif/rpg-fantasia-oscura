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
var player: PlayerController

func _state_node() -> Node:
	return get_node_or_null("/root/GameState")

func _ready() -> void:
	root_control = Control.new()
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var safe_area := Stage1SafeAreaContainer.new()
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
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _label(text: String, size: int, color: Color) -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", color)
	return result

func _build_status() -> void:
	status_panel = _panel(Color(0.06, 0.07, 0.1, 0.90))
	status_panel.position = Vector2(10, 10)
	status_panel.size = Vector2(188, 66)
	root_control.add_child(status_panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	status_panel.add_child(row)
	var portrait := TextureRect.new()
	portrait.texture = load("res://assets/p1/player_portrait.png") as Texture2D
	portrait.custom_minimum_size = Vector2(52, 52)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	row.add_child(portrait)
	var column := VBoxContainer.new()
	row.add_child(column)
	name_label = _label("Aventurero", 13, Color("#ffe8ad"))
	column.add_child(name_label)
	class_label = _label("Nivel 1", 10, Color("#bac3d6"))
	column.add_child(class_label)
	hp_bar = _bar(Color("#bd4a4a"), 100)
	column.add_child(hp_bar)
	mp_bar = _bar(Color("#4e83b9"), 40)
	column.add_child(mp_bar)

func _bar(color: Color, max_value: float) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(104, 8)
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
	var panel := _panel(Color(0.07, 0.08, 0.12, 0.86))
	panel.position = Vector2(218, 10)
	panel.size = Vector2(254, 56)
	root_control.add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	quest_title = _label("MQ00_01 · Un día cualquiera", 12, Color("#f0bf5a"))
	column.add_child(quest_title)
	quest_objective = _label("Habla con Iria en la plaza.", 11, Color("#f5ecd0"))
	quest_objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(quest_objective)

func _build_actions() -> void:
	var menu := Button.new()
	menu.text = "≡"
	menu.position = Vector2(586, 10)
	menu.size = Vector2(42, 34)
	menu.tooltip_text = "Menú"
	menu.pressed.connect(func() -> void: menu_pressed.emit())
	root_control.add_child(menu)
	var inventory := Button.new()
	inventory.text = "Bolsa"
	inventory.position = Vector2(482, 10)
	inventory.size = Vector2(74, 34)
	inventory.pressed.connect(func() -> void: inventory_pressed.emit())
	root_control.add_child(inventory)
	var save := Button.new()
	save.text = "Guardar"
	save.position = Vector2(482, 48)
	save.size = Vector2(74, 26)
	save.add_theme_font_size_override("font_size", 10)
	save.pressed.connect(func() -> void: save_pressed.emit())
	root_control.add_child(save)
	var load := Button.new()
	load.text = "Cargar"
	load.position = Vector2(560, 48)
	load.size = Vector2(68, 26)
	load.add_theme_font_size_override("font_size", 10)
	load.pressed.connect(func() -> void: load_pressed.emit())
	root_control.add_child(load)
	joystick = Stage1VirtualJoystick.new()
	joystick.position = Vector2(16, 244)
	joystick.size = Vector2(112, 112)
	root_control.add_child(joystick)
	interact_button = Button.new()
	interact_button.text = "Interactuar"
	interact_button.position = Vector2(536, 292)
	interact_button.size = Vector2(96, 42)
	interact_button.add_theme_font_size_override("font_size", 11)
	interact_button.pressed.connect(func() -> void: interact_pressed.emit())
	root_control.add_child(interact_button)
	prompt_label = _label("", 11, Color("#ffe9a8"))
	prompt_label.position = Vector2(430, 264)
	prompt_label.size = Vector2(190, 24)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root_control.add_child(prompt_label)
	toast_label = _label("", 12, Color("#ffe9a8"))
	toast_label.position = Vector2(235, 322)
	toast_label.size = Vector2(200, 24)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_control.add_child(toast_label)

func _build_inventory() -> void:
	inventory_panel = _panel(Color(0.06, 0.07, 0.1, 0.96), Color("#c29b5b"))
	inventory_panel.position = Vector2(168, 72)
	inventory_panel.size = Vector2(304, 222)
	root_control.add_child(inventory_panel)
	var column := VBoxContainer.new()
	inventory_panel.add_child(column)
	var title := _label("INVENTARIO", 16, Color("#f0bf5a"))
	column.add_child(title)
	inventory_text = _label("", 12, Color("#f7eed5"))
	inventory_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(inventory_text)
	var close := Button.new()
	close.text = "Cerrar"
	close.pressed.connect(func() -> void: inventory_panel.visible = false)
	column.add_child(close)
	inventory_panel.visible = false

func set_player(target: PlayerController) -> void:
	player = target
	if joystick != null:
		joystick.value_changed.connect(_on_joystick_value)
	_refresh_profile()

func _on_joystick_value(value: Vector2) -> void:
	if player != null:
		player.set_virtual_input(value)

func set_interaction_prompt(text: String) -> void:
	prompt_label.text = text
	interact_button.modulate = Color.WHITE if not text.is_empty() else Color(0.55, 0.55, 0.60, 0.65)

func toggle_inventory() -> void:
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
		var name := "Linterna de Halven" if id == "ITEM_LANTERN" else "Ficha de Liria"
		lines.append("• %s × %d" % [name, int(items[id])])
	inventory_text.text = "\n".join(lines) + "\n\nLos objetos de misión no ocupan equipo."

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
			quest_objective.text = "Habla con Halven en el edificio del este." if int(state.call("quest_stage", "MQ00_01")) < 3 else "Regresa con Iria y entrega la linterna."
		"COMPLETE": quest_objective.text = "Completada · Liria sigue en calma."
	quest_title.text = "MQ00_01 · Un día cualquiera · " + status

func notify(message: String) -> void:
	toast_label.text = message
	var timer := get_tree().create_timer(2.2)
	timer.timeout.connect(func() -> void:
		if toast_label != null:
			toast_label.text = ""
	)
