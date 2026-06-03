class_name OpponentHand
extends Node2D

const MAX_CARDS := 3
const TEMPORARY_DRAW_LIMIT := 4
const HAND_Y_POSITION := 8.0
const CARD_WIDTH := 92.0
const CARD_SCALE := Vector2(0.5, 0.5)

var cards: Array[CardScn] = []


func add_card(card: CardScn) -> bool:
	if card == null:
		return false
	if not can_receive_drawn_card():
		push_warning("OpponentHand cheia; carta nao adicionada: %s" % card.name)
		return false
	if card in cards:
		update_positions()
		return true

	cards.append(card)
	_prepare_card(card)
	update_positions()
	return true


func remove_card(card: CardScn) -> bool:
	if not card in cards:
		return false

	cards.erase(card)
	update_positions()
	return true


func has(card: CardScn) -> bool:
	return cards.has(card)


func can_receive_drawn_card() -> bool:
	return cards.size() < TEMPORARY_DRAW_LIMIT


func is_over_limit() -> bool:
	return cards.size() > MAX_CARDS


func is_empty() -> bool:
	return cards.is_empty()


func size() -> int:
	return cards.size()


func get_cards() -> Array[CardScn]:
	var hand_cards: Array[CardScn] = []
	for card: CardScn in cards:
		hand_cards.append(card)
	return hand_cards


func update_positions() -> void:
	for index: int in range(cards.size()):
		var card: CardScn = cards[index]
		var target_position: Vector2 = Vector2(_calculate_card_x(index), HAND_Y_POSITION)
		card.start_position = target_position
		card.scale = CARD_SCALE
		card.set_meta("base_scale", CARD_SCALE)
		card.z_index = 1

		var tween: Tween = get_tree().create_tween()
		tween.tween_property(card, "position", target_position, 0.36)


func _calculate_card_x(index: int) -> float:
	var center_x: float = float(ProjectSettings.get_setting("display/window/size/viewport_width")) / 2.0
	var total_width: float = float((cards.size() - 1)) * CARD_WIDTH
	return center_x + (float(index) * CARD_WIDTH) - (total_width / 2.0)


func _prepare_card(card: CardScn) -> void:
	card.flip_to_back()
	card.set_as_revealed()
	card.scale = CARD_SCALE
	card.set_meta("base_scale", CARD_SCALE)
	card.z_index = 1
