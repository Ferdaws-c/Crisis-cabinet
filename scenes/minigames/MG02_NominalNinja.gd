## MG02_NominalNinja.gd
## PMBOK: Nominal Group Technique
## Mechanic: Catch numbered blocks (1-5) in order with a basket using A/D keys.

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
var _player_x: float = 0.0
var _player_y: float = 0.0

# ── Block tracking ────────────────────────────────────────────────────────────
var current_target: int = 1
var _initial_target: int = 1
var blocks: Array = []
# Each block dict: {node: ColorRect, stars: int, vel_y: float, x: float, y: float, active: bool, bouncing: bool}

# ── Spawn timer ───────────────────────────────────────────────────────────────
var _spawn_timer: float = 0.0
var _spawn_interval: float = 1.0

# ── UI labels ─────────────────────────────────────────────────────────────────
var _catch_label: Label
var _caught_label: Label
var _score_label: Label

# ── Constants ─────────────────────────────────────────────────────────────────
const IDEAS: Array = [
	{ "text": "Hire Expert", "stars": 5 },
	{ "text": "Update Firewall", "stars": 5 },
	{ "text": "Daily Backups", "stars": 4 },
	{ "text": "Cloud Migration", "stars": 4 },
	{ "text": "Code Review", "stars": 3 },
	{ "text": "Team Lunch", "stars": 3 },
	{ "text": "New Logo", "stars": 2 },
	{ "text": "Ignore Warnings", "stars": 1 },
	{ "text": "Skip Testing", "stars": 1 }
]

const PLAYER_SPEED_BASE: float = 900.0
const BLOCK_FALL_BASE: float = 280.0
const BLOCK_W: float = 180.0
const BLOCK_H: float = 45.0
const PLAYER_W: float = 160.0
const PLAYER_H: float = 20.0
const MAX_BLOCKS: int = 6


# ─────────────────────────────────────────────────────────────────────────────
func start(game_area: Control, overlay: Node) -> void:
	_game_area = game_area
	_overlay = overlay

	current_target = 5
	_initial_target = current_target

	var size = game_area.size

	# Background
	var bg = ColorRect.new()
	bg.color = Color(0.06, 0.06, 0.12)
	bg.size = size
	bg.position = Vector2.ZERO
	game_area.add_child(bg)

	# Player basket
	_player_x = size.x / 2.0
	_player_y = size.y * 0.85
	_player = ColorRect.new()
	_player.color = Color(0.4, 0.6, 1.0)
	_player.size = Vector2(PLAYER_W, PLAYER_H)
	_player.position = Vector2(_player_x - PLAYER_W / 2.0, _player_y - PLAYER_H / 2.0)
	game_area.add_child(_player)

	# Floor line (visual)
	var floor_line = ColorRect.new()
	floor_line.color = Color(0.3, 0.3, 0.4)
	floor_line.size = Vector2(size.x, 4)
	floor_line.position = Vector2(0, size.y * 0.9)
	game_area.add_child(floor_line)

	# CATCH label
	_catch_label = Label.new()
	_catch_label.add_theme_font_size_override("font_size", 32)
	_catch_label.modulate = Color(1.0, 1.0, 0.3)
	_catch_label.text = "CATCH: " + "⭐".repeat(current_target)
	_catch_label.position = Vector2(20, 20)
	game_area.add_child(_catch_label)

	# Caught counter
	_caught_label = Label.new()
	_caught_label.add_theme_font_size_override("font_size", 22)
	_caught_label.modulate = Color(0.8, 0.9, 1.0)
	_caught_label.text = "Caught: 0 / %d" % current_target
	_caught_label.position = Vector2(20, 60)
	game_area.add_child(_caught_label)

	# Score label
	_score_label = Label.new()
	_score_label.add_theme_font_size_override("font_size", 22)
	_score_label.modulate = Color(0.5, 1.0, 0.5)
	_score_label.text = "Score: 0"
	_score_label.position = Vector2(20, 90)
	game_area.add_child(_score_label)

	# Title / instructions
	var title = Label.new()
	title.add_theme_font_size_override("font_size", 18)
	title.modulate = Color(0.7, 0.7, 0.8)
	title.text = "Catch Community Ideas IN ORDER (5⭐ down to 1⭐)   A / D to move"
	title.position = Vector2(size.x / 2.0 - 280, 10)
	game_area.add_child(title)

	# Controls tip
	var controls_tip = Label.new()
	controls_tip.add_theme_font_size_override("font_size", 14)
	controls_tip.modulate = Color(0.6, 0.8, 1.0)
	controls_tip.text = "CONTROLS: ← A / D → to move basket"
	controls_tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls_tip.size = Vector2(size.x, 20)
	controls_tip.position = Vector2(0, 0)
	game_area.add_child(controls_tip)

	_spawn_interval = 1.0 / GameManager.speed_multiplier
	_spawn_timer = _spawn_interval  # spawn immediately on first tick


# ─────────────────────────────────────────────────────────────────────────────
func tick(delta: float) -> bool:
	if _done:
		return true

	var size = _game_area.size
	var speed_mult = GameManager.speed_multiplier
	var floor_y = size.y * 0.9

	# ── Player movement ───────────────────────────────────────────────────
	var player_speed = PLAYER_SPEED_BASE * speed_mult
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		_player_x -= player_speed * delta
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		_player_x += player_speed * delta
	_player_x = clamp(_player_x, PLAYER_W / 2.0, size.x - PLAYER_W / 2.0)
	_player.position = Vector2(_player_x - PLAYER_W / 2.0, _player_y - PLAYER_H / 2.0)

	# ── Spawn timer ───────────────────────────────────────────────────────
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = 1.0 / speed_mult
		if blocks.size() < MAX_BLOCKS and current_target >= 1:
			_spawn_block(size)

	# ── Update blocks ─────────────────────────────────────────────────────
	var to_remove: Array = []
	for b in blocks:
		if not b.active:
			continue

		b.vel_y += 0.0  # constant velocity
		b.y += b.vel_y * delta
		b.node.position = Vector2(b.x - BLOCK_W / 2.0, b.y - BLOCK_H / 2.0)

		# ── Floor check ───────────────────────────────────────────────────
		if b.y > floor_y:
			# Only penalize if it was a block we needed!
			if b.stars >= current_target:
				score -= 50
				budget_delta -= 1000
				JuiceManager.wrong_sound()
				JuiceManager.spawn_floating_text(_game_area, Vector2(b.x, floor_y - 30), "MISSED IDEA! -$1,000", Color(1, 0.3, 0.3))
			b.node.queue_free()
			b.active = false
			to_remove.append(b)
			continue

		# ── Bounce ceiling ────────────────────────────────────────────────
		if b.bouncing and b.y < 0:
			b.node.queue_free()
			b.active = false
			to_remove.append(b)
			continue

		# ── Collision with player ─────────────────────────────────────────
		var in_x = abs(b.x - _player_x) < (PLAYER_W / 2.0 + BLOCK_W / 2.0) * 0.8
		var in_y = b.y > _player_y - 20.0 and b.y < _player_y + 20.0
		if in_x and in_y and not b.bouncing:
			if b.stars == current_target:
				# Correct catch!
				score += 150
				JuiceManager.correct_sound()
				JuiceManager.spawn_floating_text(_game_area, Vector2(b.x, _player_y - 30), "+150", Color(0.3, 1.0, 0.3))
				b.node.queue_free()
				b.active = false
				to_remove.append(b)
				current_target -= 1
				if current_target < 1:
					score += 500
					days_delta += 5
					JuiceManager.bonus_sound()
					JuiceManager.spawn_floating_text(_game_area, Vector2(size.x / 2.0, size.y / 2.0), "COMBO COMPLETE!\n+500 BONUS!", Color(1.0, 0.9, 0.2))
					current_target = 5
				_refresh_ui()
			else:
				# Wrong order — bounce it away
				score -= 75
				days_delta -= 2
				b.vel_y = -200.0 * speed_mult
				b.bouncing = true
				JuiceManager.wrong_sound()
				JuiceManager.hit_stop_and_shake(0.4)
				JuiceManager.spawn_floating_text(_game_area, Vector2(b.x, _player_y - 30), "WRONG PRIORITY!", Color(1, 0.3, 0.1))

	for b in to_remove:
		blocks.erase(b)

	_score_label.text = "Score: %d" % score
	return false


# ─────────────────────────────────────────────────────────────────────────────
func get_result() -> Dictionary:
	return {
		"score": score,
		"budget_delta": budget_delta,
		"days_delta": days_delta
	}


# ─────────────────────────────────────────────────────────────────────────────
func _spawn_block(size: Vector2) -> void:
	var speed_mult = GameManager.speed_multiplier
	
	# Pick an idea: it should be at or below the current target star rating.
	var possible_ideas = []
	for idea in IDEAS:
		if idea["stars"] <= current_target + 1 and idea["stars"] >= max(1, current_target - 1):
			possible_ideas.append(idea)
			
	var chosen_idea = possible_ideas[randi() % possible_ideas.size()]
	var stars = chosen_idea["stars"]

	var x = randf_range(BLOCK_W / 2.0 + 10, size.x - BLOCK_W / 2.0 - 10)

	var node = ColorRect.new()
	node.color = Color(0.2, 0.2, 0.2, 0.9) # Dark grey background
	node.size = Vector2(BLOCK_W, BLOCK_H)
	node.position = Vector2(x - BLOCK_W / 2.0, -BLOCK_H)
	
	# Add a border based on stars
	var border = ReferenceRect.new()
	border.editor_only = false
	border.border_color = Color(1.0, 0.8, 0.2) if stars >= 4 else (Color(0.8, 0.8, 0.8) if stars >= 2 else Color(0.8, 0.4, 0.2))
	border.border_width = 2.0
	border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	node.add_child(border)
	
	_game_area.add_child(node)

	var lbl = Label.new()
	lbl.text = "%s\n%s" % [chosen_idea["text"], "⭐".repeat(stars)]
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.modulate = Color(1, 1, 1)
	lbl.size = Vector2(BLOCK_W, BLOCK_H)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	node.add_child(lbl)

	var b = {
		"node": node,
		"stars": stars,
		"vel_y": BLOCK_FALL_BASE * speed_mult,
		"x": x,
		"y": -BLOCK_H / 2.0,
		"active": true,
		"bouncing": false
	}
	blocks.append(b)


# ─────────────────────────────────────────────────────────────────────────────
func _refresh_ui() -> void:
	if current_target >= 1:
		_catch_label.text = "CATCH: " + "⭐".repeat(current_target)
	else:
		_catch_label.text = "ALL RANKED!"
	_caught_label.text = "Caught: Endless"
