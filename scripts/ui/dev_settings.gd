extends Screen

## Dev Settings: a showcase of template features already in the codebase.
## The user picks their preferred options and can tell Summer Engine to hardcode
## them and delete this screen. Not meant to survive into a real release.


func _on_screen_ready() -> void:
	var col := center_column()
	col.add_child(make_title("Dev Settings"))

	var note := make_label(
		"This menu shows features this template already has in the code.
Feel free to tell Summer Engine to stick with one setting
and remove this menu.",
		16
	)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD
	note.custom_minimum_size.x = 400
	col.add_child(note)
	col.add_child(make_label("", 8))  # spacer

	# -- Camera view --
	var cam_row := HBoxContainer.new()
	var cam_label := make_label("Camera", 22)
	cam_label.custom_minimum_size.x = 120
	cam_row.add_child(cam_label)
	var cam_option := OptionButton.new()
	cam_option.custom_minimum_size = Vector2(260, 0)
	for name in ["Top-down", "Angled (ortho)", "Angled (perspective)"]:
		cam_option.add_item(name)
	cam_option.selected = LevelManager.cam_view
	cam_option.item_selected.connect(_on_cam_selected)
	cam_row.add_child(cam_option)
	col.add_child(cam_row)

	# -- Movement mode --
	var move_row := HBoxContainer.new()
	var move_label := make_label("Movement", 22)
	move_label.custom_minimum_size.x = 120
	move_row.add_child(move_label)
	var move_option := OptionButton.new()
	move_option.custom_minimum_size = Vector2(260, 0)
	for name in ["Turn-based (grid)", "Real-time (free)"]:
		move_option.add_item(name)
	move_option.selected = LevelManager.move_mode
	move_option.item_selected.connect(_on_move_selected)
	move_row.add_child(move_option)
	col.add_child(move_row)

	# -- Level Select --
	var check := CheckButton.new()
	check.text = "Level Select enabled"
	check.button_pressed = LevelManager.level_select_enabled
	check.toggled.connect(_on_level_select_toggled)
	col.add_child(check)

	# -- Back --
	var back := make_button("Back")
	back.pressed.connect(func(): GameFlow.goto("settings"))
	col.add_child(back)


func _on_cam_selected(index: int) -> void:
	LevelManager.cam_view = index


func _on_move_selected(index: int) -> void:
	LevelManager.move_mode = index


func _on_level_select_toggled(pressed: bool) -> void:
	LevelManager.level_select_enabled = pressed
