extends Control

signal closed()
signal contrast_finished()

const GAME_THEME := preload("res://themes/game_theme.tres")
const NPC_DIALOGUE_SCENE := preload("res://scenes/components/NPCDialogue.tscn")
const PROFILE_CARD_SCENE := preload("res://scenes/components/ClientProfileCard.tscn")
const RIPPLE_SCENE := preload("res://scenes/components/RippleEffect.tscn")

const DIMENSIONS := ["cost", "schedule", "quality", "scope"]
const IMPACT_LEVELS := ["none", "low", "medium", "high"]

@onready var dim_background: ColorRect = $DimBackground
@onready var content_panel: PanelContainer = $ContentPanel
@onready var step_indicator: Label = $ContentPanel/MarginContainer/VBoxContainer/StepIndicator
@onready var dialogue_container: Control = $ContentPanel/MarginContainer/VBoxContainer/DialogueContainer
@onready var profile_build_container: Control = $ContentPanel/MarginContainer/VBoxContainer/ProfileBuildContainer
@onready var impact_exercise_container: VBoxContainer = $ContentPanel/MarginContainer/VBoxContainer/ImpactExerciseContainer
@onready var risk_title: Label = $ContentPanel/MarginContainer/VBoxContainer/ImpactExerciseContainer/RiskTitle
@onready var impact_grid: GridContainer = $ContentPanel/MarginContainer/VBoxContainer/ImpactExerciseContainer/ImpactGrid
@onready var submit_assessment: Button = $ContentPanel/MarginContainer/VBoxContainer/ImpactExerciseContainer/SubmitAssessment
@onready var ripple_container: Control = $ContentPanel/MarginContainer/VBoxContainer/ImpactExerciseContainer/RippleContainer
@onready var corrections_container: VBoxContainer = $ContentPanel/MarginContainer/VBoxContainer/ImpactExerciseContainer/CorrectionsContainer
@onready var next_risk_button: Button = $ContentPanel/MarginContainer/VBoxContainer/ImpactExerciseContainer/NextRiskButton
@onready var priority_lens_container: VBoxContainer = $ContentPanel/MarginContainer/VBoxContainer/PriorityLensContainer
@onready var profile_display_container: Control = $ContentPanel/MarginContainer/VBoxContainer/PriorityLensContainer/ProfileAndRisks/ProfileDisplayContainer
@onready var risk_impact_summary: VBoxContainer = $ContentPanel/MarginContainer/VBoxContainer/PriorityLensContainer/ProfileAndRisks/RiskImpactSummary
@onready var lens_explanation: RichTextLabel = $ContentPanel/MarginContainer/VBoxContainer/PriorityLensContainer/LensExplanation
@onready var lens_continue: Button = $ContentPanel/MarginContainer/VBoxContainer/PriorityLensContainer/LensContinue
@onready var contrast_container: VBoxContainer = $ContentPanel/MarginContainer/VBoxContainer/ContrastContainer
@onready var dana_card_container: Control = $ContentPanel/MarginContainer/VBoxContainer/ContrastContainer/CardsRow/DanaCardContainer
@onready var gov_card_container: Control = $ContentPanel/MarginContainer/VBoxContainer/ContrastContainer/CardsRow/GovCardContainer
@onready var contrast_note: RichTextLabel = $ContentPanel/MarginContainer/VBoxContainer/ContrastContainer/ContrastNote
@onready var contrast_continue: Button = $ContentPanel/MarginContainer/VBoxContainer/ContrastContainer/ContrastContinue

var _station_data: Dictionary = {}
var _dialogue_data: Dictionary = {}
var _npc_info: Dictionary = {}
var _client_profile: Dictionary = {}
var _contrast_profile: Dictionary = {}
var _impact_risks: Array = []
var _current_risk_index := 0
var _current_selections: Dictionary = {}
var _dimension_buttons: Dictionary = {}
var _impact_results: Array = []
var _correct_dimension_count := 0
var _total_dimension_count := 0
var _contrast_step_finished := false

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
	step_indicator.add_theme_color_override("font_color", StyleConstants.COLOR_TEXT_MUTED)
	step_indicator.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_XS)
	risk_title.add_theme_color_override("font_color", StyleConstants.COLOR_ACCENT_PRIMARY)
	risk_title.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_LG)
	lens_explanation.add_theme_color_override("default_color", StyleConstants.COLOR_TEXT_PRIMARY)
	contrast_note.add_theme_color_override("default_color", StyleConstants.COLOR_TEXT_PRIMARY)
	$ContentPanel/MarginContainer/VBoxContainer/PriorityLensContainer/LensTitle.add_theme_color_override("font_color", StyleConstants.COLOR_ACCENT_PRIMARY)
	$ContentPanel/MarginContainer/VBoxContainer/PriorityLensContainer/LensTitle.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_LG)
	StyleConstants.style_button(submit_assessment, true, true)
	StyleConstants.style_button(next_risk_button, true)
	StyleConstants.style_button(lens_continue, true)
	StyleConstants.style_button(contrast_continue, true)

func _load_data() -> void:
	var layer1_data: Dictionary = DataManager.get_phase_data("stations", 1)
	var stations_data = layer1_data.get("stations", {})
	if stations_data is Dictionary:
		_station_data = stations_data.get("station_3", {})

	var conversation: Dictionary = _station_data.get("conversation", {})
	var npc_id := str(conversation.get("npc_id", "dana"))
	var dialogue_id := str(conversation.get("dialogue_id", ""))
	_dialogue_data = DataManager.get_dialogue(npc_id, dialogue_id)
	_npc_info = DataManager.get_npc_info(npc_id)
	_client_profile = DataManager.get_client_profile("dana_original")
	if _client_profile.is_empty():
		_client_profile = _station_data.get("client_profile", {}).duplicate(true)
	_contrast_profile = DataManager.get_client_profile("government_contrast")
	if _contrast_profile.is_empty():
		_contrast_profile = _station_data.get("contrast_client_profile", {}).duplicate(true)
	_impact_risks = _station_data.get("impact_risks", []).duplicate(true)

func _run_station() -> void:
	await _run_dialogue_step()
	await _run_profile_step()
	await _run_impact_sequence()
	await _run_priority_lens_step()
	await _run_contrast_step()
	_complete_station()

func _hide_all_step_containers() -> void:
	dialogue_container.visible = false
	profile_build_container.visible = false
	impact_exercise_container.visible = false
	priority_lens_container.visible = false
	contrast_container.visible = false

func _clear_container(container: Node) -> void:
	for child in container.get_children():
		child.queue_free()

func _show_only(target: Control) -> void:
	_hide_all_step_containers()
	target.visible = true

func _run_dialogue_step() -> void:
	_show_only(dialogue_container)
	step_indicator.text = "Step 1 of 6: Meet the Client"
	_clear_container(dialogue_container)
	var dialogue := NPC_DIALOGUE_SCENE.instantiate()
	_prepare_embedded_component(dialogue, dialogue_container)
	dialogue.setup({
		"npc_name": str(_npc_info.get("display_name", "Dana")),
		"npc_role": str(_npc_info.get("role", "CEO of SecurePay")),
		"npc_avatar": str(_npc_info.get("avatar_path", _client_profile.get("avatar_path", ""))),
		"dialogue_tree": _dialogue_data.get("tree", [])
	})
	await dialogue.completed

func _run_profile_step() -> void:
	_show_only(profile_build_container)
	step_indicator.text = "Step 2 of 6: Build Dana's Profile"
	_clear_container(profile_build_container)
	var profile_card := PROFILE_CARD_SCENE.instantiate()
	_prepare_embedded_component(profile_card, profile_build_container)
	profile_card.setup({
		"mode": "build",
		"character_name": str(_client_profile.get("name", "Dana")),
		"company": str(_client_profile.get("company", "SecurePay")),
		"avatar": str(_client_profile.get("avatar_path", "")),
		"correct_stats": {
			"budget_tolerance": str(_client_profile.get("budget_tolerance", "high")),
			"schedule_flexibility": str(_client_profile.get("schedule_flexibility", "low")),
			"quality_standards": str(_client_profile.get("quality_standards", "high")),
			"scope_flexibility": str(_client_profile.get("scope_flexibility", "high"))
		},
		"correction_hints": _station_data.get("profile_correction_lines", {})
	})
	var result: Dictionary = await profile_card.completed
	GameManager.client_profile_active = _client_profile.duplicate(true)
	GameManager.client_profile_active.merge(result.get("player_stats", {}), true)

func _run_impact_sequence() -> void:
	_show_only(impact_exercise_container)
	for index in range(_impact_risks.size()):
		_current_risk_index = index
		var risk: Dictionary = _impact_risks[index]
		step_indicator.text = "Step 3 of 6: Impact Assessment (%d of %d)" % [index + 1, _impact_risks.size()]
		await _run_single_risk_assessment(risk, index == _impact_risks.size() - 1)

func _run_single_risk_assessment(risk: Dictionary, is_last_risk: bool) -> void:
	risk_title.text = str(risk.get("title", "Impact Assessment"))
	_clear_impact_state()
	_build_impact_grid(risk)
	await submit_assessment.pressed
	submit_assessment.disabled = true
	StyleConstants.style_button(submit_assessment, true, true)

	var player_ratings := _current_selections.duplicate(true)
	var expected := _normalize_expected_impact(risk.get("expected_impact", {}))
	var comparison := _compare_assessment(player_ratings, expected)
	_correct_dimension_count += int(comparison.get("correct_count", 0))
	_total_dimension_count += DIMENSIONS.size()
	_impact_results.append({
		"risk": risk.duplicate(true),
		"player_ratings": player_ratings,
		"expected_ratings": expected
	})

	await _show_ripple(risk)
	_show_corrections(risk, comparison)
	next_risk_button.text = "Continue" if is_last_risk else "Next Risk"
	next_risk_button.visible = true
	await next_risk_button.pressed

func _clear_impact_state() -> void:
	_current_selections.clear()
	_dimension_buttons.clear()
	submit_assessment.disabled = true
	StyleConstants.style_button(submit_assessment, true, true)
	next_risk_button.visible = false
	_clear_container(impact_grid)
	_clear_container(corrections_container)
	_clear_container(ripple_container)

func _build_impact_grid(risk: Dictionary) -> void:
	for dimension in DIMENSIONS:
		var dimension_label := Label.new()
		dimension_label.text = "%s Impact" % _display_dimension_name(dimension)
		dimension_label.add_theme_color_override("font_color", StyleConstants.COLOR_TEXT_PRIMARY)
		dimension_label.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_SM)
		impact_grid.add_child(dimension_label)

		_dimension_buttons[dimension] = {}
		for level in IMPACT_LEVELS:
			var button := Button.new()
			button.text = level.capitalize()
			button.custom_minimum_size = Vector2(92, 34)
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			StyleConstants.style_button(button, false)
			button.pressed.connect(_on_impact_option_selected.bind(dimension, level))
			_dimension_buttons[dimension][level] = button
			impact_grid.add_child(button)

func _on_impact_option_selected(dimension: String, level: String) -> void:
	_current_selections[dimension] = level
	for option in _dimension_buttons.get(dimension, {}).keys():
		var button: Button = _dimension_buttons[dimension][option]
		StyleConstants.style_button(button, option == level)
	_update_submit_state()

func _update_submit_state() -> void:
	submit_assessment.disabled = _current_selections.size() < DIMENSIONS.size()
	StyleConstants.style_button(submit_assessment, true, submit_assessment.disabled)

func _show_ripple(risk: Dictionary) -> void:
	var ripple := RIPPLE_SCENE.instantiate()
	_prepare_embedded_component(ripple, ripple_container)
	ripple.setup({
		"steps": risk.get("ripple_steps", []),
		"summary": _build_ripple_summary(risk.get("ripple_steps", []))
	})
	await ripple.completed

func _build_ripple_summary(steps: Array) -> Dictionary:
	var summary := {
		"budget": 0,
		"schedule": 0,
		"quality": 0,
		"stakeholder_trust": 0
	}
	for step in steps:
		var dimension := str(step.get("dimension", ""))
		var value := int(step.get("delta_value", 0))
		match dimension:
			"budget":
				summary["budget"] += value
			"schedule":
				summary["schedule"] += value
			"quality":
				summary["quality"] += value
			"stakeholder_trust":
				summary["stakeholder_trust"] += value
	return summary

func _compare_assessment(player_ratings: Dictionary, expected: Dictionary) -> Dictionary:
	var lines: Array[String] = []
	var correct_count := 0
	for dimension in DIMENSIONS:
		var actual := str(player_ratings.get(dimension, "none"))
		var target := str(expected.get(dimension, "none"))
		if actual == target:
			correct_count += 1
			continue
		lines.append(
			"%s was %s, but you marked %s." % [
				_display_dimension_name(dimension),
				target.capitalize(),
				actual.capitalize()
			]
		)
	return {
		"correct_count": correct_count,
		"lines": lines
	}

func _show_corrections(risk: Dictionary, comparison: Dictionary) -> void:
	_clear_container(corrections_container)
	var lines: Array = comparison.get("lines", [])
	if lines.is_empty():
		var success_label := _make_feedback_label(
			"Your assessment matched the ripple closely across all four dimensions.",
			StyleConstants.COLOR_HEALTH_GOOD
		)
		corrections_container.add_child(success_label)
		return

	var feedback_text := str(risk.get("comparison_feedback", "Check the ripple sequence again and compare it to your chosen impact ratings."))
	corrections_container.add_child(_make_feedback_label(feedback_text, StyleConstants.COLOR_HEALTH_WARNING))
	for line in lines:
		corrections_container.add_child(_make_feedback_label(str(line), StyleConstants.COLOR_TEXT_PRIMARY))

func _make_feedback_label(text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_SM)
	return label

func _run_priority_lens_step() -> void:
	_show_only(priority_lens_container)
	step_indicator.text = "Step 5 of 6: The Priority Lens"
	_clear_container(profile_display_container)
	_clear_container(risk_impact_summary)
	_spawn_display_profile(profile_display_container, GameManager.client_profile_active)

	var cost_overlay := str(_station_data.get("priority_lens", {}).get("cost_overlay", ""))
	var schedule_overlay := str(_station_data.get("priority_lens", {}).get("schedule_overlay", ""))
	lens_explanation.text = "%s\n\n%s\n\n%s" % [
		cost_overlay,
		schedule_overlay,
		str(_station_data.get("priority_lens", {}).get("conclusion", ""))
	]

	for result in _impact_results:
		risk_impact_summary.add_child(_build_priority_summary_card(result))

	await lens_continue.pressed

func _build_priority_summary_card(result: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", StyleConstants.create_panel_stylebox(Color(0.10, 0.13, 0.17, 0.95), StyleConstants.COLOR_ACCENT_SECONDARY, 1))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	var risk: Dictionary = result.get("risk", {})
	var title := Label.new()
	title.text = str(risk.get("title", "Risk"))
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_color_override("font_color", StyleConstants.COLOR_ACCENT_PRIMARY)
	title.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_MD)
	vbox.add_child(title)

	var player_ratings: Dictionary = result.get("player_ratings", {})
	for dimension in DIMENSIONS:
		var tolerance_key := _tolerance_key_for_dimension(dimension)
		var tolerance := _normalize_level(str(GameManager.client_profile_active.get(tolerance_key, "medium")))
		var impact := _normalize_level(str(player_ratings.get(dimension, "none")))
		var line := Label.new()
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.text = "%s: %s impact vs Dana's %s tolerance" % [
			_display_dimension_name(dimension),
			impact.capitalize(),
			tolerance.replace("_", " ").capitalize()
		]
		line.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_SM)
		line.add_theme_color_override("font_color", _lens_color(impact, tolerance))
		vbox.add_child(line)

	return panel

func _run_contrast_step() -> void:
	_show_only(contrast_container)
	step_indicator.text = "Step 6 of 6: Contrast Client"
	_clear_container(dana_card_container)
	_clear_container(gov_card_container)
	_spawn_display_profile(dana_card_container, GameManager.client_profile_active)
	_spawn_display_profile(gov_card_container, _contrast_profile)
	contrast_note.text = "Notice how the priorities are reversed. The same risk that's a minor concern for Dana could be critical for this client."
	_contrast_step_finished = false
	_wait_for_contrast_timeout.call_deferred()
	await contrast_finished

func _wait_for_contrast_timeout() -> void:
	await get_tree().create_timer(5.0).timeout
	if contrast_container.visible:
		_finish_contrast_step()

func _on_contrast_continue_pressed() -> void:
	_finish_contrast_step()

func _finish_contrast_step() -> void:
	if _contrast_step_finished:
		return
	_contrast_step_finished = true
	contrast_finished.emit()

func _spawn_display_profile(container: Control, profile: Dictionary) -> void:
	var card := PROFILE_CARD_SCENE.instantiate()
	_prepare_embedded_component(card, container)
	card.setup({
		"mode": "display",
		"character_name": str(profile.get("name", "Unknown")),
		"company": str(profile.get("company", "")),
		"avatar": str(profile.get("avatar_path", "")),
		"stats": {
			"budget_tolerance": str(profile.get("budget_tolerance", "medium")),
			"schedule_flexibility": str(profile.get("schedule_flexibility", "medium")),
			"quality_standards": str(profile.get("quality_standards", "medium")),
			"scope_flexibility": str(profile.get("scope_flexibility", "medium"))
		}
	})
	if card.has_node("CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ContinueButton"):
		card.get_node("CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ContinueButton").visible = false

func _prepare_embedded_component(component: Control, container: Control) -> void:
	component.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.add_child(component)
	if component.has_node("DimBackground"):
		component.get_node("DimBackground").visible = false

func _normalize_expected_impact(expected: Dictionary) -> Dictionary:
	var normalized := {}
	for dimension in DIMENSIONS:
		normalized[dimension] = _normalize_level(str(expected.get(dimension, "none")))
	return normalized

func _normalize_level(level: String) -> String:
	match level.to_lower():
		"", "none":
			return "none"
		"none_low":
			return "low"
		"low":
			return "low"
		"low_medium":
			return "medium"
		"medium":
			return "medium"
		"medium_high", "high", "very_high":
			return "high"
		_:
			return "medium"

func _tolerance_key_for_dimension(dimension: String) -> String:
	match dimension:
		"cost":
			return "budget_tolerance"
		"schedule":
			return "schedule_flexibility"
		"quality":
			return "quality_standards"
		"scope":
			return "scope_flexibility"
		_:
			return ""

func _lens_color(impact: String, tolerance: String) -> Color:
	if tolerance == "low" and impact == "high":
		return StyleConstants.COLOR_HEALTH_CRITICAL
	if tolerance == "high":
		return StyleConstants.COLOR_HEALTH_GOOD
	if tolerance == "medium" and impact == "high":
		return StyleConstants.COLOR_HEALTH_WARNING
	return StyleConstants.COLOR_TEXT_SECONDARY

func _display_dimension_name(dimension: String) -> String:
	match dimension:
		"cost":
			return "Cost"
		"schedule":
			return "Schedule"
		"quality":
			return "Quality"
		"scope":
			return "Scope"
		_:
			return dimension.capitalize()

func _complete_station() -> void:
	var total := maxi(_total_dimension_count, 1)
	GameManager.layer1_performance["station_3_accuracy"] = float(_correct_dimension_count) / float(total)
	GameManager.station_3_complete = true
	SignalBus.station_completed.emit(3)
	closed.emit()
	queue_free()

