extends Control

signal completed(result: Dictionary)
signal closed()

const GAME_THEME := preload("res://themes/game_theme.tres")

@onready var dim_background: ColorRect = $DimBackground
@onready var root_panel: PanelContainer = $CenterContainer/PanelContainer
@onready var phase_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/PhaseLabel
@onready var risk_processing_container: VBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/RiskProcessingContainer
@onready var risk_title_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/RiskProcessingContainer/RiskTitleLabel
@onready var probability_info: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/RiskProcessingContainer/ProbabilityInfo
@onready var roll_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/RiskProcessingContainer/RollAnimation/RollLabel
@onready var result_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/RiskProcessingContainer/RollAnimation/ResultLabel
@onready var roll_explanation: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/RiskProcessingContainer/RollExplanation
@onready var phase_summary_container: VBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/PhaseSummaryContainer
@onready var summary_title: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/PhaseSummaryContainer/SummaryTitle
@onready var triggered_list: VBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/PhaseSummaryContainer/TriggeredList
@onready var resolved_list: VBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/PhaseSummaryContainer/ResolvedList
@onready var spawned_list: VBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/PhaseSummaryContainer/SpawnedList
@onready var health_changes_summary: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/PhaseSummaryContainer/HealthChangesSummary
@onready var continue_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ContinueButton

var _data: Dictionary = {}
var _active_risks: Array = []
var _results := {
	"triggered": [],
	"resolved": [],
	"spawned": [],
	"health_changes": {
		"budget": 0,
		"schedule": 0,
		"quality": 0,
		"stakeholder_trust": 0
	}
}
var _is_ready := false
var _has_setup := false
var _in_summary := false

func _ready() -> void:
	theme = GAME_THEME
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	randomize()
	_is_ready = true
	_apply_styles()
	phase_summary_container.visible = false
	phase_summary_container.modulate.a = 0.0
	continue_button.visible = false
	continue_button.pressed.connect(_on_continue_pressed)

	if _has_setup:
		_begin_resolution.call_deferred()

func setup(data: Dictionary) -> void:
	_data = data.duplicate(true)
	_active_risks = _data.get("active_risks", []).duplicate(true)
	_has_setup = true
	if not _is_ready:
		return
	_begin_resolution.call_deferred()

func _apply_styles() -> void:
	dim_background.color = StyleConstants.COLOR_BG_DIM
	root_panel.add_theme_stylebox_override("panel", StyleConstants.create_panel_stylebox())
	phase_label.add_theme_color_override("font_color", StyleConstants.COLOR_ACCENT_PRIMARY)
	phase_label.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_LG)
	summary_title.add_theme_color_override("font_color", StyleConstants.COLOR_ACCENT_PRIMARY)
	summary_title.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_LG)
	risk_title_label.add_theme_color_override("font_color", StyleConstants.COLOR_TEXT_PRIMARY)
	risk_title_label.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_MD)
	probability_info.add_theme_color_override("font_color", StyleConstants.COLOR_TEXT_SECONDARY)
	probability_info.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_SM)
	roll_label.add_theme_color_override("font_color", StyleConstants.COLOR_TEXT_PRIMARY)
	roll_label.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_XL)
	result_label.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_LG)
	roll_explanation.add_theme_color_override("font_color", StyleConstants.COLOR_TEXT_MUTED)
	roll_explanation.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_SM)
	health_changes_summary.add_theme_color_override("font_color", StyleConstants.COLOR_TEXT_SECONDARY)
	StyleConstants.style_button(continue_button, false)

func _begin_resolution() -> void:
	_reset_summary_lists()
	phase_label.text = "Phase Resolution: %s" % str(_data.get("phase_name", "Unknown"))
	phase_summary_container.visible = false
	phase_summary_container.modulate.a = 0.0
	continue_button.visible = false
	risk_processing_container.visible = true
	risk_processing_container.modulate.a = 1.0
	result_label.text = ""
	roll_explanation.text = ""
	roll_label.text = ""
	_in_summary = false
	SignalBus.phase_resolution_started.emit()

	if _active_risks.is_empty():
		risk_processing_container.visible = false
		_add_summary_line(triggered_list, "No active risks this phase.", StyleConstants.COLOR_TEXT_SECONDARY)
		_show_phase_summary()
		return

	await _process_all_risks()
	_show_phase_summary()

func _process_all_risks() -> void:
	for risk in _active_risks:
		await _process_single_risk(risk)

func _process_single_risk(risk: Dictionary) -> void:
	var risk_id := str(risk.get("id", ""))
	var risk_title := str(risk.get("title", risk_id))
	var strategy := str(risk.get("response_strategy", "")).to_lower()
	var base_probability := int(risk.get("base_probability", 50))
	var modified_probability := _calculate_modified_probability(risk)

	risk_title_label.text = risk_title
	probability_info.text = _build_probability_text(base_probability, modified_probability, strategy)
	roll_label.text = ""
	result_label.text = ""
	roll_explanation.text = ""
	continue_button.visible = false
	risk_processing_container.modulate.a = 0.0
	var intro_tween := create_tween()
	intro_tween.tween_property(risk_processing_container, "modulate:a", 1.0, 0.2)
	await intro_tween.finished

	if strategy == "avoid" or modified_probability <= 0:
		roll_label.text = "AVOIDED"
		result_label.text = "SAFE"
		result_label.modulate = StyleConstants.COLOR_HEALTH_GOOD
		roll_explanation.text = "%s was eliminated by your strategy." % risk_title
		GameManager.update_risk(risk_id, {
			"status": "resolved",
			"triggered": false,
			"outcome_narrative": "Risk avoided."
		})
		SignalBus.risk_resolved.emit(GameManager.get_risk(risk_id))
		_add_resolved_result(risk_id, risk_title, base_probability, modified_probability, -1, "Risk avoided.")
		await _wait_for_next("Next Risk ->")
		return

	roll_label.text = "Rolling..."
	result_label.text = ""
	roll_explanation.text = ""
	await get_tree().create_timer(1.0).timeout

	var roll := randi_range(0, 99)
	var did_trigger := roll < modified_probability
	roll_label.text = "Roll: %d" % roll
	result_label.text = "TRIGGERED" if did_trigger else "SAFE"
	result_label.modulate = StyleConstants.COLOR_HEALTH_CRITICAL if did_trigger else StyleConstants.COLOR_HEALTH_GOOD
	if did_trigger:
		var result_tween := create_tween()
		result_label.scale = Vector2(0.92, 0.92)
		result_tween.tween_property(result_label, "scale", Vector2.ONE, 0.18)
	roll_explanation.text = _build_roll_explanation(risk, modified_probability, roll, did_trigger)
	await get_tree().create_timer(1.0).timeout

	if did_trigger:
		await _handle_triggered_risk(risk, base_probability, modified_probability, roll)
	else:
		await _handle_resolved_risk(risk, base_probability, modified_probability, roll)

	await _wait_for_next("Next Risk ->")

func _calculate_modified_probability(risk: Dictionary) -> int:
	var base := int(risk.get("base_probability", 50))
	var strategy := str(risk.get("response_strategy", "")).to_lower()
	var response_options: Dictionary = risk.get("response_options", {})

	match strategy:
		"avoid":
			return 0
		"mitigate":
			return int(response_options.get("mitigate", {}).get("probability_after", base))
		"transfer":
			return int(response_options.get("transfer", {}).get("probability_after", base))
		"accept":
			return int(response_options.get("accept", {}).get("probability_after", base))
		_:
			return base

func _build_probability_text(base_probability: int, modified_probability: int, strategy: String) -> String:
	if strategy == "" or strategy == "unassessed":
		return "Modified probability: %d%% (unassessed - using base probability)" % modified_probability
	if strategy == "avoid":
		return "Modified probability: 0%% (risk eliminated by Avoid strategy)"
	return "Modified probability: %d%% (was %d%%, adjusted by %s)" % [
		modified_probability,
		base_probability,
		strategy.capitalize()
	]

func _build_roll_explanation(risk: Dictionary, modified_probability: int, roll: int, did_trigger: bool) -> String:
	var strategy := str(risk.get("response_strategy", "")).to_lower()
	if strategy == "" or strategy == "unassessed":
		return "This risk was never assessed. The team was caught off guard." if did_trigger else "This risk stayed dormant despite having no planned response."
	if did_trigger:
		return "Your %s strategy set the threshold to %d%%. The roll was %d, so the risk materialized." % [
			strategy,
			modified_probability,
			roll
		]
	return "Your %s strategy set the threshold to %d%%. The roll was %d, so the risk did not materialize." % [
		strategy,
		modified_probability,
		roll
	]

func _handle_triggered_risk(risk: Dictionary, base_probability: int, modified_probability: int, roll: int) -> void:
	var risk_id := str(risk.get("id", ""))
	var risk_title := str(risk.get("title", risk_id))
	var trigger_data: Dictionary = risk.get("if_triggered", {})
	var health_impact: Dictionary = trigger_data.get("health_impact", {}).duplicate(true)
	var strategy := str(risk.get("response_strategy", "")).to_lower()

	if strategy == "" or strategy == "unassessed":
		health_impact["stakeholder_trust"] = int(health_impact.get("stakeholder_trust", 0)) - 10
		roll_explanation.text = "This risk was never assessed. The team was caught off guard."

	GameManager.apply_health_impact(health_impact)
	_accumulate_health_changes(health_impact)

	GameManager.update_risk(risk_id, {
		"status": "triggered",
		"triggered": true,
		"outcome_narrative": str(trigger_data.get("narrative", "The risk materialized."))
	})
	SignalBus.risk_triggered.emit(GameManager.get_risk(risk_id))

	if risk.has("ripple_steps") and risk.get("ripple_steps", []).size() > 0:
		var ripple_scene := load("res://scenes/components/RippleEffect.tscn")
		if ripple_scene:
			var ripple = ripple_scene.instantiate()
			add_child(ripple)
			ripple.setup({
				"steps": risk.get("ripple_steps", []),
				"summary": health_impact
			})
			await ripple.completed

	for spawn_id in trigger_data.get("spawns", []):
		_spawn_risk(str(spawn_id))

	for modify_entry in trigger_data.get("modifies", []):
		_apply_risk_modification(modify_entry)

	_results["triggered"].append({
		"risk_id": risk_id,
		"base_probability": base_probability,
		"modified_probability": modified_probability,
		"roll": roll,
		"triggered": true
	})
	_add_summary_line(triggered_list, "%s - %s" % [risk_title, str(trigger_data.get("narrative", "Triggered"))], StyleConstants.COLOR_HEALTH_CRITICAL)

func _handle_resolved_risk(risk: Dictionary, base_probability: int, modified_probability: int, roll: int) -> void:
	var risk_id := str(risk.get("id", ""))
	var risk_title := str(risk.get("title", risk_id))
	var resolved_data: Dictionary = risk.get("if_resolved", {})
	var health_impact: Dictionary = resolved_data.get("health_impact", {}).duplicate(true)

	if not health_impact.is_empty():
		GameManager.apply_health_impact(health_impact)
		_accumulate_health_changes(health_impact)

	var refund_amount := int(floor(float(int(risk.get("budget_allocated", 0))) * 0.5))
	if refund_amount > 0:
		GameManager.contingency_budget += refund_amount
		SignalBus.resources_changed.emit()
		GameManager.emit_signal("state_changed")

	GameManager.update_risk(risk_id, {
		"status": "resolved",
		"triggered": false,
		"outcome_narrative": str(resolved_data.get("narrative", "Resolved safely."))
	})
	SignalBus.risk_resolved.emit(GameManager.get_risk(risk_id))

	_results["resolved"].append({
		"risk_id": risk_id,
		"base_probability": base_probability,
		"modified_probability": modified_probability,
		"roll": roll,
		"triggered": false
	})
	_add_summary_line(resolved_list, "%s - Resolved safely" % risk_title, StyleConstants.COLOR_HEALTH_GOOD)

func _spawn_risk(spawn_id: String) -> void:
	var risk_data := DataManager.find_risk_by_id(spawn_id)
	if risk_data.is_empty():
		risk_data = {
			"id": spawn_id,
			"title": "Emerging risk: " + spawn_id,
			"status": "unassessed",
			"source_type": "cascaded",
			"phase_identified": str(GameManager.current_phase).to_lower()
		}
	else:
		risk_data["status"] = "unassessed"
		risk_data["source_type"] = "cascaded"
		risk_data["phase_identified"] = str(GameManager.current_phase).to_lower()

	GameManager.add_risk(risk_data)
	_results["spawned"].append(spawn_id)
	_add_summary_line(spawned_list, str(risk_data.get("title", spawn_id)), StyleConstants.COLOR_HEALTH_WARNING)

func _apply_risk_modification(modify_entry: Variant) -> void:
	if modify_entry is Dictionary:
		var entry: Dictionary = modify_entry
		var target_id := str(entry.get("risk_id", entry.get("id", "")))
		if target_id == "":
			return
		var updates := entry.get("updates", {}).duplicate(true)
		if updates.is_empty():
			for key in entry.keys():
				if key in ["risk_id", "id"]:
					continue
				updates[key] = entry[key]
		GameManager.update_risk(target_id, updates)

func _accumulate_health_changes(impact: Dictionary) -> void:
	for key in _results["health_changes"].keys():
		_results["health_changes"][key] += int(impact.get(key, 0))

func _wait_for_next(button_text: String) -> void:
	_in_summary = false
	continue_button.text = button_text
	StyleConstants.style_button(continue_button, false)
	continue_button.modulate.a = 0.0
	continue_button.visible = true
	continue_button.disabled = false
	var tween := create_tween()
	tween.tween_property(continue_button, "modulate:a", 1.0, 0.2)
	continue_button.grab_focus()
	await continue_button.pressed
	continue_button.visible = false

func _show_phase_summary() -> void:
	risk_processing_container.visible = false
	phase_summary_container.visible = true
	phase_summary_container.modulate.a = 0.0
	health_changes_summary.text = "Net health changes - Budget: %+d | Schedule: %+d | Quality: %+d | Trust: %+d" % [
		int(_results["health_changes"]["budget"]),
		int(_results["health_changes"]["schedule"]),
		int(_results["health_changes"]["quality"]),
		int(_results["health_changes"]["stakeholder_trust"])
	]
	continue_button.text = "Continue to next phase"
	StyleConstants.style_button(continue_button, true)
	continue_button.modulate.a = 0.0
	continue_button.visible = true
	_in_summary = true
	var tween := create_tween()
	tween.tween_property(phase_summary_container, "modulate:a", 1.0, 0.25)
	tween.parallel().tween_property(continue_button, "modulate:a", 1.0, 0.25)
	continue_button.grab_focus()

func _reset_summary_lists() -> void:
	_results = {
		"triggered": [],
		"resolved": [],
		"spawned": [],
		"health_changes": {
			"budget": 0,
			"schedule": 0,
			"quality": 0,
			"stakeholder_trust": 0
		}
	}
	for list_container in [triggered_list, resolved_list, spawned_list]:
		for child in list_container.get_children():
			child.queue_free()

func _add_summary_line(container: VBoxContainer, text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_SM)
	container.add_child(label)

func _add_resolved_result(risk_id: String, risk_title: String, base_probability: int, modified_probability: int, roll: int, narrative: String) -> void:
	_results["resolved"].append({
		"risk_id": risk_id,
		"base_probability": base_probability,
		"modified_probability": modified_probability,
		"roll": roll,
		"triggered": false
	})
	_add_summary_line(resolved_list, "%s - %s" % [risk_title, narrative], StyleConstants.COLOR_HEALTH_GOOD)

func _on_continue_pressed() -> void:
	if not _in_summary:
		return
	completed.emit(_results)
	closed.emit()
	queue_free()
