extends Control
class_name MenuGame

@onready var background_panel: Panel = $Panel
@onready var book_sprite: Sprite2D = $Sprite2D
@onready var title_fragmentos: Label = $VBoxContainer/Label
@onready var title_do: Label = $VBoxContainer/HBoxContainer/Label
@onready var title_saber: Label = $VBoxContainer/HBoxContainer/Label2


func _ready() -> void:
	_apply_theme()
	MusicManager.play_menu_music()
	for _button in get_tree().get_nodes_in_group("button"):
		_button.pressed.connect(_on_button_pressed.bind(_button))
		if _button is Button:
			ThemeManager.apply_menu_button(_button)
		Globals.debug_log("Menu button registered: %s" % _button.name)


func _apply_theme() -> void:
	ThemeManager.apply_background_panel(background_panel, ThemeManager.TEXTURE_MENU_BACKGROUND)

	var book_texture: Texture2D = ThemeManager.get_texture(ThemeManager.TEXTURE_MENU_BOOK)
	if book_texture != null:
		book_sprite.texture = book_texture

	for title_value: Variant in [title_fragmentos, title_do, title_saber]:
		var title_label: Label = title_value as Label
		ThemeManager.apply_label(title_label, ThemeManager.COLOR_TITLE, ThemeManager.FONT_TITLE)

func _on_button_pressed(btn: Button) -> void:
	UISoundManager.play_button_click()
	match btn.name:
		"StartGame":
			#get_tree().change_scene_to_file("res://scenes/Main.tscn")
			get_tree().change_scene_to_file("res://scenes/KnowledgeArea.tscn")
		"Settings":
			get_tree().change_scene_to_file("res://scenes/SettingsScreen.tscn")
