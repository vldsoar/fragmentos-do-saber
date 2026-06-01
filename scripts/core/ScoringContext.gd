class_name ScoringContext
extends RefCounted

var deck_data: Dictionary = {}
var timeline_ids: Array = []
var effect_card_ids: Array = []


static func create(
	p_deck_data: Dictionary,
	p_timeline_ids: Array,
	p_effect_card_ids: Array = []
) -> ScoringContext:
	var context: ScoringContext = ScoringContext.new()
	context.deck_data = p_deck_data
	context.timeline_ids = p_timeline_ids
	context.effect_card_ids = p_effect_card_ids
	return context
