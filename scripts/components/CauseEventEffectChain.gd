extends Control

signal completed(result: Dictionary)
signal closed()

const GAME_THEME := preload("res://themes/game_theme.tres")

@onready var dim_background: ColorRect = $DimBackground
@onready var root_panel: PanelContainer = $CenterContainer/PanelContainer
@onready var cause_panel: PanelContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/CausePanel
@onready var event_panel: PanelContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/EventPanel
@onready var effect_panel: PanelContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/EffectPanel
@onready var arrow1: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/Arrow1
@onready var arrow2: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/Arrow2
@onready var conclusion_label: RichTextLabel = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ConclusionLabel
@onready var continue_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ContinueButton

@onready var cause_header_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/CausePanel/VBoxContainer/HeaderLabel
@onready var event_header_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/EventPanel/VBoxContainer/HeaderLabel
@onready var effect_header_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/EffectPanel/VBoxContainer/HeaderLabel
@onready var cause_content_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/CausePanel/VBoxContainer/ContentLabel
@onready var event_content_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/EventPanel/VBoxContainer/ContentLabel
@onready var effect_content_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/EffectPanel/VBoxContainer/ContentLabel

var _data: Dictionary = {}
var _is_ready := false
var _has_setup := false

func _ready() -> void:
	theme = GAME_THEME
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_is_ready = true
	_apply_styles()

	cause_panel.modulate.a = 0.0
	arrow1.modulate.a = 0.0
	event_panel.modulate.a = 0.0
	arrow2.modulate.a = 0.0
	effect_panel.modulate.a = 0.0
	conclusion_label.modulate.a = 0.0
	continue_button.visible = false
	continue_button.pressed.connect(_on_continue_pressed)

	if _has_setup:
		_apply_data()
		_animate_sequence()

func setup(data: Dictionary) -> void:
	_data = data.duplicate(true)
	_has_setup = true
	if not _is_ready:
		return
	_apply_data()
	_animate_sequence()

func _apply_styles() -> void:
	dim_background.color = StyleConstants.COLOR_BG_DIM
	root_panel.add_theme_stylebox_override("panel", StyleConstants.create_panel_stylebox())
	cause_panel.add_theme_stylebox_override("panel", StyleConstants.create_panel_stylebox())
	event_panel.add_theme_stylebox_override("panel", StyleConstants.create_panel_stylebox())
	_apply_header_style(cause_header_label)
	_apply_header_style(event_header_label)
	_apply_header_style(effect_header_label)

	for label in [cause_content_label, event_content_label, effect_content_label]:
		label.add_theme_color_override("font_color", StyleConstants.COLOR_TEXT_PRIMARY)
		label.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_MD)

	for arrow in [arrow1, arrow2]:
		arrow.add_theme_color_override("font_color", StyleConstants.COLOR_ACCENT_PRIMARY)
		arrow.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_LG)
		arrow.text = "->"

	conclusion_label.add_theme_color_override("default_color", StyleConstants.COLOR_TEXT_SECONDARY)
	continue_button.text = "Continue"
	StyleConstants.style_button(continue_button, true)

func _apply_header_style(label: Label) -> void:
	label.add_theme_color_override("font_color", StyleConstants.COLOR_ACCENT_PRIMARY)
	label.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_SM)

func _apply_data() -> void:
	cause_content_label.text = str(_data.get("cause", ""))
	event_content_label.text = str(_data.get("event", ""))
	effect_content_label.text = str(_data.get("effect", ""))
	conclusion_label.text = str(_data.get("conclusion", ""))
	_apply_severity_color(str(_data.get("severity", "medium")).to_lower())

func _apply_severity_color(severity: String) -> void:
	var accent := StyleConstants.COLOR_HEALTH_WARNING
	match severity:
		"low":
			accent = StyleConstants.COLOR_HEALTH_GOOD
		"high":
			accent = StyleConstants.COLOR_HEALTH_CRITICAL
	var style := StyleConstants.create_panel_stylebox(StyleConstants.COLOR_BG_PANEL, accent, 2)
	effect_panel.add_theme_stylebox_override("panel", style)
	effect_header_label.add_theme_color_override("font_color", accent)

func _animate_sequence() -> void:
	continue_button.visible = false
	var tween := create_tween()
	tween.tween_property(cause_panel, "modulate:a", 1.0, 0.4)
	tween.tween_interval(0.3)
	tween.tween_property(arrow1, "modulate:a", 1.0, 0.2)
	tween.tween_property(event_panel, "modulate:a", 1.0, 0.4)
	tween.tween_interval(0.3)
	tween.tween_property(arrow2, "modulate:a", 1.0, 0.2)
	tween.tween_property(effect_panel, "modulate:a", 1.0, 0.4)
	tween.tween_interval(0.4)
	tween.tween_property(conclusion_label, "modulate:a", 1.0, 0.4)
	tween.tween_callback(func() -> void:
		continue_button.visible = true
		continue_button.grab_focus()
	)

func _on_continue_pressed() -> void:
	completed.emit({})
	closed.emit()
	queue_free()
