class_name SettingsScreen
extends Control

@onready var music_toggle: CheckButton = $PanelContainer/MarginContainer/RootVBox/OptionsVBox/MusicToggle
@onready var effects_toggle: CheckButton = $PanelContainer/MarginContainer/RootVBox/OptionsVBox/EffectsToggle
@onready var teacher_mode_toggle: CheckButton = $PanelContainer/MarginContainer/RootVBox/OptionsVBox/TeacherModeToggle
@onready var back_button: Button = $PanelContainer/MarginContainer/RootVBox/BackButton


func _ready() -> void:
	music_toggle.button_pressed = SettingsManager.music_enabled
	effects_toggle.button_pressed = SettingsManager.effects_enabled
	teacher_mode_toggle.button_pressed = SettingsManager.teacher_mode_enabled

	music_toggle.toggled.connect(_on_music_toggled)
	effects_toggle.toggled.connect(_on_effects_toggled)
	teacher_mode_toggle.toggled.connect(_on_teacher_mode_toggled)
	back_button.pressed.connect(_on_back_pressed)


func _on_music_toggled(enabled: bool) -> void:
	UISoundManager.play_button_click()
	SettingsManager.set_music_enabled(enabled)


func _on_effects_toggled(enabled: bool) -> void:
	UISoundManager.play_button_click()
	SettingsManager.set_effects_enabled(enabled)


func _on_teacher_mode_toggled(enabled: bool) -> void:
	UISoundManager.play_button_click()
	SettingsManager.set_teacher_mode_enabled(enabled)


func _on_back_pressed() -> void:
	UISoundManager.play_button_click()
	get_tree().change_scene_to_file("res://scenes/MenuGame.tscn")
