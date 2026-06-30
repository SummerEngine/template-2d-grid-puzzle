extends Node

## The ordered list of levels + where the player is in it.
## ADD A LEVEL = add an entry below. Each level is a name + an ASCII map + optional "realtime".
## Map legend (see level.gd LEGEND):
##   # wall   @ player   $ crate   * star (collect to WIN)   . plate   K key   D door   space = floor
## Color channels (a door opens while its plate is pressed, or forever once its key is taken):
##   blue: b plate / B key / 1 door     green: g / G / 2     red: r / R / 3

## Turn the Level Select screen on/off here (your "disable if unwanted" switch).
## The Settings screen can also flip this at runtime.
var level_select_enabled := true

## Camera view: 0=top-down, 1=angled ortho, 2=angled perspective.
## Persisted on LevelManager so Settings and the game scene agree on it.
var cam_view := 1

## Movement mode (overrides the per-level \"realtime\" flag):
## 0 = turn-based (one keypress = one grid move)
## 1 = real-time (timer-based ticks, hold to move freely)
var move_mode := 0

const LEVELS := [
	{
		# Walk onto the star to win — the simplest objective.
		"name": "Warmup",
		"realtime": false,
		"map": [
			"#######",
			"#     #",
			"# @ * #",
			"#     #",
			"#######",
		],
	},
	{
		"name": "Two Crates",
		"realtime": false,
		"map": [
			"#########",
			"#       #",
			"#  @ $ .#",
			"#       #",
			"#  $ .  #",
			"#       #",
			"#########",
		],
	},
	{
		"name": "Corner",
		"realtime": false,
		"map": [
			"########",
			"#  .   #",
			"#  $   #",
			"#  @   #",
			"#      #",
			"########",
		],
	},
	{
		# Channel 0 (no color): grab the key (K) and the door (D) opens forever.
		# The goal plate (.) also opens channel-0 doors while a crate sits on it.
		"name": "Vault",
		"realtime": false,
		"map": [
			"#######",
			"#@  K #",
			"#  $  #",
			"#  .  #",
			"###D###",
		],
	},
	{
		# Interior walls + a ROTATED door. Grab the GREEN key (G); the GREEN door (2) is set
		# into a vertical wall, so it auto-turns to a LEFT<->RIGHT passage. Then reach the star.
		# (Walls `#` can go anywhere inside a map, not just the border.)
		"name": "Color Lock",
		"realtime": false,
		"map": [
			"#########",
			"#@ G#  *#",
			"#   2   #",
			"#   #   #",
			"#########",
		],
	},
]

var current_index := 0
var _completed := {}   # index -> true

func count() -> int:
	return LEVELS.size()

func start(index: int) -> void:
	current_index = clampi(index, 0, LEVELS.size() - 1)

func current() -> Dictionary:
	return LEVELS[current_index]

func level_name(index: int) -> String:
	return LEVELS[index].get("name", "Level %d" % (index + 1))

func has_next() -> bool:
	return current_index < LEVELS.size() - 1

func advance() -> bool:
	if has_next():
		current_index += 1
		return true
	return false

func mark_complete(index: int) -> void:
	_completed[index] = true

func is_complete(index: int) -> bool:
	return _completed.get(index, false)

func all_complete() -> bool:
	return _completed.size() >= LEVELS.size()
