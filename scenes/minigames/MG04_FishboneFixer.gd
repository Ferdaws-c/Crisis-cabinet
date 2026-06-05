## MG04_FishboneFixer.gd
## PMBOK: Ishikawa / Cause & Effect Diagrams
## Mechanic: Move with WASD and press SPACE near sparks to extinguish them before they reach the center.

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

# ── Sparks ────────────────────────────────────────────────────────────────────
# Each spark dict: {node: ColorRect, pos: Vector2, active: bool, bone_tip_index: int}
var _sparks: Array = []
var _spawn_timer: float = 0.0
var _spawn_interval: float = 3.5

# ── Core ──────────────────────────────────────────────────────────────────────
var _core: ColorRect
var _hp_label: Label
var core_hp: int = 5
var _combo: int = 0
var _center: Vector2

# ── Bone tip positions (populated in start) ────────────────────────────────────
var _bone_tips: Array = []

# ── UI ────────────────────────────────────────────────────────────────────────
var _score_label: Label
var _budget_label: Label

# ── Constants ─────────────────────────────────────────────────────────────────
const PLAYER_SPEED: float = 350.0
const SPARK_SPEED_BASE: float = 120.0
const SPARK_SIZE: float = 40.0
const PLAYER_SIZE: float = 40.0
const MAX_SPARKS: int = 5
const EXTINGUISH_RANGE: float = 50.0
const CENTER_HIT_RANGE: float = 30.0

# Bone label names
const BONE_LABELS: Array = [
	"Scope\nCreep",
	"Resource\nGaps",
	"Tech\nDebt",
	"Comms\nFail",
	"Budget\nOver",
	"Schedule\nSlip"
]


# ─────────────────────────────────────────────────────────────────────────────
func start(game_area: Control, overlay: Node) -> void:
	_game_area = game_area
	_overlay = overlay

	var size = game_area.size
	_center = Vector2(size.x / 2.0, size.y / 2.0)

	# Background
	var bg = ColorRect.new()
	bg.color = Color(0.04, 0.04, 0.08)
	bg.size = size
	bg.position = Vector2.ZERO
	game_area.add_child(bg)

	# ── Draw fishbone ─────────────────────────────────────────────────────
	_draw_fishbone(size)

	# ── Core (Project Failure node) ───────────────────────────────────────
	_core = ColorRect.new()
	_core.color = Color(0.8, 0.15, 0.15)
	_core.size = Vector2(40, 40)
	_core.position = _center - Vector2(20, 20)
	game_area.add_child(_core)

	var core_lbl = Label.new()
	core_lbl.text = "FAIL"
	core_lbl.add_theme_font_size_override("font_size", 13)
	core_lbl.modulate = Color(1, 1, 1)
	core_lbl.size = Vector2(40, 40)
	core_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	core_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_core.add_child(core_lbl)

	# HP label above core
	_hp_label = Label.new()
	_hp_label.add_theme_font_size_override("font_size", 24)
	_hp_label.modulate = Color(1.0, 0.3, 0.3)
	_hp_label.text = "❤ 5"
	_hp_label.position = _center + Vector2(-25, -65)
	game_area.add_child(_hp_label)

	# ── Player ────────────────────────────────────────────────────────────
	_player_pos = _center + Vector2(0, 50)
	_player = ColorRect.new()
	_player.color = Color(0.3, 0.5, 1.0)
	_player.size = Vector2(PLAYER_SIZE, PLAYER_SIZE)
	_player.position = _player_pos - Vector2(PLAYER_SIZE / 2.0, PLAYER_SIZE / 2.0)
	game_area.add_child(_player)

	var p_lbl = Label.new()
	p_lbl.text = "👷"
	p_lbl.add_theme_font_size_override("font_size", 20)
	p_lbl.size = Vector2(PLAYER_SIZE, PLAYER_SIZE)
	p_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_player.add_child(p_lbl)

	# ── Score / Budget ────────────────────────────────────────────────────
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
	controls_tip.text = "CONTROLS: WASD = Move | SPACE = Extinguish near sparks"
	controls_tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls_tip.size = Vector2(size.x, 30)
	controls_tip.position = Vector2(0, 5)
	game_area.add_child(controls_tip)

	_spawn_interval = 2.0 / GameManager.speed_multiplier
	_spawn_timer = 1.0


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

	# ── SPACE to extinguish ───────────────────────────────────────────────
	if Input.is_action_just_pressed("interact"):
		for spark in _sparks:
			if spark.active and _player_pos.distance_to(spark.pos) < EXTINGUISH_RANGE:
				_extinguish_spark(spark)
				break  # extinguish one at a time

	# ── Spawn timer ───────────────────────────────────────────────────────
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = 2.0 / speed_mult
		if _active_spark_count() < MAX_SPARKS:
			_spawn_spark()

	# ── Move sparks ───────────────────────────────────────────────────────
	var to_remove: Array = []
	for spark in _sparks:
		if not spark.active:
			continue
		var dir = (_center - spark.pos).normalized()
		spark.pos += dir * SPARK_SPEED_BASE * speed_mult * delta
		spark.node.position = spark.pos - Vector2(SPARK_SIZE / 2.0, SPARK_SIZE / 2.0)

		# Check if reached center
		if spark.pos.distance_to(_center) < CENTER_HIT_RANGE:
			core_hp -= 1
			budget_delta -= 5000
			_combo = 0
			JuiceManager.wrong_sound()
			JuiceManager.hit_stop_and_shake(0.6)
			JuiceManager.spawn_floating_text(_game_area, _center + Vector2(-40, -40), "-$5,000", Color(1, 0.2, 0.2))
			spark.node.queue_free()
			spark.active = false
			to_remove.append(spark)
			_hp_label.text = "❤ %d" % core_hp

			if core_hp <= 0:
				budget_delta -= 15000
				JuiceManager.spawn_floating_text(_game_area, _center, "CORE DESTROYED! -$15K", Color(1, 0, 0))
				_done = true
				return true

	for s in to_remove:
		_sparks.erase(s)

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
func _draw_fishbone(size: Vector2) -> void:
	# Main spine
	var spine = ColorRect.new()
	spine.color = Color(0.7, 0.7, 0.5)
	spine.size = Vector2(size.x * 0.7, 4)
	spine.position = Vector2(size.x * 0.15, _center.y - 2)
	_game_area.add_child(spine)

	# Arrow head at right
	var arrow = Label.new()
	arrow.text = "▶"
	arrow.add_theme_font_size_override("font_size", 28)
	arrow.modulate = Color(0.8, 0.2, 0.2)
	arrow.position = _center + Vector2(15, -18)
	_game_area.add_child(arrow)

	# Bone tip offsets from center
	var offsets: Array = [
		Vector2(-280, -130),  # Left top
		Vector2(-80, -130),   # Middle top
		Vector2(120, -130),   # Right top
		Vector2(-280, 130),   # Left bottom
		Vector2(-80, 130),    # Middle bottom
		Vector2(120, 130),    # Right bottom
	]

	_bone_tips.clear()

	for i in range(offsets.size()):
		var tip_pos = _center + offsets[i]
		_bone_tips.append(tip_pos)

		# Connection point on spine
		var spine_x = tip_pos.x
		var spine_pos = Vector2(spine_x, _center.y)

		# Draw diagonal bone (a thin rotated rect using a Line2D workaround via two ColorRects)
		var bone = ColorRect.new()
		bone.color = Color(0.6, 0.6, 0.4, 0.8)
		var diff = spine_pos - tip_pos
		var length = diff.length()
		bone.size = Vector2(length, 3)
		bone.position = tip_pos
		bone.pivot_offset = Vector2.ZERO
		bone.rotation = diff.angle()
		_game_area.add_child(bone)

		# Tip circle
		var tip_dot = ColorRect.new()
		tip_dot.color = Color(1.0, 0.6, 0.1)
		tip_dot.size = Vector2(12, 12)
		tip_dot.position = tip_pos - Vector2(6, 6)
		_game_area.add_child(tip_dot)

		# Bone label
		var lbl = Label.new()
		lbl.text = BONE_LABELS[i]
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.modulate = Color(0.9, 0.9, 0.7)
		var lbl_offset = Vector2(-30, -50) if offsets[i].y < 0 else Vector2(-30, 10)
		lbl.position = tip_pos + lbl_offset
		_game_area.add_child(lbl)


# ─────────────────────────────────────────────────────────────────────────────
func _spawn_spark() -> void:
	var tip_index = randi_range(0, _bone_tips.size() - 1)
	var tip_pos = _bone_tips[tip_index]

	var node = ColorRect.new()
	node.color = Color(1.0, 0.3, 0.1)
	node.size = Vector2(SPARK_SIZE, SPARK_SIZE)
	node.position = tip_pos - Vector2(SPARK_SIZE / 2.0, SPARK_SIZE / 2.0)
	_game_area.add_child(node)

	# Spark glow label
	var lbl = Label.new()
	lbl.text = "✦"
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.modulate = Color(1.0, 0.8, 0.2)
	lbl.size = Vector2(SPARK_SIZE, SPARK_SIZE)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	node.add_child(lbl)

	_sparks.append({
		"node": node,
		"pos": tip_pos,
		"active": true,
		"bone_tip_index": tip_index
	})


# ─────────────────────────────────────────────────────────────────────────────
func _extinguish_spark(spark: Dictionary) -> void:
	_combo += 1
	var combo_mult = 1 + _combo / 3
	score += 150 * combo_mult
	budget_delta += 2000
	JuiceManager.correct_sound()
	JuiceManager.hit_stop_and_shake(0.2)
	var combo_text = "EXTINGUISHED! +$2,000"
	if _combo > 1:
		combo_text = "EXTINGUISHED! x%d COMBO +$2,000" % _combo
	JuiceManager.spawn_floating_text(_game_area, spark.pos + Vector2(-20, -25), combo_text, Color(0.3, 1.0, 1.0))
	spark.node.queue_free()
	spark.active = false
	_sparks.erase(spark)
	_score_label.text = "Score: %d" % score


# ─────────────────────────────────────────────────────────────────────────────
func _active_spark_count() -> int:
	var count = 0
	for s in _sparks:
		if s.active:
			count += 1
	return count
