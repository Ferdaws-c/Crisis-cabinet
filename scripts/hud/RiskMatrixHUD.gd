extends PanelContainer

var _is_open := false

@onready var close_button: Button = $VBoxContainer/HeaderRow/CloseButton
const CORNER_LABEL_PATH := "MarginContainer/VBoxContainer/CornerLabel"
const DOTS_CONTAINER_PATH := "MarginContainer/VBoxContainer/DotsContainer"

func _ready() -> void:
	_apply_styles()
	SignalBus.risk_updated.connect(func(_r: Dictionary) -> void: _update_display())
	SignalBus.risk_added.connect(func(_r: Dictionary) -> void: _update_display())
	SignalBus.matrix_toggle_requested.connect(toggle)
	if close_button:
		close_button.pressed.connect(func() -> void: toggle())
	else:
		push_warning("RiskMatrixHUD: CloseButton node is missing.")
	visible = false

func _apply_styles() -> void:
	add_theme_stylebox_override("panel", StyleConstants.create_panel_stylebox())
	var title_label := get_node_or_null("VBoxContainer/HeaderRow/TitleLabel") as Label
	if title_label:
		title_label.add_theme_color_override("font_color", StyleConstants.COLOR_ACCENT_PRIMARY)
		title_label.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_XS)
	else:
		push_warning("RiskMatrixHUD: TitleLabel node is missing.")
	if close_button:
		StyleConstants.style_button(close_button, false)
	_style_cell("CampfireCell", "campfire", "CF")
	_style_cell("WildfireCell", "wildfire", "WF")
	_style_cell("SparkCell", "spark", "SP")
	_style_cell("VolcanoCell", "volcano", "VO")

func _style_cell(cell_name: String, category: String, label_text: String) -> void:
	var cell := get_node_or_null("VBoxContainer/MatrixGrid/%s" % cell_name) as PanelContainer
	if cell == null:
		push_warning("RiskMatrixHUD: Missing cell '%s'." % cell_name)
		return
	var color := StyleConstants.get_fire_color(category)
	var tint := Color(color.r, color.g, color.b, 0.1)
	cell.add_theme_stylebox_override("panel", StyleConstants.create_panel_stylebox(tint, color, 1))
	var corner_label := cell.get_node_or_null(CORNER_LABEL_PATH) as Label
	if corner_label:
		corner_label.text = label_text
		corner_label.add_theme_color_override("font_color", color)
		corner_label.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_XS)
	else:
		push_warning("RiskMatrixHUD: Missing CornerLabel for '%s'." % cell_name)

func toggle() -> void:
	_is_open = not _is_open
	visible = _is_open
	if _is_open:
		_update_display()

func _update_display() -> void:
	for cell_name in ["CampfireCell", "WildfireCell", "SparkCell", "VolcanoCell"]:
		var dots := _get_dots_container(cell_name)
		if dots == null:
			continue
		for child in dots.get_children():
			child.queue_free()

	for risk in GameManager.risk_register:
		var category := str(risk.get("matrix_category", ""))
		if category == "":
			continue

		var cell_name := ""
		match category:
			"campfire":
				cell_name = "CampfireCell"
			"wildfire":
				cell_name = "WildfireCell"
			"spark":
				cell_name = "SparkCell"
			"volcano":
				cell_name = "VolcanoCell"

		if cell_name != "":
			var dot := ColorRect.new()
			dot.custom_minimum_size = Vector2(6, 6)
			dot.color = StyleConstants.get_fire_color(category)
			if risk.get("status", "") == "triggered":
				dot.color = StyleConstants.COLOR_HEALTH_CRITICAL
			elif risk.get("status", "") == "resolved":
				dot.color = StyleConstants.COLOR_HEALTH_GOOD
				dot.modulate.a = 0.5
			var dots := _get_dots_container(cell_name)
			if dots:
				dots.add_child(dot)

func _get_dots_container(cell_name: String) -> HBoxContainer:
	var cell := get_node_or_null("VBoxContainer/MatrixGrid/%s" % cell_name) as PanelContainer
	if cell == null:
		push_warning("RiskMatrixHUD: Cannot find cell '%s' while updating display." % cell_name)
		return null
	var dots := cell.get_node_or_null(DOTS_CONTAINER_PATH) as HBoxContainer
	if dots == null:
		push_warning("RiskMatrixHUD: Missing DotsContainer for '%s'." % cell_name)
	return dots
