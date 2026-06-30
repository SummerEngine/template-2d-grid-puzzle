extends Node3D

## Cosmetic float + spin for collectibles (stars, keys, ...). Purely visual — the Level handles
## the actual pickup (walk onto the cell). Attach to any Node3D: it spins around the vertical
## axis and bobs in place. Shared by every floating collectible, so the feel is tuned in one spot.

const SPIN_SPEED := 1.8   ## radians per second around the vertical axis
const BOB_HEIGHT := 0.1   ## how far it bobs up and down
const BOB_SPEED := 2.5    ## bob speed

var _t := 0.0
var _base_y := 0.0

func _ready() -> void:
	_base_y = position.y

func _process(delta: float) -> void:
	_t += delta
	rotate_y(SPIN_SPEED * delta)
	position.y = _base_y + sin(_t * BOB_SPEED) * BOB_HEIGHT
