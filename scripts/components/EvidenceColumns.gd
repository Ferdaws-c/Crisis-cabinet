extends Control

signal completed(result: Dictionary)
signal closed()

const GAME_THEME := preload("res://themes/game_theme.tres")

@onready var dim_background: ColorRect = $DimBackground
@onready var root_panel: PanelContainer = $CenterContainer/PanelContainer
@onready var increases_header: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HeadersContainer/IncreasesHeader
@onready var decreases_header: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HeadersContainer/DecreasesHeader
@onready var increases_column: VBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ColumnsContainer/IncreasesColumn
@onready var decreases_column: VBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ColumnsContainer/DecreasesColumn
@onready var conclusion_label: RichTextLabel = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ConclusionLabel
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
	conclusion_label.modulate.a = 0.0
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
	increases_header.add_theme_color_override("font_color", StyleConstants.COLOR_HEALTH_WARNING)
	increases_header.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_SM)
	decreases_header.add_theme_color_override("font_color", StyleConstants.COLOR_HEALTH_GOOD)
	decreases_header.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_SM)
	conclusion_label.add_theme_color_override("default_color", StyleConstants.COLOR_ACCENT_PRIMARY)
	StyleConstants.style_button(continue_button, true)

func _apply_data() -> void:
	for child in increases_column.get_children():
		child.queue_free()
	for child in decreases_column.get_children():
		child.queue_free()

	conclusion_label.text = str(_data.get("conclusion", ""))
	conclusion_label.modulate.a = 0.0
	continue_button.visible = false

func _start_animation() -> void:
	await get_tree().process_frame
	var increases: Array = _data.get("increases", [])
	var decreases: Array = _data.get("decreases", [])
	var max_count := maxi(increases.size(), decreases.size())

	for i in range(max_count):
		if i < increases.size():
			var inc_label := _add_item_to_column(
				increases_column,
				str(increases[i]),
				"↑",
				StyleConstants.COLOR_HEALTH_WARNING
			)
			await _fade_in_node(inc_label, 0.3)
			await get_tree().create_timer(0.4).timeout

		if i < decreases.size():
			var dec_label := _add_item_to_column(
				decreases_column,
				str(decreases[i]),
				"↓",
				StyleConstants.COLOR_HEALTH_GOOD
			)
			await _fade_in_node(dec_label, 0.3)
			await get_tree().create_timer(0.4).timeout

	await _fade_in_node(conclusion_label, 0.4)
	continue_button.visible = true
	continue_button.grab_focus()

func _add_item_to_column(column: VBoxContainer, text: String, prefix: String, color: Color) -> Label:
	var label := Label.new()
	label.text = prefix + " " + text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_MD)
	label.modulate.a = 0.0
	column.add_child(label)
	return label

func _fade_in_node(node: CanvasItem, duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(node, "modulate:a", 1.0, duration)
	await tween.finished

func _on_continue_pressed() -> void:
	completed.emit({})
	closed.emit()
	queue_free()
