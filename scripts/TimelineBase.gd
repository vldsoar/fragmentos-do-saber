class_name TimelineBase
extends Node2D

@export var card_width: int = 160
@export var hand_y_position: int = 950
@export var hide_card_faces: bool = false

var player_timeline: Array[CardScn] = []
var center_screen_x: int = 0
var card_being_dragged: CardScn = null


func _ready() -> void:
	center_screen_x = _get_center_screen_x()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		center_screen_x = _get_center_screen_x()
		update_hand_position()


func _get_center_screen_x() -> int:
	var base_width: int = int(ProjectSettings.get_setting("display/window/size/viewport_width"))
	return base_width / 2


func find_index_of(card: CardScn) -> int:
	return player_timeline.find(card)


func has(card: CardScn) -> bool:
	return player_timeline.has(card)


func get_card_names() -> Array:
	var names: Array[String] = []
	for card: CardScn in player_timeline:
		names.append(card.name)
	return names


func get_cards() -> Array[CardScn]:
	var cards: Array[CardScn] = []
	for card: CardScn in player_timeline:
		cards.append(card)
	return cards


func add_card_to_hand(card: CardScn) -> void:
	if card in player_timeline:
		anime_card_to_position(card, card.start_position)
		return

	player_timeline.append(card)
	_prepare_card_for_timeline(card)
	update_hand_position()


func insert_card_at(card: CardScn, target_index: int) -> void:
	if card in player_timeline:
		reorder_card(card, target_index)
		return

	var safe_index: int = clampi(target_index, 0, player_timeline.size())
	player_timeline.insert(safe_index, card)
	_prepare_card_for_timeline(card)
	update_hand_position()


func update_hand_position() -> void:
	if player_timeline.is_empty():
		return

	for index: int in range(player_timeline.size()):
		var new_position: Vector2 = Vector2(calculate_card_position(index), hand_y_position)
		var card: CardScn = player_timeline[index]
		card.start_position = new_position

		if card != card_being_dragged:
			anime_card_to_position(card, new_position)


func calculate_card_position(index: int) -> int:
	var total_width: float = float((player_timeline.size() - 1) * card_width)
	var x_offset: float = center_screen_x + (index * card_width) - (total_width / 2.0)
	return int(x_offset)


func anime_card_to_position(card: CardScn, target_position: Vector2) -> void:
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(card, "position", target_position, 0.3)


func remove_card(card: CardScn) -> void:
	if card in player_timeline:
		player_timeline.erase(card)
		update_hand_position()


func clear_timeline() -> void:
	player_timeline.clear()
	card_being_dragged = null


func get_target_position_for_reorder() -> int:
	var mouse_x: float = get_global_mouse_position().x
	var center_x: float = float(_get_center_screen_x())
	var relative_x: float = mouse_x - center_x
	var half_card_width: float = card_width / 2.0
	var card_count: int = player_timeline.size()
	var total_width: float = float((card_count - 1) * card_width)

	relative_x = clampf(
		relative_x,
		-total_width / 2.0 - half_card_width,
		total_width / 2.0 + half_card_width
	)

	var index: int = int((relative_x + total_width / 2.0 + half_card_width) / card_width)
	return clampi(index, 0, card_count)


func reorder_card(card: CardScn, target_index: int) -> void:
	if not card in player_timeline:
		push_warning("Reorder failed: card not in timeline")
		return

	var current_index: int = player_timeline.find(card)
	if current_index == -1:
		push_warning("Reorder failed: current index not found")
		return

	player_timeline.remove_at(current_index)

	if current_index < target_index and (target_index - current_index) > 1:
		target_index -= 1

	var safe_index: int = clampi(target_index, 0, player_timeline.size())
	player_timeline.insert(safe_index, card)
	update_hand_position()


func _swap_cards(card1: CardScn, card2: CardScn) -> void:
	if not (card1 in player_timeline and card2 in player_timeline):
		return

	var index1: int = player_timeline.find(card1)
	var index2: int = player_timeline.find(card2)

	if index1 == -1 or index2 == -1:
		return

	player_timeline[index1] = card2
	player_timeline[index2] = card1
	update_hand_position()


func _prepare_card_for_timeline(card: CardScn) -> void:
	if hide_card_faces:
		card.flip_to_back()
