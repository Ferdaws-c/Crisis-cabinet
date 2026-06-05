extends CanvasLayer
## MinigameOverlay — Fullscreen popup container for all 12 minigames.
## Registered as an autoload in project.godot.

# ── Minigame registry ─────────────────────────────────────────────────────────
const MINIGAME_DATA: Dictionary = {
	"MG01": {
		"name": "Framework Frenzy",
		"phase": "🟢 PHASE 1: PLANNING",
		"pmbok": "IT Risk Identification Framework",
		"script": "res://scenes/minigames/MG01_FrameworkFrenzy.gd",
		"how_to_play": "Cards fall from the top — each one is a risk event.\nPress  ◀ LEFT ARROW  if it's an INTERNAL risk (people, tech, process).\nPress  RIGHT ARROW ▶  if it's an EXTERNAL risk (market, legal, politics).\nAnswer before the timer bar empties!",
		"you_will_learn": "How to classify IT project risks using the Risk Identification Framework into Internal vs. External categories — a core PMBOK skill.",
	},
	"MG02": {
		"name": "Nominal Ninja",
		"phase": "🟢 PHASE 1: PLANNING",
		"pmbok": "Nominal Group Technique",
		"script": "res://scenes/minigames/MG02_NominalNinja.gd",
		"how_to_play": "Numbered blocks (1–5) fall from above.\nMove LEFT / RIGHT with  A / D  to catch them IN SEQUENTIAL ORDER.\nKeep catching 1-2-3-4-5 in an endless loop until the timer runs out!\nWrong order = bounce penalty!",
		"you_will_learn": "The Nominal Group Technique: ideas (risks) must be prioritised in a specific ranked order to be useful in project planning.",
	},
	"MG03": {
		"name": "Decision Dash",
		"phase": "🟢 PHASE 1: PLANNING",
		"pmbok": "Decision Trees & EMV",
		"script": "res://scenes/minigames/MG03_DecisionDash.gd",
		"how_to_play": "Fork markers scroll toward you. Each has a LEFT and RIGHT lane.\nGreen = positive EMV (take it!). Red = penalty (avoid it!).\nPress  A  to go left,  D  to go right before the fork hits you.",
		"you_will_learn": "Expected Monetary Value (EMV) and Decision Tree analysis — choosing the highest-value path under uncertainty.",
	},
	"MG04": {
		"name": "Fishbone Fixer",
		"phase": "🟡 PHASE 2: EXECUTING",
		"pmbok": "Ishikawa / Cause & Effect Diagrams",
		"script": "res://scenes/minigames/MG04_FishboneFixer.gd",
		"how_to_play": "Red sparks travel along a fishbone diagram toward the project core.\nMove with  WASD  and press  SPACE  when close to a spark to extinguish it.\nDon't let sparks reach the center — the core has only 5 HP!",
		"you_will_learn": "Ishikawa (Fishbone) diagrams: tracing cause-and-effect chains to find root causes before they damage the project outcome.",
	},
	"MG05": {
		"name": "Impact Matrix",
		"phase": "🟡 PHASE 2: EXECUTING",
		"pmbok": "Tusler Risk Classification (P vs I)",
		"script": "res://scenes/minigames/MG05_ImpactMatrix.gd",
		"how_to_play": "A scenario appears on screen with Probability and Impact values.\nMove with  WASD  to run to the correct Tusler quadrant:\n🐊 Alligator (Low P / High I)  🐯 Tiger (High P / High I)\n🐱 Kitten (Low P / Low I)  🐶 Puppy (High P / Low I)\nYou have 4 seconds to reach the right zone!",
		"you_will_learn": "Tusler's Probability × Impact matrix: high-probability/high-impact risks (Tiger) cost the most, while low/low risks (Kitten) are minor.",
	},
	"MG06": {
		"name": "Monte Carlo Madness",
		"phase": "🟡 PHASE 2: EXECUTING",
		"pmbok": "Quantitative Probability Distributions",
		"script": "res://scenes/minigames/MG06_MonteCarlo.gd",
		"how_to_play": "Orange and red balls fall following a bell curve.\nMove the basket with  A / D  to catch ORANGE balls (expected outcomes).\nDODGE the RED balls (outliers) — catching one drains your budget!\nBuild combos for score multipliers!",
		"you_will_learn": "Monte Carlo simulation and Gaussian distributions: most project outcomes cluster around the mean, but outliers must be planned for.",
	},
	"MG07": {
		"name": "Strategy Shield",
		"phase": "🟠 PHASE 3: MONITORING",
		"pmbok": "PMBOK 11.5 — Risk Response Strategies",
		"script": "res://scenes/minigames/MG07_StrategyStance.gd",
		"how_to_play": "You control the Project Core. 4 types of risks approach:\n🔴 Fatal Flaw (Avoid): Use WASD to dodge!\n🟠 Hazard (Mitigate): Hold SPACE to laser/shrink it!\n🔵 Liability (Transfer): Press E to spawn an intercept drone!\n🟢 Minor Issue (Accept): Press Q to shield and absorb it for points!",
		"you_will_learn": "The four PMBOK risk response strategies: Avoid, Mitigate, Transfer, and Accept — and when each is the right choice.",
	},
	"MG08": {
		"name": "Trigger Tracker",
		"phase": "🟠 PHASE 3: MONITORING",
		"pmbok": "Risk Triggers & Early Warning Systems",
		"script": "res://scenes/minigames/MG08_TriggerTracker.gd",
		"how_to_play": "Warning circles ⚠ appear randomly and fade away.\nSprint with  WASD  (hold  SHIFT  to sprint faster).\nGet close to a warning and HOLD  SPACE  to defuse it before it explodes!\nThe more you defuse, the faster new ones appear!",
		"you_will_learn": "Risk triggers are early warning signs that a risk is about to occur. Monitoring and responding quickly prevents project damage.",
	},
	"MG09": {
		"name": "Reserve Roulette",
		"phase": "🟠 PHASE 3: MONITORING",
		"pmbok": "Contingency vs. Management Reserves",
		"script": "res://scenes/minigames/MG09_ReserveRoulette.gd",
		"how_to_play": "Risks march FAST toward your project core.\nPress  SPACE  to fire a Contingency Shot (destroys KNOWN/blue risks).\nPress  Q  for the Management Reserve AoE — but ONLY when the RED boss appears!\nWasting Q on normal risks = huge penalty. Move quickly!",
		"you_will_learn": "Contingency Reserves handle known risks. Management Reserves are for unknown risks. Using the wrong one wastes resources.",
	},
	"MG10": {
		"name": "Audit Escape",
		"phase": "🔵 PHASE 4: CLOSING",
		"pmbok": "Risk Evaluation — Lessons Learned",
		"script": "res://scenes/minigames/MG10_AuditEscape.gd",
		"how_to_play": "Objects scroll rapidly across 4 horizontal lanes!\nPress  W  (up) or  S  (down) to switch lanes.\nDODGE red obstacles (bad practices). COLLECT green pickups (best practices)!\nBuild a streak of 5 greens for a bonus!",
		"you_will_learn": "Closing a project requires documenting lessons learned, conducting audits, and reinforcing best practices to avoid repeat mistakes.",
	},
	"MG11": {
		"name": "Archive Assessor",
		"phase": "🔵 PHASE 4: CLOSING",
		"pmbok": "PMBOK 4.7 — Close Project or Phase",
		"script": "res://scenes/minigames/MG11_ArchiveAssessor.gd",
		"how_to_play": "Sort project closing documents!\n⬆️ UP: Lessons Learned (Knowledge Base)\n➡️ RIGHT: Deliverables (Customer)\n⬇️ DOWN: Invoices (Finance)\n⬅️ LEFT: Released Team (HR)",
		"you_will_learn": "The four distinct components of formally closing a project: transferring deliverables, closing procurements, releasing the team, and archiving lessons learned.",
	},
	"MG12": {
		"name": "SWOT Smasher",
		"phase": "🔵 PHASE 4: CLOSING",
		"pmbok": "SWOT Analysis",
		"script": "res://scenes/minigames/MG12_SWOTSmasher.gd",
		"how_to_play": "Characters pop up from a 3×3 cubicle grid.\nPress  Z  to SMASH 🔴 Threats and 🟡 Weaknesses.\nPress  X  to HIGH-FIVE 🟢 Strengths and 🔵 Opportunities.\nWrong response = big penalty. They disappear fast — stay sharp!",
		"you_will_learn": "SWOT Analysis: Strengths and Opportunities should be leveraged, while Threats and Weaknesses must be addressed in project closure.",
	},
}

# ── Internal state ─────────────────────────────────────────────────────────────
var _current_mg_id: String = ""
var _current_game: Node = null
var _game_score: int = 0
var _game_budget_delta: int = 0
var _game_days_delta: int = 0
var _time_remaining: float = 60.0
var _max_time: float = 60.0
var _is_running: bool = false
var _end_called: bool = false   # guard against double _end_game calls

var _caller_room: Node = null
var _caller_pad: String = ""

# ── Node references ────────────────────────────────────────────────────────────
var _root_panel: ColorRect
var _close_btn: Button              # ✕ top-right, visible only on instruction screen
var _splash_panel: PanelContainer        # instruction / intro screen
var _splash_phase_lbl: Label
var _splash_name_lbl: Label
var _splash_pmbok_lbl: Label
var _splash_howto_lbl: RichTextLabel
var _splash_learn_lbl: RichTextLabel
var _splash_play_btn: Button
var _hud_bar: PanelContainer
var _hud_phase: Label
var _hud_name: Label
var _hud_timer_bar: ProgressBar
var _hud_score: Label
var _game_area: Control
var _result_panel: PanelContainer
var _result_title: Label
var _result_details: RichTextLabel

# ── Lifecycle ──────────────────────────────────────────────────────────────────
func _ready() -> void:
	layer = 50
	visible = false
	add_to_group("minigame_overlay")
	_build_ui()

func _process(delta: float) -> void:
	if not _is_running:
		return
	_time_remaining -= delta

	# Update HUD timer
	if _hud_timer_bar:
		_hud_timer_bar.value = _time_remaining / _max_time
		if _time_remaining < 10.0:
			_hud_timer_bar.modulate = Color(1.0, 0.25, 0.25)
		elif _time_remaining < 25.0:
			_hud_timer_bar.modulate = Color(1.0, 0.75, 0.1)
		else:
			_hud_timer_bar.modulate = Color(0.3, 0.9, 0.3)

	# Mirror live score from minigame
	if is_instance_valid(_current_game):
		if "score" in _current_game:
			_game_score = _current_game.get("score")
		elif "_score" in _current_game:
			_game_score = _current_game.get("_score")
	if _hud_score:
		_hud_score.text = "⭐ %d pts" % _game_score

	# Escape to end minigame
	if Input.is_key_pressed(KEY_ESCAPE) and _is_running:
		_end_game()
		return

	# Check timer expired
	if _time_remaining <= 0.0:
		_end_game()
		return

	# Tick the active minigame
	if is_instance_valid(_current_game) and _current_game.has_method("tick"):
		var done: bool = _current_game.tick(delta)
		if done:
			_end_game()

# ── Public API ─────────────────────────────────────────────────────────────────
func launch(mg_id: String, room: Node = null, pad_category: String = "") -> void:
	if not MINIGAME_DATA.has(mg_id):
		printerr("MinigameOverlay: Unknown minigame id '", mg_id, "'")
		GameManager.is_movement_paused = false
		return
	_caller_room = room
	_caller_pad = pad_category
	_current_mg_id = mg_id
	_game_score = 0
	_game_budget_delta = 0
	_game_days_delta = 0
	_end_called = false
	_is_running = false
	visible = true
	_show_instructions(mg_id)

func report(score_delta: int, budget_delta: int, days_delta: int) -> void:
	_game_score += score_delta
	_game_budget_delta += budget_delta
	_game_days_delta += days_delta

# ── UI Builder ─────────────────────────────────────────────────────────────────
func _build_ui() -> void:
	_root_panel = ColorRect.new()
	_root_panel.color = Color(0.0, 0.0, 0.0, 0.88)
	_root_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root_panel)

	# ── Close button is built INSIDE the panel header below — not here ──

	# ── Instruction / splash panel — wrapped in CenterContainer so it's always centered ──
	var splash_center = CenterContainer.new()
	splash_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	splash_center.visible = false
	_root_panel.add_child(splash_center)

	_splash_panel = PanelContainer.new()
	_splash_panel.custom_minimum_size = Vector2(860, 460)
	var sb = _make_stylebox(Color(0.05, 0.06, 0.15, 0.98), Color(0.35, 0.65, 1.0), 3, 16)
	_splash_panel.add_theme_stylebox_override("panel", sb)
	splash_center.add_child(_splash_panel)
	# Store center wrapper so _show_instructions can show/hide it
	_splash_panel.set_meta("center", splash_center)

	var outer = VBoxContainer.new()
	outer.add_theme_constant_override("separation", 14)
	_splash_panel.add_child(outer)

	# Header row: titles on left+center, close button on right
	var header_row = HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 8)
	outer.add_child(header_row)

	var title_col = VBoxContainer.new()
	title_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_col.add_theme_constant_override("separation", 4)
	header_row.add_child(title_col)

	# Phase strip
	_splash_phase_lbl = Label.new()
	_splash_phase_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_splash_phase_lbl.add_theme_font_size_override("font_size", 13)
	_splash_phase_lbl.add_theme_color_override("font_color", Color(0.55, 0.8, 1.0))
	title_col.add_child(_splash_phase_lbl)

	# Game name
	_splash_name_lbl = Label.new()
	_splash_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_splash_name_lbl.add_theme_font_size_override("font_size", 34)
	_splash_name_lbl.add_theme_color_override("font_color", Color.WHITE)
	title_col.add_child(_splash_name_lbl)

	# PMBOK tag
	_splash_pmbok_lbl = Label.new()
	_splash_pmbok_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_splash_pmbok_lbl.add_theme_font_size_override("font_size", 13)
	_splash_pmbok_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	title_col.add_child(_splash_pmbok_lbl)

	# ✕ Close button — top-right of the panel
	_close_btn = Button.new()
	_close_btn.text = "✕"
	_close_btn.add_theme_font_size_override("font_size", 18)
	_close_btn.custom_minimum_size = Vector2(38, 38)
	_close_btn.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var close_sb = _make_stylebox(Color(0.4, 0.07, 0.07, 0.92), Color(0.85, 0.2, 0.2), 2, 8)
	_close_btn.add_theme_stylebox_override("normal", close_sb)
	_close_btn.add_theme_stylebox_override("hover",
		_make_stylebox(Color(0.7, 0.1, 0.1, 0.97), Color(1.0, 0.35, 0.35), 2, 8))
	_close_btn.add_theme_color_override("font_color", Color.WHITE)
	_close_btn.tooltip_text = "Close (return to game)"
	_close_btn.pressed.connect(_on_close_pressed)
	header_row.add_child(_close_btn)

	var sep1 = HSeparator.new(); outer.add_child(sep1)

	# Two-column row: How to Play | What You'll Learn
	var cols = HBoxContainer.new()
	cols.add_theme_constant_override("separation", 20)
	outer.add_child(cols)

	# Left column – How to Play
	var left_col = VBoxContainer.new()
	left_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_col.add_theme_constant_override("separation", 6)
	cols.add_child(left_col)

	var lbl_howto_hdr = Label.new()
	lbl_howto_hdr.text = "🎮  HOW TO PLAY"
	lbl_howto_hdr.add_theme_font_size_override("font_size", 14)
	lbl_howto_hdr.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
	left_col.add_child(lbl_howto_hdr)

	_splash_howto_lbl = RichTextLabel.new()
	_splash_howto_lbl.bbcode_enabled = true
	_splash_howto_lbl.fit_content = true
	_splash_howto_lbl.custom_minimum_size = Vector2(360, 100)
	_splash_howto_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_splash_howto_lbl.add_theme_font_size_override("normal_font_size", 13)
	left_col.add_child(_splash_howto_lbl)

	# Divider
	var vsep = VSeparator.new()
	cols.add_child(vsep)

	# Right column – What You'll Learn
	var right_col = VBoxContainer.new()
	right_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_col.add_theme_constant_override("separation", 6)
	cols.add_child(right_col)

	var lbl_learn_hdr = Label.new()
	lbl_learn_hdr.text = "🎓  WHAT YOU'LL LEARN"
	lbl_learn_hdr.add_theme_font_size_override("font_size", 14)
	lbl_learn_hdr.add_theme_color_override("font_color", Color(0.4, 1.0, 0.6))
	right_col.add_child(lbl_learn_hdr)

	_splash_learn_lbl = RichTextLabel.new()
	_splash_learn_lbl.bbcode_enabled = true
	_splash_learn_lbl.fit_content = true
	_splash_learn_lbl.custom_minimum_size = Vector2(360, 100)
	_splash_learn_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_splash_learn_lbl.add_theme_font_size_override("normal_font_size", 13)
	right_col.add_child(_splash_learn_lbl)

	var sep2 = HSeparator.new(); outer.add_child(sep2)

	# Play button
	_splash_play_btn = Button.new()
	_splash_play_btn.text = "▶  START GAME"
	_splash_play_btn.custom_minimum_size = Vector2(0, 52)
	_splash_play_btn.add_theme_font_size_override("font_size", 20)
	var btn_sb = _make_stylebox(Color(0.1, 0.55, 0.2), Color(0.3, 1.0, 0.4), 2, 10)
	_splash_play_btn.add_theme_stylebox_override("normal", btn_sb)
	_splash_play_btn.add_theme_stylebox_override("hover",
		_make_stylebox(Color(0.15, 0.7, 0.25), Color(0.4, 1.0, 0.5), 2, 10))
	_splash_play_btn.add_theme_color_override("font_color", Color.WHITE)
	_splash_play_btn.pressed.connect(_on_play_pressed)
	outer.add_child(_splash_play_btn)

	# ── HUD bar ──
	_hud_bar = PanelContainer.new()
	_hud_bar.set_anchor(SIDE_LEFT, 0.0); _hud_bar.set_anchor(SIDE_RIGHT, 1.0)
	_hud_bar.set_anchor(SIDE_TOP, 0.0);  _hud_bar.set_anchor(SIDE_BOTTOM, 0.0)
	_hud_bar.set_offset(SIDE_BOTTOM, 56)
	_hud_bar.visible = false
	_hud_bar.add_theme_stylebox_override("panel",
		_make_stylebox(Color(0.04, 0.04, 0.12, 0.96), Color(0.2, 0.4, 0.8), 0, 0))
	_root_panel.add_child(_hud_bar)

	var hud_hbox = HBoxContainer.new()
	hud_hbox.add_theme_constant_override("separation", 20)
	hud_hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hud_bar.add_child(hud_hbox)

	_hud_phase = Label.new()
	_hud_phase.add_theme_font_size_override("font_size", 12)
	_hud_phase.add_theme_color_override("font_color", Color(0.55, 0.8, 1.0))
	_hud_phase.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hud_hbox.add_child(_hud_phase)

	_hud_name = Label.new()
	_hud_name.add_theme_font_size_override("font_size", 16)
	_hud_name.add_theme_color_override("font_color", Color.WHITE)
	_hud_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hud_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_hbox.add_child(_hud_name)

	_hud_timer_bar = ProgressBar.new()
	_hud_timer_bar.custom_minimum_size = Vector2(200, 24)
	_hud_timer_bar.max_value = 1.0
	_hud_timer_bar.value = 1.0
	_hud_timer_bar.show_percentage = false
	hud_hbox.add_child(_hud_timer_bar)

	_hud_score = Label.new()
	_hud_score.add_theme_font_size_override("font_size", 16)
	_hud_score.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	_hud_score.custom_minimum_size = Vector2(130, 0)
	_hud_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hud_hbox.add_child(_hud_score)

	# ── Game area ──
	_game_area = Control.new()
	_game_area.set_anchor(SIDE_LEFT, 0.0); _game_area.set_anchor(SIDE_RIGHT, 1.0)
	_game_area.set_anchor(SIDE_TOP, 0.0);  _game_area.set_anchor(SIDE_BOTTOM, 1.0)
	_game_area.set_offset(SIDE_TOP, 60)
	_game_area.set_offset(SIDE_BOTTOM, 0)
	_game_area.visible = false
	_root_panel.add_child(_game_area)

	# ── Result panel — also wrapped in CenterContainer ──
	var result_center = CenterContainer.new()
	result_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	result_center.visible = false
	_root_panel.add_child(result_center)

	_result_panel = PanelContainer.new()
	_result_panel.custom_minimum_size = Vector2(620, 380)
	_result_panel.add_theme_stylebox_override("panel",
		_make_stylebox(Color(0.04, 0.1, 0.04, 0.98), Color(0.2, 0.9, 0.3), 3, 16))
	result_center.add_child(_result_panel)
	_result_panel.set_meta("center", result_center)

	var rvbox = VBoxContainer.new()
	rvbox.add_theme_constant_override("separation", 16)
	_result_panel.add_child(rvbox)

	_result_title = Label.new()
	_result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_title.add_theme_font_size_override("font_size", 30)
	rvbox.add_child(_result_title)

	_result_details = RichTextLabel.new()
	_result_details.bbcode_enabled = true
	_result_details.fit_content = true
	_result_details.custom_minimum_size = Vector2(560, 200)
	rvbox.add_child(_result_details)

	var cont_btn = Button.new()
	cont_btn.text = "CONTINUE  →"
	cont_btn.custom_minimum_size = Vector2(0, 50)
	cont_btn.add_theme_font_size_override("font_size", 18)
	cont_btn.pressed.connect(_on_continue_pressed)
	rvbox.add_child(cont_btn)

# ── Instruction screen ─────────────────────────────────────────────────────────
func _show_instructions(mg_id: String) -> void:
	var data: Dictionary = MINIGAME_DATA[mg_id]
	_splash_phase_lbl.text = data["phase"]
	_splash_name_lbl.text = data["name"]
	_splash_pmbok_lbl.text = "📖  " + data["pmbok"]
	_splash_howto_lbl.text = "[color=#b0d8ff]" + data["how_to_play"] + "[/color]"
	_splash_learn_lbl.text = "[color=#a0ffb8]" + data["you_will_learn"] + "[/color]"
	# Show CenterContainer wrapper (close btn is inside panel, always visible with it)
	_splash_panel.get_meta("center").visible = true
	_result_panel.get_meta("center").visible = false
	_game_area.visible = false
	_hud_bar.visible = false

func _on_play_pressed() -> void:
	_splash_panel.get_meta("center").visible = false
	_start_game(_current_mg_id)

func _on_close_pressed() -> void:
	if is_instance_valid(_caller_room) and _caller_room.has_method("unconsume_pad"):
		_caller_room.unconsume_pad(_caller_pad)
	_splash_panel.get_meta("center").visible = false
	visible = false
	GameManager.is_movement_paused = false

# ── Game start ─────────────────────────────────────────────────────────────────
func _start_game(mg_id: String) -> void:
	var data: Dictionary = MINIGAME_DATA[mg_id]
	_hud_phase.text = data["phase"]
	_hud_name.text = data["name"]
	_hud_score.text = "⭐ 0 pts"
	_hud_timer_bar.value = 1.0
	_hud_timer_bar.modulate = Color(0.3, 0.9, 0.3)
	_hud_bar.visible = true
	_game_area.visible = true

	# Clear any leftover nodes from previous minigames
	for child in _game_area.get_children():
		child.queue_free()

	var script_path: String = data["script"]
	if not ResourceLoader.exists(script_path):
		printerr("Minigame script not found: ", script_path)
		_end_game()
		return

	var script = load(script_path)
	_current_game = Node.new()
	_current_game.set_script(script)
	_game_area.add_child(_current_game)

	if _current_game.has_method("start"):
		_current_game.start(_game_area, self)

	if mg_id == "MG03":
		_max_time = 30.0
	else:
		_max_time = 45.0
	_time_remaining = _max_time
	_is_running = true

# ── Game end ───────────────────────────────────────────────────────────────────
func _end_game() -> void:
	if _end_called:
		return
	_end_called = true
	_is_running = false

	JuiceManager.game_over_sound()

	# Collect final result from minigame before freeing it
	if is_instance_valid(_current_game):
		# Stop the minigame processing so any pending awaits do no harm
		_current_game.set_process_mode(Node.PROCESS_MODE_DISABLED)
		if _current_game.has_method("get_result"):
			var result: Dictionary = _current_game.get_result()
			_game_score    = result.get("score",        _game_score)
			_game_budget_delta = result.get("budget_delta", _game_budget_delta)
			_game_days_delta   = result.get("days_delta",   _game_days_delta)
		_current_game.queue_free()
		_current_game = null

	_game_area.visible = false
	_hud_bar.visible = false

	# Report to GameManager
	var time_taken = _max_time - _time_remaining
	GameManager.on_minigame_complete(
		_current_mg_id, _game_score, _game_budget_delta, _game_days_delta, time_taken)

	_show_result()

func _show_result() -> void:
	var is_win: bool = _game_score > 0
	_result_title.text = "✅  GREAT WORK!" if is_win else "❌  NEEDS IMPROVEMENT"
	_result_title.add_theme_color_override("font_color",
		Color(0.3, 1.0, 0.4) if is_win else Color(1.0, 0.3, 0.3))

	var sign_b: String = "+" if _game_budget_delta >= 0 else ""
	var sign_d: String = "+" if _game_days_delta >= 0 else ""
	var col_b: String  = "green" if _game_budget_delta >= 0 else "red"
	var col_d: String  = "green" if _game_days_delta >= 0 else "red"
	var col_s: String  = "yellow" if _game_score > 0 else "red"

	_result_details.text = (
		"[center]" +
		"[b]Score:[/b]   [color=%s]%d pts[/color]\n" % [col_s, _game_score] +
		"[b]Budget:[/b]  [color=%s]%s$%d[/color]\n" % [col_b, sign_b, abs(_game_budget_delta)] +
		"[b]Days:[/b]    [color=%s]%s%d days[/color]\n\n" % [col_d, sign_d, abs(_game_days_delta)] +
		"[color=gray]Current Budget: $%d  |  Days Remaining: %d[/color]" %
			[GameManager.budget, GameManager.schedule_days] +
		"[/center]"
	)
	# Show via CenterContainer wrapper
	_result_panel.get_meta("center").visible = true

func _on_continue_pressed() -> void:
	_result_panel.get_meta("center").visible = false
	visible = false
	if GameManager.game_over:
		return
	GameManager.is_movement_paused = false
	if GameManager.current_phase == "Finished":
		GameManager.save_high_score()

# ── Helpers ────────────────────────────────────────────────────────────────────
func _make_stylebox(bg: Color, border: Color, bw: int, radius: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	for side in ["border_width_left","border_width_right","border_width_top","border_width_bottom"]:
		s.set(side, bw)
	for c in ["corner_radius_top_left","corner_radius_top_right",
			  "corner_radius_bottom_left","corner_radius_bottom_right"]:
		s.set(c, radius)
	return s
