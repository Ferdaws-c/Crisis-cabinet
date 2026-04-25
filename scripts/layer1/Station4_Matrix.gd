extends Control

signal closed()

const GAME_THEME := preload("res://themes/game_theme.tres")
const RISK_MATRIX_SCENE := preload("res://scenes/components/RiskMatrix.tscn")

@onready var dim_background: ColorRect = $DimBackground
@onready var content_panel: PanelContainer = $ContentPanel
@onready var intro_container: VBoxContainer = $ContentPanel/MarginContainer/VBoxContainer/IntroContainer
@onready var intro_text: RichTextLabel = $ContentPanel/MarginContainer/VBoxContainer/IntroContainer/IntroText
@onready var intro_continue: Button = $ContentPanel/MarginContainer/VBoxContainer/IntroContainer/IntroContinue
@onready var empty_matrix_container: VBoxContainer = $ContentPanel/MarginContainer/VBoxContainer/EmptyMatrixContainer
@onready var preview_continue: Button = $ContentPanel/MarginContainer/VBoxContainer/EmptyMatrixContainer/PreviewContinue
@onready var matrix_exercise_container: Control = $ContentPanel/MarginContainer/VBoxContainer/MatrixExerciseContainer
@onready var misplacement_container: VBoxContainer = $ContentPanel/MarginContainer/VBoxContainer/MisplacementContainer
@onready var misplacement_list: VBoxContainer = $ContentPanel/MarginContainer/VBoxContainer/MisplacementContainer/MisplacementList
@onready var misplacement_continue: Button = $ContentPanel/MarginContainer/VBoxContainer/MisplacementContainer/MisplacementContinue
@onready var summary_container: VBoxContainer = $ContentPanel/MarginContainer/VBoxContainer/SummaryContainer
@onready var final_matrix_container: Control = $ContentPanel/MarginContainer/VBoxContainer/SummaryContainer/FinalMatrixContainer
@onready var summary_text: RichTextLabel = $ContentPanel/MarginContainer/VBoxContainer/SummaryContainer/SummaryText
@onready var summary_continue: Button = $ContentPanel/MarginContainer/VBoxContainer/SummaryContainer/SummaryContinue

var _station_data: Dictionary = {}
var _risks_to_place: Array = []
var _placement_results: Array = []
var _risk_lookup: Dictionary = {}

func _ready() -> void:
	theme = GAME_THEME
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_apply_styles()
	_load_data()
	_hide_all_step_containers()
	_run_station.call_deferred()

func _apply_styles() -> void:
	dim_background.color = StyleConstants.COLOR_BG_DIM
	content_panel.add_theme_stylebox_override("panel", StyleConstants.create_panel_stylebox())
	intro_text.add_theme_color_override("default_color", StyleConstants.COLOR_TEXT_PRIMARY)
	summary_text.add_theme_color_override("default_color", StyleConstants.COLOR_TEXT_PRIMARY)
	$ContentPanel/MarginContainer/VBoxContainer/MisplacementContainer/MisplacementTitle.add_theme_color_override("font_color", StyleConstants.COLOR_ACCENT_PRIMARY)
	$ContentPanel/MarginContainer/VBoxContainer/MisplacementContainer/MisplacementTitle.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_LG)
	for label in [
		$ContentPanel/MarginContainer/VBoxContainer/EmptyMatrixContainer/MatrixPreview/HeaderRow/BlankCorner,
		$ContentPanel/MarginContainer/VBoxContainer/EmptyMatrixContainer/MatrixPreview/HeaderRow/LowImpactLabel,
		$ContentPanel/MarginContainer/VBoxContainer/EmptyMatrixContainer/MatrixPreview/HeaderRow/HighImpactLabel,
		$ContentPanel/MarginContainer/VBoxContainer/EmptyMatrixContainer/MatrixPreview/TopRow/ProbabilityHighLabel,
		$ContentPanel/MarginContainer/VBoxContainer/EmptyMatrixContainer/MatrixPreview/BottomRow/ProbabilityLowLabel
	]:
		label.add_theme_color_override("font_color", StyleConstants.COLOR_TEXT_SECONDARY)
		label.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_SM)
	for panel_path in [
		"EmptyMatrixContainer/MatrixPreview/TopRow/QuadrantTopLeft",
		"EmptyMatrixContainer/MatrixPreview/TopRow/QuadrantTopRight",
		"EmptyMatrixContainer/MatrixPreview/BottomRow/QuadrantBottomLeft",
		"EmptyMatrixContainer/MatrixPreview/BottomRow/QuadrantBottomRight"
	]:
		var panel: PanelContainer = $ContentPanel/MarginContainer/VBoxContainer.get_node(panel_path)
		panel.add_theme_stylebox_override("panel", StyleConstants.create_panel_stylebox(Color(0.08, 0.10, 0.13, 0.25), StyleConstants.COLOR_ACCENT_SECONDARY, 1))
	StyleConstants.style_button(intro_continue, true)
	StyleConstants.style_button(preview_continue, true)
	StyleConstants.style_button(misplacement_continue, true)
	StyleConstants.style_button(summary_continue, true)

func _load_data() -> void:
	var layer1_data: Dictionary = DataManager.get_phase_data("stations", 1)
	var stations_data = layer1_data.get("stations", {})
	if stations_data is Dictionary:
		_station_data = stations_data.get("station_4", {})
	_risks_to_place = _station_data.get("risks_to_place", []).duplicate(true)
	for risk in _risks_to_place:
		_risk_lookup[str(risk.get("id", ""))] = risk

func _run_station() -> void:
	_show_intro()
	await intro_continue.pressed
	_show_empty_matrix()
	await preview_continue.pressed
	await _run_matrix_exercise()
	_show_misplacement_review()
	await misplacement_continue.pressed
	_show_summary()
	await summary_continue.pressed
	_complete_station()

func _hide_all_step_containers() -> void:
	intro_container.visible = false
	empty_matrix_container.visible = false
	matrix_exercise_container.visible = false
	misplacement_container.visible = false
	summary_container.visible = false

func _show_intro() -> void:
	_hide_all_step_containers()
	intro_container.visible = true
	intro_text.text = "You've assessed probability and impact separately. Now let's combine them. The risk matrix shows you where each risk falls - and what that means for how you prioritize it."

func _show_empty_matrix() -> void:
	_hide_all_step_containers()
	empty_matrix_container.visible = true

func _run_matrix_exercise() -> void:
	_hide_all_step_containers()
	matrix_exercise_container.visible = true
	_clear_container(matrix_exercise_container)
	var matrix := RISK_MATRIX_SCENE.instantiate()
	_prepare_embedded_component(matrix, matrix_exercise_container)
	matrix.setup({
		"mode": "interactive",
		"risks_to_place": _risks_to_place
	})
	var results: Dictionary = await matrix.completed
	_placement_results = results.get("placements", [])

func _show_misplacement_review() -> void:
	_hide_all_step_containers()
	misplacement_container.visible = true
	_clear_container(misplacement_list)

	var misplaced := _placement_results.filter(func(entry: Dictionary) -> bool: return not entry.get("was_correct", false))
	if misplaced.is_empty():
		misplacement_list.add_child(_make_review_label(
			"You placed all risks correctly. You're building strong risk assessment intuition.",
			StyleConstants.COLOR_HEALTH_GOOD
		))
		return

	for entry in misplaced:
		var risk: Dictionary = _risk_lookup.get(str(entry.get("id", "")), {})
		var probability := str(risk.get("probability", "unknown")).replace("_", " ").capitalize()
		var impact := str(risk.get("impact", "unknown")).replace("_", " ").capitalize()
		var line := "You rated '%s' as %s, but its probability was %s and its impact was %s for Dana - that combination makes it a %s." % [
			str(risk.get("title", entry.get("id", "Unknown risk"))),
			str(entry.get("placed", "")).capitalize(),
			probability,
			impact,
			str(entry.get("correct", "")).capitalize()
		]
		misplacement_list.add_child(_make_review_label(line, StyleConstants.COLOR_HEALTH_WARNING))

	var borderline_note := str(_station_data.get("borderline_note", ""))
	if borderline_note != "":
		misplacement_list.add_child(_make_review_label(borderline_note, StyleConstants.COLOR_TEXT_SECONDARY))

func _show_summary() -> void:
	_hide_all_step_containers()
	summary_container.visible = true
	_clear_container(final_matrix_container)
	var display_risks: Array = []
	for risk in _risks_to_place:
		display_risks.append({
			"id": str(risk.get("id", "")),
			"title": str(risk.get("title", "Unnamed Risk")),
			"quadrant": str(risk.get("correct_quadrant", "spark"))
		})

	var matrix := RISK_MATRIX_SCENE.instantiate()
	_prepare_embedded_component(matrix, final_matrix_container)
	matrix.setup({
		"mode": "display",
		"placed_risks": display_risks
	})
	if matrix.has_node("CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ContinueButton"):
		matrix.get_node("CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ContinueButton").visible = false
	summary_text.text = str(_station_data.get("matrix_summary", "This is your risk matrix - the single most important tool in risk management."))

func _make_review_label(text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_SM)
	return label

func _prepare_embedded_component(component: Control, container: Control) -> void:
	component.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.add_child(component)
	if component.has_node("DimBackground"):
		component.get_node("DimBackground").visible = false

func _clear_container(container: Node) -> void:
	for child in container.get_children():
		child.queue_free()

func _complete_station() -> void:
	var correct := _placement_results.filter(func(entry: Dictionary) -> bool: return entry.get("was_correct", false)).size()
	var total := maxi(_placement_results.size(), 1)
	GameManager.layer1_performance["station_4_accuracy"] = float(correct) / float(total)
	GameManager.station_4_complete = true
	SignalBus.station_completed.emit(4)
	closed.emit()
	queue_free()

