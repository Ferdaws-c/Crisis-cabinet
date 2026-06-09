extends CanvasLayer

var _is_exiting: bool = false  # guard against double-press / mid-scroll crash

# Data snapshots — captured once in _ready, never accessed live during scroll
var _snap_minigame_scores: Array = []
var _snap_decision_log: Array = []
var _snap_total_time: float = 0.0

func _ready() -> void:
	self.layer = 120
	GameManager.is_movement_paused = true
	# ── Snapshot ALL GameManager data NOW, before anything else runs ──
	# This decouples the UI entirely from live autoload state so scrolling
	# can never race against a reset_game() call or any other mutation.
	_snap_total_time = GameManager.total_play_time
	_snap_minigame_scores.clear()
	for s in GameManager.minigame_scores:
		if s is Dictionary:
			_snap_minigame_scores.append(s.duplicate(true))
	_snap_decision_log.clear()
	for e in GameManager.decision_log:
		if e is Dictionary:
			_snap_decision_log.append(e.duplicate(true))
	_build_ui()

	# Create a solid loading overlay on top of the built UI
	var overlay = ColorRect.new()
	overlay.color = Color(0.02, 0.05, 0.1, 1.0) # Match background color
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	self.add_child(overlay)
	
	var loading_lbl = Label.new()
	loading_lbl.text = "Loading Performance Review..."
	loading_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	loading_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	loading_lbl.add_theme_font_size_override("font_size", 24)
	loading_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	overlay.add_child(loading_lbl)
	
	# Wait for the 2.0s buffer to complete before showing the page
	await get_tree().create_timer(2.0).timeout
	
	# Fade out the overlay to reveal the review page
	if is_instance_valid(overlay):
		var tw = create_tween()
		tw.tween_property(overlay, "color:a", 0.0, 0.5)
		await tw.finished
		if is_instance_valid(overlay):
			overlay.queue_free()

func _build_ui() -> void:
	var bg = ColorRect.new()
	bg.color = Color(0.02, 0.05, 0.1, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	self.add_child(bg)
	
	# ── Outer scroll so the whole page is scrollable on small screens ──
	var outer_scroll = ScrollContainer.new()
	outer_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	bg.add_child(outer_scroll)
	
	var main_margin = MarginContainer.new()
	main_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_margin.add_theme_constant_override("margin_top", 40)
	main_margin.add_theme_constant_override("margin_bottom", 40)
	main_margin.add_theme_constant_override("margin_left", 60)
	main_margin.add_theme_constant_override("margin_right", 60)
	outer_scroll.add_child(main_margin)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 30)
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_margin.add_child(main_vbox)
	
	var total_time = _snap_total_time
	var mins = int(total_time / 60.0)
	var secs = int(total_time) % 60
	
	var header_lbl = Label.new()
	header_lbl.text = "MISSION ACCOMPLISHED — CLEAR TIME: %02d:%02d" % [mins, secs]
	header_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_lbl.add_theme_font_size_override("font_size", 28)
	header_lbl.add_theme_color_override("font_color", Color(0.3, 0.9, 0.4))
	main_vbox.add_child(header_lbl)
	
	# === TOP ROW: Phase Accuracy | PMBOK Block ===
	var top_hbox = HBoxContainer.new()
	top_hbox.custom_minimum_size = Vector2(0, 250)
	top_hbox.add_theme_constant_override("separation", 30)
	main_vbox.add_child(top_hbox)
	
	# Phase Accuracy Panel
	var tusler_panel = PanelContainer.new()
	tusler_panel.custom_minimum_size = Vector2(300, 0)
	_apply_box_style(tusler_panel, Color(0.1, 0.15, 0.25))
	top_hbox.add_child(tusler_panel)
	
	var t_vbox = VBoxContainer.new()
	t_vbox.add_theme_constant_override("separation", 15)
	
	var t_header = Label.new()
	t_header.text = "Phase\nAccuracy"
	t_header.add_theme_font_size_override("font_size", 22)
	t_vbox.add_child(t_header)
	
	var t_grid = GridContainer.new()
	t_grid.columns = 2
	t_grid.add_theme_constant_override("h_separation", 10)
	t_grid.add_theme_constant_override("v_separation", 10)
	t_vbox.add_child(t_grid)
	
	t_grid.add_child(_create_phase_stat("🟢 PLANNING", "Planning", Color(0.2, 0.8, 0.3)))
	t_grid.add_child(_create_phase_stat("🟡 EXECUTING", "Executing", Color(0.9, 0.8, 0.2)))
	t_grid.add_child(_create_phase_stat("🟠 MONITORING", "Monitoring", Color(0.8, 0.4, 0.8)))
	t_grid.add_child(_create_phase_stat("🔵 CLOSING", "Closing", Color(0.2, 0.8, 0.9)))
	
	# PanelContainer auto-fills its child — use a MarginContainer for padding
	var t_margin = MarginContainer.new()
	t_margin.add_theme_constant_override("margin_left", 20)
	t_margin.add_theme_constant_override("margin_top", 20)
	t_margin.add_theme_constant_override("margin_right", 20)
	t_margin.add_theme_constant_override("margin_bottom", 20)
	t_margin.add_child(t_vbox)
	tusler_panel.add_child(t_margin)
	
	# PMBOK Text Block
	var info_panel = PanelContainer.new()
	info_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_box_style(info_panel, Color(0.1, 0.15, 0.25))
	top_hbox.add_child(info_panel)
	
	var info_vbox = VBoxContainer.new()
	info_vbox.add_theme_constant_override("separation", 15)
	var info_header = Label.new()
	info_header.text = "What This Game Teaches (PMBOK)"
	info_header.add_theme_font_size_override("font_size", 22)
	info_vbox.add_child(info_header)
	
	var text1 = "This simulation covers PMBOK Knowledge Area 11 - Project Risk Management. Processes practiced: 11.1 Plan Risk Management, 11.2 Identify Risks, 11.3 Perform Qualitative Risk Analysis (Tusler Matrix), 11.4 Perform Quantitative Risk Analysis, 11.5 Plan Risk Responses (Avoid/Mitigate/Transfer/Accept), 11.7 Monitor Risks."
	var text2 = "Learning objectives map to Bloom's Taxonomy levels: Apply (classification), Analyse (strategy selection), Evaluate (mitigation specificity). Reference: Marchewka, Information Technology Project Management 5e, Chapter 8."
	var info_body = Label.new()
	info_body.text = text1 + "\n\n" + text2
	info_body.autowrap_mode = TextServer.AUTOWRAP_WORD
	info_body.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	info_vbox.add_child(info_body)
	
	# PanelContainer auto-fills its child — use a MarginContainer for padding
	var info_margin = MarginContainer.new()
	info_margin.add_theme_constant_override("margin_left", 20)
	info_margin.add_theme_constant_override("margin_top", 20)
	info_margin.add_theme_constant_override("margin_right", 20)
	info_margin.add_theme_constant_override("margin_bottom", 20)
	info_margin.add_child(info_vbox)
	info_panel.add_child(info_margin)
	
	# === BOTTOM ROW: Decisions Log ===
	var log_panel = PanelContainer.new()
	_apply_box_style(log_panel, Color(0.1, 0.15, 0.25))
	main_vbox.add_child(log_panel)
	
	var log_vbox = VBoxContainer.new()
	log_vbox.add_theme_constant_override("separation", 20)
	
	var log_header = Label.new()
	log_header.text = "Decisions Log"
	log_header.add_theme_font_size_override("font_size", 22)
	log_vbox.add_child(log_header)
	
	# Header Row
	var trow = HBoxContainer.new()
	trow.add_child(_create_cell("Minigame", true, 2))
	trow.add_child(_create_cell("Status", true, 1))
	trow.add_child(_create_cell("Score", true, 1))
	trow.add_child(_create_cell("Time", true, 1))
	log_vbox.add_child(trow)
	
	var sep = HSeparator.new()
	sep.add_theme_constant_override("separation", 5)
	log_vbox.add_child(sep)
	
	# ── Decision log rows (no inner ScrollContainer — outer scroll handles it) ──
	var data_list = VBoxContainer.new()
	data_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	data_list.add_theme_constant_override("separation", 15)
	
	# Snapshot already captured in _ready — use it here (never reads GameManager live)
	var log_snapshot: Array = _snap_decision_log
	
	for entry in log_snapshot:
		var row = HBoxContainer.new()
		row.add_child(_create_cell(entry.get("title", "Unknown"), false, 2))
		
		var success: bool = bool(entry.get("is_success", false))
		var sc: int = int(entry.get("score", 0))
		var tt: float = float(entry.get("time_taken", 0.0))
		
		row.add_child(_create_status_cell(success))
		row.add_child(_create_cell(str(sc) + " pts", false, 1))
		
		var tt_lbl = _create_cell("%.1fs" % tt, false, 1)
		if tt < 5.0:
			tt_lbl.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))
		row.add_child(tt_lbl)
		
		data_list.add_child(row)
		data_list.add_child(HSeparator.new())
	
	log_vbox.add_child(data_list)

	# PanelContainer auto-fills its child — use a MarginContainer for padding
	var log_margin = MarginContainer.new()
	log_margin.add_theme_constant_override("margin_left", 20)
	log_margin.add_theme_constant_override("margin_top", 20)
	log_margin.add_theme_constant_override("margin_right", 20)
	log_margin.add_theme_constant_override("margin_bottom", 20)
	log_margin.add_child(log_vbox)
	log_panel.add_child(log_margin)
	
	# Continue Button
	var btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 20)
	
	var continue_btn = Button.new()
	continue_btn.text = "Finish Review & Roll Credits →"
	continue_btn.custom_minimum_size = Vector2(400, 60)
	continue_btn.add_theme_font_size_override("font_size", 22)
	
	var bs = StyleBoxFlat.new()
	bs.bg_color = Color(0.2, 0.4, 0.8)
	for c in ["corner_radius_top_left","corner_radius_top_right","corner_radius_bottom_left","corner_radius_bottom_right"]:
		bs.set(c, 8)
	continue_btn.add_theme_stylebox_override("normal", bs)
	continue_btn.pressed.connect(_on_continue_pressed)
	btn_row.add_child(continue_btn)
	
	var export_gpaf_btn = Button.new()
	export_gpaf_btn.text = "📥 Export GPAF JSONL Logs"
	export_gpaf_btn.custom_minimum_size = Vector2(300, 60)
	export_gpaf_btn.add_theme_font_size_override("font_size", 20)
	
	var export_style = StyleBoxFlat.new()
	export_style.bg_color = Color(0.15, 0.45, 0.25)
	for c in ["corner_radius_top_left","corner_radius_top_right","corner_radius_bottom_left","corner_radius_bottom_right"]:
		export_style.set(c, 8)
	export_gpaf_btn.add_theme_stylebox_override("normal", export_style)
	export_gpaf_btn.pressed.connect(func():
		GPAFLogger.export_logs_to_file(self)
	)
	btn_row.add_child(export_gpaf_btn)
	
	main_vbox.add_child(btn_row)

func _create_phase_stat(title: String, phase_key: String, col: Color) -> PanelContainer:
	var phase_scores = {"Planning": {"c":0,"t":0}, "Executing": {"c":0,"t":0}, "Monitoring": {"c":0,"t":0}, "Closing": {"c":0,"t":0}}
	# Use snapshot — never reads GameManager.minigame_scores live
	for s in _snap_minigame_scores:
		var pid = "Planning"
		var s_id = str(s.get("id", ""))
		if s_id in ["MG04", "MG05", "MG06"]: pid = "Executing"
		elif s_id in ["MG07", "MG08", "MG09"]: pid = "Monitoring"
		elif s_id in ["MG10", "MG11", "MG12"]: pid = "Closing"
		phase_scores[pid]["t"] += 1
		if int(s.get("score", 0)) > 0:
			phase_scores[pid]["c"] += 1
	
	var p = PanelContainer.new()
	p.custom_minimum_size = Vector2(120, 80)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.05, 0.05, 0.5)
	sb.border_width_left = 2; sb.border_width_top = 2
	sb.border_width_right = 2; sb.border_width_bottom = 2
	sb.border_color = col
	sb.corner_radius_top_left = 6; sb.corner_radius_bottom_right = 6
	p.add_theme_stylebox_override("panel", sb)
	
	var v = VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var label = Label.new()
	label.text = title
	label.add_theme_color_override("font_color", col)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(label)
	
	var stats = phase_scores[phase_key]
	var c = stats.get("c", 0)
	var t = stats.get("t", 0)
	var perc = 0
	if t > 0: perc = int((float(c) / float(t)) * 100.0)
	
	var nums = Label.new()
	nums.text = "%d/%d (%d%%)" % [c, t, perc]
	nums.add_theme_color_override("font_color", col if perc < 100 else Color(0.3, 0.9, 0.3))
	nums.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(nums)
	
	p.add_child(v)
	return p

func _create_cell(txt: String, is_bold: bool, size_mut: int) -> Label:
	var l = Label.new()
	l.text = txt
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.size_flags_stretch_ratio = size_mut
	return l

func _create_status_cell(is_correct: bool) -> Label:
	var l = Label.new()
	l.text = "Correct" if is_correct else "Failed"
	l.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2) if is_correct else Color(0.9, 0.2, 0.2))
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.size_flags_stretch_ratio = 1
	return l

func _apply_box_style(panel: PanelContainer, color: Color) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left = 2; style.border_width_top = 2
	style.border_width_right = 2; style.border_width_bottom = 2
	style.border_color = Color(0.2, 0.3, 0.4)
	panel.add_theme_stylebox_override("panel", style)

func _on_continue_pressed() -> void:
	# Guard: ignore if already in progress
	if _is_exiting:
		return
	_is_exiting = true
	
	# Change scene FIRST — then reset GameManager data on the next idle frame
	# so no live nodes are accessing wiped arrays during this frame.
	get_tree().change_scene_to_file("res://scenes/ui/Credits.tscn")
	# Defer the reset so it runs after the scene swap is fully committed
	GameManager.call_deferred("reset_game", true)
