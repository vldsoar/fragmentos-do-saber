extends Control
class_name MenuGame

func _ready() -> void:
	for _button in get_tree().get_nodes_in_group("button"):
		_button.pressed.connect(_on_button_pressed.bind(_button))
		Globals.debug_log("Menu button registered: %s" % _button.name)

func _on_button_pressed(btn: Button) -> void:
	UISoundManager.play_button_click()
	match btn.name:
		"StartGame":
			#get_tree().change_scene_to_file("res://scenes/Main.tscn")
			get_tree().change_scene_to_file("res://scenes/KnowledgeArea.tscn")
		"Settings":
			get_tree().change_scene_to_file("res://scenes/SettingsScreen.tscn")
