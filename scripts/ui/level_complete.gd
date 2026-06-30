extends Screen

## Shown after a level is solved. Offers Next / Replay / Level Select / Main Menu,
## or a "you beat the whole game" screen once every level is complete.

func _on_screen_ready() -> void:
	var col := center_column()

	if LevelManager.all_complete():
		col.add_child(make_title("All Levels Complete!"))
		col.add_child(make_label("Thanks for playing"))

		if LevelManager.level_select_enabled:
			var sel := make_button("Level Select")
			sel.pressed.connect(func(): GameFlow.goto("level_select"))
			col.add_child(sel)

		var menu := make_button("Main Menu")
		menu.pressed.connect(func(): GameFlow.goto("main_menu"))
		col.add_child(menu)
		return

	col.add_child(make_title("Level Complete!"))
	col.add_child(make_label(LevelManager.level_name(LevelManager.current_index)))

	if LevelManager.has_next():
		var next := make_button("Next Level")
		next.pressed.connect(func():
			LevelManager.advance()
			GameFlow.goto("game"))
		col.add_child(next)

	var replay := make_button("Replay")
	replay.pressed.connect(func(): GameFlow.goto("game"))
	col.add_child(replay)

	if LevelManager.level_select_enabled:
		var sel := make_button("Level Select")
		sel.pressed.connect(func(): GameFlow.goto("level_select"))
		col.add_child(sel)

	var menu := make_button("Main Menu")
	menu.pressed.connect(func(): GameFlow.goto("main_menu"))
	col.add_child(menu)
