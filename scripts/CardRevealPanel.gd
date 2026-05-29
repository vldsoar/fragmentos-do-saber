# CardRevealPanel.gd
class_name CardRevealPanel
extends Control

signal connect_selected(card)
signal discard_selected(card)
signal apply_effect_selected(card)

var current_card: CardScn

@onready var connect_button = $ButtonsContainer/ConnectButton
@onready var discard_button  = $ButtonsContainer/DiscardButton
@onready var apply_effect_button = $ButtonsContainer/ApplyEffectButton
#$"../CardSlot2" -> is discard slot

func _ready():
	hide()
	connect_button.connect("pressed", _on_connect_pressed)
	discard_button.connect("pressed", _on_discard_pressed)
	apply_effect_button.connect("pressed", _on_apply_effect_pressed)
	apply_effect_button.hide()
	connect_button.hide()

func show_for(card: CardScn) -> void:
	current_card = card
	current_card.flip_to_front()
	# posiciona o painel próximo ao centro ou fixa num canto da UI
	apply_effect_button.hide()
	connect_button.hide()
	#visible = true
	if card.is_special():
		apply_effect_button.show()
	else:
		connect_button.show()

	show()

func has_card() -> bool:
	return current_card != null

func _on_connect_pressed() -> void:
	UISoundManager.play_button_click()
	emit_signal("connect_selected", current_card)
	current_card = null
	hide()

func _on_discard_pressed() -> void:
	UISoundManager.play_button_click()
	emit_signal("discard_selected", current_card)
	current_card = null
	hide()

func _on_apply_effect_pressed() -> void:
	UISoundManager.play_button_click()
	emit_signal("apply_effect_selected", current_card)
	current_card = null
	hide()
