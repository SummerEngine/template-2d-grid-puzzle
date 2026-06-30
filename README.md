# GridKit

A tiny **grid-based topdown** template for 12-hour hackathons. Fork it into a Sokoban, a
roguelike, a Pac-Man, a Zelda-like, a puzzle game, a tower defense — the grid is the same,
only your rules change.

- **3D, but zero 2D art.** Everything is a flat-shaded primitive (box / capsule / cylinder).
  Recolor or reshape in `scripts/visuals.gd`. Drop in a `.glb` later if you want.
- **Real-time OR turn-based**, one flag.
- **Keyboard now, Arduino later** — same input actions, no code change.
- **Light by design** — no shadows, no post, orthographic camera, Compatibility renderer.
- **Full menu system** — main menu, level select, settings, credits, pause, level-complete,
  with a Game Boy-green theme and fade transitions. Sound-ready.

The game boots into the **Main Menu**. The shipped demo is a 3-level Sokoban: push the tan
crates onto the green pads, and progress through the levels.

## Controls
- Move: **Arrow keys** or **WASD**
- Action button: **Space** (unused by the demo; wired up for your game)

## Make it your own

1. **Add / edit levels** — edit the `LEVELS` array in `scripts/autoload/level_manager.gd`.
   Each entry is `{ "name": ..., "realtime": false, "map": [ ... ] }`. The map is just text:
   `#` wall · `@` player · `$` crate · `*` star · `.` plate · `K` key · `D` door · space = floor.
   Add an entry → new level in the sequence and on the Level Select grid.

   **Winning:** collect every `*` star to win. A level with no star falls back to the legacy
   sokoban rule (push a crate onto each `.` plate).

   **Walls & doors:** `#` walls can go anywhere inside a map, not just the border. A door set
   into a *vertical* wall (walls above & below) auto-rotates to a left↔right passage; otherwise
   it's an up↔down passage.

   **Color channels:** doors, plates, and keys share a numbered "channel" (a color). A door
   opens while a plate of its channel is pressed, or **forever** once a key of its channel is
   collected. Channel 0 (`.`/`K`/`D`) is colorless; colored channels: blue `b`/`B`/`1`,
   green `g`/`G`/`2`, red `r`/`R`/`3` (plate / key / door). Add colors in `Visuals.CHANNEL_COLORS`.

2. **Switch genre feel** — set `"realtime": true` on a level for arcade-style continuous
   movement; `false` for one-step-per-press puzzle movement. Per-level.

3. **Add a new object type** — copy `scripts/box.gd` to e.g. `scripts/coin.gd`, add a letter
   to `LEGEND` in `scripts/level.gd`, give it a mesh in `scripts/visuals.gd`, and spawn it in
   `Level.build()`. Override `on_tick()` (acts every world tick) or `on_bump(other)` (someone
   walked into it) for behaviour.

4. **Change the win rule** — edit `_on_tick()` in `scripts/game_manager.gd`. It runs after
   every world tick; on a win it sends you to the Level Complete screen.

5. **Make it look like your game** — tile art is pixel-art textures in `art/tiles/`
   (`floor_stone`, `floor_plate`, `floor_key`, `wall_metal`, `crate_wood`, `door_tile`).
   Swap a PNG to reskin a tile; paths live in `scripts/visuals.gd`. The player stays a flat
   capsule. Menu palette is `scripts/autoload/ui_theme.gd` (change 5 colors, whole UI reskins).

6. **Turn Level Select off** — set `level_select_enabled = false` in `level_manager.gd`
   (or toggle it in the Settings screen).

## How it fits together

| File | Job |
|------|-----|
| `scripts/grid.gd` | Cell ↔ world math, bounds. Pure logic. |
| `scripts/tick_manager.gd` | The world heartbeat. Timer (real-time) or keypress (turn-based). |
| `scripts/input_router.gd` | Autoload. Feeds keyboard **and** Arduino into the same input actions. |
| `scripts/grid_entity.gd` | Base for anything on a cell. Subclass + override `on_tick`/`on_bump`. |
| `scripts/player.gd` | Reads input on each tick, asks the Level to move. |
| `scripts/box.gd` | Example pushable crate (the subclassing pattern). |
| `scripts/level.gd` | Builds the world from the ASCII map; owns the one shared movement rule. |
| `scripts/visuals.gd` | The only "art": flat-shaded primitive meshes. |
| `scripts/game_manager.gd` | Plays the current level; handles pause + win. |
| `game.tscn` | The gameplay scene (one level at a time). |

Everything that moves listens to `TickManager.tick`. That single idea is why the same code
runs as both a turn-based puzzle and a real-time arcade game.

## Menus & level flow

The boot scene is `screens/main_menu.tscn`. Navigation goes through one autoload:
`GameFlow.goto("main_menu" | "level_select" | "game" | "level_complete" | "settings" | "credits")`,
which fades and swaps scenes.

| File | Job |
|------|-----|
| `scripts/autoload/game_flow.gd` | Screen manager — `goto(...)`, `play_level(i)`, fade transitions. |
| `scripts/autoload/level_manager.gd` | The `LEVELS` list + progression + the Level Select on/off flag. |
| `scripts/autoload/audio_manager.gd` | Sound hooks (`play_ui`, `play_music`) + volume buses. Silent until you add sounds. |
| `scripts/autoload/ui_theme.gd` | The whole menu look, built in code (no image assets). 5 colors to reskin. |
| `scripts/autoload/fader.gd` | The fade overlay used between screens. |
| `scripts/ui/screen.gd` | Base class for menu screens + builder helpers (`make_button`, etc.). |
| `scripts/ui/menu_button.gd` | Button with hover/click sound + focus pop. |
| `screens/*.tscn` + `scripts/ui/*.gd` | The individual menu screens. |

To add a screen: make `scripts/ui/foo.gd` (`extends Screen`), a one-line `screens/foo.tscn`,
register it in `GameFlow.SCREENS`, then `GameFlow.goto("foo")`. See `.summer/ui-system-contract.md`.

## Adding sounds

`AudioManager` is wired everywhere but silent until you give it streams:
```gdscript
AudioManager.register_ui("click", preload("res://sfx/click.wav"))
AudioManager.register_ui("hover", preload("res://sfx/hover.wav"))
AudioManager.play_music(preload("res://music/theme.ogg"))
```
Buttons already call `play_ui("hover"/"click")`; volume sliders live in the Settings screen.

## Plugging in an Arduino

The game only ever reads input *actions* (`move_up`, `move_down`, `move_left`, `move_right`,
`action`), never the keyboard directly. So a controller just has to feed those actions.

`scripts/input_router.gd` is the one place that does it. Suggested protocol: the Arduino sends
**one byte per update**, one bit per button:

```
bit 0 = up   bit 1 = down   bit 2 = left   bit 3 = right   bit 4 = action
```

Godot can't read a serial port on its own — install a serial GDExtension (Asset Library →
search "serial"), then fill in `_open_serial()` and `_poll_serial()` in `input_router.gd`.
Until then it silently stays on the keyboard, so you can build the whole game first and add
the controller at the end.

## Performance notes (the "it runs on a weak handheld" budget)
- Compatibility (GLES3) renderer, set in `project.godot`.
- All materials are `SHADING_MODE_UNSHADED` → no lighting cost, no shadows.
- One orthographic camera, one ground plane, a handful of primitive meshes.

Add heavy stuff (real lights, shadows, particles, high-poly imports) only if your target
hardware can afford it.

## License

MIT — see [LICENSE](LICENSE). Free to use, modify, and share; just keep the copyright notice.
