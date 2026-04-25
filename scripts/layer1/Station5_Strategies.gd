extends Control

signal closed()

const GAME_THEME := preload("res://themes/game_theme.tres")
const NPC_DIALOGUE_SCENE := preload("res://scenes/components/NPCDialogue.tscn")
const RIPPLE_SCENE := preload("res://scenes/components/RippleEffect.tscn")

const STRATEGY_ORDER := ["avoid", "mitigate", "transfer", "accept"]

@onready var dim_background: ColorRect = $DimBackground
@onready var content_panel: PanelContainer = $ContentPanel
@onready var step_label: Label = $ContentPanel/MarginContainer/VBoxContainer/StepLabel
@onready var intro_container: VBoxContainer = $ContentPanel/MarginContainer/VBoxContainer/IntroContainer
@onready var risk_description: RichTextLabel = $ContentPanel/MarginContainer/VBoxContainer/IntroContainer/RiskDescription
@onready var investigate_prompt: Label = $ContentPanel/MarginContainer/VBoxContainer/IntroContainer/InvestigatePrompt
@onready var talk_to_jordan_button: Button = $ContentPanel/MarginContainer/VBoxContainer/IntroContainer/TalkToJordanButton
@onready var dialogue_container: Control = $ContentPanel/MarginContainer/VBoxContainer/IntroContainer/DialogueContainer
@onready var exploration_container: VBoxContainer = $ContentPanel/MarginContainer/VBoxContainer/ExplorationContainer
@onready var strategies_grid: GridContainer = $ContentPanel/MarginContainer/VBoxContainer/ExplorationContainer/StrategiesGrid
@onready var ripple_container: Control = $ContentPanel/MarginContainer/VBoxContainer/ExplorationContainer/RippleContainer
@onready var choose_button: Button = $ContentPanel/MarginContainer/VBoxContainer/ExplorationContainer/ChooseButton
@onready var choice_container: VBoxContainer = $ContentPanel/MarginContainer/VBoxContainer/ChoiceContainer
@onready var choice_buttons: HBoxContainer = $ContentPanel/MarginContainer/VBoxContainer/ChoiceContainer/ChoiceButtons
@onready var analysis_panel: PanelContainer = $ContentPanel/MarginContainer/VBoxContainer/ChoiceContainer/AnalysisPanel
@onready var analysis_text: RichTextLabel = $ContentPanel/MarginContainer/VBoxContainer/ChoiceContainer/AnalysisPanel/MarginContainer/AnalysisText
@onready var analysis_note: Label = $ContentPanel/MarginContainer/VBoxContainer/ChoiceContainer/AnalysisNote
@onready var choice_continue: Button = $ContentPanel/MarginContainer/VBoxContainer/ChoiceContainer/ChoiceContinue
@onready var reference_container: VBoxContainer = $ContentPanel/MarginContainer/VBoxContainer/ReferenceContainer
@onready var ref_grid: GridContainer = $ContentPanel/MarginContainer/VBoxContainer/ReferenceContainer/RefGrid
@onready var ref_continue: Button = $ContentPanel/MarginContainer/VBoxContainer/ReferenceContainer/RefContinue

var _station_data: Dictionary = {}
var _dialogue_data: Dictionary = {}
var _npc_info: Dictionary = {}
var _response_options: Dictionary = {}
var _explored := {
	"avoid": false,
	"mitigate": false,
	"transfer": false,
	"accept": false
}
var _strategy_panels: Dictionary = {}
var _chosen_strategy := ""
var _investigated := false

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
	step_label.add_theme_color_override("font_color", StyleConstants.COLOR_TEXT_MUTED)
	step_label.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_XS)
	risk_description.add_theme_color_override("default_color", StyleConstants.COLOR_TEXT_PRIMARY)
	investigate_prompt.add_theme_color_override("font_color", StyleConstants.COLOR_TEXT_SECONDARY)
	investigate_prompt.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_SM)
	$ContentPanel/MarginContainer/VBoxContainer/ExplorationContainer/ExploreTitle.add_theme_color_override("font_color", StyleConstants.COLOR_ACCENT_PRIMARY)
	$ContentPanel/MarginContainer/VBoxContainer/ExplorationContainer/ExploreTitle.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_LG)
	$ContentPanel/MarginContainer/VBoxContainer/ExplorationContainer/ExploreInstruction.add_theme_color_override("font_color", StyleConstants.COLOR_TEXT_MUTED)
	$ContentPanel/MarginContainer/VBoxContainer/ChoiceContainer/ChoiceTitle.add_theme_color_override("font_color", StyleConstants.COLOR_ACCENT_PRIMARY)
	$ContentPanel/MarginContainer/VBoxContainer/ChoiceContainer/ChoiceTitle.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_LG)
	$ContentPanel/MarginContainer/VBoxContainer/ReferenceContainer/RefTitle.add_theme_color_override("font_color", StyleConstants.COLOR_ACCENT_PRIMARY)
	$ContentPanel/MarginContainer/VBoxContainer/ReferenceContainer/RefTitle.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_LG)
	analysis_panel.add_theme_stylebox_override("panel", StyleConstants.create_panel_stylebox(Color(0.10, 0.13, 0.17, 0.95), StyleConstants.COLOR_ACCENT_PRIMARY, 1))
	analysis_text.add_theme_color_override("default_color", StyleConstants.COLOR_TEXT_PRIMARY)
	analysis_note.add_theme_color_override("font_color", StyleConstants.COLOR_TEXT_MUTED)
	analysis_note.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_SM)
	StyleConstants.style_button(talk_to_jordan_button, true)
	StyleConstants.style_button(choose_button, true, true)
	StyleConstants.style_button(choice_continue, true)
	StyleConstants.style_button(ref_continue, true)

func _load_data() -> void:
	var layer1_data: Dictionary = DataManager.get_phase_data("stations", 1)
	var stations_data = layer1_data.get("stations", {})
	if stations_data is Dictionary:
		_station_data = stations_data.get("station_5", {})
	var investigation: Dictionary = _station_data.get("investigation", {})
	var npc_id := str(investigation.get("npc_id", "jordan"))
	var dialogue_id := str(investigation.get("dialogue_id", ""))
	_dialogue_data = DataManager.get_dialogue(npc_id, dialogue_id)
	_npc_info = DataManager.get_npc_info(npc_id)
	_response_options = _station_data.get("response_options", {}).duplicate(true)

func _run_station() -> void:
	await _run_intro_step()
	await _run_exploration_step()
	await _run_choice_step()
	await _run_reference_step()
	_complete_station()

func _hide_all_step_containers() -> void:
	intro_container.visible = false
	exploration_container.visible = false
	choice_container.visible = false
	reference_container.visible = false

func _show_only(target: Control) -> void:
	_hide_all_step_containers()
	target.visible = true

func _run_intro_step() -> void:
	_show_only(intro_container)
	step_label.text = "Step 1 of 4: Investigate the Risk"
	risk_description.text = str(_station_data.get("scenario", ""))
	_clear_container(dialogue_container)
	await talk_to_jordan_button.pressed
	_investigated = true
	var dialogue := NPC_DIALOGUE_SCENE.instantiate()
	_prepare_embedded_component(dialogue, dialogue_container)
	dialogue.setup({
		"npc_name": str(_npc_info.get("display_name", "Jordan")),
		"npc_role": str(_npc_info.get("role", "Senior Developer")),
		"npc_avatar": str(_npc_info.get("avatar_path", "")),
		"dialogue_tree": _dialogue_data.get("tree", [])
	})
	await dialogue.completed

func _run_exploration_step() -> void:
	_show_only(exploration_container)
	step_label.text = "Step 2 of 4: Explore All Four Strategies"
	_build_strategy_panels()
	choose_button.disabled = true
	StyleConstants.style_button(choose_button, true, true)
	await choose_button.pressed

func _build_strategy_panels() -> void:
	_clear_container(strategies_grid)
	_strategy_panels.clear()
	for strategy_name in STRATEGY_ORDER:
		var panel := _create_strategy_panel(strategy_name, _response_options.get(strategy_name, {}))
		strategies_grid.add_child(panel)
		_strategy_panels[strategy_name] = panel

func _create_strategy_panel(strategy_name: String, option: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(360, 190)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", StyleConstants.create_panel_stylebox())

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var header := Label.new()
	header.text = strategy_name.to_upper()
	header.add_theme_color_override("font_color", StyleConstants.COLOR_ACCENT_PRIMARY)
	header.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_SM)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(header)

	var description := Label.new()
	description.text = str(option.get("description", ""))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_color_override("font_color", StyleConstants.COLOR_TEXT_PRIMARY)
	description.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_SM)
	description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(description)

	var explore_button := Button.new()
	explore_button.text = "See what happens"
	StyleConstants.style_button(explore_button, false)
	explore_button.pressed.connect(_on_explore_strategy_pressed.bind(strategy_name))
	vbox.add_child(explore_button)

	var summary := RichTextLabel.new()
	summary.bbcode_enabled = false
	summary.fit_content = true
	summary.scroll_active = false
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.visible = false
	summary.add_theme_color_override("default_color", StyleConstants.COLOR_TEXT_SECONDARY)
	summary.custom_minimum_size = Vector2(0, 70)
	vbox.add_child(summary)

	var check := Label.new()
	check.text = "Explored ✓"
	check.visible = false
	check.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	check.add_theme_color_override("font_color", StyleConstants.COLOR_ACCENT_PRIMARY)
	check.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_SM)
	vbox.add_child(check)

	panel.set_meta("explore_button", explore_button)
	panel.set_meta("summary", summary)
	panel.set_meta("check", check)
	return panel

func _on_explore_strategy_pressed(strategy_name: String) -> void:
	await _explore_strategy(strategy_name)

func _explore_strategy(strategy_name: String) -> void:
	var option: Dictionary = _response_options.get(strategy_name, {})
	_clear_container(ripple_container)
	var ripple := RIPPLE_SCENE.instantiate()
	_prepare_embedded_component(ripple, ripple_container)
	ripple.setup({
		"steps": option.get("ripple_steps", []),
		"summary": _build_ripple_summary(option.get("ripple_steps", []))
	})
	await ripple.completed

	_explored[strategy_name] = true
	var panel: PanelContainer = _strategy_panels.get(strategy_name)
	if panel:
		var summary: RichTextLabel = panel.get_meta("summary")
		var check: Label = panel.get_meta("check")
		summary.text = "%s\n\n%s" % [
			str(option.get("action", "")),
			str(option.get("summary_text", ""))
		]
		summary.visible = true
		check.visible = true
		panel.add_theme_stylebox_override("panel", StyleConstants.create_panel_stylebox(Color(0.10, 0.16, 0.17, 0.96), StyleConstants.COLOR_ACCENT_PRIMARY, 2))

	_update_choose_button_state()

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

func _update_choose_button_state() -> void:
	var all_explored := true
	for strategy_name in STRATEGY_ORDER:
		if not _explored.get(strategy_name, false):
			all_explored = false
			break
	choose_button.disabled = not all_explored
	StyleConstants.style_button(choose_button, true, choose_button.disabled)

func _run_choice_step() -> void:
	_show_only(choice_container)
	step_label.text = "Step 3 of 4: Make an Informed Choice"
	_build_choice_buttons()
	analysis_text.text = ""
	choice_continue.visible = false
	await choice_continue.pressed

func _build_choice_buttons() -> void:
	_clear_container(choice_buttons)
	for strategy_name in STRATEGY_ORDER:
		var button := Button.new()
		button.text = strategy_name.capitalize()
		button.custom_minimum_size = Vector2(150, 40)
		StyleConstants.style_button(button, false)
		button.pressed.connect(_on_choice_selected.bind(strategy_name))
		choice_buttons.add_child(button)

func _on_choice_selected(strategy_name: String) -> void:
	_chosen_strategy = strategy_name
	analysis_text.text = "%s\n\nThere's rarely one perfect answer - the skill is in matching the strategy to the risk profile and your constraints." % [
		str(_station_data.get("tradeoff_analysis", {}).get(strategy_name, ""))
	]
	choice_continue.visible = true

func _run_reference_step() -> void:
	_show_only(reference_container)
	step_label.text = "Step 4 of 4: Strategy Reference"
	_build_reference_cards()
	await ref_continue.pressed

func _build_reference_cards() -> void:
	_clear_container(ref_grid)
	for entry in _station_data.get("strategy_reference_summary", []):
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(360, 130)
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
		title.text = str(entry.get("strategy", "")).capitalize()
		title.add_theme_color_override("font_color", StyleConstants.COLOR_ACCENT_PRIMARY)
		title.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_SM)
		vbox.add_child(title)

		var desc := Label.new()
		desc.text = str(entry.get("description", ""))
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.add_theme_color_override("font_color", StyleConstants.COLOR_TEXT_PRIMARY)
		desc.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_SM)
		vbox.add_child(desc)

		var best_when := Label.new()
		best_when.text = "Best when: %s" % str(entry.get("best_used_when", ""))
		best_when.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		best_when.add_theme_color_override("font_color", StyleConstants.COLOR_TEXT_SECONDARY)
		best_when.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_SM)
		vbox.add_child(best_when)

		ref_grid.add_child(panel)

func _prepare_embedded_component(component: Control, container: Control) -> void:
	component.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.add_child(component)
	if component.has_node("DimBackground"):
		component.get_node("DimBackground").visible = false

func _clear_container(container: Node) -> void:
	for child in container.get_children():
		child.queue_free()

func _complete_station() -> void:
	GameManager.layer1_performance["station_5_strategy_chosen"] = _chosen_strategy
	GameManager.station_5_complete = true
	SignalBus.station_completed.emit(5)
	closed.emit()
	queue_free()

