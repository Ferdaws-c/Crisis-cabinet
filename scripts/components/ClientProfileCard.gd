extends Control

signal completed(result: Dictionary)
signal closed()

const GAME_THEME := preload("res://themes/game_theme.tres")

@onready var dim_background: ColorRect = $DimBackground
@onready var root_panel: PanelContainer = $CenterContainer/PanelContainer
@onready var avatar_container: CenterContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/AvatarContainer
@onready var avatar_texture: TextureRect = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/AvatarContainer/AvatarTexture
@onready var name_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/NameLabel
@onready var company_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CompanyLabel
@onready var correction_label: RichTextLabel = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CorrectionLabel
@onready var submit_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/SubmitButton
@onready var continue_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ContinueButton

@onready var budget_row: HBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/StatsContainer/BudgetRow
@onready var schedule_row: HBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/StatsContainer/ScheduleRow
@onready var quality_row: HBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/StatsContainer/QualityRow
@onready var scope_row: HBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/StatsContainer/ScopeRow

var _data: Dictionary = {}
var _mode := "display"
var _is_ready := false
var _has_setup := false
var _player_stats: Dictionary = {}
var _row_map: Dictionary = {}
var _placeholder_nodes: Array[Node] = []
var _avatar_frame: PanelContainer

func _ready() -> void:
	theme = GAME_THEME
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_is_ready = true
	_build_row_map()
	_ensure_avatar_frame()
	_apply_styles()
	submit_button.pressed.connect(_on_submit_pressed)
	continue_button.pressed.connect(_on_continue_pressed)

	if _has_setup:
		_apply_setup()

func setup(data: Dictionary) -> void:
	_data = data.duplicate(true)
	_has_setup = true
	if not _is_ready:
		return
	_apply_setup()

func _build_row_map() -> void:
	_row_map = {
		"budget_tolerance": {
			"row": budget_row,
			"selector": budget_row.get_node("SelectorContainer"),
			"bar": budget_row.get_node("StatBar"),
			"label": budget_row.get_node("LevelLabel")
		},
		"schedule_flexibility": {
			"row": schedule_row,
			"selector": schedule_row.get_node("SelectorContainer"),
			"bar": schedule_row.get_node("StatBar"),
			"label": schedule_row.get_node("LevelLabel")
		},
		"quality_standards": {
			"row": quality_row,
			"selector": quality_row.get_node("SelectorContainer"),
			"bar": quality_row.get_node("StatBar"),
			"label": quality_row.get_node("LevelLabel")
		},
		"scope_flexibility": {
			"row": scope_row,
			"selector": scope_row.get_node("SelectorContainer"),
			"bar": scope_row.get_node("StatBar"),
			"label": scope_row.get_node("LevelLabel")
		}
	}

func _ensure_avatar_frame() -> void:
	if is_instance_valid(_avatar_frame):
		return
	_avatar_frame = PanelContainer.new()
	_avatar_frame.custom_minimum_size = Vector2(
		StyleConstants.AVATAR_SIZE.x + 4,
		StyleConstants.AVATAR_SIZE.y + 4
	)
	_avatar_frame.add_theme_stylebox_override("panel", StyleConstants.create_avatar_frame_stylebox())
	avatar_container.add_child(_avatar_frame)
	avatar_texture.reparent(_avatar_frame, false)
	StyleConstants.style_avatar_texture(avatar_texture)

func _apply_styles() -> void:
	dim_background.color = StyleConstants.COLOR_BG_DIM
	root_panel.add_theme_stylebox_override("panel", StyleConstants.create_panel_stylebox(StyleConstants.COLOR_BG_CARD, StyleConstants.COLOR_ACCENT_SECONDARY, 1))
	name_label.add_theme_color_override("font_color", StyleConstants.COLOR_ACCENT_PRIMARY)
	name_label.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_LG)
	company_label.add_theme_color_override("font_color", StyleConstants.COLOR_TEXT_SECONDARY)
	company_label.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_SM)
	correction_label.add_theme_color_override("default_color", StyleConstants.COLOR_HEALTH_WARNING)
	StyleConstants.style_button(submit_button, true)
	StyleConstants.style_button(continue_button, true)

	for stat_key in _row_map.keys():
		var row: HBoxContainer = _row_map[stat_key]["row"]
		var stat_label: Label = row.get_child(0)
		var value_label: Label = _row_map[stat_key]["label"]
		stat_label.add_theme_color_override("font_color", StyleConstants.COLOR_TEXT_PRIMARY)
		stat_label.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_SM)
		value_label.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_XS)
		value_label.add_theme_color_override("font_color", StyleConstants.COLOR_TEXT_SECONDARY)
		_style_stat_bar(_row_map[stat_key]["bar"], StyleConstants.COLOR_TEXT_MUTED)

func _apply_setup() -> void:
	_mode = str(_data.get("mode", "display")).to_lower()
	_player_stats.clear()
	name_label.text = str(_data.get("character_name", "Unknown"))
	company_label.text = str(_data.get("company", ""))
	correction_label.visible = false
	continue_button.visible = _mode == "display"
	submit_button.visible = _mode == "build"
	submit_button.disabled = _mode == "build"
	StyleConstants.style_button(submit_button, true, submit_button.disabled)
	_set_avatar(str(_data.get("avatar", "")), name_label.text)
	_reset_rows()

	if _mode == "display":
		_apply_display_stats(_data.get("stats", {}))
	else:
		_prepare_build_mode()

func _reset_rows() -> void:
	for stat_key in _row_map.keys():
		var meta: Dictionary = _row_map[stat_key]
		var selector: HBoxContainer = meta["selector"]
		var bar: ProgressBar = meta["bar"]
		var label: Label = meta["label"]
		var row: HBoxContainer = meta["row"]
		row.modulate = Color.WHITE
		label.text = "-"
		label.add_theme_color_override("font_color", StyleConstants.COLOR_TEXT_SECONDARY)
		bar.value = 0.0
		_style_stat_bar(bar, StyleConstants.COLOR_TEXT_MUTED)
		for child in selector.get_children():
			child.queue_free()

func _apply_display_stats(stats: Dictionary) -> void:
	for stat_key in _row_map.keys():
		var level := str(stats.get(stat_key, "low")).to_lower()
		_update_row_visual(stat_key, level)
		var selector: HBoxContainer = _row_map[stat_key]["selector"]
		selector.visible = false

func _prepare_build_mode() -> void:
	for stat_key in _row_map.keys():
		var selector: HBoxContainer = _row_map[stat_key]["selector"]
		selector.visible = true
		for level in ["low", "medium", "high"]:
			var button := Button.new()
			button.text = level.capitalize()
			button.custom_minimum_size = Vector2(66, 32)
			StyleConstants.style_button(button, false)
			button.pressed.connect(_on_stat_level_selected.bind(stat_key, level))
			selector.add_child(button)

func _on_stat_level_selected(stat_key: String, level: String) -> void:
	_player_stats[stat_key] = level
	_update_row_visual(stat_key, level)
	_row_map[stat_key]["row"].modulate = Color.WHITE
	_update_selector_buttons(stat_key, level)
	_update_submit_state()

func _update_selector_buttons(stat_key: String, selected_level: String) -> void:
	var selector: HBoxContainer = _row_map[stat_key]["selector"]
	for child in selector.get_children():
		if child is Button:
			var button: Button = child
			StyleConstants.style_button(button, button.text.to_lower() == selected_level)

func _update_row_visual(stat_key: String, level: String) -> void:
	var meta: Dictionary = _row_map[stat_key]
	var bar: ProgressBar = meta["bar"]
	var label: Label = meta["label"]
	bar.value = _level_to_progress(level)
	label.text = _format_level(level)
	var color := _level_to_color(level)
	label.add_theme_color_override("font_color", color)
	_style_stat_bar(bar, color)

func _update_submit_state() -> void:
	submit_button.disabled = _player_stats.size() < 4
	StyleConstants.style_button(submit_button, true, submit_button.disabled)

func _on_submit_pressed() -> void:
	var correct_stats: Dictionary = _data.get("correct_stats", {})
	var correction_hints: Dictionary = _data.get("correction_hints", {})
	var first_incorrect := ""

	for stat_key in _row_map.keys():
		var expected := str(correct_stats.get(stat_key, "")).to_lower()
		var actual := str(_player_stats.get(stat_key, "")).to_lower()
		if actual != expected:
			_row_map[stat_key]["row"].modulate = Color(1.0, 0.72, 0.72)
			if first_incorrect == "":
				first_incorrect = stat_key
		else:
			_row_map[stat_key]["row"].modulate = Color.WHITE

	if first_incorrect != "":
		correction_label.visible = true
		correction_label.text = str(correction_hints.get(first_incorrect, "Check the conversation clues again."))
		return

	correction_label.visible = true
	correction_label.text = "Profile confirmed. You matched the stakeholder priorities correctly."
	submit_button.visible = false
	continue_button.visible = true
	continue_button.grab_focus()

func _on_continue_pressed() -> void:
	if _mode == "display":
		completed.emit({})
	else:
		completed.emit({
			"player_stats": _player_stats.duplicate(true),
			"all_correct": true
		})
	closed.emit()
	queue_free()

func _set_avatar(path: String, fallback_name: String) -> void:
	for node in _placeholder_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_placeholder_nodes.clear()

	avatar_texture.visible = false
	avatar_texture.texture = null
	if path != "" and ResourceLoader.exists(path):
		avatar_texture.texture = load(path)
		avatar_texture.visible = true
		return

	var placeholder := StyleConstants.create_avatar_placeholder(fallback_name.left(1).to_upper())
	_avatar_frame.add_child(placeholder)
	_placeholder_nodes.append(placeholder)

func _style_stat_bar(bar: ProgressBar, fill_color: Color) -> void:
	var background := StyleConstants.create_panel_stylebox(Color(0.09, 0.11, 0.14, 0.95), StyleConstants.COLOR_ACCENT_SECONDARY, 1)
	background.content_margin_left = 0
	background.content_margin_right = 0
	background.content_margin_top = 0
	background.content_margin_bottom = 0
	var fill := StyleConstants.create_panel_stylebox(fill_color, fill_color, 0)
	fill.content_margin_left = 0
	fill.content_margin_right = 0
	fill.content_margin_top = 0
	fill.content_margin_bottom = 0
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)

func _level_to_progress(level: String) -> float:
	match level:
		"low":
			return 33.0
		"medium":
			return 66.0
		"high", "very_high":
			return 100.0
		_:
			return 0.0

func _level_to_color(level: String) -> Color:
	match level:
		"low":
			return StyleConstants.COLOR_HEALTH_CRITICAL
		"medium":
			return StyleConstants.COLOR_HEALTH_WARNING
		"high", "very_high":
			return StyleConstants.COLOR_HEALTH_GOOD
		_:
			return StyleConstants.COLOR_TEXT_MUTED

func _format_level(level: String) -> String:
	return level.replace("_", " ").capitalize()
