# File: card_resource.gd
class_name CardResource
extends Resource

enum SpecialEffect {
	NONE,
	FLAT_SCORE_BONUS,
	OPPONENT_DISCARD_RANDOM,
	REPLACE_BOARD_CARD
}

enum Rarity {
	COMMON,
	SPECIAL
}

@export var id: String
@export var title: String
@export var description: String

@export var category: String = ""       # CAUSE, PROCESS, CONSEQUENCE, SPECIAL
@export var rarity: Rarity = Rarity.COMMON
@export var effect: SpecialEffect = SpecialEffect.NONE
@export var effect_description: String = ""
@export var truth_value: float = 0.0

@export var bonus_score: float = 0.0    # only for SPECIAL cards
@export var tags: Array[String] = []

@export var feedback: Dictionary = {}   # contains why_true / why_false / tip


static func from_dict(data: Dictionary) -> CardResource:
	var c := CardResource.new()

	c.id = data.get("id", "")
	c.title = data.get("title", "")
	c.description = data.get("description", "")

	c.category = data.get("category", "")
	c.rarity = _rarity_from_string(data.get("rarity", "COMMON").to_upper())
	
	c.effect = _effect_from_string(data.get("effect", "").to_upper())
	c.effect_description = data.get("effect_description", "")
	c.truth_value = float(data.get("truth_value", 0.0))

	c.bonus_score = float(data.get("bonus_score", 0.0))

	# Convert tags
	c.tags.clear()
	for tag in data.get("tags", []):
		c.tags.append(str(tag))

	# Feedback dictionary
	var fb = data.get("feedback", {})
	if fb is Dictionary:
		c.feedback = fb.duplicate(true)
	else:
		c.feedback = {}

	return c

static func _effect_from_string(effect_str: String) -> SpecialEffect:
	match effect_str:
		"FLAT_SCORE_BONUS":
			return SpecialEffect.FLAT_SCORE_BONUS
		"OPPONENT_DISCARD_RANDOM":
			return SpecialEffect.OPPONENT_DISCARD_RANDOM
		"REPLACE_BOARD_CARD":
			return SpecialEffect.REPLACE_BOARD_CARD
		_:
			return SpecialEffect.NONE

static func _rarity_from_string(rarity_str: String) -> Rarity:
	match rarity_str:
		"COMMON":
			return Rarity.COMMON
		"SPECIAL":
			return Rarity.SPECIAL
		_:
			return Rarity.COMMON
