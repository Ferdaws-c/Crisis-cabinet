extends Node2D

const STATION_SCENES := {
	1: preload("res://scenes/layer1/Station1_Identification.tscn"),
	2: preload("res://scenes/layer1/Station2_Probability.tscn"),
	3: preload("res://scenes/layer1/Station3_Impact.tscn"),
	4: preload("res://scenes/layer1/Station4_Matrix.tscn"),
	5: preload("res://scenes/layer1/Station5_Strategies.tscn"),
	6: preload("res://scenes/layer1/Station6_FullCycle.tscn")
}

const STATION_POSITIONS := {
	1: Vector2(0, 0),
	2: Vector2(760, 0),
	3: Vector2(1520, 0),
	4: Vector2(2280, 0),
	5: Vector2(3040, 0),
	6: Vector2(3800, 0)
}

const GATE_POSITIONS := {
	1: Vector2(380, 0),
	2: Vector2(1140, 0),
	3: Vector2(1900, 0),
	4: Vector2(2660, 0),
	5: Vector2(3420, 0)
}

const EXIT_POSITION := Vector2(4560, 0)
const CORRIDOR_MIN_X := -620.0
const CORRIDOR_MAX_X := 4860.0
const CORRIDOR_HALF_HEIGHT := 240.0

@onready var geometry_root: Node2D = $Geometry
@onready var stations_root: Node2D = $Stations
@onready var gates_root: Node2D = $Gates
@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Player/Camera2D
@onready var overlay_container: Control = $OverlayLayer/OverlayContainer
@onready var message_label: Label = $OverlayLayer/MessageLabel

var _station_titles: Dictionary = {}
var _station_nodes: Dictionary = {}
var _gate_nodes: Dictionary = {}
var _exit_nodes: Dictionary = {}
var _player_in_zone := -1
var _player_at_gate := -1
var _player_at_exit := false
var _overlay_active := false
var _current_overlay: Control

func _ready() -> void:
	GameManager.current_layer = 1
	GameManager.is_movement_paused = false
	overlay_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	SignalBus.layer_started.emit(1)
	_load_station_titles()
	_build_environment()
	_build_stations()
	_build_gates()
	_build_exit_zone()
	_apply_message_style()
	_update_all_station_visuals()
	SignalBus.station_completed.connect(_on_station_completed)

func _load_station_titles() -> void:
	var layer1_data: Dictionary = DataManager.get_phase_data("stations", 1)
	var stations_data = layer1_data.get("stations", {})
	for station_number in range(1, 7):
		var station_key := "station_%d" % station_number
		var station_data: Dictionary = stations_data.get(station_key, {})
		_station_titles[station_number] = str(station_data.get("title", "Station %d" % station_number))

func _build_environment() -> void:
	var floor := Polygon2D.new()
	floor.polygon = PackedVector2Array([
		Vector2(CORRIDOR_MIN_X, -CORRIDOR_HALF_HEIGHT),
		Vector2(CORRIDOR_MAX_X, -CORRIDOR_HALF_HEIGHT),
		Vector2(CORRIDOR_MAX_X, CORRIDOR_HALF_HEIGHT),
		Vector2(CORRIDOR_MIN_X, CORRIDOR_HALF_HEIGHT)
	])
	floor.color = Color(0.10, 0.12, 0.15, 1.0)
	geometry_root.add_child(floor)

	var stripe := Polygon2D.new()
	stripe.polygon = PackedVector2Array([
		Vector2(CORRIDOR_MIN_X, -26),
		Vector2(CORRIDOR_MAX_X, -26),
		Vector2(CORRIDOR_MAX_X, 26),
		Vector2(CORRIDOR_MIN_X, 26)
	])
	stripe.color = Color(0.14, 0.18, 0.20, 1.0)
	geometry_root.add_child(stripe)

	_create_wall(Vector2((CORRIDOR_MIN_X + CORRIDOR_MAX_X) * 0.5, -CORRIDOR_HALF_HEIGHT - 24), Vector2(CORRIDOR_MAX_X - CORRIDOR_MIN_X, 48))
	_create_wall(Vector2((CORRIDOR_MIN_X + CORRIDOR_MAX_X) * 0.5, CORRIDOR_HALF_HEIGHT + 24), Vector2(CORRIDOR_MAX_X - CORRIDOR_MIN_X, 48))
	_create_wall(Vector2(CORRIDOR_MIN_X - 24, 0), Vector2(48, CORRIDOR_HALF_HEIGHT * 2.0 + 96.0))

func _create_wall(position: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = position

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)

	var visual := Polygon2D.new()
	visual.polygon = PackedVector2Array([
		Vector2(-size.x * 0.5, -size.y * 0.5),
		Vector2(size.x * 0.5, -size.y * 0.5),
		Vector2(size.x * 0.5, size.y * 0.5),
		Vector2(-size.x * 0.5, size.y * 0.5)
	])
	visual.color = Color(0.05, 0.07, 0.09, 1.0)
	body.add_child(visual)
	geometry_root.add_child(body)

func _build_stations() -> void:
	for station_number in range(1, 7):
		var station_node := Node2D.new()
		station_node.name = "StationZone%d" % station_number
		station_node.position = STATION_POSITIONS[station_number]

		var area := Area2D.new()
		area.name = "InteractionArea"
		var collision := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 92.0
		collision.shape = circle
		area.add_child(collision)
		area.body_entered.connect(_on_player_entered_zone.bind(station_number))
		area.body_exited.connect(_on_player_exited_zone.bind(station_number))
		station_node.add_child(area)

		var pad := Polygon2D.new()
		pad.name = "StationPad"
		pad.polygon = PackedVector2Array([
			Vector2(-82, -60),
			Vector2(82, -60),
			Vector2(82, 60),
			Vector2(-82, 60)
		])
		pad.color = StyleConstants.COLOR_BG_PANEL
		station_node.add_child(pad)

		var glow := Polygon2D.new()
		glow.name = "PadGlow"
		glow.polygon = PackedVector2Array([
			Vector2(-96, -72),
			Vector2(96, -72),
			Vector2(96, 72),
			Vector2(-96, 72)
		])
		glow.color = Color(0.0, 0.0, 0.0, 0.0)
		glow.z_index = -1
		station_node.add_child(glow)

		var label := Label.new()
		label.name = "StationLabel"
		label.text = "Station %d: %s" % [station_number, _station_titles.get(station_number, "Station")]
		label.position = Vector2(-140, -120)
		label.size = Vector2(280, 48)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_color_override("font_color", StyleConstants.COLOR_TEXT_PRIMARY)
		label.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_SM)
		station_node.add_child(label)

		var status := Label.new()
		status.name = "StatusIndicator"
		status.position = Vector2(-40, -20)
		status.size = Vector2(80, 40)
		status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		status.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_MD)
		station_node.add_child(status)

		var prompt := Label.new()
		prompt.name = "InteractPrompt"
		prompt.position = Vector2(-120, 90)
		prompt.size = Vector2(240, 32)
		prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		prompt.add_theme_color_override("font_color", StyleConstants.COLOR_ACCENT_PRIMARY)
		prompt.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_SM)
		prompt.visible = false
		station_node.add_child(prompt)

		stations_root.add_child(station_node)
		_station_nodes[station_number] = {
			"node": station_node,
			"area": area,
			"pad": pad,
			"glow": glow,
			"label": label,
			"status": status,
			"prompt": prompt
		}

func _build_gates() -> void:
	for gate_number in range(1, 6):
		var gate := Node2D.new()
		gate.name = "Gate%d" % gate_number
		gate.position = GATE_POSITIONS[gate_number]

		var body := StaticBody2D.new()
		body.name = "GateBody"
		var shape := CollisionShape2D.new()
		shape.name = "CollisionShape2D"
		var rect := RectangleShape2D.new()
		rect.size = Vector2(28, CORRIDOR_HALF_HEIGHT * 2.0 - 40.0)
		shape.shape = rect
		body.add_child(shape)
		gate.add_child(body)

		var visual := Polygon2D.new()
		visual.name = "GateVisual"
		visual.polygon = PackedVector2Array([
			Vector2(-14, -CORRIDOR_HALF_HEIGHT + 20),
			Vector2(14, -CORRIDOR_HALF_HEIGHT + 20),
			Vector2(14, CORRIDOR_HALF_HEIGHT - 20),
			Vector2(-14, CORRIDOR_HALF_HEIGHT - 20)
		])
		visual.color = StyleConstants.COLOR_HEALTH_CRITICAL
		gate.add_child(visual)

		var gate_label := Label.new()
		gate_label.name = "GateLabel"
		gate_label.position = Vector2(-80, -CORRIDOR_HALF_HEIGHT - 10)
		gate_label.size = Vector2(160, 24)
		gate_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		gate_label.add_theme_color_override("font_color", StyleConstants.COLOR_TEXT_SECONDARY)
		gate_label.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_SM)
		gate_label.text = "Gate %d" % gate_number
		gate.add_child(gate_label)

		var prompt_area := Area2D.new()
		prompt_area.name = "PromptArea"
		var prompt_shape := CollisionShape2D.new()
		var prompt_rect := RectangleShape2D.new()
		prompt_rect.size = Vector2(160, 120)
		prompt_shape.shape = prompt_rect
		prompt_area.add_child(prompt_shape)
		prompt_area.body_entered.connect(_on_player_entered_gate.bind(gate_number))
		prompt_area.body_exited.connect(_on_player_exited_gate.bind(gate_number))
		gate.add_child(prompt_area)

		var prompt := Label.new()
		prompt.name = "Prompt"
		prompt.position = Vector2(-150, -42)
		prompt.size = Vector2(300, 24)
		prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		prompt.add_theme_color_override("font_color", StyleConstants.COLOR_TEXT_MUTED)
		prompt.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_SM)
		prompt.visible = false
		gate.add_child(prompt)

		gates_root.add_child(gate)
		_gate_nodes[gate_number] = {
			"node": gate,
			"collision": shape,
			"visual": visual,
			"label": gate_label,
			"prompt": prompt
		}

func _build_exit_zone() -> void:
	var exit_node := Node2D.new()
	exit_node.name = "ExitGate"
	exit_node.position = EXIT_POSITION

	var body := StaticBody2D.new()
	var collision := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(32, CORRIDOR_HALF_HEIGHT * 2.0 - 40.0)
	collision.shape = rect
	body.add_child(collision)
	exit_node.add_child(body)

	var visual := Polygon2D.new()
	visual.polygon = PackedVector2Array([
		Vector2(-16, -CORRIDOR_HALF_HEIGHT + 20),
		Vector2(16, -CORRIDOR_HALF_HEIGHT + 20),
		Vector2(16, CORRIDOR_HALF_HEIGHT - 20),
		Vector2(-16, CORRIDOR_HALF_HEIGHT - 20)
	])
	visual.color = StyleConstants.COLOR_TEXT_MUTED
	exit_node.add_child(visual)

	var label := Label.new()
	label.position = Vector2(-160, -CORRIDOR_HALF_HEIGHT - 18)
	label.size = Vector2(320, 40)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", StyleConstants.COLOR_TEXT_SECONDARY)
	label.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_SM)
	label.text = "Layer 2 Exit"
	exit_node.add_child(label)

	var area := Area2D.new()
	var area_shape := CollisionShape2D.new()
	var area_rect := RectangleShape2D.new()
	area_rect.size = Vector2(180, 120)
	area_shape.shape = area_rect
	area.add_child(area_shape)
	area.body_entered.connect(_on_player_entered_exit)
	area.body_exited.connect(_on_player_exited_exit)
	exit_node.add_child(area)

	var prompt := Label.new()
	prompt.position = Vector2(-150, -42)
	prompt.size = Vector2(300, 24)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_color_override("font_color", StyleConstants.COLOR_TEXT_MUTED)
	prompt.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_SM)
	prompt.visible = false
	exit_node.add_child(prompt)

	gates_root.add_child(exit_node)
	_exit_nodes = {
		"node": exit_node,
		"collision": collision,
		"visual": visual,
		"label": label,
		"prompt": prompt
	}

func _apply_message_style() -> void:
	message_label.add_theme_color_override("font_color", StyleConstants.COLOR_TEXT_PRIMARY)
	message_label.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_MD)
	message_label.visible = false

func _input(event: InputEvent) -> void:
	if _overlay_active:
		return
	if not event.is_action_pressed("interact"):
		return
	if _player_in_zone > 0:
		_try_open_station(_player_in_zone)
		return
	if _player_at_gate > 0:
		_show_message("Complete the previous station first.")
		return
	if _player_at_exit:
		_try_exit_layer()

func _on_player_entered_zone(body: Node2D, station_number: int) -> void:
	if body.name != "Player":
		return
	_player_in_zone = station_number
	_show_interact_prompt(station_number)

func _on_player_exited_zone(body: Node2D, station_number: int) -> void:
	if body.name != "Player":
		return
	if _player_in_zone == station_number:
		_player_in_zone = -1
		_hide_interact_prompt(station_number)

func _on_player_entered_gate(body: Node2D, gate_number: int) -> void:
	if body.name != "Player":
		return
	if _is_gate_locked(gate_number):
		_player_at_gate = gate_number
		var prompt: Label = _gate_nodes[gate_number]["prompt"]
		prompt.text = "Locked: complete Station %d first" % gate_number
		prompt.visible = true

func _on_player_exited_gate(body: Node2D, gate_number: int) -> void:
	if body.name != "Player":
		return
	if _player_at_gate == gate_number:
		_player_at_gate = -1
	var prompt: Label = _gate_nodes[gate_number]["prompt"]
	prompt.visible = false

func _on_player_entered_exit(body: Node2D) -> void:
	if body.name != "Player":
		return
	_player_at_exit = true
	var prompt: Label = _exit_nodes["prompt"]
	prompt.visible = true
	prompt.text = "Press Space to enter Layer 2" if GameManager.layer1_complete else "Finish all stations to unlock Layer 2"

func _on_player_exited_exit(body: Node2D) -> void:
	if body.name != "Player":
		return
	_player_at_exit = false
	var prompt: Label = _exit_nodes["prompt"]
	prompt.visible = false

func _try_open_station(station_number: int) -> void:
	if _is_station_complete(station_number):
		_show_message("Station %d completed." % station_number)
		return
	if not _is_station_available(station_number):
		_show_message("Complete the previous station first.")
		return

	var station_scene: PackedScene = STATION_SCENES.get(station_number)
	if station_scene == null:
		_show_message("Station scene missing.")
		return

	GameManager.is_movement_paused = true
	_overlay_active = true
	var station := station_scene.instantiate()
	_current_overlay = station
	station.closed.connect(_on_station_closed.bind(station_number), CONNECT_ONE_SHOT)
	overlay_container.add_child(station)

func _on_station_closed(_station_number: int) -> void:
	_overlay_active = false
	GameManager.is_movement_paused = false
	_current_overlay = null
	_update_all_station_visuals()

func _on_station_completed(_station_number: int) -> void:
	_update_all_station_visuals()

func _is_station_complete(station_number: int) -> bool:
	match station_number:
		1:
			return GameManager.station_1_complete
		2:
			return GameManager.station_2_complete
		3:
			return GameManager.station_3_complete
		4:
			return GameManager.station_4_complete
		5:
			return GameManager.station_5_complete
		6:
			return GameManager.station_6_complete
		_:
			return false

func _is_station_available(station_number: int) -> bool:
	if station_number == 1:
		return true
	return _is_station_complete(station_number - 1)

func _is_gate_locked(gate_number: int) -> bool:
	return not _is_station_complete(gate_number)

func _update_all_station_visuals() -> void:
	for station_number in range(1, 7):
		var station_info: Dictionary = _station_nodes[station_number]
		var pad: Polygon2D = station_info["pad"]
		var glow: Polygon2D = station_info["glow"]
		var status: Label = station_info["status"]

		if _is_station_complete(station_number):
			pad.color = Color(0.18, 0.38, 0.24, 1.0)
			glow.color = Color(StyleConstants.COLOR_HEALTH_GOOD.r, StyleConstants.COLOR_HEALTH_GOOD.g, StyleConstants.COLOR_HEALTH_GOOD.b, 0.22)
			status.text = "DONE"
			status.add_theme_color_override("font_color", StyleConstants.COLOR_HEALTH_GOOD)
		elif _is_station_available(station_number):
			pad.color = Color(0.14, 0.22, 0.24, 1.0)
			glow.color = Color(StyleConstants.COLOR_ACCENT_PRIMARY.r, StyleConstants.COLOR_ACCENT_PRIMARY.g, StyleConstants.COLOR_ACCENT_PRIMARY.b, 0.18)
			status.text = "GO"
			status.add_theme_color_override("font_color", StyleConstants.COLOR_ACCENT_PRIMARY)
		else:
			pad.color = Color(0.11, 0.11, 0.11, 0.85)
			glow.color = Color(0.0, 0.0, 0.0, 0.0)
			status.text = "LOCK"
			status.add_theme_color_override("font_color", StyleConstants.COLOR_TEXT_MUTED)

	_update_gate_visuals()
	_update_exit_visual()
	if _player_in_zone > 0:
		_show_interact_prompt(_player_in_zone)

func _update_gate_visuals() -> void:
	for gate_number in range(1, 6):
		var gate_info: Dictionary = _gate_nodes[gate_number]
		var collision: CollisionShape2D = gate_info["collision"]
		var visual: Polygon2D = gate_info["visual"]
		var label: Label = gate_info["label"]
		var prompt: Label = gate_info["prompt"]
		var locked := _is_gate_locked(gate_number)
		collision.disabled = not locked
		if locked:
			visual.color = StyleConstants.COLOR_HEALTH_CRITICAL
			label.text = "Station %d Gate Locked" % (gate_number + 1)
			label.add_theme_color_override("font_color", StyleConstants.COLOR_HEALTH_CRITICAL)
			if _player_at_gate == gate_number:
				prompt.text = "Locked: complete Station %d first" % gate_number
				prompt.visible = true
		else:
			visual.color = Color(StyleConstants.COLOR_HEALTH_GOOD.r, StyleConstants.COLOR_HEALTH_GOOD.g, StyleConstants.COLOR_HEALTH_GOOD.b, 0.4)
			label.text = "Station %d Unlocked" % (gate_number + 1)
			label.add_theme_color_override("font_color", StyleConstants.COLOR_HEALTH_GOOD)
			if _player_at_gate == gate_number:
				prompt.text = "Path open"
				prompt.visible = true

func _update_exit_visual() -> void:
	var collision: CollisionShape2D = _exit_nodes["collision"]
	var visual: Polygon2D = _exit_nodes["visual"]
	var label: Label = _exit_nodes["label"]
	var prompt: Label = _exit_nodes["prompt"]
	var unlocked := GameManager.layer1_complete
	collision.disabled = unlocked
	if unlocked:
		visual.color = Color(StyleConstants.COLOR_ACCENT_PRIMARY.r, StyleConstants.COLOR_ACCENT_PRIMARY.g, StyleConstants.COLOR_ACCENT_PRIMARY.b, 0.6)
		label.text = "Layer 2 Exit Open"
		label.add_theme_color_override("font_color", StyleConstants.COLOR_ACCENT_PRIMARY)
		if _player_at_exit:
			prompt.text = "Press Space to enter Layer 2"
	else:
		visual.color = StyleConstants.COLOR_TEXT_MUTED
		label.text = "Complete all six stations"
		label.add_theme_color_override("font_color", StyleConstants.COLOR_TEXT_MUTED)
		if _player_at_exit:
			prompt.text = "Finish all stations to unlock Layer 2"

func _show_interact_prompt(station_number: int) -> void:
	var prompt: Label = _station_nodes[station_number]["prompt"]
	prompt.visible = true
	if _is_station_complete(station_number):
		prompt.text = "Station complete"
	elif _is_station_available(station_number):
		prompt.text = "Press Space to interact"
	else:
		prompt.text = "Locked"

func _hide_interact_prompt(station_number: int) -> void:
	var prompt: Label = _station_nodes[station_number]["prompt"]
	prompt.visible = false

func _show_message(text: String) -> void:
	message_label.text = text
	message_label.visible = true
	message_label.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(1.4)
	tween.tween_property(message_label, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func() -> void:
		message_label.visible = false
	)

func _try_exit_layer() -> void:
	if not GameManager.layer1_complete:
		_show_message("Finish all six stations to unlock Layer 2.")
		return
	GameManager.is_movement_paused = true
	_show_message("Layer 1 complete. Entering the main facility...")
	await get_tree().create_timer(0.8).timeout
	get_tree().change_scene_to_file("res://scenes/levels/MainFacility.tscn")
