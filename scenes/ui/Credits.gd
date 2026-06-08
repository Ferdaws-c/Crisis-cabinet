extends CanvasLayer

@onready var panel = ColorRect.new()
@onready var center = CenterContainer.new()
@onready var layout = VBoxContainer.new()
var _upload_status_lbl: Label = null
var _btn_exit: Button = null

func _ready() -> void:
	self.layer = 120 # Absolute top
	
	# Solid black background
	panel.color = Color(0.05, 0.05, 0.05, 1.0)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Centering wrapper
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Content layout
	layout.add_theme_constant_override("separation", 30)
	
	# Fade in starting at 0
	panel.modulate.a = 0.0
	
	add_text("Thanks everyone for playing this game", 28, Color(0.8, 0.8, 0.2))
	
	var sep1 = HSeparator.new(); layout.add_child(sep1)
	
	add_text("Special Thanks to", 18, Color.GRAY)
	add_text("Professor YUSUF ALTUNEL", 28, Color(0.4, 0.8, 1.0))
	
	var sep2 = HSeparator.new(); layout.add_child(sep2)
	
	add_text("Project Team", 24, Color(0.9, 0.9, 0.9))
	add_text("Project Members:", 16, Color.GRAY)
	add_text("Ferdaws Qaem\nAbdelmagied Farhouda\nMohamed Sallam", 22, Color.WHITE)
	
	var sep3 = HSeparator.new(); layout.add_child(sep3)
	
	# Upload status label
	_upload_status_lbl = Label.new()
	_upload_status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_upload_status_lbl.add_theme_font_size_override("font_size", 16)
	_upload_status_lbl.visible = false
	layout.add_child(_upload_status_lbl)
	
	# Exit button — disabled until upload finishes
	_btn_exit = Button.new()
	_btn_exit.text = "Exit to Main Menu"
	_btn_exit.custom_minimum_size = Vector2(250, 60)
	var bs = StyleBoxFlat.new()
	bs.bg_color = Color(0.2, 0.4, 0.8)
	for c in ["corner_radius_top_left","corner_radius_top_right","corner_radius_bottom_left","corner_radius_bottom_right"]:
		bs.set(c, 8)
	_btn_exit.add_theme_stylebox_override("normal", bs)
	_btn_exit.pressed.connect(_on_exit_pressed)
	layout.add_child(_btn_exit)
	
	center.add_child(layout)
	panel.add_child(center)
	self.add_child(panel)
	
	# Cinematic Fade In
	create_tween().tween_property(panel, "modulate:a", 1.0, 2.0)
	
	# ── Cloud upload ──
	var pending = GameManager.get_pending_upload()
	if not pending.is_empty():
		GameManager.clear_pending_upload()
		# Disable exit until upload completes
		_btn_exit.disabled = true
		_btn_exit.modulate = Color(0.5, 0.5, 0.5)
		_upload_status_lbl.text = "⏳ Uploading score to global leaderboard...\nPlease wait before exiting."
		_upload_status_lbl.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
		_upload_status_lbl.visible = true
		_do_cloud_upload(pending)
		_start_upload_timeout()
	else:
		# Nothing to upload — exit is free immediately
		_btn_exit.disabled = false

func _do_cloud_upload(data: Dictionary) -> void:
	if not is_instance_valid(self):
		return
	var pname: String = data.get("name", "Unknown")
	var score: int    = data.get("score", 0)
	var meta: Dictionary = data.get("meta", {})
	
	if not SilentWolf.Scores.sw_save_score_complete.is_connected(_on_upload_done):
		SilentWolf.Scores.sw_save_score_complete.connect(_on_upload_done)
	
	SilentWolf.Scores.save_score(pname, score, "main", meta)

func _on_upload_done(result: Dictionary) -> void:
	if SilentWolf.Scores.sw_save_score_complete.is_connected(_on_upload_done):
		SilentWolf.Scores.sw_save_score_complete.disconnect(_on_upload_done)
	
	if not is_instance_valid(_upload_status_lbl) or not is_instance_valid(_btn_exit):
		return
	
	# Check if upload actually succeeded
	var success: bool = result.get("success", false) or result.has("score_id")
	if success:
		_upload_status_lbl.text = "✅ Score uploaded to global leaderboard!"
		_upload_status_lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
	else:
		_upload_status_lbl.text = "⚠️ Upload failed — score saved locally only."
		_upload_status_lbl.add_theme_color_override("font_color", Color(1.0, 0.7, 0.3))
	
	# Unlock exit button
	_btn_exit.disabled = false
	_btn_exit.modulate = Color(1, 1, 1)

func _on_exit_pressed() -> void:
	var tw = create_tween()
	tw.tween_property(panel, "modulate:a", 0.0, 1.0)
	await tw.finished
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")

func add_text(text: String, size: int, color: Color = Color.WHITE) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)
	layout.add_child(lbl)
	return lbl

func _start_upload_timeout() -> void:
	await get_tree().create_timer(59.0).timeout
	if is_instance_valid(_btn_exit) and _btn_exit.disabled:
		# Disconnect the listener to prevent double-triggering or state overwrite if it resolves late
		if SilentWolf.Scores.sw_save_score_complete.is_connected(_on_upload_done):
			SilentWolf.Scores.sw_save_score_complete.disconnect(_on_upload_done)
			
		if is_instance_valid(_upload_status_lbl):
			_upload_status_lbl.text = "⚠️ Upload timed out — score saved locally."
			_upload_status_lbl.add_theme_color_override("font_color", Color(1.0, 0.7, 0.3))
			
		_btn_exit.disabled = false
		_btn_exit.modulate = Color(1, 1, 1)
