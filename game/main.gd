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
	return Stage1Theme.button(text, minimum_size, emphasized)

func _show_menu() -> void:
	mode = "menu"
	world = null
	player = null
	hud = null
	dialogue = null
	_clear_view()
	queue_redraw()
	var canvas_size := _layout_size()
	var title_background := TextureRect.new()
	title_background.name = "LiriaTitleBackground"
	title_background.texture = load("res://assets/p1_1/liria_scene.png") as Texture2D
	title_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	title_background.modulate = Color(0.78, 0.86, 0.72, 0.92)
	title_background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	title_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title_background)
	var veil := ColorRect.new()
	veil.name = "TitleReadabilityVeil"
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.color = Color(0.025, 0.045, 0.05, 0.48)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)
	var title := Label.new()
	title.text = "RPG FANTASÍA OSCURA"
	title.position = Vector2(0, 32)
	title.size = Vector2(canvas_size.x, 38)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", Stage1Theme.FONT_TITLE)
	title.add_theme_color_override("font_color", Stage1Theme.COLOR_TEXT_GOLD)
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
	var panel_position := Vector2(maxf(42.0, canvas_size.x * 0.12), 108.0)
	var panel_size := Vector2(270, 214)
	var panel := _menu_panel(panel_position, panel_size)
	add_child(panel)
	var location_card := _menu_panel(Vector2(canvas_size.x * 0.64, 148.0), Vector2(210, 116))
	add_child(location_card)
	var location_column := VBoxContainer.new()
	location_column.position = location_card.position + Vector2(16, 14)
	location_column.size = location_card.size - Vector2(32, 28)
	location_column.add_theme_constant_override("separation", 4)
	add_child(location_column)
	var location_name := Stage1Theme.label("LIRIA", 18, Stage1Theme.COLOR_TEXT_GOLD)
	location_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	location_column.add_child(location_name)
	var location_rule := HSeparator.new()
	location_column.add_child(location_rule)
	var location_text := Stage1Theme.label("Zona neutral de Ilyrion\nUn prólogo tranquilo entre vecinos.", Stage1Theme.FONT_BODY, Stage1Theme.COLOR_TEXT)
	location_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	location_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	location_column.add_child(location_text)
	var column := VBoxContainer.new()
	column.position = panel_position + Vector2(18, 12)
	column.size = panel_size - Vector2(36, 24)
	column.add_theme_constant_override("separation", 8)
	add_child(column)
	var prompt := Label.new()
	prompt.text = "Comienza tu día en Liria"
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", Stage1Theme.FONT_HEADING)
	prompt.add_theme_color_override("font_color", Stage1Theme.COLOR_TEXT)
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
	hint.text = "Controles táctiles activos" if OS.has_feature("android") else "WASD / flechas · E o botón Hablar"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", Stage1Theme.FONT_SMALL)
	hint.add_theme_color_override("font_color", Stage1Theme.COLOR_TEXT_MUTED)
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
	title.add_theme_font_size_override("font_size", Stage1Theme.FONT_HEADING + 8)
	title.add_theme_color_override("font_color", Stage1Theme.COLOR_TEXT_GOLD)
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
	name_label.add_theme_color_override("font_color", Stage1Theme.COLOR_TEXT)
	column.add_child(name_label)
	name_input = LineEdit.new()
	name_input.placeholder_text = "Escribe un nombre"
	name_input.text = "Ari"
	name_input.custom_minimum_size = Vector2(0, 30)
	column.add_child(name_input)
	var class_label := Label.new()
	class_label.text = "Clase inicial"
	class_label.add_theme_color_override("font_color", Stage1Theme.COLOR_TEXT)
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
		_fade_from_menu_to_world()

func _continue_game() -> void:
	if bool(_save_service().call("load_slot", "autosave")):
		_fade_from_menu_to_world()

func _load_game() -> void:
	if bool(_save_service().call("load_slot", "slot_01")):
		_fade_from_menu_to_world()

func _fade_from_menu_to_world() -> void:
	var transition := Stage1TransitionLayer.new()
	transition.name = "MenuTransition"
	add_child(transition)
	transition.transition_finished.connect(_enter_world_after_menu_fade)
	transition.fade_to_black(0.18)

func _enter_world_after_menu_fade() -> void:
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
	dialogue.offset_top = -154.0
	dialogue.offset_right = 0.0
	dialogue.offset_bottom = -8.0
	dialogue.grow_horizontal = Control.GROW_DIRECTION_BOTH
	dialogue.grow_vertical = Control.GROW_DIRECTION_BEGIN
	dialogue.z_index = 100
	var dialogue_parent: Control = hud.root_control if hud != null and hud.root_control != null else self
	dialogue_parent.add_child(dialogue)
	dialogue.closed.connect(_dialogue_closed)
	hud.set_dialogue_mode(false)
	hud.set_quest_world(world)
	hud.refresh_quest()
	_on_interaction_target_changed(player.current_interaction_target)
	var state := _game_state()
	if state != null and not state.state_changed.is_connected(_on_game_state_changed):
		state.state_changed.connect(_on_game_state_changed)
	var transition := Stage1TransitionLayer.new()
	transition.name = "Stage1Transition"
	add_child(transition)
	transition.fade_from_black(0.32, "LIRIA\nZona neutral de Ilyrion")

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

func _on_game_state_changed() -> void:
	if mode == "world" and hud != null:
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
	Stage1Theme.apply_panel(panel, Color(0.08, 0.09, 0.13, 0.94), Color("#a67b4c"), true)
	return panel

func _draw() -> void:
	if mode == "menu":
		var canvas_size := _layout_size()
		draw_rect(Rect2(Vector2.ZERO, canvas_size), Color("#182a2a"), true)
