extends Screen

## Level Select — the showcase grid. One card per level; a checkmark means solved.
## Layout only (no manual colors): the shared theme makes it look good.

func _on_screen_ready() -> void:
	var col := center_column(24)

	col.add_child(make_title("Select Level"))

	var grid := GridContainer.new()
	grid.columns = min(LevelManager.count(), 4)
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 18)

	for i in range(LevelManager.count()):
		var label = LevelManager.level_name(i)
		if LevelManager.is_complete(i):
			label += "  ✓"
		var btn := make_button(label, 200)
		btn.custom_minimum_size = Vector2(200, 90)
		btn.pressed.connect(GameFlow.play_level.bind(i))
		grid.add_child(btn)

	col.add_child(grid)

	var back := make_button("Back")
	back.pressed.connect(func(): GameFlow.goto("main_menu"))
	col.add_child(back)
