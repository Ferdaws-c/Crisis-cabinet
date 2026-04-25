extends HBoxContainer

var _pulse_tweens: Dictionary = {}

@onready var budget_state_label: Label = $BudgetIndicator/StateLabel
@onready var schedule_state_label: Label = $ScheduleIndicator/StateLabel
@onready var quality_state_label: Label = $QualityIndicator/StateLabel
@onready var trust_state_label: Label = $TrustIndicator/StateLabel

func _ready() -> void:
	_apply_styles()
	SignalBus.health_changed.connect(_on_health_changed)
	_update_display()

func _on_health_changed() -> void:
	_update_display()

func _apply_styles() -> void:
	for indicator in [$BudgetIndicator, $ScheduleIndicator, $QualityIndicator, $TrustIndicator]:
		var icon_label: Label = indicator.get_node("IconLabel")
		var state_label: Label = indicator.get_node("StateLabel")
		icon_label.add_theme_color_override("font_color", StyleConstants.COLOR_TEXT_SECONDARY)
		icon_label.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_XS)
		state_label.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_SM)

func _update_display() -> void:
	_update_indicator("budget", budget_state_label)
	_update_indicator("schedule", schedule_state_label)
	_update_indicator("quality", quality_state_label)
	_update_indicator("stakeholder_trust", trust_state_label)

func _update_indicator(dimension: String, label: Label) -> void:
	var state := GameManager.get_health_label(dimension)
	label.text = state
	label.add_theme_color_override("font_color", StyleConstants.get_health_color(state))

	if state in ["Critical", "Lost Confidence", "Depleted", "Deficient"]:
		if not _pulse_tweens.has(dimension):
			_pulse_tweens[dimension] = StyleConstants.start_critical_pulse(label)
	else:
		if _pulse_tweens.has(dimension):
			var tween: Tween = _pulse_tweens[dimension]
			if is_instance_valid(tween):
				tween.kill()
			_pulse_tweens.erase(dimension)
			label.modulate.a = 1.0
