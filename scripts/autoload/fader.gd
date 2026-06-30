extends CanvasLayer

## Full-screen fade used for clean transitions between screens. Owned by GameFlow.
## Lives on a very high layer so it covers everything, and ignores mouse so it never
## blocks clicks while transparent.

var _rect: ColorRect

func _ready() -> void:
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect = ColorRect.new()
	_rect.color = Color(0.043, 0.075, 0.035, 0.0)  # UITheme.BG, starts transparent
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_rect)

func fade_out(duration: float = 0.2) -> void:
	var t := create_tween()
	t.tween_property(_rect, "color:a", 1.0, duration)
	await t.finished

func fade_in(duration: float = 0.2) -> void:
	var t := create_tween()
	t.tween_property(_rect, "color:a", 0.0, duration)
	await t.finished
