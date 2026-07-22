extends Screen

## Shown when an enemy catches the player. Mirrors Level Complete, but with Retry.
func _on_screen_ready() -> void:
	var col := center_column()
	col.add_child(make_title("Caught!"))
	col.add_child(make_label(LevelManager.level_name(LevelManager.current_index)))

	var retry := make_button("Retry")
	retry.pressed.connect(func():
		LevelManager.start(LevelManager.current_index)
		GameFlow.goto("game"))
	col.add_child(retry)

	if LevelManager.level_select_enabled:
		var sel := make_button("Level Select")
		sel.pressed.connect(func(): GameFlow.goto("level_select"))
		col.add_child(sel)

	var menu := make_button("Main Menu")
	menu.pressed.connect(func(): GameFlow.goto("main_menu"))
	col.add_child(menu)
