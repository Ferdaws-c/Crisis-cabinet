extends CanvasLayer

# ─────────────────────────────────────────────
# Node structure (ScenarioPopup.tscn):
# ScenarioPopup (CanvasLayer)
# └── Panel
#     └── Layout (VBoxContainer)
#         ├── AlertHeader (HBoxContainer)
#         │   ├── AlertBadge (Label)
#         │   └── TitleLabel (Label)
#         ├── SituationLabel (Label)
#         ├── TimerBar (ProgressBar)
#         ├── StepLabel (Label)
#         ├── TuslerGrid (GridContainer)  ← classification step
#         ├── StrategyContainer (VBoxContainer)
#         ├── MitigationContainer (VBoxContainer)
#         └── FeedbackContainer (VBoxContainer)  ← post-answer PMBOK tip
# ─────────────────────────────────────────────

@onready var popup_panel        = find_child("Panel", true, false)
@onready var title_label        = find_child("TitleLabel", true, false)
@onready var situation_label    = find_child("SituationLabel", true, false)
@onready var timer_bar          = find_child("TimerBar", true, false)
@onready var step_label         = find_child("StepLabel", true, false)
@onready var alert_badge        = find_child("AlertBadge", true, false)

var stats_hbox: HBoxContainer
var prob_val: Label
var impact_val: Label
var urgency_val: Label
@onready var tusler_grid        = find_child("TuslerGrid", true, false)
@onready var strategy_container = find_child("StrategyContainer", true, false)
@onready var mitigation_container = find_child("MitigationContainer", true, false)
@onready var feedback_container = find_child("FeedbackContainer", true, false)

var time_left: float = 45.0
var timer_active: bool = false
var current_scenario: Dictionary
var chosen_category: String = ""
var current_step_name: String = ""
var next_callback: String = ""

var current_log: Dictionary = {"title": "", "classify": false, "strategy": false, "mitigate": false}

signal scenario_completed

# ── Tusler category metadata ──────────────────
const TUSLER = {
	"tiger":    {"label": "🐯 TIGER",     "color": Color(0.85, 0.15, 0.15), "desc": "High Prob · High Impact\nACT NOW"},
	"alligator":{"label": "🐊 ALLIGATOR", "color": Color(0.85, 0.45, 0.05), "desc": "Low Prob · High Impact\nPLAN FOR IT"},
	"puppy":    {"label": "🐶 PUPPY",     "color": Color(0.15, 0.55, 0.85), "desc": "High Prob · Low Impact\nMANAGE IT"},
	"kitten":   {"label": "🐱 KITTEN",    "color": Color(0.35, 0.75, 0.35), "desc": "Low Prob · Low Impact\nMONITOR"}
}

# PMBOK 11 tips shown after correct answers
const PMBOK_TIPS = {
	"tiger":    "📖 PMBOK 11.5 — Plan Risk Responses:\nHigh-probability, high-impact risks demand an active response strategy. Mitigation or Avoidance must be implemented before the risk triggers.",
	"alligator":"📖 PMBOK 11.3 — Qualitative Analysis:\nLow-probability risks with catastrophic potential are mapped to contingency plans. Transfer strategies (insurance) are cost-effective here.",
	"puppy":    "📖 PMBOK 11.4 — Quantitative Analysis:\nFrequent low-impact risks inflate cumulative costs. Mitigation via process controls reduces probability across delivery cycles.",
	"kitten":   "📖 PMBOK 11.7 — Monitor Risks:\nLow-priority risks are added to the Risk Register watchlist. No active response unless thresholds are breached.",
}

func _ready() -> void:
	self.visible = false
	_apply_panel_style()
	if situation_label:
		situation_label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		situation_label.custom_minimum_size = Vector2(700, 0)
	if timer_bar:
		timer_bar.max_value = 45
		timer_bar.value = 45
	# Push Layout inward so content never touches edges
	var layout = find_child("Layout", true, false)
	if layout:
		layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		layout.set_offset(SIDE_LEFT, 32)
		layout.set_offset(SIDE_TOP, 24)
		layout.set_offset(SIDE_RIGHT, -32)
		layout.set_offset(SIDE_BOTTOM, -24)
		layout.add_theme_constant_override("separation", 10)
		
		# Inject Stats HBox right below Situation Label
		stats_hbox = HBoxContainer.new()
		stats_hbox.add_theme_constant_override("separation", 20)
		stats_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		
		var p_box = HBoxContainer.new()
		var p_tit = Label.new(); p_tit.text = "Probability: "
		p_tit.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		prob_val = Label.new()
		prob_val.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
		p_box.add_child(p_tit); p_box.add_child(prob_val)
		
		var i_box = HBoxContainer.new()
		var i_tit = Label.new(); i_tit.text = "Impact: "
		i_tit.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		impact_val = Label.new()
		impact_val.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
		i_box.add_child(i_tit); i_box.add_child(impact_val)
		
		var u_box = HBoxContainer.new()
		var u_tit = Label.new(); u_tit.text = "Urgency: "
		u_tit.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		urgency_val = Label.new()
		urgency_val.add_theme_color_override("font_color", Color(0.2, 0.8, 1.0))
		u_box.add_child(u_tit); u_box.add_child(urgency_val)
		
		stats_hbox.add_child(p_box)
		stats_hbox.add_child(i_box)
		stats_hbox.add_child(u_box)
		
		var idx = situation_label.get_index() + 1
		layout.add_child(stats_hbox)
		layout.move_child(stats_hbox, idx)
		
	_hide_all_steps()

func _apply_panel_style() -> void:
	if not popup_panel: return
	
	# Fallback: Procedurally add a solid ColorRect background
	# This is much more reliable on Intel/Surface integrated graphics than StyleBoxFlat
	var solid_bg = popup_panel.get_node_or_null("SolidBackground")
	if not solid_bg:
		solid_bg = ColorRect.new()
		solid_bg.name = "SolidBackground"
		solid_bg.color = Color(0.02, 0.05, 0.1, 1.0) # Solid dark navy
		solid_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		popup_panel.add_child(solid_bg)
		popup_panel.move_child(solid_bg, 0)
	
	var style = StyleBoxFlat.new()
	style.draw_center = false # Let the ColorRect do the filling
	for corner in ["corner_radius_top_left","corner_radius_top_right",
				   "corner_radius_bottom_left","corner_radius_bottom_right"]:
		style.set(corner, 14)
	for side in ["border_width_left","border_width_right",
				 "border_width_top","border_width_bottom"]:
		style.set(side, 2)
	style.border_color = Color(0.25, 0.55, 1.0, 0.9)
	style.content_margin_left = 32
	style.content_margin_right = 32
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	popup_panel.add_theme_stylebox_override("panel", style)

func _hide_all_steps() -> void:
	for node in [tusler_grid, strategy_container, mitigation_container, feedback_container]:
		if node: node.hide()

func _process(delta: float) -> void:
	if not timer_active: return
	
	if GameManager.timer_enabled:
		time_left -= delta
		
	if timer_bar:
		timer_bar.value = time_left
		# Colour-coded urgency: green → yellow → red
		if time_left > 25:
			timer_bar.modulate = Color(0.3, 0.9, 0.3)
		elif time_left > 10:
			timer_bar.modulate = Color(1.0, 0.8, 0.1)
		else:
			timer_bar.modulate = Color(1.0, 0.2, 0.2)
	if time_left <= 0:
		timer_active = false
		GameManager.budget -= 3000
		GameManager.break_streak()
		var msg = "⏰ TIME OUT! -$3,000 Budget."
		if current_step_name == "classification":
			_show_intermediate_feedback(false, msg + "\nMoving to Strategy.", "_start_strategy")
		elif current_step_name == "strategy":
			_show_intermediate_feedback(false, msg + "\nMoving to Mitigation.", "_start_mitigation")
		elif current_step_name == "mitigation":
			_show_intermediate_feedback(false, msg, "_scenario_done")

# ── Public entry point ────────────────────────
func show_popup(scenario_data: Dictionary, _category: String) -> void:
	current_scenario = scenario_data
	self.visible = true

	if title_label and current_scenario.has("title"):
		var raw_title = current_scenario["title"]
		if " — " in raw_title:
			raw_title = raw_title.split(" — ", false, 1)[1]
		title_label.text = raw_title
		
	# Initialize structured local logging
	current_log = {
		"title": current_scenario.get("title", "Unknown Risk"),
		"classify": false,
		"strategy": false,
		"mitigate": false
	}
	if situation_label and current_scenario.has("setup"):
		situation_label.text = current_scenario["setup"]
		
	if prob_val: prob_val.text = current_scenario.get("prob", "N/A")
	if impact_val: impact_val.text = current_scenario.get("impact", "N/A") + " / max 20 Days"
	if urgency_val: urgency_val.text = current_scenario.get("urgency", "N/A")

	if alert_badge:
		alert_badge.hide()

	# Fade in
	if popup_panel:
		popup_panel.modulate.a = 0.0
		create_tween().tween_property(popup_panel, "modulate:a", 1.0, 0.4)

	# Injecting Step 0: The Educational Primer
	var has_lesson = current_scenario.has("lesson_text")
	if has_lesson:
		_show_lesson()
	else:
		_start_classification()

# ── Step 0: The Educational Qualifier ─────────
func _show_lesson() -> void:
	_hide_all_steps()
	current_step_name = "lesson"
	timer_active = false # No timer while reading the textbook!
	if timer_bar: timer_bar.modulate.a = 0.3 # Dim the timer bar
	
	if step_label: step_label.text = "ACADEMIC PRIMER — Please read before deciding"
	
	if not mitigation_container: return
	mitigation_container.show()
	for child in mitigation_container.get_children(): child.queue_free()
	
	var lesson_label = Label.new()
	lesson_label.text = current_scenario.get("lesson_text", "")
	lesson_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lesson_label.custom_minimum_size = Vector2(700, 0)
	lesson_label.add_theme_font_size_override("font_size", 16)
	lesson_label.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	mitigation_container.add_child(lesson_label)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	mitigation_container.add_child(spacer)
	
	var btn = Button.new()
	btn.text = "I Understand — Begin Scenario"
	btn.custom_minimum_size = Vector2(300, 50)
	var bs = StyleBoxFlat.new()
	bs.bg_color = Color(0.2, 0.5, 0.8)
	for c in ["corner_radius_top_left","corner_radius_top_right","corner_radius_bottom_left","corner_radius_bottom_right"]: bs.set(c, 8)
	btn.add_theme_stylebox_override("normal", bs)
	btn.pressed.connect(func():
		if timer_bar: timer_bar.modulate.a = 1.0
		_start_classification()
	)
	mitigation_container.add_child(btn)
	btn.grab_focus.call_deferred()

# ── Step 1: Tusler Classification Mini-game ───
func _start_classification() -> void:
	_hide_all_steps()
	current_step_name = "classification"
	time_left = 45.0; timer_active = true
	if step_label: step_label.text = "STEP 1 OF 3 — Classify this risk on the Tusler Matrix"
	if not tusler_grid: return
	tusler_grid.show()
	tusler_grid.columns = 2
	for child in tusler_grid.get_children(): child.queue_free()

	var order = ["tiger","alligator","puppy","kitten"]
	for cat in order:
		var meta = TUSLER[cat]
		var btn = Button.new()
		btn.text = meta["label"] + "\n" + meta["desc"]
		btn.custom_minimum_size = Vector2(220, 100)
		_style_tile(btn, meta["color"])
		btn.pressed.connect(_on_classification_selected.bind(cat))
		tusler_grid.add_child(btn)
		if cat == order[0]:
			btn.grab_focus.call_deferred()

# ── Step 2: PMBOK Strategy ────────────────────
func _start_strategy() -> void:
	_hide_all_steps()
	current_step_name = "strategy"
	time_left = 45.0; timer_active = true
	if step_label: step_label.text = "STEP 2 OF 3 — Select a PMBOK Response Strategy"
	if not strategy_container: return
	strategy_container.show()
	for child in strategy_container.get_children(): child.queue_free()

	var strategies = [
		{"name":"Avoid",    "icon":"🚫", "desc":"Eliminate the risk entirely by changing the plan.", "color":Color(0.75,0.15,0.15)},
		{"name":"Mitigate", "icon":"🛡", "desc":"Reduce probability or impact before it occurs.",   "color":Color(0.15,0.55,0.20)},
		{"name":"Transfer", "icon":"📦", "desc":"Shift the impact to a third party (insurance).",  "color":Color(0.15,0.35,0.80)},
		{"name":"Accept",   "icon":"✅", "desc":"Acknowledge the risk and prepare a fallback.",     "color":Color(0.55,0.45,0.10)},
	]
	for s in strategies:
		var btn = Button.new()
		btn.text = s["icon"] + "  " + s["name"] + "\n" + s["desc"]
		btn.custom_minimum_size = Vector2(0, 55)
		var locked = GameManager.is_low_budget() and s["name"] in ["Avoid","Transfer"]
		if locked:
			btn.disabled = true
			btn.text += "\n💰 LOCKED — Budget too low"
			_style_tile(btn, Color(0.25,0.25,0.25))
		else:
			_style_tile(btn, s["color"])
		btn.pressed.connect(_on_strategy_selected.bind(s["name"]))
		strategy_container.add_child(btn)
		if s == strategies[0]:
			btn.grab_focus.call_deferred()

# ── Step 3: Specific Mitigation ───────────────
func _start_mitigation() -> void:
	_hide_all_steps()
	current_step_name = "mitigation"
	time_left = 45.0; timer_active = true
	if step_label: step_label.text = "STEP 3 OF 3 — Choose the specific mitigation action"
	if not mitigation_container: return
	mitigation_container.show()
	for child in mitigation_container.get_children(): child.queue_free()

	var correct = "Implement correct action"
	if current_scenario.has("winCondition"):
		var parts = current_scenario["winCondition"].split("'")
		if parts.size() >= 3: correct = parts[1]

	var options = [correct,
		"Wait and observe — do nothing yet.",
		"Request extra budget as a buffer.",
		"Delegate to the standard team process."]
	options.shuffle()

	for opt in options:
		var btn = Button.new()
		btn.text = opt
		btn.custom_minimum_size = Vector2(0, 52)
		var is_correct = (opt == correct)
		_style_tile(btn, Color(0.20, 0.35, 0.55)) # Neutral blue for all options
		btn.pressed.connect(_on_mitigation_selected.bind(is_correct, opt))
		mitigation_container.add_child(btn)
		if opt == options[0]:
			btn.grab_focus.call_deferred()

# ── Callbacks ─────────────────────────────────
func _on_classification_selected(cat: String) -> void:
	timer_active = false
	chosen_category = cat
	
	var title = current_scenario.get("title", "").to_lower()
	var correct_cat = "tiger"
	for k in TUSLER.keys():
		if k in title: correct_cat = k; break
		
	var is_correct = cat == correct_cat
	current_log.classify = is_correct
	
	var stat_dict = GameManager.get("stats_" + correct_cat)
	if stat_dict:
		stat_dict.t += 1
		if is_correct: stat_dict.c += 1
		GameManager.emit_signal("state_changed")
	
	if is_correct:
		GameManager.schedule_days -= 2
		GameManager.add_score(30)
		_start_strategy()
	else:
		GameManager.schedule_days -= 5
		GameManager.budget -= 5000
		GameManager.emit_signal("state_changed")
		GameManager.break_streak()
		_show_intermediate_feedback(false, "Incorrect Classification! -$5,000 Budget & -5 Days.\nCorrect answer was: " + correct_cat.to_upper(), "_start_strategy")

func _on_strategy_selected(strat: String) -> void:
	timer_active = false
	var objective = current_scenario.get("objective", "")
	var is_correct = ("Select " + strat) in objective or ("Choose " + strat) in objective or strat in objective
	current_log.strategy = is_correct
	
	if is_correct:
		GameManager.schedule_days -= 3
		GameManager.add_score(20)
		_start_mitigation()
	else:
		GameManager.schedule_days -= 5
		GameManager.budget -= 5000
		GameManager.emit_signal("state_changed")
		GameManager.break_streak()
		_show_intermediate_feedback(false, "Incorrect Strategy! -$5,000 Budget & -5 Days.\nCheck the scenario constraints carefully.", "_start_mitigation")

func _on_mitigation_selected(is_correct: bool, _opt: String) -> void:
	timer_active = false
	
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("log_risk_decision"):
		var risk_title = current_scenario.get("title", "Unknown Risk")
		var strat = current_scenario.get("objective", "Action")
		hud.log_risk_decision(risk_title, strat, is_correct)
		
	current_log.mitigate = is_correct
	GameManager.decision_log.append(current_log.duplicate(true))
		
	if is_correct:
		GameManager.schedule_days -= 5
		GameManager.add_score(30)
		GameManager.increment_streak()
	else:
		GameManager.schedule_days -= 10
		GameManager.budget -= 15000
		GameManager.emit_signal("state_changed")
		GameManager.break_streak()
	_show_feedback(is_correct)

func _show_intermediate_feedback(is_correct: bool, msg: String, next_func: String) -> void:
	_hide_all_steps()
	next_callback = next_func
	if step_label:
		step_label.text = "✅ CORRECT" if is_correct else "❌ INCORRECT"
		step_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4) if is_correct else Color(1.0, 0.3, 0.3))
	
	if feedback_container:
		feedback_container.show()
		for child in feedback_container.get_children(): child.queue_free()
		
		var tip = Label.new()
		tip.text = msg
		tip.autowrap_mode = TextServer.AUTOWRAP_WORD
		tip.custom_minimum_size = Vector2(700, 0)
		feedback_container.add_child(tip)
		
		var btn = Button.new()
		btn.text = "Continue →"
		btn.custom_minimum_size = Vector2(0, 48)
		_style_tile(btn, Color(0.2, 0.4, 0.8))
		btn.pressed.connect(_on_intermediate_continue)
		feedback_container.add_child(btn)
		btn.grab_focus.call_deferred()

func _on_intermediate_continue() -> void:
	if next_callback == "_start_strategy":
		_start_strategy()
	elif next_callback == "_start_mitigation":
		_start_mitigation()
	elif next_callback == "_scenario_done":
		_scenario_done()

func _show_feedback(is_correct: bool) -> void:
	_hide_all_steps()
	if step_label:
		step_label.text = "✅ CORRECT! Well done. (-5 Days)" if is_correct else "❌ Incorrect. -$15,000 Budget & -10 Days Late Penalty."
		step_label.add_theme_color_override("font_color",
			Color(0.3, 1.0, 0.4) if is_correct else Color(1.0, 0.3, 0.3))

	if feedback_container:
		feedback_container.show()
		for child in feedback_container.get_children(): child.queue_free()

		# PMBOK tip label
		var tip = Label.new()
		tip.text = PMBOK_TIPS.get(chosen_category, "📖 Review PMBOK Chapter 11 — Project Risk Management.")
		tip.autowrap_mode = TextServer.AUTOWRAP_WORD
		tip.custom_minimum_size = Vector2(700, 0)
		feedback_container.add_child(tip)

		# Continue button
		var btn = Button.new()
		btn.text = "Continue →"
		btn.custom_minimum_size = Vector2(0, 48)
		_style_tile(btn, Color(0.2, 0.4, 0.8))
		btn.pressed.connect(_scenario_done)
		feedback_container.add_child(btn)
		btn.grab_focus.call_deferred()

func _scenario_done() -> void:
	# Disable buttons immediately to prevent double-click counter skips
	if feedback_container:
		for child in feedback_container.get_children():
			if child is Button:
				child.disabled = true
				
	if popup_panel:
		var tw = create_tween()
		tw.tween_property(popup_panel, "modulate:a", 0.0, 0.4)
		await tw.finished
	self.visible = false
	var passed = current_log.mitigate == true
	GameManager.mark_scenario_complete(passed)
	GameManager.is_movement_paused = false
	emit_signal("scenario_completed")

# ── Helper ────────────────────────────────────
func _style_tile(btn: Button, color: Color) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	for corner in ["corner_radius_top_left","corner_radius_top_right",
				   "corner_radius_bottom_left","corner_radius_bottom_right"]:
		style.set(corner, 8)
	for margin in ["content_margin_left","content_margin_right",
				   "content_margin_top","content_margin_bottom"]:
		style.set(margin, 10)
		
	# Add 3D pseudo-bevel (bottom edge)
	style.border_width_bottom = 4
	style.border_color = color.darkened(0.5)
	
	# Add subtle shadow
	style.shadow_color = Color(0, 0, 0, 0.4)
	style.shadow_size = 2
	style.shadow_offset = Vector2(0, 3)
	
	btn.add_theme_stylebox_override("normal", style)
	
	# Hover state: brighter, slight lift
	var hover_style = _brighter(style, 0.15)
	btn.add_theme_stylebox_override("hover", hover_style)
	
	# Pressed state: flatten the bevel to simulate physical clicking
	var pressed_style = style.duplicate()
	pressed_style.border_width_bottom = 0
	pressed_style.border_width_top = 4       # Shift border to top to mimic sinking
	pressed_style.border_color = Color(0,0,0,0) # Invisible top border purely for padding
	btn.add_theme_stylebox_override("pressed", pressed_style)
	
	# Focus state: to prevent default ugly borders when using arrows
	btn.add_theme_stylebox_override("focus", hover_style)
	
	btn.add_theme_color_override("font_color", Color.WHITE)

func _brighter(base: StyleBoxFlat, amount: float) -> StyleBoxFlat:
	var s = base.duplicate()
	s.bg_color = base.bg_color.lightened(amount)
	s.border_color = base.border_color.lightened(amount)
	return s
