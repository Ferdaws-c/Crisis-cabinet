extends Node

# === PRIMARY COLORS ===
const COLOR_BG_DIM := Color(0, 0, 0, 0.65)
const COLOR_BG_PANEL := Color(0.12, 0.14, 0.18, 0.92)
const COLOR_BG_CARD := Color(0.15, 0.17, 0.22, 0.95)
const COLOR_BG_BUTTON := Color(0.18, 0.20, 0.24)
const COLOR_BG_BUTTON_HOVER := Color(0.25, 0.28, 0.32)

const COLOR_ACCENT_PRIMARY := Color(0.33, 0.85, 0.82)
const COLOR_ACCENT_SECONDARY := Color(0.25, 0.55, 0.53)
const COLOR_ACCENT_PRESSED := Color(0.33, 0.85, 0.82)

const COLOR_TEXT_PRIMARY := Color(0.92, 0.93, 0.94)
const COLOR_TEXT_SECONDARY := Color(0.65, 0.67, 0.70)
const COLOR_TEXT_MUTED := Color(0.40, 0.42, 0.45)
const COLOR_TEXT_DARK := Color(0.12, 0.14, 0.18)

# === FIRE METAPHOR COLORS ===
const COLOR_WILDFIRE := Color(0.90, 0.25, 0.20)
const COLOR_VOLCANO := Color(0.85, 0.50, 0.15)
const COLOR_CAMPFIRE := Color(0.90, 0.75, 0.20)
const COLOR_SPARK := Color(0.60, 0.62, 0.55)

# === HEALTH STATE COLORS ===
const COLOR_HEALTH_GOOD := Color(0.30, 0.80, 0.50)
const COLOR_HEALTH_WARNING := Color(0.90, 0.75, 0.20)
const COLOR_HEALTH_CRITICAL := Color(0.90, 0.25, 0.20)

# === DIMENSION COLORS ===
const COLOR_DIM_BUDGET := Color(0.90, 0.30, 0.30)
const COLOR_DIM_SCHEDULE := Color(0.90, 0.50, 0.20)
const COLOR_DIM_QUALITY := Color(0.85, 0.75, 0.25)
const COLOR_DIM_TRUST := Color(0.60, 0.35, 0.80)

# === FONT SIZES ===
const FONT_SIZE_XS := 8
const FONT_SIZE_SM := 10
const FONT_SIZE_MD := 14
const FONT_SIZE_LG := 18
const FONT_SIZE_XL := 22

# === AVATAR ===
const AVATAR_SIZE := Vector2(48, 48)
const AVATAR_BORDER_WIDTH := 2
const AVATAR_BORDER_COLOR := COLOR_ACCENT_SECONDARY

# === PULSE ANIMATION ===
const PULSE_DURATION := 2.0
const PULSE_MIN_ALPHA := 0.6
const PULSE_MAX_ALPHA := 1.0

static func get_fire_color(category: String) -> Color:
	match category:
		"wildfire":
			return COLOR_WILDFIRE
		"volcano":
			return COLOR_VOLCANO
		"campfire":
			return COLOR_CAMPFIRE
		"spark":
			return COLOR_SPARK
		_:
			return COLOR_TEXT_MUTED

static func get_health_color(label: String) -> Color:
	match label:
		"On Track", "Confident", "Ahead", "Excellent", "Enthusiastic":
			return COLOR_HEALTH_GOOD
		"Strained", "Slipping", "Declining", "Concerned", "Tightening", "Neutral":
			return COLOR_HEALTH_WARNING
		"Critical", "Lost Confidence", "Depleted", "At Risk", "Deficient":
			return COLOR_HEALTH_CRITICAL
		_:
			return COLOR_TEXT_PRIMARY

static func get_dimension_color(dimension: String) -> Color:
	match dimension:
		"budget":
			return COLOR_DIM_BUDGET
		"schedule":
			return COLOR_DIM_SCHEDULE
		"quality":
			return COLOR_DIM_QUALITY
		"stakeholder_trust":
			return COLOR_DIM_TRUST
		_:
			return COLOR_TEXT_PRIMARY

static func create_panel_stylebox(bg_color: Color = COLOR_BG_PANEL, border_color: Color = COLOR_ACCENT_SECONDARY, border_width: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_right = border_width
	style.border_width_top = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style

static func create_button_stylebox(bg_color: Color, border_color: Color, border_width: int = 1) -> StyleBoxFlat:
	var style := create_panel_stylebox(bg_color, border_color, border_width)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

static func create_avatar_frame_stylebox() -> StyleBoxFlat:
	return create_panel_stylebox(Color(0.08, 0.10, 0.13, 0.95), AVATAR_BORDER_COLOR, AVATAR_BORDER_WIDTH)

static func create_avatar_placeholder(initial: String, size: Vector2 = AVATAR_SIZE) -> Control:
	var holder := PanelContainer.new()
	holder.custom_minimum_size = size
	holder.add_theme_stylebox_override("panel", create_avatar_frame_stylebox())

	var label := Label.new()
	label.text = initial
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.anchors_preset = Control.PRESET_FULL_RECT
	label.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
	label.add_theme_font_size_override("font_size", FONT_SIZE_LG)
	holder.add_child(label)
	return holder

static func style_avatar_texture(texture_rect: TextureRect) -> void:
	texture_rect.custom_minimum_size = AVATAR_SIZE
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

static func style_button(button: Button, primary: bool = false, disabled: bool = false) -> void:
	var normal_bg := COLOR_BG_BUTTON
	var normal_text := COLOR_TEXT_PRIMARY
	var border := COLOR_ACCENT_SECONDARY
	if primary:
		normal_bg = COLOR_ACCENT_PRIMARY
		normal_text = COLOR_TEXT_DARK
		border = COLOR_ACCENT_PRIMARY
	if disabled:
		normal_bg = Color(COLOR_BG_BUTTON.r, COLOR_BG_BUTTON.g, COLOR_BG_BUTTON.b, 0.9)
		normal_text = COLOR_TEXT_MUTED
		border = COLOR_TEXT_MUTED

	button.add_theme_stylebox_override("normal", create_button_stylebox(normal_bg, border, 1))
	button.add_theme_stylebox_override("hover", create_button_stylebox(COLOR_BG_BUTTON_HOVER if not primary else COLOR_ACCENT_PRIMARY.lightened(0.08), COLOR_ACCENT_PRIMARY, 1))
	button.add_theme_stylebox_override("pressed", create_button_stylebox(COLOR_ACCENT_PRESSED, COLOR_ACCENT_PRIMARY, 1))
	button.add_theme_stylebox_override("disabled", create_button_stylebox(normal_bg, border, 1))
	button.add_theme_color_override("font_color", normal_text)
	button.add_theme_color_override("font_hover_color", COLOR_ACCENT_PRIMARY if not primary else COLOR_TEXT_DARK)
	button.add_theme_color_override("font_pressed_color", COLOR_TEXT_DARK)
	button.add_theme_color_override("font_disabled_color", COLOR_TEXT_MUTED)
	button.add_theme_font_size_override("font_size", FONT_SIZE_SM)

static func style_line_edit(line_edit: LineEdit) -> void:
	line_edit.add_theme_stylebox_override("normal", create_panel_stylebox(COLOR_BG_PANEL, COLOR_ACCENT_SECONDARY, 1))
	line_edit.add_theme_stylebox_override("focus", create_panel_stylebox(COLOR_BG_PANEL, COLOR_ACCENT_PRIMARY, 1))
	line_edit.add_theme_stylebox_override("read_only", create_panel_stylebox(COLOR_BG_PANEL, COLOR_TEXT_MUTED, 1))
	line_edit.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
	line_edit.add_theme_color_override("font_placeholder_color", COLOR_TEXT_MUTED)
	line_edit.add_theme_color_override("caret_color", COLOR_ACCENT_PRIMARY)
	line_edit.add_theme_font_size_override("font_size", FONT_SIZE_SM)

static func start_critical_pulse(node: CanvasItem) -> Tween:
	var tween := node.create_tween()
	tween.set_loops()
	tween.tween_property(node, "modulate:a", PULSE_MIN_ALPHA, PULSE_DURATION / 2.0)
	tween.tween_property(node, "modulate:a", PULSE_MAX_ALPHA, PULSE_DURATION / 2.0)
	return tween
