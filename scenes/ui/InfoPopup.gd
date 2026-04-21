extends CanvasLayer

@onready var center = CenterContainer.new()
@onready var panel = PanelContainer.new()
@onready var layout = VBoxContainer.new()

var title_lbl: Label
var body_txt: RichTextLabel
var btn_next: Button
var current_page: int = 1

func _ready() -> void:
	self.visible = false
	self.layer = 100 
	
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.05, 0.1, 0.98)
	style.corner_radius_top_left = 12; style.corner_radius_bottom_right = 12
	style.border_width_left = 3; style.border_width_top = 3
	style.border_color = Color(0.0, 0.83, 1.0)
	style.content_margin_left = 40; style.content_margin_top = 40
	style.content_margin_right = 40; style.content_margin_bottom = 40
	panel.add_theme_stylebox_override("panel", style)
	
	layout.add_theme_constant_override("separation", 20)
	layout.custom_minimum_size = Vector2(700, 0) 
	
	title_lbl = Label.new()
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 24)
	title_lbl.add_theme_color_override("font_color", Color(0.0, 0.83, 1.0))
	layout.add_child(title_lbl)
	
	layout.add_child(HSeparator.new())
	
	body_txt = RichTextLabel.new()
	body_txt.bbcode_enabled = true
	body_txt.fit_content = true
	body_txt.autowrap_mode = TextServer.AUTOWRAP_WORD
	layout.add_child(body_txt)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	layout.add_child(spacer)
	
	btn_next = Button.new()
	btn_next.custom_minimum_size = Vector2(0, 50)
	var bs = StyleBoxFlat.new()
	bs.bg_color = Color(0.0, 0.5, 0.8)
	for c in ["corner_radius_top_left","corner_radius_top_right","corner_radius_bottom_left","corner_radius_bottom_right"]: bs.set(c, 8)
	btn_next.add_theme_stylebox_override("normal", bs)
	btn_next.pressed.connect(_on_next_pressed)
	layout.add_child(btn_next)
	
	panel.add_child(layout)
	center.add_child(panel)
	self.add_child(center)

func show_popup() -> void:
	self.visible = true
	GameManager.is_movement_paused = true
	current_page = 1
	_render_page()

func _render_page() -> void:
	if current_page == 1:
		title_lbl.text = "1. WHAT IS A RISK?"
		var msg = "A risk is an uncertain event or condition that, if it occurs, has a positive or negative effect on project objectives.\n\n"
		msg += "[color=cyan][b]Risk = Probability × Impact[/b][/color]\n\n"
		msg += "You cannot respond to every risk — you must prioritize them using a matrix."
		body_txt.text = msg
		btn_next.text = "Next: The Tusler Matrix →"
		
	elif current_page == 2:
		title_lbl.text = "2. THE TUSLER CLASSIFICATION MATRIX"
		var msg = "Risks are categorized into 4 quadrants by Base Probability × Impact:\n\n"
		msg += "• [color=#ff3d00][b]🐯 TIGER[/b][/color] (High Prob × High Imp): Highly likely, highly lethal.\n"
		msg += "• [color=#ff5252][b]🐊 ALLIGATOR[/b][/color] (Low Prob × High Imp): Unlikely but catastrophic. You need a contingency plan ready.\n"
		msg += "• [color=yellow][b]🐶 PUPPY[/b][/color] (High Prob × Low Imp): Common but low immediate damage. Warning: Ignored Puppies accumulate into Tigers!\n"
		msg += "• [color=green][b]🐱 KITTEN[/b][/color] (Low Prob × Low Imp): Lowest priority. Log and monitor."
		body_txt.text = msg
		btn_next.text = "Next: PMBOK Strategies →"
		
	elif current_page == 3:
		title_lbl.text = "3. PMBOK RESPONSE STRATEGIES"
		var msg = "When managing these risks, you must strictly assign one of four PMBOK active response strategies:\n\n"
		msg += "• [color=cyan][b]🚫 AVOID:[/b][/color] Change the project plan to eliminate the threat entirely. Analogy: Cancel the risky feature.\n"
		msg += "• [color=green][b]🛡 MITIGATE:[/b][/color] Take proactive steps to reduce probability or impact. Analogy: Wear a seatbelt.\n"
		msg += "• [color=yellow][b]📦 TRANSFER:[/b][/color] Shift the financial consequence to a 3rd party. Analogy: Buy insurance.\n"
		msg += "• [color=red][b]✅ ACCEPT:[/b][/color] Acknowledge the risk and prepare a fallback. Analogy: Keep a spare tyre in the boot."
		body_txt.text = msg
		btn_next.text = "Next: The Project Lifecycle →"
		
	elif current_page == 4:
		title_lbl.text = "4. THE PROJECT LIFECYCLE"
		var msg = "You will navigate the four phases of standard project delivery:\n\n"
		msg += "• [color=#2ecc71][b]1. PLANNING:[/b][/color] The blueprint stage. High uncertainty, but changes are cheap.\n"
		msg += "• [color=#e74c3c][b]2. EXECUTING:[/b][/color] Building the deliverables. The highest burn-rate of your budget.\n"
		msg += "• [color=#9b59b6][b]3. MONITORING:[/b][/color] Quality Assurance and Stress Testing. Finding the hidden defects.\n"
		msg += "• [color=#3498db][b]4. CLOSING:[/b][/color] Handover to Operations. The stakes are highest here!\n\n"
		msg += "[i]Keep your budget alive through all 12 scenarios to graduate![/i]"
		body_txt.text = msg
		btn_next.text = "ENTER CRISIS CABINET"

func _on_next_pressed() -> void:
	if current_page < 4:
		current_page += 1
		_render_page()
	else:
		self.visible = false
		GameManager.has_read_info = true
		GameManager.is_movement_paused = false
