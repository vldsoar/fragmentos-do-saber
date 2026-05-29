extends Node

const SETTINGS_PATH := "user://settings.cfg"
const SECTION := "settings"

var music_enabled: bool = true
var effects_enabled: bool = true
var teacher_mode_enabled: bool = false


func _ready() -> void:
	load_settings()
	apply_audio_settings()


func load_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	var err: Error = config.load(SETTINGS_PATH)
	if err != OK:
		save_settings()
		return

	music_enabled = bool(config.get_value(SECTION, "music_enabled", music_enabled))
	effects_enabled = bool(config.get_value(SECTION, "effects_enabled", effects_enabled))
	teacher_mode_enabled = bool(config.get_value(SECTION, "teacher_mode_enabled", teacher_mode_enabled))
	apply_audio_settings()


func save_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value(SECTION, "music_enabled", music_enabled)
	config.set_value(SECTION, "effects_enabled", effects_enabled)
	config.set_value(SECTION, "teacher_mode_enabled", teacher_mode_enabled)
	config.save(SETTINGS_PATH)
	apply_audio_settings()


func set_music_enabled(value: bool) -> void:
	music_enabled = value
	save_settings()


func set_effects_enabled(value: bool) -> void:
	effects_enabled = value
	save_settings()


func set_teacher_mode_enabled(value: bool) -> void:
	teacher_mode_enabled = value
	save_settings()


func apply_audio_settings() -> void:
	pass


func can_play_effects() -> bool:
	return effects_enabled
