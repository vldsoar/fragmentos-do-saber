class_name FeedbackEffect
extends Control

signal confirmed

@export var default_toast_duration: float = 1.5

@onready var panel: Panel = $Panel
@onready var label: Label = $Panel/VBoxContainer/Label
@onready var ok_button: Button = $Panel/VBoxContainer/OkButton

var _on_finished: Callable = Callable()  # callback opcional


func _ready() -> void:
	z_index = 3000
	z_as_relative = false
	visible = false
	ok_button.pressed.connect(_on_ok_button_pressed)
	
	var vp = get_viewport().get_visible_rect().size
	var panel_size = panel.size
	panel.global_position = (vp - panel_size) * 0.5


## MODO 1: TOAST (mensagem rápida que some sozinha)
func show_toast(message: String, duration: float = -1.0, on_finished: Callable = Callable()) -> void:
	visible = true
	label.text = message

	_on_finished = on_finished

	ok_button.visible = false
	mouse_filter = MOUSE_FILTER_IGNORE  # não bloqueia cliques no resto do jogo

	panel.modulate.a = 1.0

	var d := duration if duration > 0.0 else default_toast_duration

	var tween := create_tween()
	tween.tween_interval(d)
	tween.tween_property(panel, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func ():
		if _on_finished.is_valid():
			_on_finished.call()
		queue_free()
	)


## MODO 2: MODAL (mensagem com botão OK)
func show_modal(message: String, ok_text: String = "OK", on_finished: Callable = Callable()) -> void:
	visible = true
	label.text = message

	_on_finished = on_finished

	ok_button.visible = true
	ok_button.text = ok_text
	mouse_filter = MOUSE_FILTER_STOP  # bloqueia cliques nas cartas enquanto está aberto

	panel.modulate.a = 1.0
	ok_button.grab_focus()


func _on_ok_button_pressed() -> void:
	emit_signal("confirmed")

	var tween := create_tween()
	tween.tween_property(panel, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func():
		if _on_finished.is_valid():
			_on_finished.call()
		queue_free()
	)
