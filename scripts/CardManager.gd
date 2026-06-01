class_name CardManager
extends Node2D

# Variables for card dragging control
var screen_size: Vector2
var card_being_dragged: CardScn
var is_hovering_card: bool = false
var player_timeline_ref: PlayerTimeline
var game_manager: GameManager
var original_z_index: int
@export var player_timeline_path: String = "../PlayerTimeline"
@export var game_manager_path: String = "../GameManager"
@export var input_manager_path: String = "../InputManager"

const Z_INDEX_DEFAULT := 1
const Z_INDEX_HOVER := 3
const Z_INDEX_DRAG := 100

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_size = get_viewport_rect().size
	player_timeline_ref = get_node(player_timeline_path) as PlayerTimeline
	game_manager = get_node(game_manager_path) as GameManager
	var input_manager: InputManager = get_node(input_manager_path) as InputManager
	input_manager.connect("left_mouse_button_released", _on_left_mouse_button_released)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	update_dragged_card_position()

## Updates the position of the dragged card following the mouse cursor
## Position is clamped to screen boundaries to prevent cards from going off-screen
func update_dragged_card_position() -> void:
	if card_being_dragged:
		var mouse_pos: Vector2 = get_global_mouse_position()
		card_being_dragged.position = Vector2(
			clampf(mouse_pos.x, 0.0, screen_size.x),
			clampf(mouse_pos.y, 0.0, screen_size.y)
		)

## Starts dragging a card by setting it as the dragged card
## and resetting its scale to normal size
func start_drag(card: CardScn) -> void:
	if not game_manager.can_drag_card(card):
		return  # Não permite arrastar cartas reveladas
	
	Globals.debug_log("start_drag")
	card_being_dragged = card
	original_z_index = card.z_index
	card.z_index = Z_INDEX_DRAG  # Bring to front
	card.scale = Vector2.ONE

## Finishes dragging the card by applying highlight scale and clearing the reference
func finish_drag() -> void:
	if card_being_dragged == null:
		return

	Globals.debug_log("CardManager finish_drag - Card: %s" % card_being_dragged.name)
	
	var selected_card_slot: CardSlotScn = get_card_slot_under_mouse()
	Globals.debug_log("Card slot detected: %s" % selected_card_slot)

	var ctx: DropContext = DropResolver.resolve(
		card_being_dragged,
		selected_card_slot,
		get_card_under_mouse(),
		player_timeline_ref
	)
	
	# Delega a regra de jogo para o GameManager
	game_manager.handle_card_drop(ctx)

	Globals.debug_log("ctx: %s" % DropContext.DropType.find_key(ctx.type))
	_cleanup_after_drop()
	

func _cleanup_after_drop() -> void:
	# Move card to its final position and reset properties
	if card_being_dragged:
		card_being_dragged.scale = Vector2.ONE
		card_being_dragged.z_index = Z_INDEX_DEFAULT
		
		# If card is in timeline, set it to the correct position (without animation since it was just dragged)
		if card_being_dragged in player_timeline_ref.player_timeline:
			Globals.debug_log("card_being_dragged: start position")
			card_being_dragged.position = card_being_dragged.start_position
		
	player_timeline_ref.card_being_dragged = null	
	card_being_dragged = null
	is_hovering_card = false

## Connects a card's hover signals to their corresponding callback methods
## Allows the CardManager to respond to card hover events
func connect_card_signals(card: CardScn) -> void:
	if card == null:
		return
	if not card.hovered.is_connected(_on_card_hovered_card):
		card.hovered.connect(_on_card_hovered_card)
	if not card.hovered_off.is_connected(_on_card_hovered_off_card):
		card.hovered_off.connect(_on_card_hovered_off_card)
	
func _on_left_mouse_button_released() -> void:
	if card_being_dragged:
		finish_drag()
	

## Callback executed when a card enters hover state
## Applies visual highlight only if not already hovering another card
func _on_card_hovered_card(card: CardScn) -> void:
	Globals.debug_log("hover")
	if card.is_revealed or card_being_dragged:
		return
	if !is_hovering_card:
		is_hovering_card = true
		highlight_card(card, true)

"""
Callback executed when a card exits hover state
Removes highlight and checks if mouse is over another card
If over another card, applies highlight to it; otherwise clears hover state
"""
func _on_card_hovered_off_card(card: CardScn) -> void:
	
	if card_being_dragged:
		return

	highlight_card(card, false)
	# Check if mouse is over another card after leaving the current one
	var new_card_hovered: CardScn = get_card_under_mouse()
	if new_card_hovered:
		highlight_card(new_card_hovered, true)
	else:
		is_hovering_card = false
	
## Applies or removes visual highlight from a card
## When highlighted: increases scale to 1.1x and elevates z_index to 2
## When not highlighted: returns scale to 1.0x and z_index to 1
func highlight_card(card: CardScn, hovered: bool) -> void:
	# mate o tween anterior da PRÓPRIA carta
	if card.has_meta("hover_tween"):
		var old: Tween = card.get_meta("hover_tween") as Tween
		if old != null and old.is_valid():
			old.kill()

	var tween: Tween = get_tree().create_tween().set_trans(Tween.TRANS_QUAD)
	card.set_meta("hover_tween", tween)

	if hovered:
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(card, "scale", Vector2(1.1, 1.1), 0.18)
		tween.parallel().tween_property(card, "modulate", Color(1.08,1.08,1.08,1), 0.18)
		card.z_index = Z_INDEX_HOVER
	else:
		tween.set_ease(Tween.EASE_IN)
		tween.tween_property(card, "scale", Vector2.ONE, 0.14)
		tween.parallel().tween_property(card, "modulate", Color(1,1,1,1), 0.14)
		# Só volta pro default se não estiver sendo arrastada
		if card != card_being_dragged:
			card.z_index = Z_INDEX_DEFAULT
		
## Detects which card slot is under the mouse cursor using raycast
## Returns the first card slot
func get_card_slot_under_mouse() -> CardSlotScn:
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var params: PhysicsPointQueryParameters2D = PhysicsPointQueryParameters2D.new()
	
	params.position = get_global_mouse_position()
	params.collide_with_areas = true
	params.collision_mask = Globals.COLLISION_MASK_CARD_SLOT
	
	var result: Array[Dictionary] = space_state.intersect_point(params)
	
	if result.size() > 0:
		var collider: Area2D = result[0]["collider"] as Area2D
		if collider == null:
			return null
		return collider.get_parent() as CardSlotScn
	return null


## Detects which card is under the mouse cursor using raycast
## Returns the card with highest z_index if multiple cards are overlapping
func get_card_under_mouse() -> CardScn:
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var params: PhysicsPointQueryParameters2D = PhysicsPointQueryParameters2D.new()
	
	params.position = get_global_mouse_position()
	params.collide_with_areas = true
	params.collision_mask = Globals.COLLISION_MASK_CARD
	
	var result: Array[Dictionary] = space_state.intersect_point(params)
	
	if result.size() > 0:
		var cards: Array[CardScn] = _get_all_cards_from_result(result)
		# Filter out the card being dragged
		if card_being_dragged:
			var filtered_cards: Array[CardScn] = []
			for candidate: CardScn in cards:
				if candidate != card_being_dragged:
					filtered_cards.append(candidate)
			cards = filtered_cards
		
		if cards.size() > 0:
			return _get_card_with_highest_z_index_from_array(cards)
	return null

## Gets all cards from raycast result
func _get_all_cards_from_result(result: Array[Dictionary]) -> Array[CardScn]:
	var cards: Array[CardScn] = []
	for item: Dictionary in result:
		var collider: Area2D = item["collider"] as Area2D
		if collider == null:
			continue
		var card: Node = collider.get_parent()
		if card is CardScn:
			cards.append(card as CardScn)
	return cards

## Gets card with highest z_index from array
func _get_card_with_highest_z_index_from_array(cards: Array[CardScn]) -> CardScn:
	if cards.size() == 0:
		return null
		
	var highest_card: CardScn = cards[0]
	var highest_z: int = highest_card.z_index
	
	for card: CardScn in cards:
		if card.z_index > highest_z:
			highest_z = card.z_index
			highest_card = card
	
	#print("high card: ", highest_card.data.title)
	return highest_card

func animate_to_center(card: CardScn, center_pos: Vector2) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(card, "position", center_pos, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "scale", Vector2(2.5, 2.5), 0.3)
