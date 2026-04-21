extends Area2D

var player_in_zone: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	# Check for "E" input when player is standing inside
	if player_in_zone:
		if Input.is_action_just_pressed("interact"):
			var ui = get_tree().root.find_child("InfoPopup", true, false)
			if ui and not ui.visible:
				ui.show_popup()

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_in_zone = true

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_in_zone = false
