extends Control
class_name Screen

## Base class every menu screen extends. Applies the shared theme, paints the page
## background, and offers small builder helpers so all screens look consistent.
## Subclasses override _on_screen_ready() (NOT _ready) and build their UI with the helpers.

const MenuButtonScript := preload("res://scripts/ui/menu_button.gd")

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UITheme.theme
	var bg := ColorRect.new()
	bg.color = UITheme.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	move_child(bg, 0)
	_on_screen_ready()

## Override this in each screen.
func _on_screen_ready() -> void:
	pass

# --- builder helpers (use these so screens stay consistent) ---

## A vertically-centered column you add rows to. Returns the VBoxContainer.
func center_column(separation: int = 16) -> VBoxContainer:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", separation)
	center.add_child(vbox)
	return vbox

## A big title label.
func make_title(text: String, size: int = 52) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", UITheme.LIGHTEST)
	return l

## A smaller subtitle/caption label.
func make_label(text: String, size: int = 20) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", UITheme.LIGHT)
	return l

## A themed button with hover/click sound + focus pop already wired.
func make_button(text: String, min_width: int = 300) -> Button:
	var b := Button.new()
	b.set_script(MenuButtonScript)
	b.text = text
	b.custom_minimum_size = Vector2(min_width, 0)
	return b
