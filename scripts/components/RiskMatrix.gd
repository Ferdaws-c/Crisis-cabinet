extends Control

signal completed(result: Dictionary)
signal closed()

const GAME_THEME := preload("res://themes/game_theme.tres")

@onready var dim_background: ColorRect = $DimBackground
@onready var root_panel: PanelContainer = $CenterContainer/PanelContainer
@onready var title_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TitleLabel
@onready var matrix_grid: GridContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/MatrixGrid
@onready var campfire_quadrant: PanelContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/MatrixGrid/CampfireQuadrant
@onready var wildfire_quadrant: PanelContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/MatrixGrid/WildfireQuadrant
@onready var spark_quadrant: PanelContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/MatrixGrid/SparkQuadrant
@onready var volcano_quadrant: PanelContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/MatrixGrid/VolcanoQuadrant
@onready var risk_cards_sidebar: VBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/RiskCardsSidebar
@onready var correction_message: RichTextLabel = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CorrectionMessage
@onready var strategic_description: RichTextLabel = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/StrategicDescription
@onready var continue_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ContinueButton

var _data: Dictionary = {}
var _mode := "interactive"
var _selected_card_id := ""
var _card_buttons: Dictionary = {}
var _risk_lookup: Dictionary = {}
var _placements: Array = []
var _quadrant_meta: Dictionary = {}
var _active_quadrants: Dictionary = {}
var _is_ready := false
var _has_setup := false
var _pending_resolutions := 0

func _ready() -> void:
	theme = GAME_THEME
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_is_ready = true
	_build_quadrant_meta()
	_apply_styles()
	_connect_quadrants()
	correction_message.visible = false
	strategic_description.visible = false
	continue_button.visible = false
	continue_button.pressed.connect(_on_continue_pressed)

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
	title_label.add_theme_color_override("font_color", StyleConstants.COLOR_ACCENT_PRIMARY)
	title_label.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_LG)
	correction_message.add_theme_color_override("default_color", StyleConstants.COLOR_HEALTH_CRITICAL)
	strategic_description.add_theme_color_override("default_color", StyleConstants.COLOR_TEXT_SECONDARY)
	StyleConstants.style_button(continue_button, true)
	for quadrant_id in _quadrant_meta.keys():
		var label: Label = _quadrant_meta[quadrant_id]["label"]
		label.add_theme_color_override("font_color", StyleConstants.get_fire_color(quadrant_id))
		label.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_SM)
	_reset_all_quadrants()

func _apply_setup() -> void:
	_mode = str(_data.get("mode", "interactive")).to_lower()
	_selected_card_id = ""
	_card_buttons.clear()
	_risk_lookup.clear()
	_placements.clear()
	_active_quadrants.clear()
	_pending_resolutions = 0
	correction_message.visible = false
	strategic_description.visible = false
	continue_button.visible = _mode == "display"

	for child in risk_cards_sidebar.get_children():
		child.queue_free()

	_reset_all_quadrants()
	risk_cards_sidebar.visible = _mode == "interactive"

	if _mode == "display":
		_populate_display_mode()
	else:
		_populate_interactive_mode()

func _build_quadrant_meta() -> void:
	_quadrant_meta = {
		"campfire": {
			"panel": campfire_quadrant,
			"container": campfire_quadrant.get_node("VBoxContainer/DroppedRisksContainer"),
			"label": campfire_quadrant.get_node("VBoxContainer/CategoryLabel"),
			"color": StyleConstants.COLOR_CAMPFIRE,
			"description": "This is a Campfire - always burning, never dangerous on its own. Small delays, minor bugs, routine issues. Manage efficiently without over-investing. But too many unattended Campfires create smoke that obscures real threats."
		},
		"wildfire": {
			"panel": wildfire_quadrant,
			"container": wildfire_quadrant.get_node("VBoxContainer/DroppedRisksContainer"),
			"label": wildfire_quadrant.get_node("VBoxContainer/CategoryLabel"),
			"color": StyleConstants.COLOR_WILDFIRE,
			"description": "This is a Wildfire - it's already spreading and burns everything in its path. Almost certain to happen and will cause serious damage. Deal with these first, aggressively, with real resources. Never ignore a Wildfire."
		},
		"spark": {
			"panel": spark_quadrant,
			"container": spark_quadrant.get_node("VBoxContainer/DroppedRisksContainer"),
			"label": spark_quadrant.get_node("VBoxContainer/CategoryLabel"),
			"color": StyleConstants.COLOR_SPARK,
			"description": "This is a Spark - might ignite, probably won't, and even if it does, it's small. Log it and move on. The biggest risk with Sparks is wasting time on them when Wildfires need your attention."
		},
		"volcano": {
			"panel": volcano_quadrant,
			"container": volcano_quadrant.get_node("VBoxContainer/DroppedRisksContainer"),
			"label": volcano_quadrant.get_node("VBoxContainer/CategoryLabel"),
			"color": StyleConstants.COLOR_VOLCANO,
			"description": "This is a Volcano - quiet right now, maybe for the whole project. But if it erupts, the damage is massive. You can't prevent a Volcano, but you can prepare. Always have a contingency plan."
		}
	}

func _connect_quadrants() -> void:
	for quadrant_id in _quadrant_meta.keys():
		var panel: PanelContainer = _quadrant_meta[quadrant_id]["panel"]
		panel.gui_input.connect(_on_quadrant_gui_input.bind(quadrant_id))

func _populate_interactive_mode() -> void:
	var risks: Array = _data.get("risks_to_place", [])
	for risk in risks:
		var risk_data: Dictionary = risk
		var risk_id := str(risk_data.get("id", ""))
		if risk_id == "":
			continue
		_risk_lookup[risk_id] = risk_data.duplicate(true)
		var button := _create_risk_card_button(risk_data)
		_card_buttons[risk_id] = button
		risk_cards_sidebar.add_child(button)

func _populate_display_mode() -> void:
	var placed_risks: Array = _data.get("placed_risks", [])
	for risk in placed_risks:
		var risk_data: Dictionary = risk
		var quadrant_id := str(risk_data.get("quadrant", "")).to_lower()
		var button := _create_risk_card_button({
			"id": risk_data.get("id", ""),
			"title": risk_data.get("title", "")
		})
		button.disabled = true
		button.focus_mode = Control.FOCUS_NONE
		_place_card_in_container(button, quadrant_id)
		_activate_quadrant(quadrant_id)

	if placed_risks.size() > 0:
		var first_quadrant := str(placed_risks[0].get("quadrant", ""))
		strategic_description.visible = true
		strategic_description.text = _quadrant_meta.get(first_quadrant, {}).get("description", "")

func _create_risk_card_button(risk_data: Dictionary) -> Button:
	var button := Button.new()
	button.text = str(risk_data.get("title", "Unnamed Risk"))
	button.custom_minimum_size = Vector2(220, 54)
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(_on_risk_card_selected.bind(str(risk_data.get("id", ""))))
	_apply_card_selected_style(button, false)
	return button

func _on_risk_card_selected(risk_id: String) -> void:
	if _mode != "interactive":
		return
	if not _card_buttons.has(risk_id):
		return
	_selected_card_id = risk_id
	for id in _card_buttons.keys():
		_apply_card_selected_style(_card_buttons[id], id == risk_id)

func _apply_card_selected_style(button: Button, selected: bool) -> void:
	var style := StyleConstants.create_panel_stylebox(StyleConstants.COLOR_BG_PANEL, StyleConstants.COLOR_ACCENT_PRIMARY if selected else StyleConstants.COLOR_ACCENT_SECONDARY, 2 if selected else 1)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_color_override("font_color", StyleConstants.COLOR_TEXT_PRIMARY)
	button.add_theme_color_override("font_hover_color", StyleConstants.COLOR_TEXT_PRIMARY)
	button.add_theme_color_override("font_pressed_color", StyleConstants.COLOR_TEXT_PRIMARY)
	button.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_SM)

func _on_quadrant_gui_input(event: InputEvent, quadrant_id: String) -> void:
	if _mode != "interactive":
		return
	if _selected_card_id == "":
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_place_selected_card(quadrant_id)

func _place_selected_card(quadrant_id: String) -> void:
	var risk_id := _selected_card_id
	_selected_card_id = ""
	for id in _card_buttons.keys():
		_apply_card_selected_style(_card_buttons[id], false)

	if not _risk_lookup.has(risk_id):
		return

	var risk_data: Dictionary = _risk_lookup[risk_id]
	var button: Button = _card_buttons[risk_id]
	button.disabled = true
	var correct_quadrant := str(risk_data.get("correct_quadrant", "")).to_lower()
	var was_correct := quadrant_id == correct_quadrant

	_placements.append({
		"id": risk_id,
		"placed": quadrant_id,
		"correct": correct_quadrant,
		"was_correct": was_correct
	})

	if was_correct:
		_place_card_in_container(button, quadrant_id)
		_activate_quadrant(quadrant_id)
		_check_completion()
		return

	_pending_resolutions += 1
	_place_card_in_container(button, quadrant_id)
	_show_correction_message(quadrant_id, correct_quadrant)
	_activate_quadrant(correct_quadrant)
	_correct_card_placement(button, correct_quadrant)

func _show_correction_message(placed_quadrant: String, correct_quadrant: String) -> void:
	correction_message.text = "You already assessed this risk as a different combination. That makes it a %s, not a %s." % [
		correct_quadrant.capitalize(),
		placed_quadrant.capitalize()
	]
	correction_message.visible = true
	correction_message.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(correction_message, "modulate:a", 1.0, 0.25)
	tween.tween_interval(1.5)
	tween.tween_property(correction_message, "modulate:a", 0.0, 0.25)
	tween.tween_callback(func() -> void:
		correction_message.visible = false
	)

func _correct_card_placement(button: Button, correct_quadrant: String) -> void:
	var target_container: VBoxContainer = _quadrant_meta[correct_quadrant]["container"]
	var start_position := button.global_position
	var target_position := target_container.global_position + Vector2(8, 8 + target_container.get_child_count() * 46)

	button.reparent(self, true)
	button.z_index = 10
	button.global_position = start_position

	var tween := create_tween()
	tween.tween_interval(2.0)
	tween.tween_property(button, "global_position", target_position, 0.45)
	tween.tween_callback(func() -> void:
		_place_card_in_container(button, correct_quadrant)
		button.z_index = 0
		_pending_resolutions = maxi(_pending_resolutions - 1, 0)
		_check_completion()
	)

func _place_card_in_container(button: Button, quadrant_id: String) -> void:
	var target_container: VBoxContainer = _quadrant_meta[quadrant_id]["container"]
	button.reparent(target_container, false)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func _activate_quadrant(quadrant_id: String) -> void:
	if not _quadrant_meta.has(quadrant_id):
		return

	var meta: Dictionary = _quadrant_meta[quadrant_id]
	var panel: PanelContainer = meta["panel"]
	var label: Label = meta["label"]
	var color: Color = meta["color"]

	var fill_color := Color(color.r, color.g, color.b, 0.4)
	panel.add_theme_stylebox_override("panel", StyleConstants.create_panel_stylebox(fill_color, color, 2))
	label.text = quadrant_id.to_upper()
	label.visible = true
	label.add_theme_color_override("font_color", color)
	strategic_description.text = str(meta["description"])
	strategic_description.visible = true

	if not _active_quadrants.has(quadrant_id):
		_active_quadrants[quadrant_id] = true
		panel.modulate.a = 0.0
		label.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(panel, "modulate:a", 1.0, 0.25)
		tween.parallel().tween_property(label, "modulate:a", 1.0, 0.25)
	else:
		panel.modulate.a = 1.0
		label.modulate.a = 1.0

func _reset_all_quadrants() -> void:
	for quadrant_id in _quadrant_meta.keys():
		var dropped_container: VBoxContainer = _quadrant_meta[quadrant_id]["container"]
		for child in dropped_container.get_children():
			child.queue_free()
		_reset_quadrant_visuals(quadrant_id)

func _reset_quadrant_visuals(quadrant_id: String) -> void:
	var meta: Dictionary = _quadrant_meta[quadrant_id]
	var panel: PanelContainer = meta["panel"]
	var label: Label = meta["label"]
	var fire_color: Color = meta["color"]
	var idle_fill := Color(fire_color.r, fire_color.g, fire_color.b, 0.15)
	panel.add_theme_stylebox_override("panel", StyleConstants.create_panel_stylebox(idle_fill, StyleConstants.COLOR_ACCENT_SECONDARY, 1))
	panel.modulate.a = 1.0
	label.visible = false
	label.modulate.a = 1.0

func _check_completion() -> void:
	if _mode != "interactive":
		return
	if _pending_resolutions > 0:
		return
	if _placements.size() < _risk_lookup.size():
		return
	continue_button.visible = true
	continue_button.grab_focus()

func _on_continue_pressed() -> void:
	if _mode == "display":
		completed.emit({})
	else:
		completed.emit({"placements": _placements})
	closed.emit()
	queue_free()
