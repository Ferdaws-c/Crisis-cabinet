## MG03_DecisionDash.gd
## PMBOK: Decision Trees & EMV
## Mechanic: Steer a ship between two lanes to pick the higher-EMV fork option.

extends Node

# ── Interface state ──────────────────────────────────────────────────────────
var _done: bool = false
var _score: int = 0
var _budget_delta: int = 0
var _days_delta: int = 0
var _dashes: Array = []

# ── Game references ───────────────────────────────────────────────────────────
var _game_area: Control
var _overlay: Node

# ── Player ────────────────────────────────────────────────────────────────────
var _player: ColorRect
var _lane: int = 0          # 0 = left, 1 = right
var _player_y: float = 0.0
var _left_x: float = 0.0
var _right_x: float = 0.0

# ── Forks ─────────────────────────────────────────────────────────────────────
# Each fork dict: {node: Control, left_val: int, right_val: int, is_gamble: bool, y: float, resolved: bool}
var _forks: Array = []
var _spawn_timer: float = 0.0
var _spawn_interval: float = 3.0

# ── UI ────────────────────────────────────────────────────────────────────────
var _lane_label: Label
var _score_label: Label
var _budget_label: Label

# ── Fork scroll speed ─────────────────────────────────────────────────────────
const FORK_SPEED_BASE: float = 320.0

const SCENARIOS: Array = [
	{ "name_a": "Build In-House", "prob_a": 0.8, "val_a": 10000, "name_b": "Buy COTS", "prob_b": 1.0, "val_b": 7000 },
	{ "name_a": "Hire Expert", "prob_a": 0.9, "val_a": 5000, "name_b": "Train Team", "prob_b": 0.5, "val_b": 8000 },
	{ "name_a": "Aggressive Launch", "prob_a": 0.4, "val_a": 20000, "name_b": "Safe Launch", "prob_b": 0.9, "val_b": 8000 },
	{ "name_a": "Cloud Migration", "prob_a": 0.7, "val_a": 12000, "name_b": "On-Premises", "prob_b": 1.0, "val_b": 8000 },
	{ "name_a": "Outsource Dev", "prob_a": 0.6, "val_a": 15000, "name_b": "Local Dev", "prob_b": 0.9, "val_b": 9000 }
]


# ─────────────────────────────────────────────────────────────────────────────
func start(game_area: Control, overlay: Node) -> void:
	_game_area = game_area
	_overlay = overlay

	var size = game_area.size
	_left_x = size.x * 0.35
	_right_x = size.x * 0.65
	_player_y = size.y - 60.0

	# Background
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.15)
	bg.size = size
	bg.position = Vector2.ZERO
	game_area.add_child(bg)

	# Lane dividers (animated dashed road)
	for i in range(12):
		var dash = ColorRect.new()
		dash.color = Color(0.0, 1.0, 1.0, 0.8)
		dash.size = Vector2(8, 40)
		dash.position = Vector2(size.x / 2.0 - 4, i * 80.0)
		game_area.add_child(dash)
		_dashes.append(dash)

	# Lane edge lines
	var left_edge = ColorRect.new()
	left_edge.color = Color(1.0, 0.0, 1.0, 0.8)
	left_edge.size = Vector2(4, size.y)
	left_edge.position = Vector2(size.x * 0.1, 0)
	game_area.add_child(left_edge)

	var left_inner_edge = ColorRect.new()
	left_inner_edge.color = Color(1.0, 0.0, 1.0, 0.8)
	left_inner_edge.size = Vector2(4, size.y)
	left_inner_edge.position = Vector2(size.x * 0.3, 0)
	game_area.add_child(left_inner_edge)

	var right_inner_edge = ColorRect.new()
	right_inner_edge.color = Color(1.0, 0.0, 1.0, 0.8)
	right_inner_edge.size = Vector2(4, size.y)
	right_inner_edge.position = Vector2(size.x * 0.7, 0)
	game_area.add_child(right_inner_edge)

	var right_edge = ColorRect.new()
	right_edge.color = Color(1.0, 0.0, 1.0, 0.8)
	right_edge.size = Vector2(4, size.y)
	right_edge.position = Vector2(size.x * 0.9, 0)
	game_area.add_child(right_edge)

	# Player (sci-fi ship representation)
	_player = ColorRect.new()
	_player.color = Color(0.1, 0.1, 0.25)
	_player.size = Vector2(60, 40)
	_player.position = Vector2(_left_x - 30, _player_y - 20)
	
	var p_border = ReferenceRect.new()
	p_border.editor_only = false
	p_border.border_color = Color(0.0, 1.0, 1.0)
	p_border.border_width = 3.0
	p_border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_player.add_child(p_border)
	game_area.add_child(_player)

	var ship_lbl = Label.new()
	ship_lbl.text = "🚀"
	ship_lbl.add_theme_font_size_override("font_size", 24)
	ship_lbl.size = Vector2(60, 40)
	ship_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ship_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_player.add_child(ship_lbl)

	# Lane indicator label
	_lane_label = Label.new()
	_lane_label.add_theme_font_size_override("font_size", 22)
	_lane_label.modulate = Color(0.9, 0.9, 0.5)
	_lane_label.text = "LANE: LEFT"
	_lane_label.position = Vector2(_left_x - 50, _player_y - 60)
	game_area.add_child(_lane_label)

	# Score / budget
	_score_label = Label.new()
	_score_label.add_theme_font_size_override("font_size", 22)
	_score_label.modulate = Color(0.5, 1.0, 0.5)
	_score_label.text = "Score: 0"
	_score_label.position = Vector2(20, 20)
	game_area.add_child(_score_label)

	_budget_label = Label.new()
	_budget_label.add_theme_font_size_override("font_size", 22)
	_budget_label.modulate = Color(1.0, 0.8, 0.3)
	_budget_label.text = "Budget Δ: $0"
	_budget_label.position = Vector2(20, 50)
	game_area.add_child(_budget_label)

	# Controls tip
	var controls_tip = Label.new()
	controls_tip.add_theme_font_size_override("font_size", 14)
	controls_tip.modulate = Color(0.6, 0.8, 1.0)
	controls_tip.text = "CONTROLS: ← A = Left Lane | D = Right Lane →"
	controls_tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls_tip.size = Vector2(size.x, 30)
	controls_tip.position = Vector2(0, 5)
	game_area.add_child(controls_tip)

	_spawn_interval = 2.0 / GameManager.speed_multiplier
	_spawn_timer = 0.5  # short delay before first fork


# ─────────────────────────────────────────────────────────────────────────────
func tick(delta: float) -> bool:
	if _done:
		return true

	var size = _game_area.size
	var speed_mult = GameManager.speed_multiplier
	var fork_speed = FORK_SPEED_BASE * speed_mult

	# ── Player lane switch ────────────────────────────────────────────────
	if Input.is_action_just_pressed("move_left"):
		_lane = 0
		_update_player_position(size)
	if Input.is_action_just_pressed("move_right"):
		_lane = 1
		_update_player_position(size)

	# ── Animate Dashes ────────────────────────────────────────────────────
	for dash in _dashes:
		dash.position.y += fork_speed * delta * 1.5
		if dash.position.y > size.y:
			dash.position.y -= size.y + 80.0

	# ── Spawn fork ────────────────────────────────────────────────────────
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = _spawn_interval
		_spawn_fork(size)

	# ── Move / resolve forks ──────────────────────────────────────────────
	var to_remove: Array = []
	for f in _forks:
		f.y += fork_speed * delta
		f.node.position = Vector2(size.x * 0.1, f.y - 20)

		if not f.resolved and f.y >= _player_y - 30.0 and f.y <= _player_y + 30.0:
			f.resolved = true
			_resolve_fork(f, size)

		# Remove if past bottom
		if f.y > size.y + 60:
			f.node.queue_free()
			to_remove.append(f)

	for f in to_remove:
		_forks.erase(f)

	_score_label.text = "Score: %d" % _score
	_budget_label.text = "Budget Δ: $%d" % _budget_delta
	return false


# ─────────────────────────────────────────────────────────────────────────────
func get_result() -> Dictionary:
	return {
		"score": _score,
		"budget_delta": _budget_delta,
		"days_delta": _days_delta
	}


# ─────────────────────────────────────────────────────────────────────────────
func _update_player_position(size: Vector2) -> void:
	var target_x = _left_x if _lane == 0 else _right_x
	_player.position = Vector2(target_x - 30, _player_y - 20)
	_lane_label.text = "LANE: LEFT" if _lane == 0 else "LANE: RIGHT"
	_lane_label.position = Vector2(target_x - 50, _player_y - 60)


# ─────────────────────────────────────────────────────────────────────────────
func _spawn_fork(size: Vector2) -> void:
	var scenario = SCENARIOS[randi() % SCENARIOS.size()]
	
	var emv_a = int(scenario["prob_a"] * scenario["val_a"])
	var emv_b = int(scenario["prob_b"] * scenario["val_b"])
	
	var swap = randf() > 0.5
	var left_emv = emv_b if swap else emv_a
	var right_emv = emv_a if swap else emv_b
	
	var left_text = ("%s\n%d%% chance of $%dk" % [scenario["name_b"], int(scenario["prob_b"]*100), scenario["val_b"]/1000]) if swap else ("%s\n%d%% chance of $%dk" % [scenario["name_a"], int(scenario["prob_a"]*100), scenario["val_a"]/1000])
	var right_text = ("%s\n%d%% chance of $%dk" % [scenario["name_a"], int(scenario["prob_a"]*100), scenario["val_a"]/1000]) if swap else ("%s\n%d%% chance of $%dk" % [scenario["name_b"], int(scenario["prob_b"]*100), scenario["val_b"]/1000])

	# Build fork node
	var fork_node = Control.new()
	fork_node.size = Vector2(size.x * 0.8, 60)
	fork_node.position = Vector2(size.x * 0.1, -80)
	_game_area.add_child(fork_node)

	# Horizontal bar
	var bar = ColorRect.new()
	bar.color = Color(0.0, 1.0, 1.0, 0.4)
	bar.size = Vector2(size.x * 0.8, 8)
	bar.position = Vector2(0, 26)
	fork_node.add_child(bar)

	# Left panel
	var left_rect = ColorRect.new()
	left_rect.color = Color(0.1, 0.2, 0.4, 0.9)
	left_rect.size = Vector2(size.x * 0.35, 60)
	left_rect.position = Vector2(0, 0)
	fork_node.add_child(left_rect)

	var left_lbl = Label.new()
	left_lbl.text = left_text
	left_lbl.add_theme_font_size_override("font_size", 14)
	left_lbl.modulate = Color(1, 1, 1)
	left_lbl.size = Vector2(size.x * 0.35, 60)
	left_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	left_rect.add_child(left_lbl)

	# Right panel
	var right_rect = ColorRect.new()
	right_rect.color = Color(0.1, 0.2, 0.4, 0.9)
	right_rect.size = Vector2(size.x * 0.35, 60)
	right_rect.position = Vector2(size.x * 0.45, 0)
	fork_node.add_child(right_rect)

	var right_lbl = Label.new()
	right_lbl.text = right_text
	right_lbl.add_theme_font_size_override("font_size", 14)
	right_lbl.modulate = Color(1, 1, 1)
	right_lbl.size = Vector2(size.x * 0.35, 60)
	right_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	right_rect.add_child(right_lbl)

	var fork = {
		"node": fork_node,
		"left_emv": left_emv,
		"right_emv": right_emv,
		"y": -80.0,
		"resolved": false
	}
	_forks.append(fork)


# ─────────────────────────────────────────────────────────────────────────────
func _resolve_fork(f: Dictionary, size: Vector2) -> void:
	var chosen_emv: int
	var other_emv: int
	if _lane == 0:
		chosen_emv = f.left_emv
		other_emv = f.right_emv
	else:
		chosen_emv = f.right_emv
		other_emv = f.left_emv

	if chosen_emv >= other_emv:
		_budget_delta += chosen_emv
		_score += 50
		JuiceManager.correct_sound()
		JuiceManager.spawn_floating_text(_game_area, Vector2(size.x / 2.0, _player_y - 40),
			"BEST EMV! +$%d" % chosen_emv, Color(0.3, 1.0, 0.3))
	else:
		_score -= 25
		JuiceManager.wrong_sound()
		JuiceManager.hit_stop_and_shake(0.4)
		JuiceManager.spawn_floating_text(_game_area, Vector2(size.x / 2.0, _player_y - 40),
			"SUBOPTIMAL! Missed $%d" % (other_emv - chosen_emv), Color(1, 0.4, 0.2))
