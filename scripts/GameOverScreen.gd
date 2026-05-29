class_name GameOverScreen
extends Control

signal play_again_pressed
signal exit_pressed
signal review_timeline_pressed

@onready var title_label: Label = $CenterContainer/PanelContainer/MarginContainer/RootVBox/TitleLabel
@onready var summary_label: Label = $CenterContainer/PanelContainer/MarginContainer/RootVBox/SummaryLabel

@onready var total_score_value: Label = $CenterContainer/PanelContainer/MarginContainer/RootVBox/MainScoreBox/TotalScoreVBox/TotalScoreValue
@onready var coherence_value: Label = $CenterContainer/PanelContainer/MarginContainer/RootVBox/MainScoreBox/CoherenceVBox/CoherenceValue
@onready var opponent_score_label: Label = $CenterContainer/PanelContainer/MarginContainer/RootVBox/MainScoreBox/OpponentScoreVBox/OpponentScoreLabel
@onready var opponent_score_value: Label = $CenterContainer/PanelContainer/MarginContainer/RootVBox/MainScoreBox/OpponentScoreVBox/OpponentScoreValue
@onready var opponent_coherence_value: Label = $CenterContainer/PanelContainer/MarginContainer/RootVBox/MainScoreBox/OpponentScoreVBox/OpponentCoherenceValue

@onready var cards_score_value: Label = $CenterContainer/PanelContainer/MarginContainer/RootVBox/BreakdownGrid/CardsScoreValue
@onready var context_score_value: Label = $CenterContainer/PanelContainer/MarginContainer/RootVBox/BreakdownGrid/ContextScoreValue
@onready var global_score_value: Label = $CenterContainer/PanelContainer/MarginContainer/RootVBox/BreakdownGrid/GlobalScoreValue
@onready var motifs_score_value: Label = $CenterContainer/PanelContainer/MarginContainer/RootVBox/BreakdownGrid/MotifsScoreValue
@onready var bonus_score_value: Label = $CenterContainer/PanelContainer/MarginContainer/RootVBox/BreakdownGrid/BonusScoreValue

@onready var feedback_title_label: Label = $CenterContainer/PanelContainer/MarginContainer/RootVBox/FeedbackTitleLabel
@onready var feedback_container: VBoxContainer = $CenterContainer/PanelContainer/MarginContainer/RootVBox/ScrollContainer/FeedbackContainer

@onready var review_timeline_button: Button = $CenterContainer/PanelContainer/MarginContainer/RootVBox/ButtonsBox/ReviewTimelineButton
@onready var play_again_button: Button = $CenterContainer/PanelContainer/MarginContainer/RootVBox/ButtonsBox/PlayAgainButton
@onready var exit_button: Button = $CenterContainer/PanelContainer/MarginContainer/RootVBox/ButtonsBox/ExitButton


func _ready() -> void:
	visible = false

	#review_timeline_button.pressed.connect(_on_review_timeline_button_pressed)
	play_again_button.pressed.connect(_on_play_again_button_pressed)
	exit_button.pressed.connect(_on_exit_button_pressed)


func show_result(result: ResultGame, did_win: bool = true, opponent_result: ResultGame = null) -> void:
	visible = true

	# ---- Título dinâmico ----
	var comparison: int = 1 if did_win else -1
	if opponent_result != null:
		comparison = result.compare_with(opponent_result)

	if comparison > 0:
		title_label.text = "Missão concluída!"
		summary_label.text = "Você venceu o oponente. Veja a análise da sua linha do tempo:"
	elif comparison < 0:
		title_label.text = "Fim da partida"
		summary_label.text = "O oponente venceu esta rodada. Reveja os pontos de coerência para a próxima tentativa."
	else:
		title_label.text = "Empate"
		summary_label.text = "As linhas do tempo ficaram equilibradas. Pequenas escolhas podem decidir a próxima partida."

	# ---- Scores principais ----
	total_score_value.text = _format_score(result.total_score)
	coherence_value.text = "%s / 100" % _format_score(result.coherence)
	_update_opponent_score(opponent_result)

	# ---- Breakdown ----
	var breakdown: ResultGame.BreakdownScore = result.breakdown
	if breakdown:
		cards_score_value.text = _format_score(breakdown.cards)
		context_score_value.text = _format_score(breakdown.context)
		global_score_value.text = _format_score(breakdown.global)
		motifs_score_value.text = _format_score(breakdown.motifs)
		bonus_score_value.text = _format_score(breakdown.bonus)
	else:
		cards_score_value.text = "0"
		context_score_value.text = "0"
		global_score_value.text = "0"
		motifs_score_value.text = "0"
		bonus_score_value.text = "0"

	# ---- Feedback (array) ----
	_populate_feedback(result.feedback)


func _populate_feedback(feedback_array: Array) -> void:
	# Remove feedback antigo
	for child: Node in feedback_container.get_children():
		child.queue_free()

	var has_feedback: bool = false

	for item: Variant in feedback_array:
		var text: String = ""

		match typeof(item):
			TYPE_STRING:
				text = str(item)
			TYPE_DICTIONARY:
				var item_dict: Dictionary = item
				var msg: String = str(item_dict.get("message", ""))
				var tip: String = str(item_dict.get("tip", ""))
				text = msg
				if tip != "":
					text += " (Dica: %s)" % tip
			_:
				text = str(item)

		if text.strip_edges() != "":
			has_feedback = true
			var lbl: Label = Label.new()
			lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
			lbl.text = "- " + text
			feedback_container.add_child(lbl)

	if has_feedback:
		feedback_title_label.text = "O que pode melhorar:"
	else:
		feedback_title_label.text = "Nenhum erro crítico detectado"
		var lbl: Label = Label.new()
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		lbl.text = "Sua narrativa manteve coerência histórica nesta rodada. Excelente!"
		feedback_container.add_child(lbl)


func _update_opponent_score(opponent_result: ResultGame) -> void:
	if opponent_result == null:
		opponent_score_label.text = "Oponente"
		opponent_score_value.text = "-"
		opponent_coherence_value.text = "-"
		return

	opponent_score_label.text = "Oponente"
	opponent_score_value.text = _format_score(opponent_result.total_score)
	opponent_coherence_value.text = "Coerência %s / 100" % _format_score(opponent_result.coherence)


func _format_score(value: float) -> String:
	return "%.1f" % value


# ---- Botões ----

#func _on_review_timeline_button_pressed() -> void:
	#review_timeline_pressed.emit()

func _on_play_again_button_pressed() -> void:
	UISoundManager.play_button_click()
	play_again_pressed.emit()

func _on_exit_button_pressed() -> void:
	UISoundManager.play_button_click()
	exit_pressed.emit()
