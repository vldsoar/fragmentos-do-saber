class_name CardActionController
extends RefCounted

var player_timeline: PlayerTimeline
var discard_slot: CardSlotScn
var effect_slot: CardSlotScn


func configure(
	player_timeline_ref: PlayerTimeline,
	discard_slot_ref: CardSlotScn,
	effect_slot_ref: CardSlotScn
) -> void:
	player_timeline = player_timeline_ref
	discard_slot = discard_slot_ref
	effect_slot = effect_slot_ref


func connect_card_to_timeline(card: CardScn) -> void:
	_prepare_card_for_board(card)
	player_timeline.add_card_to_hand(card)


func discard_card(card: CardScn) -> void:
	_prepare_card_for_board(card)
	_tween_card_scale(card)
	discard_slot.occupy_with(card, true, 0.3)


func move_effect_card(card: CardScn) -> void:
	_prepare_card_for_board(card)
	var tween: Tween = card.get_tree().create_tween()
	tween.tween_property(card, "rotation_degrees", -30, 0.1)
	tween.tween_property(card, "rotation_degrees", 30, 0.1)
	tween.tween_property(card, "rotation_degrees", 0, 0.1)
	tween.tween_property(card, "scale", Vector2.ONE, 0.1)
	effect_slot.occupy_with(card, true, 0.3)


func _prepare_card_for_board(card: CardScn) -> void:
	card.disable_as_revealed()
	card.scale = Vector2.ONE
	card.z_index = 1


func _tween_card_scale(card: CardScn) -> void:
	var tween: Tween = card.get_tree().create_tween()
	tween.tween_property(card, "scale", Vector2.ONE, 0.1)
