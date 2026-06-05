extends Node
## MG01 — Framework Frenzy
## PMBOK: IT Risk Identification Framework
## Mechanic: Cards fall — press LEFT (Internal) or RIGHT (External)

const CARDS: Array = [
	{"text": "Staff Turnover",          "internal": true},
	{"text": "New EU Regulation",       "internal": false},
	{"text": "Legacy Tech Debt",        "internal": true},
	{"text": "Market Downturn",         "internal": false},
	{"text": "Vendor Bankruptcy",       "internal": false},
	{"text": "Team Skill Gap",          "internal": true},
	{"text": "Cybersecurity Breach",    "internal": true},
	{"text": "Currency Fluctuation",    "internal": false},
	{"text": "Budget Cut",              "internal": true},
	{"text": "New Competitor Launch",   "internal": false},
	{"text": "Power Outage",            "internal": false},
	{"text": "Poor Requirements",       "internal": true},
	{"text": "Data Privacy Law",        "internal": false},
	{"text": "Scope Creep",             "internal": true},
	{"text": "Supply Chain Delay",      "internal": false},
	{"text": "Developer Burnout",       "internal": true},
	{"text": "Economic Recession",      "internal": false},
	{"text": "Server Hardware Failure", "internal": true},
	{"text": "Political Instability",   "internal": false},
	{"text": "Knowledge Silos",         "internal": true},
]

var _overlay: Node
var _game_area: Control
var _cards: Array = []
var _card_index: int = 0
var _card_timer: float = 0.0
var _card_lifetime: float = 4.0
var _score: int = 0
var _budget_delta: int = 0
var _days_delta: int = 0
var _done: bool = false
var _answered: bool = false
var _input_locked: bool = false
var _delay_timer: float = 0.0

# UI nodes
var _card_label: Label
var _timer_fill: ColorRect
var _timer_bg: ColorRect
var _feedback_label: Label
var _feedback_timer: float = 0.0
var _correct_count: int = 0
var _total_count: int = 0

func start(game_area: Control, overlay: Node) -> void:
	_game_area = game_area
	_overlay = overlay
	_cards = CARDS.duplicate()
	_cards.shuffle()
	_card_index = 0
	_card_lifetime = 4.0 / GameManager.speed_multiplier
	_build_ui()
	_load_card()

func _build_ui() -> void:
	var size = _game_area.get_viewport_rect().size
	var center = size / 2.0

	# Background
	var bg = ColorRect.new()
	bg.color = Color(0.04, 0.04, 0.1)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_game_area.add_child(bg)

	# Phase label
	var phase_info = Label.new()
	phase_info.text = "Sort each risk: is it INTERNAL or EXTERNAL?"
	phase_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	phase_info.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	phase_info.set_offset(SIDE_TOP, 10)
	phase_info.add_theme_font_size_override("font_size", 14)
	phase_info.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	_game_area.add_child(phase_info)

	# Card container
	var card_bg = PanelContainer.new()
	card_bg.position = center - Vector2(250, 80)
	card_bg.custom_minimum_size = Vector2(500, 160)
	var cs = StyleBoxFlat.new()
	cs.bg_color = Color(0.1, 0.12, 0.22)
	for side in ["border_width_left","border_width_right","border_width_top","border_width_bottom"]: cs.set(side, 2)
	cs.border_color = Color(0.4, 0.6, 1.0)
	for c in ["corner_radius_top_left","corner_radius_top_right","corner_radius_bottom_left","corner_radius_bottom_right"]: cs.set(c, 12)
	card_bg.add_theme_stylebox_override("panel", cs)
	_game_area.add_child(card_bg)

	_card_label = Label.new()
	_card_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_card_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_card_label.add_theme_font_size_override("font_size", 28)
	_card_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_card_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_bg.add_child(_card_label)

	# Timer bar (shrinks over time)
	_timer_bg = ColorRect.new()
	_timer_bg.color = Color(0.2, 0.2, 0.2)
	_timer_bg.position = Vector2(center.x - 250, center.y + 100)
	_timer_bg.size = Vector2(500, 16)
	_game_area.add_child(_timer_bg)

	_timer_fill = ColorRect.new()
	_timer_fill.color = Color(0.3, 0.9, 0.3)
	_timer_fill.position = _timer_bg.position
	_timer_fill.size = Vector2(500, 16)
	_game_area.add_child(_timer_fill)

	# Buttons
	var btn_hbox = HBoxContainer.new()
	btn_hbox.add_theme_constant_override("separation", 40)
	btn_hbox.position = Vector2(center.x - 300, center.y + 140)
	btn_hbox.custom_minimum_size = Vector2(600, 70)
	_game_area.add_child(btn_hbox)

	var left_btn = Button.new()
	left_btn.text = "◀  INTERNAL\n(Tech, People, Process)"
	left_btn.custom_minimum_size = Vector2(280, 70)
	var ls = StyleBoxFlat.new()
	ls.bg_color = Color(0.1, 0.3, 0.7)
	for c in ["corner_radius_top_left","corner_radius_top_right","corner_radius_bottom_left","corner_radius_bottom_right"]: ls.set(c, 10)
	left_btn.add_theme_stylebox_override("normal", ls)
	left_btn.add_theme_font_size_override("font_size", 16)
	left_btn.pressed.connect(func(): _check_answer(true))
	btn_hbox.add_child(left_btn)

	var right_btn = Button.new()
	right_btn.text = "EXTERNAL  ▶\n(Legal, Market, Political)"
	right_btn.custom_minimum_size = Vector2(280, 70)
	var rs = StyleBoxFlat.new()
	rs.bg_color = Color(0.6, 0.2, 0.1)
	for c in ["corner_radius_top_left","corner_radius_top_right","corner_radius_bottom_left","corner_radius_bottom_right"]: rs.set(c, 10)
	right_btn.add_theme_stylebox_override("normal", rs)
	right_btn.add_theme_font_size_override("font_size", 16)
	right_btn.pressed.connect(func(): _check_answer(false))
	btn_hbox.add_child(right_btn)

	# Feedback
	_feedback_label = Label.new()
	_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback_label.add_theme_font_size_override("font_size", 20)
	_feedback_label.position = Vector2(center.x - 200, center.y - 160)
	_feedback_label.custom_minimum_size = Vector2(400, 40)
	_feedback_label.modulate.a = 0.0
	_game_area.add_child(_feedback_label)

	# Progress counter
	var progress_label = Label.new()
	progress_label.name = "ProgressLabel"
	progress_label.add_theme_font_size_override("font_size", 14)
	progress_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	progress_label.position = Vector2(center.x - 100, 40)
	progress_label.custom_minimum_size = Vector2(200, 30)
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_game_area.add_child(progress_label)
	progress_label.set_meta("ref", true)

func _load_card() -> void:
	if _card_index >= _cards.size():
		_done = true
		return
	_card_label.text = _cards[_card_index]["text"]
	_card_timer = 0.0
	_answered = false
	_input_locked = false
	_card_lifetime = max(1.5, 4.0 / GameManager.speed_multiplier)
	# Update progress
	var pl = _game_area.find_child("ProgressLabel", true, false)
	if pl: pl.text = "Card %d / %d" % [_card_index + 1, _cards.size()]

func _check_answer(player_said_internal: bool) -> void:
	if _input_locked or _done: return
	_input_locked = true
	_total_count += 1
	var is_correct: bool = _cards[_card_index]["internal"] == player_said_internal
	if is_correct:
		_score += 100
		_budget_delta += 2000
		_correct_count += 1
		_feedback_label.text = "✔ CORRECT! +100 pts / +$2,000"
		_feedback_label.add_theme_color_override("font_color", Color.GREEN)
		JuiceManager.correct_sound()
	else:
		_score -= 50
		_budget_delta -= 3000
		_feedback_label.text = "✘ WRONG! -50 pts / -$3,000"
		_feedback_label.add_theme_color_override("font_color", Color.RED)
		JuiceManager.wrong_sound()
		JuiceManager.hit_stop_and_shake(5.0)
	_feedback_label.modulate.a = 1.0
	_feedback_timer = 1.0
	_delay_timer = 0.7

func tick(delta: float) -> bool:
	if _done: return true
	if _delay_timer > 0.0:
		_delay_timer -= delta
		if _delay_timer <= 0.0:
			_card_index += 1
			_input_locked = false
			_load_card()
		return false
	if _input_locked: return false
	_card_timer += delta
	# Update timer bar
	if is_instance_valid(_timer_fill):
		var pct = 1.0 - (_card_timer / _card_lifetime)
		_timer_fill.size.x = 500.0 * pct
		if pct < 0.3:
			_timer_fill.color = Color(0.9, 0.2, 0.2)
		elif pct < 0.6:
			_timer_fill.color = Color(1.0, 0.7, 0.1)
		else:
			_timer_fill.color = Color(0.3, 0.9, 0.3)
	# Feedback fade
	if _feedback_timer > 0.0:
		_feedback_timer -= delta
		_feedback_label.modulate.a = clamp(_feedback_timer, 0.0, 1.0)
	# Time out
	if _card_timer >= _card_lifetime and not _input_locked:
		_input_locked = true
		_budget_delta -= 5000
		_feedback_label.text = "⏰ TIME OUT! -$5,000"
		_feedback_label.add_theme_color_override("font_color", Color.ORANGE)
		_feedback_label.modulate.a = 1.0
		_feedback_timer = 1.0
		JuiceManager.wrong_sound()
		JuiceManager.hit_stop_and_shake(4.0)
		_delay_timer = 0.7
	return false

func get_result() -> Dictionary:
	# Bonus for high accuracy
	if _total_count > 0 and float(_correct_count) / float(_total_count) >= 0.8:
		_score += 300
		_budget_delta += 3000
	return {"score": _score, "budget_delta": _budget_delta, "days_delta": _days_delta}
