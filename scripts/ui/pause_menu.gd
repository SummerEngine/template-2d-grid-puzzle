extends CanvasLayer

## Pause overlay that floats over the running 3D game (NOT a Screen).
## It pauses the tree, dims the world, and offers Resume / Restart / Quit.
## Built entirely in code so it can be instanced on top of anything.

func _ready() -> void:
	# Keep working while the tree is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 64
	get_tree().paused = true

	# Root control fills the screen and carries the shared theme.
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = UITheme.theme
	add_child(root)

	# Dim the game behind us and block clicks from reaching it.
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dim)

	# Centered panel with the menu contents.
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var panel := PanelContainer.new()
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "Paused"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", UITheme.LIGHTEST)
	vbox.add_child(title)

	var resume := _make_button("Resume")
	resume.pressed.connect(_resume)
	vbox.add_child(resume)

	var restart := _make_button("Restart")
	restart.pressed.connect(func():
		get_tree().paused = false
		GameFlow.goto("game"))
	vbox.add_child(restart)

	var quit := _make_button("Quit to Menu")
	quit.pressed.connect(func():
		get_tree().paused = false
		GameFlow.goto("main_menu"))
	vbox.add_child(quit)

func _make_button(text: String) -> Button:
	var b := Button.new()
	b.set_script(load("res://scripts/ui/menu_button.gd"))
	b.text = text
	b.custom_minimum_size = Vector2(260, 0)
	return b

func _resume() -> void:
	get_tree().paused = false
	queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_resume()
