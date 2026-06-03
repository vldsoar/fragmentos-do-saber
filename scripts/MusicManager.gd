extends Node

const MENU_MUSIC: AudioStream = preload("res://assets/audio/start_game.ogg")

var _player: AudioStreamPlayer


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.volume_db = -12.0
	add_child(_player)


func play_menu_music() -> void:
	play_music(MENU_MUSIC)


func play_music(stream: AudioStream) -> void:
	if not SettingsManager.music_enabled:
		stop()
		return
	if stream == null:
		return
	if _player == null:
		return
	if _player.stream == stream and _player.playing:
		return

	_player.stream = stream
	_player.play()


func stop() -> void:
	if _player == null:
		return
	_player.stop()
