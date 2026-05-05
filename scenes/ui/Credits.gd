extends CanvasLayer

@onready var panel = ColorRect.new()
@onready var center = CenterContainer.new()
@onready var layout = VBoxContainer.new()

func _ready() -> void:
	self.layer = 120 # Absolute top
	
	# Solid black background
	panel.color = Color(0.05, 0.05, 0.05, 1.0)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Unbreakable Centering wrapper
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Content layout
	layout.add_theme_constant_override("separation", 30)
	
	# Fade in starting at 0
	panel.modulate.a = 0.0
	
	# Helper function to add labels easily
	var add_text = func(text: String, size: int, color: Color = Color.WHITE):
		var lbl = Label.new()
		lbl.text = text
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", size)
		lbl.add_theme_color_override("font_color", color)
		layout.add_child(lbl)
		return lbl
	
	add_text.call("Thanks everyone for playing this game", 28, Color(0.8, 0.8, 0.2))
	
	var sep1 = HSeparator.new(); layout.add_child(sep1)
	
	add_text.call("Special Thanks to", 18, Color.GRAY)
	add_text.call("Professor YUSUF ALTUNEL", 28, Color(0.4, 0.8, 1.0))
	
	var sep2 = HSeparator.new(); layout.add_child(sep2)
	
	add_text.call("Project Team", 24, Color(0.9, 0.9, 0.9))
	add_text.call("Project Members:", 16, Color.GRAY)
	add_text.call("Ferdaws Qaem\nAbdelmagied Farhouda\nMohamed Sallam", 22, Color.WHITE)
	
	var sep3 = HSeparator.new(); layout.add_child(sep3)
	
	var btn_exit = Button.new()
	btn_exit.text = "Exit to Main Menu"
	btn_exit.custom_minimum_size = Vector2(250, 60)
	var bs = StyleBoxFlat.new()
	bs.bg_color = Color(0.2, 0.4, 0.8)
	for c in ["corner_radius_top_left","corner_radius_top_right","corner_radius_bottom_left","corner_radius_bottom_right"]:
		bs.set(c, 8)
	btn_exit.add_theme_stylebox_override("normal", bs)
	btn_exit.pressed.connect(_on_exit_pressed)
	layout.add_child(btn_exit)
	
	center.add_child(layout)
	panel.add_child(center)
	self.add_child(panel)
	
	# Cinematic Fade In
	create_tween().tween_property(panel, "modulate:a", 1.0, 2.0)

func _on_exit_pressed() -> void:
	# Fade out then transition
	var tw = create_tween()
	tw.tween_property(panel, "modulate:a", 0.0, 1.0)
	await tw.finished
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
