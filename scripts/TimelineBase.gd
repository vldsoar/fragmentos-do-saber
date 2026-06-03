class_name TimelineBase
extends Node2D

@export var card_width: int = 160
@export var hand_y_position: int = 950
@export var hide_card_faces: bool = false
@export var max_cards: int = 0
@export var card_scale: Vector2 = Vector2.ONE
@export var use_grid_layout: bool = false
@export var grid_columns: int = 4
@export var grid_origin: Vector2 = Vector2.ZERO
@export var grid_spacing: Vector2 = Vector2(150.0, 175.0)

const REPLACEMENT_TARGET_Z_INDEX := 6
const REPLACEMENT_TARGET_MODULATE := Color(1.22, 1.16, 0.78, 1.0)
const REPLACEMENT_TARGET_SCALE_MULTIPLIER := 1.06

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

	if is_full():
		push_warning("%s is full; card not added: %s" % [name, card.name])
		return

	player_timeline.append(card)
	_prepare_card_for_timeline(card)
	update_hand_position()


func insert_card_at(card: CardScn, target_index: int) -> void:
	if card in player_timeline:
		reorder_card(card, target_index)
		return

	if is_full():
		push_warning("%s is full; card not inserted: %s" % [name, card.name])
		return

	var safe_index: int = clampi(target_index, 0, player_timeline.size())
	player_timeline.insert(safe_index, card)
	_prepare_card_for_timeline(card)
	update_hand_position()


func update_hand_position() -> void:
	if player_timeline.is_empty():
		return

	for index: int in range(player_timeline.size()):
		var new_position: Vector2 = calculate_card_position_for_index(index)
		var card: CardScn = player_timeline[index]
		card.start_position = new_position
		_set_card_base_scale(card)

		if card != card_being_dragged:
			anime_card_to_position(card, new_position)


func calculate_card_position(index: int) -> int:
	var total_width: float = float((player_timeline.size() - 1) * card_width)
	var x_offset: float = center_screen_x + (index * card_width) - (total_width / 2.0)
	return int(x_offset)


func calculate_card_position_for_index(index: int) -> Vector2:
	if use_grid_layout:
		var col: int = index % grid_columns
		var row: int = floori(float(index) / float(grid_columns))
		return Vector2(
			grid_origin.x + float(col) * grid_spacing.x,
			grid_origin.y + float(row) * grid_spacing.y
		)
	return Vector2(calculate_card_position(index), hand_y_position)


func anime_card_to_position(card: CardScn, target_position: Vector2) -> void:
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(card, "position", target_position, 0.3)


func remove_card(card: CardScn) -> void:
	if card in player_timeline:
		player_timeline.erase(card)
		update_hand_position()


func is_full() -> bool:
	return max_cards > 0 and player_timeline.size() >= max_cards


func get_capacity() -> int:
	if max_cards > 0:
		return max_cards
	return player_timeline.size()


func replace_card_at(index: int, card: CardScn) -> CardScn:
	if index < 0 or index >= player_timeline.size():
		push_warning("Replace failed: index out of range")
		return null

	var replaced_card: CardScn = player_timeline[index]
	player_timeline[index] = card
	_prepare_card_for_timeline(card)
	update_hand_position()
	return replaced_card


func set_replacement_targets_highlighted(highlighted: bool) -> void:
	for card: CardScn in player_timeline:
		if card == null:
			continue
		if highlighted:
			_highlight_replacement_target(card)
		else:
			_clear_replacement_target_highlight(card)


func clear_timeline() -> void:
	player_timeline.clear()
	card_being_dragged = null


func get_target_position_for_reorder() -> int:
	if use_grid_layout:
		return _get_grid_target_position()

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


func _get_grid_target_position() -> int:
	var mouse_pos: Vector2 = get_global_mouse_position()
	var best_index: int = 0
	var best_distance: float = INF
	var count: int = player_timeline.size()

	for index: int in range(count):
		var candidate_pos: Vector2 = calculate_card_position_for_index(index)
		var distance: float = mouse_pos.distance_squared_to(candidate_pos)
		if distance < best_distance:
			best_distance = distance
			best_index = index

	return clampi(best_index, 0, maxi(count - 1, 0))


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
	else:
		card.flip_to_front()
	_set_card_base_scale(card)


func _set_card_base_scale(card: CardScn) -> void:
	if card == null:
		return
	card.scale = card_scale
	card.set_meta("base_scale", card_scale)


func _highlight_replacement_target(card: CardScn) -> void:
	if card.has_meta("hover_tween"):
		var old: Tween = card.get_meta("hover_tween") as Tween
		if old != null and old.is_valid():
			old.kill()

	card.set_meta("replacement_highlighted", true)
	card.scale = card_scale * REPLACEMENT_TARGET_SCALE_MULTIPLIER
	card.modulate = REPLACEMENT_TARGET_MODULATE
	card.z_index = REPLACEMENT_TARGET_Z_INDEX


func _clear_replacement_target_highlight(card: CardScn) -> void:
	if not card.has_meta("replacement_highlighted"):
		return

	card.remove_meta("replacement_highlighted")
	card.scale = card_scale
	card.modulate = Color(1, 1, 1, 1)
	card.z_index = 1
