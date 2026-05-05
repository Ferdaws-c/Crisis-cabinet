extends Control

var fade_rect: ColorRect
var scoreboard_panel: ColorRect

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
	
	# Connect Username input
	var user_input = find_child("UsernameInput", true, false)
	if user_input:
		user_input.text = GameManager.current_player_name
		user_input.text_changed.connect(_on_username_changed)
		
	# Connect Scoreboard button
	var sb_btn = find_child("ScoreboardButton", true, false)
	if sb_btn:
		sb_btn.pressed.connect(_on_scoreboard_pressed)
		
	_build_scoreboard_ui()
	
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
	if new_text.strip_edges() != "":
		GameManager.current_player_name = new_text.strip_edges()
	else:
		GameManager.current_player_name = "Guest"

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
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var list = VBoxContainer.new()
	list.name = "ScoreList"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	vbox.add_child(scroll)
	
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

func _on_scoreboard_pressed() -> void:
	scoreboard_panel.visible = true
	var list = scoreboard_panel.find_child("ScoreList", true, false)
	if list:
		for c in list.get_children():
			c.queue_free()
		
		var loading_label = Label.new()
		loading_label.text = "Loading global leaderboard from cloud..."
		loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		list.add_child(loading_label)
		
		# Fetch from SilentWolf
		await SilentWolf.Scores.get_scores().sw_get_scores_complete
		var scores = SilentWolf.Scores.scores
		
		if is_instance_valid(loading_label):
			loading_label.queue_free()
		
		if scores.size() == 0:
			var l = Label.new()
			l.text = "No scores recorded yet. Be the first!"
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			list.add_child(l)
		else:
			for i in range(scores.size()):
				var s = scores[i]
				var l = RichTextLabel.new()
				l.bbcode_enabled = true
				l.fit_content = true
				l.autowrap_mode = TextServer.AUTOWRAP_OFF
				
				var meta = s.get("metadata", {})
				var time_val = meta.get("time", 0.0) if typeof(meta) == TYPE_DICTIONARY else 0.0
				var mins = int(time_val / 60.0)
				var secs = int(time_val) % 60
				var time_str = "%02d:%02d" % [mins, secs]
				
				# Medal and colour for top 3
				var medal := ""
				var hex_color := "ffffff"
				match i:
					0:
						medal = "🥇 "
						hex_color = "FFD700"
					1:
						medal = "🥈 "
						hex_color = "C0C0C0"
					2:
						medal = "🥉 "
						hex_color = "CD7F32"
				
				var player_name = s.get("player_name", "Unknown")
				var diff = meta.get("diff", "Easy") if typeof(meta) == TYPE_DICTIONARY else "Easy"
				var budget = meta.get("budget", 0) if typeof(meta) == TYPE_DICTIONARY else 0
				var xp = meta.get("xp", 0) if typeof(meta) == TYPE_DICTIONARY else 0
				
				var rank_str := ""
				if i < 3:
					rank_str = "[color=#%s][b]%s#%d %s[/b][/color]" % [hex_color, medal, i+1, player_name]
				else:
					rank_str = "[b]#%d %s[/b]" % [i+1, player_name]
				
				l.text = "%s  [%s] — Score: %s | Time: %s | Budget: $%s | XP: %s" % [
					rank_str, diff, str(s.get("score", 0)),
					time_str, str(budget), str(xp)
				]
				
				list.add_child(l)
				list.add_child(HSeparator.new())
