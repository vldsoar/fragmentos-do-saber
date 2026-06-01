class_name TurnController
extends RefCounted

#// SAFE_TURN_BUDGET_PERCENTAGE := 0.6


## Define a duracao da partida a partir do tamanho do deck.
## Cada jogador usa uma copia propria do deck e compra uma carta por turno.
## A regra usa metade do deck como orcamento seguro para preservar variedade,
## evitar esgotamento e ainda permitir partidas curtas, padrao e longas.
## Como a duracao minima e 8 turnos, o deck recomendado minimo tem 16 cartas.
func calculate_max_turns(deck_card_count: int) -> int:
	if deck_card_count < Globals.MIN_TURNS:
		push_warning("Deck com %d cartas; o jogo precisa de pelo menos %d para uma partida minima." % [deck_card_count, Globals.MIN_TURNS])
		return maxi(deck_card_count, 1)

	if deck_card_count < Globals.MIN_DECK_CARDS:
		push_warning("Deck com %d cartas; o minimo recomendado e %d para preservar metade do deck." % [deck_card_count, Globals.MIN_DECK_CARDS])
		return Globals.MIN_TURNS

	var safe_turn_budget: int = floori(float(deck_card_count) * 0.6)
	if safe_turn_budget >= Globals.LONG_TURNS:
		return Globals.LONG_TURNS
	if safe_turn_budget >= Globals.DEFAULT_TURNS:
		return Globals.DEFAULT_TURNS
	return Globals.MIN_TURNS


func advance_turn(current_turn: int, max_turns: int) -> int:
	return clampi(current_turn + 1, 1, max_turns)


func is_final_turn(current_turn: int, max_turns: int) -> bool:
	return current_turn >= max_turns
