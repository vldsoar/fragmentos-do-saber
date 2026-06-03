class_name PlayerHand
extends Node2D

signal hand_size_changed(size: int)

const MAX_CARDS := 3
const TEMPORARY_DRAW_LIMIT := 4
const HAND_Y_POSITION := 950
const HAND_CARD_WIDTH := 160
const HAND_CARD_SCALE := Vector2.ONE

var cards: Array[CardScn] = []
var center_screen_x: int = 0


func _ready() -> void:
	center_screen_x = _get_center_screen_x()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		center_screen_x = _get_center_screen_x()
		update_positions()


func add_card(card: CardScn) -> bool:
	if card == null:
		return false
	if not can_receive_drawn_card():
		push_warning("PlayerHand cheia; carta nao adicionada: %s" % card.name)
		return false
	if card in cards:
		update_positions()
		return true

	cards.append(card)
	_prepare_card(card)
	update_positions()
	hand_size_changed.emit(cards.size())
	return true


func remove_card(card: CardScn) -> bool:
	if not card in cards:
		return false

	cards.erase(card)
	update_positions()
	hand_size_changed.emit(cards.size())
	return true


func has(card: CardScn) -> bool:
	return cards.has(card)


func is_full() -> bool:
	return cards.size() >= MAX_CARDS


func can_receive_drawn_card() -> bool:
	return cards.size() < TEMPORARY_DRAW_LIMIT


func is_over_limit() -> bool:
	return cards.size() > MAX_CARDS


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
		card.set_meta("base_scale", HAND_CARD_SCALE)
		if card.scale != HAND_CARD_SCALE:
			card.scale = HAND_CARD_SCALE

		var tween: Tween = get_tree().create_tween()
		tween.tween_property(card, "position", target_position, 0.3)


func _prepare_card(card: CardScn) -> void:
	card.flip_to_front()
	card.disable_as_revealed()
	card.scale = HAND_CARD_SCALE
	card.set_meta("base_scale", HAND_CARD_SCALE)
	card.z_index = 1


func _calculate_card_x(index: int) -> int:
	var total_width: float = float((cards.size() - 1) * HAND_CARD_WIDTH)
	var x_offset: float = float(center_screen_x) + float(index * HAND_CARD_WIDTH) - (total_width / 2.0)
	return int(x_offset)


func _get_center_screen_x() -> int:
	var base_width: int = int(ProjectSettings.get_setting("display/window/size/viewport_width"))
	return base_width / 2
