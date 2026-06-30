extends Node3D
class_name Door

## A 3D door occupying one tile (1x1x0.3). Two halves slide apart along the X axis.
## The door blocks movement when closed (via walls map + a StaticBody3D collision).
## When open, collision is disabled and the halves visually slide apart.
##
## Call toggle() or open()/close() to control it. In the future, wire a key or
## pressure-plate check before calling open().

signal opened
signal closed

const OPEN_DISTANCE := 0.65  ## how far each half slides outward (X axis); gap = 2*(this-0.25) -> ~80% open
const SPEED := 3.0           ## open/close animation speed

var is_open := false

@onready var left_half: Node3D = $LeftHalf
@onready var right_half: Node3D = $RightHalf
@onready var collision: CollisionShape3D = $Body/Collision

var _animating := false
var _target_left_x: float
var _target_right_x: float


func _ready() -> void:
	_target_left_x = left_half.position.x
	_target_right_x = right_half.position.x


func _process(delta: float) -> void:
	if not _animating:
		return
	var left_done := _slide_to(left_half, _target_left_x, delta)
	var right_done := _slide_to(right_half, _target_right_x, delta)
	if left_done and right_done:
		_animating = false


func _slide_to(node: Node3D, target_x: float, delta: float) -> bool:
	var pos := node.position
	pos.x = move_toward(pos.x, target_x, SPEED * delta)
	node.position = pos
	return abs(pos.x - target_x) < 0.001


func open() -> void:
	if is_open:
		return
	is_open = true
	_animating = true
	_target_left_x = -OPEN_DISTANCE
	_target_right_x = OPEN_DISTANCE
	if collision:
		collision.disabled = true
	opened.emit()


func close() -> void:
	if not is_open:
		return
	is_open = false
	_animating = true
	_target_left_x = left_half.position.x - sign(left_half.position.x) * OPEN_DISTANCE
	# Snap to closed positions
	_target_left_x = -0.25
	_target_right_x = 0.25
	if collision:
		collision.disabled = false
	closed.emit()


func toggle() -> void:
	if is_open:
		close()
	else:
		open()
