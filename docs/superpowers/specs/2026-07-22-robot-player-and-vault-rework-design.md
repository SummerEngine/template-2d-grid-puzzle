# Robot Player Toggle + Vault Rework — Design

Date: 2026-07-22
Status: approved (chat), implemented same day

## Goals

1. Give the player a 3D look: the **standard Summer robot** (from the dwarf_gym
   asset set), switchable against the existing 2D sprite via Dev Settings.
   Default = 3D robot.
2. Rework the **Vault** level: it previously had no star, its key/door were dead
   props, and it was solvable in three pushes. Give it a real star locked behind
   the door, and move it earlier in the campaign (it is the gentlest lock puzzle).

## 1. Assets

`art/models/robot/robot_idle.glb`, `robot_walk.glb`, `robot_run.glb` (~14 MB each,
textures embedded — verified in the GLB headers, so no sidecar PNGs). Copied from
`dwarf_gym/characters/robot/`. Loaded by path from scripts (like `key.glb`), so no
scene-uid dance; Godot imports them on next project open.

Clip set is deliberately minimal: a grid player only ever stands, walks, or runs.
The full standard set (attack/dead/fall/idle_alt) stays in dwarf_gym.

## 2. Setting

`LevelManager.player_visual` (`PLAYER_ROBOT = 0` default, `PLAYER_SPRITE = 1`),
next to `cam_view` / `move_mode`. Applied when a level builds — no live reswap.
Dev Settings gets a "Player" OptionButton row (3D robot / 2D sprite) between
Camera and Movement, wired exactly like the Camera row.

## 3. scripts/robot_character.gd (new)

The 3D sibling of `sprite_character.gd`, attached to a pivot built by
`Visuals.make_robot_character()` with `robot_idle.glb` instanced underneath.

- **Clip merging** (`_ready`): copies the rig's baked idle plus the single clip
  from each of `robot_walk.glb` / `robot_run.glb` into a fresh `extra/`
  AnimationLibrary with `loop_mode = LOOP_LINEAR` forced on. This sidesteps two
  gotchas at once: the imported `""` library is read-only, and freshly imported
  clips don't loop. Entries are keyed off file names (`extra/walk`), never the
  unreliable internal clip names.
- **Auto-scale** (`_ready`): measures the rig's combined MeshInstance3D AABB and
  scales it to `ROBOT_HEIGHT = 0.9` world units with feet at y=0. Handles any
  authoring scale (Meshy armatures are often 0.01) and makes rig swaps trivial.
- **Animation picking** (`_process`): watches its own `global_position` delta —
  the same idiom as SpriteCharacter — so it works in BOTH movement modes
  (turn-based lerp has no velocity; real-time is physics-driven). Still → idle;
  moving → walk; run only after `RUN_SPEED` is sustained for `RUN_HOLD` seconds
  (the hold keeps single turn-based steps, whose lerp speed briefly spikes ~14
  u/s, from flickering into run).
- **Facing**: rotates to face travel with `lerp_angle` at `TURN_SPEED`. glTF
  rigs face +Z, so `atan2(dir.x, dir.z)`, `MODEL_YAW_OFFSET = 0` (set to PI only
  for a backwards rig — never rotate the mesh child).
- **Fail-loud**: missing AnimationPlayer / clips → `push_error` naming the file;
  no silent fallback (house doctrine: build-time correctness, no runtime repair).

Collision is untouched — `Level._spawn()` adds the capsule as before; this is a
visual-only swap. The enemy stays a red capsule.

## 4. Vault rework + reorder

New map (win by star, like every other level):

    #######
    #@   K#
    #     #
    ##D####
    #*    #
    #######

The star chamber's only entrance is the channel-0 door `D`; the key `K` latches
it open forever. The door sits in a horizontal wall run, so it keeps its default
up/down passage (auto-orient verified against `level.gd` `_add_door`).

Order change: Vault moves from slot 3 to slot 2 — Warmup, **Vault**, Two Crates,
Color Lock, The Chase — so difficulty ramps key → plates+crates → rotated door →
enemy.

Consequence: no shipped level uses the legacy sokoban fallback win rule anymore
(`level.gd` keeps the code + docs; it remains a forkable feature).

## Testing

Built on disk; user tests in-engine (house rule — Claude does not drive the
engine). Script-error check via the Summer MCP when the engine has gridkit open.
Watch for: robot scale/facing (tunables `ROBOT_HEIGHT`, `MODEL_YAW_OFFSET`),
walk/run feel (`RUN_SPEED`, `RUN_HOLD`), and the new Vault solve path.
