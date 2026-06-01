# File: coherence_scoring_engine.gd
class_name CoherenceScoringEngine
extends Object

## Engine de pontuação por coerência para Fragmentos do Saber.
##
## Uso:
##   var engine = CoherenceScoringEngine.new()
##   var result = engine.evaluate_timeline(deck_data, ["FR001", "FR004", "FR005", "FR006"], ["SP001"])
##
## deck_data: Dictionary carregado a partir do JSON do deck.
## timeline_ids: Array de IDs de cartas na ordem escolhida pelo jogador.

func evaluate_context(context: ScoringContext) -> ResultGame:
	if context == null:
		return ResultGame.new()
	return evaluate_timeline(context.deck_data, context.timeline_ids, context.effect_card_ids)


func evaluate_timeline(deck_data: Dictionary, timeline_ids: Array, effect_card_ids: Array = []) -> ResultGame:
	var card_by_id := _build_card_index(deck_data)
	var edge_map := _build_edge_index(deck_data)
	var constraints: Array = deck_data.get("constraints", [])
	var motifs: Array = deck_data.get("motifs", [])

	var score_cards := 0.0
	var score_context := 0.0
	var score_global := 0.0
	var score_motifs := 0.0
	var score_bonus := 0.0
	var feedback: Array[String] = []

	# 1) Pontuação local + contextual
	for i in range(timeline_ids.size()):
		var card_id = timeline_ids[i]
		if not card_by_id.has(card_id):
			continue

		var card: Dictionary = card_by_id[card_id]
		var truth_value := float(card.get("truth_value", 0.0))

		# 1.1 Local
		var local_score := _compute_local_score(truth_value)
		score_cards += local_score

		var card_feedback: Dictionary = card.get("feedback", {})
		if truth_value == 0.0 and card_feedback.has("why_false"):
			feedback.append(str(card_feedback["why_false"]))
		elif truth_value == 0.5 and card_feedback.has("why_partial"):
			feedback.append(str(card_feedback["why_partial"]))

		# 1.2 Contexto (compatibilidade com vizinhos)
		var prev_compat := _get_edge_compat(edge_map, timeline_ids, i - 1, i)
		var next_compat := _get_edge_compat(edge_map, timeline_ids, i, i + 1)

		var context := _compute_context(prev_compat, next_compat)
		var context_score := _compute_context_score(truth_value, context)
		score_context += context_score

		# feedback simples para conexões muito fracas
		if prev_compat >= 0.0 and prev_compat <= 0.2 and i > 0:
			var prev_card: Dictionary = card_by_id[timeline_ids[i - 1]]
			feedback.append("A conexão entre '%s' e '%s' é muito fraca ou não canônica." % [
				str(prev_card.get("title", prev_card.get("id", ""))),
				str(card.get("title", card_id))
			])

	# 2) Motifs (mini-arcos)
	score_motifs += _evaluate_motifs(motifs, timeline_ids, feedback)

	# 3) Constraints globais
	score_global += _evaluate_constraints(constraints, timeline_ids, feedback)

	# 4) Bônus de cartas especiais
	score_bonus += _evaluate_special_bonus(card_by_id, effect_card_ids, timeline_ids)

	var total_score := score_cards + score_context + score_global + score_motifs + score_bonus

	# Normalização opcional
	var max_score_hint := float(deck_data.get("max_score_hint", 100.0))
	var coherence: float = clampf((total_score / max_score_hint) * 100.0, 0.0, 100.0)

	var result := ResultGame.new()
	result.total_score = total_score
	result.coherence = coherence
	result.feedback = feedback
	
	var breakdown := ResultGame.BreakdownScore.new()
	breakdown.cards = score_cards
	breakdown.context = score_context
	breakdown.global = score_global
	breakdown.motifs = score_motifs
	breakdown.bonus = score_bonus
	result.breakdown = breakdown

	return result


# -----------------------
# Helpers de construção
# -----------------------

func _build_card_index(deck_data: Dictionary) -> Dictionary:
	var index := {}
	for card in deck_data.get("cards", []):
		if card is Dictionary and card.has("id"):
			index[card["id"]] = card
	return index


func _build_edge_index(deck_data: Dictionary) -> Dictionary:
	# edge_map[from_id][to_id] = edge_dict
	var edge_map := {}
	for edge in deck_data.get("edges", []):
		if not (edge is Dictionary):
			continue
		if not (edge.has("from") and edge.has("to")):
			continue
		var from_id = edge["from"]
		var to_id = edge["to"]
		if not edge_map.has(from_id):
			edge_map[from_id] = {}
		edge_map[from_id][to_id] = edge
	return edge_map


# -----------------------
# Cálculos locais/contexto
# -----------------------

func _compute_local_score(truth_value: float) -> float:
	if truth_value >= 0.99:
		return 10.0
	elif truth_value >= 0.49:
		return 4.0
	else:
		return -8.0


func _get_edge_compat(edge_map: Dictionary, timeline_ids: Array, from_idx: int, to_idx: int) -> float:
	if from_idx < 0 or to_idx < 0:
		return -1.0
	if from_idx >= timeline_ids.size() or to_idx >= timeline_ids.size():
		return -1.0

	var from_id = timeline_ids[from_idx]
	var to_id = timeline_ids[to_idx]

	if not edge_map.has(from_id):
		return -1.0
	var inner: Dictionary = edge_map[from_id]
	if not inner.has(to_id):
		return -1.0

	var edge: Dictionary = inner[to_id]
	return float(edge.get("compatibility", 0.0))


func _compute_context(prev_compat: float, next_compat: float) -> float:
	var values: Array[float] = []
	if prev_compat >= 0.0:
		values.append(prev_compat)
	if next_compat >= 0.0:
		values.append(next_compat)

	if values.is_empty():
		return 0.5  # neutro

	var sum := 0.0
	for v in values:
		sum += v
	return sum / values.size()


func _compute_context_score(truth_value: float, context: float) -> float:
	if truth_value >= 0.99:
		# carta verdadeira em contexto forte ganha bônus maior
		return 6.0 * context
	elif truth_value >= 0.49:
		# parcial: ajuste fino
		return 3.0 * (context - 0.5)
	else:
		# falsa: quanto mais coerente o entorno, maior a penalidade
		return -6.0 * context


# -----------------------
# Motifs
# -----------------------

func _evaluate_motifs(motifs: Array, timeline_ids: Array, feedback: Array) -> float:
	var total := 0.0

	for motif in motifs:
		if not (motif is Dictionary):
			continue
		var nodes: Array = motif.get("nodes", [])
		if nodes.is_empty():
			continue
		var score_factor := float(motif.get("score", 0.0))
		if score_factor == 0.0:
			continue

		# Procura a sequência exata nodes dentro da timeline
		for i in range(timeline_ids.size() - nodes.size() + 1):
			var slice := timeline_ids.slice(i, i + nodes.size())
			if _arrays_equal(slice, nodes):
				var inc := 30.0 * score_factor
				total += inc
				var motif_feedback = motif.get("feedback", null)
				if motif_feedback != null:
					feedback.append(str(motif_feedback))
				# se quiser permitir múltiplas ocorrências, não dê break
				break

	return total


func _arrays_equal(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for i in range(a.size()):
		if a[i] != b[i]:
			return false
	return true


# -----------------------
# Constraints globais
# -----------------------

func _evaluate_constraints(constraints: Array, timeline_ids: Array, feedback: Array) -> float:
	var total := 0.0

	for constraint in constraints:
		if not (constraint is Dictionary):
			continue

		var ctype := str(constraint.get("type", ""))
		var penalty := float(constraint.get("penalty", 10.0))
		var violated := false

		match ctype:
			"ORDER":
				violated = _violates_order_constraint(constraint, timeline_ids)
			"MUTUAL_EXCLUSION":
				violated = _violates_mutual_exclusion(constraint, timeline_ids)
			_:
				violated = false

		if violated:
			total -= penalty
			var fb = constraint.get("feedback_if_violate", null)
			if fb != null:
				feedback.append(str(fb))

	return total


func _violates_order_constraint(constraint: Dictionary, timeline_ids: Array) -> bool:
	var required_before: Array = constraint.get("required_before", [])
	var required_after: Array = constraint.get("required_after", [])

	if required_before.is_empty() or required_after.is_empty():
		return false

	# Usa o primeiro de cada lista por simplicidade (pode ser estendido)
	var before_id = required_before[0]
	var after_id = required_after[0]

	var before_index := timeline_ids.find(before_id)
	var after_index := timeline_ids.find(after_id)

	if before_index == -1 or after_index == -1:
		# se algum não estiver na timeline, não consideramos violação
		return false

	return before_index > after_index  # viola se o "before" aparece depois


func _violates_mutual_exclusion(constraint: Dictionary, timeline_ids: Array) -> bool:
	var nodes_a: Array = constraint.get("nodes_a", [])
	var nodes_b: Array = constraint.get("nodes_b", [])

	var has_a := false
	var has_b := false

	for id in timeline_ids:
		if id in nodes_a:
			has_a = true
		if id in nodes_b:
			has_b = true

	return has_a and has_b


# -----------------------
# Cartas especiais (bônus)
# -----------------------

func _evaluate_special_bonus(card_by_id: Dictionary, effect_card_ids: Array, timeline_ids: Array) -> float:
	var ids_to_score := effect_card_ids
	if ids_to_score.is_empty():
		# Fallback: keep old behavior scoring by timeline presence if no effect cards provided.
		ids_to_score = timeline_ids

	var total := 0.0
	for id in ids_to_score:
		if not card_by_id.has(id):
			continue
		var card: Dictionary = card_by_id[id]
		var effect_value = card.get("effect", "")
		var effect_matches := false

		if effect_value is int:
			effect_matches = effect_value == CardResource.SpecialEffect.FLAT_SCORE_BONUS
		else:
			effect_matches = str(effect_value) == "FLAT_SCORE_BONUS"

		# Support legacy decks that only flag category instead of effect type.
		if effect_matches or str(card.get("category", "")) == "SPECIAL":
			total += float(card.get("bonus_score", 0.0))
	return total
