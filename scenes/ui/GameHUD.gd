extends CanvasLayer

var minimap_cam: Camera2D
var minimap_marker: Panel
var project_board: PanelContainer

var log_list: VBoxContainer
var acc_labels: Dictionary = {}
var global_prompt: Label

@onready var hp_label = find_child("HPValue", true, false)
@onready var budget_label = find_child("BudgetValue", true, false)
@onready var streak_label = find_child("StreakValue", true, false)
@onready var phase_label = find_child("PhaseValue", true, false)
@onready var xp_label = find_child("XPValue", true, false)

func _ready() -> void:
	add_to_group("hud")
	if hp_label: hp_label.show()
	GameManager.connect("state_changed", Callable(self, "_on_state_changed"))
	_build_project_board()
	_update_ui()
	
	# Procedurally build the Minimap to track the player
	var mm_panel = PanelContainer.new()
	mm_panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	mm_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	mm_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	mm_panel.offset_right = -30
	mm_panel.offset_bottom = -30
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	style.border_width_left = 3; style.border_width_top = 3
	style.border_width_right = 3; style.border_width_bottom = 3
	style.border_color = Color.BLACK
	mm_panel.add_theme_stylebox_override("panel", style)
	
	var mm_sub = SubViewportContainer.new()
	mm_sub.custom_minimum_size = Vector2(240, 240)
	mm_sub.stretch = true # Force the viewport to fill the red box
	
	var viewport = SubViewport.new()
	viewport.transparent_bg = true
	
	# CRITICAL: Tell the minimap to render the SAME physical world the player is standing in!
	viewport.world_2d = self.get_viewport().world_2d
	
	minimap_cam = Camera2D.new()
	minimap_cam.zoom = Vector2(0.6, 0.6) # Zoomed in much closer!
	
	viewport.add_child(minimap_cam)
	mm_sub.add_child(viewport)
	mm_panel.add_child(mm_sub)
	
	# Create the mathematically isolated objective marker
	minimap_marker = Panel.new()
	minimap_marker.size = Vector2(16, 16) # Much bolder size
	minimap_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var marker_style = StyleBoxFlat.new()
	marker_style.bg_color = Color(1.0, 0.1, 0.1, 1.0) # Bright red
	marker_style.border_color = Color(1.0, 0.9, 0.2, 1.0) # Bold yellow border
	marker_style.border_width_left = 2; marker_style.border_width_top = 2
	marker_style.border_width_right = 2; marker_style.border_width_bottom = 2
	for c in ["corner_radius_top_left","corner_radius_top_right","corner_radius_bottom_left","corner_radius_bottom_right"]:
		marker_style.set(c, 16) # Perfectly circular
	minimap_marker.add_theme_stylebox_override("panel", marker_style)
	
	var pulse = create_tween().set_loops()
	pulse.tween_property(minimap_marker, "modulate:a", 0.2, 0.4)
	pulse.tween_property(minimap_marker, "modulate:a", 1.0, 0.2)
	
	# Godot 4 Layout Fix: A pure Control will block the PanelContainer from violently stretching the 8x8 circle!
	var marker_canvas = Control.new()
	marker_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker_canvas.add_child(minimap_marker)
	mm_panel.add_child(marker_canvas)
	
	self.add_child(mm_panel)
	
	# Procedural Interaction Prompt
	global_prompt = Label.new()
	global_prompt.text = "PRESS [ SPACE ] TO INTERACT"
	global_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	global_prompt.add_theme_font_size_override("font_size", 16)
	global_prompt.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2)) # High visibility yellow
	
	var pb = StyleBoxFlat.new()
	pb.bg_color = Color(0.05, 0.05, 0.1, 0.9)
	pb.border_color = Color(0.3, 0.6, 1.0, 0.8)
	pb.border_width_left = 2; pb.border_width_top = 2
	pb.border_width_right = 2; pb.border_width_bottom = 2
	pb.set_corner_radius_all(6)
	pb.content_margin_left = 20
	pb.content_margin_right = 20
	pb.content_margin_top = 10
	pb.content_margin_bottom = 10
	global_prompt.add_theme_stylebox_override("normal", pb)
	
	global_prompt.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	global_prompt.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	global_prompt.grow_vertical = Control.GROW_DIRECTION_BEGIN
	global_prompt.offset_right = -30
	global_prompt.offset_bottom = -285 # Just above the 240px minimap + 30px offset
	global_prompt.hide()
	
	self.add_child(global_prompt)
	
	# Procedurally create a solid black cinematic overlay that fades away
	var fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 1.0) # Start pitch black
	fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.z_index = 4096
	self.add_child(fade_rect)
	
	# Fade IN
	var tw = create_tween()
	tw.tween_property(fade_rect, "color:a", 0.0, 1.0)
	
	# Clean up memory after fade
	tw.finished.connect(func(): fade_rect.queue_free())

func _process(_delta: float) -> void:
	if project_board:
		project_board.visible = not GameManager.is_movement_paused
		
	# Pause Menu Trigger (Escape Key)
	if Input.is_action_just_pressed("ui_cancel"):
		var p_menu = get_tree().root.find_child("PauseMenu", true, false)
		if p_menu:
			if p_menu.visible:
				p_menu.hide_pause()
			else:
				# Only pause if not already blocked by Info/Scenario popups!
				if not GameManager.is_movement_paused or (p_menu.visible == false and GameManager.is_movement_paused == false):
					p_menu.show_pause()
	
	if minimap_cam:
		var player = get_tree().root.find_child("Player", true, false)
		if player:
			minimap_cam.global_position = player.global_position
			
			if minimap_marker:
				var target_name = ""
				var completed = GameManager.scenarios_completed
				
				# Waterfall progression sequence
				if not GameManager.has_read_info:
					target_name = "InfoTrigger"
				elif GameManager.current_phase == "Planning":
					target_name = "RiskRoom"
				elif GameManager.current_phase == "Executing":
					target_name = "RiskRoom2"
				elif GameManager.current_phase == "Monitoring":
					target_name = "RiskRoom3"
				elif GameManager.current_phase == "Closing":
					var max_s = 12
					if GameManager.current_difficulty == "Easy": max_s = 4
					elif GameManager.current_difficulty == "Medium": max_s = 8
					
					if completed >= max_s:
						target_name = "CeoTrigger"
					else:
						target_name = "RiskRoom4"
				else:
					target_name = "CeoTrigger"
				
				var target_node = get_tree().root.find_child(target_name, true, false)
				if target_node:
					# Map Real Space -> UI Space
					var world_offset = target_node.global_position - player.global_position
					var ui_offset = world_offset * minimap_cam.zoom.x
					var map_center = Vector2(120, 120) - Vector2(8, 8) # 240/2 minus half-size
					
					var raw_pos = map_center + ui_offset
					
					# Clamp to screen boundary safely
					raw_pos.x = clamp(raw_pos.x, 8, 216)
					raw_pos.y = clamp(raw_pos.y, 8, 216)
					
					minimap_marker.position = raw_pos
					minimap_marker.show()
				else:
					minimap_marker.hide()

func _on_state_changed() -> void:
	_update_ui()

func show_interaction_prompt(show: bool) -> void:
	if global_prompt:
		global_prompt.visible = show

func _update_ui() -> void:
	if hp_label: hp_label.text = str(GameManager.schedule_days) + " Days Left ⏱️"
	if budget_label: budget_label.text = "$" + str(GameManager.budget) + " 💰"
	if streak_label: streak_label.text = str(GameManager.streak) + " / 12 🔥"
	if xp_label: xp_label.text = str(GameManager.xp_score) + " XP ✨"
	
	if phase_label: 
		phase_label.text = GameManager.current_phase.to_upper()
		
		# Set distinct color per phase
		if GameManager.current_phase == "Planning":
			phase_label.modulate = Color(0.2, 0.8, 0.3) # Green
		elif GameManager.current_phase == "Executing":
			phase_label.modulate = Color(0.9, 0.2, 0.2) # Red
		elif GameManager.current_phase == "Monitoring":
			phase_label.modulate = Color(0.6, 0.2, 0.9) # Purple
		elif GameManager.current_phase == "Closing":
			phase_label.modulate = Color(0.2, 0.8, 0.9) # Cyan
		else:
			phase_label.modulate = Color(1.0, 1.0, 1.0)
	
	# Update Project Board
	if acc_labels.has("tiger"):
		acc_labels["tiger"].text = "🐯 %d / %d" % [GameManager.stats_tiger.c, GameManager.stats_tiger.t]
		acc_labels["alligator"].text = "🐊 %d / %d" % [GameManager.stats_alligator.c, GameManager.stats_alligator.t]
		acc_labels["puppy"].text = "🐶 %d / %d" % [GameManager.stats_puppy.c, GameManager.stats_puppy.t]
		acc_labels["kitten"].text = "🐱 %d / %d" % [GameManager.stats_kitten.c, GameManager.stats_kitten.t]

func log_risk_decision(risk_title: String, strategy: String, is_correct: bool) -> void:
	if not log_list: return
	var entry = Label.new()
	entry.text = "- " + risk_title + " (" + strategy + ")"
	entry.add_theme_font_size_override("font_size", 12)
	entry.add_theme_color_override("font_color", Color(0.2, 0.9, 0.2) if is_correct else Color(0.9, 0.2, 0.2))
	entry.autowrap_mode = TextServer.AUTOWRAP_WORD
	log_list.add_child(entry)

func _build_project_board() -> void:
	project_board = PanelContainer.new()
	var pb = project_board
	pb.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	pb.offset_top = 60
	pb.offset_bottom = -290
	pb.offset_left = 30
	pb.custom_minimum_size = Vector2(246, 0)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.12, 0.9)
	style.border_width_left = 2; style.border_width_right = 2
	style.border_width_top = 2; style.border_width_bottom = 2
	style.border_color = Color(0.2, 0.4, 0.6, 0.5)
	style.corner_radius_top_left = 8; style.corner_radius_bottom_right = 8
	style.content_margin_left = 15; style.content_margin_right = 15
	style.content_margin_top = 15; style.content_margin_bottom = 15
	pb.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	
	var title = Label.new()
	title.text = "PROJECT BOARD"
	title.add_theme_color_override("font_color", Color(0.0, 0.8, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	vbox.add_child(HSeparator.new())
	
	# Process Flow
	var pf_title = Label.new()
	pf_title.text = "PROCESS FLOW"
	pf_title.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	vbox.add_child(pf_title)
	
	var pf_sep = HSeparator.new()
	var pf_style = StyleBoxLine.new()
	pf_style.color = Color(0.3, 0.3, 0.3)
	pf_style.thickness = 4
	pf_sep.add_theme_stylebox_override("separator", pf_style)
	vbox.add_child(pf_sep)
	
	# Tusler Reference Grid
	var tm_title = Label.new()
	tm_title.text = "TUSLER MATRIX REFERENCE"
	tm_title.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	vbox.add_child(tm_title)
	
	var tm_grid = GridContainer.new()
	tm_grid.columns = 2
	tm_grid.add_theme_constant_override("h_separation", 10)
	tm_grid.add_theme_constant_override("v_separation", 10)
	
	var ref_data = [
		{"icon": "🐯", "title": "Tiger", "mult": "H×H", "col": Color(1.0, 0.3, 0.0)},
		{"icon": "🐶", "title": "Puppy", "mult": "H×L", "col": Color(1.0, 0.8, 0.0)},
		{"icon": "🐊", "title": "Alligator", "mult": "L×H", "col": Color(0.8, 0.1, 0.1)},
		{"icon": "🐱", "title": "Kitten", "mult": "L×L", "col": Color(0.2, 0.9, 0.4)}
	]
	
	for d in ref_data:
		var pc = PanelContainer.new()
		pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var stb = StyleBoxFlat.new()
		stb.bg_color = Color(0.05, 0.05, 0.08, 0.8)
		stb.border_width_left = 1; stb.border_width_right = 1
		stb.border_width_top = 1; stb.border_width_bottom = 1
		stb.border_color = d["col"]
		stb.corner_radius_top_left = 4; stb.corner_radius_bottom_right = 4
		stb.content_margin_top = 8; stb.content_margin_bottom = 8
		pc.add_theme_stylebox_override("panel", stb)
		
		var cvbox = VBoxContainer.new()
		cvbox.add_theme_constant_override("separation", 2)
		
		var chbox = HBoxContainer.new()
		chbox.alignment = BoxContainer.ALIGNMENT_CENTER
		chbox.add_theme_constant_override("separation", 8)
		var l_icon = Label.new(); l_icon.text = d["icon"]
		var l_title = Label.new(); l_title.text = d["title"]
		l_title.add_theme_color_override("font_color", d["col"])
		chbox.add_child(l_icon)
		chbox.add_child(l_title)
		cvbox.add_child(chbox)
		
		var l_mult = Label.new(); l_mult.text = d["mult"]
		l_mult.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l_mult.add_theme_color_override("font_color", d["col"].lerp(Color.WHITE, 0.3))
		cvbox.add_child(l_mult)
		
		pc.add_child(cvbox)
		tm_grid.add_child(pc)
	
	vbox.add_child(tm_grid)
	var post_grid_spacer = Control.new()
	post_grid_spacer.custom_minimum_size = Vector2(0, 5)
	vbox.add_child(post_grid_spacer)
	
	var acc_title = Label.new()
	acc_title.text = "ACCURACY"
	acc_title.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	vbox.add_child(acc_title)
	
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 10)
	
	var emo_map = {"tiger": "🐯", "alligator": "🐊", "puppy": "🐶", "kitten": "🐱"}
	for key in emo_map.keys():
		var l = Label.new()
		l.text = emo_map[key] + " 0 / 0"
		grid.add_child(l)
		acc_labels[key] = l
	
	vbox.add_child(grid)
	vbox.add_child(HSeparator.new())
	
	var log_title = Label.new()
	log_title.text = "RISK LOG"
	log_title.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	vbox.add_child(log_title)
	
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 150)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	
	log_list = VBoxContainer.new()
	log_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(log_list)
	vbox.add_child(scroll)
	
	pb.add_child(vbox)
	self.add_child(pb)
	
	# Change budget color to red if dangerously low, else white
	if budget_label:
		if GameManager.is_low_budget():
			budget_label.modulate = Color(1, 0.2, 0.2) # Red warning
		else:
			budget_label.modulate = Color(1, 1, 1) # White
