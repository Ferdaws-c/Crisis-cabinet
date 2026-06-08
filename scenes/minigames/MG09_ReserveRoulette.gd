## MG09_ReserveRoulette.gd
## PMBOK: Contingency vs. Management Reserves
## Mechanic: Space-shooter. SPACE fires Contingency (blue risks). Q fires Management Reserve AoE.

extends Node

# ── Interface state ──────────────────────────────────────────────
var _game_area: Control
var _overlay: Node

var _score: int = 0
var _budget_delta: int = 0
var _days_delta: int = 0
var _finished: bool = false

# ── Runtime ───────────────────────────────────────────────────────
var _core_pos: Vector2
var _player_node: Polygon2D
var _known_risks: Array = []     # ColorRect nodes
var _unknown_bosses: Array = []  # ColorRect nodes
var _projectiles: Array = []     # ColorRect nodes

var _known_spawn_timer: float = 0.0
var _unknown_spawn_timer: float = 20.0
var _q_cooldown: float = 0.0
const Q_COOLDOWN_MAX := 15.0

var _game_timer: float = 60.0   # 60-second game

var _score_label: Label
var _q_cooldown_bar: ColorRect
var _q_cooldown_bg: ColorRect
var _hint_q: Label
var _prev_q: bool = false   # manual edge detection for Q key

func start(game_area: Control, overlay: Node) -> void:
	_game_area = game_area
	_overlay = overlay
	var size: Vector2 = game_area.size
	_core_pos = Vector2(size.x * 0.5, size.y - 60)

	# Background
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.04, 0.10)
	bg.size = size
	game_area.add_child(bg)

	# Title
	var title := Label.new()
	title.text = "RESERVE ROULETTE — Defend the Project Core!"
	title.add_theme_font_size_override("font_size", 20)
	title.modulate = Color(0.9, 0.9, 1.0)
	title.position = Vector2(size.x * 0.5 - 240, 10)
	game_area.add_child(title)

	# Project Core (Player)
	var player_poly = Polygon2D.new()
	player_poly.polygon = PackedVector2Array([
		Vector2(0, -20),
		Vector2(-20, 20),
		Vector2(20, 20)
	])
	player_poly.color = Color(0.2, 0.9, 0.3)
	player_poly.position = _core_pos
	game_area.add_child(player_poly)
	_player_node = player_poly

	var core_lbl := Label.new()
	core_lbl.text = "CORE"
	core_lbl.add_theme_font_size_override("font_size", 10)
	core_lbl.position = Vector2(-15, 0)
	_player_node.add_child(core_lbl)

	# Hints
	var h1 := Label.new()
	h1.text = "SPACE = CONTINGENCY SHOT  (destroys 🔵 Known risks)"
	h1.add_theme_font_size_override("font_size", 14)
	h1.modulate = Color(0.7, 0.9, 1.0)
	h1.position = Vector2(10, size.y - 80)
	game_area.add_child(h1)

	_hint_q = Label.new()
	_hint_q.text = "Q = MANAGEMENT RESERVE AoE  (clears ALL — use wisely!)"
	_hint_q.add_theme_font_size_override("font_size", 14)
	_hint_q.modulate = Color(1.0, 0.85, 0.2)
	_hint_q.position = Vector2(10, size.y - 58)
	game_area.add_child(_hint_q)

	# Q cooldown bar
	var q_bg := ColorRect.new()
	q_bg.color = Color(0.2, 0.2, 0.2)
	q_bg.size = Vector2(200, 14)
	q_bg.position = Vector2(size.x - 220, size.y - 40)
	game_area.add_child(q_bg)
	_q_cooldown_bg = q_bg

	_q_cooldown_bar = ColorRect.new()
	_q_cooldown_bar.color = Color(1.0, 0.85, 0.2)
	_q_cooldown_bar.size = Vector2(200, 14)
	_q_cooldown_bar.position = q_bg.position
	game_area.add_child(_q_cooldown_bar)

	var q_lbl := Label.new()
	q_lbl.text = "Q COOLDOWN"
	q_lbl.add_theme_font_size_override("font_size", 12)
	q_lbl.position = Vector2(size.x - 220, size.y - 58)
	game_area.add_child(q_lbl)

	# Score + timer labels
	_score_label = Label.new()
	_score_label.text = "Score: 0"
	_score_label.add_theme_font_size_override("font_size", 18)
	_score_label.position = Vector2(10, 10)
	game_area.add_child(_score_label)

	var time_lbl := Label.new()
	time_lbl.name = "TimeLabel"
	time_lbl.text = "Time: 60s"
	time_lbl.add_theme_font_size_override("font_size", 18)
	time_lbl.modulate = Color(1, 0.9, 0.5)
	time_lbl.position = Vector2(size.x - 130, 10)
	game_area.add_child(time_lbl)

func _spawn_known() -> void:
	var size: Vector2 = _game_area.size
	var risk := ColorRect.new()
	risk.color = Color(0.2, 0.4, 0.95)
	risk.size = Vector2(40, 40)
	risk.position = Vector2(randf_range(20, size.x - 60), -50)
	_game_area.add_child(risk)

	var lbl := Label.new()
	lbl.text = "🔵\nKNOWN"
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.modulate = Color(1, 1, 1)
	lbl.position = Vector2(2, 2)
	risk.add_child(lbl)

	_known_risks.append(risk)

func _spawn_unknown() -> void:
	var size: Vector2 = _game_area.size
	var boss := ColorRect.new()
	boss.color = Color(0.85, 0.1, 0.1)
	boss.size = Vector2(70, 70)
	boss.position = Vector2(size.x * 0.5 - 35, -80)
	_game_area.add_child(boss)

	var lbl := Label.new()
	lbl.text = "🔴\nUNKNOWN"
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.modulate = Color(1, 1, 1)
	lbl.position = Vector2(4, 4)
	boss.add_child(lbl)

	_unknown_bosses.append(boss)

func _fire_projectile() -> void:
	var proj := ColorRect.new()
	proj.color = Color(1.0, 0.95, 0.2)
	proj.size = Vector2(8, 20)
	proj.position = _core_pos - Vector2(4, 20)
	_game_area.add_child(proj)
	_projectiles.append(proj)
	JuiceManager.correct_sound()

func tick(delta: float) -> bool:
	if _finished:
		return true

	var speed: float = GameManager.speed_multiplier
	var size: Vector2 = _game_area.size
	var core_y: float = _core_pos.y

	_game_timer -= delta
	if _game_timer <= 0.0:
		_finished = true
		return true

	var time_lbl: Label = _game_area.get_node_or_null("TimeLabel")
	if time_lbl:
		time_lbl.text = "Time: %ds" % int(ceil(_game_timer))

	# Player movement
	var move = Vector2.ZERO
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W): move.y -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S): move.y += 1
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A): move.x -= 1
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D): move.x += 1
	
	if move.length() > 0:
		move = move.normalized()
	_core_pos += move * 450.0 * speed * delta
	
	_core_pos.x = clamp(_core_pos.x, 20, size.x - 20)
	_core_pos.y = clamp(_core_pos.y, 20, size.y - 20)
	_player_node.position = _core_pos

	# Cooldown update
	if _q_cooldown > 0.0:
		_q_cooldown -= delta
		_q_cooldown_bar.size = Vector2(200.0 * clampf(_q_cooldown / Q_COOLDOWN_MAX, 0, 1), 14)
		_hint_q.modulate = Color(0.5, 0.5, 0.5)
	else:
		_q_cooldown_bar.size = Vector2(0, 14)
		_hint_q.modulate = Color(1.0, 0.85, 0.2)

	# Spawn known risks
	_known_spawn_timer -= delta
	if _known_spawn_timer <= 0.0:
		_known_spawn_timer = 1.0 / speed
		_spawn_known()

	# Spawn unknown boss
	_unknown_spawn_timer -= delta
	if _unknown_spawn_timer <= 0.0:
		_unknown_spawn_timer = 12.0
		_spawn_unknown()

	# Player input: fire projectile
	if Input.is_action_just_pressed("interact"):
		_fire_projectile()

	# Player input: management reserve AoE (manual edge detection — Godot 4 has no is_key_just_pressed)
	var q_now := Input.is_physical_key_pressed(KEY_Q)
	if q_now and not _prev_q and _q_cooldown <= 0.0:
		var has_boss := _unknown_bosses.size() > 0
		if has_boss:
			_score += 500
			_budget_delta += 5000
			JuiceManager.bonus_sound()
			JuiceManager.spawn_floating_text(_game_area, _core_pos + Vector2(0, -80), "RESERVE USED! +500 +$5K", Color(1, 1, 0))
		else:
			_score -= 200
			JuiceManager.wrong_sound()
			JuiceManager.spawn_floating_text(_game_area, _core_pos + Vector2(0, -80), "WASTED! -200 pts", Color(1, 0.3, 0.3))
		# Clear all enemies
		for r in _known_risks:
			r.queue_free()
		_known_risks.clear()
		for b in _unknown_bosses:
			b.queue_free()
		_unknown_bosses.clear()
		_q_cooldown = Q_COOLDOWN_MAX

	# Move projectiles up
	var dead_projs: Array = []
	for proj in _projectiles:
		if not is_instance_valid(proj):
			dead_projs.append(proj)
			continue
		proj.position.y -= 400.0 * delta
		if proj.position.y < -30:
			dead_projs.append(proj)
			proj.queue_free()
			continue
		# Check collision with known risks
		var proj_rect := Rect2(proj.position, proj.size)
		var hit_risk = null
		for risk in _known_risks:
			if not is_instance_valid(risk):
				continue
			if proj_rect.intersects(Rect2(risk.position, risk.size)):
				hit_risk = risk
				break
		if hit_risk:
			_score += 100
			JuiceManager.correct_sound()
			JuiceManager.spawn_floating_text(_game_area, hit_risk.position, "+100", Color(0.4, 0.9, 1.0))
			hit_risk.queue_free()
			_known_risks.erase(hit_risk)
			dead_projs.append(proj)
			proj.queue_free()
	for p in dead_projs:
		_projectiles.erase(p)

	# Move known risks down
	var dead_known: Array = []
	for risk in _known_risks:
		if not is_instance_valid(risk):
			dead_known.append(risk)
			continue
		risk.position.y += 200.0 * speed * delta
		
		# Check collision with player
		if Rect2(risk.position, risk.size).has_point(_core_pos) or risk.position.y >= size.y:
			_budget_delta -= 300
			JuiceManager.wrong_sound()
			JuiceManager.hit_stop_and_shake(0.4)
			JuiceManager.spawn_floating_text(_game_area, risk.position, "HIT! -$300", Color(1, 0.3, 0.3))
			dead_known.append(risk)
			risk.queue_free()
	for r in dead_known:
		_known_risks.erase(r)

	# Move unknown bosses down
	var dead_bosses: Array = []
	for boss in _unknown_bosses:
		if not is_instance_valid(boss):
			dead_bosses.append(boss)
			continue
		boss.position.y += 120.0 * speed * delta
		
		# Check collision with player
		if Rect2(boss.position, boss.size).has_point(_core_pos) or boss.position.y >= size.y:
			_budget_delta -= 20000
			_days_delta -= 10
			JuiceManager.wrong_sound()
			JuiceManager.hit_stop_and_shake(1.2)
			JuiceManager.spawn_floating_text(_game_area, boss.position, "UNKNOWN HIT! -$20K -10d", Color(1, 0, 0))
			dead_bosses.append(boss)
			boss.queue_free()
	for b in dead_bosses:
		_unknown_bosses.erase(b)

	_score_label.text = "Score: %d" % _score
	_prev_q = Input.is_physical_key_pressed(KEY_Q)
	return _finished

func get_result() -> Dictionary:
	return {
		"score": _score,
		"budget_delta": _budget_delta,
		"days_delta": _days_delta,
	}
