extends HBoxContainer

@onready var budget_value: Label = $BudgetDisplay/BudgetValue
@onready var capacity_value: Label = $CapacityDisplay/CapacityValue

func _ready() -> void:
	_apply_styles()
	SignalBus.resources_changed.connect(_on_resources_changed)
	_update_display()

func _on_resources_changed() -> void:
	_update_display()

func _apply_styles() -> void:
	for display in [$BudgetDisplay, $CapacityDisplay]:
		var icon_label: Label = display.get_child(0)
		var value_label: Label = display.get_child(1)
		icon_label.add_theme_color_override("font_color", StyleConstants.COLOR_TEXT_SECONDARY)
		icon_label.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_SM)
		value_label.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_SM)

func _update_display() -> void:
	budget_value.text = "$%s" % _format_number(GameManager.contingency_budget)
	capacity_value.text = "%d pw" % GameManager.phase_capacity

	if GameManager.contingency_budget < 10000:
		budget_value.add_theme_color_override("font_color", StyleConstants.COLOR_HEALTH_CRITICAL)
	elif GameManager.contingency_budget < 25000:
		budget_value.add_theme_color_override("font_color", StyleConstants.COLOR_HEALTH_WARNING)
	else:
		budget_value.add_theme_color_override("font_color", StyleConstants.COLOR_TEXT_PRIMARY)

	if GameManager.phase_capacity <= 2:
		capacity_value.add_theme_color_override("font_color", StyleConstants.COLOR_HEALTH_CRITICAL)
	elif GameManager.phase_capacity <= 5:
		capacity_value.add_theme_color_override("font_color", StyleConstants.COLOR_HEALTH_WARNING)
	else:
		capacity_value.add_theme_color_override("font_color", StyleConstants.COLOR_TEXT_PRIMARY)

func _format_number(n: int) -> String:
	var s := str(abs(n))
	var result := ""
	for i in range(s.length()):
		if i > 0 and (s.length() - i) % 3 == 0:
			result += ","
		result += s[i]
	return result
