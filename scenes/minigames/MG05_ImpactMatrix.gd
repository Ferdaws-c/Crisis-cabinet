## MG05_ImpactMatrix.gd
## PMBOK: Tusler Risk Classification (Probability vs. Impact)
## Mechanic: Navigate 4 quadrants, collect tokens in safe zones, avoid danger flashes.

extends Node

# ── Interface state ──────────────────────────────────────────────────────────
var _done: bool = false
var score: int = 0
var budget_delta: int = 0
var days_delta: int = 0

# ── Game references ───────────────────────────────────────────────────────────
var _game_area: Control
var _overlay: Node

# ── Player ────────────────────────────────────────────────────────────────────
var _player: ColorRect
var _player_pos: Vector2

# ── Quadrant definitions ──────────────────────────────────────────────────────
# Index: 0=top-left, 1=top-right, 2=bottom-left, 3=bottom-right
const QUAD_LABELS: Array = [
	"🐊 ALLIGATOR\nLow P / High I",
	"🐯 TIGER\nHigh P / High I",
	"🐱 KITTEN\nLow P / Low I",
	"🐶 PUPPY\nHigh P / Low I"
]
const QUAD_COLORS: Array = [
	Color(0.8, 0.45, 0.1, 0.35),   # orange
	Color(0.85, 0.1, 0.1, 0.35),   # red
	Color(0.1, 0.7, 0.2, 0.35),    # green
	Color(0.1, 0.3, 0.85, 0.35),   # blue
]
const QUAD_DAMAGE: Array = [10000, 15000, 1000, 3000]

var _quad_rects: Array = []   # Rect2 for each quadrant
var _quad_nodes: Array = []   # ColorRect for each quadrant

# ── Game State ────────────────────────────────────────────────────────────────
var _state: String = "READ"  # "READ" or "EVAL"
var _timer: float = 4.0
var _current_scenario: Dictionary
var _scenarios_played: int = 0
const MAX_SCENARIOS: int = 6

const SCENARIOS: Array = [
	{ "text": "Key developer quits right before launch.\n(Probability: Low | Impact: High)", "answer": 0 },
	{ "text": "Major hurricane hits datacenter.\n(Probability: Low | Impact: High)", "answer": 0 },
	{ "text": "Vendor increases software licensing by 5%.\n(Probability: High | Impact: Low)", "answer": 3 },
	{ "text": "Team members arrive 5 mins late to standup.\n(Probability: High | Impact: Low)", "answer": 3 },
	{ "text": "Critical API goes offline daily.\n(Probability: High | Impact: High)", "answer": 1 },
	{ "text": "Funding gets completely cut next week.\n(Probability: High | Impact: High)", "answer": 1 },
	{ "text": "We run out of decaf coffee.\n(Probability: Low | Impact: Low)", "answer": 2 },
	{ "text": "A typo in an internal wiki page.\n(Probability: Low | Impact: Low)", "answer": 2 }
]

var _scenario_panel: ColorRect
var _scenario_label: Label
var _time_label: Label

# ── UI ────────────────────────────────────────────────────────────────────────
var _score_label: Label
var _budget_label: Label

# ── Constants ─────────────────────────────────────────────────────────────────
const PLAYER_SPEED: float = 500.0
const PLAYER_SIZE: float = 24.0


# ─────────────────────────────────────────────────────────────────────────────
func start(game_area: Control, overlay: Node) -> void:
	_game_area = game_area
	_overlay = overlay

	var size = game_area.size
	var half_w = size.x / 2.0
	var half_h = size.y / 2.0

	_quad_rects = [
		Rect2(0, 0, half_w, half_h),                    # top-left
		Rect2(half_w, 0, half_w, half_h),               # top-right
		Rect2(0, half_h, half_w, half_h),               # bottom-left
		Rect2(half_w, half_h, half_w, half_h),          # bottom-right
	]

	# Background
	var bg = ColorRect.new()
	bg.color = Color(0.06, 0.06, 0.1)
	bg.size = size
	bg.position = Vector2.ZERO
	game_area.add_child(bg)

	# Draw quadrants
	for i in range(4):
		var rect = _quad_rects[i]
		var node = ColorRect.new()
		node.color = QUAD_COLORS[i]
		node.size = rect.size
		node.position = rect.position
		game_area.add_child(node)
		_quad_nodes.append(node)

		# Quadrant label
		var lbl = Label.new()
		lbl.text = QUAD_LABELS[i]
		lbl.add_theme_font_size_override("font_size", 18)
		lbl.modulate = Color(1, 1, 1, 0.85)
		lbl.size = rect.size
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		node.add_child(lbl)

	# Grid lines
	var hline = ColorRect.new()
	hline.color = Color(0.4, 0.4, 0.5)
	hline.size = Vector2(size.x, 2)
	hline.position = Vector2(0, half_h - 1)
	game_area.add_child(hline)

	var vline = ColorRect.new()
	vline.color = Color(0.4, 0.4, 0.5)
	vline.size = Vector2(2, size.y)
	vline.position = Vector2(half_w - 1, 0)
	game_area.add_child(vline)

	# Axis labels
	var x_lbl_l = Label.new()
	x_lbl_l.text = "← Low Probability"
	x_lbl_l.add_theme_font_size_override("font_size", 14)
	x_lbl_l.modulate = Color(0.6, 0.6, 0.7)
	x_lbl_l.position = Vector2(10, half_h - 24)
	game_area.add_child(x_lbl_l)

	var x_lbl_r = Label.new()
	x_lbl_r.text = "High Probability →"
	x_lbl_r.add_theme_font_size_override("font_size", 14)
	x_lbl_r.modulate = Color(0.6, 0.6, 0.7)
	x_lbl_r.position = Vector2(half_w + 10, half_h - 24)
	game_area.add_child(x_lbl_r)

	var y_lbl_t = Label.new()
	y_lbl_t.text = "High Impact ↑"
	y_lbl_t.add_theme_font_size_override("font_size", 14)
	y_lbl_t.modulate = Color(0.6, 0.6, 0.7)
	y_lbl_t.position = Vector2(half_w - 60, 10)
	game_area.add_child(y_lbl_t)

	# Player
	_player_pos = Vector2(half_w * 0.5, half_h * 1.5)  # bottom-left quadrant start
	_player = ColorRect.new()
	_player.color = Color(1.0, 1.0, 1.0)
	_player.size = Vector2(PLAYER_SIZE, PLAYER_SIZE)
	_player.position = _player_pos - Vector2(PLAYER_SIZE / 2.0, PLAYER_SIZE / 2.0)
	game_area.add_child(_player)

	var p_icon = Label.new()
	p_icon.text = "🏃"
	p_icon.add_theme_font_size_override("font_size", 18)
	p_icon.size = Vector2(PLAYER_SIZE, PLAYER_SIZE)
	p_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_player.add_child(p_icon)

	# Scenario Display
	_scenario_panel = ColorRect.new()
	_scenario_panel.color = Color(0.1, 0.1, 0.2, 0.95)
	_scenario_panel.size = Vector2(size.x * 0.7, 100)
	_scenario_panel.position = Vector2(size.x * 0.15, size.y / 2.0 - 50)
	game_area.add_child(_scenario_panel)
	
	var border = ReferenceRect.new()
	border.editor_only = false
	border.border_color = Color(1.0, 0.8, 0.2)
	border.border_width = 3.0
	border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scenario_panel.add_child(border)

	_scenario_label = Label.new()
	_scenario_label.add_theme_font_size_override("font_size", 18)
	_scenario_label.modulate = Color(1, 1, 1)
	_scenario_label.size = _scenario_panel.size
	_scenario_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_scenario_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_scenario_panel.add_child(_scenario_label)

	_time_label = Label.new()
	_time_label.add_theme_font_size_override("font_size", 48)
	_time_label.modulate = Color(1, 0.2, 0.2)
	_time_label.position = Vector2(size.x / 2.0 - 20, size.y / 2.0 - 120)
	game_area.add_child(_time_label)

	# Instructions
	var instruct = Label.new()
	instruct.add_theme_font_size_override("font_size", 16)
	instruct.modulate = Color(0.7, 0.7, 0.8)
	instruct.text = "WASD to move  |  Run to the correct quadrant before time runs out!"
	instruct.position = Vector2(size.x / 2.0 - 240, size.y - 30)
	game_area.add_child(instruct)

	# Score and Budget
	_score_label = Label.new()
	_score_label.add_theme_font_size_override("font_size", 20)
	_score_label.modulate = Color(0.5, 1.0, 0.5)
	_score_label.text = "Score: 0"
	_score_label.position = Vector2(20, 20)
	game_area.add_child(_score_label)

	_budget_label = Label.new()
	_budget_label.add_theme_font_size_override("font_size", 20)
	_budget_label.modulate = Color(1.0, 0.8, 0.3)
	_budget_label.text = "Budget Δ: $0"
	_budget_label.position = Vector2(20, 50)
	game_area.add_child(_budget_label)

	_pick_next_scenario()


# ─────────────────────────────────────────────────────────────────────────────
func tick(delta: float) -> bool:
	if _done:
		return true

	var size = _game_area.size
	var speed_mult = GameManager.speed_multiplier

	# ── Player movement ───────────────────────────────────────────────────
	var move = Vector2.ZERO
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		move.y -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		move.y += 1
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		move.x -= 1
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		move.x += 1
	if move.length() > 0:
		move = move.normalized()
	_player_pos += move * PLAYER_SPEED * delta
	_player_pos.x = clamp(_player_pos.x, PLAYER_SIZE / 2.0, size.x - PLAYER_SIZE / 2.0)
	_player_pos.y = clamp(_player_pos.y, PLAYER_SIZE / 2.0, size.y - PLAYER_SIZE / 2.0)
	_player.position = _player_pos - Vector2(PLAYER_SIZE / 2.0, PLAYER_SIZE / 2.0)

	_timer -= delta
	
	if _state == "READ":
		_time_label.text = str(ceil(_timer))
		if _timer <= 0.0:
			_evaluate_position()
			_state = "EVAL"
			_timer = 1.5
	elif _state == "EVAL":
		_time_label.text = ""
		if _timer <= 0.0:
			if _scenarios_played >= MAX_SCENARIOS:
				_done = true
				score += 500
				JuiceManager.bonus_sound()
				JuiceManager.spawn_floating_text(_game_area, Vector2(size.x / 2.0, size.y / 2.0), "COMPLETED!\n+500 BONUS!", Color(1.0, 0.9, 0.2))
			else:
				_pick_next_scenario()
				_state = "READ"
				_timer = 4.0 / speed_mult
				# Restore original colors
				for i in range(4):
					_quad_nodes[i].color = QUAD_COLORS[i]

	_score_label.text = "Score: %d" % score
	_budget_label.text = "Budget Δ: $%d" % budget_delta
	return false


# ─────────────────────────────────────────────────────────────────────────────
func get_result() -> Dictionary:
	return {
		"score": score,
		"budget_delta": budget_delta,
		"days_delta": days_delta
	}


func _pick_next_scenario() -> void:
	_current_scenario = SCENARIOS[randi() % SCENARIOS.size()]
	if is_instance_valid(_scenario_label):
		_scenario_label.text = _current_scenario["text"]
	_scenarios_played += 1

func _evaluate_position() -> void:
	var player_quad = _get_player_quadrant(_game_area.size)
	var correct_quad = _current_scenario["answer"]
	
	if player_quad == correct_quad:
		score += 150
		budget_delta += 2000
		JuiceManager.correct_sound()
		JuiceManager.spawn_floating_text(_game_area, _player_pos + Vector2(-20, -30), "CORRECT! +$2,000", Color(0.3, 1.0, 0.3))
		_quad_nodes[correct_quad].color = Color(0.2, 1.0, 0.2, 0.6)
	else:
		score -= 100
		budget_delta -= 5000
		JuiceManager.wrong_sound()
		JuiceManager.hit_stop_and_shake(0.5)
		JuiceManager.spawn_floating_text(_game_area, _player_pos + Vector2(-20, -30), "WRONG! -$5,000", Color(1.0, 0.2, 0.2))
		if player_quad != -1:
			_quad_nodes[player_quad].color = Color(1.0, 0.2, 0.2, 0.6)
		_quad_nodes[correct_quad].color = Color(0.2, 1.0, 0.2, 0.4) # Highlight correct answer slightly

func _get_player_quadrant(size: Vector2) -> int:
	for i in range(4):
		if _quad_rects[i].has_point(_player_pos):
			return i
	return -1
