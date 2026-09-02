extends Control

const P1_CLASS_IDS: Array[String] = ["CLASS_WARRIOR", "CLASS_SWORDSMAN", "CLASS_ARCHER", "CLASS_SORCERER", "CLASS_CLERIC"]
const P1_CLASS_NAMES: Dictionary = {"CLASS_WARRIOR":"Guerrero", "CLASS_SWORDSMAN":"Espadachín", "CLASS_ARCHER":"Arquero", "CLASS_SORCERER":"Hechicero", "CLASS_CLERIC":"Clérigo"}

var mode: String = "menu"
var world: VillageWorld
var player: PlayerController
var hud: Stage1Hud
var dialogue: DialoguePanel
var name_input: LineEdit
var class_picker: OptionButton

func _game_state() -> Node:
	return get_node_or_null("/root/GameState")

func _save_service() -> Node:
	return get_node_or_null("/root/SaveService")

func _ready() -> void:
	set_process(true)
	_configure_display_contract()
	_show_menu()

func _configure_display_contract() -> void:
	# Godot 4.7.2 maps SCREEN_LANDSCAPE to Android screenOrientation=0. The
	# explicit runtime call complements the project/export settings on devices
	# that launch while the OS is still locked to portrait.
	if OS.has_feature("android"):
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)
	get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND

func _process(_delta: float) -> void:
	if mode != "world" or player == null:
		return
	if Input.is_action_just_pressed("interact"):
		_request_interaction()
	if Input.is_action_just_pressed("inventory"):
		hud.toggle_inventory()
	if InputMap.has_action("save_game") and Input.is_action_just_pressed("save_game"):
		_save_game()
	if InputMap.has_action("load_game") and Input.is_action_just_pressed("load_game"):
		_load_game()
	if Input.is_action_just_pressed("ui_cancel"):
		_show_menu()
	hud.refresh_quest()

func _clear_view() -> void:
	for child in get_children():
		child.queue_free()

func _layout_size() -> Vector2:
	var result := size
	if result.x <= 0.0 or result.y <= 0.0:
		result = get_viewport_rect().size
	return result

func _menu_button(text: String, minimum_size: Vector2, emphasized: bool = false) -> Button:
	var result := Button.new()
	result.text = text
	result.custom_minimum_size = minimum_size
	result.focus_mode = Control.FOCUS_NONE
	result.add_theme_font_size_override("font_size", 12)
	result.add_theme_color_override("font_color", Color("#fff1cb"))
	result.add_theme_color_override("font_hover_color", Color("#fff8e8"))
	result.add_theme_color_override("font_pressed_color", Color("#fff8e8"))
	result.add_theme_color_override("font_disabled_color", Color(0.7, 0.7, 0.7, 0.55))
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#2a3543") if not emphasized else Color("#76552f")
	normal.border_color = Color("#64788a") if not emphasized else Color("#d5ae67")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(6)
	normal.content_margin_left = 9
	normal.content_margin_right = 9
	var hover := normal.duplicate()
	hover.bg_color = Color("#3c4c5d") if not emphasized else Color("#98713f")
	var pressed := normal.duplicate()
	pressed.bg_color = Color("#1e2733") if not emphasized else Color("#513a23")
	var disabled := normal.duplicate()
	disabled.bg_color = Color(0.15, 0.17, 0.21, 0.6)
	disabled.border_color = Color(0.36, 0.38, 0.42, 0.45)
	result.add_theme_stylebox_override("normal", normal)
	result.add_theme_stylebox_override("hover", hover)
	result.add_theme_stylebox_override("pressed", pressed)
	result.add_theme_stylebox_override("disabled", disabled)
	return result

func _show_menu() -> void:
	mode = "menu"
	world = null
	player = null
	hud = null
	dialogue = null
	_clear_view()
	queue_redraw()
	var canvas_size := _layout_size()
	var title := Label.new()
	title.text = "RPG FANTASÍA OSCURA"
	title.position = Vector2(0, 32)
	title.size = Vector2(canvas_size.x, 38)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color("#f0c56d"))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Un prólogo tranquilo en Liria"
	subtitle.position = Vector2(0, 68)
	subtitle.size = Vector2(canvas_size.x, 24)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.add_theme_color_override("font_color", Color("#b6c6b4"))
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(subtitle)
	var panel_position := Vector2(canvas_size.x * 0.22, canvas_size.y * 0.34)
	var panel_size := Vector2(270, 210)
	var panel := _menu_panel(panel_position, panel_size)
	add_child(panel)
	var visual_preview := TextureRect.new()
	visual_preview.texture = load("res://assets/p1_1/liria_scene.png") as Texture2D
	visual_preview.position = Vector2(canvas_size.x - 186.0, panel_position.y + 4.0)
	visual_preview.size = Vector2(172, 114)
	visual_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	visual_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	visual_preview.modulate = Color(1.0, 1.0, 1.0, 0.86)
	visual_preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(visual_preview)
	var column := VBoxContainer.new()
	column.position = panel_position + Vector2(18, 12)
	column.size = panel_size - Vector2(36, 24)
	column.add_theme_constant_override("separation", 8)
	add_child(column)
	var prompt := Label.new()
	prompt.text = "Comienza tu día en Liria"
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 14)
	prompt.add_theme_color_override("font_color", Color("#fff1cb"))
	column.add_child(prompt)
	var new_game := _menu_button("Nueva partida", Vector2(0, 34), true)
	new_game.pressed.connect(_show_creation)
	column.add_child(new_game)
	var continue_button := _menu_button("Continuar", Vector2(0, 30))
	continue_button.disabled = not bool(_save_service().call("has_valid_save", "autosave"))
	continue_button.pressed.connect(_continue_game)
	column.add_child(continue_button)
	var load_button := _menu_button("Cargar partida", Vector2(0, 30))
	load_button.disabled = not bool(_save_service().call("has_valid_save", "slot_01"))
	load_button.pressed.connect(_load_game)
	column.add_child(load_button)
	var hint := Label.new()
	hint.text = "WASD / flechas · E o botón Hablar"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_color_override("font_color", Color("#99a9aa"))
	column.add_child(hint)

func _show_creation() -> void:
	_clear_view()
	queue_redraw()
	var canvas_size := _layout_size()
	var title := Label.new()
	title.text = "NUEVA PARTIDA"
	title.position = Vector2(0, 28)
	title.size = Vector2(canvas_size.x, 34)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color("#f0c56d"))
	add_child(title)
	var panel_size := Vector2(minf(360.0, canvas_size.x - 40.0), 240.0)
	var panel_position := Vector2((canvas_size.x - panel_size.x) * 0.5, 78.0)
	var panel := _menu_panel(panel_position, panel_size)
	add_child(panel)
	var column := VBoxContainer.new()
	column.position = panel_position + Vector2(24, 18)
	column.size = panel_size - Vector2(48, 30)
	column.add_theme_constant_override("separation", 7)
	add_child(column)
	var name_label := Label.new()
	name_label.text = "Nombre del aventurero"
	name_label.add_theme_color_override("font_color", Color("#f7e6bb"))
	column.add_child(name_label)
	name_input = LineEdit.new()
	name_input.placeholder_text = "Escribe un nombre"
	name_input.text = "Ari"
	name_input.custom_minimum_size = Vector2(0, 30)
	column.add_child(name_input)
	var class_label := Label.new()
	class_label.text = "Clase inicial"
	class_label.add_theme_color_override("font_color", Color("#f7e6bb"))
	column.add_child(class_label)
	class_picker = OptionButton.new()
	class_picker.custom_minimum_size = Vector2(0, 30)
	for class_id in P1_CLASS_IDS:
		class_picker.add_item(String(P1_CLASS_NAMES[class_id]))
		class_picker.set_item_metadata(class_picker.item_count - 1, class_id)
	column.add_child(class_picker)
	var start := _menu_button("Entrar en Liria", Vector2(0, 34), true)
	start.pressed.connect(_create_profile)
	column.add_child(start)
	var back := _menu_button("Volver", Vector2(0, 30))
	back.pressed.connect(_show_menu)
	column.add_child(back)

func _create_profile() -> void:
	if name_input == null or class_picker == null:
		return
	var class_id := String(class_picker.get_selected_metadata())
	if bool(_game_state().call("new_game", name_input.text, class_id)):
		_show_world()

func _continue_game() -> void:
	if bool(_save_service().call("load_slot", "autosave")):
		_show_world()

func _load_game() -> void:
	if bool(_save_service().call("load_slot", "slot_01")):
		_show_world()

func _show_world() -> void:
	mode = "world"
	_clear_view()
	world = VillageWorld.new()
	add_child(world)
	player = PlayerController.new()
	player.global_position = _game_state().call("get_position")
	world.add_child(player)
	player.interaction_target_changed.connect(_on_interaction_target_changed)
	player.interaction_requested.connect(_on_interaction_requested)
	var camera := Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(VillageWorld.WORLD_SIZE.x)
	camera.limit_bottom = int(VillageWorld.WORLD_SIZE.y)
	player.add_child(camera)
	hud = Stage1Hud.new()
	add_child(hud)
	hud.set_player(player)
	hud.interact_pressed.connect(_request_interaction)
	hud.inventory_pressed.connect(hud.toggle_inventory)
	hud.save_pressed.connect(_save_game)
	hud.load_pressed.connect(_load_game)
	hud.menu_pressed.connect(hud.toggle_menu)
	dialogue = DialoguePanel.new()
	dialogue.anchor_left = 0.12
	dialogue.anchor_top = 1.0
	dialogue.anchor_right = 0.88
	dialogue.anchor_bottom = 1.0
	dialogue.offset_left = 0.0
	dialogue.offset_top = -144.0
	dialogue.offset_right = 0.0
	dialogue.offset_bottom = -8.0
	dialogue.grow_horizontal = Control.GROW_DIRECTION_BOTH
	dialogue.grow_vertical = Control.GROW_DIRECTION_BEGIN
	dialogue.z_index = 100
	var dialogue_parent: Control = hud.root_control if hud != null and hud.root_control != null else self
	dialogue_parent.add_child(dialogue)
	dialogue.closed.connect(_dialogue_closed)
	hud.set_dialogue_mode(false)
	hud.refresh_quest()
	_on_interaction_target_changed(player.current_interaction_target)

func _on_interaction_target_changed(target: InteractionTarget) -> void:
	if hud == null:
		return
	hud.set_interaction_prompt(target.prompt if target != null else "")

func _request_interaction() -> void:
	if player == null or not player.request_interaction():
		if hud != null:
			hud.notify("Acércate a un vecino para hablar")

func _interact() -> void:
	# Compatibility wrapper for tools; the public path remains PlayerController
	# request_interaction(), which is also what the touch button invokes.
	_request_interaction()

func _on_interaction_requested(target: InteractionTarget) -> void:
	if target == null or dialogue == null or dialogue.visible:
		return
	if dialogue.open_actor(target.target_id):
		if player != null:
			player.set_physics_process(false)
		if hud != null:
			hud.set_dialogue_mode(true)

func _dialogue_closed() -> void:
	if player != null:
		player.set_physics_process(true)
	if hud != null:
		hud.set_dialogue_mode(false)
		hud.refresh_quest()

func _save_game() -> void:
	if player != null:
		_game_state().call("set_position", player.global_position)
	var ok := bool(_save_service().call("save_slot", "slot_01"))
	_save_service().call("save_slot", "autosave")
	if hud != null:
		hud.notify("Partida guardada" if ok else "No se pudo guardar")

func _menu_panel(panel_position: Vector2, panel_size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = panel_position
	panel.size = panel_size
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.09, 0.13, 0.94)
	style.border_color = Color("#a67b4c")
	style.set_border_width_all(2)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _draw() -> void:
	if mode == "menu":
		var canvas_size := _layout_size()
		draw_rect(Rect2(Vector2.ZERO, canvas_size), Color("#182a2a"), true)
		draw_circle(Vector2(canvas_size.x * 0.14, canvas_size.y * 0.22), canvas_size.y * 0.36, Color(0.22, 0.42, 0.28, 0.42))
		draw_circle(Vector2(canvas_size.x * 0.88, canvas_size.y * 0.86), canvas_size.y * 0.52, Color(0.35, 0.21, 0.19, 0.38))
		for x in range(0, int(canvas_size.x), 32):
			draw_line(Vector2(x, canvas_size.y - 18), Vector2(x + 18, canvas_size.y - 40), Color(0.67, 0.53, 0.34, 0.22), 2)
