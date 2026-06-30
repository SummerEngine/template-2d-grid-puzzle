extends Node

## Bridges an Arduino controller (USB serial) to Godot's input actions.
##
## WHY THIS EXISTS: the whole game reads input via Input.is_action_pressed("move_up")
## and friends. The keyboard feeds those actions automatically (see project.godot).
## This autoload lets an Arduino feed the SAME actions, so nothing else in the game
## has to change when you plug in hardware. Develop on the keyboard now; add the
## controller later for free.
##
## SUGGESTED PROTOCOL (dead simple): the Arduino sends ONE byte per update, where each
## bit is one button held/released:
##     bit 0 = up   bit 1 = down   bit 2 = left   bit 3 = right   bit 4 = action
## e.g. byte 0b00000101 means "up + left held".
##
## Godot has no built-in serial port reader. To actually read the Arduino you need a
## serial GDExtension addon (search the Asset Library for "serial"). Once installed,
## fill in _open_serial() and _poll_serial() below — the rest already works.

const BIT_ACTIONS := ["move_up", "move_down", "move_left", "move_right", "action"]

var _serial = null  # set this to your serial-port object in _open_serial()

func _ready() -> void:
	_open_serial()

func _process(_delta: float) -> void:
	if _serial == null:
		return  # no controller -> keyboard still works, do nothing
	var byte := _poll_serial()
	if byte < 0:
		return
	for i in BIT_ACTIONS.size():
		var pressed := ((byte >> i) & 1) == 1
		var act: String = BIT_ACTIONS[i]
		if pressed and not Input.is_action_pressed(act):
			Input.action_press(act)
		elif not pressed and Input.is_action_pressed(act):
			Input.action_release(act)

# --- fill these in once you have a serial addon ---

func _open_serial() -> void:
	# Example (pseudo-code, depends on your addon):
	#   _serial = SerialPort.new()
	#   _serial.open("COM3", 115200)   # Windows: "COM3", Linux: "/dev/ttyUSB0"
	# Leaving _serial as null keeps the game on keyboard input.
	_serial = null

func _poll_serial() -> int:
	# Return the latest byte (0..255), or -1 if no new data this frame.
	#   if _serial.available() > 0: return _serial.read_byte()
	return -1
