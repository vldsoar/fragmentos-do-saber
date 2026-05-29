# File: result_game.gd
class_name ResultGame
extends RefCounted

var total_score: float = 0.0
var coherence: float = 0.0
var breakdown: ResultGame.BreakdownScore
var feedback: Array[String] = []


## Compares this instance with another and returns which has the greater result
## Returns: 1 if this instance is greater, -1 if the other is greater, 0 if they are equal
func compare_with(other: ResultGame) -> int:
	if other == null:
		return 1
	
	# Main criterion: total_score
	if total_score > other.total_score:
		return 1
	elif total_score < other.total_score:
		return -1
	
	# Secondary criterion: coherence (in case of tie in total_score)
	if coherence > other.coherence:
		return 1
	elif coherence < other.coherence:
		return -1
	
	# If both are equal
	return 0


## Static method that returns which of the two instances has the greater result
## Returns the instance with the greater result, or null if both are null
static func get_greater(result1: ResultGame, result2: ResultGame) -> ResultGame:
	if result1 == null and result2 == null:
		return null
	if result1 == null:
		return result2
	if result2 == null:
		return result1
	
	var comparison = result1.compare_with(result2)
	if comparison > 0:
		return result1
	elif comparison < 0:
		return result2
	else:
		# In case of tie, return the first
		return result1


class BreakdownScore:
	var cards: float = 0.0
	var context: float = 0.0
	var global: float = 0.0
	var motifs: float = 0.0
	var bonus: float = 0.0
