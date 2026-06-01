class_name MatchResultController
extends RefCounted

var _scoring_engine: CoherenceScoringEngine = CoherenceScoringEngine.new()


func build_match_result(
	deck_data: Dictionary,
	player_timeline_ids: Array,
	opponent_timeline_ids: Array,
	player_effect_ids: Array,
	opponent_effect_ids: Array
) -> Dictionary:
	var player_context: ScoringContext = ScoringContext.create(deck_data, player_timeline_ids, player_effect_ids)
	var opponent_context: ScoringContext = ScoringContext.create(deck_data, opponent_timeline_ids, opponent_effect_ids)
	var player_result: ResultGame = _scoring_engine.evaluate_context(player_context)
	var opponent_result: ResultGame = _scoring_engine.evaluate_context(opponent_context)

	return {
		"player_result": player_result,
		"opponent_result": opponent_result,
		"did_win": player_result.compare_with(opponent_result) == 1,
		"teacher_context": {
			"deck_data": deck_data,
			"player_timeline_ids": player_timeline_ids,
			"opponent_timeline_ids": opponent_timeline_ids,
			"player_effect_ids": player_effect_ids,
			"opponent_effect_ids": opponent_effect_ids,
		}
	}
