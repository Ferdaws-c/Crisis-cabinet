extends Node2D

## RiskRoom — manages its 3 TuslerPads and difficulty-based filtering.
## Minigame IDs are assigned via exports directly on this node (set in MainFacility.tscn).

@export var pad_1_scenario: String = "SC-01"  # kept for legacy compat
@export var pad_2_scenario: String = "SC-02"
@export var pad_3_scenario: String = "SC-03"

## Which minigame each pad launches — SET THESE in the Inspector per RiskRoom instance
@export var pad_1_minigame: String = "MG01"   # TigerPad
@export var pad_2_minigame: String = "MG02"   # AlligatorPad
@export var pad_3_minigame: String = "MG03"   # PuppyPad

@onready var tiger_pad = $TigerPad
@onready var alligator_pad = $AlligatorPad
@onready var puppy_pad = $PuppyPad

var completed_pads: Dictionary = {
	"tiger": false,
	"alligator": false,
	"puppy": false,
	"kitten": false
}

func _ready() -> void:
	var active_count: int = 3
	if GameManager.current_difficulty == "Easy":
		active_count = 1
	elif GameManager.current_difficulty == "Medium":
		active_count = 2

	# Fixed priority order: Tiger (pad 1), Alligator (pad 2), Puppy (pad 3)
	var pads: Array = []
	if is_instance_valid(tiger_pad): pads.append(tiger_pad)
	if is_instance_valid(alligator_pad): pads.append(alligator_pad)
	if is_instance_valid(puppy_pad): pads.append(puppy_pad)

	# Remove excess pads beyond active count
	for i in range(active_count, pads.size()):
		var p = pads[i]
		if p == tiger_pad: tiger_pad = null
		elif p == alligator_pad: alligator_pad = null
		elif p == puppy_pad: puppy_pad = null
		p.queue_free()

	# Connect remaining pads
	if is_instance_valid(tiger_pad):
		tiger_pad.connect("pad_confirmed", Callable(self, "_on_pad_confirmed"))
	if is_instance_valid(alligator_pad):
		alligator_pad.connect("pad_confirmed", Callable(self, "_on_pad_confirmed"))
	if is_instance_valid(puppy_pad):
		puppy_pad.connect("pad_confirmed", Callable(self, "_on_pad_confirmed"))

func _on_pad_confirmed(category: String) -> void:
	if completed_pads[category]: return
	if GameManager.game_over: return

	# Read minigame ID directly from this room's exports — reliable across all instances
	var mg_id: String = "MG01"
	var triggered_pad: Node = null
	match category:
		"tiger":
			triggered_pad = tiger_pad
			mg_id = pad_1_minigame
		"alligator":
			triggered_pad = alligator_pad
			mg_id = pad_2_minigame
		"puppy":
			triggered_pad = puppy_pad
			mg_id = pad_3_minigame

	if GameManager.randomizer_mode:
		mg_id = GameManager.get_random_minigame()

	#print("Triggered Pad: ", category, " | Minigame: ", mg_id)

	# Mark pad completed immediately to prevent double-triggers
	completed_pads[category] = true

	# Hide the pad sprite
	if is_instance_valid(triggered_pad):
		for child in triggered_pad.get_children():
			if child is AnimatedSprite2D:
				child.hide()

	# Pause world movement while minigame is open
	GameManager.is_movement_paused = true

	# MinigameOverlay is a global autoload — call directly, passing self and category so it can be un-consumed if cancelled
	MinigameOverlay.launch(mg_id, self, category)

func unconsume_pad(category: String) -> void:
	completed_pads[category] = false
	var pad: Node = null
	match category:
		"tiger": pad = tiger_pad
		"alligator": pad = alligator_pad
		"puppy": pad = puppy_pad
	
	if is_instance_valid(pad):
		for child in pad.get_children():
			if child is AnimatedSprite2D:
				child.show()
