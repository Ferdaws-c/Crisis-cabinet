## MG07_StrategyStance.gd
## PMBOK: PMBOK 11.5 — Risk Response Strategies
## Mechanic: Dodge Fatal (Avoid), Laser Hazard (Mitigate), Drone Liability (Transfer), Shield Minor (Accept).

extends Node

# ── Interface state ──────────────────────────────────────────────
var _game_area: Control
var _overlay: Node

var _score: int = 0
var _budget_delta: int = 0
var _days_delta: int = 0
var _finished: bool = false

# ── Entities ─────────────────────────────────────────────────────
var _player: Polygon2D
var _player_pos: Vector2
var _shield: Polygon2D
var _shield_timer: float = 0.0

var _laser: Line2D
var _laser_target: Dictionary = {}

var _enemies: Array = []
var _drones: Array = []

var _spawn_timer: float = 0.0
var _spawn_interval: float = 2.0

var _score_label: Label
var _tip_label: Label

const PLAYER_SPEED: float = 350.0

func start(game_area: Control, overlay: Node) -> void:
	_game_area = game_area
	_overlay = overlay
	var size = _game_area.size
	_player_pos = size * 0.5

	# Background
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.1)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_game_area.add_child(bg)

	# Tip label
	_tip_label = Label.new()
	_tip_label.text = "🔴 Dodge (WASD)  |  🟠 Laser (Hold SPACE)  |  🔵 Drone (Press E)  |  🟢 Shield (Press Q)"
	_tip_label.add_theme_font_size_override("font_size", 16)
	_tip_label.modulate = Color(0.8, 0.9, 1.0)
	_tip_label.position = Vector2(size.x * 0.5 - 350, 10)
	_game_area.add_child(_tip_label)

	_score_label = Label.new()
	_score_label.text = "Score: 0"
	_score_label.add_theme_font_size_override("font_size", 22)
	_score_label.modulate = Color(0.5, 1.0, 0.5)
	_score_label.position = Vector2(20, 20)
	_game_area.add_child(_score_label)

	# Laser
	_laser = Line2D.new()
	_laser.width = 6.0
	_laser.default_color = Color(1.0, 0.8, 0.2)
	_laser.visible = false
	_game_area.add_child(_laser)

	# Player
	_player = Polygon2D.new()
	_player.polygon = PackedVector2Array([
		Vector2(0, -20), Vector2(15, 15), Vector2(0, 10), Vector2(-15, 15)
	])
	_player.color = Color(0.2, 0.8, 1.0)
	_game_area.add_child(_player)

	# Shield
	_shield = Polygon2D.new()
	var pts = []
	for i in range(32):
		var a = i * TAU / 32.0
		pts.append(Vector2(cos(a), sin(a)) * 30.0)
	_shield.polygon = PackedVector2Array(pts)
	_shield.color = Color(0.2, 1.0, 0.4, 0.3)
	_shield.visible = false
	_player.add_child(_shield)

func tick(delta: float) -> bool:
	if _finished: return true

	var size = _game_area.size
	var speed_mult = GameManager.speed_multiplier

	# ── Player Movement ──────────────────────────────────────────
	var move_dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):    move_dir.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):  move_dir.y += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):  move_dir.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): move_dir.x += 1
	if move_dir != Vector2.ZERO:
		move_dir = move_dir.normalized()
		_player.rotation = move_dir.angle() + PI/2.0
	
	_player_pos += move_dir * PLAYER_SPEED * delta
	_player_pos.x = clampf(_player_pos.x, 20, size.x - 20)
	_player_pos.y = clampf(_player_pos.y, 20, size.y - 20)
	_player.position = _player_pos

	# ── Shield (Q - Accept) ──────────────────────────────────────
	if _shield_timer > 0.0:
		_shield_timer -= delta
		_shield.visible = _shield_timer > 0.0
	elif Input.is_key_pressed(KEY_Q):
		_shield_timer = 1.0
		_shield.visible = true

	# ── Spawning ─────────────────────────────────────────────────
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = (_spawn_interval / speed_mult) * randf_range(0.8, 1.2)
		_spawn_enemy(size)

	# ── Transfer Drone (E) ───────────────────────────────────────
	if Input.is_action_just_pressed("interact") or Input.is_key_pressed(KEY_E):
		# Find nearest Liability (type 2)
		var best_e = null
		var best_d = 999999.0
		for e in _enemies:
			if e.active and e.type == 2:
				var d = _player_pos.distance_to(e.pos)
				if d < best_d:
					best_d = d
					best_e = e
		if best_e != null:
			_spawn_drone(_player_pos, best_e)

	# ── Mitigate Laser (SPACE) ───────────────────────────────────
	_laser.visible = false
	if Input.is_key_pressed(KEY_SPACE):
		var best_e = null
		var best_d = 999999.0
		for e in _enemies:
			if e.active and e.type == 1:
				var d = _player_pos.distance_to(e.pos)
				if d < best_d:
					best_d = d
					best_e = e
		if best_e != null:
			_laser.visible = true
			_laser.points = PackedVector2Array([_player_pos, best_e.pos])
			best_e.node.scale -= Vector2.ONE * delta * 1.2
			if best_e.node.scale.x <= 0.2:
				_score += 150
				_budget_delta += 1000
				JuiceManager.correct_sound()
				JuiceManager.spawn_floating_text(_game_area, best_e.pos, "MITIGATED! +150", Color(1.0, 0.8, 0.2))
				_kill_enemy(best_e)

	# ── Update Drones ────────────────────────────────────────────
	for d in _drones:
		if not d.active: continue
		if not d.target.active:
			d.active = false
			d.node.queue_free()
			continue
		var dir = (d.target.pos - d.pos).normalized()
		d.pos += dir * 800.0 * delta
		d.node.position = d.pos
		if d.pos.distance_to(d.target.pos) < 20.0:
			_score += 150
			_budget_delta += 1000
			JuiceManager.correct_sound()
			JuiceManager.spawn_floating_text(_game_area, d.target.pos, "TRANSFERRED! +150", Color(0.2, 0.6, 1.0))
			_kill_enemy(d.target)
			d.active = false
			d.node.queue_free()

	# ── Update Enemies ───────────────────────────────────────────
	var to_remove = []
	for e in _enemies:
		if not e.active:
			to_remove.append(e)
			continue
		
		e.pos += e.vel * delta * speed_mult
		e.node.position = e.pos

		# Off screen
		if e.pos.x < -50 or e.pos.x > size.x + 50 or e.pos.y < -50 or e.pos.y > size.y + 50:
			if e.type == 0:
				# Fatal flaw avoided successfully!
				_score += 100
				JuiceManager.spawn_floating_text(_game_area, e.pos, "AVOIDED!", Color(0.5, 1.0, 0.5))
			_kill_enemy(e)
			continue

		# Collision with player
		if e.pos.distance_to(_player_pos) < 30.0:
			if e.type == 3 and _shield_timer > 0.0:
				# Accepted safely!
				_score += 150
				JuiceManager.correct_sound()
				JuiceManager.spawn_floating_text(_game_area, e.pos, "ACCEPTED! +150", Color(0.2, 1.0, 0.4))
			else:
				# Hurt
				_score -= 100
				_budget_delta -= 3000
				JuiceManager.wrong_sound()
				JuiceManager.hit_stop_and_shake(0.6)
				JuiceManager.spawn_floating_text(_game_area, _player_pos, "HIT! -$3K", Color(1.0, 0.2, 0.2))
			_kill_enemy(e)

	for e in to_remove:
		_enemies.erase(e)

	_score_label.text = "Score: %d" % _score
	return false

func _spawn_enemy(size: Vector2) -> void:
	var side = randi() % 4
	var pos := Vector2.ZERO
	if side == 0: pos = Vector2(randf_range(0, size.x), -30)
	elif side == 1: pos = Vector2(size.x + 30, randf_range(0, size.y))
	elif side == 2: pos = Vector2(randf_range(0, size.x), size.y + 30)
	else: pos = Vector2(-30, randf_range(0, size.y))

	var dir = (_player_pos - pos).normalized()
	
	# Randomize type if possible
	var type = randi() % 4
	
	var node = ColorRect.new()
	node.size = Vector2(30, 30)
	
	var icon = Label.new()
	icon.add_theme_font_size_override("font_size", 20)
	icon.size = Vector2(30, 30)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	node.add_child(icon)

	if type == 0: # Fatal Flaw
		node.color = Color(1.0, 0.2, 0.2, 0.8)
		icon.text = "💀"
	elif type == 1: # Hazard
		node.color = Color(1.0, 0.6, 0.1, 0.8)
		icon.text = "🔥"
	elif type == 2: # Liability
		node.color = Color(0.2, 0.6, 1.0, 0.8)
		icon.text = "💼"
	elif type == 3: # Minor
		node.color = Color(0.2, 1.0, 0.4, 0.8)
		icon.text = "🐛"

	node.position = pos - Vector2(15, 15)
	_game_area.add_child(node)

	_enemies.append({
		"node": node,
		"type": type,
		"pos": pos,
		"vel": dir * randf_range(80, 140),
		"active": true
	})

func _spawn_drone(pos: Vector2, target: Dictionary) -> void:
	var node = ColorRect.new()
	node.size = Vector2(10, 10)
	node.color = Color(1.0, 1.0, 0.5)
	node.position = pos - Vector2(5, 5)
	_game_area.add_child(node)
	_drones.append({
		"node": node,
		"pos": pos,
		"target": target,
		"active": true
	})

func _kill_enemy(e: Dictionary) -> void:
	if is_instance_valid(e.node):
		e.node.queue_free()
	e.active = false

func get_result() -> Dictionary:
	return {
		"score": _score,
		"budget_delta": _budget_delta,
		"days_delta": _days_delta
	}
