class_name CardSlotScn
extends Node2D

# Slot mode: SINGLE (1 card) or STACK (multiple cards, like discard)
enum SlotMode { SINGLE, STACK }

@export_enum("SINGLE", "STACK")
var slot_mode: int = SlotMode.SINGLE

# Which card types this slot accepts.
@export var accepted_card_types: Array[CardResource.Rarity] = [CardResource.Rarity.COMMON, CardResource.Rarity.SPECIAL]

var _cards: Array[CardScn] = []           # Used only when in STACK mode

func _ready() -> void:
	Globals.debug_log("CardSlot collision mask: %s" % $Area2D.collision_mask)

func occupy_with(card: CardScn, animate: bool = false, duration: float = 0.3) -> void:
	# Check if this slot accepts the card type
	if not can_accept_card(card):
		print_debug("CardSlotScn: card rejected. Type: %s" % [card.rarity])
		return
	
	card.flip_to_front()
	# Disable collision of the card when entering the slot
	card.disable_collision()

	if slot_mode == SlotMode.SINGLE:
		# Original behavior: only one card in the slot
		_cards.clear()
		_cards.append(card)	
	else:
		# STACK mode: stack cards, always keeping the last one on top
		_cards.append(card)
		# Adjust z_index to ensure the last one is visible on top of the others
		card.z_index = _cards.size()

	# Move the card to the slot position (same behavior as before)
	if animate:
		var tween = get_tree().create_tween()
		tween.tween_property(card, "position", self.position, duration)
	else:
		card.position = self.position

func can_accept_card(card: CardScn) -> bool:
	# Maintain compatibility: just check if there is a current card
	if not _accepts_card(card):
		return false

	if slot_mode == SlotMode.SINGLE and _cards.size() > 0:
		return false
	
	return true

func has_cards() -> bool:
	return not _cards.is_empty()

func get_top_card() -> CardScn:
	if _cards.is_empty():
		return null
	return _cards[_cards.size() - 1]

func get_all_cards() -> Array[CardScn]:
	return _cards.duplicate()

func _accepts_card(card: CardScn) -> bool:
	# If the list is empty, consider it accepts any type
	if accepted_card_types.is_empty():
		return true

	# Check if the card's rarity is in the accepted types
	return card.rarity in accepted_card_types
