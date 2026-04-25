extends Control

signal closed()
signal step_choice_made(choice: String)

const GAME_THEME := preload("res://themes/game_theme.tres")
const CHAIN_SCENE := preload("res://scenes/components/CauseEventEffectChain.tscn")
const EVIDENCE_SCENE := preload("res://scenes/components/EvidenceColumns.tscn")
const RIPPLE_SCENE := preload("res://scenes/components/RippleEffect.tscn")
const MATRIX_SCENE := preload("res://scenes/components/RiskMatrix.tscn")
const NPC_DIALOGUE_SCENE := preload("res://scenes/components/NPCDialogue.tscn")
const PROFILE_CARD_SCENE := preload("res://scenes/components/ClientProfileCard.tscn")

const DIMENSIONS := ["cost", "schedule", "quality", "scope"]
const IMPACT_LEVELS := ["none", "low", "medium", "high"]
const STRATEGY_ORDER := ["avoid", "mitigate", "transfer", "accept"]

@onready var dim_background: ColorRect = $DimBackground
@onready var content_panel: PanelContainer = $ContentPanel
@onready var step_label: Label = $ContentPanel/MarginContainer/VBoxContainer/StepLabel
@onready var scenario_text: RichTextLabel = $ContentPanel/MarginContainer/VBoxContainer/ScenarioText
@onready var hint_label: Label = $ContentPanel/MarginContainer/VBoxContainer/HintContainer/HintLabel
@onready var step1_container: VBoxContainer = $ContentPanel/MarginContainer/VBoxContainer/Step1Container
@onready var yes_button: Button = $ContentPanel/MarginContainer/VBoxContainer/Step1Container/ButtonsRow/YesButton
@onready var no_button: Button = $ContentPanel/MarginContainer/VBoxContainer/Step1Container/ButtonsRow/NoButton
@onready var step2_container: VBoxContainer = $ContentPanel/MarginContainer/VBoxContainer/Step2Container
@onready var low_btn: Button = $ContentPanel/MarginContainer/VBoxContainer/Step2Container/ZoneButtons/LowBtn
@onready var medium_btn: Button = $ContentPanel/MarginContainer/VBoxContainer/Step2Container/ZoneButtons/MediumBtn
@onready var high_btn: Button = $ContentPanel/MarginContainer/VBoxContainer/Step2Container/ZoneButtons/HighBtn
@onready var step3_container: VBoxContainer = $ContentPanel/MarginContainer/VBoxContainer/Step3Container
@onready var profile_card_container: Control = $ContentPanel/MarginContainer/VBoxContainer/Step3Container/ProfileCardContainer
@onready var impact_grid: GridContainer = $ContentPanel/MarginContainer/VBoxContainer/Step3Container/ImpactGrid
@onready var submit_impact: Button = $ContentPanel/MarginContainer/VBoxContainer/Step3Container/SubmitImpact
@onready var step4_container: Control = $ContentPanel/MarginContainer/VBoxContainer/Step4Container
@onready var step5_container: VBoxContainer = $ContentPanel/MarginContainer/VBoxContainer/Step5Container
@onready var talk_to_alex_button: Button = $ContentPanel/MarginContainer/VBoxContainer/Step5Container/ButtonsRow/TalkToAlexButton
@onready var skip_alex_button: Button = $ContentPanel/MarginContainer/VBoxContainer/Step5Container/ButtonsRow/SkipAlexButton
@onready var alex_status: Label = $ContentPanel/MarginContainer/VBoxContainer/Step5Container/AlexStatus
@onready var step6_container: VBoxContainer = $ContentPanel/MarginContainer/VBoxContainer/Step6Container
@onready var strategy_buttons: HBoxContainer = $ContentPanel/MarginContainer/VBoxContainer/Step6Container/StrategyButtons
@onready var strategy_analysis_text: RichTextLabel = $ContentPanel/MarginContainer/VBoxContainer/Step6Container/AnalysisText
@onready var step6_continue: Button = $ContentPanel/MarginContainer/VBoxContainer/Step6Container/Step6Continue
@onready var step7_container: VBoxContainer = $ContentPanel/MarginContainer/VBoxContainer/Step7Container
@onready var debrief_sections: VBoxContainer = $ContentPanel/MarginContainer/VBoxContainer/Step7Container/DebriefSections
@onready var final_message: RichTextLabel = $ContentPanel/MarginContainer/VBoxContainer/Step7Container/FinalMessage
@onready var complete_continue: Button = $ContentPanel/MarginContainer/VBoxContainer/Step7Container/CompleteContinue
@onready var component_container: Control = $ContentPanel/MarginContainer/VBoxContainer/ComponentContainer
@onready var hint_timer: Timer = $HintTimer

var _station_data: Dictionary = {}
var _alex_dialogue_data: Dictionary = {}
var _alex_npc_info: Dictionary = {}
var _client_profile: Dictionary = {}
var _current_hint_text := ""
var _hint_usage_count := 0
var _current_impact_selections: Dictionary = {}
var _dimension_buttons: Dictionary = {}
var _selected_probability := ""
var _matrix_result: Dictionary = {}
var _investigated_alex := false
var _selected_strategy := ""
var _step_completed := false

func _ready() -> void:
	theme = GAME_THEME
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_apply_styles()
	_load_data()
	_hide_all_step_containers()
	hint_timer.timeout.connect(_on_hint_timeout)
	_run_station.call_deferred()

func _apply_styles() -> void:
	dim_background.color = StyleConstants.COLOR_BG_DIM
	content_panel.add_theme_stylebox_override("panel", StyleConstants.create_panel_stylebox())
	step_label.add_theme_color_override("font_color", StyleConstants.COLOR_TEXT_MUTED)
	step_label.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_XS)
	scenario_text.add_theme_color_override("default_color", StyleConstants.COLOR_TEXT_PRIMARY)
	hint_label.add_theme_color_override("font_color", StyleConstants.COLOR_HEALTH_WARNING)
	hint_label.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_SM)
	$ContentPanel/MarginContainer/VBoxContainer/Step7Container/DebriefTitle.add_theme_color_override("font_color", StyleConstants.COLOR_ACCENT_PRIMARY)
	$ContentPanel/MarginContainer/VBoxContainer/Step7Container/DebriefTitle.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_LG)
	alex_status.add_theme_color_override("font_color", StyleConstants.COLOR_TEXT_SECONDARY)
	alex_status.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_SM)
	strategy_analysis_text.add_theme_color_override("default_color", StyleConstants.COLOR_TEXT_PRIMARY)
	final_message.add_theme_color_override("default_color", StyleConstants.COLOR_TEXT_PRIMARY)
	for button in [yes_button, no_button, low_btn, medium_btn, high_btn, submit_impact, talk_to_alex_button, skip_alex_button, step6_continue, complete_continue]:
		StyleConstants.style_button(button, true if button in [yes_button, medium_btn, submit_impact, talk_to_alex_button, step6_continue, complete_continue] else false, button == submit_impact)
	submit_impact.disabled = true

func _load_data() -> void:
	var layer1_data: Dictionary = DataManager.get_phase_data("stations", 1)
	var stations_data = layer1_data.get("stations", {})
	if stations_data is Dictionary:
		_station_data = stations_data.get("station_6", {})
	var investigation: Dictionary = _station_data.get("investigation", {})
	var npc_id := str(investigation.get("npc_id", "alex"))
	var dialogue_id := str(investigation.get("dialogue_id", ""))
	_alex_dialogue_data = DataManager.get_dialogue(npc_id, dialogue_id)
	_alex_npc_info = DataManager.get_npc_info(npc_id)
	_client_profile = DataManager.get_client_profile("dana_original")
	if _client_profile.is_empty():
		_client_profile = GameManager.client_profile_active.duplicate(true)
	scenario_text.text = str(_station_data.get("scenario", ""))

func _run_station() -> void:
	await _run_identification_step()
	await _run_probability_step()
	await _run_impact_step()
	await _run_matrix_step()
	await _run_investigation_step()
	await _run_strategy_step()
	await _run_debrief_step()
	_complete_station()

func _hide_all_step_containers() -> void:
	step1_container.visible = false
	step2_container.visible = false
	step3_container.visible = false
	step4_container.visible = false
	step5_container.visible = false
	step6_container.visible = false
	step7_container.visible = false

func _show_only(target: Control) -> void:
	_hide_all_step_containers()
	target.visible = true

func _start_hint_for_step(step_text: String, hint_text: String) -> void:
	step_label.text = step_text
	_current_hint_text = hint_text
	hint_label.visible = false
	hint_label.modulate.a = 0.0
	hint_timer.stop()
	hint_timer.start()

func _register_activity() -> void:
	hint_timer.stop()
	hint_label.visible = false
	hint_label.modulate.a = 0.0
	if _current_hint_text != "":
		hint_timer.start()

func _on_hint_timeout() -> void:
	hint_label.text = _current_hint_text
	hint_label.visible = true
	hint_label.modulate.a = 0.0
	_hint_usage_count += 1
	GameManager.layer1_performance["station_6_hints_used"] = _hint_usage_count
	var tween := create_tween()
	tween.tween_property(hint_label, "modulate:a", 1.0, 0.25)

func _run_identification_step() -> void:
	_show_only(step1_container)
	_start_hint_for_step("Step 1 of 7: Identification", str(_station_data.get("hint_texts", {}).get("identification", "")))
	var selected := await _wait_for_button_choice({
		"yes": yes_button,
		"no": no_button
	})
	_register_activity()
	await _show_component(CHAIN_SCENE, _station_data.get("cause_event_effect_chain", {}))
	_step_completed = str(selected) == str(_station_data.get("correct_answers", {}).get("identification", "yes"))

func _run_probability_step() -> void:
	_show_only(step2_container)
	_start_hint_for_step("Step 2 of 7: Probability", str(_station_data.get("hint_texts", {}).get("probability", "")))
	_selected_probability = await _wait_for_button_choice({
		"low": low_btn,
		"medium": medium_btn,
		"high": high_btn
	})
	_register_activity()
	await _show_component(EVIDENCE_SCENE, _station_data.get("probability_evidence", {}))

func _run_impact_step() -> void:
	_show_only(step3_container)
	_start_hint_for_step("Step 3 of 7: Impact", str(_station_data.get("hint_texts", {}).get("impact", "")))
	_spawn_profile_card()
	_build_impact_grid()
	await submit_impact.pressed
	_register_activity()
	submit_impact.disabled = true
	StyleConstants.style_button(submit_impact, true, true)
	await _show_component(RIPPLE_SCENE, {
		"steps": _station_data.get("impact_ripple_steps", []),
		"summary": _build_ripple_summary(_station_data.get("impact_ripple_steps", []))
	})

func _run_matrix_step() -> void:
	_show_only(step4_container)
	_start_hint_for_step("Step 4 of 7: Matrix Classification", str(_station_data.get("hint_texts", {}).get("matrix", "")))
	_clear_container(step4_container)
	var matrix := MATRIX_SCENE.instantiate()
	_prepare_embedded_component(matrix, step4_container)
	matrix.setup({
		"mode": "interactive",
		"risks_to_place": [{
			"id": "station6_risk",
			"title": "Testing framework incompatible with new mobile OS",
			"correct_quadrant": str(_station_data.get("correct_answers", {}).get("matrix_category", "wildfire"))
		}]
	})
	var result: Dictionary = await matrix.completed
	_register_activity()
	var placements: Array = result.get("placements", [])
	if not placements.is_empty():
		_matrix_result = placements[0]

func _run_investigation_step() -> void:
	_show_only(step5_container)
	_start_hint_for_step("Step 5 of 7: Investigation", "Investigating first helps. What can Alex tell you?")
	alex_status.text = "You can ask Alex for more context before choosing a response."
	var selected := await _wait_for_button_choice({
		"talk": talk_to_alex_button,
		"skip": skip_alex_button
	})
	_register_activity()
	if selected == "talk":
		_investigated_alex = true
		var dialogue := NPC_DIALOGUE_SCENE.instantiate()
		_prepare_embedded_component(dialogue, component_container)
		dialogue.setup({
			"npc_name": str(_alex_npc_info.get("display_name", "Alex")),
			"npc_role": str(_alex_npc_info.get("role", "QA Lead")),
			"npc_avatar": str(_alex_npc_info.get("avatar_path", "")),
			"dialogue_tree": _alex_dialogue_data.get("tree", [])
		})
		await dialogue.completed
		alex_status.text = "Alex confirmed a framework update may exist, manual testing is only a stopgap, and dropping OS support carries reputational cost."
	else:
		alex_status.text = "You skipped the investigation and are choosing with less context."

func _run_strategy_step() -> void:
	_show_only(step6_container)
	_start_hint_for_step("Step 6 of 7: Response Strategy", "Remember the tradeoffs - what does each strategy cost, and what does it protect?")
	_build_strategy_buttons()
	strategy_analysis_text.text = ""
	step6_continue.visible = false
	await step6_continue.pressed
	_register_activity()

func _build_strategy_buttons() -> void:
	_clear_container(strategy_buttons)
	for strategy_name in STRATEGY_ORDER:
		var button := Button.new()
		button.text = strategy_name.capitalize()
		button.custom_minimum_size = Vector2(140, 40)
		StyleConstants.style_button(button, false)
		button.pressed.connect(_on_station6_strategy_selected.bind(strategy_name))
		strategy_buttons.add_child(button)

func _on_station6_strategy_selected(strategy_name: String) -> void:
	_register_activity()
	_selected_strategy = strategy_name
	var option: Dictionary = _station_data.get("response_options", {}).get(strategy_name, {})
	var perspective := ""
	match strategy_name:
		"mitigate":
			perspective = "This protects Dana's non-negotiable quality bar while containing schedule damage."
		"accept":
			perspective = "This leaves the team exposed on the very dimensions Dana cares about most."
		"transfer":
			perspective = "This buys speed, but it trades away some direct control over testing depth."
		"avoid":
			perspective = "This removes schedule pressure now, but creates reputation and trust risk at launch."
	strategy_analysis_text.text = "%s\n\n%s" % [str(option.get("summary_text", "")), perspective]
	step6_continue.visible = true

func _run_debrief_step() -> void:
	_show_only(step7_container)
	_current_hint_text = ""
	hint_timer.stop()
	hint_label.visible = false
	_clear_container(debrief_sections)
	final_message.text = str(_station_data.get("debrief", {}).get("final_message", ""))
	_build_debrief_sections()
	await complete_continue.pressed

func _build_debrief_sections() -> void:
	var debrief: Dictionary = _station_data.get("debrief", {})
	var sections: Array = debrief.get("sections", [])
	var summaries := [
		"The chain showed this is an uncertain testing failure with direct quality and schedule impact.",
		"You assessed probability as %s. Medium or High both recognized this as more than a minor edge case." % _selected_probability.capitalize(),
		"Your impact assessment considered cost, schedule, quality, and scope, then the ripple confirmed where the damage lands.",
		"The risk landed in the %s quadrant, which frames it as a top-priority fire to manage." % str(_matrix_result.get("correct", "wildfire")).capitalize(),
		"You chose %s. %s" % [_selected_strategy.capitalize(), str(_station_data.get("response_options", {}).get(_selected_strategy, {}).get("summary_text", ""))],
		"Here's another perspective: %s" % str(debrief.get("textbook_response", ""))
	]
	for index in range(min(sections.size(), summaries.size())):
		debrief_sections.add_child(_make_debrief_entry(str(sections[index]), summaries[index]))
	if not _investigated_alex:
		debrief_sections.add_child(_make_debrief_entry("Investigation note", "You skipped Alex's input, so your choice relied more on assumptions than evidence."))

func _make_debrief_entry(title_text: String, body_text: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", StyleConstants.create_panel_stylebox(Color(0.10, 0.13, 0.17, 0.95), StyleConstants.COLOR_ACCENT_SECONDARY, 1))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = title_text
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_color_override("font_color", StyleConstants.COLOR_ACCENT_PRIMARY)
	title.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_SM)
	vbox.add_child(title)

	var body := Label.new()
	body.text = body_text
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_color_override("font_color", StyleConstants.COLOR_TEXT_PRIMARY)
	body.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_SM)
	vbox.add_child(body)
	return panel

func _spawn_profile_card() -> void:
	_clear_container(profile_card_container)
	var card := PROFILE_CARD_SCENE.instantiate()
	_prepare_embedded_component(card, profile_card_container)
	card.setup({
		"mode": "display",
		"character_name": str(_client_profile.get("name", "Dana")),
		"company": str(_client_profile.get("company", "SecurePay")),
		"avatar": str(_client_profile.get("avatar_path", "")),
		"stats": {
			"budget_tolerance": str(_client_profile.get("budget_tolerance", "high")),
			"schedule_flexibility": str(_client_profile.get("schedule_flexibility", "low")),
			"quality_standards": str(_client_profile.get("quality_standards", "high")),
			"scope_flexibility": str(_client_profile.get("scope_flexibility", "high"))
		}
	})
	if card.has_node("CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ContinueButton"):
		card.get_node("CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ContinueButton").visible = false

func _build_impact_grid() -> void:
	_clear_container(impact_grid)
	_current_impact_selections.clear()
	_dimension_buttons.clear()
	submit_impact.disabled = true
	StyleConstants.style_button(submit_impact, true, true)
	for dimension in DIMENSIONS:
		var label := Label.new()
		label.text = "%s Impact" % _display_dimension_name(dimension)
		label.add_theme_color_override("font_color", StyleConstants.COLOR_TEXT_PRIMARY)
		label.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_SM)
		impact_grid.add_child(label)
		_dimension_buttons[dimension] = {}
		for level in IMPACT_LEVELS:
			var button := Button.new()
			button.text = level.capitalize()
			button.custom_minimum_size = Vector2(84, 34)
			StyleConstants.style_button(button, false)
			button.pressed.connect(_on_impact_option_selected.bind(dimension, level))
			_dimension_buttons[dimension][level] = button
			impact_grid.add_child(button)

func _on_impact_option_selected(dimension: String, level: String) -> void:
	_register_activity()
	_current_impact_selections[dimension] = level
	for option in _dimension_buttons[dimension].keys():
		StyleConstants.style_button(_dimension_buttons[dimension][option], option == level)
	submit_impact.disabled = _current_impact_selections.size() < DIMENSIONS.size()
	StyleConstants.style_button(submit_impact, true, submit_impact.disabled)

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

func _wait_for_button_choice(buttons: Dictionary) -> String:
	for key in buttons.keys():
		var button: Button = buttons[key]
		if button.pressed.is_connected(_register_activity):
			button.pressed.disconnect(_register_activity)
		button.pressed.connect(_register_activity)
		button.pressed.connect(_emit_step_choice.bind(str(key)), CONNECT_ONE_SHOT)
	var choice: String = await step_choice_made
	return choice

func _emit_step_choice(choice: String) -> void:
	step_choice_made.emit(choice)

func _show_component(scene: PackedScene, data: Dictionary) -> void:
	_clear_container(component_container)
	var component := scene.instantiate()
	_prepare_embedded_component(component, component_container)
	component.setup(data)
	await component.completed

func _prepare_embedded_component(component: Control, container: Control) -> void:
	component.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.add_child(component)
	if component.has_node("DimBackground"):
		component.get_node("DimBackground").visible = false

func _clear_container(container: Node) -> void:
	for child in container.get_children():
		child.queue_free()

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
	GameManager.layer1_performance["station_6_strategy_chosen"] = _selected_strategy
	GameManager.layer1_performance["station_6_hints_used"] = _hint_usage_count
	GameManager.station_6_complete = true
	GameManager.layer1_complete = true
	SignalBus.station_completed.emit(6)
	SignalBus.layer_completed.emit(1, GameManager.layer1_performance)
	closed.emit()
	queue_free()
