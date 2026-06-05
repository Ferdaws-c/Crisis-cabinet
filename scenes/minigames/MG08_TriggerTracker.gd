## MG08_TriggerTracker.gd
## PMBOK: Risk Triggers & Early Warning Systems
## Mechanic: Random warning circles appear and fade. Sprint to defuse before explosion!

extends Node

# ── Interface state ──────────────────────────────────────────────
var _game_area: Control
var _overlay: Node

var _score: int = 0
var _budget_delta: int = 0
var _days_delta: int = 0
var _finished: bool = false

# ── Constants ────────────────────────────────────────────────────
const PLAYER_SPEED := 350.0
const SPRINT_MULT  := 1.8
const DEFUSE_TIME  := 1.0
const TRIGGER_LIFE := 5.0
const MAX_TRIGGERS := 4
const PLAYER_SIZE  := 28.0

# ── Trigger state ────────────────────────────────────────────────
# Each: {node: ColorRect, pos: Vector2, life: float, max_life: float,
#         defuse_progress: float, prog_bar: ColorRect, active: bool}
var _triggers: Array = []
var _spawn_timer: float = 2.0
var _spawn_interval: float = 2.5

# ── Player ───────────────────────────────────────────────────────
var _player: Polygon2D
var _player_pos: Vector2

# ── Stats ────────────────────────────────────────────────────────
var _defuse_streak: int = 0
var _game_timer: float = 45.0
var _score_label: Label
var _time_label: Label
var _streak_label: Label

func start(game_area: Control, overlay: Node) -> void:
	_game_area = game_area
	_overlay = overlay
	var size: Vector2 = game_area.size
	var center: Vector2 = size * 0.5

	# Background
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.04, 0.08)
	bg.size = size
	game_area.add_child(bg)

	# Grid lines for visual flair
	for i in range(1, 6):
		var vl := ColorRect.new()
		vl.color = Color(0.1, 0.15, 0.25, 0.3)
		vl.size = Vector2(1, size.y)
		vl.position = Vector2(size.x * i / 6.0, 0)
		game_area.add_child(vl)
		var hl := ColorRect.new()
		hl.color = Color(0.1, 0.15, 0.25, 0.3)
		hl.size = Vector2(size.x, 1)
		hl.position = Vector2(0, size.y * i / 6.0)
		game_area.add_child(hl)

	# Controls tip
	var ctrl := Label.new()
	ctrl.text = "CONTROLS: WASD = Move | SHIFT = Sprint | SPACE = Hold near ⚠ to Defuse"
	ctrl.add_theme_font_size_override("font_size", 14)
	ctrl.modulate = Color(0.6, 0.8, 1.0)
	ctrl.position = Vector2(center.x - 310, 8)
	game_area.add_child(ctrl)

	# Player — cyan triangle
	_player_pos = center
	_player = Polygon2D.new()
	_player.polygon = PackedVector2Array([
		Vector2(0, -PLAYER_SIZE * 0.6),
		Vector2(-PLAYER_SIZE * 0.45, PLAYER_SIZE * 0.4),
		Vector2(PLAYER_SIZE * 0.45, PLAYER_SIZE * 0.4),
	])
	_player.color = Color(0.1, 0.95, 1.0)
	_player.position = _player_pos
	game_area.add_child(_player)

	# Score label
	_score_label = Label.new()
	_score_label.text = "Score: 0"
	_score_label.add_theme_font_size_override("font_size", 18)
	_score_label.modulate = Color(0.5, 1.0, 0.5)
	_score_label.position = Vector2(10, 30)
	game_area.add_child(_score_label)

	# Timer label
	_time_label = Label.new()
	_time_label.text = "Time: 45s"
	_time_label.add_theme_font_size_override("font_size", 18)
	_time_label.modulate = Color(1, 0.9, 0.5)
	_time_label.position = Vector2(size.x - 130, 8)
	game_area.add_child(_time_label)

	# Streak label
	_streak_label = Label.new()
	_streak_label.text = "Streak: 0"
	_streak_label.add_theme_font_size_override("font_size", 16)
	_streak_label.modulate = Color(1, 1, 0.5)
	_streak_label.position = Vector2(10, 55)
	game_area.add_child(_streak_label)

func _count_active() -> int:
	var n := 0
	for t in _triggers:
		if t.active:
			n += 1
	return n

func _spawn_trigger() -> void:
	if _count_active() >= MAX_TRIGGERS:
		return
	var size: Vector2 = _game_area.size
	var px: float = randf_range(60, size.x - 60)
	var py: float = randf_range(60, size.y - 60)
	var pos := Vector2(px, py)

	# Circle body
	var node := ColorRect.new()
	node.color = Color(1.0, 0.3, 0.1, 0.85)
	node.size = Vector2(60, 60)
	node.position = pos - Vector2(30, 30)
	_game_area.add_child(node)

	# Border glow
	var border := ReferenceRect.new()
	border.editor_only = false
	border.border_color = Color(1.0, 0.6, 0.1)
	border.border_width = 3.0
	border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	node.add_child(border)

	# Warning icon
	var icon := Label.new()
	icon.text = "⚠"
	icon.add_theme_font_size_override("font_size", 28)
	icon.modulate = Color(1, 1, 0.3)
	icon.size = Vector2(60, 60)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	node.add_child(icon)

	# Defuse progress bar background
	var prog_bg := ColorRect.new()
	prog_bg.color = Color(0.15, 0.15, 0.15)
	prog_bg.size = Vector2(60, 8)
	prog_bg.position = Vector2(pos.x - 30, pos.y + 35)
	prog_bg.visible = false
	_game_area.add_child(prog_bg)

	# Defuse progress bar fill
	var prog := ColorRect.new()
	prog.color = Color(0.2, 1.0, 0.4)
	prog.size = Vector2(0, 8)
	prog.position = prog_bg.position
	prog.visible = false
	_game_area.add_child(prog)

	# Move player triangle to front
	_game_area.move_child(_player, _game_area.get_child_count() - 1)

	_triggers.append({
		"node": node,
		"pos": pos,
		"life": TRIGGER_LIFE,
		"max_life": TRIGGER_LIFE,
		"defuse_progress": 0.0,
		"prog_bar": prog,
		"prog_bg": prog_bg,
		"active": true,
	})

func tick(delta: float) -> bool:
	if _finished:
		return true

	_game_timer -= delta
	if _game_timer <= 0.0:
		_finished = true
		return true

	_time_label.text = "Time: %ds" % int(ceil(_game_timer))

	var size: Vector2 = _game_area.size

	# ── Movement ─────────────────────────────────────────────────
	var move_dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):    move_dir.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):  move_dir.y += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):  move_dir.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): move_dir.x += 1
	if move_dir != Vector2.ZERO:
		move_dir = move_dir.normalized()
	var spd := PLAYER_SPEED
	if Input.is_key_pressed(KEY_SHIFT):
		spd *= SPRINT_MULT
	_player_pos += move_dir * spd * delta
	_player_pos.x = clampf(_player_pos.x, 20, size.x - 20)
	_player_pos.y = clampf(_player_pos.y, 20, size.y - 20)
	_player.position = _player_pos

	# ── Spawn triggers ───────────────────────────────────────────
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = _spawn_interval
		_spawn_trigger()

	# ── Update triggers ──────────────────────────────────────────
	var space_held: bool = Input.is_key_pressed(KEY_SPACE)
	var to_remove: Array = []

	for t in _triggers:
		if not t.active:
			continue

		t.life -= delta

		# Fade alpha based on remaining life
		var ratio: float = clampf(t.life / t.max_life, 0.0, 1.0)
		t.node.modulate.a = 0.3 + 0.7 * ratio

		# Border color shifts to red as time runs out
		var border_node = t.node.get_child(0)
		if border_node is ReferenceRect:
			border_node.border_color = Color(1.0, ratio * 0.6, ratio * 0.1)

		# Check proximity for defuse
		var dist: float = _player_pos.distance_to(t.pos)
		if dist <= 50.0 and space_held:
			t.defuse_progress += delta
			t.prog_bar.visible = true
			t.prog_bg.visible = true
			t.prog_bar.size = Vector2(60.0 * clampf(t.defuse_progress / DEFUSE_TIME, 0, 1), 8)

			if t.defuse_progress >= DEFUSE_TIME:
				# Defused!
				_score += 200
				_budget_delta += 2000
				_defuse_streak += 1
				JuiceManager.correct_sound()
				JuiceManager.spawn_floating_text(_game_area, t.pos, "+200 pts +$2K", Color(0.2, 1, 0.4))

				if _defuse_streak >= 3 and _defuse_streak % 3 == 0:
					_score += 500
					JuiceManager.bonus_sound()
					JuiceManager.spawn_floating_text(_game_area, t.pos + Vector2(0, -40), "%d-STREAK! +500" % _defuse_streak, Color(1, 1, 0))

				# Escalate difficulty
				_spawn_interval = max(0.8, _spawn_interval * 0.9)

				_cleanup_trigger(t)
				to_remove.append(t)
				continue
		else:
			if dist > 50.0 or not space_held:
				t.defuse_progress = 0.0
				t.prog_bar.size = Vector2(0, 8)
				t.prog_bar.visible = false

		# Expired — EXPLOSION!
		if t.life <= 0.0:
			_budget_delta -= 8000
			_days_delta -= 3
			_defuse_streak = 0
			JuiceManager.wrong_sound()
			JuiceManager.hit_stop_and_shake(0.8)
			JuiceManager.spawn_floating_text(_game_area, t.pos, "EXPLOSION! -$8K -3d", Color(1, 0.2, 0.2))
			_cleanup_trigger(t)
			to_remove.append(t)

	for t in to_remove:
		_triggers.erase(t)

	# ── UI update ────────────────────────────────────────────────
	_score_label.text = "Score: %d" % _score
	_streak_label.text = "Streak: %d" % _defuse_streak

	return _finished

func _cleanup_trigger(t: Dictionary) -> void:
	if is_instance_valid(t.node):
		t.node.queue_free()
	if is_instance_valid(t.prog_bar):
		t.prog_bar.queue_free()
	if is_instance_valid(t.prog_bg):
		t.prog_bg.queue_free()
	t.active = false

func get_result() -> Dictionary:
	return {
		"score": _score,
		"budget_delta": _budget_delta,
		"days_delta": _days_delta,
	}
