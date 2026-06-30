extends Node
class_name TickManager

## The heartbeat of the world. Everything that moves listens to `tick`.
## The ONLY difference between the two genres is what fires the tick:
##   REALTIME  -> a timer (great for arcade / action / snake / pac-man feel)
##   TURN_BASED -> a movement keypress (great for sokoban / roguelike / puzzle)
## Because entity code only reacts to `tick`, the same game works in both modes —
## flip GameManager.tick_mode_realtime to switch.

signal tick

enum Mode { REALTIME, TURN_BASED }

var mode: Mode = Mode.TURN_BASED
var interval: float = 0.15  ## seconds between ticks in REALTIME mode
var _accum: float = 0.0

func _process(delta: float) -> void:
	match mode:
		Mode.REALTIME:
			_accum += delta
			if _accum >= interval:
				_accum = 0.0
				tick.emit()
		Mode.TURN_BASED:
			if _move_just_pressed():
				tick.emit()

func _move_just_pressed() -> bool:
	return (Input.is_action_just_pressed("move_up")
		or Input.is_action_just_pressed("move_down")
		or Input.is_action_just_pressed("move_left")
		or Input.is_action_just_pressed("move_right")
		or Input.is_action_just_pressed("action"))
