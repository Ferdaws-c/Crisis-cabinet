extends Area2D

# The specific category of this pad (Tiger, Alligator, Puppy, Kitten)
@export var category: String = "tiger"

var is_player_on_pad: bool = false
var hold_time: float = 0.0
const REQUIRED_HOLD_TIME: float = 0.5

signal pad_confirmed(category)

func _ready() -> void:
	self.body_entered.connect(_on_body_entered)
	self.body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	if is_player_on_pad and not GameManager.is_movement_paused:
		hold_time += delta
		# If we had a progressbar child, update it here
		# $ProgressBar.value = (hold_time / REQUIRED_HOLD_TIME) * 100
		if hold_time >= REQUIRED_HOLD_TIME:
			is_player_on_pad = false
			hold_time = 0.0
			emit_signal("pad_confirmed", category)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		is_player_on_pad = true
		# $ProgressBar.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		is_player_on_pad = false
		hold_time = 0.0
		# $ProgressBar.visible = false
		# $ProgressBar.value = 0
