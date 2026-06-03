class_name OpponentDecisionEngine
extends Object

const DECISION_CONNECT := "CONNECT"
const DECISION_DISCARD := "DISCARD"
const DECISION_APPLY_EFFECT := "APPLY_EFFECT"

var scoring_engine: CoherenceScoringEngine = CoherenceScoringEngine.new()


func choose_action(
	deck_data: Dictionary,
	card: CardScn,
	timeline_ids: Array,
	effect_card_ids: Array,
	min_score_gain_to_connect: float = 0.0,
	max_timeline_cards: int = 0
) -> Dictionary:
	var plan: Dictionary = _default_plan()

	if card == null or card.data == null:
		return plan

	if card.is_special():
		plan["decision"] = DECISION_APPLY_EFFECT
		plan["reason"] = "special_card"
		return plan

	if deck_data.is_empty():
		return _choose_by_truth_value(card)

	var current_score: float = _score_timeline(deck_data, timeline_ids, effect_card_ids)
	var best_score: float = -INF
	var best_index: int = timeline_ids.size()
	var best_replace_index: int = -1

	if max_timeline_cards > 0 and timeline_ids.size() >= max_timeline_cards:
		for index in range(timeline_ids.size()):
			var candidate_timeline: Array = timeline_ids.duplicate()
			candidate_timeline[index] = card.data.id
			var candidate_score: float = _score_timeline(deck_data, candidate_timeline, effect_card_ids)

			if candidate_score > best_score:
				best_score = candidate_score
				best_index = index
				best_replace_index = index
	else:
		for index in range(timeline_ids.size() + 1):
			var candidate_timeline: Array = timeline_ids.duplicate()
			candidate_timeline.insert(index, card.data.id)
			var candidate_score: float = _score_timeline(deck_data, candidate_timeline, effect_card_ids)

			if candidate_score > best_score:
				best_score = candidate_score
				best_index = index

	var score_delta: float = best_score - current_score
	plan["score_delta"] = score_delta
	plan["insert_index"] = best_index
	plan["replace_index"] = best_replace_index
	plan["projected_score"] = best_score

	if score_delta > min_score_gain_to_connect:
		plan["decision"] = DECISION_CONNECT
		plan["reason"] = "best_projected_score"
	else:
		plan["decision"] = DECISION_DISCARD
		plan["reason"] = "no_positive_score_gain"

	return plan


func _score_timeline(deck_data: Dictionary, timeline_ids: Array, effect_card_ids: Array) -> float:
	var result: ResultGame = scoring_engine.evaluate_timeline(deck_data, timeline_ids, effect_card_ids)
	return result.total_score


func _choose_by_truth_value(card: CardScn) -> Dictionary:
	var plan: Dictionary = _default_plan()
	if card.data.truth_value > 0.8:
		plan["decision"] = DECISION_CONNECT
		plan["reason"] = "fallback_truth_value"
	else:
		plan["decision"] = DECISION_DISCARD
		plan["reason"] = "fallback_truth_value"
	return plan


func _default_plan() -> Dictionary:
	return {
		"decision": DECISION_DISCARD,
		"insert_index": -1,
		"replace_index": -1,
		"score_delta": 0.0,
		"projected_score": 0.0,
		"reason": "default"
	}
