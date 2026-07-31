extends Node3D
class_name RobotCharacter

## The 3D player: the standard Summer robot (art/models/robot/). The sibling of
## SpriteCharacter -- the same trick of WATCHING ITS OWN MOTION each frame, so it
## works unchanged in both movement modes (turn-based lerp and real-time physics).
## Unlike the billboarded sprite, it also TURNS to face where it's going.
##
## Built by Visuals.make_robot_character(): a pivot carrying this script, with the
## rigged robot_idle.glb instanced underneath.
##
## CLIPS: the rig arrives with only its baked idle, and the imported library is
## read-only (plus fresh imports don't loop). So _ready() copies idle + the clip
## from each GLB in EXTRA_GLBS into our own "extra" library with looping forced on.
## Playable names are simply extra/idle, extra/walk, extra/run.

const EXTRA_GLBS := {
	walk = "res://art/models/robot/robot_walk.glb",
	run = "res://art/models/robot/robot_run.glb",
}

## Generated Summer models import ~1 unit tall with the pivot at the feet, so a plain
## scale fits the robot to a cell -- no measuring needed (skinned-mesh AABBs lie about
## height once a Meshy armature bakes in its 0.01 scale). Nudge this if he's off.
const ROBOT_SCALE := 0.9

const MIN_SPEED := 0.4   ## world units/sec below which the robot counts as standing still
const RUN_SPEED := 2.0   ## sustained speed that upgrades walk to run...
const RUN_HOLD := 0.25   ## ...after this many seconds continuously above RUN_SPEED
const TURN_SPEED := 12.0 ## how snappily the robot turns to face its travel direction
## glTF characters are authored facing +Z, so atan2(dir.x, dir.z) faces travel with no
## offset. If a swapped-in rig walks backwards, set this to PI -- never rotate the mesh.
const MODEL_YAW_OFFSET := 0.0

var _anim: AnimationPlayer
var _last_pos: Vector3
var _initialized := false
var _fast_time := 0.0    # seconds spent continuously above RUN_SPEED

func _ready() -> void:
	_anim = find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _anim == null:
		push_error("RobotCharacter: no AnimationPlayer under %s -- is the rig GLB missing?" % name)
		return
	var baked := _anim.get_animation_list()
	if baked.is_empty():
		push_error("RobotCharacter: the rig has no baked idle clip")
		_anim = null
		return
	var lib := AnimationLibrary.new()
	_add_looping(lib, "idle", _anim.get_animation(baked[0]))
	for key in EXTRA_GLBS:
		var entry: String = key  # explicit type: key is a Variant dictionary key
		var packed := load(EXTRA_GLBS[entry]) as PackedScene
		if packed == null:
			push_error("RobotCharacter: could not load %s" % EXTRA_GLBS[entry])
			continue
		var inst: Node = packed.instantiate()
		var src := inst.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if src == null or src.get_animation_list().is_empty():
			push_error("RobotCharacter: no animation clip inside %s" % EXTRA_GLBS[entry])
			inst.free()
			continue
		# Name the entry from the FILE (walk/run), not the clip's internal name --
		# internal names are unreliable across per-clip exports.
		_add_looping(lib, entry, src.get_animation(src.get_animation_list()[0]))
		inst.free()
	_anim.add_animation_library("extra", lib)
	_anim.play("extra/idle")

static func _add_looping(lib: AnimationLibrary, entry: String, anim: Animation) -> void:
	var copy: Animation = anim.duplicate()
	copy.loop_mode = Animation.LOOP_LINEAR
	lib.add_animation(entry, copy)

func _process(delta: float) -> void:
	if _anim == null:
		return  # setup failed; the error is already on the console
	if not _initialized:
		_last_pos = global_position
		_initialized = true
		return
	var vel: Vector3 = (global_position - _last_pos) / maxf(delta, 0.0001)
	_last_pos = global_position

	var planar := Vector2(vel.x, vel.z)
	var speed := planar.length()
	if speed > RUN_SPEED:
		_fast_time += delta
	else:
		_fast_time = 0.0

	if speed < MIN_SPEED:
		_play("extra/idle")
		return

	# Turn the robot to face travel. atan2(x, z) aims the rig's +Z (its face) along
	# the direction of motion; lerp_angle takes the short way around.
	var target_yaw := atan2(planar.x, planar.y) + MODEL_YAW_OFFSET
	rotation.y = lerp_angle(rotation.y, target_yaw, clampf(TURN_SPEED * delta, 0.0, 1.0))

	_play("extra/run" if _fast_time >= RUN_HOLD else "extra/walk")

func _play(clip: String) -> void:
	if _anim.current_animation != clip:
		_anim.play(clip, 0.2)  # 0.2s crossfade
