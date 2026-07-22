extends AnimatedSprite3D
class_name SpriteCharacter

## A 2D animated character living in the 3D top-down world. Build one from any 4-direction
## sprite sheet with Visuals.make_sprite_character(...) — it slices the sheet into
## walk_down / walk_up / walk_left / walk_right animations.
##
## It picks its own animation by WATCHING ITS OWN MOTION each frame (no coupling to player,
## enemy, or box code), so the same node works on anything that moves, in both movement modes
## (turn-based lerp and real-time physics). Attach to a moving entity and it just works.

const MIN_SPEED := 0.4  ## world units/sec below which the character counts as standing still

var _last_pos: Vector3
var _initialized := false

func _process(delta: float) -> void:
	if not _initialized:
		_last_pos = global_position
		_initialized = true
		return
	var vel: Vector3 = (global_position - _last_pos) / maxf(delta, 0.0001)
	_last_pos = global_position

	var planar := Vector2(vel.x, vel.z)
	if planar.length() < MIN_SPEED:
		stop()  # rest on the first frame of the current direction
		return

	# Dominant axis picks the facing. +z is "down" on screen with the top-down camera.
	var anim: String
	if absf(planar.x) >= absf(planar.y):
		anim = "walk_right" if planar.x > 0.0 else "walk_left"
	else:
		anim = "walk_down" if planar.y > 0.0 else "walk_up"
	if animation != anim or not is_playing():
		play(anim)
