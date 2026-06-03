class_name SettingsScreen
extends Control

@onready var background_panel: Panel = $Background
@onready var overlay: ColorRect = $Overlay
@onready var panel_container: PanelContainer = $PanelContainer
@onready var title_label: Label = $PanelContainer/MarginContainer/RootVBox/TitleLabel
@onready var music_toggle: CheckButton = $PanelContainer/MarginContainer/RootVBox/OptionsVBox/MusicToggle
@onready var effects_toggle: CheckButton = $PanelContainer/MarginContainer/RootVBox/OptionsVBox/EffectsToggle
@onready var teacher_mode_toggle: CheckButton = $PanelContainer/MarginContainer/RootVBox/OptionsVBox/TeacherModeToggle
@onready var back_button: Button = $PanelContainer/MarginContainer/RootVBox/BackButton


func _ready() -> void:
	_apply_theme()
	music_toggle.button_pressed = SettingsManager.music_enabled
	effects_toggle.button_pressed = SettingsManager.effects_enabled
	teacher_mode_toggle.button_pressed = SettingsManager.teacher_mode_enabled

	music_toggle.toggled.connect(_on_music_toggled)
	effects_toggle.toggled.connect(_on_effects_toggled)
	teacher_mode_toggle.toggled.connect(_on_teacher_mode_toggled)
	back_button.pressed.connect(_on_back_pressed)


func _apply_theme() -> void:
	ThemeManager.apply_background_panel(background_panel, ThemeManager.TEXTURE_MENU_BACKGROUND)
	overlay.color = ThemeManager.get_color(ThemeManager.COLOR_OVERLAY, Color(0, 0, 0, 0.5))
	panel_container.add_theme_stylebox_override("panel", ThemeManager.make_panel_style(ThemeManager.COLOR_PANEL_BG, ThemeManager.COLOR_PANEL_BORDER, 6, 1, 0))

	var body_font: Font = ThemeManager.get_font(ThemeManager.FONT_BODY)
	ThemeManager.apply_label(title_label, ThemeManager.COLOR_TITLE, ThemeManager.FONT_TITLE)

	for button_value: Variant in [music_toggle, effects_toggle, teacher_mode_toggle, back_button]:
		var button: Button = button_value as Button
		button.add_theme_color_override("font_color", ThemeManager.get_color(ThemeManager.COLOR_BODY, Color(0.93, 0.9, 0.8, 1.0)))
		if body_font != null:
			button.add_theme_font_override("font", body_font)
	ThemeManager.apply_button(back_button)


func _on_music_toggled(enabled: bool) -> void:
	UISoundManager.play_button_click()
	SettingsManager.set_music_enabled(enabled)
	if enabled:
		MusicManager.play_menu_music()
	else:
		MusicManager.stop()


func _on_effects_toggled(enabled: bool) -> void:
	UISoundManager.play_button_click()
	SettingsManager.set_effects_enabled(enabled)


func _on_teacher_mode_toggled(enabled: bool) -> void:
	UISoundManager.play_button_click()
	SettingsManager.set_teacher_mode_enabled(enabled)


func _on_back_pressed() -> void:
	UISoundManager.play_button_click()
	get_tree().change_scene_to_file("res://scenes/MenuGame.tscn")
