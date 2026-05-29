class_name DeckRepository
extends Object

const REQUIRED_KEYS: Array[String] = ["cards", "edges"]


static func load_deck_data(deck_path: String) -> Dictionary:
	if deck_path.is_empty():
		push_error("DeckRepository: caminho do deck vazio.")
		return {}

	var file: FileAccess = FileAccess.open(deck_path, FileAccess.READ)
	if file == null:
		push_error("DeckRepository: erro ao abrir deck em %s" % deck_path)
		return {}

	var raw_text: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(raw_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("DeckRepository: JSON invalido em %s" % deck_path)
		return {}

	var deck_data: Dictionary = parsed
	if not is_valid_deck_data(deck_data):
		push_error("DeckRepository: deck invalido em %s" % deck_path)
		return {}

	return deck_data


static func load_selected_deck_data() -> Dictionary:
	var selected_deck: Dictionary = GameSession.selected_deck
	var deck_path: String = selected_deck.get("path", "")
	return load_deck_data(deck_path)


static func build_card_resources(deck_data: Dictionary) -> Array[CardResource]:
	var resources: Array[CardResource] = []
	var cards_data: Array = deck_data.get("cards", [])

	for card_data: Variant in cards_data:
		if typeof(card_data) != TYPE_DICTIONARY:
			continue
		var card_dict: Dictionary = card_data
		resources.append(CardResource.from_dict(card_dict))

	return resources


static func is_valid_deck_data(deck_data: Dictionary) -> bool:
	for key: String in REQUIRED_KEYS:
		if not deck_data.has(key):
			push_error("DeckRepository: deck sem chave obrigatoria '%s'." % key)
			return false
		if typeof(deck_data[key]) != TYPE_ARRAY:
			push_error("DeckRepository: chave '%s' deve ser Array." % key)
			return false

	var card_ids: Dictionary = _collect_card_ids(deck_data.get("cards", []))
	if card_ids.is_empty():
		push_error("DeckRepository: deck sem cartas validas.")
		return false

	if not _validate_edges(deck_data.get("edges", []), card_ids):
		return false
	if not _validate_constraints(deck_data.get("constraints", []), card_ids):
		return false
	if not _validate_motifs(deck_data.get("motifs", []), card_ids):
		return false

	return true


static func _collect_card_ids(cards_data: Array) -> Dictionary:
	var card_ids: Dictionary = {}

	for card_data: Variant in cards_data:
		if typeof(card_data) != TYPE_DICTIONARY:
			push_error("DeckRepository: entrada de carta deve ser Dictionary.")
			return {}

		var card: Dictionary = card_data
		var card_id: String = str(card.get("id", ""))
		if card_id.is_empty():
			push_error("DeckRepository: carta sem id.")
			return {}
		if card_ids.has(card_id):
			push_error("DeckRepository: id de carta duplicado '%s'." % card_id)
			return {}

		card_ids[card_id] = true

	return card_ids


static func _validate_edges(edges_data: Array, card_ids: Dictionary) -> bool:
	for edge_data: Variant in edges_data:
		if typeof(edge_data) != TYPE_DICTIONARY:
			push_error("DeckRepository: edge deve ser Dictionary.")
			return false

		var edge: Dictionary = edge_data
		var from_id: String = str(edge.get("from", ""))
		var to_id: String = str(edge.get("to", ""))

		if not card_ids.has(from_id):
			push_error("DeckRepository: edge aponta from inexistente '%s'." % from_id)
			return false
		if not card_ids.has(to_id):
			push_error("DeckRepository: edge aponta to inexistente '%s'." % to_id)
			return false

	return true


static func _validate_constraints(constraints_data: Array, card_ids: Dictionary) -> bool:
	for constraint_data: Variant in constraints_data:
		if typeof(constraint_data) != TYPE_DICTIONARY:
			push_error("DeckRepository: constraint deve ser Dictionary.")
			return false

		var constraint: Dictionary = constraint_data
		var ctype: String = str(constraint.get("type", ""))

		match ctype:
			"ORDER":
				if constraint.has("required_before") or constraint.has("required_after"):
					if not _validate_node_list(constraint.get("required_before", []), card_ids, "required_before"):
						return false
					if not _validate_node_list(constraint.get("required_after", []), card_ids, "required_after"):
						return false
				elif constraint.has("nodes_a") or constraint.has("nodes_b"):
					if not _validate_node_list(constraint.get("nodes_a", []), card_ids, "nodes_a"):
						return false
					if not _validate_node_list(constraint.get("nodes_b", []), card_ids, "nodes_b"):
						return false
				else:
					push_error("DeckRepository: ORDER sem campos de ordem validos.")
					return false
			"MUTUAL_EXCLUSION":
				if not _validate_node_list(constraint.get("nodes_a", []), card_ids, "nodes_a"):
					return false
				if not _validate_node_list(constraint.get("nodes_b", []), card_ids, "nodes_b"):
					return false
			"COVERAGE":
				continue
			_:
				push_error("DeckRepository: tipo de constraint desconhecido '%s'." % ctype)
				return false

	return true


static func _validate_motifs(motifs_data: Array, card_ids: Dictionary) -> bool:
	for motif_data: Variant in motifs_data:
		if typeof(motif_data) != TYPE_DICTIONARY:
			push_error("DeckRepository: motif deve ser Dictionary.")
			return false

		var motif: Dictionary = motif_data
		if not _validate_node_list(motif.get("nodes", []), card_ids, "motif.nodes"):
			return false

	return true


static func _validate_node_list(nodes_data: Variant, card_ids: Dictionary, field_name: String) -> bool:
	if typeof(nodes_data) != TYPE_ARRAY:
		push_error("DeckRepository: campo '%s' deve ser Array." % field_name)
		return false

	var nodes: Array = nodes_data
	for node_id_value: Variant in nodes:
		var node_id: String = str(node_id_value)
		if not card_ids.has(node_id):
			push_error("DeckRepository: campo '%s' aponta id inexistente '%s'." % [field_name, node_id])
			return false

	return true
