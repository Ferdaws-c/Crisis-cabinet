extends CanvasLayer

@onready var top_bar: PanelContainer = $TopBar
@onready var phase_label: Label = $TopBar/HBoxContainer/PhaseLabel
@onready var health_dashboard: HBoxContainer = $TopBar/HBoxContainer/HealthDashboard
@onready var resource_bar: HBoxContainer = $TopBar/HBoxContainer/ResourceBar
@onready var toggle_buttons: VBoxContainer = $ToggleButtonsContainer
@onready var register_toggle_button: Button = $ToggleButtonsContainer/RegisterToggleButton
@onready var matrix_toggle_button: Button = $ToggleButtonsContainer/MatrixToggleButton
@onready var register_panel: PanelContainer = $RiskRegisterPanel
@onready var matrix_hud: PanelContainer = $RiskMatrixHUD
@onready var overlay_container: Control = $OverlayContainer

func _ready() -> void:
	overlay_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_apply_styles()
	register_toggle_button.pressed.connect(func() -> void: SignalBus.register_toggle_requested.emit())
	matrix_toggle_button.pressed.connect(func() -> void: SignalBus.matrix_toggle_requested.emit())
	SignalBus.phase_started.connect(_on_phase_started)
	SignalBus.layer_started.connect(_on_layer_started)
	SignalBus.station_completed.connect(_on_station_completed)
	SignalBus.overlay_requested.connect(_on_overlay_requested)
	SignalBus.overlay_closed.connect(_on_overlay_closed)
	SignalBus.risk_added.connect(_on_risk_added)
	_configure_for_layer(GameManager.current_layer)

func _apply_styles() -> void:
	var style := StyleConstants.create_panel_stylebox()
	style.border_width_left = 0
	style.border_width_top = 0
	style.border_width_right = 0
	style.border_width_bottom = 1
	top_bar.add_theme_stylebox_override("panel", style)
	phase_label.add_theme_color_override("font_color", StyleConstants.COLOR_ACCENT_PRIMARY)
	phase_label.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_SM)
	StyleConstants.style_button(register_toggle_button, false)
	StyleConstants.style_button(matrix_toggle_button, false)

func _configure_for_layer(layer: int) -> void:
	match layer:
		1:
			health_dashboard.visible = false
			resource_bar.visible = false
			toggle_buttons.visible = false
			register_panel.visible = false
			matrix_hud.visible = false
			phase_label.text = "Training Wing - Station %d/6" % _get_completed_station_count()
		2, 3:
			health_dashboard.visible = true
			resource_bar.visible = true
			toggle_buttons.visible = true
			register_panel.visible = false
			matrix_hud.visible = false
			phase_label.text = "%s Phase" % str(GameManager.current_phase).capitalize()

func _on_layer_started(layer: int) -> void:
	_configure_for_layer(layer)

func _on_phase_started(phase_name: String, layer: int) -> void:
	if layer == 1:
		phase_label.text = "Training Wing - Station %d/6" % _get_completed_station_count()
	else:
		phase_label.text = "%s Phase" % phase_name.capitalize()

func _on_station_completed(station_number: int) -> void:
	phase_label.text = "Training Wing - Station %d/6" % _get_completed_station_count()

func _on_risk_added(_risk_data: Dictionary) -> void:
	var original_modulate := register_toggle_button.modulate
	var tween := create_tween()
	tween.tween_property(register_toggle_button, "modulate", Color(1.2, 1.2, 0.5, 1.0), 0.2)
	tween.tween_property(register_toggle_button, "modulate", original_modulate, 0.3)

func _on_overlay_requested(scene_path: String, data: Dictionary) -> void:
	var scene = load(scene_path)
	if scene:
		var instance = scene.instantiate()
		if instance.has_method("setup"):
			instance.setup(data)
		if instance.has_signal("closed"):
			instance.closed.connect(func() -> void:
				_on_overlay_closed()
			)
		overlay_container.add_child(instance)

func _on_overlay_closed() -> void:
	for child in overlay_container.get_children():
		if not is_instance_valid(child):
			overlay_container.remove_child(child)

func _get_completed_station_count() -> int:
	var count := 0
	if GameManager.station_1_complete:
		count += 1
	if GameManager.station_2_complete:
		count += 1
	if GameManager.station_3_complete:
		count += 1
	if GameManager.station_4_complete:
		count += 1
	if GameManager.station_5_complete:
		count += 1
	if GameManager.station_6_complete:
		count += 1
	return count
