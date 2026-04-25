extends Control

signal completed(result: Dictionary)
signal closed()

const GAME_THEME := preload("res://themes/game_theme.tres")

@onready var dim_background: ColorRect = $DimBackground
@onready var dialogue_panel: PanelContainer = $DialoguePanel
@onready var avatar_container: VBoxContainer = $DialoguePanel/MarginContainer/HBoxContainer/AvatarContainer
@onready var avatar_texture: TextureRect = $DialoguePanel/MarginContainer/HBoxContainer/AvatarContainer/AvatarTexture
@onready var name_label: Label = $DialoguePanel/MarginContainer/HBoxContainer/AvatarContainer/NameLabel
@onready var role_label: Label = $DialoguePanel/MarginContainer/HBoxContainer/AvatarContainer/RoleLabel
@onready var dialogue_text: RichTextLabel = $DialoguePanel/MarginContainer/HBoxContainer/ContentContainer/DialogueText
@onready var choices_container: VBoxContainer = $DialoguePanel/MarginContainer/HBoxContainer/ContentContainer/ChoicesContainer

var _data: Dictionary = {}
var _tree: Array = []
var _choices_made: Array = []
var _visited_node_ids: Array = []
var _all_node_ids: Array = []
var _placeholder_nodes: Array[Node] = []
var _is_ready := false
var _has_setup := false
var _avatar_frame: PanelContainer

func _ready() -> void:
	theme = GAME_THEME
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_is_ready = true
	_ensure_avatar_frame()
	_apply_styles()
	if _has_setup:
		_apply_setup()

func setup(data: Dictionary) -> void:
	_data = data.duplicate(true)
	_has_setup = true
	if not _is_ready:
		return
	_apply_setup()

func _ensure_avatar_frame() -> void:
	if is_instance_valid(_avatar_frame):
		return
	_avatar_frame = PanelContainer.new()
	_avatar_frame.custom_minimum_size = Vector2(
		StyleConstants.AVATAR_SIZE.x + 4,
		StyleConstants.AVATAR_SIZE.y + 4
	)
	_avatar_frame.add_theme_stylebox_override("panel", StyleConstants.create_avatar_frame_stylebox())
	avatar_container.add_child(_avatar_frame)
	avatar_texture.reparent(_avatar_frame, false)
	StyleConstants.style_avatar_texture(avatar_texture)

func _apply_styles() -> void:
	dim_background.color = StyleConstants.COLOR_BG_DIM
	dialogue_panel.add_theme_stylebox_override("panel", StyleConstants.create_panel_stylebox())
	name_label.add_theme_color_override("font_color", StyleConstants.COLOR_ACCENT_PRIMARY)
	name_label.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_SM)
	role_label.add_theme_color_override("font_color", StyleConstants.COLOR_TEXT_MUTED)
	role_label.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_XS)
	dialogue_text.add_theme_color_override("default_color", StyleConstants.COLOR_TEXT_PRIMARY)

func _apply_setup() -> void:
	_tree = _data.get("dialogue_tree", []).duplicate(true)
	_choices_made.clear()
	_visited_node_ids.clear()
	_all_node_ids.clear()
	for node in _tree:
		_all_node_ids.append(str(node.get("id", "")))

	name_label.text = str(_data.get("npc_name", "Unknown"))
	role_label.text = str(_data.get("npc_role", ""))
	dialogue_text.text = ""
	_set_avatar(str(_data.get("npc_avatar", "")), name_label.text)
	_navigate_to("root")

func _find_node(id: String) -> Dictionary:
	for node in _tree:
		if str(node.get("id", "")) == id:
			return node
	push_warning("NPCDialogue: node '%s' not found" % id)
	return {}

func _navigate_to(node_id: String) -> void:
	var node := _find_node(node_id)
	if node.is_empty():
		_end_conversation()
		return

	if not _visited_node_ids.has(node_id):
		_visited_node_ids.append(node_id)

	for child in choices_container.get_children():
		child.queue_free()

	var npc_text := str(node.get("npc_text", ""))
	dialogue_text.text = npc_text

	var choices: Array = node.get("choices", [])
	if choices.is_empty():
		await get_tree().create_timer(1.5).timeout
		_end_conversation()
		return

	for choice in choices:
		var button := Button.new()
		button.text = str(choice.get("text", "Continue"))
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0, 42)
		_apply_choice_button_style(button)
		var target := str(choice.get("leads_to", ""))
		button.pressed.connect(func() -> void:
			if target == "":
				push_warning("NPCDialogue: choice is missing 'leads_to'")
				_end_conversation()
				return
			_choices_made.append(target)
			_navigate_to(target)
		)
		choices_container.add_child(button)

func _apply_choice_button_style(button: Button) -> void:
	var normal := StyleConstants.create_panel_stylebox(StyleConstants.COLOR_BG_BUTTON, StyleConstants.COLOR_ACCENT_PRIMARY, 2)
	normal.border_width_top = 0
	normal.border_width_right = 0
	normal.border_width_bottom = 0
	normal.content_margin_left = 12
	normal.content_margin_right = 10
	var hover := StyleConstants.create_panel_stylebox(StyleConstants.COLOR_ACCENT_PRIMARY, StyleConstants.COLOR_ACCENT_PRIMARY, 2)
	hover.border_width_top = 0
	hover.border_width_right = 0
	hover.border_width_bottom = 0
	hover.content_margin_left = 12
	hover.content_margin_right = 10
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_color_override("font_color", StyleConstants.COLOR_TEXT_PRIMARY)
	button.add_theme_color_override("font_hover_color", StyleConstants.COLOR_TEXT_DARK)
	button.add_theme_color_override("font_pressed_color", StyleConstants.COLOR_TEXT_DARK)
	button.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_SM)

func _end_conversation() -> void:
	var visited_all := true
	for node_id in _all_node_ids:
		if node_id == "":
			continue
		if not _visited_node_ids.has(node_id):
			visited_all = false
			break
	completed.emit({
		"choices_made": _choices_made,
		"all_nodes_visited": visited_all
	})
	closed.emit()
	queue_free()

func _set_avatar(path: String, fallback_name: String) -> void:
	for node in _placeholder_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_placeholder_nodes.clear()

	avatar_texture.visible = false
	avatar_texture.texture = null
	if path != "" and ResourceLoader.exists(path):
		avatar_texture.texture = load(path)
		avatar_texture.visible = true
		return

	var placeholder := StyleConstants.create_avatar_placeholder(fallback_name.left(1).to_upper())
	_avatar_frame.add_child(placeholder)
	_placeholder_nodes.append(placeholder)
