extends PanelContainer

signal assess_requested(risk_id: String)
signal respond_requested(risk_id: String)
signal investigate_requested(risk_id: String)

var _risk_data: Dictionary = {}
var _expanded := false

@onready var category_indicator: ColorRect = $VBoxContainer/TopRow/CategoryIndicator
@onready var title_label: Label = $VBoxContainer/TopRow/TitleLabel
@onready var status_badge: Label = $VBoxContainer/TopRow/StatusBadge
@onready var details_row: HBoxContainer = $VBoxContainer/DetailsRow
@onready var prob_label: Label = $VBoxContainer/DetailsRow/ProbLabel
@onready var strategy_label: Label = $VBoxContainer/DetailsRow/StrategyLabel
@onready var cost_label: Label = $VBoxContainer/DetailsRow/CostLabel
@onready var actions_row: HBoxContainer = $VBoxContainer/ActionsRow

func _ready() -> void:
	_connect_buttons()
	gui_input.connect(_on_gui_input)
	_apply_button_styles()
	if not _risk_data.is_empty():
		_update_display()

func setup(risk_data: Dictionary) -> void:
	_risk_data = risk_data.duplicate(true)
	if is_node_ready():
		_update_display()

func _connect_buttons() -> void:
	if actions_row.has_node("AssessButton"):
		actions_row.get_node("AssessButton").pressed.connect(func() -> void:
			assess_requested.emit(str(_risk_data.get("id", "")))
		)
	if actions_row.has_node("RespondButton"):
		actions_row.get_node("RespondButton").pressed.connect(func() -> void:
			respond_requested.emit(str(_risk_data.get("id", "")))
		)
	if actions_row.has_node("InvestigateButton"):
		actions_row.get_node("InvestigateButton").pressed.connect(func() -> void:
			investigate_requested.emit(str(_risk_data.get("id", "")))
		)
	if actions_row.has_node("ReassessButton"):
		actions_row.get_node("ReassessButton").pressed.connect(func() -> void:
			assess_requested.emit(str(_risk_data.get("id", "")))
		)

func _apply_button_styles() -> void:
	for child in actions_row.get_children():
		if child is Button:
			StyleConstants.style_button(child, false)

func _update_display() -> void:
	title_label.text = str(_risk_data.get("title", "Unknown Risk"))
	title_label.add_theme_color_override("font_color", StyleConstants.COLOR_TEXT_PRIMARY)
	title_label.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_XS)

	var category := str(_risk_data.get("matrix_category", ""))
	if category != "":
		category_indicator.color = StyleConstants.get_fire_color(category)
	else:
		category_indicator.color = StyleConstants.COLOR_TEXT_MUTED

	var status := str(_risk_data.get("status", "unassessed"))
	status_badge.text = status.capitalize()
	status_badge.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_XS)
	match status:
		"unassessed":
			status_badge.add_theme_color_override("font_color", StyleConstants.COLOR_HEALTH_WARNING)
		"triggered":
			status_badge.add_theme_color_override("font_color", StyleConstants.COLOR_HEALTH_CRITICAL)
		"resolved":
			status_badge.add_theme_color_override("font_color", StyleConstants.COLOR_HEALTH_GOOD)
		_:
			status_badge.add_theme_color_override("font_color", StyleConstants.COLOR_TEXT_SECONDARY)

	details_row.visible = _expanded
	if _expanded:
		var prob := str(_risk_data.get("probability", ""))
		var strat := str(_risk_data.get("response_strategy", ""))
		prob_label.text = "Prob: %s" % (prob.capitalize() if prob != "" else "-")
		strategy_label.text = "Strat: %s" % (strat.capitalize() if strat != "" else "-")
		var budget_cost := int(_risk_data.get("budget_allocated", 0))
		var cap_cost := int(_risk_data.get("capacity_allocated", 0))
		cost_label.text = "$%dK / %dpw" % [budget_cost / 1000, cap_cost] if budget_cost > 0 or cap_cost > 0 else "No cost"
		for detail_label in [prob_label, strategy_label, cost_label]:
			detail_label.add_theme_color_override("font_color", StyleConstants.COLOR_TEXT_SECONDARY)
			detail_label.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_XS)

	for child in actions_row.get_children():
		child.visible = false

	match status:
		"unassessed":
			if actions_row.has_node("AssessButton"):
				actions_row.get_node("AssessButton").visible = true
			if actions_row.has_node("InvestigateButton") and _risk_data.get("investigation", {}).get("available", false):
				actions_row.get_node("InvestigateButton").visible = true
		"analyzed":
			if actions_row.has_node("RespondButton"):
				actions_row.get_node("RespondButton").visible = true
			if actions_row.has_node("InvestigateButton") and _risk_data.get("investigation", {}).get("available", false) and not _risk_data.get("investigated", false):
				actions_row.get_node("InvestigateButton").visible = true
		"response_planned", "active":
			if actions_row.has_node("ReassessButton"):
				actions_row.get_node("ReassessButton").visible = true

	_apply_card_style(status)

func _apply_card_style(status: String) -> void:
	var border_color := StyleConstants.COLOR_ACCENT_SECONDARY
	var border_width := 1
	var alpha := 1.0
	match status:
		"unassessed":
			border_color = StyleConstants.COLOR_HEALTH_WARNING
			border_width = 2
		"triggered":
			border_color = StyleConstants.COLOR_HEALTH_CRITICAL
			border_width = 2
		"resolved":
			border_color = StyleConstants.COLOR_HEALTH_GOOD
			alpha = 0.75
	add_theme_stylebox_override("panel", StyleConstants.create_panel_stylebox(StyleConstants.COLOR_BG_PANEL, border_color, border_width))
	modulate.a = alpha

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_expanded = not _expanded
		_update_display()
