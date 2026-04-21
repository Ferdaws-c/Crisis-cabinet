extends CanvasLayer

@onready var panel = Panel.new()
@onready var layout = VBoxContainer.new()

func _ready() -> void:
	self.visible = false
	self.layer = 100 # Ensure it's on top of everything
	
	var dimmer = ColorRect.new()
	dimmer.color = Color(0, 0, 0, 0.8)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Build UI procedurally
	panel.custom_minimum_size = Vector2(500, 420)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.1, 0.95)
	style.corner_radius_top_left = 12
	style.corner_radius_bottom_right = 12
	style.border_width_left = 3; style.border_width_top = 3
	style.border_color = Color(0.8, 0.6, 0.1)
	panel.add_theme_stylebox_override("panel", style)
	
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.set_offset(SIDE_LEFT, 20); layout.set_offset(SIDE_TOP, 20)
	layout.set_offset(SIDE_RIGHT, -20); layout.set_offset(SIDE_BOTTOM, -20)
	layout.add_theme_constant_override("separation", 10)
	
	var title = Label.new()
	title.text = "Select Simulation Difficulty"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	layout.add_child(title)
	
	_add_diff_button("Easy", "$200,000 Budget. Trivial workload. 4 active scenario pads.", Color(0.2, 0.5, 0.2))
	_add_diff_button("Medium", "$150,000 Budget. Moderate workload. 8 active scenario pads.", Color(0.7, 0.4, 0.1))
	_add_diff_button("Hard", "$100,000 Budget. Heavy workload. All 12 scenario pads active.", Color(0.6, 0.1, 0.1))
	
	var close_btn = Button.new()
	close_btn.text = "Close"
	close_btn.custom_minimum_size = Vector2(0, 40)
	var bs_close = StyleBoxFlat.new()
	bs_close.bg_color = Color(0.3, 0.3, 0.3)
	for c in ["corner_radius_top_left","corner_radius_top_right","corner_radius_bottom_left","corner_radius_bottom_right"]:
		bs_close.set(c, 8)
	close_btn.add_theme_stylebox_override("normal", bs_close)
	close_btn.pressed.connect(_close_popup)
	layout.add_child(close_btn)
	
	panel.add_child(layout)
	center.add_child(panel)
	dimmer.add_child(center)
	self.add_child(dimmer)

func _close_popup() -> void:
	self.visible = false
	GameManager.is_movement_paused = false

func _add_diff_button(level: String, desc: String, col: Color) -> void:
	var btn = Button.new()
	btn.text = level.to_upper() + "\n" + desc
	btn.custom_minimum_size = Vector2(0, 60)
	
	var bs = StyleBoxFlat.new()
	bs.bg_color = col
	for c in ["corner_radius_top_left","corner_radius_top_right","corner_radius_bottom_left","corner_radius_bottom_right"]:
		bs.set(c, 8)
	btn.add_theme_stylebox_override("normal", bs)
	
	btn.pressed.connect(_on_difficulty_selected.bind(level))
	layout.add_child(btn)

func show_popup() -> void:
	self.visible = true
	GameManager.is_movement_paused = true

func _on_difficulty_selected(level: String) -> void:
	GameManager.set_difficulty(level)
	
	# Deep clean stats but retain the difficulty we just picked (pass false)
	GameManager.reset_game(false)
	
	self.visible = false
	GameManager.is_movement_paused = false
	
	# Restart the level so the player spawns fresh with the new stats applied
	get_tree().reload_current_scene()
