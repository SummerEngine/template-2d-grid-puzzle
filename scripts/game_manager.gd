extends Node3D

## Runs ONE level -- whichever LevelManager currently points at. The level list lives in
## scripts/autoload/level_manager.gd; this just plays the current entry, handles pause
## (Esc), and on a win advances the flow to the Level Complete screen.
##
## Camera: press Tab to cycle between top-down ortho, angled ortho, and angled perspective.
## The setting is persisted on LevelManager.cam_view and the Settings screen also controls it.
##
## Movement: real-time mode uses CharacterBody3D.move_and_slide() with real collision
## against walls and boxes. Turn-based mode uses the grid tick system.

const PAUSE_SCENE := preload("res://screens/pause_menu.tscn")
const CAM_LABELS := ["top-down", "angled", "perspective"]
const MOVE_LABELS := ["turn-based", "real-time"]

@onready var tick_manager: TickManager = $TickManager
@onready var level: Level = $Level
@onready var camera: Camera3D = $Camera3D
@onready var status_label: Label = $UI/Status

var _won := false
var _pause_instance: Node = null
var _cam_center: Vector3
var _cam_grid_size: float
var _status_text: String = ""

func _ready() -> void:
	var data: Dictionary = LevelManager.current()
	var map: Array = data["map"]

	var grid := Grid.new(_map_width(map), map.size(), 1.0)
	level.build(map, grid, tick_manager)
	_cam_center = grid.center_world()
	_cam_grid_size = max(grid.width, grid.height)
	_apply_camera()

	tick_manager.interval = 0.14
	level.won.connect(_on_won)   # Level decides when the win condition is met
	_apply_move_mode()

	_status_text = data.get("name", "Level")
	_refresh_status()

func _unhandled_input(event: InputEvent) -> void:
	if _won:
		return
	if event.is_action_pressed("ui_cancel"):
		_open_pause()
	elif event.is_action_pressed("camera_toggle"):
		LevelManager.cam_view = wrapi(LevelManager.cam_view + 1, 0, 3)
		_apply_camera()

func _open_pause() -> void:
	if _pause_instance != null and is_instance_valid(_pause_instance):
		return  # already open; the pause menu closes itself
	_pause_instance = PAUSE_SCENE.instantiate()
	add_child(_pause_instance)

func _on_won() -> void:
	if _won:
		return
	_won = true
	LevelManager.mark_complete(LevelManager.current_index)
	_status_text = "Solved!"
	_refresh_status()
	await get_tree().create_timer(0.8).timeout
	GameFlow.goto("level_complete")

func _map_width(map: Array) -> int:
	var w := 0
	for line in map:
		w = max(w, line.length())
	return w

func _apply_camera() -> void:
	match LevelManager.cam_view:
		0:  # top-down
			camera.projection = Camera3D.PROJECTION_ORTHOGONAL
			camera.size = _cam_grid_size * 0.9
			camera.position = _cam_center + Vector3(0, 20, 0)
			camera.look_at(_cam_center, Vector3(0, 0, -1))
		1:  # angled ortho
			camera.projection = Camera3D.PROJECTION_ORTHOGONAL
			camera.size = _cam_grid_size * 0.9
			camera.position = _cam_center + Vector3(0, 14, 7)
			camera.look_at(_cam_center)
		2:  # angled perspective
			camera.projection = Camera3D.PROJECTION_PERSPECTIVE
			camera.fov = 40.0
			camera.position = _cam_center + Vector3(0, 8, 4)
			camera.look_at(_cam_center)

	_refresh_status()

func _apply_move_mode() -> void:
	var realtime := LevelManager.move_mode == 1
	tick_manager.mode = TickManager.Mode.REALTIME if realtime else TickManager.Mode.TURN_BASED

	# Toggle physics on every entity. In real-time mode the player uses
	# CharacterBody3D.move_and_slide(); boxes become static obstacles via
	# their collision shapes. In turn-based mode the grid-lerp takes over.
	for child in level.get_children():
		if child is GridEntity:
			child._use_physics = realtime

func _refresh_status() -> void:
	status_label.text = "%s  [Tab: %s | %s]" % [
		_status_text, CAM_LABELS[LevelManager.cam_view], MOVE_LABELS[LevelManager.move_mode]
	]
