extends Control

signal closed()

const GAME_THEME := preload("res://themes/game_theme.tres")
const EVIDENCE_SCENE := preload("res://scenes/components/EvidenceColumns.tscn")

@onready var dim_background: ColorRect = $DimBackground
@onready var content_panel: PanelContainer = $ContentPanel
@onready var intro_container: VBoxContainer = $ContentPanel/MarginContainer/VBoxContainer/IntroContainer
@onready var intro_text: RichTextLabel = $ContentPanel/MarginContainer/VBoxContainer/IntroContainer/IntroText
@onready var intro_continue: Button = $ContentPanel/MarginContainer/VBoxContainer/IntroContainer/IntroContinue
@onready var exercise_container: VBoxContainer = $ContentPanel/MarginContainer/VBoxContainer/ExerciseContainer
@onready var progress_label: Label = $ContentPanel/MarginContainer/VBoxContainer/ExerciseContainer/ProgressLabel
@onready var risk_text: RichTextLabel = $ContentPanel/MarginContainer/VBoxContainer/ExerciseContainer/RiskText
@onready var feedback_label: Label = $ContentPanel/MarginContainer/VBoxContainer/ExerciseContainer/FeedbackLabel
@onready var scale_container: HBoxContainer = $ContentPanel/MarginContainer/VBoxContainer/ExerciseContainer/ScaleContainer
@onready var low_button: Button = $ContentPanel/MarginContainer/VBoxContainer/ExerciseContainer/ScaleContainer/LowZone/ZoneButton
@onready var medium_button: Button = $ContentPanel/MarginContainer/VBoxContainer/ExerciseContainer/ScaleContainer/MediumZone/ZoneButton
@onready var high_button: Button = $ContentPanel/MarginContainer/VBoxContainer/ExerciseContainer/ScaleContainer/HighZone/ZoneButton
@onready var low_cards: VBoxContainer = $ContentPanel/MarginContainer/VBoxContainer/ExerciseContainer/ScaleContainer/LowZone/PlacedCards
@onready var medium_cards: VBoxContainer = $ContentPanel/MarginContainer/VBoxContainer/ExerciseContainer/ScaleContainer/MediumZone/PlacedCards
@onready var high_cards: VBoxContainer = $ContentPanel/MarginContainer/VBoxContainer/ExerciseContainer/ScaleContainer/HighZone/PlacedCards
@onready var evidence_overlay_container: Control = $ContentPanel/MarginContainer/VBoxContainer/ExerciseContainer/EvidenceOverlayContainer
@onready var debrief_container: VBoxContainer = $ContentPanel/MarginContainer/VBoxContainer/DebriefContainer
@onready var debrief_title: Label = $ContentPanel/MarginContainer/VBoxContainer/DebriefContainer/DebriefTitle
@onready var ordered_risks_list: VBoxContainer = $ContentPanel/MarginContainer/VBoxContainer/DebriefContainer/OrderedRisksList
@onready var conclusion_text: RichTextLabel = $ContentPanel/MarginContainer/VBoxContainer/DebriefContainer/ConclusionText
@onready var debrief_continue: Button = $ContentPanel/MarginContainer/VBoxContainer/DebriefContainer/DebriefContinue

var _station_data: Dictionary = {}
var _risks: Array = []
var _current_index := 0
var _correct_count := 0
var _placements: Array = []

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
	intro_text.add_theme_color_override("default_color", StyleConstants.COLOR_TEXT_PRIMARY)
	progress_label.add_theme_color_override("font_color", StyleConstants.COLOR_TEXT_MUTED)
	progress_label.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_XS)
	risk_text.add_theme_color_override("default_color", StyleConstants.COLOR_TEXT_PRIMARY)
	debrief_title.add_theme_color_override("font_color", StyleConstants.COLOR_ACCENT_PRIMARY)
	debrief_title.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_LG)
	conclusion_text.add_theme_color_override("default_color", StyleConstants.COLOR_TEXT_PRIMARY)
	for zone in [
		$ContentPanel/MarginContainer/VBoxContainer/ExerciseContainer/ScaleContainer/LowZone,
		$ContentPanel/MarginContainer/VBoxContainer/ExerciseContainer/ScaleContainer/MediumZone,
		$ContentPanel/MarginContainer/VBoxContainer/ExerciseContainer/ScaleContainer/HighZone
	]:
		var label: Label = zone.get_node("ZoneLabel")
		label.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_SM)
		label.add_theme_color_override("font_color", StyleConstants.COLOR_TEXT_PRIMARY)
	StyleConstants.style_button(intro_continue, true)
	StyleConstants.style_button(low_button, false)
	StyleConstants.style_button(medium_button, false)
	StyleConstants.style_button(high_button, false)
	StyleConstants.style_button(debrief_continue, true)

func _load_data() -> void:
	var layer1_data: Dictionary = DataManager.get_phase_data("stations", 1)
	var stations_data = layer1_data.get("stations", {})
	if stations_data is Dictionary:
		_station_data = stations_data.get("station_2", {})
	elif stations_data is Array:
		for station in stations_data:
			if station.get("station_number", 0) == 2:
				_station_data = station
				break
	_risks = _station_data.get("risks", [])
	if _risks.is_empty():
		push_warning("Station2_Probability: no probability data found.")

func _show_intro() -> void:
	intro_container.visible = true
	exercise_container.visible = false
	debrief_container.visible = false
	intro_text.text = str(_station_data.get("intro_prompt", "Now that you know what risks look like on SecurePay, let's figure out which ones are most likely to actually happen."))
	if intro_continue.pressed.is_connected(_start_exercise):
		intro_continue.pressed.disconnect(_start_exercise)
	intro_continue.pressed.connect(_start_exercise)

func _start_exercise() -> void:
	intro_container.visible = false
	exercise_container.visible = true
	_show_risk(_current_index)

func _show_risk(index: int) -> void:
	if index >= _risks.size():
		_show_debrief()
		return

	var risk: Dictionary = _risks[index]
	progress_label.text = "Risk %d of %d" % [index + 1, _risks.size()]
	risk_text.text = str(risk.get("risk_event", risk.get("text", "")))
	feedback_label.visible = false
	scale_container.visible = true
	_set_zone_buttons_enabled(true)
	_reconnect_zone_buttons(risk)

func _reconnect_zone_buttons(risk: Dictionary) -> void:
	for button in [low_button, medium_button, high_button]:
		for conn in button.get_signal_connection_list("pressed"):
			button.disconnect("pressed", conn["callable"])
	low_button.pressed.connect(func() -> void:
		_on_zone_selected("low", risk)
	)
	medium_button.pressed.connect(func() -> void:
		_on_zone_selected("medium", risk)
	)
	high_button.pressed.connect(func() -> void:
		_on_zone_selected("high", risk)
	)

func _on_zone_selected(player_zone: String, risk: Dictionary) -> void:
	var correct_zone := str(risk.get("correct_zone", "medium"))
	var is_correct := player_zone == correct_zone
	if is_correct:
		_correct_count += 1

	_placements.append({
		"risk_text": str(risk.get("risk_event", risk.get("text", ""))),
		"player_zone": player_zone,
		"correct_zone": correct_zone,
		"correct": is_correct
	})

	_set_zone_buttons_enabled(false)

	feedback_label.visible = true
	if is_correct:
		feedback_label.text = "Correct!"
		feedback_label.add_theme_color_override("font_color", StyleConstants.COLOR_HEALTH_GOOD)
	else:
		feedback_label.text = "Not quite - it's actually %s probability." % correct_zone.capitalize()
		feedback_label.add_theme_color_override("font_color", StyleConstants.COLOR_HEALTH_WARNING)

	await get_tree().create_timer(1.0).timeout
	feedback_label.visible = false

	var evidence_data: Dictionary = risk.get("evidence", {})
	if not evidence_data.is_empty():
		var evidence = EVIDENCE_SCENE.instantiate()
		evidence.setup(evidence_data)
		evidence_overlay_container.add_child(evidence)
		await evidence.completed

	_add_placed_label(correct_zone, str(risk.get("risk_event", risk.get("text", ""))))
	_current_index += 1
	_show_risk(_current_index)

func _set_zone_buttons_enabled(enabled: bool) -> void:
	for button in [low_button, medium_button, high_button]:
		button.disabled = not enabled

func _add_placed_label(zone: String, text_value: String) -> void:
	var placed_label := Label.new()
	var clipped := text_value
	if clipped.length() > 30:
		clipped = clipped.substr(0, 30) + "..."
	placed_label.text = "• " + clipped
	placed_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	placed_label.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_XS)
	placed_label.add_theme_color_override("font_color", StyleConstants.COLOR_TEXT_SECONDARY)
	match zone:
		"low":
			low_cards.add_child(placed_label)
		"medium":
			medium_cards.add_child(placed_label)
		"high":
			high_cards.add_child(placed_label)

func _show_debrief() -> void:
	exercise_container.visible = false
	debrief_container.visible = true
	for child in ordered_risks_list.get_children():
		child.queue_free()

	var ordered := _placements.duplicate(true)
	var zone_order := {"low": 0, "medium": 1, "high": 2}
	ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return zone_order.get(str(a.get("correct_zone", "medium")), 1) < zone_order.get(str(b.get("correct_zone", "medium")), 1)
	)

	for placement in ordered:
		var item := HBoxContainer.new()
		item.add_theme_constant_override("separation", 10)

		var zone_label := Label.new()
		var zone := str(placement.get("correct_zone", "medium"))
		zone_label.text = "[%s]" % zone.to_upper()
		zone_label.custom_minimum_size.x = 70
		zone_label.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_XS)
		match zone:
			"low":
				zone_label.add_theme_color_override("font_color", StyleConstants.COLOR_HEALTH_GOOD)
			"medium":
				zone_label.add_theme_color_override("font_color", StyleConstants.COLOR_HEALTH_WARNING)
			"high":
				zone_label.add_theme_color_override("font_color", StyleConstants.COLOR_HEALTH_CRITICAL)
		item.add_child(zone_label)

		var risk_label := Label.new()
		risk_label.text = str(placement.get("risk_text", ""))
		risk_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		risk_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		risk_label.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_XS)
		risk_label.add_theme_color_override("font_color", StyleConstants.COLOR_TEXT_PRIMARY)
		item.add_child(risk_label)

		ordered_risks_list.add_child(item)

	conclusion_text.text = str(_station_data.get("debrief_message", "Probability isn't a guess - it's a judgment built on evidence. When you assess risk in a real project, you'll look at historical data, team experience, project conditions, and industry patterns."))
	if debrief_continue.pressed.is_connected(_complete_station):
		debrief_continue.pressed.disconnect(_complete_station)
	debrief_continue.pressed.connect(_complete_station)

func _complete_station() -> void:
	var total := maxi(_risks.size(), 1)
	GameManager.layer1_performance["station_2_accuracy"] = float(_correct_count) / float(total)
	GameManager.station_2_complete = true
	SignalBus.station_completed.emit(2)
	closed.emit()
	queue_free()
