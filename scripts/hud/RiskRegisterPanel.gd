extends PanelContainer

var _is_open := false
var _sort_mode := "status"
var _card_scene := preload("res://scenes/hud/RiskEntryCard.tscn")

@onready var title_label: Label = $VBoxContainer/HeaderContainer/TitleLabel
@onready var close_button: Button = $VBoxContainer/HeaderContainer/CloseButton
@onready var sort_by_status_button: Button = $VBoxContainer/SortContainer/SortByStatusButton
@onready var sort_by_category_button: Button = $VBoxContainer/SortContainer/SortByCategoryButton
@onready var list_container: VBoxContainer = $VBoxContainer/ScrollContainer/RiskListContainer
@onready var add_risk_button: Button = $VBoxContainer/AddRiskButton

func _ready() -> void:
	_apply_styles()
	SignalBus.risk_added.connect(_on_risk_added)
	SignalBus.risk_updated.connect(_on_risk_updated)
	SignalBus.register_toggle_requested.connect(toggle)
	close_button.pressed.connect(func() -> void: toggle())
	add_risk_button.pressed.connect(_on_add_risk)
	sort_by_status_button.pressed.connect(func() -> void:
		_sort_mode = "status"
		_update_sort_button_styles()
		_rebuild_list()
	)
	sort_by_category_button.pressed.connect(func() -> void:
		_sort_mode = "category"
		_update_sort_button_styles()
		_rebuild_list()
	)
	visible = false
	_rebuild_list()

func _apply_styles() -> void:
	add_theme_stylebox_override("panel", StyleConstants.create_panel_stylebox())
	title_label.add_theme_color_override("font_color", StyleConstants.COLOR_ACCENT_PRIMARY)
	title_label.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_SM)
	StyleConstants.style_button(close_button, false)
	StyleConstants.style_button(add_risk_button, true)
	_update_sort_button_styles()

func _update_sort_button_styles() -> void:
	StyleConstants.style_button(sort_by_status_button, _sort_mode == "status")
	StyleConstants.style_button(sort_by_category_button, _sort_mode == "category")

func toggle() -> void:
	_is_open = not _is_open
	if _is_open:
		visible = true
		_rebuild_list()
		var tween := create_tween()
		position.x = -size.x
		tween.tween_property(self, "position:x", 0.0, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	else:
		var tween := create_tween()
		tween.tween_property(self, "position:x", -size.x, 0.2)
		tween.tween_callback(func() -> void:
			visible = false
		)

func _rebuild_list() -> void:
	for child in list_container.get_children():
		child.queue_free()

	var risks: Array = GameManager.risk_register.duplicate(true)
	if _sort_mode == "status":
		risks.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return _status_order(str(a.get("status", ""))) < _status_order(str(b.get("status", "")))
		)
	else:
		risks.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return _category_order(str(a.get("matrix_category", ""))) < _category_order(str(b.get("matrix_category", "")))
		)

	if risks.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No risks identified yet"
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.add_theme_color_override("font_color", StyleConstants.COLOR_TEXT_SECONDARY)
		empty_label.add_theme_font_size_override("font_size", StyleConstants.FONT_SIZE_SM)
		list_container.add_child(empty_label)
		return

	for risk in risks:
		var card = _card_scene.instantiate()
		card.setup(risk)
		card.assess_requested.connect(func(id: String) -> void:
			SignalBus.overlay_requested.emit("res://scenes/components/RiskMatrix.tscn", {"mode": "interactive", "risk_id": id})
		)
		card.respond_requested.connect(func(id: String) -> void:
			var r := GameManager.get_risk(id)
			SignalBus.overlay_requested.emit("res://scenes/components/ResourceAllocationUI.tscn", {
				"risk_id": id,
				"risk_title": r.get("title", id),
				"available_budget": GameManager.contingency_budget,
				"available_capacity": GameManager.phase_capacity,
				"response_options": r.get("response_options", {})
			})
		)
		card.investigate_requested.connect(func(id: String) -> void:
			var r := GameManager.get_risk(id)
			var inv: Dictionary = r.get("investigation", {})
			if inv.get("available", false):
				var npc_id := str(inv.get("npc", ""))
				var dialogue_id := str(inv.get("dialogue_id", ""))
				var dialogue_data := DataManager.get_dialogue(npc_id, dialogue_id)
				var npc_info := DataManager.get_npc_info(npc_id)
				SignalBus.investigation_started.emit(id, npc_id)
				SignalBus.overlay_requested.emit("res://scenes/components/NPCDialogue.tscn", {
					"npc_name": npc_info.get("display_name", npc_id),
					"npc_role": npc_info.get("role", ""),
					"npc_avatar": npc_info.get("avatar_path", ""),
					"dialogue_tree": dialogue_data.get("tree", [])
				})
		)
		list_container.add_child(card)

func _on_risk_added(_risk_data: Dictionary) -> void:
	if _is_open:
		_rebuild_list()

func _on_risk_updated(_risk_data: Dictionary) -> void:
	if _is_open:
		_rebuild_list()

func _on_add_risk() -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "Add Hidden Risk"
	var input := LineEdit.new()
	input.placeholder_text = "Describe the risk you've identified..."
	input.custom_minimum_size.x = 250
	StyleConstants.style_line_edit(input)
	dialog.add_child(input)
	dialog.confirmed.connect(func() -> void:
		if input.text.strip_edges() != "":
			var risk_id := "HIDDEN-%d" % (GameManager.risk_register.size() + 1)
			var new_risk := {
				"id": risk_id,
				"title": input.text.strip_edges(),
				"source_type": "player_identified",
				"source_description": "Identified by player",
				"phase_identified": GameManager.current_phase,
				"layer": GameManager.current_layer,
				"probability": "",
				"impact": {"budget": "", "schedule": "", "quality": "", "scope": ""},
				"matrix_category": "",
				"response_strategy": "",
				"budget_allocated": 0,
				"capacity_allocated": 0,
				"investigated": false,
				"status": "unassessed",
				"triggered": false,
				"outcome_narrative": "",
				"base_probability": 50,
				"response_options": {},
				"if_triggered": {},
				"if_resolved": {},
				"investigation": {},
				"debrief": {},
				"ambiguous": false,
				"true_probability": -1,
				"ethical_dimension": {},
				"layer2_echo": {}
			}
			GameManager.add_risk(new_risk)
			SignalBus.hidden_risk_discovered.emit(risk_id)
		dialog.queue_free()
	)
	add_child(dialog)
	dialog.popup_centered()

func _status_order(status: String) -> int:
	match status:
		"unassessed":
			return 0
		"analyzed":
			return 1
		"response_planned":
			return 2
		"active":
			return 3
		"triggered":
			return 4
		"resolved":
			return 5
		"escalated":
			return 6
		_:
			return 7

func _category_order(category: String) -> int:
	match category:
		"wildfire":
			return 0
		"volcano":
			return 1
		"campfire":
			return 2
		"spark":
			return 3
		_:
			return 4
