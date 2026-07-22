extends RefCounted
class_name Visuals

## The look of the board. Tiles use pixel-art textures from res://art/tiles/ (viewed top-down,
## so the texture lands on the upward face). Want a different look? Swap the PNGs, or change a
## path below. The player stays a flat-shaded capsule so the actor reads clearly against the art.
##
## Everything is SHADING_MODE_UNSHADED (no lights/shadows = cheap + predictable) and
## TEXTURE_FILTER_NEAREST so the pixel art stays crisp instead of going blurry.
##
## IMPORTANT -- texture gotcha for 3D cubes:
## Godot's BoxMesh uses a cross-layout UV map (6 faces share one texture in a cross pattern).
## That means each face only gets ~1/4 of your image, and the visible face shows a weird crop.
## DO NOT use BoxMesh for textured blocks viewed from above. Instead, build cubes from 6
## individual QuadMesh faces (see make_box() / make_wall() below). Each face gets the FULL
## texture, so your sprites look correct from every angle -- especially important once the
## camera tilts into angled or perspective views.

const FLOOR_TEX := "res://art/tiles/floor_stone.png"
const PLATE_TEX := "res://art/tiles/floor_plate.png"           # goal: metal pressure plate (up)
const PLATE_PRESSED_TEX := "res://art/tiles/floor_plate_pressed.png"  # goal: plate pressed down
const DOOR_TEX := "res://art/tiles/door_wood.png"      # wooden door panel (sits on each door half)
const WALL_TEX := "res://art/tiles/wall_metal.png"
const CRATE_TEX := "res://art/tiles/crate_wood.png"

## 4-direction character sprite sheets (art/sprites/). Both have real alpha.
##   hero_green: 4 cols x 4 rows, rows = down/up/left/right walk (the default player)
##   hero_cape:  6 cols x 8 rows, 40x56 frames — extra sheet; map its rows when you use it
const PLAYER_SHEET := "res://art/sprites/hero_green.png"
const CAPE_SHEET := "res://art/sprites/hero_cape.png"

## Collision layers used by the physics system in real-time mode.
const LAYER_WORLD := 1   ## walls, static obstacles
const LAYER_ENTITY := 2  ## player, boxes

## Color "channels" shared by doors, plates, and keys. Channel 0 = NO color (neutral, white
## tint = texture unchanged). Channels 1+ tint the tile so matching door/plate/key read as a
## set. Add more colors here to add more channels.
const CHANNEL_COLORS := [
	Color(1, 1, 1),            # 0 — no color
	Color(0.40, 0.60, 1.0),    # 1 — blue
	Color(0.40, 0.85, 0.45),   # 2 — green
	Color(1.0, 0.42, 0.42),    # 3 — red
]

static func channel_color(channel: int) -> Color:
	if channel >= 0 and channel < CHANNEL_COLORS.size():
		return CHANNEL_COLORS[channel]
	return Color(1, 1, 1)

## albedo_color multiplies the texture, so `tint` recolors a tile (white = unchanged).
static func _tex_mat(path: String, transparent: bool = false, tint: Color = Color(1, 1, 1)) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = load(path)
	m.albedo_color = tint
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST  # crisp pixels
	if transparent:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m

static func _flat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m

## A flat ground tile (floor / plate / key / door). Lies on the board at y=0.
## size defaults to (1, 1) to fill one grid cell; pass a smaller value for overlays.
## Set transparent=true when the texture has an alpha channel and you need to see
## what's underneath (e.g. a pressure plate layered on top of the floor).
static func make_tile(texture_path: String, tile_size: Vector2 = Vector2(1, 1), transparent: bool = false, tint: Color = Color(1, 1, 1)) -> MeshInstance3D:
	var mesh := PlaneMesh.new()
	mesh.size = tile_size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _tex_mat(texture_path, transparent, tint)
	return mi

## A full-cell wall block (1x1x1). Returns a StaticBody3D with 6 textured QuadMesh faces
## plus a BoxShape3D collision shape so the player can't walk through it.
static func make_wall() -> StaticBody3D:
	var wall := StaticBody3D.new()
	wall.collision_layer = LAYER_WORLD

	var s := 0.5
	var face_size := Vector2(1.0, 1.0)
	var mat := _tex_mat(WALL_TEX)

	var faces := [
		{ pos = Vector3(0, s, 0),   rot = Vector3(-PI / 2, 0, 0) },    # top
		{ pos = Vector3(0, -s, 0),  rot = Vector3(PI / 2, 0, 0) },     # bottom
		{ pos = Vector3(0, 0, s),   rot = Vector3(0, 0, 0) },          # front
		{ pos = Vector3(0, 0, -s),  rot = Vector3(0, PI, 0) },          # back
		{ pos = Vector3(s, 0, 0),   rot = Vector3(0, PI / 2, 0) },      # right
		{ pos = Vector3(-s, 0, 0),  rot = Vector3(0, -PI / 2, 0) },     # left
	]

	for f in faces:
		var quad := QuadMesh.new()
		quad.size = face_size
		var mi := MeshInstance3D.new()
		mi.mesh = quad
		mi.position = f.pos
		mi.rotation = f.rot
		mi.material_override = mat
		wall.add_child(mi)

	# Collision so the player bumps into walls in real-time mode.
	var col := CollisionShape3D.new()
	col.shape = BoxShape3D.new()  # default 1x1x1, perfect for a cell
	wall.add_child(col)

	return wall

## A slightly-smaller cube (0.9 x 0.9 x 0.9) for pushable crates. Centered on the origin so the
## RigidBody3D crate rotates about its own center. Body + collision are set up in Level._spawn_box().
static func make_box() -> Node3D:
	var box := Node3D.new()
	var s := 0.45
	var face_size := Vector2(0.9, 0.9)
	var mat := _tex_mat(CRATE_TEX)

	var faces := [
		{ pos = Vector3(0, s, 0),   rot = Vector3(-PI / 2, 0, 0) },    # top
		{ pos = Vector3(0, -s, 0),  rot = Vector3(PI / 2, 0, 0) },     # bottom
		{ pos = Vector3(0, 0, s),   rot = Vector3(0, 0, 0) },          # front
		{ pos = Vector3(0, 0, -s),  rot = Vector3(0, PI, 0) },          # back
		{ pos = Vector3(s, 0, 0),   rot = Vector3(0, PI / 2, 0) },      # right
		{ pos = Vector3(-s, 0, 0),  rot = Vector3(0, -PI / 2, 0) },     # left
	]

	for f in faces:
		var quad := QuadMesh.new()
		quad.size = face_size
		var mi := MeshInstance3D.new()
		mi.mesh = quad
		mi.position = f.pos
		mi.rotation = f.rot
		mi.material_override = mat
		box.add_child(mi)

	return box

## A 3D door made of two sliding halves. Returns a Door node (extends Node3D).
## Each half is a thin box (0.5 x 1.0 x 0.3) textured with the door sprite on all
## six faces. A StaticBody3D child provides collision when the door is closed.
##
## The halves start at x = -0.25 (left) and x = +0.25 (right). Opening slides them
## to x = -0.5 and +0.5, leaving the center clear.
static func make_door(tint: Color = Color(1, 1, 1)) -> Door:
	const DoorScript := preload("res://scripts/door.gd")
	var d: Door = DoorScript.new()
	d.name = "Door"
	d.position = Vector3(0, 0.5, 0)  # sit on the floor, centered

	# Two identical thin, full-height slabs side by side. door.gd slides them apart on X.
	d.add_child(_door_half(-0.25, "LeftHalf", tint))   # left half, covers x = -0.5 .. 0
	d.add_child(_door_half(0.25, "RightHalf", tint))   # right half, covers x = 0 .. 0.5

	# Collision body (blocks passage when closed)
	var body := StaticBody3D.new()
	body.name = "Body"
	body.collision_layer = LAYER_WORLD
	var col := CollisionShape3D.new()
	col.name = "Collision"
	col.shape = BoxShape3D.new()  # 1x1x1, spans the full cell
	body.add_child(col)
	d.add_child(body)

	return d


## A single door half: a thin, full-height slab (0.5 wide x 1.0 tall x 0.3 deep) with the
## door texture on all 6 faces, positioned at `x_pos` in the parent's local space.
static func _door_half(x_pos: float, node_name: String, tint: Color = Color(1, 1, 1)) -> Node3D:
	var node := Node3D.new()
	node.name = node_name
	node.position = Vector3(x_pos, 0, 0)

	# Half-extents of the slab: 0.5 wide (X), 1.0 tall (Y), 0.3 deep (Z).
	var sx := 0.25   # half width
	var sy := 0.5    # half height
	var sz := 0.15   # half depth
	var mat := _tex_mat(DOOR_TEX, false, tint)

	# Each quad's size is the box's TWO in-plane dimensions for that face.
	var faces := [
		{ pos = Vector3(0,  sy, 0), rot = Vector3(-PI / 2, 0, 0), size = Vector2(2 * sx, 2 * sz) },  # top    (X x Z)
		{ pos = Vector3(0, -sy, 0), rot = Vector3(PI / 2, 0, 0),  size = Vector2(2 * sx, 2 * sz) },  # bottom (X x Z)
		{ pos = Vector3(0, 0,  sz), rot = Vector3(0, 0, 0),       size = Vector2(2 * sx, 2 * sy) },  # front  (X x Y)
		{ pos = Vector3(0, 0, -sz), rot = Vector3(0, PI, 0),      size = Vector2(2 * sx, 2 * sy) },  # back   (X x Y)
		{ pos = Vector3(sx, 0, 0),  rot = Vector3(0, PI / 2, 0),  size = Vector2(2 * sz, 2 * sy) },  # right  (Z x Y)
		{ pos = Vector3(-sx, 0, 0), rot = Vector3(0, -PI / 2, 0), size = Vector2(2 * sz, 2 * sy) },  # left   (Z x Y)
	]

	for f in faces:
		var quad := QuadMesh.new()
		quad.size = f.size
		var mi := MeshInstance3D.new()
		mi.mesh = quad
		mi.position = f.pos
		mi.rotation = f.rot
		mi.material_override = mat
		node.add_child(mi)

	return node


## Player visual: a flat-shaded blue capsule so the actor reads clearly.
## Visual only -- collision shape is added by Level._spawn().
## The player is a 2D animated sprite (see make_sprite_character). Want a different look?
## Point PLAYER_SHEET at your own 4-direction sheet and adjust the grid/rows here.
static func make_player() -> Node3D:
	return make_sprite_character(PLAYER_SHEET, 4, 4, {down = 0, up = 1, left = 2, right = 3})

## Build a SpriteCharacter (AnimatedSprite3D) from a 4-direction walk sheet.
##   columns/rows: the sheet grid. row_map: which ROW holds each direction's walk cycle.
##   world_height: how tall the character stands in world units (a cell is 1.0).
## The sprite billboards toward the camera, keeps crisp pixels, and picks walk_down/up/left/
## right on its own by watching its motion (scripts/sprite_character.gd) — works on anything.
static func make_sprite_character(sheet_path: String, columns: int, rows: int, row_map: Dictionary, fps: float = 8.0, world_height: float = 0.9) -> AnimatedSprite3D:
	var tex: Texture2D = load(sheet_path)
	var fw: int = tex.get_width() / columns
	var fh: int = tex.get_height() / rows
	var frames := SpriteFrames.new()
	for dir in row_map:
		var anim: String = "walk_" + dir  # explicit type: dir is a Variant dictionary key
		frames.add_animation(anim)
		frames.set_animation_speed(anim, fps)
		frames.set_animation_loop(anim, true)
		for c in columns:
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(c * fw, row_map[dir] * fh, fw, fh)
			frames.add_frame(anim, at)
	var s := AnimatedSprite3D.new()
	s.set_script(load("res://scripts/sprite_character.gd"))
	s.sprite_frames = frames
	s.animation = "walk_down"
	s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	s.pixel_size = world_height / fh
	s.position.y = world_height * 0.5
	return s

## Temporary enemy visual: a red flat-shaded capsule. Stand-in until a rigged model lands --
## swapping in a generated .glb here is a one-function change (see the chasing-enemies design).
static func make_enemy() -> MeshInstance3D:
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.32
	mesh.height = 1.0
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position.y = 0.5
	mi.material_override = _flat(Color(0.90, 0.20, 0.20))
	return mi

## A floating 3D collectible star (real geometry — no sprite, no transparency). It spins and
## bobs via pickup.gd. Per-face gold shades give it a 3D read even though the scene is unlit.
static func make_star() -> Node3D:
	var pivot := Node3D.new()
	pivot.name = "Star"
	pivot.set_script(load("res://scripts/pickup.gd"))

	var mi := MeshInstance3D.new()
	mi.mesh = _star_mesh(0.34, 0.15, 0.12)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true   # the per-face gold shades stand in for lighting
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	pivot.add_child(mi)
	return pivot

## Extruded 5-point star, laid flat (points up, faces +Y), built with SurfaceTool.
## Vertex colors shade top/sides/bottom differently so the form reads without lights.
static func _star_mesh(outer_r: float, inner_r: float, thickness: float) -> ArrayMesh:
	var top_col := Color(1.0, 0.85, 0.30)
	var side_col := Color(0.85, 0.66, 0.20)
	var bot_col := Color(0.65, 0.50, 0.14)
	var t := thickness * 0.5

	var pts: Array = []
	for i in 10:
		var ang := PI / 2.0 + float(i) * PI / 5.0   # start at the top point
		var r: float = outer_r if i % 2 == 0 else inner_r
		pts.append(Vector3(cos(ang) * r, 0.0, -sin(ang) * r))

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Top face — fan from the center point.
	st.set_color(top_col)
	for i in pts.size():
		st.add_vertex(Vector3(0, t, 0))
		st.add_vertex(pts[i] + Vector3(0, t, 0))
		st.add_vertex(pts[(i + 1) % pts.size()] + Vector3(0, t, 0))

	# Bottom face — fan, reversed winding.
	st.set_color(bot_col)
	for i in pts.size():
		st.add_vertex(Vector3(0, -t, 0))
		st.add_vertex(pts[(i + 1) % pts.size()] + Vector3(0, -t, 0))
		st.add_vertex(pts[i] + Vector3(0, -t, 0))

	# Side walls — a quad per edge.
	st.set_color(side_col)
	for i in pts.size():
		var i2 := (i + 1) % pts.size()
		var ta: Vector3 = pts[i] + Vector3(0, t, 0)
		var tb: Vector3 = pts[i2] + Vector3(0, t, 0)
		var ba: Vector3 = pts[i] + Vector3(0, -t, 0)
		var bb: Vector3 = pts[i2] + Vector3(0, -t, 0)
		st.add_vertex(ta); st.add_vertex(ba); st.add_vertex(tb)
		st.add_vertex(tb); st.add_vertex(ba); st.add_vertex(bb)

	st.generate_normals()
	return st.commit()

## A floating 3D key — the generated model in art/models/key.glb. Channel 0 keeps the model's
## own gold material; colored channels tint the whole key so they read at a glance. Spins +
## bobs via pickup.gd. SCALE / TILT are tunable — adjust if it's too big/small or sits wrong.
const KEY_MODEL := "res://art/models/key.glb"
const KEY_SCALE := 0.45      ## the model imports ~1 unit tall; shrink to fit a cell
const KEY_TILT_DEG := 0.0    ## rotate about X if you'd rather lay the key flat (e.g. -90)

static func make_key(color: Color) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = "Key"
	pivot.set_script(load("res://scripts/pickup.gd"))

	var model: Node3D = load(KEY_MODEL).instantiate()
	model.scale = Vector3.ONE * KEY_SCALE
	model.rotation.x = deg_to_rad(KEY_TILT_DEG)
	# Channel 0 (white) keeps the model's gold look; colored channels tint the whole key.
	if not color.is_equal_approx(Color(1, 1, 1)):
		_tint_meshes(model, _flat(color))
	pivot.add_child(model)
	return pivot

## Apply a material override to every MeshInstance3D under `node` (recursive).
static func _tint_meshes(node: Node, mat: Material) -> void:
	if node is MeshInstance3D:
		node.material_override = mat
	for child in node.get_children():
		_tint_meshes(child, mat)
