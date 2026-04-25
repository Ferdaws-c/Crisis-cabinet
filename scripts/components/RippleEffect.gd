extends Control

signal completed(result: Dictionary)
signal closed()

const GAME_THEME := preload("res://themes/game_theme.tres")

@onready var dim_background: ColorRect = $DimBackground
@onready var root_panel: PanelContainer = $CenterContainer/PanelContainer
@onready var title_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TitleLabel
@onready var steps_container: VBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/StepsContainer
@onready var summary_container: HBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/SummaryContainer
@onready var budget_value_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/SummaryContainer/BudgetSummary/ValueLabel
@onready var schedule_value_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/SummaryContainer/ScheduleSummary/ValueLabel
@onready var quality_value_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/SummaryContainer/QualitySummary/ValueLabel
@onready var trust_value_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/SummaryContainer/TrustSummary/ValueLabel
@onready var budget_summary: VBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/SummaryContainer/BudgetSummary
@onready var schedule_summary: VBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/SummaryContainer/ScheduleSummary
@onready var quality_summary: VBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/SummaryContainer/QualitySummary
@onready var trust_summary: VBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/SummaryContainer/TrustSummary
@onready var continue_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ContinueButton

var _data: Dictionary = {}
var _is_ready := false
var _has_setup := false

func _ready() -> void:
	theme = GAME_THEME
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_is_ready = true
	_apply_styles()
	summary_container.modulate.a = 0.0
	continue_button.visible = false
	continue_button.pressed.connect(_on_continue_pressed)

	if _has_setup:
		_apply_data()
		_start_animation.call_deferred()

func setup(data: Dictionary) -> void:
	_data = data.duplicate(true)
	_has_setup = true
	if not _is_ready:
		return
	_apply_data()
	_start_animation.call_deferred()

func _apply_styles() -> void:
	dim_background.color = StyleConstants.COLOR_BG_DIM
	root_panel.add_theme_stylebox_override("panel", StyleConstants.create_panel_stylebox())
	title_label.add_theme_color_override("font_color", StyleConstants.COLOR_ACCENT_PRIMARY)
	title_label.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_LG)
	StyleConstants.style_button(continue_button, true)

func _apply_data() -> void:
	for child in steps_container.get_children():
		child.queue_free()
	summary_container.modulate.a = 0.0
	continue_button.visible = false
	_apply_summary(_data.get("summary", {}))

func _start_animation() -> void:
	await get_tree().process_frame
	var steps: Array = _data.get("steps", [])
	for step in steps:
		var step_panel := _create_step_panel(step)
		steps_container.add_child(step_panel)
		await _fade_in_node(step_panel, 0.4)
		await get_tree().create_timer(0.5).timeout

	await get_tree().create_timer(0.3).timeout
	await _fade_in_node(summary_container, 0.4)
	continue_button.visible = true
	continue_button.grab_focus()

func _create_step_panel(step: Dictionary) -> HBoxContainer:
	var panel := HBoxContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_constant_override("separation", 16)

	var desc_label := Label.new()
	desc_label.text = str(step.get("description", ""))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_color_override("font_color", StyleConstants.COLOR_TEXT_PRIMARY)
	desc_label.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_MD)
	desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(desc_label)

	var delta_label := Label.new()
	delta_label.text = "-> %s: %s" % [_get_dimension_display_name(str(step.get("dimension", ""))), str(step.get("delta", ""))]
	delta_label.add_theme_color_override("font_color", StyleConstants.get_dimension_color(str(step.get("dimension", ""))))
	delta_label.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_SM)
	delta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	panel.add_child(delta_label)

	panel.modulate.a = 0.0
	return panel

func _apply_summary(summary: Dictionary) -> void:
	_set_summary_value(budget_summary, budget_value_label, int(summary.get("budget", 0)), "budget")
	_set_summary_value(schedule_summary, schedule_value_label, int(summary.get("schedule", 0)), "schedule")
	_set_summary_value(quality_summary, quality_value_label, int(summary.get("quality", 0)), "quality")
	_set_summary_value(trust_summary, trust_value_label, int(summary.get("stakeholder_trust", 0)), "stakeholder_trust")

func _set_summary_value(container: VBoxContainer, value_label: Label, value: int, dimension: String) -> void:
	container.visible = value != 0
	if value == 0:
		return

	value_label.text = _format_summary_delta(value)
	var color := StyleConstants.get_dimension_color(dimension) if value < 0 else StyleConstants.COLOR_HEALTH_GOOD
	value_label.add_theme_color_override("font_color", color)
	value_label.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_SM)

func _format_summary_delta(value: int) -> String:
	return "%+d" % value

func _get_dimension_display_name(dimension: String) -> String:
	match dimension:
		"stakeholder_trust":
			return "Trust"
		_:
			return dimension.capitalize()

func _fade_in_node(node: CanvasItem, duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(node, "modulate:a", 1.0, duration)
	await tween.finished

func _on_continue_pressed() -> void:
	completed.emit({})
	closed.emit()
	queue_free()
