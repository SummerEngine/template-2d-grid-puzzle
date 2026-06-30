extends Node3D
class_name Level

## Builds the world from an ASCII map + a legend. EDITING THE MAP IS EDITING THE GAME.
## Every cell gets a ground tile (textured pixel-art); walls add a block on top; the player
## and crates are GridEntity nodes tracked in `_entities` / `_movers`.
##
## COLOR CHANNELS: doors, pressure plates, and keys each belong to a `channel` (a color).
## Channel 0 = no color (neutral). A door of channel C is OPEN while any plate of C is pressed,
## or PERMANENTLY once a key of C is collected. Colors live in Visuals.CHANNEL_COLORS.
##
## WIN: collect every star (`*`) to win. A level with no star falls back to the legacy
## sokoban rule (all channel-0 plates covered by a crate).

signal won  ## emitted once, the moment the win condition is first met

const LEGEND := {
	"#": {type = "wall"},
	"@": {type = "player"},
	"$": {type = "box"},
	"*": {type = "star"},   # collect to win
	# channel 0 — no color:
	".": {type = "plate", channel = 0},   # also the sokoban win goal
	"K": {type = "key", channel = 0},
	"D": {type = "door", channel = 0},
	# channel 1 — blue:
	"b": {type = "plate", channel = 1},
	"B": {type = "key", channel = 1},
	"1": {type = "door", channel = 1},
	# channel 2 — green:
	"g": {type = "plate", channel = 2},
	"G": {type = "key", channel = 2},
	"2": {type = "door", channel = 2},
	# channel 3 — red:
	"r": {type = "plate", channel = 3},
	"R": {type = "key", channel = 3},
	"3": {type = "door", channel = 3},
	# anything else (space, etc.) = plain floor
}

const PlayerScript := preload("res://scripts/player.gd")
const BoxScript := preload("res://scripts/box.gd")

var grid: Grid
var player: GridEntity

var _walls := {}        # Vector2i -> true (walls + closed doors)
var _doors := {}        # Vector2i -> Door
var _goals := []        # Array[Vector2i] (channel-0 plates double as win goals)
var _entities := {}     # Vector2i -> GridEntity (turn-based grid occupancy)
var _movers := []       # Array[GridEntity] (player + boxes; live occupancy in both modes)

# --- color-channel state ---
var _plates := []          # Array of { cell, channel, vis, pressed }
var _keys := {}            # Vector2i -> { channel, vis }
var _channel_doors := []   # Array of { channel, door }
var _key_collected := {}   # channel -> true (latched open forever)

# --- win state ---
var _stars := {}           # Vector2i -> star vis (uncollected)
var _star_total := 0       # stars the level started with
var _stars_collected := 0
var _won := false

func build(map_lines: Array, grid_ref: Grid, tick_manager: TickManager) -> void:
	grid = grid_ref
	for y in map_lines.size():
		var line: String = map_lines[y]
		for x in line.length():
			var cell := Vector2i(x, y)
			var entry: Dictionary = LEGEND.get(line[x], {type = "floor"})
			var channel: int = entry.get("channel", 0)
			match entry.get("type", "floor"):
				"wall":
					_add_wall(cell)
				"plate":
					_add_tile(cell, Visuals.FLOOR_TEX)
					_add_plate(cell, channel)
				"key":
					_add_tile(cell, Visuals.FLOOR_TEX)
					_add_key(cell, channel)
				"star":
					_add_tile(cell, Visuals.FLOOR_TEX)
					_add_star(cell)
				"door":
					_add_door(cell, channel, map_lines)
				"player":
					_add_tile(cell, Visuals.FLOOR_TEX)
					_spawn(PlayerScript, "player", cell, Visuals.make_player(), tick_manager)
				"box":
					_add_tile(cell, Visuals.FLOOR_TEX)
					_spawn(BoxScript, "box", cell, Visuals.make_box(), tick_manager)
				_:
					_add_tile(cell, Visuals.FLOOR_TEX)

# --- color channels (evaluated every frame; cheap for a handful of tiles) ---

func _process(_delta: float) -> void:
	if grid == null:
		return
	_update_channels()

func _update_channels() -> void:
	# 1. Which cells currently have a mover (player or crate) on them?
	var occupied := {}
	for e in _movers:
		if is_instance_valid(e):
			occupied[grid.world_to_cell(e.global_position)] = true

	# 2. Player pickups: a key (latches its channel open) or a star (counts toward the win).
	if player != null and is_instance_valid(player):
		var pcell: Vector2i = grid.world_to_cell(player.global_position)
		if _keys.has(pcell):
			var info: Dictionary = _keys[pcell]
			_key_collected[info.channel] = true
			info.vis.queue_free()
			_keys.erase(pcell)
		if _stars.has(pcell):
			_stars[pcell].queue_free()
			_stars.erase(pcell)
			_stars_collected += 1

	# 3. Which channels are pressed right now? (any mover sitting on a plate of that channel)
	var pressed := {}
	for p in _plates:
		var down: bool = occupied.has(p.cell)
		if down:
			pressed[p.channel] = true
		if down != p.pressed:
			p.pressed = down
			_set_plate_texture(p)

	# 4. Open/close every door: open if its key is collected OR its channel is pressed.
	for d in _channel_doors:
		if _key_collected.get(d.channel, false) or pressed.get(d.channel, false):
			d.door.open()
		else:
			d.door.close()

	# 5. Win the moment the condition is met (frame-based, so star pickup fires instantly).
	if not _won and is_won():
		_won = true
		won.emit()

func _set_plate_texture(p: Dictionary) -> void:
	var mat: StandardMaterial3D = p.vis.material_override
	mat.albedo_texture = load(Visuals.PLATE_PRESSED_TEX if p.pressed else Visuals.PLATE_TEX)

# --- movement (the one rule every game shares) ---

## Try to move `entity` one cell in `dir`. Handles walls, bounds, and pushing.
## Returns true if the entity actually moved.
func try_move(entity: GridEntity, dir: Vector2i) -> bool:
	var target: Vector2i = entity.grid_pos + dir
	if not grid.in_bounds(target) or _walls.has(target):
		return false
	var other: GridEntity = _entities.get(target)
	if other != null:
		if other.pushable:
			var beyond: Vector2i = target + dir
			if grid.in_bounds(beyond) and not _walls.has(beyond) and not _entities.has(beyond):
				_relocate(other, beyond)
			else:
				return false  # crate is jammed against something
		else:
			entity.on_bump(other)
			return false
	_relocate(entity, target)
	return true

func _relocate(entity: GridEntity, cell: Vector2i) -> void:
	_entities.erase(entity.grid_pos)
	entity.set_cell(cell)
	_entities[cell] = entity

func entity_at(cell: Vector2i) -> GridEntity:
	return _entities.get(cell)

func door_at(cell: Vector2i) -> Door:
	return _doors.get(cell)

# --- win condition ---
## Star levels win by collecting every star. Levels with no star fall back to the legacy
## sokoban rule (every channel-0 plate covered by a crate).
func is_won() -> bool:
	if _star_total > 0:
		return _stars_collected >= _star_total
	if _goals.is_empty():
		return false
	for g in _goals:
		var e: GridEntity = _entities.get(g)
		if e == null or not e.pushable:
			return false
	return true

# --- builders ---

func _add_tile(cell: Vector2i, texture_path: String) -> void:
	var t := Visuals.make_tile(texture_path)
	t.position = grid.cell_to_world(cell)
	add_child(t)

func _add_wall(cell: Vector2i) -> void:
	var m: StaticBody3D = Visuals.make_wall()
	# Offset y by 0.5 so the wall cube sits ON the floor, not half-buried.
	m.position = grid.cell_to_world(cell) + Vector3(0, 0.5, 0)
	add_child(m)
	_walls[cell] = true

func _add_plate(cell: Vector2i, channel: int) -> void:
	# A pressure plate, drawn as a small overlay on the floor, tinted by its channel color.
	var vis := Visuals.make_tile(Visuals.PLATE_TEX, Vector2(0.6, 0.6), true, Visuals.channel_color(channel))
	vis.position = grid.cell_to_world(cell) + Vector3(0, 0.01, 0)
	add_child(vis)
	_plates.append({cell = cell, channel = channel, vis = vis, pressed = false})
	if channel == 0:
		_goals.append(cell)  # channel-0 plates double as the sokoban win goal

func _add_key(cell: Vector2i, channel: int) -> void:
	var vis := Visuals.make_key(Visuals.channel_color(channel))
	vis.position = grid.cell_to_world(cell) + Vector3(0, 0.5, 0)  # float above the floor tile
	add_child(vis)
	_keys[cell] = {channel = channel, vis = vis}

func _add_star(cell: Vector2i) -> void:
	var s := Visuals.make_star()
	s.position = grid.cell_to_world(cell) + Vector3(0, 0.55, 0)  # float above the floor tile
	add_child(s)
	_stars[cell] = s
	_star_total += 1

func _add_door(cell: Vector2i, channel: int, map_lines: Array) -> void:
	_add_tile(cell, Visuals.FLOOR_TEX)  # floor under the door (visible when it opens)
	var d := Visuals.make_door(Visuals.channel_color(channel))
	# Raise half a cube so the slab sits ON the floor instead of half-buried in it.
	d.position = grid.cell_to_world(cell) + Vector3(0, 0.5, 0)
	# Auto-orient: a door set into a VERTICAL wall (walls above & below) turns 90 degrees so you
	# pass through it left<->right. Otherwise it keeps the default up<->down passage.
	var vertical_wall := _is_wall_char(map_lines, cell.x, cell.y - 1) and _is_wall_char(map_lines, cell.x, cell.y + 1)
	var horizontal_wall := _is_wall_char(map_lines, cell.x - 1, cell.y) and _is_wall_char(map_lines, cell.x + 1, cell.y)
	if vertical_wall and not horizontal_wall:
		d.rotation.y = deg_to_rad(90)
	add_child(d)
	_walls[cell] = true  # blocks movement when closed
	_doors[cell] = d
	_channel_doors.append({channel = channel, door = d})
	# Door open/close keeps the wall flag in sync so turn-based movement respects it.
	d.opened.connect(func(): _walls.erase(cell))
	d.closed.connect(func(): _walls[cell] = true)

## True if map_lines has a wall ('#') at (x, y); false if out of bounds or not a wall.
func _is_wall_char(map_lines: Array, x: int, y: int) -> bool:
	if y < 0 or y >= map_lines.size():
		return false
	var line: String = map_lines[y]
	if x < 0 or x >= line.length():
		return false
	return line[x] == "#"

func _spawn(script: GDScript, kind: String, cell: Vector2i, mesh: Node3D, tick_manager: TickManager) -> void:
	var e: GridEntity = script.new()
	e.kind = kind
	add_child(e)
	e.add_child(mesh)

	# Collision shape so the entity blocks movement in real-time mode.
	var col := CollisionShape3D.new()
	if kind == "player":
		var cap := CapsuleShape3D.new()
		cap.radius = 0.32
		cap.height = 1.0
		col.shape = cap
		col.position.y = 0.5
		e.collision_layer = Visuals.LAYER_ENTITY
		e.collision_mask = Visuals.LAYER_WORLD | Visuals.LAYER_ENTITY
	else:
		var box := BoxShape3D.new()
		box.size = Vector3(0.9, 0.9, 0.9)   # match the visual
		col.shape = box
		col.position.y = 0.5                # center in the cube
		e.collision_layer = Visuals.LAYER_ENTITY
		e.collision_mask = Visuals.LAYER_WORLD | Visuals.LAYER_ENTITY  # collide with walls + other entities
	e.add_child(col)

	e.setup(self, cell)
	_entities[cell] = e
	_movers.append(e)
	tick_manager.tick.connect(e.on_tick)
	if kind == "player":
		player = e
