## MG11_PayoffPlinko.gd (Archive Assessor)
## PMBOK: Close Project or Phase (Archiving, transferring, releasing)
## Mechanic: Sort documents into 4 bins using Arrow Keys

extends Node

var _game_area: Control
var _overlay: Node

var _score: int = 0
var _budget_delta: int = 0
var _days_delta: int = 0
var _finished: bool = false

var _score_label: Label
var _streak_label: Label
var _doc_node: ColorRect
var _doc_label: Label

var _current_type: int = -1
var _is_animating: bool = false
var _streak: int = 0

const DOCS_UP = ["Project Retrospective", "Risk Register Archive", "Lessons Learned Log", "Post-Mortem Analysis", "Final Phase Audit"]
const DOCS_RIGHT = ["Final Software Build", "Keys to the Facility", "Signed Acceptance Form", "User Manuals", "Product Handover"]
const DOCS_DOWN = ["Vendor Final Invoice", "Contractor Payment", "Budget Closure Report", "Supplier Final Bill", "Financial Audit"]
const DOCS_LEFT = ["Team Performance Evals", "Release Developer", "Reassign QA Tester", "Close Freelance Contract", "HR Release Form"]

func start(game_area: Control, overlay: Node) -> void:
	_game_area = game_area
	_overlay = overlay
	var size = game_area.size
	
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.1)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_area.add_child(bg)
	
	var title = Label.new()
	title.text = "ARCHIVE ASSESSOR — Sort closing documents with ARROW KEYS"
	title.add_theme_font_size_override("font_size", 18)
	title.modulate = Color(0.9, 0.9, 1.0)
	title.position = Vector2(size.x * 0.5 - 260, 8)
	game_area.add_child(title)
	
	_create_bin(size.x * 0.5, 70, "⬆️ KNOWLEDGE BASE\n(Lessons Learned)", Color(0.2, 0.8, 0.2))
	_create_bin(size.x - 80, size.y * 0.5, "➡️ CUSTOMER\n(Deliverables)", Color(0.2, 0.5, 1.0))
	_create_bin(size.x * 0.5, size.y - 40, "⬇️ FINANCE\n(Invoices)", Color(0.8, 0.8, 0.2))
	_create_bin(80, size.y * 0.5, "⬅️ HR\n(Release Team)", Color(0.8, 0.2, 0.2))
	
	_doc_node = ColorRect.new()
	_doc_node.size = Vector2(180, 100)
	_doc_node.color = Color(0.95, 0.95, 0.9)
	
	var doc_bg = ColorRect.new()
	doc_bg.color = Color(0.1, 0.3, 0.5)
	doc_bg.size = Vector2(180, 20)
	_doc_node.add_child(doc_bg)
	
	var doc_head = Label.new()
	doc_head.text = "DOCUMENT"
	doc_head.add_theme_font_size_override("font_size", 12)
	doc_head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	doc_head.size = Vector2(180, 20)
	_doc_node.add_child(doc_head)
	
	_doc_label = Label.new()
	_doc_label.add_theme_color_override("font_color", Color.BLACK)
	_doc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_doc_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_doc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_doc_label.position = Vector2(10, 20)
	_doc_label.size = Vector2(160, 80)
	_doc_node.add_child(_doc_label)
	
	game_area.add_child(_doc_node)
	
	_score_label = Label.new()
	_score_label.text = "Score: 0"
	_score_label.add_theme_font_size_override("font_size", 18)
	_score_label.position = Vector2(10, 10)
	game_area.add_child(_score_label)
	
	_streak_label = Label.new()
	_streak_label.text = "Streak: 0"
	_streak_label.add_theme_font_size_override("font_size", 14)
	_streak_label.modulate = Color(1.0, 1.0, 0.5)
	_streak_label.position = Vector2(10, 35)
	game_area.add_child(_streak_label)
	
	_spawn_doc()

func _create_bin(px: float, py: float, txt: String, col: Color) -> void:
	var b = ColorRect.new()
	b.size = Vector2(140, 60)
	b.position = Vector2(px - 70, py - 30)
	b.color = col
	b.color.a = 0.4
	
	var outline = ReferenceRect.new()
	outline.border_color = col
	outline.border_width = 3.0
	outline.editor_only = false
	outline.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	b.add_child(outline)
	
	var l = Label.new()
	l.text = txt
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.size = b.size
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", Color.WHITE)
	b.add_child(l)
	_game_area.add_child(b)

func _spawn_doc() -> void:
	_is_animating = false
	_doc_node.position = _game_area.size * 0.5 - _doc_node.size * 0.5
	_doc_node.scale = Vector2.ONE
	_current_type = randi() % 4
	
	var arr = []
	if _current_type == 0: arr = DOCS_UP
	elif _current_type == 1: arr = DOCS_RIGHT
	elif _current_type == 2: arr = DOCS_DOWN
	elif _current_type == 3: arr = DOCS_LEFT
	
	_doc_label.text = arr[randi() % arr.size()]

func tick(delta: float) -> bool:
	if _finished: return true
	if _is_animating: return false
	
	var dir = -1
	if Input.is_action_just_pressed("ui_up") or Input.is_key_pressed(KEY_UP): dir = 0
	elif Input.is_action_just_pressed("ui_right") or Input.is_key_pressed(KEY_RIGHT): dir = 1
	elif Input.is_action_just_pressed("ui_down") or Input.is_key_pressed(KEY_DOWN): dir = 2
	elif Input.is_action_just_pressed("ui_left") or Input.is_key_pressed(KEY_LEFT): dir = 3
	
	if dir != -1:
		_handle_sort(dir)
	return false

func _handle_sort(dir: int) -> void:
	_is_animating = true
	var size = _game_area.size
	var target = Vector2.ZERO
	if dir == 0: target = Vector2(size.x * 0.5, 70)
	elif dir == 1: target = Vector2(size.x - 80, size.y * 0.5)
	elif dir == 2: target = Vector2(size.x * 0.5, size.y - 40)
	elif dir == 3: target = Vector2(80, size.y * 0.5)
	
	target -= _doc_node.size * 0.5 * 0.2 # Account for scaling down
	
	var speed_mult = GameManager.speed_multiplier
	var t_time = 0.2 / speed_mult
	
	var tw = _game_area.create_tween()
	tw.tween_property(_doc_node, "position", target, t_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(_doc_node, "scale", Vector2(0.2, 0.2), t_time)
	
	if dir == _current_type:
		tw.tween_callback(Callable(self, "_on_correct"))
	else:
		tw.tween_callback(Callable(self, "_on_wrong"))

func _on_correct() -> void:
	_score += 150
	_streak += 1
	if _streak >= 5 and _streak % 5 == 0:
		_score += 300
		_budget_delta += 2000
		JuiceManager.spawn_floating_text(_game_area, _doc_node.position, "PERFECT ORGANIZATION!\n+300 pts", Color(1,1,0))
	else:
		JuiceManager.spawn_floating_text(_game_area, _doc_node.position, "FILED! +150", Color(0.2, 1.0, 0.2))
	JuiceManager.correct_sound()
	_update_ui()
	_spawn_doc()

func _on_wrong() -> void:
	_score -= 50
	_budget_delta -= 1000
	_streak = 0
	JuiceManager.wrong_sound()
	JuiceManager.hit_stop_and_shake(0.3)
	JuiceManager.spawn_floating_text(_game_area, _doc_node.position, "WRONG DEPARTMENT!\n-50 -$1K", Color(1,0.2,0.2))
	_update_ui()
	
	var tw = _game_area.create_tween()
	tw.tween_property(_doc_node, "position", _game_area.size * 0.5 - _doc_node.size * 0.5, 0.1)
	tw.parallel().tween_property(_doc_node, "scale", Vector2.ONE, 0.1)
	tw.tween_callback(func(): _is_animating = false)

func _update_ui() -> void:
	_score_label.text = "Score: %d" % _score
	_streak_label.text = "Streak: %d" % _streak

func get_result() -> Dictionary:
	return {
		"score": _score,
		"budget_delta": _budget_delta,
		"days_delta": _days_delta
	}
