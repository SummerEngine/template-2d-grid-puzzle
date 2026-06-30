extends GridEntity

## The player. In turn-based mode on_tick() reads input and asks the Level for one grid move.
## In real-time mode _physics_process() reads input every frame and calls move_and_slide()
## for free movement with real collision against walls. When the player walks into a
## pushable box, velocity transfers to the box so it slides away.
##
## Input actions (move_up/down/left/right, action) come from the keyboard OR an Arduino --
## this script doesn't know or care which. See scripts/input_router.gd.

const MOVE_SPEED: float = 5.0
const PUSH_FORCE: float = 4.5   ## how hard the player shoves a box

func _physics_process(_delta: float) -> void:
	if not _use_physics:
		return
	var dir := _read_dir_free()
	velocity = Vector3(dir.x, 0.0, dir.y) * MOVE_SPEED
	move_and_slide()

	# Push any pushable box we collided with.
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		var other := col.get_collider()
		if other is GridEntity and other.pushable:
			var push_dir := -col.get_normal()
			push_dir.y = 0.0
			push_dir = push_dir.normalized()
			var strength := velocity.length() * col.get_depth()
			other._push_velocity = push_dir * strength * PUSH_FORCE

func on_tick() -> void:
	if _use_physics:
		return
	var dir := _read_dir_grid()
	if dir != Vector2i.ZERO:
		level.try_move(self, dir)

## Grid movement: single-axis priority, no diagonals.
func _read_dir_grid() -> Vector2i:
	if Input.is_action_pressed("move_up"):
		return Vector2i(0, -1)
	if Input.is_action_pressed("move_down"):
		return Vector2i(0, 1)
	if Input.is_action_pressed("move_left"):
		return Vector2i(-1, 0)
	if Input.is_action_pressed("move_right"):
		return Vector2i(1, 0)
	return Vector2i.ZERO

## Free movement: normalized vector, diagonals allowed.
func _read_dir_free() -> Vector2:
	var dir := Vector2.ZERO
	if Input.is_action_pressed("move_up"):
		dir.y -= 1.0
	if Input.is_action_pressed("move_down"):
		dir.y += 1.0
	if Input.is_action_pressed("move_left"):
		dir.x -= 1.0
	if Input.is_action_pressed("move_right"):
		dir.x += 1.0
	return dir.normalized()
