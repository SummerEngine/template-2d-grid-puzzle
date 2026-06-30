extends GridEntity

## A pushable crate. In turn-based mode Level.try_move() handles the push.
## In real-time mode _physics_process() runs move_and_slide() with drag,
## and the player transfers velocity into the box on collision.

const PUSH_DAMP := 6.0   ## how fast the box slows down after a push (higher = quicker stop)

func _init() -> void:
	pushable = true
	kind = "box"

func _physics_process(delta: float) -> void:
	if not _use_physics:
		return
	# Apply the push impulse then decay it with drag.
	velocity = _push_velocity
	_push_velocity = _push_velocity.move_toward(Vector3.ZERO, PUSH_DAMP * delta)
	move_and_slide()
