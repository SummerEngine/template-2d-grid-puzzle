extends Node

## "Ready for sound" layer. Every menu button already calls play_ui("hover"/"click").
## Until you register streams, calls are silent no-ops — so the game works now, and adding
## sound later is just: AudioManager.register_ui("click", preload("res://sfx/click.wav")).
##
## Buses: Master -> Music, SFX (created at runtime, no .tres needed). Settings adjusts them.

var _music_player: AudioStreamPlayer
var _ui_player: AudioStreamPlayer

var _ui_streams := {}   # name -> AudioStream

func _ready() -> void:
	_ensure_buses()
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	add_child(_music_player)
	_ui_player = AudioStreamPlayer.new()
	_ui_player.bus = "SFX"
	add_child(_ui_player)

func _ensure_buses() -> void:
	for bus_name in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, "Master")

# --- registration ---
func register_ui(sound_name: String, stream: AudioStream) -> void:
	_ui_streams[sound_name] = stream

# --- playback ---
func play_ui(sound_name: String) -> void:
	var stream = _ui_streams.get(sound_name)
	if stream != null:
		_ui_player.stream = stream
		_ui_player.play()

func play_music(stream: AudioStream) -> void:
	if stream == null:
		return
	_music_player.stream = stream
	_music_player.play()

func stop_music() -> void:
	_music_player.stop()

# --- volume (0..1 linear), called by Settings sliders ---
func set_volume(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(linear, 0.0001, 1.0)))

func get_volume(bus_name: String) -> float:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return 1.0
	return db_to_linear(AudioServer.get_bus_volume_db(idx))
