extends Control

var fade_rect: ColorRect
var scoreboard_panel: ColorRect
var logs_panel: ColorRect
var logs_text: RichTextLabel
var input_buffer: Array = []

func _ready() -> void:
	# Ensure GameManager is perfectly clean when the menu loads
	GameManager.reset_game(true)
	
	# Connect Play button
	var play = find_child("PlayButton", true, false)
	if play:
		play.pressed.connect(_on_play_pressed)
	
	# Connect Difficulty buttons
	for diff in ["Easy", "Medium", "Hard"]:
		var btn = find_child(diff + "Button", true, false)
		if btn:
			btn.pressed.connect(_on_diff_selected.bind(diff))
	
	# Force initial visual highlight
	_update_button_colors("Easy")
	
	# Add Randomizer CheckButton
	var easy_btn = find_child("EasyButton", true, false)
	if easy_btn:
		var parent_hbox = easy_btn.get_parent()
		var parent_vbox = parent_hbox.get_parent()
		var rand_btn = CheckButton.new()
		rand_btn.name = "RandomizerCheck"
		rand_btn.text = "🎲 Randomizer Mode (Offline Scores Only)"
		rand_btn.add_theme_font_size_override("font_size", 16)
		rand_btn.button_pressed = GameManager.randomizer_mode
		rand_btn.toggled.connect(func(toggled_on): GameManager.randomizer_mode = toggled_on)
		parent_vbox.add_child(rand_btn)
		parent_vbox.move_child(rand_btn, parent_hbox.get_index() + 1)
	
	# Connect Username input
	var user_input = find_child("UsernameInput", true, false)
	if user_input:
		if GameManager.current_player_name == "Guest":
			GameManager.current_player_name = ""
		user_input.text = GameManager.current_player_name
		user_input.placeholder_text = "Enter your name"
		user_input.text_changed.connect(_on_username_changed)
		
	# Connect Scoreboard button
	var sb_btn = find_child("ScoreboardButton", true, false)
	if sb_btn:
		sb_btn.pressed.connect(_on_scoreboard_pressed)
		
	_build_scoreboard_ui()
	_build_logs_ui()
	
	# Procedurally create a solid black cinematic overlay
	fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 1.0) # Start pitch black
	fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE # Allow clicking through it
	fade_rect.z_index = 4096 # Guarantee it sits on top of all menu art
	self.add_child(fade_rect)
	
	# Fade IN
	var tw = create_tween()
	tw.tween_property(fade_rect, "color:a", 0.0, 1.0) # Fade to transparent over 1 second

func _on_play_pressed() -> void:
	if GameManager.current_player_name.strip_edges() == "":
		var user_input = find_child("UsernameInput", true, false)
		if user_input:
			user_input.text = ""
			user_input.placeholder_text = "REQUIRED: PLEASE ENTER NAME"
			user_input.grab_focus()
		return
		
	# Block button mashing while fading
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Fade OUT to black
	var tw = create_tween()
	tw.tween_property(fade_rect, "color:a", 1.0, 1.0)
	await tw.finished
	
	# Keep the selected difficulty, just ensure health/budget are maxed out
	GameManager.reset_game(false)
	# IMPORTANT: Make sure this path matches exactly where your Main map is saved!
	get_tree().change_scene_to_file("res://scenes/levels/MainFacility.tscn")

func _on_diff_selected(level: String) -> void:
	GameManager.set_difficulty(level)
	_update_button_colors(level)

func _update_button_colors(active_level: String) -> void:
	for diff in ["Easy", "Medium", "Hard"]:
		var btn = find_child(diff + "Button", true, false)
		if btn:
			# Dim deselected buttons, brighten the active one
			if diff == active_level:
				btn.modulate = Color(1.0, 1.0, 1.0, 1.0) # Full brightness
			else:
				btn.modulate = Color(0.4, 0.4, 0.4, 1.0) # Dimmed out

func _on_username_changed(new_text: String) -> void:
	GameManager.current_player_name = new_text.strip_edges()

func _build_scoreboard_ui() -> void:
	scoreboard_panel = ColorRect.new()
	scoreboard_panel.color = Color(0, 0, 0, 0.8)
	scoreboard_panel.visible = false
	scoreboard_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scoreboard_panel.z_index = 100
	
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(950, 500)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.95)
	style.border_width_left = 4; style.border_width_top = 4
	style.border_width_right = 4; style.border_width_bottom = 4
	style.border_color = Color(0.3, 0.5, 0.8)
	style.corner_radius_top_left = 8; style.corner_radius_bottom_right = 8
	style.content_margin_left = 20; style.content_margin_top = 20
	style.content_margin_right = 20; style.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	
	var title = Label.new()
	title.text = "🏆 TOP 10 SCORES 🏆"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)
	
	vbox.add_child(HSeparator.new())
	
	var tabs = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Local Tab
	var local_tab = VBoxContainer.new()
	local_tab.name = "Local Scores"
	var local_scroll = ScrollContainer.new()
	local_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var local_list = VBoxContainer.new()
	local_list.name = "LocalScoreList"
	local_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	local_scroll.add_child(local_list)
	local_tab.add_child(local_scroll)
	
	var clear_btn = Button.new()
	clear_btn.text = "🗑 CLEAR LOCAL LEADERBOARD"
	clear_btn.custom_minimum_size = Vector2(0, 40)
	clear_btn.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	clear_btn.pressed.connect(func():
		var f = FileAccess.open("user://scoreboard.json", FileAccess.WRITE)
		f.store_string("[]")
		f.close()
		_populate_local_scores()
	)
	local_tab.add_child(clear_btn)
	tabs.add_child(local_tab)
	
	# Global Tab
	var global_tab = VBoxContainer.new()
	global_tab.name = "Global Scores"
	var global_scroll = ScrollContainer.new()
	global_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var global_list = VBoxContainer.new()
	global_list.name = "GlobalScoreList"
	global_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	global_scroll.add_child(global_list)
	global_tab.add_child(global_scroll)
	tabs.add_child(global_tab)
	
	vbox.add_child(tabs)
	
	vbox.add_child(HSeparator.new())

	var close_btn = Button.new()
	close_btn.text = "CLOSE SCOREBOARD"
	close_btn.custom_minimum_size = Vector2(0, 50)
	close_btn.pressed.connect(func(): scoreboard_panel.visible = false)
	vbox.add_child(close_btn)
	
	panel.add_child(vbox)
	center.add_child(panel)
	scoreboard_panel.add_child(center)
	self.add_child(scoreboard_panel)
	
	# Dynamically fetch global scores only when clicking its tab
	tabs.tab_changed.connect(func(tab_idx):
		if tab_idx == 1:
			_populate_global_scores()
	)

func _on_scoreboard_pressed() -> void:
	scoreboard_panel.visible = true
	var tabs = scoreboard_panel.find_child("TabContainer", true, false)
	if tabs:
		tabs.current_tab = 0 # Default to Local
	_populate_local_scores()

func _create_score_row(i: int, player_name: String, score: int, diff: String, time_val: float, budget: int, xp: int, date: String, log_data: Array) -> Control:
	var hbox = HBoxContainer.new()
	var l = RichTextLabel.new()
	l.bbcode_enabled = true
	l.fit_content = true
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var mins = int(time_val / 60.0)
	var secs = int(time_val) % 60
	var time_str = "%02d:%02d" % [mins, secs]
	
	var medal := ""
	var hex_color := "ffffff"
	match i:
		0: medal = "🥇 "; hex_color = "FFD700"
		1: medal = "🥈 "; hex_color = "C0C0C0"
		2: medal = "🥉 "; hex_color = "CD7F32"
	
	var rank_str := ""
	if i < 3:
		rank_str = "[color=#%s][b]%s#%d %s[/b][/color]" % [hex_color, medal, i+1, player_name]
	else:
		rank_str = "[b]#%d %s[/b]" % [i+1, player_name]
	
	var date_part = (" | " + date) if date != "" else ""
	l.text = "%s  [%s] — Score: %s | Time: %s | Budget: $%s | Pts: %s%s" % [
		rank_str, diff, str(score), time_str, str(budget), str(xp), date_part
	]
	hbox.add_child(l)
	
	var btn = Button.new()
	btn.text = "🔍 VIEW LOGS"
	btn.custom_minimum_size = Vector2(150, 0)
	btn.pressed.connect(func(): _show_player_logs(player_name, log_data))
	hbox.add_child(btn)
	
	var export_btn = Button.new()
	export_btn.text = "📥 EXPORT LOGS"
	export_btn.custom_minimum_size = Vector2(150, 0)
	export_btn.pressed.connect(func(): _show_export_format_selection(player_name, log_data))
	hbox.add_child(export_btn)
	
	if log_data.size() == 0:
		btn.disabled = true
		export_btn.disabled = true
	
	return hbox

func _populate_local_scores() -> void:
	var list = scoreboard_panel.find_child("LocalScoreList", true, false)
	if not list: return
	for c in list.get_children(): c.queue_free()
	
	var scores = GameManager.get_high_scores()
	if scores.size() == 0:
		var l = Label.new()
		l.text = "No local scores recorded yet."
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		list.add_child(l)
	else:
		for i in range(scores.size()):
			var s = scores[i]
			var log_data = s.get("log", [])
			var date = s.get("date", "")
			var l = _create_score_row(i, s.get("name", "Unknown"), s.get("score", 0), s.get("diff", "Easy"), s.get("time", 0.0), s.get("budget", 0), s.get("xp", 0), date, log_data)
			list.add_child(l)
			list.add_child(HSeparator.new())

func _populate_global_scores() -> void:
	var list = scoreboard_panel.find_child("GlobalScoreList", true, false)
	if not list: return
	for c in list.get_children(): c.queue_free()
	
	var loading = Label.new()
	loading.text = "Loading global leaderboard from cloud..."
	loading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	list.add_child(loading)
	
	await SilentWolf.Scores.get_scores().sw_get_scores_complete
	var scores = SilentWolf.Scores.scores
	
	if is_instance_valid(loading):
		loading.queue_free()
		
	if scores.size() == 0:
		var l = Label.new()
		l.text = "No global scores recorded yet. Be the first!"
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		list.add_child(l)
	else:
		for i in range(scores.size()):
			var s = scores[i]
			var meta = s.get("metadata", {})
			var time_val = meta.get("time", 0.0) if typeof(meta) == TYPE_DICTIONARY else 0.0
			var budget = meta.get("budget", 0) if typeof(meta) == TYPE_DICTIONARY else 0
			var xp = meta.get("xp", 0) if typeof(meta) == TYPE_DICTIONARY else 0
			var diff = meta.get("diff", "Easy") if typeof(meta) == TYPE_DICTIONARY else "Easy"
			var pname = s.get("player_name", "Unknown")
			var log_data = meta.get("log", []) if typeof(meta) == TYPE_DICTIONARY else []
			var date = meta.get("date", "") if typeof(meta) == TYPE_DICTIONARY else ""
			
			var l = _create_score_row(i, pname, s.get("score", 0), diff, time_val, budget, xp, date, log_data)
			list.add_child(l)
			list.add_child(HSeparator.new())

func _build_logs_ui() -> void:
	logs_panel = ColorRect.new()
	logs_panel.color = Color(0, 0, 0, 0.95)
	logs_panel.visible = false
	logs_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	logs_panel.z_index = 200
	
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(800, 600)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.95)
	style.border_width_left = 4; style.border_width_top = 4
	style.border_width_right = 4; style.border_width_bottom = 4
	style.border_color = Color(0.8, 0.5, 0.1)
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	
	var title = Label.new()
	title.text = "📖 DECISION LOGS 📖"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)
	vbox.add_child(HSeparator.new())
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	logs_text = RichTextLabel.new()
	logs_text.bbcode_enabled = true
	logs_text.fit_content = true
	logs_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(logs_text)
	vbox.add_child(scroll)
	
	vbox.add_child(HSeparator.new())
	var close_btn = Button.new()
	close_btn.text = "CLOSE LOGS"
	close_btn.custom_minimum_size = Vector2(0, 50)
	close_btn.pressed.connect(func(): logs_panel.visible = false)
	vbox.add_child(close_btn)
	
	panel.add_child(vbox)
	center.add_child(panel)
	logs_panel.add_child(center)
	self.add_child(logs_panel)

func _show_player_logs(player_name: String, log_data: Array) -> void:
	logs_panel.visible = true
	var bbcode = "[center][b]Logs for Player: %s[/b][/center]\n\n" % player_name
	
	if log_data.size() == 0:
		bbcode += "[center][color=gray]No logs available for this run.[/color][/center]"
	else:
		for i in range(log_data.size()):
			var entry = log_data[i]
			var sc_name = entry.get("title", "Unknown Scenario")
			var score = entry.get("score", 0)
			var time_taken = entry.get("time_taken", 0.0)
			var success = entry.get("is_success", false)
			
			var game_time = entry.get("game_time", -1.0)
			var real_time = entry.get("real_time", "")
			
			var time_info = ""
			if game_time >= 0.0:
				var mins = int(game_time / 60.0)
				var secs = int(game_time) % 60
				time_info = " [color=gray](%02d:%02d)[/color]" % [mins, secs]
			
			var date_info = ""
			if real_time != "":
				date_info = "\n  Date: [color=darkgray]%s[/color]" % real_time
				
			var s_icon = "✔" if success else "❌"
			var s_col = "green" if success else "red"
			
			bbcode += "[b]Scenario %d[/b]%s[b]:[/b] %s\n" % [i+1, time_info, sc_name]
			bbcode += "  Status: [color=%s]%s %s[/color]\n" % [s_col, s_icon, "Completed" if success else "Failed"]
			bbcode += "  Score: %d pts\n" % score
			if time_taken < 5.0:
				bbcode += "  Time Taken: [color=red]%.1fs (Failed: Too fast!)[/color]%s\n\n" % [time_taken, date_info]
			else:
				bbcode += "  Time Taken: %.1fs%s\n\n" % [time_taken, date_info]
			
	logs_text.text = bbcode

func _export_player_logs(player_name: String, log_data: Array) -> void:
	var fd = FileDialog.new()
	fd.title = "Export Logs for Player: %s" % player_name
	fd.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	fd.access = FileDialog.ACCESS_FILESYSTEM
	fd.filters = PackedStringArray(["*.json ; JSON Files"])
	
	# Sanitize filename
	var safe_name = player_name.to_lower().replace(" ", "_")
	var regex = RegEx.new()
	regex.compile("[^a-zA-Z0-9_]")
	safe_name = regex.sub(safe_name, "", true)
	if safe_name == "":
		safe_name = "player"
		
	fd.current_file = "crisis_cabinet_logs_%s.json" % safe_name
	fd.use_native_dialog = true
	
	add_child(fd)
	
	fd.file_selected.connect(func(path: String):
		var file = FileAccess.open(path, FileAccess.WRITE)
		if file:
			var json_string = JSON.stringify(log_data, "\t")
			file.store_string(json_string)
			file.close()
		fd.queue_free()
	)
	
	fd.canceled.connect(func():
		fd.queue_free()
	)
	
	fd.popup_centered(Vector2i(800, 600))

func _show_export_format_selection(player_name: String, log_data: Array) -> void:
	# Build a choice popup overlay
	var choice_overlay = ColorRect.new()
	choice_overlay.color = Color(0, 0, 0, 0.7)
	choice_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	choice_overlay.z_index = 300 # Above scoreboard
	
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	choice_overlay.add_child(center)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(400, 200)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.12, 0.95)
	style.border_width_left = 3; style.border_width_top = 3
	style.border_width_right = 3; style.border_width_bottom = 3
	style.border_color = Color(0.3, 0.5, 0.8)
	style.corner_radius_top_left = 8; style.corner_radius_bottom_right = 8
	style.content_margin_left = 20; style.content_margin_top = 20
	style.content_margin_right = 20; style.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "Select Export Format for:\n" + player_name
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title)
	
	vbox.add_child(HSeparator.new())
	
	var btn_json = Button.new()
	btn_json.text = "📄 User Logs (JSON)"
	btn_json.custom_minimum_size = Vector2(0, 45)
	btn_json.pressed.connect(func():
		choice_overlay.queue_free()
		_export_player_logs(player_name, log_data)
	)
	vbox.add_child(btn_json)
	
	var btn_jsonl = Button.new()
	btn_jsonl.text = "📥 GPAF Event Logs (JSONL)"
	btn_jsonl.custom_minimum_size = Vector2(0, 45)
	btn_jsonl.pressed.connect(func():
		choice_overlay.queue_free()
		_export_player_logs_jsonl(player_name, log_data)
	)
	vbox.add_child(btn_jsonl)
	
	var btn_cancel = Button.new()
	btn_cancel.text = "Cancel"
	btn_cancel.custom_minimum_size = Vector2(0, 35)
	btn_cancel.pressed.connect(func():
		choice_overlay.queue_free()
	)
	vbox.add_child(btn_cancel)
	
	add_child(choice_overlay)

func _export_player_logs_jsonl(player_name: String, log_data: Array) -> void:
	var fd = FileDialog.new()
	fd.title = "Export GPAF JSONL Logs for Player: %s" % player_name
	fd.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	fd.access = FileDialog.ACCESS_FILESYSTEM
	fd.filters = PackedStringArray(["*.jsonl ; JSON Lines Files"])
	
	# Sanitize filename
	var safe_name = player_name.to_lower().replace(" ", "_")
	var regex = RegEx.new()
	regex.compile("[^a-zA-Z0-9_]")
	safe_name = regex.sub(safe_name, "", true)
	if safe_name == "":
		safe_name = "player"
		
	fd.current_file = "gpaf_logs_%s.jsonl" % safe_name
	fd.use_native_dialog = true
	
	add_child(fd)
	
	fd.file_selected.connect(func(path: String):
		var file = FileAccess.open(path, FileAccess.WRITE)
		if file:
			file.store_string(reconstruct_gpaf_jsonl(player_name, log_data))
			file.close()
		fd.queue_free()
	)
	
	fd.canceled.connect(func():
		fd.queue_free()
	)
	
	fd.popup_centered(Vector2i(800, 600))

func reconstruct_gpaf_jsonl(player_name: String, log_data: Array) -> String:
	var lines = []
	var pseudo_id = "p_" + player_name.to_lower().replace(" ", "_")
	var regex = RegEx.new()
	regex.compile("[^a-zA-Z0-9_]")
	pseudo_id = regex.sub(pseudo_id, "", true)
	if pseudo_id == "p_":
		pseudo_id = "p_unknown"
		
	var session_id = "s_reconstructed"
	var game_id = "GM-CrisisCabinetV2"
	
	# Helper to format ISO-8601 UTC timestamp
	var format_ts = func(real_time_str: String) -> String:
		if real_time_str != "" and real_time_str.length() >= 19:
			return real_time_str.replace(" ", "T") + "Z"
		return Time.get_datetime_string_from_system(true) + "Z"

	# 1. session_start
	var start_ts = format_ts.call(log_data[0].get("real_time", "")) if log_data.size() > 0 else Time.get_datetime_string_from_system(true) + "Z"
	lines.append(JSON.stringify({
		"ts": start_ts,
		"playerPseudoId": pseudo_id,
		"sessionId": session_id,
		"gameId": game_id,
		"eventType": "session_start",
		"payload": {}
	}))
	
	# 2. Iterate through minigames
	var cumulative_score = 0
	for i in range(log_data.size()):
		var entry = log_data[i]
		var ts = format_ts.call(entry.get("real_time", ""))
		cumulative_score += int(entry.get("score", 0))
		
		# level_complete
		lines.append(JSON.stringify({
			"ts": ts,
			"playerPseudoId": pseudo_id,
			"sessionId": session_id,
			"gameId": game_id,
			"eventType": "level_complete",
			"payload": { "level": i + 1 }
		}))
		
		# score_update
		lines.append(JSON.stringify({
			"ts": ts,
			"playerPseudoId": pseudo_id,
			"sessionId": session_id,
			"gameId": game_id,
			"eventType": "score_update",
			"payload": { "score": cumulative_score }
		}))
		
	# 3. session_end
	var end_ts = format_ts.call(log_data[-1].get("real_time", "")) if log_data.size() > 0 else Time.get_datetime_string_from_system(true) + "Z"
	lines.append(JSON.stringify({
		"ts": end_ts,
		"playerPseudoId": pseudo_id,
		"sessionId": session_id,
		"gameId": game_id,
		"eventType": "session_end",
		"payload": { "completed": true }
	}))
	
	return "\n".join(lines)

func _unhandled_input(event: InputEvent) -> void:
	if not scoreboard_panel or not scoreboard_panel.visible:
		return
		
	if event is InputEventKey and event.pressed and not event.echo:
		var key_str = OS.get_keycode_string(event.keycode).to_upper()
		input_buffer.append(key_str)
		if input_buffer.size() > 3:
			input_buffer.pop_front()
			
		if input_buffer == ["D", "E", "L"]:
			input_buffer.clear()
			_wipe_global_database()

func _wipe_global_database() -> void:
	var list = scoreboard_panel.find_child("GlobalScoreList", true, false)
	if list:
		for c in list.get_children(): c.queue_free()
		var loading = Label.new()
		loading.text = "⚠️ WIPING GLOBAL LEADERBOARD... ⚠️"
		loading.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		loading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		list.add_child(loading)
		
	await SilentWolf.Scores.wipe_leaderboard("main").sw_wipe_leaderboard_complete
	_populate_global_scores()
