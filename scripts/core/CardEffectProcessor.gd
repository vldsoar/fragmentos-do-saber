# File: card_effect_processor.gd
class_name CardEffectProcessor
extends Object

# Keeps track of which effect cards were applied so we can forward them to scoring.
var _applied_effect_cards: Array[String] = []
var _accumulated_score: float = 0


func reset() -> void:
	_applied_effect_cards.clear()
	_accumulated_score = 0


func apply_effect(card: CardScn, ctx: Dictionary = {}) -> void:
	if card == null:
		return
		
	Globals.debug_log("effect card: %s" % card.data.effect_description)

	match card.effect:
		CardResource.SpecialEffect.FLAT_SCORE_BONUS:
			_register_effect_card(card.name)
			_apply_flat_score_bonus(card)
			return
			# The flat bonus itself is handled later by the scoring engine.
		CardResource.SpecialEffect.OPPONENT_DISCARD_RANDOM:
			_register_effect_card(card.name)
			_apply_opponent_discard_random(ctx)
		_:
			return


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


func _apply_opponent_discard_random(ctx: Dictionary) -> void:
	# Placeholder logic until we actually have an opponent timeline to work with.
	if not ctx.has("opponent_timeline"):
		print_debug("CardEffectProcessor: no opponent timeline present; discard effect skipped")
		return

	var opponent_timeline = ctx["opponent_timeline"]
	if opponent_timeline == null:
		return
	if not opponent_timeline.has_method("get_cards"):
		print_debug("CardEffectProcessor: opponent timeline missing get_cards() for discard effect")
		return

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
		return

	randomize()
	var target: CardScn = candidate_cards[randi() % candidate_cards.size()]

	if opponent_timeline.has_method("remove_card"):
		opponent_timeline.remove_card(target)

	if ctx.has("discard_slot") and ctx["discard_slot"]:
		ctx["discard_slot"].occupy_with(target)
