# CardRevealPanel.gd
class_name CardRevealPanel
extends Control

signal connect_selected(card)
signal discard_selected(card)
signal apply_effect_selected(card)
signal keep_selected(card)
signal reveal_state_changed(active: bool)

var current_card: CardScn
const KEEP_BUTTON_TEXT := "Ficar na mão"
const CANCEL_REPLACEMENT_TEXT := "Cancelar"
const ACTION_BUTTON_MIN_SIZE := Vector2(246, 44)

@onready var connect_button = $ButtonsContainer/ConnectButton
@onready var discard_button  = $ButtonsContainer/DiscardButton
@onready var apply_effect_button = $ButtonsContainer/ApplyEffectButton
@onready var keep_button = $ButtonsContainer/KeepButton
#$"../CardSlot2" -> is discard slot

func _ready():
	_apply_theme()
	_configure_action_buttons()
	hide()
	connect_button.connect("pressed", _on_connect_pressed)
	discard_button.connect("pressed", _on_discard_pressed)
	apply_effect_button.connect("pressed", _on_apply_effect_pressed)
	keep_button.connect("pressed", _on_keep_pressed)
	_hide_action_buttons()


func _apply_theme() -> void:
	ThemeManager.apply_button(connect_button)
	ThemeManager.apply_button(discard_button)
	ThemeManager.apply_button(apply_effect_button)
	ThemeManager.apply_button(keep_button)


func _configure_action_buttons() -> void:
	for button: Button in [connect_button, discard_button, apply_effect_button, keep_button]:
		button.custom_minimum_size = ACTION_BUTTON_MIN_SIZE
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER

func show_for(card: CardScn) -> void:
	current_card = card
	current_card.flip_to_front()
	keep_button.text = KEEP_BUTTON_TEXT
	# posiciona o painel próximo ao centro ou fixa num canto da UI
	_hide_action_buttons()
	#visible = true
	if card.is_special():
		apply_effect_button.show()
	else:
		connect_button.show()

	discard_button.show()
	keep_button.show()
	show()
	reveal_state_changed.emit(true)


func show_replacement_mode(card: CardScn) -> void:
	current_card = card
	_hide_action_buttons()
	keep_button.text = CANCEL_REPLACEMENT_TEXT
	keep_button.show()
	show()
	reveal_state_changed.emit(true)

func has_card() -> bool:
	return current_card != null

func _on_connect_pressed() -> void:
	UISoundManager.play_button_click()
	emit_signal("connect_selected", current_card)

func _on_discard_pressed() -> void:
	UISoundManager.play_button_click()
	emit_signal("discard_selected", current_card)
	_clear_current_card()

func _on_apply_effect_pressed() -> void:
	UISoundManager.play_button_click()
	emit_signal("apply_effect_selected", current_card)


func _on_keep_pressed() -> void:
	UISoundManager.play_button_click()
	emit_signal("keep_selected", current_card)
	_clear_current_card()


func _clear_current_card() -> void:
	current_card = null
	hide()
	reveal_state_changed.emit(false)


func clear_current_card() -> void:
	_clear_current_card()


func _hide_action_buttons() -> void:
	apply_effect_button.hide()
	connect_button.hide()
	discard_button.hide()
	keep_button.hide()
