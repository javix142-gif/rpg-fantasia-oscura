extends Control

const P1_CLASS_IDS: Array[String] = ["CLASS_WARRIOR", "CLASS_SWORDSMAN", "CLASS_ARCHER", "CLASS_SORCERER", "CLASS_CLERIC"]
const P1_CLASS_NAMES: Dictionary = {"CLASS_WARRIOR":"Guerrero", "CLASS_SWORDSMAN":"Espadachín", "CLASS_ARCHER":"Arquero", "CLASS_SORCERER":"Hechicero", "CLASS_CLERIC":"Clérigo"}

var mode: String = "menu"
var world: VillageWorld
var player: PlayerController
var hud: Stage1Hud
var dialogue: DialoguePanel
var nearest_npc: VillageNpc
var name_input: LineEdit
var class_picker: OptionButton

func _game_state() -> Node:
	return get_node_or_null("/root/GameState")

func _save_service() -> Node:
	return get_node_or_null("/root/SaveService")

func _ready() -> void:
	set_process(true)
	_show_menu()

func _process(_delta: float) -> void:
	if mode != "world" or player == null or world == null:
		return
	var candidate := world.get_nearest_npc(player.global_position, 76.0)
	if candidate != nearest_npc:
		nearest_npc = candidate
		hud.set_interaction_prompt(candidate.prompt_text() if candidate != null else "")
	if Input.is_action_just_pressed("interact"):
		_interact()
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

func _show_menu() -> void:
	mode = "menu"
	world = null
	player = null
	hud = null
	dialogue = null
	nearest_npc = null
	_clear_view()
	queue_redraw()
	var title := Label.new()
	title.text = "RPG FANTASÍA OSCURA"
	title.position = Vector2(0, 42)
	title.size = Vector2(640, 42)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color("#f0c56d"))
	add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Liria · prólogo jugable · P1 provisional"
	subtitle.position = Vector2(0, 85)
	subtitle.size = Vector2(640, 24)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.add_theme_color_override("font_color", Color("#b6c6b4"))
	add_child(subtitle)
	var panel := _menu_panel(Vector2(188, 118), Vector2(264, 200))
	add_child(panel)
	var visual_preview := TextureRect.new()
	visual_preview.texture = load("res://assets/p1/liria_kit.png") as Texture2D
	visual_preview.position = Vector2(474, 122)
	visual_preview.size = Vector2(150, 100)
	visual_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	visual_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	visual_preview.modulate = Color(1.0, 1.0, 1.0, 0.68)
	visual_preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(visual_preview)
	var column := VBoxContainer.new()
	column.position = Vector2(208, 132)
	column.size = Vector2(224, 170)
	column.add_theme_constant_override("separation", 8)
	add_child(column)
	var prompt := Label.new()
	prompt.text = "Comienza tu día en Liria"
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 14)
	prompt.add_theme_color_override("font_color", Color("#fff1cb"))
	column.add_child(prompt)
	var new_game := Button.new()
	new_game.text = "Nueva partida"
	new_game.custom_minimum_size = Vector2(0, 34)
	new_game.pressed.connect(_show_creation)
	column.add_child(new_game)
	var continue_button := Button.new()
	continue_button.text = "Continuar"
	continue_button.custom_minimum_size = Vector2(0, 30)
	continue_button.disabled = not bool(_save_service().call("has_valid_save", "autosave"))
	continue_button.pressed.connect(_continue_game)
	column.add_child(continue_button)
	var load_button := Button.new()
	load_button.text = "Cargar partida"
	load_button.custom_minimum_size = Vector2(0, 30)
	load_button.disabled = not bool(_save_service().call("has_valid_save", "slot_01"))
	load_button.pressed.connect(_load_game)
	column.add_child(load_button)
	var hint := Label.new()
	hint.text = "Teclado: WASD / flechas · E interactúa"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_color_override("font_color", Color("#99a9aa"))
	column.add_child(hint)

func _show_creation() -> void:
	_clear_view()
	queue_redraw()
	var title := Label.new()
	title.text = "NUEVA PARTIDA"
	title.position = Vector2(0, 38)
	title.size = Vector2(640, 34)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color("#f0c56d"))
	add_child(title)
	var panel := _menu_panel(Vector2(146, 88), Vector2(348, 236))
	add_child(panel)
	var column := VBoxContainer.new()
	column.position = Vector2(170, 106)
	column.size = Vector2(300, 200)
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
	var start := Button.new()
	start.text = "Entrar en Liria"
	start.custom_minimum_size = Vector2(0, 34)
	start.pressed.connect(_create_profile)
	column.add_child(start)
	var back := Button.new()
	back.text = "Volver"
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
	queue_redraw()
	world = VillageWorld.new()
	add_child(world)
	player = PlayerController.new()
	player.global_position = _game_state().call("get_position")
	world.add_child(player)
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
	hud.interact_pressed.connect(_interact)
	hud.inventory_pressed.connect(hud.toggle_inventory)
	hud.save_pressed.connect(_save_game)
	hud.load_pressed.connect(_load_game)
	hud.menu_pressed.connect(_show_menu)
	dialogue = DialoguePanel.new()
	dialogue.position = Vector2(92, 250)
	dialogue.size = Vector2(456, 100)
	dialogue.z_index = 50
	add_child(dialogue)
	dialogue.closed.connect(_dialogue_closed)
	hud.refresh_quest()

func _interact() -> void:
	if dialogue != null and dialogue.visible:
		return
	if nearest_npc == null and player != null and world != null:
		nearest_npc = world.get_nearest_npc(player.global_position, 76.0)
	if nearest_npc == null:
		if hud != null:
			hud.notify("Acércate a un vecino para interactuar")
		return
	if player != null:
		player.set_physics_process(false)
	dialogue.open_actor(nearest_npc.actor_id)

func _dialogue_closed() -> void:
	if player != null:
		player.set_physics_process(true)
	if hud != null:
		hud.refresh_quest()

func _save_game() -> void:
	if player != null:
		_game_state().call("set_position", player.global_position)
	var ok := bool(_save_service().call("save_slot", "slot_01"))
	_save_service().call("save_slot", "autosave")
	if hud != null:
		hud.notify("Partida guardada" if ok else "No se pudo guardar")

func _menu_panel(position: Vector2, panel_size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = position
	panel.size = panel_size
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.09, 0.13, 0.94)
	style.border_color = Color("#a67b4c")
	style.set_border_width_all(2)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _draw() -> void:
	if mode == "menu":
		draw_rect(Rect2(Vector2.ZERO, Vector2(640, 360)), Color("#182a2a"), true)
		draw_circle(Vector2(100, 80), 130, Color(0.22, 0.42, 0.28, 0.42))
		draw_circle(Vector2(555, 300), 190, Color(0.35, 0.21, 0.19, 0.38))
		for x in range(0, 640, 32):
			draw_line(Vector2(x, 342), Vector2(x + 18, 320), Color(0.67, 0.53, 0.34, 0.22), 2)
