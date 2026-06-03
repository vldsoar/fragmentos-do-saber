# File: card_effect_processor.gd
class_name CardEffectProcessor
extends Object

# Processes card effects after the caller has collected any choices required by UI.
# Keeps track of applied effect card IDs so they can be forwarded to scoring.
var _applied_effect_cards: Array[String] = []
var _accumulated_score: float = 0


func reset() -> void:
	_applied_effect_cards.clear()
	_accumulated_score = 0


func apply_effect(card: CardScn, ctx: Dictionary = {}) -> bool:
	if card == null:
		return false
		
	Globals.debug_log("effect card: %s" % card.data.effect_description)

	match card.effect:
		CardResource.SpecialEffect.FLAT_SCORE_BONUS:
			_register_effect_card(card.name)
			_apply_flat_score_bonus(card)
			return true
			# The flat bonus itself is handled later by the scoring engine.
		CardResource.SpecialEffect.OPPONENT_DISCARD_RANDOM:
			if _apply_opponent_discard_random(ctx):
				_register_effect_card(card.name)
				return true
			return false
		CardResource.SpecialEffect.REPLACE_BOARD_CARD:
			if _apply_replace_board_card(ctx):
				_register_effect_card(card.name)
				return true
			return false
		_:
			return false


func get_applied_effect_ids() -> Array[String]:
	return _applied_effect_cards.duplicate()

func get_accumulated_score() -> float:
	return _accumulated_score

func _apply_flat_score_bonus(card: CardScn) -> void:
	if card.effect == CardResource.SpecialEffect.FLAT_SCORE_BONUS:
		_accumulated_score += card.data.bonus_score

func _register_effect_card(card_id: String) -> void:
	if card_id.is_empty():
		return
	if _applied_effect_cards.has(card_id):
		return
	_applied_effect_cards.append(card_id)


func _apply_opponent_discard_random(ctx: Dictionary) -> bool:
	# Placeholder logic until we actually have an opponent timeline to work with.
	if not ctx.has("opponent_timeline"):
		print_debug("CardEffectProcessor: no opponent timeline present; discard effect skipped")
		return false

	var opponent_timeline = ctx["opponent_timeline"]
	if opponent_timeline == null:
		return false
	if not opponent_timeline.has_method("get_cards"):
		print_debug("CardEffectProcessor: opponent timeline missing get_cards() for discard effect")
		return false

	# Pick a COMMON card with truth_value >= 0.99 to discard.
	var candidate_cards: Array = []
	for candidate in opponent_timeline.get_cards():
		if candidate == null:
			continue
		if not (candidate is CardScn):
			continue
		var data: CardResource = candidate.data
		if data == null:
			continue
		if data.rarity != CardResource.Rarity.COMMON:
			continue
		if data.truth_value < 0.99:
			continue
		candidate_cards.append(candidate)

	if candidate_cards.is_empty():
		print_debug("CardEffectProcessor: no opponent COMMON true card to discard")
		return false

	randomize()
	var target: CardScn = candidate_cards[randi() % candidate_cards.size()]

	if opponent_timeline.has_method("remove_card"):
		opponent_timeline.remove_card(target)

	if ctx.has("discard_slot") and ctx["discard_slot"]:
		ctx["discard_slot"].occupy_with(target)
		return true

	return false


func _apply_replace_board_card(ctx: Dictionary) -> bool:
	var player_timeline: Variant = ctx.get("player_timeline", null)
	var player_hand: Variant = ctx.get("player_hand", null)
	var replacement_card: CardScn = ctx.get("replacement_card", null) as CardScn
	var target_card: CardScn = ctx.get("target_card", null) as CardScn
	var discard_slot: CardSlotScn = ctx.get("discard_slot", null) as CardSlotScn

	if player_timeline == null or player_hand == null or replacement_card == null or target_card == null or discard_slot == null:
		print_debug("CardEffectProcessor: replace board effect missing context")
		return false
	if not player_timeline.has_method("has") or not player_timeline.has_method("find_index_of") or not player_timeline.has_method("replace_card_at"):
		print_debug("CardEffectProcessor: replace board effect timeline has invalid interface")
		return false
	if not player_hand.has_method("has") or not player_hand.has_method("remove_card"):
		print_debug("CardEffectProcessor: replace board effect hand has invalid interface")
		return false
	if not player_hand.has(replacement_card):
		print_debug("CardEffectProcessor: replacement card is not in hand")
		return false
	if not player_timeline.has(target_card):
		print_debug("CardEffectProcessor: target card is not in timeline")
		return false

	var target_index: int = player_timeline.find_index_of(target_card)
	if target_index < 0:
		return false

	player_hand.remove_card(replacement_card)
	replacement_card.disable_as_revealed()
	replacement_card.z_index = 1
	var replaced_card: CardScn = player_timeline.replace_card_at(target_index, replacement_card)
	if replaced_card == null:
		return false

	discard_slot.occupy_with(replaced_card, true, 0.3)
	return true
