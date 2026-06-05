extends CanvasLayer

@onready var center = CenterContainer.new()
@onready var panel = PanelContainer.new()
@onready var layout = VBoxContainer.new()
var result_label: RichTextLabel

func _ready() -> void:
	self.visible = false
	self.layer = 100
	
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.95)
	style.corner_radius_top_left = 12
	style.corner_radius_bottom_right = 12
	style.border_width_left = 6; style.border_width_top = 6
	style.border_color = Color(0.8, 0.2, 0.2)
	style.content_margin_left = 40
	style.content_margin_top = 40
	style.content_margin_right = 40
	style.content_margin_bottom = 40
	panel.add_theme_stylebox_override("panel", style)
	
	layout.add_theme_constant_override("separation", 25)
	layout.custom_minimum_size = Vector2(700, 0)
	
	var title = Label.new()
	title.text = "BOSS: FINAL EVALUATION"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	layout.add_child(title)
	
	var sep = HSeparator.new()
	layout.add_child(sep)
	
	result_label = RichTextLabel.new()
	result_label.bbcode_enabled = true
	result_label.fit_content = true
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	layout.add_child(result_label)
	
	var btn_restart = Button.new()
	btn_restart.text = "Roll Credits"
	btn_restart.custom_minimum_size = Vector2(0, 60)
	var bs = StyleBoxFlat.new()
	bs.bg_color = Color(0.8, 0.3, 0.3)
	for c in ["corner_radius_top_left","corner_radius_top_right","corner_radius_bottom_left","corner_radius_bottom_right"]:
		bs.set(c, 8)
	btn_restart.add_theme_stylebox_override("normal", bs)
	btn_restart.pressed.connect(_on_restart_pressed)
	layout.add_child(btn_restart)
	
	panel.add_child(layout)
	center.add_child(panel)
	self.add_child(center)

func show_popup() -> void:
	self.visible = true
	GameManager.is_movement_paused = true
	GameManager.save_high_score()
	
	var grade = ""
	var budget = GameManager.budget
	var score = GameManager.point_score
	var best_streak = GameManager.best_streak
	
	var days = GameManager.schedule_days
	
	var games_played = max(1, GameManager.scenarios_completed)
	var good_thresh = games_played * 1000
	var ok_thresh = games_played * 400
	
	if score < 0:
		panel.get_theme_stylebox("panel").border_color = Color(0.6, 0.0, 0.0)
		grade = "[b][color=red]CATASTROPHIC FAILURE[/color][/b]\n"
		grade += "You scored terribly. You actively sabotaged the project and proved completely incompetent. Security is escorting you out."
	elif score < ok_thresh:
		panel.get_theme_stylebox("panel").border_color = Color(0.8, 0.4, 0.2)
		grade = "[b][color=orange]DISAPPOINTING[/color][/b]\n"
		grade += "You barely scraped by. Your performance in the project phases was weak, leading to massive inefficiencies."
	elif score < good_thresh:
		panel.get_theme_stylebox("panel").border_color = Color(0.8, 0.8, 0.2)
		grade = "[b][color=yellow]ACCEPTABLE[/color][/b]\n"
		grade += "You get to keep your job. The project had bumps, but you managed the PMBOK phases adequately."
	else:
		panel.get_theme_stylebox("panel").border_color = Color(0.2, 0.8, 0.2)
		grade = "[b][color=green]EXCELLENT JOB[/color][/b]\n"
		grade += "Outstanding performance! You managed the PMBOK phases brilliantly, maximizing efficiency and minimizing risks."
		
	var msg = grade + "\n\n"
	msg += "[b]Final Remaining Budget:[/b] $" + str(budget) + "\n"
	msg += "[b]Days Remaining / Late:[/b] " + (str(days) if days >= 0 else str(abs(days)) + " Days Late") + "\n"
	msg += "[b]Highest Classification Streak:[/b] " + str(best_streak) + " in a row\n"
	msg += "[b]Skill Score:[/b] " + str(score) + " pts\n"
	msg += "[b]Total XP:[/b] " + str(GameManager.xp_score) + " XP"
	
	result_label.text = msg

func _on_restart_pressed() -> void:
	self.visible = false
	get_tree().change_scene_to_file("res://scenes/ui/PerformanceReview.tscn")
