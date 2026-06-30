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
  Tiles use pixel-art textures in `art/tiles/`; the player is a flat capsule. Collectibles
  (star, key) are floating 3D meshes (`Visuals.make_star` / `make_key`) spun by the shared
  `pickup.gd`; the key is tinted by its channel color. (The flat `floor_star/floor_key` PNGs
  are now unused.)
  **BoxMesh UV gotcha:** Godot's BoxMesh uses a cross-layout UV map where each face only
  gets a fraction of the texture. When viewed from above (or at an angle), this produces a
  weird crop instead of the full sprite. The fix is in `make_box()` and `make_wall()`:
  build cubes from 6 individual `QuadMesh` faces so every side gets the full texture.
  Any new 3D textured block added to this template MUST follow the same pattern.
- Movement has two modes (toggled in Settings or via `LevelManager.move_mode`):
  - **Turn-based**: grid ticks, `player.on_tick()` calls `level.try_move()`. One key = one cell.
  - **Real-time**: `CharacterBody3D.move_and_slide()` in `player._physics_process()`.
    Walls are `StaticBody3D` nodes with collision; boxes are `CharacterBody3D` with
    collision shapes that act as obstacles. `GameManager._apply_move_mode()` sets
    `_use_physics` on every `GridEntity` to flip between the two paths.
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

Constraints to respect:
- Stay on the Compatibility renderer and unshaded materials (low-power "handheld" budget).
- Keep textures NEAREST-filtered (crisp pixel art) and tiles edge-to-edge.
- Don't over-engineer. A 12h team should read the whole template in half an hour.
