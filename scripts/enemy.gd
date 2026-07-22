extends GridEntity

## An enemy that greedily steps toward the player and ends the level when it catches you.
## Works in BOTH modes like every entity: on_tick() for turn-based, _physics_process() for
## real-time (gated by _use_physics). Walls are COVER -- a blocked enemy just stays put; there
## is deliberately no pathfinding around walls, so the player uses walls to escape.

const MOVE_SPEED := 3.5     ## real-time chase speed (slower than the player's 5.0, so you can outrun it)
const TICKS_PER_MOVE := 2   ## turn-based: step once every N player ticks (higher = slower = easier)
const CATCH_RADIUS := 0.8   ## real-time catch distance (must exceed the ~0.64 capsule-contact gap)

var _tick_count := 0

func _init() -> void:
	pushable = false
	kind = "enemy"

# --- turn-based ---
func on_tick() -> void:
	if _use_physics or level.player == null:
		return
	_tick_count += 1
	if _tick_count % TICKS_PER_MOVE == 0:
		var d: Vector2i = level.player.grid_pos - grid_pos
		# Greedy: try the larger axis first, then the other. Blocked both ways -> stay put.
		for step in _step_order(d):
			if step != Vector2i.ZERO and level.try_move(self, step):
				break
	_check_caught()

func _step_order(d: Vector2i) -> Array:
	var horiz := Vector2i(signi(d.x), 0)
	var vert := Vector2i(0, signi(d.y))
	return [horiz, vert] if abs(d.x) >= abs(d.y) else [vert, horiz]

# --- real-time ---
func _physics_process(_delta: float) -> void:
	if not _use_physics:
		return
	if level.player != null:
		var to_player: Vector3 = level.player.global_position - global_position
		to_player.y = 0.0
		velocity = to_player.normalized() * MOVE_SPEED
	move_and_slide()
	_check_caught()

func _check_caught() -> void:
	if level.player == null:
		return
	if _use_physics:
		var a: Vector3 = global_position;  a.y = 0.0
		var b: Vector3 = level.player.global_position;  b.y = 0.0
		if a.distance_to(b) < CATCH_RADIUS:
			level.player_caught()
	else:
		var d: Vector2i = level.player.grid_pos - grid_pos
		if abs(d.x) + abs(d.y) <= 1:  # reached an adjacent cell -> grabs you
			level.player_caught()
