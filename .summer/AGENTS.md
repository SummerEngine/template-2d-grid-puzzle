# Agent Notes — GridKit template

This is a **hackathon starter template**, not a finished game. Teams fork it and build their
own grid-based topdown game on top in ~12 hours. Keep changes small, legible, and beginner-
friendly — clarity beats cleverness here.

Architecture (see README.md for the full table):
- `TickManager` is the world heartbeat; everything that moves listens to its `tick` signal.
- `tick_mode_realtime` flips between real-time (timer) and turn-based (keypress) — entity code
  is identical in both.
- Input is decoupled via actions (`move_*`, `action`). `input_router.gd` (autoload) bridges
  keyboard + Arduino serial into those actions. Don't read the keyboard directly elsewhere.
- `visuals.gd` is the ONLY art layer — unshaded textured tiles + primitives, no lights.
  Tiles use pixel-art textures in `art/tiles/`. The PLAYER is a 2D animated sprite:
  `Visuals.make_sprite_character(sheet, cols, rows, row_map)` slices a 4-direction walk sheet
  (art/sprites/) into an AnimatedSprite3D (billboard, NEAREST). `sprite_character.gd` picks
  walk_down/up/left/right by watching its own motion — no coupling to entity code, works in
  both movement modes on any mover. Enemy is still a red capsule. Collectibles
  spin/bob via the shared `pickup.gd`. The STAR is procedural geometry (`make_star`); the KEY
  is a generated GLB model (`art/models/key.glb`, `make_key`) — channel 0 keeps its gold
  material, colored channels get a flat tint via `_tint_meshes`; scale/tilt are consts in
  `make_key`. (The flat `floor_star`/`floor_key` PNGs are now unused.)
  **BoxMesh UV gotcha:** Godot's BoxMesh uses a cross-layout UV map where each face only
  gets a fraction of the texture. When viewed from above (or at an angle), this produces a
  weird crop instead of the full sprite. The fix is in `make_box()` and `make_wall()`:
  build cubes from 6 individual `QuadMesh` faces so every side gets the full texture.
  Any new 3D textured block added to this template MUST follow the same pattern.
- Movement has two modes (toggled in Settings or via `LevelManager.move_mode`):
  - **Turn-based**: grid ticks, `player.on_tick()` calls `level.try_move()`. One key = one cell.
  - **Real-time**: `CharacterBody3D.move_and_slide()` in `player._physics_process()`.
    Walls are `StaticBody3D`. Crates are `RigidBody3D` (`box.gd`, NOT a GridEntity — it
    duck-types the grid interface): dynamic in real-time (linear/angular damping = friction,
    off-center player impulses spin them), frozen/kinematic + grid-controlled in turn-based.
    `GameManager._apply_move_mode()` calls `set_physics_active()` on every mover to flip modes.
  - Collision layers: `LAYER_WORLD=1` (walls), `LAYER_ENTITY=2` (player + boxes).
- WALLS (`#`) are full-cell cubes and can be placed ANYWHERE in a map (interior too, not just
  the border). DOORS auto-orient in `Level._add_door`: set into a vertical wall (walls above &
  below) they rotate 90° for a left<->right passage; otherwise default up<->down.
- COLOR CHANNELS: doors/plates/keys carry a `channel` int. `LEGEND` maps map-chars →
  `{type, channel}`. Channel 0 = no color. A door opens while a plate of its channel is pressed,
  or forever once a key of its channel is collected. Driven by `Level._update_channels()` every
  frame using world positions (works in both movement modes). Colors: `Visuals.CHANNEL_COLORS`;
  tiles are tinted via `albedo_color` on the texture material.
- WIN: `Level` emits a `won` signal (GameManager listens). Default win = collect every `*`
  star (`Level._add_star` / `_stars`); levels with no star fall back to crates-on-`.`-plates.
  Checked each frame in `_update_channels`, so a pickup ends the level instantly.
- ENEMIES (`E`, `enemy.gd` extends GridEntity): greedily step toward `level.player` (walls are
  cover -- no pathfinding). Catch = adjacent (turn-based) or within CATCH_RADIUS (real-time) ->
  `Level.player_caught()` -> `Level` emits `lost` -> GameManager -> `level_failed` ("Caught!"
  screen, Retry). Enemy visual is a temporary red capsule (`Visuals.make_enemy`); a rigged glb
  swaps in there later (see docs/superpowers/specs chasing-enemies design).

Constraints to respect:
- Stay on the Compatibility renderer and unshaded materials (low-power "handheld" budget).
- Keep textures NEAREST-filtered (crisp pixel art) and tiles edge-to-edge.
- Don't over-engineer. A 12h team should read the whole template in half an hour.
