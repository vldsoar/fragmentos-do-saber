class_name GameOverScreen
extends Control

const TEACHER_ANALYSIS_PANEL_SCENE: PackedScene = preload("res://scenes/TeacherAnalysisPanel.tscn")

signal play_again_pressed
signal exit_pressed
signal review_timeline_pressed

@onready var title_label: Label = $CenterContainer/PanelContainer/MarginContainer/RootVBox/TitleLabel
@onready var summary_label: Label = $CenterContainer/PanelContainer/MarginContainer/RootVBox/SummaryLabel
@onready var background_image: TextureRect = $BackgroundImage
@onready var overlay_rect: ColorRect = $ColorRect
@onready var panel_container: PanelContainer = $CenterContainer/PanelContainer
@onready var root_vbox: VBoxContainer = $CenterContainer/PanelContainer/MarginContainer/RootVBox

@onready var total_score_value: Label = $CenterContainer/PanelContainer/MarginContainer/RootVBox/MainScoreBox/TotalScoreVBox/TotalScoreValue
@onready var coherence_value: Label = $CenterContainer/PanelContainer/MarginContainer/RootVBox/MainScoreBox/CoherenceVBox/CoherenceValue
@onready var opponent_score_label: Label = $CenterContainer/PanelContainer/MarginContainer/RootVBox/MainScoreBox/OpponentScoreVBox/OpponentScoreLabel
@onready var opponent_score_value: Label = $CenterContainer/PanelContainer/MarginContainer/RootVBox/MainScoreBox/OpponentScoreVBox/OpponentScoreValue
@onready var opponent_coherence_value: Label = $CenterContainer/PanelContainer/MarginContainer/RootVBox/MainScoreBox/OpponentCoherenceVBox/OpponentCoherenceValue

@onready var cards_score_value: Label = $CenterContainer/PanelContainer/MarginContainer/RootVBox/BreakdownGrid/CardsScoreValue
@onready var context_score_value: Label = $CenterContainer/PanelContainer/MarginContainer/RootVBox/BreakdownGrid/ContextScoreValue
@onready var global_score_value: Label = $CenterContainer/PanelContainer/MarginContainer/RootVBox/BreakdownGrid/GlobalScoreValue
@onready var motifs_score_value: Label = $CenterContainer/PanelContainer/MarginContainer/RootVBox/BreakdownGrid/MotifsScoreValue
@onready var bonus_score_value: Label = $CenterContainer/PanelContainer/MarginContainer/RootVBox/BreakdownGrid/BonusScoreValue

@onready var feedback_title_label: Label = $CenterContainer/PanelContainer/MarginContainer/RootVBox/FeedbackTitleLabel
@onready var feedback_scroll: ScrollContainer = $CenterContainer/PanelContainer/MarginContainer/RootVBox/ScrollContainer
@onready var feedback_container: VBoxContainer = $CenterContainer/PanelContainer/MarginContainer/RootVBox/ScrollContainer/FeedbackContainer

@onready var review_timeline_button: Button = $CenterContainer/PanelContainer/MarginContainer/RootVBox/ButtonsBox/ReviewTimelineButton
@onready var play_again_button: Button = $CenterContainer/PanelContainer/MarginContainer/RootVBox/ButtonsBox/PlayAgainButton
@onready var exit_button: Button = $CenterContainer/PanelContainer/MarginContainer/RootVBox/ButtonsBox/ExitButton

var teacher_analysis_panel: TeacherAnalysisPanel = null


func _ready() -> void:
	visible = false
	_apply_theme()

	#review_timeline_button.pressed.connect(_on_review_timeline_button_pressed)
	play_again_button.pressed.connect(_on_play_again_button_pressed)
	exit_button.pressed.connect(_on_exit_button_pressed)


func _apply_theme() -> void:
	var game_over_texture: Texture2D = ThemeManager.get_texture(ThemeManager.TEXTURE_GAME_OVER_BACKGROUND)
	if game_over_texture != null:
		background_image.texture = game_over_texture

	overlay_rect.color = ThemeManager.get_color(ThemeManager.COLOR_OVERLAY, Color(0, 0, 0, 0.46))
	panel_container.add_theme_stylebox_override("panel", ThemeManager.make_panel_style(ThemeManager.COLOR_PANEL_BG, ThemeManager.COLOR_PANEL_BORDER, 6, 1, 0))

	ThemeManager.apply_label(title_label, ThemeManager.COLOR_TITLE, ThemeManager.FONT_TITLE)
	ThemeManager.apply_label(summary_label, ThemeManager.COLOR_BODY, ThemeManager.FONT_BODY)
	ThemeManager.apply_label(feedback_title_label, ThemeManager.COLOR_TEACHER_HEADER, ThemeManager.FONT_BODY_BOLD)
	ThemeManager.apply_label(total_score_value, ThemeManager.COLOR_SCORE_PRIMARY, ThemeManager.FONT_BODY_BOLD)
	ThemeManager.apply_label(coherence_value, ThemeManager.COLOR_SCORE_SECONDARY, ThemeManager.FONT_BODY_BOLD)
	ThemeManager.apply_label(opponent_score_value, ThemeManager.COLOR_SCORE_OPPONENT, ThemeManager.FONT_BODY_BOLD)
	ThemeManager.apply_label(opponent_coherence_value, ThemeManager.COLOR_SCORE_OPPONENT, ThemeManager.FONT_BODY)
	for score_value: Variant in [
		cards_score_value,
		context_score_value,
		global_score_value,
		motifs_score_value,
		bonus_score_value,
	]:
		ThemeManager.apply_label(score_value as Label, ThemeManager.COLOR_SCORE_PRIMARY, ThemeManager.FONT_BODY)

	for button_value: Variant in [review_timeline_button, play_again_button, exit_button]:
		ThemeManager.apply_button(button_value as Button)

	_apply_font_size_overrides()


func _apply_font_size_overrides() -> void:
	var body_size: int = int(ThemeManager.get_value(ThemeManager.VALUE_GAME_OVER_BODY_FONT_SIZE, 22))
	var feedback_size: int = int(ThemeManager.get_value(ThemeManager.VALUE_GAME_OVER_FEEDBACK_FONT_SIZE, 20))
	summary_label.add_theme_font_size_override("font_size", body_size)
	feedback_title_label.add_theme_font_size_override("font_size", body_size)
	opponent_coherence_value.add_theme_font_size_override("font_size", feedback_size)


func show_result(
	result: ResultGame,
	did_win: bool = true,
	opponent_result: ResultGame = null,
	teacher_context: Dictionary = {}
) -> void:
	visible = true
	feedback_scroll.custom_minimum_size = Vector2(0, 180)

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
	coherence_value.text = _format_percent(result.coherence)
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
	_populate_teacher_analysis(result, opponent_result, teacher_context)


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
			ThemeManager.apply_label(lbl, ThemeManager.COLOR_BODY, ThemeManager.FONT_BODY)
			lbl.add_theme_font_size_override("font_size", int(ThemeManager.get_value(ThemeManager.VALUE_GAME_OVER_FEEDBACK_FONT_SIZE, 20)))
			lbl.text = "- " + text
			feedback_container.add_child(lbl)

	if has_feedback:
		feedback_title_label.text = "O que pode melhorar:"
	else:
		feedback_title_label.text = "Nenhum erro crítico detectado"
		var lbl: Label = Label.new()
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		ThemeManager.apply_label(lbl, ThemeManager.COLOR_BODY, ThemeManager.FONT_BODY)
		lbl.add_theme_font_size_override("font_size", int(ThemeManager.get_value(ThemeManager.VALUE_GAME_OVER_FEEDBACK_FONT_SIZE, 20)))
		lbl.text = "Sua narrativa manteve coerência histórica nesta rodada. Excelente!"
		feedback_container.add_child(lbl)


func _populate_teacher_analysis(
	player_result: ResultGame,
	opponent_result: ResultGame,
	context: Dictionary
) -> void:
	_clear_teacher_analysis_panel()
	if not SettingsManager.teacher_mode_enabled:
		return

	teacher_analysis_panel = TEACHER_ANALYSIS_PANEL_SCENE.instantiate() as TeacherAnalysisPanel
	if teacher_analysis_panel == null:
		push_warning("GameOverScreen: TeacherAnalysisPanel nao pode ser instanciado.")
		return

	var button_index: int = root_vbox.get_children().find(review_timeline_button.get_parent())
	if button_index == -1:
		root_vbox.add_child(teacher_analysis_panel)
	else:
		root_vbox.add_child(teacher_analysis_panel)
		root_vbox.move_child(teacher_analysis_panel, button_index)

	teacher_analysis_panel.show_analysis(player_result, opponent_result, context)


func _clear_teacher_analysis_panel() -> void:
	if teacher_analysis_panel == null:
		return

	if teacher_analysis_panel.get_parent() != null:
		teacher_analysis_panel.get_parent().remove_child(teacher_analysis_panel)
	teacher_analysis_panel.queue_free()
	teacher_analysis_panel = null


func _update_opponent_score(opponent_result: ResultGame) -> void:
	if opponent_result == null:
		opponent_score_label.text = "Pontuação oponente"
		opponent_score_value.text = "-"
		opponent_coherence_value.text = "-"
		return

	opponent_score_label.text = "Pontuação oponente"
	opponent_score_value.text = _format_score(opponent_result.total_score)
	opponent_coherence_value.text = _format_percent(opponent_result.coherence)


func _format_score(value: float) -> String:
	return "%.1f" % value


func _format_percent(value: float) -> String:
	return "%.0f%%" % value


# ---- Botões ----

#func _on_review_timeline_button_pressed() -> void:
	#review_timeline_pressed.emit()

func _on_play_again_button_pressed() -> void:
	UISoundManager.play_button_click()
	play_again_pressed.emit()

func _on_exit_button_pressed() -> void:
	UISoundManager.play_button_click()
	exit_pressed.emit()
