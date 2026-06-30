# GridKit — Chasing Enemies + Lose Condition

**Date:** 2026-06-30
**Status:** Approved design, ready for implementation plan

## Goal

Add enemies to GridKit that walk toward the player and end the level when they
catch you. Enemies work in **both** movement modes (turn-based grid + real-time)
with no per-mode special-casing, exactly like every other entity. Enemy levels
are larger and have interior walls the player uses as cover. The enemy is an
**animated rigged 3D model**, not a primitive.

This is a hackathon template, so every addition must follow the existing patterns
(`GridEntity` + `on_tick()` + `TickManager`, `Visuals` factory, ASCII-map levels)
and stay forkable and readable.

## Decisions (locked)

- **Model source:** generate a rigged enemy now via the character-model pipeline
  (Meshy: T-pose → auto-rig → walk loop), wired through `Visuals.make_enemy()`.
- **Chase logic:** greedy step toward the player; **walls are cover** (a blocked
  enemy stays put — no pathfinding around walls). This is what makes walls "help
  the player".
- **Lose outcome:** a "Caught!" screen mirroring Level Complete, with **Retry**
  (restart current level) and **Menu**.
- **Win on enemy levels:** unchanged — collect the star(s) (`*`) while dodging the
  enemy. No new win logic.

## Components

### 1. `scripts/enemy.gd` — `extends GridEntity`

Mirrors the player's dual structure (`on_tick` for turn-based, `_physics_process`
for real-time, gated by `_use_physics`), so it works in both modes for free.

- `_init()`: `pushable = false`, `kind = "enemy"`.
- **Turn-based `on_tick()`:** greedy single step toward the player.
  - Compute delta `d = player.grid_pos - grid_pos`.
  - Try the axis with the larger `abs` component first via `level.try_move(self, step)`.
  - If that move returns false (wall / closed door / occupied), try the other axis.
  - If both are blocked, stay put (this is the "cover" behavior).
  - No diagonals.
  - Respect `ticks_per_move`: only move on every Nth tick (internal counter).
  - After moving, call `_check_caught()`.
- **Real-time `_physics_process(delta)`:** if `_use_physics`, set
  `velocity = (toward player on XZ).normalized() * MOVE_SPEED`, `move_and_slide()`.
  Walls block it via physics. Then `_check_caught()`.
- **Tunables** (top of file, no clamps/floors per house rule):
  - `MOVE_SPEED := 3.5` (real-time; slower than player's 5.0 so the player can
    outrun it in the open and walls/corners matter).
  - `ticks_per_move := 1` (turn-based; 1 = moves every player turn, 2 = every
    other turn = slower/easier).
  - `CATCH_RADIUS := 0.6` (real-time world-distance catch threshold).
- **`_check_caught()`:**
  - Turn-based: caught when Manhattan distance to the player ≤ 1 (it reached an
    adjacent cell and grabs you).
  - Real-time: caught when world distance to the player < `CATCH_RADIUS`.
  - On catch, call `level.player_caught()`.
- Needs a reference to the player; read `level.player` (already exposed on `Level`).

### 2. Lose plumbing on `Level` (`scripts/level.gd`)

- Add `signal lost` (symmetric with the existing `signal won`).
- Add `var _lost := false` guard.
- Add `func player_caught() -> void:` that emits `lost` exactly once (guarded),
  the same shape as the win guard in `_update_channels()`.
- `LEGEND`: add `"E": {type = "enemy"}`.
- `build()`: add a `"enemy"` match arm that lays a floor tile and spawns the enemy
  via `_spawn(EnemyScript, "enemy", cell, Visuals.make_enemy(), tick_manager)`.
- `_spawn()`: the enemy uses the same capsule collision setup as the player
  (collision so it blocks cells in real-time mode); generalize the existing
  `if kind == "player"` branch to also cover `"enemy"` (capsule + entity layer),
  leaving the box branch unchanged.
- `const EnemyScript := preload("res://scripts/enemy.gd")`.

### 3. `scripts/game_manager.gd` — lose flow

- Connect `level.lost` to a new `_on_lost()` (alongside `level.won.connect(_on_won)`).
- `_on_lost()`: guard against double-fire, set a "Caught!" status, short
  `await` beat (~0.8s like `_on_won`), then `GameFlow.goto("level_failed")`.
- Block pause/win input once lost (extend the existing `_won` guard to
  `_won or _lost` where appropriate).

### 4. "Caught" screen — `screens/level_failed.tscn` + `scripts/ui/level_failed.gd`

- Cloned from `level_complete` (same `screen.gd` / `menu_button.gd` conventions).
- Title: "Caught!".
- **Retry** button: `LevelManager.start(LevelManager.current_index)` then
  `GameFlow.goto("game")`.
- **Menu** button: `GameFlow.goto("main_menu")`.
- Register the `"level_failed"` route wherever `game_flow.gd` maps the other
  screens (confirm the exact registration pattern when implementing).

### 5. New levels (`scripts/autoload/level_manager.gd`)

- Add 2 new large levels (~11×9 or bigger) to `LEVELS`, each with:
  - A border plus **interior `#` walls** forming corridors / pillars / cover.
  - A `*` star as the objective (existing win logic).
  - 1–2 `E` enemy spawns placed away from the player start.
- Keep all rows the same length (ragged rows render jagged — known GridKit gotcha).
- Update the legend comment block at the top of the file to document `E`.
- Existing small puzzle levels stay enemy-free.

### 6. Animated model — `Visuals.make_enemy()`

- Generate a rigged enemy via the **character-model** skill (Meshy T-pose →
  auto-rig → walk loop). Gate the un-rigged preview past the user; don't drive
  the engine — hand the user checkpoints to test.
- `make_enemy()` instantiates the generated glb, scales it to ~1 cell, finds its
  `AnimationPlayer`, and plays the **walk** loop. The enemy `GridEntity` keeps its
  capsule collision; the glb is its visual child (same split as `make_player`).
- Wire gameplay against `make_enemy()` from the start with a temporary
  capsule/primitive stand-in so the feature is playable and testable before the
  model lands; swapping in the rigged glb is then a one-function change.

## Build order

1. `enemy.gd` + `Level` lose plumbing + legend/spawn, with a **temporary primitive
   visual** in `make_enemy()`.
2. `game_manager` lose flow + `level_failed` screen + route.
3. New large enemy levels.
4. Playtest both modes (turn-based + real-time): chase works, walls block the
   enemy, catch → Caught screen → Retry restarts.
5. Generate the rigged model via character-model; swap it into `make_enemy()`;
   re-verify the walk anim plays and scale/orientation read correctly.

## Out of scope (YAGNI)

- Pathfinding around walls (explicitly chose greedy/cover).
- Enemy health, attacks, or projectiles (touch = caught).
- Multiple enemy types or per-enemy AI variants.
- Difficulty scaling beyond the existing `MOVE_SPEED` / `ticks_per_move` tunables.

## Risks / notes

- **Catch fairness:** turn-based "adjacent = caught" plus equal step cadence
  (`ticks_per_move = 1`) means open ground is deadly; the design leans on walls
  and `MOVE_SPEED 3.5` (real-time) to keep levels winnable. Tune during playtest.
- **Meshy gotchas** (from prior sessions): rigs may import at small armature
  scale, motion clips are named via a curated library, and instanced-glb overrides
  can be finicky — defer those specifics to the character-model / generate-motion
  skills at implementation time.
- **MCP/engine:** asset generation acts on whichever project the running engine
  has open; the user must have gridkit open. Don't launch or drive the engine —
  ask the user to test.
