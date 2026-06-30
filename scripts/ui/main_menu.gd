extends Screen

## The main menu. Title, subtitle, and the top-level navigation buttons.

func _on_screen_ready() -> void:
	var col := center_column()
	col.add_child(make_title("GridKit"))
	col.add_child(make_label("a tiny grid game"))

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 16)
	col.add_child(spacer)

	var play := make_button("Play")
	play.pressed.connect(func(): GameFlow.play_level(0))
	col.add_child(play)

	if LevelManager.level_select_enabled:
		var level_select := make_button("Level Select")
		level_select.pressed.connect(func(): GameFlow.goto("level_select"))
		col.add_child(level_select)

	var settings := make_button("Settings")
	settings.pressed.connect(func(): GameFlow.goto("settings"))
	col.add_child(settings)

	var credits := make_button("Credits")
	credits.pressed.connect(func(): GameFlow.goto("credits"))
	col.add_child(credits)

	var quit := make_button("Quit")
	quit.pressed.connect(func(): get_tree().quit())
	col.add_child(quit)
