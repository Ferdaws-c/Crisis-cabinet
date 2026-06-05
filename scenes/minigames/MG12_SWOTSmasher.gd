## MG12_SWOTSmasher.gd
## PMBOK: SWOT Analysis
## Mechanic: Whack-a-mole on a 3x3 cubicle grid.
##           Z = Smash Threats/Weaknesses | X = High-Five Strengths/Opportunities

extends Node

# ── Interface state ──────────────────────────────────────────────
var _game_area: Control
var _overlay: Node

var _score: int = 0
var _budget_delta: int = 0
var _days_delta: int = 0
var _finished: bool = false

# ── Character types ───────────────────────────────────────────────
const TYPES: Array = ["THREAT", "WEAKNESS", "STRENGTH", "OPPORTUNITY"]

const TYPE_META: Dictionary = {
	"THREAT":      {"emoji": "🔴", "color": Color(0.75, 0.15, 0.15), "key": "Z"},
	"WEAKNESS":    {"emoji": "🟡", "color": Color(0.85, 0.50, 0.05), "key": "Z"},
	"STRENGTH":    {"emoji": "🟢", "color": Color(0.10, 0.65, 0.20), "key": "X"},
	"OPPORTUNITY": {"emoji": "🔵", "color": Color(0.10, 0.55, 0.85), "key": "X"},
}

# ── Cubicle ───────────────────────────────────────────────────────
class Cubicle:
	var panel: ColorRect
	var char_label: Label   # emoji + type shown when active
	var life_timer: float = 0.0
	var life_max: float = 2.5
	var active: bool = false
	var char_type: String = ""
	var spawn_time: float = 0.0  # game time when this cubicle became active

const CUBICLE_SIZE  := Vector2(130, 110)
const CUBICLE_GAP   := 20

var _cubicles: Array = []
var _spawn_timer: float = 0.0
var _game_timer: float = 45.0

var _streak: int = 0
var _score_label: Label
var _streak_label: Label
var _time_label: Label

var _elapsed: float = 0.0   # used for oldest-active tracking

# Input guard
var _z_was_down: bool = false
var _x_was_down: bool = false

func start(game_area: Control, overlay: Node) -> void:
	_game_area = game_area
	_overlay = overlay
	var size: Vector2 = game_area.size
	var center: Vector2 = size * 0.5

	# Background
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.06, 0.10)
	bg.size = size
	game_area.add_child(bg)

	# Controls tip
	var title := Label.new()
	title.text = "⚡ SWOT SMASHER — [Z] Smash Threats/Weaknesses | [X] High-Five Strengths/Opportunities"
	title.add_theme_font_size_override("font_size", 16)
	title.modulate = Color(0.85, 0.9, 1.0)
	title.position = Vector2(center.x - 380, 8)
	game_area.add_child(title)

	# Legend
	var legend := Label.new()
	legend.text = "[Z] Smash = Threats 🔴 & Weaknesses 🟡   |   [X] High-Five = Strengths 🟢 & Opportunities 🔵"
	legend.add_theme_font_size_override("font_size", 14)
	legend.modulate = Color(0.85, 0.85, 1.0)
	legend.position = Vector2(center.x - 360, 38)
	game_area.add_child(legend)

	# Build 3x3 grid
	var grid_w: float = 3 * CUBICLE_SIZE.x + 2 * CUBICLE_GAP
	var grid_h: float = 3 * CUBICLE_SIZE.y + 2 * CUBICLE_GAP
	var grid_origin: Vector2 = Vector2(center.x - grid_w * 0.5, center.y - grid_h * 0.5 + 20)

	for row in range(3):
		for col in range(3):
			var pos: Vector2 = grid_origin + Vector2(
				col * (CUBICLE_SIZE.x + CUBICLE_GAP),
				row * (CUBICLE_SIZE.y + CUBICLE_GAP)
			)
			var c := Cubicle.new()

			# Panel (cubicle body)
			var panel := ColorRect.new()
			panel.size = CUBICLE_SIZE
			panel.position = pos
			panel.color = Color(0.18, 0.18, 0.24)
			game_area.add_child(panel)
			c.panel = panel

			# Panel border
			var panel_border := ReferenceRect.new()
			panel_border.editor_only = false
			panel_border.border_color = Color(0.35, 0.35, 0.45)
			panel_border.border_width = 2.0
			panel_border.set_anchors_preset(Control.PRESET_FULL_RECT)
			panel.add_child(panel_border)

			# Wall-texture lines (decorative)
			for li in range(2):
				var wall := ColorRect.new()
				wall.color = Color(0.25, 0.25, 0.32)
				wall.size = Vector2(CUBICLE_SIZE.x, 2)
				wall.position = Vector2(pos.x, pos.y + 30 + li * 30)
				game_area.add_child(wall)

			# Character label (centered in panel, hidden when idle)
			var lbl := Label.new()
			lbl.text = ""
			lbl.add_theme_font_size_override("font_size", 32)
			lbl.modulate = Color(1, 1, 1)
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			lbl.size = CUBICLE_SIZE - Vector2(8, 8)
			lbl.position = pos + Vector2(4, 4)
			lbl.visible = false
			game_area.add_child(lbl)
			c.char_label = lbl

			# Life-timer bar (shown below panel when active)
			var bar_bg := ColorRect.new()
			bar_bg.color = Color(0.15, 0.15, 0.15)
			bar_bg.size = Vector2(CUBICLE_SIZE.x, 5)
			bar_bg.position = Vector2(pos.x, pos.y + CUBICLE_SIZE.y + 2)
			bar_bg.visible = false
			game_area.add_child(bar_bg)
			panel.set_meta("bar_bg", bar_bg)

			var bar := ColorRect.new()
			bar.color = Color(0.9, 0.8, 0.1)
			bar.size = Vector2(CUBICLE_SIZE.x, 5)
			bar.position = bar_bg.position
			bar.visible = false
			game_area.add_child(bar)
			panel.set_meta("bar", bar)

			_cubicles.append(c)

	# Score label
	_score_label = Label.new()
	_score_label.text = "Score: 0"
	_score_label.add_theme_font_size_override("font_size", 18)
	_score_label.position = Vector2(10, 10)
	game_area.add_child(_score_label)

	# Streak label
	_streak_label = Label.new()
	_streak_label.text = "Streak: 0"
	_streak_label.add_theme_font_size_override("font_size", 16)
	_streak_label.modulate = Color(1, 1, 0.5)
	_streak_label.position = Vector2(10, 35)
	game_area.add_child(_streak_label)

	# Time label
	_time_label = Label.new()
	_time_label.text = "Time: 60s"
	_time_label.add_theme_font_size_override("font_size", 18)
	_time_label.modulate = Color(1, 0.9, 0.5)
	_time_label.position = Vector2(size.x - 130, 10)
	game_area.add_child(_time_label)

	_spawn_timer = 1.0

func _count_active() -> int:
	var n := 0
	for c in _cubicles:
		if c.active:
			n += 1
	return n

func _get_oldest_active() -> Cubicle:
	var oldest: Cubicle = null
	var oldest_time: float = 1e9
	for c in _cubicles:
		if c.active and c.spawn_time < oldest_time:
			oldest_time = c.spawn_time
			oldest = c
	return oldest

func _spawn_character() -> void:
	if _count_active() >= 3:
		return
	var idle_cubicles: Array = []
	for c in _cubicles:
		if not c.active:
			idle_cubicles.append(c)
	if idle_cubicles.is_empty():
		return

	var speed: float = GameManager.speed_multiplier
	var c: Cubicle = idle_cubicles[randi() % idle_cubicles.size()]
	c.char_type = TYPES[randi() % TYPES.size()]
	c.life_max = 2.5 / speed
	c.life_timer = c.life_max
	c.active = true
	c.spawn_time = _elapsed

	var meta: Dictionary = TYPE_META[c.char_type]
	c.panel.color = meta["color"].darkened(0.35)
	c.char_label.text = "%s\n%s" % [meta["emoji"], c.char_type]
	c.char_label.visible = true

	var bar_bg: ColorRect = c.panel.get_meta("bar_bg")
	var bar: ColorRect = c.panel.get_meta("bar")
	bar_bg.visible = true
	bar.visible = true
	bar.size = Vector2(CUBICLE_SIZE.x, 5)

func _deactivate(c: Cubicle) -> void:
	c.active = false
	c.char_type = ""
	c.panel.color = Color(0.18, 0.18, 0.24)
	c.char_label.visible = false
	var bar_bg: ColorRect = c.panel.get_meta("bar_bg")
	var bar: ColorRect = c.panel.get_meta("bar")
	bar_bg.visible = false
	bar.visible = false

func _process_input(key: String) -> void:
	# Applies to the OLDEST active cubicle only
	var target: Cubicle = _get_oldest_active()
	if target == null:
		return

	var meta: Dictionary = TYPE_META[target.char_type]
	var correct: bool = (meta["key"] == key)

	if correct:
		_score += 150
		_budget_delta += 1000
		_streak += 1
		JuiceManager.correct_sound()
		JuiceManager.spawn_floating_text(_game_area,
			target.panel.position + Vector2(CUBICLE_SIZE.x * 0.5, CUBICLE_SIZE.y * 0.5),
			"+150 pts +$1K", Color(0.4, 1.0, 0.4))
		if _streak >= 8 and _streak % 8 == 0:
			_score += 400
			JuiceManager.bonus_sound()
			JuiceManager.spawn_floating_text(_game_area,
				target.panel.position + Vector2(CUBICLE_SIZE.x * 0.5, 0),
				"8-STREAK! +400", Color(1, 1, 0))
	else:
		_score -= 200
		_budget_delta -= 5000
		_streak = 0
		JuiceManager.wrong_sound()
		JuiceManager.hit_stop_and_shake(0.6)
		JuiceManager.spawn_floating_text(_game_area,
			target.panel.position + Vector2(CUBICLE_SIZE.x * 0.5, CUBICLE_SIZE.y * 0.5),
			"WRONG! -200 -$5K", Color(1, 0.3, 0.3))

	_deactivate(target)

func tick(delta: float) -> bool:
	if _finished:
		return true

	_elapsed += delta
	var speed: float = GameManager.speed_multiplier

	_game_timer -= delta
	if _game_timer <= 0.0:
		_finished = true
		return true
	_time_label.text = "Time: %ds" % int(ceil(_game_timer))

	# Input (rising edge only)
	var z_down: bool = Input.is_key_pressed(KEY_Z)
	var x_down: bool = Input.is_key_pressed(KEY_X)

	if z_down and not _z_was_down:
		_process_input("Z")
	if x_down and not _x_was_down:
		_process_input("X")

	_z_was_down = z_down
	_x_was_down = x_down

	# Spawn
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = 1.2 / speed
		_spawn_character()

	# Update active cubicle timers
	for c in _cubicles:
		if not c.active:
			continue
		c.life_timer -= delta
		var ratio: float = clampf(c.life_timer / c.life_max, 0.0, 1.0)
		var bar: ColorRect = c.panel.get_meta("bar")
		bar.size = Vector2(CUBICLE_SIZE.x * ratio, 5)
		# Pulse panel alpha to signal urgency
		if ratio < 0.3:
			var pulse: float = 0.6 + 0.4 * sin(_elapsed * 12.0)
			c.panel.modulate.a = pulse
		else:
			c.panel.modulate.a = 1.0

		if c.life_timer <= 0.0:
			_score -= 50
			_days_delta -= 1
			_streak = 0
			JuiceManager.wrong_sound()
			JuiceManager.spawn_floating_text(_game_area,
				c.panel.position + Vector2(CUBICLE_SIZE.x * 0.5, CUBICLE_SIZE.y * 0.5),
				"TIMEOUT! -50 -1d", Color(1, 0.6, 0.2))
			_deactivate(c)

	_score_label.text = "Score: %d" % _score
	_streak_label.text = "Streak: %d" % _streak
	return _finished

func get_result() -> Dictionary:
	return {
		"score": _score,
		"budget_delta": _budget_delta,
		"days_delta": _days_delta,
	}
