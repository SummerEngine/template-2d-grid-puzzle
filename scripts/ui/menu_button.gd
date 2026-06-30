extends Button

## Attach to any Button in a menu to get consistent feel: hover/click sounds (silent until
## you register sounds in AudioManager) and a tiny grow-on-focus/hover pop. Styling itself
## comes from the shared theme, so this script is only about feel.

func _ready() -> void:
	pivot_offset = size * 0.5
	resized.connect(func(): pivot_offset = size * 0.5)
	mouse_entered.connect(_on_hover)
	focus_entered.connect(_on_hover)
	mouse_exited.connect(_on_unhover)
	focus_exited.connect(_on_unhover)
	pressed.connect(func(): AudioManager.play_ui("click"))

func _on_hover() -> void:
	AudioManager.play_ui("hover")
	_scale_to(1.06)

func _on_unhover() -> void:
	_scale_to(1.0)

func _scale_to(s: float) -> void:
	var t := create_tween()
	t.tween_property(self, "scale", Vector2(s, s), 0.08)
