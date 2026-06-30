extends Screen

## Settings screen: volume sliders for each audio bus, plus a link to Dev Settings.


func _on_screen_ready() -> void:
	var col := center_column()
	col.add_child(make_title("Settings"))

	for bus in ["Master", "Music", "SFX"]:
		var row := HBoxContainer.new()
		var label := make_label(bus, 22)
		label.custom_minimum_size.x = 120
		row.add_child(label)
		var slider := HSlider.new()
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.01
		slider.custom_minimum_size = Vector2(260, 0)
		slider.value = AudioManager.get_volume(bus)
		slider.value_changed.connect(_on_vol.bind(bus))
		row.add_child(slider)
		col.add_child(row)

	var dev := make_button("Dev Settings")
	dev.pressed.connect(func(): GameFlow.goto("dev_settings"))
	col.add_child(dev)

	var back := make_button("Back")
	back.pressed.connect(func(): GameFlow.goto("main_menu"))
	col.add_child(back)


func _on_vol(value: float, bus: String) -> void:
	AudioManager.set_volume(bus, value)
