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
	
	var diff = GameManager.current_difficulty
	
	var good_thresh = 160000
	var ok_thresh = 130000
	if diff == "Medium":
		good_thresh = 110000
		ok_thresh = 80000
	elif diff == "Hard":
		good_thresh = 60000
		ok_thresh = 30000

	var days = GameManager.schedule_days

	if budget < 0 and days < 0:
		panel.get_theme_stylebox("panel").border_color = Color(0.6, 0.0, 0.0)
		grade = "[b][color=red]CATASTROPHIC FAILURE[/color][/b]\n"
		grade += "You bankrupt the company AND missed the launch window! You're an absolute buffoon. A %d day delay on a bleeding project? Security is escorting you out immediately." % abs(days)
	elif days < 0 and budget >= good_thresh:
		panel.get_theme_stylebox("panel").border_color = Color(0.8, 0.4, 0.2)
		grade = "[b][color=orange]MISSED MARKET WINDOW[/color][/b]\n"
		grade += "You saved our budget, but the project launched %d days late! Our competitors beat us to market. Next time, spend the money to buy speed." % abs(days)
	elif budget < -150000:
		panel.get_theme_stylebox("panel").border_color = Color(0.6, 0.0, 0.0)
		grade = "[b][color=red]FINANCIAL CATASTROPHE[/color][/b]\n"
		grade += "You absolute buffoon. You plunged us into $150,000+ of pure debt! The company is facing bankruptcy hearings tomorrow because of your incompetence. Security is escorting you out immediately."
	elif budget < -50000:
		panel.get_theme_stylebox("panel").border_color = Color(0.8, 0.1, 0.1)
		grade = "[b][color=red]SEVERE FAILURE[/color][/b]\n"
		grade += "Are you kidding me? A $50,000+ deficit? We are taking your severe negligence to the board. Your career in project management ends today."
	elif budget < 0:
		panel.get_theme_stylebox("panel").border_color = Color(0.8, 0.2, 0.2)
		grade = "[b][color=red]PROJECT BANKRUPT[/color][/b]\n"
		grade += "You ran out of money and still kept going. We are in the red. The project is an utter failure and you are formally terminated."
	elif days < 0:
		panel.get_theme_stylebox("panel").border_color = Color(0.8, 0.4, 0.2)
		grade = "[b][color=orange]LATE DELIVERY[/color][/b]\n"
		grade += "You avoided bankruptcy, but you delivered the project %d days late. Time is money! You're on probation." % abs(days)
	elif budget < ok_thresh:
		panel.get_theme_stylebox("panel").border_color = Color(0.8, 0.4, 0.2)
		grade = "[b][color=orange]DISAPPOINTING[/color][/b]\n"
		grade += "You disappointed us. You managed to avoid bankruptcy and deliver on-time, but you burned through far more capital than planned."
	elif budget < good_thresh:
		panel.get_theme_stylebox("panel").border_color = Color(0.8, 0.8, 0.2)
		grade = "[b][color=yellow]ACCEPTABLE[/color][/b]\n"
		grade += "You get to keep your job. The budget was tight, but the project survived and launched on-schedule."
	else:
		panel.get_theme_stylebox("panel").border_color = Color(0.2, 0.8, 0.2)
		grade = "[b][color=green]GOOD JOB[/color][/b]\n"
		grade += "Good job! You managed the PMBOK phases efficiently, stuck to the timeline, and returned a healthy budget."
		
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
