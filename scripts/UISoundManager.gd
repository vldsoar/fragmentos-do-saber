extends Node

const BUTTON_CLICK_SOUND := preload("res://assets/audio/mouse_click2.wav")
const TAKE_CARD_SOUND := preload("res://assets/audio/taking-card.wav")

var _player: AudioStreamPlayer


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	add_child(_player)


func play_button_click() -> void:
	_play(BUTTON_CLICK_SOUND)


func play_take_card() -> void:
	_play(TAKE_CARD_SOUND)


func _play(stream: AudioStream) -> void:
	if not SettingsManager.can_play_effects():
		return
	if stream == null:
		return

	_player.stream = stream
	_player.play()
