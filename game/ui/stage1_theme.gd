class_name Stage1Theme
extends RefCounted

## Small, code-first visual grammar shared by the title, HUD and dialogue.
## Keeping these values together prevents each screen from drifting into a
## different UI style while preserving the existing lightweight UI approach.

const COLOR_PANEL := Color("#10151d")
const COLOR_PANEL_STRONG := Color("#0b1017")
const COLOR_PANEL_SOFT := Color("#1b2630")
const COLOR_BORDER := Color("#8f6b43")
const COLOR_BORDER_FOCUS := Color("#d0a45b")
const COLOR_TEXT := Color("#f7efd7")
const COLOR_TEXT_MUTED := Color("#b7c2bb")
const COLOR_TEXT_GOLD := Color("#f0c56d")
const COLOR_TEXT_GREEN := Color("#a9c49f")
const COLOR_BUTTON := Color("#293745")
const COLOR_BUTTON_HOVER := Color("#3d5260")
const COLOR_BUTTON_PRESSED := Color("#1e2a34")
const COLOR_BUTTON_EMPHASIZED := Color("#765632")
const COLOR_BUTTON_EMPHASIZED_HOVER := Color("#98713f")
const COLOR_BUTTON_EMPHASIZED_PRESSED := Color("#513a23")

const FONT_TITLE := 24
const FONT_HEADING := 14
const FONT_BODY := 11
const FONT_SMALL := 9
const FONT_TOUCH := 11

static func panel_style(background: Color = COLOR_PANEL, border: Color = COLOR_BORDER, strong: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_PANEL_STRONG if strong else background
	style.border_color = border
	style.set_border_width_all(1 if not strong else 2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 9
	style.content_margin_right = 9
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	return style

static func apply_panel(panel: PanelContainer, background: Color = COLOR_PANEL, border: Color = COLOR_BORDER, strong: bool = false) -> PanelContainer:
	panel.add_theme_stylebox_override("panel", panel_style(background, border, strong))
	return panel

static func label(text: String, size: int = FONT_BODY, color: Color = COLOR_TEXT) -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", color)
	return result

static func button(text: String, minimum_size: Vector2 = Vector2.ZERO, emphasized: bool = false) -> Button:
	var result := Button.new()
	result.text = text
	result.custom_minimum_size = minimum_size
	result.focus_mode = Control.FOCUS_NONE
	result.add_theme_font_size_override("font_size", FONT_TOUCH if not emphasized else FONT_HEADING)
	result.add_theme_color_override("font_color", COLOR_TEXT)
	result.add_theme_color_override("font_hover_color", Color("#fff9e9"))
	result.add_theme_color_override("font_pressed_color", Color("#fff9e9"))
	result.add_theme_color_override("font_disabled_color", Color(0.7, 0.72, 0.72, 0.55))
	var normal := StyleBoxFlat.new()
	normal.bg_color = COLOR_BUTTON_EMPHASIZED if emphasized else COLOR_BUTTON
	normal.border_color = COLOR_BORDER_FOCUS if emphasized else Color("#5d7380")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(6)
	normal.content_margin_left = 8
	normal.content_margin_right = 8
	normal.content_margin_top = 4
	normal.content_margin_bottom = 4
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = COLOR_BUTTON_EMPHASIZED_HOVER if emphasized else COLOR_BUTTON_HOVER
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = COLOR_BUTTON_EMPHASIZED_PRESSED if emphasized else COLOR_BUTTON_PRESSED
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(0.15, 0.17, 0.21, 0.6)
	disabled.border_color = Color(0.36, 0.38, 0.42, 0.45)
	result.add_theme_stylebox_override("normal", normal)
	result.add_theme_stylebox_override("hover", hover)
	result.add_theme_stylebox_override("pressed", pressed)
	result.add_theme_stylebox_override("disabled", disabled)
	return result

static func compact_button(text: String, minimum_size: Vector2 = Vector2.ZERO, emphasized: bool = false) -> Button:
	var result := button(text, minimum_size, emphasized)
	result.add_theme_font_size_override("font_size", FONT_BODY)
	return result
