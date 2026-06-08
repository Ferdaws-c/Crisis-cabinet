## MG10_AuditEscape.gd
## PMBOK: Risk Evaluation — Lessons Learned & Best Practices
## Mechanic: Endless runner — 4 horizontal lanes, dodge red obstacles, collect green pickups.

extends Node

# ── Interface state ──────────────────────────────────────────────
var _game_area: Control
var _overlay: Node

var _score: int = 0
var _budget_delta: int = 0
var _days_delta: int = 0
var _finished: bool = false

# ── Content ───────────────────────────────────────────────────────
const RED_TEXTS: Array = [
	"Poor Documentation", "Missed Deadline", "Scope Creep",
	"No Risk Register", "Poor Communication", "Ignored Feedback", "Underestimated Costs",
]
const GREEN_TEXTS: Array = [
	"Regular Audits", "Stakeholder Updates", "Change Log",
	"Lessons Learned Doc", "Post-Mortem Review", "Risk Register Kept", "Clear Deliverables",
]

# ── Runtime ───────────────────────────────────────────────────────
var _lane_y: Array = []
var _player_lane: int = 1      # 0, 1, 2, 3
var _player_node: ColorRect
var _player_x: float = 80.0

var _objects: Array = []       # {node: ColorRect, lane: int, is_red: bool}
var _spawn_timer: float = 0.0
var _game_timer: float = 60.0

var _green_streak: int = 0
var _score_label: Label
var _streak_label: Label
var _time_label: Label

var _lane_indicators: Array = []

# ── Dynamic speed ─────────────────────────────────────────────────
const SPEED_BASE: float = 1.0
const SPEED_MAX: float  = 2.2    # cap when collecting lots of greens
const SPEED_MIN: float  = 0.4    # floor when hitting lots of reds
const SPEED_UP: float   = 0.12   # boost per green collected
const SPEED_DOWN: float = 0.18   # penalty per red hit
var _current_speed: float = SPEED_BASE
var _speed_label: Label

# Input guard
var _w_was_down: bool = false
var _s_was_down: bool = false

func start(game_area: Control, overlay: Node) -> void:
	_game_area = game_area
	_overlay = overlay
	var size: Vector2 = game_area.size

	_lane_y = [size.y * 0.25, size.y * 0.45, size.y * 0.65, size.y * 0.85]

	# Background
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.09)
	bg.size = size
	game_area.add_child(bg)

	# Lane separators
	for i in range(1, 4):
		var sep := ColorRect.new()
		sep.color = Color(0.2, 0.2, 0.3, 0.5)
		sep.size = Vector2(size.x, 2)
		sep.position = Vector2(0, _lane_y[i] - (size.y * 0.1))
		game_area.add_child(sep)

	# Lane indicators (left side)
	for i in range(4):
		var ind := ColorRect.new()
		ind.size = Vector2(4, size.y * 0.2 - 4)
		ind.position = Vector2(10, _lane_y[i] - (size.y * 0.1) + 2)
		ind.color = Color(0.3, 0.3, 0.6)
		game_area.add_child(ind)
		_lane_indicators.append(ind)

	# Title
	var title := Label.new()
	title.text = "AUDIT ESCAPE — Dodge Mistakes, Collect Best Practices!"
	title.add_theme_font_size_override("font_size", 18)
	title.modulate = Color(0.9, 0.9, 1.0)
	title.position = Vector2(size.x * 0.5 - 280, 8)
	game_area.add_child(title)

	# Controls
	var ctrl := Label.new()
	ctrl.text = "W/S = Switch Lanes  |  A/D = Move Left/Right"
	ctrl.add_theme_font_size_override("font_size", 14)
	ctrl.modulate = Color(0.7, 0.9, 0.7)
	ctrl.position = Vector2(size.x * 0.5 - 120, 32)
	game_area.add_child(ctrl)

	# Player
	_player_node = ColorRect.new()
	_player_node.color = Color(0.2, 0.9, 1.0)
	_player_node.size = Vector2(50, 30)
	_player_node.position = Vector2(_player_x, _lane_y[_player_lane] - 15)
	game_area.add_child(_player_node)

	# Score label
	_score_label = Label.new()
	_score_label.text = "Score: 0"
	_score_label.add_theme_font_size_override("font_size", 18)
	_score_label.position = Vector2(10, 10)
	game_area.add_child(_score_label)

	# Streak label
	_streak_label = Label.new()
	_streak_label.text = "Green Streak: 0"
	_streak_label.add_theme_font_size_override("font_size", 15)
	_streak_label.modulate = Color(0.4, 1.0, 0.4)
	_streak_label.position = Vector2(10, 35)
	game_area.add_child(_streak_label)

	# Time label
	_time_label = Label.new()
	_time_label.text = "Time: 60s"
	_time_label.add_theme_font_size_override("font_size", 18)
	_time_label.modulate = Color(1, 0.9, 0.5)
	_time_label.position = Vector2(size.x - 130, 10)
	game_area.add_child(_time_label)

	_spawn_timer = 0.5

	# Speed meter label
	_speed_label = Label.new()
	_speed_label.text = "Speed: 1.0x"
	_speed_label.add_theme_font_size_override("font_size", 15)
	_speed_label.modulate = Color(1.0, 0.85, 0.3)
	_speed_label.position = Vector2(10, 58)
	game_area.add_child(_speed_label)

func _spawn_object() -> void:
	var size: Vector2 = _game_area.size
	var is_red: bool = randf() < 0.75
	var lane: int = randi() % 4

	var obj_node := ColorRect.new()
	obj_node.size = Vector2(80, 40)
	obj_node.color = Color(0.85, 0.2, 0.2) if is_red else Color(0.2, 0.8, 0.35)
	obj_node.position = Vector2(size.x + 50, _lane_y[lane] - 20)
	_game_area.add_child(obj_node)

	var texts: Array = RED_TEXTS if is_red else GREEN_TEXTS
	var lbl := RichTextLabel.new()
	lbl.bbcode_enabled = true
	lbl.text = "[center][b]" + texts[randi() % texts.size()] + "[/b][/center]"
	lbl.add_theme_font_size_override("normal_font_size", 13)
	lbl.add_theme_font_size_override("bold_font_size", 13)
	lbl.modulate = Color(1, 1, 1)
	lbl.position = Vector2(2, 2)
	lbl.size = Vector2(76, 36)
	lbl.fit_content = true
	lbl.scroll_active = false
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	obj_node.add_child(lbl)

	_objects.append({"node": obj_node, "lane": lane, "is_red": is_red})

func tick(delta: float) -> bool:
	if _finished:
		return true

	# Use dynamic speed driven by green/red collisions
	var speed: float = _current_speed
	var size: Vector2 = _game_area.size

	_game_timer -= delta
	if _game_timer <= 0.0:
		_finished = true
		return true
	_time_label.text = "Time: %ds" % int(ceil(_game_timer))

	# Lane switching — detect rising edge
	var w_down: bool = Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)
	var s_down: bool = Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)

	if w_down and not _w_was_down:
		_player_lane = max(0, _player_lane - 1)
	if s_down and not _s_was_down:
		_player_lane = min(3, _player_lane + 1)

	_w_was_down = w_down
	_s_was_down = s_down

	# Horizontal movement — scales with speed so you can always dodge
	var move_x = 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): move_x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): move_x += 1.0
	
	_player_x += move_x * 550.0 * speed * delta
	_player_x = clamp(_player_x, 20.0, size.x - 70.0)

	# Update player position
	_player_node.position = Vector2(_player_x, _lane_y[_player_lane] - 15)

	# Lane indicator colors
	for i in range(4):
		_lane_indicators[i].color = Color(0.3, 0.9, 1.0) if i == _player_lane else Color(0.3, 0.3, 0.6)

	# Spawn — interval shrinks as speed rises
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = 0.75 / speed
		_spawn_object()

	# Move and check objects
	var dead: Array = []
	for obj in _objects:
		var node: ColorRect = obj["node"]
		if not is_instance_valid(node):
			dead.append(obj)
			continue
		node.position.x -= 350.0 * speed * delta

		# Collision check
		var obj_center_x: float = node.position.x + 40
		var in_x: bool = abs(obj_center_x - (_player_x + 25)) <= 30
		var in_lane: bool = obj["lane"] == _player_lane

		if in_x and in_lane:
			if obj["is_red"]:
				_score -= 100
				_budget_delta -= 4000
				_green_streak = 0
				# RED hit — slow down
				_current_speed = clamp(_current_speed - SPEED_DOWN, SPEED_MIN, SPEED_MAX)
				JuiceManager.wrong_sound()
				JuiceManager.hit_stop_and_shake(0.5)
				JuiceManager.spawn_floating_text(_game_area, node.position, "-100 pts -$4K 🐢", Color(1, 0.3, 0.3))
			else:
				_score += 150
				_budget_delta += 2000
				_green_streak += 1
				# GREEN collect — speed up
				_current_speed = clamp(_current_speed + SPEED_UP, SPEED_MIN, SPEED_MAX)
				JuiceManager.correct_sound()
				JuiceManager.spawn_floating_text(_game_area, node.position, "+150 pts +$2K ⚡", Color(0.4, 1.0, 0.4))
				if _green_streak >= 5 and _green_streak % 5 == 0:
					_score += 300
					JuiceManager.bonus_sound()
					JuiceManager.spawn_floating_text(_game_area, node.position + Vector2(0, -40), "5-STREAK! +300", Color(1, 1, 0))
			dead.append(obj)
			node.queue_free()
			continue

		# Fell off left side
		if node.position.x < -100:
			dead.append(obj)
			node.queue_free()

	for o in dead:
		_objects.erase(o)

	# Update speed label with color feedback
	_speed_label.text = "Speed: %.1fx" % _current_speed
	if _current_speed > 1.2:
		_speed_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))   # green = fast
	elif _current_speed < 0.85:
		_speed_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.3))   # red = slow
	else:
		_speed_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))  # yellow = normal

	_score_label.text = "Score: %d" % _score
	_streak_label.text = "Green Streak: %d" % _green_streak
	return _finished


func get_result() -> Dictionary:
	return {
		"score": _score,
		"budget_delta": _budget_delta,
		"days_delta": _days_delta,
	}
