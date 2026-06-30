extends RefCounted
class_name Grid

## Pure grid math. No nodes, no state beyond dimensions — easy to reason about and test.
## A "cell" is a Vector2i (x, y). World space puts x on the X axis and y on the Z axis,
## so the grid lies flat on the floor and the camera looks straight down at it.

var width: int
var height: int
var cell_size: float

func _init(w: int, h: int, cs: float = 1.0) -> void:
	width = w
	height = h
	cell_size = cs

func cell_to_world(cell: Vector2i) -> Vector3:
	return Vector3(cell.x * cell_size, 0.0, cell.y * cell_size)

## Inverse of cell_to_world: which cell a world position sits over (uses X/Z, ignores Y).
## Works in both turn-based (settled) and real-time (physics) movement.
func world_to_cell(pos: Vector3) -> Vector2i:
	return Vector2i(roundi(pos.x / cell_size), roundi(pos.z / cell_size))

func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < width and cell.y < height

func center_world() -> Vector3:
	return Vector3((width - 1) * 0.5 * cell_size, 0.0, (height - 1) * 0.5 * cell_size)
