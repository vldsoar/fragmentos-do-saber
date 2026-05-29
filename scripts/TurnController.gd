class_name TurnController
extends RefCounted


func advance_turn(current_turn: int, max_turns: int) -> int:
	return clampi(current_turn + 1, 1, max_turns)


func is_final_turn(current_turn: int, max_turns: int) -> bool:
	return current_turn >= max_turns
