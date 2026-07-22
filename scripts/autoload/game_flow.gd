extends Node

## The screen manager. Anywhere in the game: GameFlow.goto("main_menu").
## It fades out, swaps the whole scene, and fades back in. Because menus and the 3D
## gameplay are separate scenes, switching scenes (not stacking nodes) keeps them cleanly
## isolated. State that needs to survive a switch lives in autoloads (LevelManager etc.).

const SCREENS := {
	"main_menu": "res://screens/main_menu.tscn",
	"level_select": "res://screens/level_select.tscn",
	"game": "res://game.tscn",
	"level_complete": "res://screens/level_complete.tscn",
	"level_failed": "res://screens/level_failed.tscn",
	"settings": "res://screens/settings.tscn",
	"credits": "res://screens/credits.tscn",
	"dev_settings": "res://screens/dev_settings.tscn",
}

var _busy := false

func goto(screen_key: String) -> void:
	if not SCREENS.has(screen_key):
		push_error("GameFlow: unknown screen '%s'" % screen_key)
		return
	if _busy:
		return
	_busy = true
	await Fader.fade_out()
	get_tree().change_scene_to_file(SCREENS[screen_key])
	await Fader.fade_in()
	_busy = false

## Convenience used by Main Menu / Level Complete: start a level and jump into the game.
func play_level(index: int) -> void:
	LevelManager.start(index)
	goto("game")
