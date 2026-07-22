extends RigidBody3D

## A pushable crate. Dual-mode:
##  - Turn-based: FROZEN (kinematic). Level.try_move() relocates it and it lerps to the target
##    cell -- it behaves like any other grid tile.
##  - Real-time: UNFROZEN dynamic physics. Linear/angular damping act as friction so it stops
##    sliding soon after the push ends, and an OFF-CENTER shove from the player spins it. Gravity
##    is off, motion is locked to the floor plane (Y), and it only rotates about the vertical
##    axis (spins flat, never tips over).
##
## It deliberately does NOT extend GridEntity (that's a CharacterBody3D). Instead it mirrors the
## small slice of that interface the grid system needs (grid_pos / setup / set_cell / pushable),
## which Level accesses by duck typing.

const MOVE_LERP := 14.0    ## turn-based lerp-to-cell speed
const CENTER_Y := 0.45     ## half the cube height -- the body sits centered at this height

# --- grid interface (duck-typed by Level) ---
var grid_pos: Vector2i
var pushable := true
var kind := "box"
var level
var _use_physics := false
var _target_world := Vector3.ZERO

func _ready() -> void:
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	freeze = true                 # turn-based by default; GameManager unfreezes for real-time
	gravity_scale = 0.0
	axis_lock_linear_y = true     # stay on the floor plane
	axis_lock_angular_x = true    # only spin around the vertical axis (never tip over)
	axis_lock_angular_z = true
	linear_damp = 5.0             # "friction": stop sliding soon after the push ends
	angular_damp = 5.0            # settle the spin

func setup(level_ref, cell: Vector2i) -> void:
	level = level_ref
	grid_pos = cell
	global_position = level.grid.cell_to_world(cell) + Vector3(0, CENTER_Y, 0)
	_target_world = global_position

func set_cell(cell: Vector2i) -> void:
	grid_pos = cell
	_target_world = level.grid.cell_to_world(cell) + Vector3(0, CENTER_Y, 0)

## Called by GameManager when the movement mode changes.
func set_physics_active(active: bool) -> void:
	_use_physics = active
	freeze = not active
	if not active:
		linear_velocity = Vector3.ZERO
		angular_velocity = Vector3.ZERO
		rotation = Vector3.ZERO          # snap back to grid alignment
		_target_world = global_position

func _process(delta: float) -> void:
	if _use_physics or level == null:
		return  # real-time: physics owns the transform
	# Turn-based: lerp the frozen (kinematic) body toward its target cell.
	global_position = global_position.lerp(_target_world, clampf(MOVE_LERP * delta, 0.0, 1.0))

# Grid hooks, present for the interface (a plain crate has no per-tick behaviour).
func on_tick() -> void:
	pass

func on_bump(_other) -> void:
	pass
