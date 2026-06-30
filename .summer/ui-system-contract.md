# GridKit UI / Menu System — Contract for screen authors

The foundation (autoloads, theme, Screen base) already exists. Build screens against THIS API.
Do not modify the foundation files. Keep it beginner-legible (this is a hackathon template).

## How to author a screen

Each screen is TWO files:

1. `screens/<name>.tscn` — a single root node, type `Control`, with the script attached:
   ```
   [gd_scene load_steps=2 format=3]
   [ext_resource type="Script" path="res://scripts/ui/<name>.gd" id="1"]
   [node name="<Name>" type="Control"]
   script = ExtResource("1")
   ```
2. `scripts/ui/<name>.gd` — `extends Screen`. Override `_on_screen_ready()` (NOT `_ready()`)
   and build the UI **in code** using the helpers on `Screen`. The base already applies the
   theme + paints the background, so DO NOT hand-style controls — the theme makes it look good.

### Screen base helpers (in scripts/ui/screen.gd)
- `center_column(sep := 16) -> VBoxContainer` — a vertically-centered column; add rows to it.
- `make_title(text, size := 52) -> Label`
- `make_label(text, size := 20) -> Label`
- `make_button(text, min_width := 300) -> Button` — themed, hover/click sound + focus pop already wired.

Minimal example:
```gdscript
extends Screen

func _on_screen_ready() -> void:
    var col := center_column()
    col.add_child(make_title("GridKit"))
    var play := make_button("Play")
    play.pressed.connect(func(): GameFlow.goto("game"))
    col.add_child(play)
```

## Navigation (autoload `GameFlow`)
- `GameFlow.goto("main_menu" | "level_select" | "game" | "level_complete" | "settings" | "credits")`
  — fades + swaps scene.
- `GameFlow.play_level(index: int)` — sets the level and jumps into the game.

## Levels (autoload `LevelManager`)
- `LevelManager.count() -> int`
- `LevelManager.level_name(i) -> String`
- `LevelManager.is_complete(i) -> bool`  (true once the player has solved it)
- `LevelManager.all_complete() -> bool`
- `LevelManager.current_index` (int), `LevelManager.has_next() -> bool`, `LevelManager.advance() -> bool`
- `LevelManager.level_select_enabled` (bool) — the on/off switch for the Level Select screen.

## Audio (autoload `AudioManager`)
- `AudioManager.play_ui("click" | "hover")` — buttons already call these; silent until sounds registered.
- `AudioManager.set_volume("Master" | "Music" | "SFX", linear01)` / `get_volume(bus) -> float`.

## Theme palette (autoload `UITheme`, edit to reskin)
`UITheme.BG`, `.DARKEST`, `.DARK`, `.LIGHT`, `.LIGHTEST`, `.ACCENT` — Game Boy DMG greens.

## Hard rules
- Reference autoloads by their global name, UNTYPED (e.g. `var n = LevelManager.count()`).
  Never declare a typed var of another script's class and poke its members — it causes
  cross-script compile errors. Globals need no typing.
- Override `_on_screen_ready()`, never `_ready()` (the base needs its `_ready`).
- Don't run the engine or call MCP tools. Write files only.
