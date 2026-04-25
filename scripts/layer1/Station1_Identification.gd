extends Control

signal closed()

const GAME_THEME := preload("res://themes/game_theme.tres")
const CHAIN_SCENE := preload("res://scenes/components/CauseEventEffectChain.tscn")

@onready var dim_background: ColorRect = $DimBackground
@onready var content_panel: PanelContainer = $ContentPanel
@onready var intro_container: VBoxContainer = $ContentPanel/MarginContainer/VBoxContainer/IntroContainer
@onready var intro_title: Label = $ContentPanel/MarginContainer/VBoxContainer/IntroContainer/IntroTitle
@onready var intro_text: RichTextLabel = $ContentPanel/MarginContainer/VBoxContainer/IntroContainer/IntroText
@onready var intro_continue: Button = $ContentPanel/MarginContainer/VBoxContainer/IntroContainer/IntroContinue
@onready var exercise_container: VBoxContainer = $ContentPanel/MarginContainer/VBoxContainer/ExerciseContainer
@onready var progress_label: Label = $ContentPanel/MarginContainer/VBoxContainer/ExerciseContainer/ProgressLabel
@onready var statement_text: RichTextLabel = $ContentPanel/MarginContainer/VBoxContainer/ExerciseContainer/StatementText
@onready var feedback_label: Label = $ContentPanel/MarginContainer/VBoxContainer/ExerciseContainer/FeedbackLabel
@onready var buttons_container: HBoxContainer = $ContentPanel/MarginContainer/VBoxContainer/ExerciseContainer/ButtonsContainer
@onready var risk_button: Button = $ContentPanel/MarginContainer/VBoxContainer/ExerciseContainer/ButtonsContainer/RiskButton
@onready var not_risk_button: Button = $ContentPanel/MarginContainer/VBoxContainer/ExerciseContainer/ButtonsContainer/NotRiskButton
@onready var summary_container: VBoxContainer = $ContentPanel/MarginContainer/VBoxContainer/SummaryContainer
@onready var summary_text: RichTextLabel = $ContentPanel/MarginContainer/VBoxContainer/SummaryContainer/SummaryText
@onready var summary_continue: Button = $ContentPanel/MarginContainer/VBoxContainer/SummaryContainer/SummaryContinue
@onready var chain_overlay_container: Control = $ContentPanel/MarginContainer/VBoxContainer/ChainOverlayContainer

var _station_data: Dictionary = {}
var _statements: Array = []
var _current_index := 0
var _correct_count := 0
var _intro_advanced := false

func _ready() -> void:
	theme = GAME_THEME
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_apply_styles()
	_load_data()
	_show_intro()

func _apply_styles() -> void:
	dim_background.color = StyleConstants.COLOR_BG_DIM
	content_panel.add_theme_stylebox_override("panel", StyleConstants.create_panel_stylebox())
	intro_title.add_theme_color_override("font_color", StyleConstants.COLOR_ACCENT_PRIMARY)
	intro_title.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_LG)
	intro_text.add_theme_color_override("default_color", StyleConstants.COLOR_TEXT_PRIMARY)
	progress_label.add_theme_color_override("font_color", StyleConstants.COLOR_TEXT_MUTED)
	progress_label.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_XS)
	statement_text.add_theme_color_override("default_color", StyleConstants.COLOR_TEXT_PRIMARY)
	feedback_label.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_MD)
	summary_text.add_theme_color_override("default_color", StyleConstants.COLOR_TEXT_PRIMARY)
	for label in [
		$ContentPanel/MarginContainer/VBoxContainer/SummaryContainer/SummaryChain/CauseLabel,
		$ContentPanel/MarginContainer/VBoxContainer/SummaryContainer/SummaryChain/EventLabel,
		$ContentPanel/MarginContainer/VBoxContainer/SummaryContainer/SummaryChain/EffectLabel
	]:
		label.add_theme_color_override("font_color", StyleConstants.COLOR_ACCENT_PRIMARY)
		label.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_SM)
	for arrow in [
		$ContentPanel/MarginContainer/VBoxContainer/SummaryContainer/SummaryChain/Arrow1,
		$ContentPanel/MarginContainer/VBoxContainer/SummaryContainer/SummaryChain/Arrow2
	]:
		arrow.add_theme_color_override("font_color", StyleConstants.COLOR_TEXT_SECONDARY)
		arrow.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_SM)
	StyleConstants.style_button(intro_continue, true)
	StyleConstants.style_button(risk_button, true)
	StyleConstants.style_button(not_risk_button, false)
	StyleConstants.style_button(summary_continue, true)

func _load_data() -> void:
	var layer1_data: Dictionary = DataManager.get_phase_data("stations", 1)
	var stations_data = layer1_data.get("stations", {})
	if stations_data is Dictionary:
		_station_data = stations_data.get("station_1", {})
	elif stations_data is Array:
		for station in stations_data:
			if station.get("station_number", 0) == 1:
				_station_data = station
				break
	_statements = _station_data.get("statements", [])
	if _statements.is_empty():
		push_warning("Station1_Identification: no statement data found.")

func _show_intro() -> void:
	intro_container.visible = true
	exercise_container.visible = false
	summary_container.visible = false
	intro_container.modulate.a = 0.0
	intro_title.text = str(_station_data.get("title", "SecurePay Project"))
	intro_text.text = str(_station_data.get("intro_text", DataManager.get_phase_data("stations", 1).get("narrative_intro", "")))
	var tween := create_tween()
	tween.tween_property(intro_container, "modulate:a", 1.0, 0.35)
	_intro_advanced = false
	if intro_continue.pressed.is_connected(_start_exercise):
		intro_continue.pressed.disconnect(_start_exercise)
	intro_continue.pressed.connect(_start_exercise)
	_auto_advance_intro()

func _auto_advance_intro() -> void:
	await get_tree().create_timer(3.0).timeout
	if not _intro_advanced:
		_start_exercise()

func _start_exercise() -> void:
	if _intro_advanced:
		return
	_intro_advanced = true
	intro_container.visible = false
	exercise_container.visible = true
	_show_statement(_current_index)

func _show_statement(index: int) -> void:
	if index >= _statements.size():
		_show_summary()
		return

	var stmt: Dictionary = _statements[index]
	progress_label.text = "Statement %d of %d" % [index + 1, _statements.size()]
	statement_text.text = str(stmt.get("statement", stmt.get("text", "")))
	feedback_label.visible = false
	buttons_container.visible = true
	risk_button.disabled = false
	not_risk_button.disabled = false
	_reconnect_answer_buttons(stmt)

func _reconnect_answer_buttons(stmt: Dictionary) -> void:
	for conn in risk_button.get_signal_connection_list("pressed"):
		risk_button.disconnect("pressed", conn["callable"])
	for conn in not_risk_button.get_signal_connection_list("pressed"):
		not_risk_button.disconnect("pressed", conn["callable"])
	risk_button.pressed.connect(func() -> void:
		_on_answer("project_risk", stmt)
	)
	not_risk_button.pressed.connect(func() -> void:
		_on_answer("not_a_risk", stmt)
	)

func _on_answer(player_answer: String, statement: Dictionary) -> void:
	var correct := str(statement.get("correct_answer", "")) == player_answer
	if correct:
		_correct_count += 1

	buttons_container.visible = false
	var feedback_color := StyleConstants.COLOR_HEALTH_GOOD if correct else StyleConstants.COLOR_HEALTH_WARNING
	feedback_label.text = "Correct!" if correct else "Not quite."
	feedback_label.add_theme_color_override("font_color", feedback_color)
	feedback_label.visible = true

	await get_tree().create_timer(1.0).timeout
	feedback_label.visible = false

	var chain_data: Dictionary = statement.get("chain", {})
	if not chain_data.is_empty():
		await _show_chain(chain_data)

	if statement.has("secondary_risk_chain"):
		feedback_label.text = "But what IS the risk here?"
		feedback_label.add_theme_color_override("font_color", StyleConstants.COLOR_ACCENT_PRIMARY)
		feedback_label.visible = true
		await get_tree().create_timer(1.5).timeout
		feedback_label.visible = false
		await _show_chain(statement.get("secondary_risk_chain", {}))

	_current_index += 1
	_show_statement(_current_index)

func _show_chain(chain_data: Dictionary) -> void:
	var chain = CHAIN_SCENE.instantiate()
	chain.setup(chain_data)
	chain_overlay_container.add_child(chain)
	await chain.completed

func _show_summary() -> void:
	exercise_container.visible = false
	summary_container.visible = true
	summary_text.text = str(_station_data.get("summary_text", "A project risk = an uncertain event, rooted in a cause, that could affect your project's scope, time, cost, or quality."))
	if summary_continue.pressed.is_connected(_complete_station):
		summary_continue.pressed.disconnect(_complete_station)
	summary_continue.pressed.connect(_complete_station)

func _complete_station() -> void:
	var total := maxi(_statements.size(), 1)
	GameManager.layer1_performance["station_1_accuracy"] = float(_correct_count) / float(total)
	GameManager.station_1_complete = true
	SignalBus.station_completed.emit(1)
	closed.emit()
	queue_free()
