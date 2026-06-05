## MG06_MonteCarlo.gd
## PMBOK: Quantitative Probability Distributions
## Mechanic: Catch orange balls (expected outcomes), dodge red outlier balls with a basket.

extends Node

# ── Interface state ──────────────────────────────────────────────────────────
var _done: bool = false
var score: int = 0
var budget_delta: int = 0
var days_delta: int = 0
var _combo: int = 0
var _sims_run: int = 0

# ── Game references ───────────────────────────────────────────────────────────
var _game_area: Control
var _overlay: Node

# ── Basket ────────────────────────────────────────────────────────────────────
var _basket: ColorRect
var _basket_x: float = 0.0
var _basket_y: float = 0.0
const BASKET_W: float = 120.0
const BASKET_H: float = 24.0

# ── Balls ─────────────────────────────────────────────────────────────────────
# Each ball: {node: ColorRect, x: float, y: float, is_red: bool, active: bool}
var _balls: Array = []
var _spawn_timer: float = 0.0
var _spawn_interval: float = 0.6
const MAX_BALLS: int = 12
const BALL_SIZE: float = 20.0
const BALL_FALL_BASE: float = 380.0

# ── Bell curve visual ─────────────────────────────────────────────────────────
var _curve_dots: Array = []   # ColorRect dots for bell curve
const CURVE_DOTS: int = 40
const CURVE_HEIGHT: float = 60.0
const CURVE_Y: float = 60.0

# ── UI ────────────────────────────────────────────────────────────────────────
var _score_label: Label
var _budget_label: Label
var _sim_label: Label

# ── Constants ─────────────────────────────────────────────────────────────────
const BASKET_SPEED_BASE: float = 500.0
const CATCH_HALF_W: float = 70.0


# ─────────────────────────────────────────────────────────────────────────────
## Box-Muller Gaussian random
func _randn() -> float:
	var u1 = max(randf(), 0.0001)
	var v1 = randf()
	return sqrt(-2.0 * log(u1)) * cos(TAU * v1)


# ─────────────────────────────────────────────────────────────────────────────
func start(game_area: Control, overlay: Node) -> void:
	_game_area = game_area
	_overlay = overlay

	var size = game_area.size

	# Background
	var bg = ColorRect.new()
	bg.color = Color(0.04, 0.04, 0.1)
	bg.size = size
	bg.position = Vector2.ZERO
	game_area.add_child(bg)

	# ── Bell curve visual ─────────────────────────────────────────────────
	for i in range(CURVE_DOTS):
		var t = float(i) / float(CURVE_DOTS - 1)  # 0..1
		var x_norm = (t - 0.5) * 4.0  # range -2..2 (in sigma units)
		var bell_y = exp(-x_norm * x_norm / 2.0)  # Gaussian PDF (unnormalized)
		var dot_x = size.x * t
		var dot_h = bell_y * CURVE_HEIGHT
		var dot = ColorRect.new()
		dot.color = Color(0.3, 0.7, 1.0, 0.6)
		dot.size = Vector2(max(4, size.x / CURVE_DOTS - 1), dot_h)
		dot.position = Vector2(dot_x - 2, CURVE_Y + CURVE_HEIGHT - dot_h)
		game_area.add_child(dot)
		_curve_dots.append(dot)

	# Curve label
	var curve_lbl = Label.new()
	curve_lbl.text = "Bell Curve: Most balls fall near center"
	curve_lbl.add_theme_font_size_override("font_size", 15)
	curve_lbl.modulate = Color(0.5, 0.8, 1.0)
	curve_lbl.position = Vector2(size.x / 2.0 - 140, CURVE_Y + CURVE_HEIGHT + 5)
	game_area.add_child(curve_lbl)

	# Divider line
	var divider = ColorRect.new()
	divider.color = Color(0.3, 0.3, 0.4)
	divider.size = Vector2(size.x, 2)
	divider.position = Vector2(0, CURVE_Y + CURVE_HEIGHT + 26)
	game_area.add_child(divider)

	# Outer zone markers (outlier zone)
	var outlier_threshold_left = size.x / 2.0 - size.x * 0.35
	var outlier_threshold_right = size.x / 2.0 + size.x * 0.35

	var left_zone = ColorRect.new()
	left_zone.color = Color(0.8, 0.1, 0.1, 0.15)
	left_zone.size = Vector2(outlier_threshold_left, size.y)
	left_zone.position = Vector2.ZERO
	game_area.add_child(left_zone)

	var right_zone = ColorRect.new()
	right_zone.color = Color(0.8, 0.1, 0.1, 0.15)
	right_zone.size = Vector2(size.x - outlier_threshold_right, size.y)
	right_zone.position = Vector2(outlier_threshold_right, 0)
	game_area.add_child(right_zone)

	# Instructions label
	var instruct = Label.new()
	instruct.add_theme_font_size_override("font_size", 17)
	instruct.modulate = Color(0.85, 0.85, 0.9)
	instruct.text = "🟠 = Expected (catch!)   🔴 = Outlier (dodge!)   ← A / D → to move"
	instruct.position = Vector2(size.x / 2.0 - 270, 12)
	game_area.add_child(instruct)

	# Basket
	_basket_x = size.x / 2.0
	_basket_y = size.y - 40.0
	_basket = ColorRect.new()
	_basket.color = Color(0.4, 0.55, 0.9)
	_basket.size = Vector2(BASKET_W, BASKET_H)
	_basket.position = Vector2(_basket_x - BASKET_W / 2.0, _basket_y - BASKET_H / 2.0)
	game_area.add_child(_basket)

	var basket_rim = ColorRect.new()
	basket_rim.color = Color(0.2, 0.8, 0.9)
	basket_rim.size = Vector2(BASKET_W + 10, 8)
	basket_rim.position = Vector2(-5, -4)
	_basket.add_child(basket_rim)

	# Basket label
	var b_lbl = Label.new()
	b_lbl.text = "CATCHER"
	b_lbl.add_theme_font_size_override("font_size", 12)
	b_lbl.modulate = Color(1.0, 1.0, 1.0)
	b_lbl.size = Vector2(BASKET_W, BASKET_H)
	b_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_basket.add_child(b_lbl)

	# Simulation Counter
	_sim_label = Label.new()
	_sim_label.add_theme_font_size_override("font_size", 64)
	_sim_label.modulate = Color(1.0, 1.0, 1.0, 0.05)
	_sim_label.text = "SIMULATIONS:\n0"
	_sim_label.position = Vector2(20, size.y / 2.0 - 50)
	game_area.add_child(_sim_label)

	# Score / Budget
	_score_label = Label.new()
	_score_label.add_theme_font_size_override("font_size", 20)
	_score_label.modulate = Color(0.5, 1.0, 0.5)
	_score_label.text = "Score: 0"
	_score_label.position = Vector2(20, CURVE_Y + CURVE_HEIGHT + 30)
	game_area.add_child(_score_label)

	_budget_label = Label.new()
	_budget_label.add_theme_font_size_override("font_size", 20)
	_budget_label.modulate = Color(1.0, 0.8, 0.3)
	_budget_label.text = "Budget Δ: $0"
	_budget_label.position = Vector2(20, CURVE_Y + CURVE_HEIGHT + 55)
	game_area.add_child(_budget_label)

	_spawn_interval = 0.6 / GameManager.speed_multiplier
	_spawn_timer = 0.3


# ─────────────────────────────────────────────────────────────────────────────
func tick(delta: float) -> bool:
	if _done:
		return true

	var size = _game_area.size
	var speed_mult = GameManager.speed_multiplier

	_sims_run += int(randf_range(100, 5000) * speed_mult)
	_sim_label.text = "SIMULATIONS RUN:\n%d" % _sims_run

	# ── Basket movement ───────────────────────────────────────────────────
	var basket_speed = BASKET_SPEED_BASE * speed_mult
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		_basket_x -= basket_speed * delta
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		_basket_x += basket_speed * delta
	_basket_x = clamp(_basket_x, BASKET_W / 2.0, size.x - BASKET_W / 2.0)
	_basket.position = Vector2(_basket_x - BASKET_W / 2.0, _basket_y - BASKET_H / 2.0)

	# ── Spawn timer ───────────────────────────────────────────────────────
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = 0.6 / speed_mult
		if _active_ball_count() < MAX_BALLS:
			_spawn_ball(size)

	# ── Update balls ──────────────────────────────────────────────────────
	var to_remove: Array = []
	for ball in _balls:
		if not ball.active:
			continue

		ball.y += BALL_FALL_BASE * speed_mult * delta
		ball.node.position = Vector2(ball.x - BALL_SIZE / 2.0, ball.y - BALL_SIZE / 2.0)
		ball.node.rotation += 6.0 * delta * (1.0 if ball.is_red else -1.0)

		# ── Catch check ───────────────────────────────────────────────────
		if ball.y >= _basket_y - BALL_SIZE / 2.0 and ball.y <= _basket_y + BALL_SIZE:
			if abs(ball.x - _basket_x) < CATCH_HALF_W:
				# Caught!
				if ball.is_red:
					# Red outlier — penalty
					_combo = 0
					_basket.color = Color(0.4, 0.55, 0.9)
					budget_delta -= 5000
					JuiceManager.wrong_sound()
					JuiceManager.hit_stop_and_shake(0.6)
					JuiceManager.spawn_floating_text(_game_area, Vector2(ball.x, _basket_y - 30),
						"OUTLIER! -$5,000", Color(1, 0.2, 0.2))
				else:
					# Green expected — reward
					_combo += 1
					var mult = 1 + (_combo / 5)
					_basket.color = Color(min(1.0, 0.4 + _combo * 0.05), min(1.0, 0.55 + _combo * 0.05), 0.9, 1.0)
					score += 10 * mult
					JuiceManager.correct_sound()
					JuiceManager.spawn_floating_text(_game_area, Vector2(ball.x, _basket_y - 30),
						"+%d (x%d)" % [10 * mult, mult], Color(1.0, 0.6, 0.0))
				ball.node.queue_free()
				ball.active = false
				to_remove.append(ball)
				continue

		# ── Miss check (past basket) ───────────────────────────────────────
		if ball.y > size.y + 20:
			if not ball.is_red:
				# Missed a green ball
				_combo = 0
				_basket.color = Color(0.4, 0.55, 0.9)
				score -= 10
				JuiceManager.spawn_floating_text(_game_area, Vector2(ball.x, size.y - 40),
					"MISSED -10", Color(1.0, 0.6, 0.2))
			# Red balls that fall past basket are fine (successfully dodged)
			ball.node.queue_free()
			ball.active = false
			to_remove.append(ball)

	for b in to_remove:
		_balls.erase(b)

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


# ─────────────────────────────────────────────────────────────────────────────
func _spawn_ball(size: Vector2) -> void:
	# Force red outlier 25% of the time
	var force_red = randf() < 0.25
	var spawn_x: float
	var is_red: bool

	if force_red:
		# Spawn at a random edge position
		if randf() < 0.5:
			spawn_x = randf_range(10, size.x * 0.15)
		else:
			spawn_x = randf_range(size.x * 0.85, size.x - 10)
		is_red = true
	else:
		# Gaussian distribution around center
		spawn_x = size.x / 2.0 + _randn() * 160.0
		spawn_x = clamp(spawn_x, 20, size.x - 20)
		# Determine color by position
		is_red = abs(spawn_x - size.x / 2.0) > size.x * 0.35

	var node = ColorRect.new()
	node.color = Color(0.9, 0.2, 0.2) if is_red else Color(1.0, 0.6, 0.0)
	node.size = Vector2(BALL_SIZE, BALL_SIZE)
	node.position = Vector2(spawn_x - BALL_SIZE / 2.0, -BALL_SIZE)
	node.pivot_offset = Vector2(BALL_SIZE / 2.0, BALL_SIZE / 2.0)
	_game_area.add_child(node)

	# Ball icon
	var lbl = Label.new()
	lbl.text = "●"
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.modulate = Color(1, 1, 1, 0.8)
	lbl.size = Vector2(BALL_SIZE, BALL_SIZE)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	node.add_child(lbl)

	_balls.append({
		"node": node,
		"x": spawn_x,
		"y": -BALL_SIZE / 2.0,
		"is_red": is_red,
		"active": true
	})


# ─────────────────────────────────────────────────────────────────────────────
func _active_ball_count() -> int:
	var count = 0
	for b in _balls:
		if b.active:
			count += 1
	return count
