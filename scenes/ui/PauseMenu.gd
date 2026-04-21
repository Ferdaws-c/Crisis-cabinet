extends CanvasLayer

@onready var panel = PanelContainer.new()
@onready var center = CenterContainer.new()

func _ready() -> void:
	self.visible = false
	self.layer = 125 # Absolutely top level to overlay above everything
	
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.95)
	style.corner_radius_top_left = 12
	style.corner_radius_bottom_right = 12
	style.border_width_left = 4; style.border_width_top = 4
	style.border_color = Color(0.8, 0.5, 0.1)
	style.content_margin_left = 40
	style.content_margin_top = 40
	style.content_margin_right = 40
	style.content_margin_bottom = 40
	panel.add_theme_stylebox_override("panel", style)
	
	var layout = VBoxContainer.new()
	layout.add_theme_constant_override("separation", 20)
	layout.custom_minimum_size = Vector2(400, 0)
	
	var title = Label.new()
	title.text = "- PAUSED -"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.9, 0.6, 0.1))
	layout.add_child(title)
	
	layout.add_child(HSeparator.new())
	
	# Helper function to generate standardized buttons
	var build_btn = func(txt: String, color: Color, handler: Callable):
		var btn = Button.new()
		btn.text = txt
		btn.custom_minimum_size = Vector2(0, 50)
		var bs = StyleBoxFlat.new()
		bs.bg_color = color
		for c in ["corner_radius_top_left","corner_radius_top_right","corner_radius_bottom_left","corner_radius_bottom_right"]:
			bs.set(c, 8)
		btn.add_theme_stylebox_override("normal", bs)
		btn.pressed.connect(handler)
		layout.add_child(btn)
		return btn
		
	# 1. Resume
	build_btn.call("Resume Game", Color(0.2, 0.6, 0.2), _on_resume_pressed)
	
	# 2. Retry
	build_btn.call("Retry Scenario (Restart Map)", Color(0.7, 0.4, 0.1), _on_retry_pressed)
	
	# 3. Main Menu
	build_btn.call("Exit to Main Menu", Color(0.6, 0.3, 0.1), _on_main_menu_pressed)
	
	# 4. Quit
	build_btn.call("Quit to Desktop", Color(0.8, 0.2, 0.2), _on_quit_pressed)
	
	layout.add_child(HSeparator.new())
	
	# Settings Section
	var settings_label = Label.new()
	settings_label.text = "- OPTIONS -"
	settings_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	settings_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	layout.add_child(settings_label)
	
	var toggle_timer_btn = Button.new()
	toggle_timer_btn.name = "TimerBtn" # So we can find it
	toggle_timer_btn.text = "Countdown Timer: " + ("ON" if GameManager.timer_enabled else "OFF")
	toggle_timer_btn.custom_minimum_size = Vector2(0, 50)
	var tb_style = StyleBoxFlat.new()
	tb_style.bg_color = Color(0.2, 0.4, 0.5)
	for c in ["corner_radius_top_left","corner_radius_top_right","corner_radius_bottom_left","corner_radius_bottom_right"]: tb_style.set(c, 8)
	toggle_timer_btn.add_theme_stylebox_override("normal", tb_style)
	toggle_timer_btn.pressed.connect(_on_toggle_timer_pressed.bind(toggle_timer_btn))
	layout.add_child(toggle_timer_btn)
	
	layout.add_child(HSeparator.new())
	
	# 5. Budget Adjuster
	var cheat_label = Label.new()
	cheat_label.text = "Adjust Budget Manager"
	cheat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cheat_label.add_theme_color_override("font_color", Color.GRAY)
	layout.add_child(cheat_label)
	
	var adjust_hbox = HBoxContainer.new()
	adjust_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	adjust_hbox.add_theme_constant_override("separation", 15)
	
	var btn_sub = Button.new()
	btn_sub.text = "- $5,000"
	btn_sub.custom_minimum_size = Vector2(100, 40)
	btn_sub.pressed.connect(func(): _adjust_budget(-5000))
	adjust_hbox.add_child(btn_sub)
	
	var btn_add = Button.new()
	btn_add.text = "+ $5,000"
	btn_add.custom_minimum_size = Vector2(100, 40)
	btn_add.pressed.connect(func(): _adjust_budget(5000))
	adjust_hbox.add_child(btn_add)
	
	layout.add_child(adjust_hbox)
	
	panel.add_child(layout)
	center.add_child(panel)
	self.add_child(center)

func show_pause() -> void:
	self.visible = true
	GameManager.is_movement_paused = true

func hide_pause() -> void:
	self.visible = false
	GameManager.is_movement_paused = false

func _on_resume_pressed() -> void:
	hide_pause()

func _on_retry_pressed() -> void:
	hide_pause()
	GameManager.reset_game(false) # False keeps their difficulty setting intact!
	get_tree().reload_current_scene()

func _on_main_menu_pressed() -> void:
	hide_pause()
	GameManager.reset_game(true)  # Wipe everything totally
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_toggle_timer_pressed(btn: Button) -> void:
	GameManager.timer_enabled = not GameManager.timer_enabled
	btn.text = "Countdown Timer: " + ("ON" if GameManager.timer_enabled else "OFF")
	var color = Color(0.2, 0.4, 0.5) if GameManager.timer_enabled else Color(0.4, 0.2, 0.2)
	var style = btn.get_theme_stylebox("normal").duplicate()
	style.bg_color = color
	btn.add_theme_stylebox_override("normal", style)

func _adjust_budget(amount: int) -> void:
	GameManager.budget += amount
	# Safely update the Godot physics stream manually 
	GameManager.emit_signal("state_changed")
