class_name TeacherAnalysisPanel
extends PanelContainer

var _tabs: TabContainer


func _ready() -> void:
	custom_minimum_size = Vector2(0, 300)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_stylebox_override("panel", ThemeManager.make_panel_style("panel_bg", "panel_border", 6, 1, 18))
	_ensure_tabs()


func show_analysis(
	player_result: ResultGame,
	opponent_result: ResultGame,
	context: Dictionary
) -> void:
	_ensure_tabs()
	_clear_tabs()

	if context.is_empty():
		var unavailable_tab: VBoxContainer = _create_tab("Resumo")
		_add_text(unavailable_tab, "Dados detalhados da partida indisponíveis para análise.")
		return

	var deck_data: Dictionary = _get_context_dictionary(context, "deck_data")
	var player_timeline_ids: Array = _get_context_array(context, "player_timeline_ids")
	var opponent_timeline_ids: Array = _get_context_array(context, "opponent_timeline_ids")
	var player_effect_ids: Array = _get_context_array(context, "player_effect_ids")
	var opponent_effect_ids: Array = _get_context_array(context, "opponent_effect_ids")
	var card_by_id: Dictionary = _build_card_index(deck_data)
	var edge_map: Dictionary = _build_edge_index(deck_data)

	_populate_summary_tab(player_result, opponent_result)
	_populate_cards_tab(player_timeline_ids, player_effect_ids, card_by_id)
	_populate_connections_tab(player_timeline_ids, card_by_id, edge_map)
	_populate_rules_tab(player_timeline_ids, _get_deck_array(deck_data, "constraints"), _get_deck_array(deck_data, "motifs"))
	_populate_opponent_tab(opponent_timeline_ids, opponent_effect_ids, card_by_id)


func _clear_tabs() -> void:
	if _tabs == null:
		return
	for child: Node in _tabs.get_children():
		child.queue_free()


func _ensure_tabs() -> void:
	if _tabs != null:
		return

	_tabs = TabContainer.new()
	_tabs.name = "Tabs"
	_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_tabs)


func _create_tab(title: String) -> VBoxContainer:
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.name = title
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_tabs.add_child(scroll)

	var margin: MarginContainer = MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 12)
	scroll.add_child(margin)

	var box: VBoxContainer = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)
	return box


func _populate_summary_tab(player_result: ResultGame, opponent_result: ResultGame) -> void:
	var tab: VBoxContainer = _create_tab("Resumo")
	_add_header(tab, "Critérios de pontuação")
	_add_text(tab, "Cartas verdadeiras somam +10; parcialmente verdadeiras somam +4; falsas aplicam -8.")
	_add_text(tab, "O contexto usa a compatibilidade entre cartas vizinhas. Motifs concedem bônus para sequências canônicas. Constraints aplicam penalidades para incoerências globais.")

	_add_header(tab, "Comparação com o oponente")
	if opponent_result == null:
		_add_text(tab, "Resultado do oponente indisponível.")
		return

	var score_delta: float = player_result.total_score - opponent_result.total_score
	var coherence_delta: float = player_result.coherence - opponent_result.coherence
	_add_text(tab, "Diferença de pontuação: %s. Diferença de coerência: %s pontos." % [
		_format_signed_score(score_delta),
		_format_signed_score(coherence_delta)
	])

	if player_result.breakdown != null and opponent_result.breakdown != null:
		_add_text(tab, "Cartas %s | Contexto %s | Global %s | Motifs %s | Bônus %s" % [
			_format_signed_score(player_result.breakdown.cards - opponent_result.breakdown.cards),
			_format_signed_score(player_result.breakdown.context - opponent_result.breakdown.context),
			_format_signed_score(player_result.breakdown.global - opponent_result.breakdown.global),
			_format_signed_score(player_result.breakdown.motifs - opponent_result.breakdown.motifs),
			_format_signed_score(player_result.breakdown.bonus - opponent_result.breakdown.bonus),
		])


func _populate_cards_tab(timeline_ids: Array, effect_ids: Array, card_by_id: Dictionary) -> void:
	var tab: VBoxContainer = _create_tab("Cartas")
	if timeline_ids.is_empty():
		_add_text(tab, "Nenhuma carta conectada à timeline.")
	else:
		for index: int in range(timeline_ids.size()):
			var card_id: String = str(timeline_ids[index])
			if not card_by_id.has(card_id):
				continue

			var card_value: Variant = card_by_id[card_id]
			if not (card_value is Dictionary):
				continue

			var card: Dictionary = card_value
			var truth_value: float = float(card.get("truth_value", 0.0))
			var local_score: float = _compute_local_score(truth_value)
			var text: String = "%d. %s [%s] - %s (%s)" % [
				index + 1,
				_get_card_title(card, card_id),
				str(card.get("category", "")),
				_get_truth_label(truth_value),
				_format_signed_score(local_score)
			]

			var explanation: String = _get_card_feedback_explanation(card, truth_value)
			var tip: String = _get_card_tip(card)
			if not explanation.is_empty():
				text += "\n" + explanation
			if not tip.is_empty():
				text += "\nDica: " + tip
			_add_text(tab, text)

	_add_header(tab, "Efeitos")
	if effect_ids.is_empty():
		_add_text(tab, "Nenhum efeito especial aplicado pelo jogador.")
	else:
		_add_text(tab, "Efeitos aplicados: %s" % _format_card_id_list(effect_ids, card_by_id))


func _populate_connections_tab(timeline_ids: Array, card_by_id: Dictionary, edge_map: Dictionary) -> void:
	var tab: VBoxContainer = _create_tab("Conexões")
	if timeline_ids.size() < 2:
		_add_text(tab, "A timeline precisa de pelo menos duas cartas para avaliar conexões.")
		return

	for index: int in range(timeline_ids.size() - 1):
		var from_id: String = str(timeline_ids[index])
		var to_id: String = str(timeline_ids[index + 1])
		var from_title: String = _get_card_title_by_id(from_id, card_by_id)
		var to_title: String = _get_card_title_by_id(to_id, card_by_id)
		var edge: Dictionary = _get_edge(edge_map, from_id, to_id)

		if edge.is_empty():
			_add_text(tab, "%s -> %s: sem edge definida; contexto neutro." % [from_title, to_title])
			continue

		var compatibility: float = float(edge.get("compatibility", 0.0))
		var text: String = "%s -> %s: compatibilidade %.1f (%s)." % [
			from_title,
			to_title,
			compatibility,
			_get_compatibility_label(compatibility)
		]
		var feedback: String = str(edge.get("feedback", ""))
		if not feedback.is_empty():
			text += " " + feedback
		_add_text(tab, text)


func _populate_rules_tab(timeline_ids: Array, constraints: Array, motifs: Array) -> void:
	var tab: VBoxContainer = _create_tab("Regras")
	_add_header(tab, "Constraints")
	if constraints.is_empty():
		_add_text(tab, "Este deck não possui constraints cadastradas.")
	else:
		_add_constraints(tab, timeline_ids, constraints)

	_add_header(tab, "Motifs")
	if motifs.is_empty():
		_add_text(tab, "Este deck não possui motifs cadastrados.")
	else:
		_add_motifs(tab, timeline_ids, motifs)


func _populate_opponent_tab(timeline_ids: Array, effect_ids: Array, card_by_id: Dictionary) -> void:
	var tab: VBoxContainer = _create_tab("Oponente")
	if timeline_ids.is_empty():
		_add_text(tab, "O oponente não conectou cartas à timeline.")
	else:
		_add_text(tab, "Timeline: %s" % _format_card_id_list(timeline_ids, card_by_id))

	if effect_ids.is_empty():
		_add_text(tab, "Nenhum efeito especial aplicado pelo oponente.")
	else:
		_add_text(tab, "Efeitos aplicados: %s" % _format_card_id_list(effect_ids, card_by_id))


func _add_constraints(tab: VBoxContainer, timeline_ids: Array, constraints: Array) -> void:
	var listed_any: bool = false
	for constraint_value: Variant in constraints:
		if not (constraint_value is Dictionary):
			continue

		var constraint: Dictionary = constraint_value
		var ctype: String = str(constraint.get("type", ""))
		var violated: bool = false

		match ctype:
			"ORDER":
				violated = _violates_order_constraint(constraint, timeline_ids)
			"MUTUAL_EXCLUSION":
				violated = _violates_mutual_exclusion(constraint, timeline_ids)
			_:
				continue

		listed_any = true
		var penalty: float = float(constraint.get("penalty", 0.0))
		var label: String = "Violada" if violated else "Cumprida"
		var text: String = "%s: %s" % [str(constraint.get("id", ctype)), label]
		if violated:
			text += " (%s)" % _format_signed_score(-penalty)

		var feedback: String = str(constraint.get("feedback_if_violate", ""))
		if not feedback.is_empty():
			text += ". " + feedback
		_add_text(tab, text)

	if not listed_any:
		_add_text(tab, "Nenhuma constraint compatível com a análise atual foi encontrada.")


func _add_motifs(tab: VBoxContainer, timeline_ids: Array, motifs: Array) -> void:
	var completed_count: int = 0
	for motif_value: Variant in motifs:
		if not (motif_value is Dictionary):
			continue

		var motif: Dictionary = motif_value
		var nodes: Array = _get_dictionary_array(motif, "nodes")
		if nodes.is_empty():
			continue

		var completed: bool = _contains_sequence(timeline_ids, nodes)
		var score_factor: float = float(motif.get("score", 0.0))
		var label: String = "Completo" if completed else "Não formado"
		var text: String = "%s: %s" % [str(motif.get("id", "Motif")), label]

		if completed:
			completed_count += 1
			text += " (%s)" % _format_signed_score(30.0 * score_factor)

		var feedback: String = str(motif.get("feedback", ""))
		if not feedback.is_empty():
			text += ". " + feedback
		_add_text(tab, text)

	if completed_count == 0:
		_add_text(tab, "Nenhum arco canônico foi completado na ordem exata.")


func _add_header(parent: VBoxContainer, text: String) -> void:
	var lbl: Label = Label.new()
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 17)
	ThemeManager.apply_label(lbl, "teacher_header", "body_bold")
	parent.add_child(lbl)


func _add_text(parent: VBoxContainer, text: String) -> void:
	if text.strip_edges().is_empty():
		return

	var lbl: Label = Label.new()
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	ThemeManager.apply_label(lbl, "body", "body")
	lbl.text = text
	parent.add_child(lbl)


func _get_context_dictionary(context: Dictionary, key: String) -> Dictionary:
	var value: Variant = context.get(key, {})
	if value is Dictionary:
		return value
	return {}


func _get_context_array(context: Dictionary, key: String) -> Array:
	var value: Variant = context.get(key, [])
	if value is Array:
		return value
	return []


func _get_deck_array(deck_data: Dictionary, key: String) -> Array:
	var value: Variant = deck_data.get(key, [])
	if value is Array:
		return value
	return []


func _get_dictionary_array(data: Dictionary, key: String) -> Array:
	var value: Variant = data.get(key, [])
	if value is Array:
		return value
	return []


func _build_card_index(deck_data: Dictionary) -> Dictionary:
	var index: Dictionary = {}
	for card_value: Variant in _get_deck_array(deck_data, "cards"):
		if not (card_value is Dictionary):
			continue
		var card: Dictionary = card_value
		var card_id: String = str(card.get("id", ""))
		if not card_id.is_empty():
			index[card_id] = card
	return index


func _build_edge_index(deck_data: Dictionary) -> Dictionary:
	var edge_map: Dictionary = {}
	for edge_value: Variant in _get_deck_array(deck_data, "edges"):
		if not (edge_value is Dictionary):
			continue

		var edge: Dictionary = edge_value
		var from_id: String = str(edge.get("from", ""))
		var to_id: String = str(edge.get("to", ""))
		if from_id.is_empty() or to_id.is_empty():
			continue

		if not edge_map.has(from_id):
			edge_map[from_id] = {}

		var inner_value: Variant = edge_map[from_id]
		if not (inner_value is Dictionary):
			continue

		var inner: Dictionary = inner_value
		inner[to_id] = edge
	return edge_map


func _get_edge(edge_map: Dictionary, from_id: String, to_id: String) -> Dictionary:
	if not edge_map.has(from_id):
		return {}

	var inner_value: Variant = edge_map[from_id]
	if not (inner_value is Dictionary):
		return {}

	var inner: Dictionary = inner_value
	if not inner.has(to_id):
		return {}

	var edge_value: Variant = inner[to_id]
	if edge_value is Dictionary:
		return edge_value
	return {}


func _compute_local_score(truth_value: float) -> float:
	if truth_value >= 0.99:
		return 10.0
	if truth_value >= 0.49:
		return 4.0
	return -8.0


func _get_truth_label(truth_value: float) -> String:
	if truth_value >= 0.99:
		return "verdadeira"
	if truth_value >= 0.49:
		return "parcial"
	return "falsa"


func _get_compatibility_label(compatibility: float) -> String:
	if compatibility >= 0.8:
		return "forte"
	if compatibility >= 0.3:
		return "plausível"
	return "fraca"


func _get_card_title(card: Dictionary, fallback_id: String) -> String:
	return str(card.get("title", fallback_id))


func _get_card_title_by_id(card_id: String, card_by_id: Dictionary) -> String:
	if not card_by_id.has(card_id):
		return card_id

	var card_value: Variant = card_by_id[card_id]
	if card_value is Dictionary:
		var card: Dictionary = card_value
		return _get_card_title(card, card_id)
	return card_id


func _get_card_feedback_explanation(card: Dictionary, truth_value: float) -> String:
	var feedback_value: Variant = card.get("feedback", {})
	if not (feedback_value is Dictionary):
		return ""

	var feedback: Dictionary = feedback_value
	if truth_value >= 0.99:
		return str(feedback.get("why_true", ""))
	if truth_value >= 0.49:
		return str(feedback.get("why_partial", ""))
	return str(feedback.get("why_false", ""))


func _get_card_tip(card: Dictionary) -> String:
	var feedback_value: Variant = card.get("feedback", {})
	if feedback_value is Dictionary:
		var feedback: Dictionary = feedback_value
		return str(feedback.get("tip", ""))
	return ""


func _format_card_id_list(ids: Array, card_by_id: Dictionary) -> String:
	var text: String = ""
	for id_value: Variant in ids:
		var card_id: String = str(id_value)
		if not text.is_empty():
			text += ", "
		text += _get_card_title_by_id(card_id, card_by_id)
	return text


func _contains_sequence(timeline_ids: Array, sequence: Array) -> bool:
	if sequence.is_empty() or timeline_ids.size() < sequence.size():
		return false

	for index: int in range(timeline_ids.size() - sequence.size() + 1):
		var matches: bool = true
		for seq_index: int in range(sequence.size()):
			if str(timeline_ids[index + seq_index]) != str(sequence[seq_index]):
				matches = false
				break
		if matches:
			return true
	return false


func _violates_order_constraint(constraint: Dictionary, timeline_ids: Array) -> bool:
	var required_before: Array = _get_dictionary_array(constraint, "required_before")
	var required_after: Array = _get_dictionary_array(constraint, "required_after")
	if required_before.is_empty() or required_after.is_empty():
		return false

	var before_id: String = str(required_before[0])
	var after_id: String = str(required_after[0])
	var before_index: int = timeline_ids.find(before_id)
	var after_index: int = timeline_ids.find(after_id)

	if before_index == -1 or after_index == -1:
		return false
	return before_index > after_index


func _violates_mutual_exclusion(constraint: Dictionary, timeline_ids: Array) -> bool:
	var nodes_a: Array = _get_dictionary_array(constraint, "nodes_a")
	var nodes_b: Array = _get_dictionary_array(constraint, "nodes_b")
	var has_a: bool = false
	var has_b: bool = false

	for id_value: Variant in timeline_ids:
		var card_id: String = str(id_value)
		if nodes_a.has(card_id):
			has_a = true
		if nodes_b.has(card_id):
			has_b = true
	return has_a and has_b


func _format_signed_score(value: float) -> String:
	if value > 0.0:
		return "+%.1f" % value
	return "%.1f" % value
