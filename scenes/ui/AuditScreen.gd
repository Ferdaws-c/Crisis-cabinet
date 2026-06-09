extends CanvasLayer

@onready var reason_label = $Panel/VBoxContainer/ReasonLabel
@onready var retry_button = $Panel/VBoxContainer/RetryButton

func _ready() -> void:
	self.visible = false
	retry_button.pressed.connect(_on_retry_pressed)
	
	var container = $Panel/VBoxContainer
	if container:
		var export_btn = Button.new()
		export_btn.text = "📥 Export GPAF JSONL Logs"
		export_btn.custom_minimum_size = Vector2(250, 40)
		export_btn.pressed.connect(func():
			GPAFLogger.export_logs_to_file(self)
		)
		container.add_child(export_btn)
		container.move_child(retry_button, container.get_child_count() - 1)

func show_audit(reason: String) -> void:
	self.visible = true
	reason_label.text = reason

func _on_retry_pressed() -> void:
	GameManager.reset_game()
	get_tree().reload_current_scene()
