class_name RebuildHud
extends CanvasLayer

signal joystick_changed(value: Vector2)
signal attack_pressed
signal dodge_pressed
signal interact_pressed
signal potion_pressed
signal save_pressed
signal load_pressed
signal buy_potion_pressed
signal new_game_pressed
signal continue_pressed
signal dialogue_closed

var root: Control
var hp_label: Label
var coin_label: Label
var potion_label: Label
var objective_label: Label
var zone_label: Label
var interact_button: Button
var dodge_button: Button
var attack_button: Button
var potion_button: Button
var dialogue_panel: PanelContainer
var dialogue_speaker: Label
var dialogue_text: Label
var title_layer: Control
var pause_panel: PanelContainer
var inventory_panel: PanelContainer
var shop_panel: PanelContainer
var end_panel: PanelContainer
var _dialogue_open := false
var _vibration := true

const GOLD := Color("#d4ae62")
const PANEL := Color(0.055, 0.062, 0.082, 0.92)
const BORDER := Color("#8e744e")
const TEXT := Color("#e9e2ce")
const MUTED := Color("#a8afa5")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_root()
	_build_status()
	_build_touch_controls()
	_build_dialogue()
	_build_pause()
	_build_inventory()
	_build_shop()
	_build_end()

func _build_root() -> void:
	root = Control.new()
	root.name = "SafeHudRoot"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

func _panel(rect: Rect2, fill: Color = PANEL) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = rect.position
	panel.size = rect.size
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = BORDER
	style.set_border_width_all(2)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 9
	style.content_margin_right = 9
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _label(text: String, size: int = 13, color: Color = TEXT) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label

func _button(text: String, size: Vector2, emphasized: bool = false) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = size
	b.add_theme_font_size_override("font_size", 14)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#35424a") if not emphasized else Color("#6f5a37")
	normal.border_color = Color("#8c9a91") if not emphasized else GOLD
	normal.set_border_width_all(2)
	normal.corner_radius_top_left = 8
	normal.corner_radius_top_right = 8
	normal.corner_radius_bottom_left = 8
	normal.corner_radius_bottom_right = 8
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = normal.bg_color.lightened(0.16)
	pressed.border_color = Color("#f1d487")
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", normal)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("focus", pressed)
	b.add_theme_color_override("font_color", TEXT)
	return b

func _build_status() -> void:
	var status := _panel(Rect2(12, 10, 218, 66))
	root.add_child(status)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	status.add_child(box)
	hp_label = _label("VIDA 100/100", 14, GOLD)
	box.add_child(hp_label)
	var economy := HBoxContainer.new()
	coin_label = _label("Monedas 0", 12)
	potion_label = _label("Pociones 2", 12)
	economy.add_child(coin_label)
	var spacer := Control.new(); spacer.custom_minimum_size.x = 16; economy.add_child(spacer)
	economy.add_child(potion_label)
	box.add_child(economy)
	var quest := _panel(Rect2(390, 10, 238, 74))
	root.add_child(quest)
	var qbox := VBoxContainer.new(); qbox.add_theme_constant_override("separation", 1); quest.add_child(qbox)
	zone_label = _label("LIRIA", 13, GOLD); zone_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; qbox.add_child(zone_label)
	objective_label = _label("Objetivo", 12); objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; qbox.add_child(objective_label)

func _build_touch_controls() -> void:
	var joystick := Stage1VirtualJoystick.new()
	joystick.name = "Joystick"
	joystick.position = Vector2(14, 248)
	joystick.size = Vector2(98, 98)
	joystick.value_changed.connect(func(v: Vector2): joystick_changed.emit(v))
	root.add_child(joystick)
	attack_button = _button("ATAQUE", Vector2(76, 62), true)
	attack_button.position = Vector2(548, 282)
	attack_button.pressed.connect(func(): attack_pressed.emit())
	root.add_child(attack_button)
	dodge_button = _button("ESQUIVA", Vector2(72, 54))
	dodge_button.position = Vector2(468, 292)
	dodge_button.pressed.connect(func(): dodge_pressed.emit())
	root.add_child(dodge_button)
	interact_button = _button("HABLAR", Vector2(74, 48))
	interact_button.position = Vector2(548, 224)
	interact_button.pressed.connect(func(): interact_pressed.emit())
	root.add_child(interact_button)
	potion_button = _button("POCIÓN", Vector2(70, 44))
	potion_button.position = Vector2(474, 236)
	potion_button.pressed.connect(func(): potion_pressed.emit())
	root.add_child(potion_button)
	var menu := _button("Ⅱ", Vector2(42, 38))
	menu.position = Vector2(299, 10)
	menu.pressed.connect(_toggle_pause)
	root.add_child(menu)
	var bag := _button("Bolsa", Vector2(62, 38))
	bag.position = Vector2(306, 310)
	bag.pressed.connect(toggle_inventory)
	root.add_child(bag)

func _build_dialogue() -> void:
	dialogue_panel = _panel(Rect2(58, 218, 524, 126), Color(0.045,0.050,0.070,0.97))
	dialogue_panel.visible = false
	dialogue_panel.z_index = 50
	root.add_child(dialogue_panel)
	var box := VBoxContainer.new(); box.add_theme_constant_override("separation", 4); dialogue_panel.add_child(box)
	dialogue_speaker = _label("", 14, GOLD); box.add_child(dialogue_speaker)
	dialogue_text = _label("", 14); dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; dialogue_text.custom_minimum_size.y = 56; box.add_child(dialogue_text)
	var continue_btn := _button("Continuar", Vector2(0, 30), true)
	continue_btn.pressed.connect(close_dialogue)
	box.add_child(continue_btn)

func show_dialogue(speaker: String, text: String) -> void:
	dialogue_speaker.text = speaker
	dialogue_text.text = text
	dialogue_panel.visible = true
	_dialogue_open = true

func close_dialogue() -> void:
	if not _dialogue_open:
		return
	dialogue_panel.visible = false
	_dialogue_open = false
	dialogue_closed.emit()

func is_dialogue_open() -> bool:
	return _dialogue_open

func _build_pause() -> void:
	pause_panel = _panel(Rect2(190, 74, 260, 220), Color(0.035,0.04,0.055,0.98))
	pause_panel.visible = false; pause_panel.z_index = 90; root.add_child(pause_panel)
	var box := VBoxContainer.new(); box.add_theme_constant_override("separation", 8); pause_panel.add_child(box)
	var title := _label("PAUSA", 20, GOLD); title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; box.add_child(title)
	var resume := _button("Reanudar", Vector2(0, 34), true); resume.pressed.connect(_toggle_pause); box.add_child(resume)
	var save := _button("Guardar", Vector2(0, 32)); save.pressed.connect(func(): save_pressed.emit()); box.add_child(save)
	var load := _button("Cargar", Vector2(0, 32)); load.pressed.connect(func(): load_pressed.emit()); box.add_child(load)
	var vibrate := _button("Vibración: Sí", Vector2(0, 32)); vibrate.pressed.connect(func(): _vibration = not _vibration; vibrate.text = "Vibración: " + ("Sí" if _vibration else "No")); box.add_child(vibrate)

func _toggle_pause() -> void:
	if title_layer != null and title_layer.visible:
		return
	pause_panel.visible = not pause_panel.visible
	get_tree().paused = pause_panel.visible

func toggle_inventory() -> void:
	if pause_panel.visible or _dialogue_open:
		return
	inventory_panel.visible = not inventory_panel.visible

func _build_inventory() -> void:
	inventory_panel = _panel(Rect2(142, 76, 356, 214), Color(0.04,0.045,0.06,0.97))
	inventory_panel.visible = false; inventory_panel.z_index = 70; root.add_child(inventory_panel)
	var box := VBoxContainer.new(); box.add_theme_constant_override("separation", 8); inventory_panel.add_child(box)
	var title := _label("INVENTARIO", 18, GOLD); title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; box.add_child(title)
	var info := _label("Poción de Vitae\nRestaura 35 PV. Úsala desde el botón táctil durante exploración o combate.", 13); info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; info.custom_minimum_size.y = 90; box.add_child(info)
	var close := _button("Cerrar", Vector2(0, 34)); close.pressed.connect(toggle_inventory); box.add_child(close)

func _build_shop() -> void:
	shop_panel = _panel(Rect2(146, 86, 348, 196), Color(0.04,0.045,0.06,0.98))
	shop_panel.visible = false; shop_panel.z_index = 75; root.add_child(shop_panel)
	var box := VBoxContainer.new(); box.add_theme_constant_override("separation", 7); shop_panel.add_child(box)
	var title := _label("PUESTO DE CENIZA", 18, GOLD); title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; box.add_child(title)
	var info := _label("Poción de Vitae · 5 monedas\nUna mezcla amarga que restaura 35 PV.", 13); info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; box.add_child(info)
	var buy := _button("Comprar poción", Vector2(0, 36), true); buy.pressed.connect(func(): buy_potion_pressed.emit()); box.add_child(buy)
	var close := _button("Salir", Vector2(0, 32)); close.pressed.connect(func(): shop_panel.visible = false); box.add_child(close)

func open_shop() -> void:
	shop_panel.visible = true

func _build_end() -> void:
	end_panel = _panel(Rect2(112, 56, 416, 250), Color(0.025,0.03,0.045,0.985))
	end_panel.visible = false; end_panel.z_index = 100; root.add_child(end_panel)

func show_end(time_seconds: float, kills: int, coins: int) -> void:
	for child in end_panel.get_children(): child.queue_free()
	var box := VBoxContainer.new(); box.add_theme_constant_override("separation", 9); end_panel.add_child(box)
	var title := _label("FIN DEL VERTICAL SLICE", 22, GOLD); title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; box.add_child(title)
	var sub := _label("La primera ruina de Cyrion guarda más preguntas que respuestas.", 13, MUTED); sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; box.add_child(sub)
	var stats := _label("Tiempo: %02d:%02d\nEnemigos derrotados: %d\nMonedas: %d" % [int(time_seconds)/60, int(time_seconds)%60, kills, coins], 14); stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; box.add_child(stats)
	var again := _button("Volver al inicio", Vector2(0, 38), true); again.pressed.connect(func(): get_tree().reload_current_scene()); box.add_child(again)
	end_panel.visible = true

func show_title(has_save: bool) -> void:
	if title_layer != null:
		title_layer.queue_free()
	title_layer = Control.new(); title_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); title_layer.z_index = 120; root.add_child(title_layer)
	var bg := ColorRect.new(); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); bg.color = Color("#121c1d"); title_layer.add_child(bg)
	var band := ColorRect.new(); band.position = Vector2(0,78); band.size = Vector2(640,120); band.color = Color("#263736"); title_layer.add_child(band)
	var title := _label("ILYRION", 34, GOLD); title.position = Vector2(0,68); title.size = Vector2(640,52); title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title_layer.add_child(title)
	var sub := _label("Las Cinco Luces · reconstrucción visual", 14, MUTED); sub.position = Vector2(0,116); sub.size = Vector2(640,28); sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title_layer.add_child(sub)
	var new_game := _button("Nueva partida", Vector2(220,42), true); new_game.position = Vector2(210,202); new_game.pressed.connect(func(): title_layer.visible = false; new_game_pressed.emit()); title_layer.add_child(new_game)
	var cont := _button("Continuar", Vector2(220,38)); cont.position = Vector2(210,252); cont.disabled = not has_save; cont.pressed.connect(func(): title_layer.visible = false; continue_pressed.emit()); title_layer.add_child(cont)
	var note := _label("640×360 · controles táctiles · guardado local", 11, MUTED); note.position = Vector2(0,316); note.size = Vector2(640,20); note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title_layer.add_child(note)

func set_stats(hp: int, max_hp: int, coins: int, potions: int) -> void:
	hp_label.text = "VIDA %d/%d" % [hp, max_hp]
	coin_label.text = "Monedas %d" % coins
	potion_label.text = "Pociones %d" % potions

func set_objective(zone: String, text: String) -> void:
	zone_label.text = zone.to_upper().replace("_", " ")
	objective_label.text = text

func set_interaction(text: String) -> void:
	interact_button.text = text if text != "" else "HABLAR"
	interact_button.modulate.a = 1.0 if text != "" else 0.68

func notify(text: String) -> void:
	objective_label.text = text
