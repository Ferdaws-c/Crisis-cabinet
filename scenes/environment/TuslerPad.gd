extends Area2D

# The specific category of this pad (Tiger, Alligator, Puppy, Kitten)
@export var category: String = "tiger"

var is_player_on_pad: bool = false

signal pad_confirmed(category)

func _ready() -> void:
	self.body_entered.connect(_on_body_entered)
	self.body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	if is_player_on_pad and not GameManager.is_movement_paused:
		if Input.is_key_pressed(KEY_SPACE):
			is_player_on_pad = false
			# Remove the physical collision body if it exists
			var static_body = get_node_or_null("StaticBody2D")
			if static_body:
				static_body.queue_free()
			emit_signal("pad_confirmed", category)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		is_player_on_pad = true
		# $ProgressBar.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		is_player_on_pad = false
		# $ProgressBar.visible = false
		# $ProgressBar.value = 0
