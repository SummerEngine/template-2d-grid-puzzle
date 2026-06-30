extends Node

## Builds the whole UI look in code — NO image assets. Retro handheld palette
## (the classic Game Boy DMG 4 greens). Want a different vibe? Change the 5 colors below
## and every menu updates. Screens get this via `theme = UITheme.theme` (see screen.gd).

# --- palette (edit these to reskin everything) ---
const BG       := Color(0.043, 0.075, 0.035)   # near-black green (page background)
const DARKEST  := Color(0.059, 0.220, 0.059)   # #0f380f
const DARK     := Color(0.188, 0.384, 0.188)   # #306230
const LIGHT    := Color(0.545, 0.675, 0.059)   # #8bac0f
const LIGHTEST := Color(0.608, 0.737, 0.059)   # #9bbc0f
const ACCENT   := Color(0.608, 0.737, 0.059)   # same as LIGHTEST; used for highlights

var theme: Theme

func _ready() -> void:
	theme = _build()

func _build() -> Theme:
	var t := Theme.new()
	t.default_font_size = 20

	# Buttons — chunky, blocky, inverts on hover for that handheld feel.
	t.set_stylebox("normal", "Button", _box(DARK, LIGHT))
	t.set_stylebox("hover", "Button", _box(LIGHT, LIGHTEST))
	t.set_stylebox("pressed", "Button", _box(LIGHTEST, LIGHTEST))
	t.set_stylebox("disabled", "Button", _box(DARKEST, DARK))
	t.set_stylebox("focus", "Button", _focus_box())
	t.set_color("font_color", "Button", LIGHTEST)
	t.set_color("font_hover_color", "Button", DARKEST)
	t.set_color("font_pressed_color", "Button", DARKEST)
	t.set_color("font_focus_color", "Button", LIGHTEST)
	t.set_color("font_disabled_color", "Button", DARK)
	t.set_font_size("font_size", "Button", 22)

	# Panels / containers
	var panel := _box(DARKEST, LIGHT)
	t.set_stylebox("panel", "Panel", panel)
	t.set_stylebox("panel", "PanelContainer", panel)

	# Labels
	t.set_color("font_color", "Label", LIGHT)

	# Sliders (used by Settings)
	t.set_stylebox("slider", "HSlider", _flat(DARKEST))
	t.set_stylebox("grabber_area", "HSlider", _flat(LIGHT))
	t.set_stylebox("grabber_area_highlight", "HSlider", _flat(LIGHTEST))

	# CheckButton (used by Settings toggle) — keep default font colors readable
	t.set_color("font_color", "CheckButton", LIGHT)

	return t

func _box(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(3)
	s.set_corner_radius_all(0)        # blocky = retro
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	return s

func _flat(bg: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(0)
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	return s

func _focus_box() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0, 0, 0, 0)
	s.border_color = LIGHTEST
	s.set_border_width_all(3)
	s.set_corner_radius_all(0)
	return s
