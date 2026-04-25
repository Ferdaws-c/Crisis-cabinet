extends Control

signal completed(result: Dictionary)
signal closed()

const GAME_THEME := preload("res://themes/game_theme.tres")

@onready var dim_background: ColorRect = $DimBackground
@onready var root_panel: PanelContainer = $CenterContainer/PanelContainer
@onready var risk_title_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/RiskTitleLabel
@onready var resources_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ResourcesLabel
@onready var strategies_container: GridContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/StrategiesContainer
@onready var confirmation_container: VBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ConfirmationContainer
@onready var confirm_text: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ConfirmationContainer/ConfirmText
@onready var confirm_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ConfirmationContainer/HBoxContainer/ConfirmButton
@onready var cancel_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ConfirmationContainer/HBoxContainer/CancelButton
@onready var continue_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ContinueButton

var _data: Dictionary = {}
var _selected_strategy := ""
var _strategy_panels: Dictionary = {}
var _is_ready := false
var _has_setup := false

func _ready() -> void:
	theme = GAME_THEME
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_is_ready = true
	_apply_styles()
	confirmation_container.visible = false
	continue_button.visible = false
	confirm_button.pressed.connect(_on_confirm_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)

	if _has_setup:
		_apply_setup()

func setup(data: Dictionary) -> void:
	_data = data.duplicate(true)
	_has_setup = true
	if not _is_ready:
		return
	_apply_setup()

func _apply_styles() -> void:
	dim_background.color = StyleConstants.COLOR_BG_DIM
	root_panel.add_theme_stylebox_override("panel", StyleConstants.create_panel_stylebox())
	risk_title_label.add_theme_color_override("font_color", StyleConstants.COLOR_ACCENT_PRIMARY)
	risk_title_label.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_LG)
	resources_label.add_theme_color_override("font_color", StyleConstants.COLOR_TEXT_PRIMARY)
	resources_label.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_SM)
	confirm_text.add_theme_color_override("font_color", StyleConstants.COLOR_TEXT_PRIMARY)
	confirm_text.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_MD)
	StyleConstants.style_button(confirm_button, true)
	StyleConstants.style_button(cancel_button, false)
	StyleConstants.style_button(continue_button, true)

func _apply_setup() -> void:
	_selected_strategy = ""
	_strategy_panels.clear()
	confirmation_container.visible = false
	confirmation_container.modulate.a = 0.0
	continue_button.visible = false

	for child in strategies_container.get_children():
		child.queue_free()

	risk_title_label.text = str(_data.get("risk_title", "Unnamed Risk"))
	resources_label.text = "Budget: $%s remaining | Capacity: %s person-weeks remaining" % [
		_format_int(int(_data.get("available_budget", 0))),
		str(int(_data.get("available_capacity", 0)))
	]

	var ordered_strategies := ["avoid", "mitigate", "transfer", "accept"]
	var options: Dictionary = _data.get("response_options", {})
	for strategy_name in ordered_strategies:
		var option: Dictionary = options.get(strategy_name, {})
		var panel := _create_strategy_panel(strategy_name, option)
		strategies_container.add_child(panel)
		_strategy_panels[strategy_name] = panel

func _create_strategy_panel(strategy_name: String, option: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(240, 200)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)

	var title := Label.new()
	title.text = strategy_name.to_upper()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", StyleConstants.COLOR_ACCENT_PRIMARY)
	title.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_SM)
	vbox.add_child(title)

	var description := Label.new()
	description.text = str(option.get("description", "No description provided."))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_color_override("font_color", StyleConstants.COLOR_TEXT_PRIMARY)
	description.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_MD)
	description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(description)

	var budget_cost := int(option.get("cost_budget", 0))
	var capacity_cost := int(option.get("cost_capacity", 0))
	var affordable := _is_affordable(budget_cost, capacity_cost)

	var cost_label := Label.new()
	var cost_text := "Cost: $%s + %s person-weeks" % [_format_int(budget_cost), str(capacity_cost)]
	if not affordable:
		cost_text += " (Insufficient resources)"
	cost_label.text = cost_text
	cost_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cost_label.add_theme_color_override("font_color", StyleConstants.COLOR_HEALTH_CRITICAL if not affordable else StyleConstants.COLOR_TEXT_SECONDARY)
	cost_label.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_SM)
	vbox.add_child(cost_label)

	var tradeoff_label := Label.new()
	tradeoff_label.text = str(option.get("tradeoff_note", ""))
	tradeoff_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tradeoff_label.add_theme_color_override("font_color", StyleConstants.COLOR_TEXT_MUTED)
	tradeoff_label.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_SM)
	vbox.add_child(tradeoff_label)

	panel.add_child(vbox)
	_apply_panel_style(panel, affordable, false)
	if not affordable:
		panel.modulate.a = 0.35
	else:
		panel.gui_input.connect(_on_strategy_panel_input.bind(strategy_name))

	return panel

func _on_strategy_panel_input(event: InputEvent, strategy_name: String) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse_event: InputEventMouseButton = event
	if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
		return
	_select_strategy(strategy_name)

func _select_strategy(strategy_name: String) -> void:
	_selected_strategy = strategy_name
	for key in _strategy_panels.keys():
		var option: Dictionary = _data.get("response_options", {}).get(key, {})
		var affordable := _is_affordable(int(option.get("cost_budget", 0)), int(option.get("cost_capacity", 0)))
		_apply_panel_style(_strategy_panels[key], affordable, key == strategy_name)

	var selected_option: Dictionary = _data.get("response_options", {}).get(strategy_name, {})
	confirm_text.text = "Commit to %s? This will spend $%s and %s person-weeks." % [
		strategy_name.to_upper(),
		_format_int(int(selected_option.get("cost_budget", 0))),
		str(int(selected_option.get("cost_capacity", 0)))
	]
	confirmation_container.visible = true
	confirmation_container.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(confirmation_container, "modulate:a", 1.0, 0.2)
	confirm_button.grab_focus()

func _on_confirm_pressed() -> void:
	if _selected_strategy == "":
		return
	var selected_option: Dictionary = _data.get("response_options", {}).get(_selected_strategy, {})
	completed.emit({
		"strategy": _selected_strategy,
		"budget_spent": int(selected_option.get("cost_budget", 0)),
		"capacity_spent": int(selected_option.get("cost_capacity", 0))
	})
	closed.emit()
	queue_free()

func _on_cancel_pressed() -> void:
	_selected_strategy = ""
	for key in _strategy_panels.keys():
		var option: Dictionary = _data.get("response_options", {}).get(key, {})
		var affordable := _is_affordable(int(option.get("cost_budget", 0)), int(option.get("cost_capacity", 0)))
		_apply_panel_style(_strategy_panels[key], affordable, false)
	if confirmation_container.visible:
		var tween := create_tween()
		tween.tween_property(confirmation_container, "modulate:a", 0.0, 0.15)
		tween.tween_callback(func() -> void:
			confirmation_container.visible = false
		)

func _is_affordable(cost_budget: int, cost_capacity: int) -> bool:
	return cost_budget <= int(_data.get("available_budget", 0)) and cost_capacity <= int(_data.get("available_capacity", 0))

func _apply_panel_style(panel: PanelContainer, affordable: bool, selected: bool) -> void:
	var bg_color := StyleConstants.COLOR_BG_PANEL
	var border := StyleConstants.COLOR_ACCENT_SECONDARY
	var border_width := 1
	if not affordable:
		border = StyleConstants.COLOR_HEALTH_CRITICAL
	elif selected:
		bg_color = Color(StyleConstants.COLOR_BG_PANEL.r, StyleConstants.COLOR_BG_PANEL.g, StyleConstants.COLOR_BG_PANEL.b + 0.06, StyleConstants.COLOR_BG_PANEL.a)
		border = StyleConstants.COLOR_ACCENT_PRIMARY
		border_width = 2
	panel.add_theme_stylebox_override("panel", StyleConstants.create_panel_stylebox(bg_color, border, border_width))

func _format_int(value: int) -> String:
	var s := str(value)
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3, 3) + out
		s = s.substr(0, s.length() - 3)
	return s + out
