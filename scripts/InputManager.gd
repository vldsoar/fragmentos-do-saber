class_name InputManager
extends Node2D

signal left_mouse_button_clicked
signal left_mouse_button_released
signal deck_clicked


const COLLISION_MASK_DECK = 4

var card_manager_ref: CardManager
@export var card_manager_path: String = "../CardManager"
#var deck_ref

func _ready() -> void:
	card_manager_ref = get_node(card_manager_path) as CardManager
	#deck_ref = $"../Deck"

## Processes mouse input events to start/stop dragging cards
## Detects left mouse button clicks and manages drag state
func _input(event: InputEvent) -> void:
	if not _is_event_mouse_button_left(event):
		return

	if event.is_pressed():
		emit_signal("left_mouse_button_clicked")
		get_card_under_mouse()
	else:
		emit_signal("left_mouse_button_released")

## Detects which card is under the mouse cursor using raycast
## Returns the card with highest z_index if multiple cards are overlapping
func get_card_under_mouse() -> void:
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var params: PhysicsPointQueryParameters2D = PhysicsPointQueryParameters2D.new()
	
	params.position = get_global_mouse_position()
	params.collide_with_areas = true
	
	var result: Array[Dictionary] = space_state.intersect_point(params)
	
	if result.size() > 0:
		var collider: Area2D = result[0]["collider"] as Area2D
		if collider == null:
			return
		var result_collision_mask: int = collider.collision_mask
		
		if Globals.COLLISION_MASK_CARD == result_collision_mask:
			var card_found: CardScn = collider.get_parent() as CardScn
			
			if card_found:
				card_manager_ref.start_drag(card_found)
		elif COLLISION_MASK_DECK == result_collision_mask:
			emit_signal("deck_clicked")
			#deck_ref.draw_card()
				
# Checks if the event is a left mouse button click
func _is_event_mouse_button_left(event: InputEvent) -> bool:
	return event is InputEventMouseButton and MOUSE_BUTTON_LEFT == event.button_index
