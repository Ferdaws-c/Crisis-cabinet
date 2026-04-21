extends CanvasLayer

@onready var reason_label = $Panel/VBoxContainer/ReasonLabel
@onready var retry_button = $Panel/VBoxContainer/RetryButton

func _ready() -> void:
	self.visible = false
	retry_button.pressed.connect(_on_retry_pressed)

func show_audit(reason: String) -> void:
	self.visible = true
	reason_label.text = reason

func _on_retry_pressed() -> void:
	GameManager.reset_game()
	get_tree().reload_current_scene()
