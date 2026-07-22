extends CharacterBody3D
class_name GridEntity

## Base class for anything that lives ON a cell: the player, a crate, an enemy, a coin.
## Extends CharacterBody3D so in real-time mode we get actual physics collisions
## (move_and_slide). In turn-based mode the CharacterBody3D machinery sits idle
## and the grid-lerp path takes over -- both coexist cleanly.
##
## Subclass it and override on_tick() / on_bump() to give it behaviour.
## The grid position (grid_pos) is the source of truth in turn-based mode;
## in real-time mode the physics engine owns position and we sync grid_pos from it.

var grid_pos: Vector2i
var pushable: bool = false   ## can another entity shove this one? (crates set this true)
var kind: String = ""        ## free-form tag, handy in on_bump()
var level                    ## reference to the Level, set in setup()

var _use_physics: bool = false  ## toggled by GameManager when move_mode changes
var _target_world: Vector3 = Vector3.ZERO
const MOVE_LERP: float = 14.0

func setup(level_ref, cell: Vector2i) -> void:
	level = level_ref
	grid_pos = cell
	position = level.grid.cell_to_world(cell)
	_target_world = position

func _process(delta: float) -> void:
	if level == null or _use_physics:
		return  # physics owns position in real-time mode
	# Visual interpolation only -- gameplay already happened in grid space.
	position = position.lerp(_target_world, clampf(MOVE_LERP * delta, 0.0, 1.0))

func set_cell(cell: Vector2i) -> void:
	grid_pos = cell
	_target_world = level.grid.cell_to_world(cell)

## Override these in subclasses:
func on_tick() -> void:
	pass

func on_bump(_other: GridEntity) -> void:
	pass

## Toggle real-time physics on/off (called by GameManager when the movement mode changes).
func set_physics_active(active: bool) -> void:
	_use_physics = active
