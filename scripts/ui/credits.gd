extends Screen

## Credits screen: a title + a few lines of credit text and a Back button.

func _on_screen_ready() -> void:
	var col := center_column()
	col.add_child(make_title("Credits"))
	col.add_child(make_label("GridKit — a grid-game hackathon template"))
	col.add_child(make_label("Built with Summer Engine"))
	col.add_child(make_label("Primitives, not pixels"))
	col.add_child(make_label("Your team name here"))

	var back := make_button("Back")
	back.pressed.connect(func(): GameFlow.goto("main_menu"))
	col.add_child(back)
