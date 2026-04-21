extends Node2D

@export var pad_1_scenario: String = "SC-01"
@export var pad_2_scenario: String = "SC-02"
@export var pad_3_scenario: String = "SC-03"


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
	var active_count = 3
	if GameManager.current_difficulty == "Easy":
		active_count = 1
	elif GameManager.current_difficulty == "Medium":
		active_count = 2

	var pads = []
	if is_instance_valid(tiger_pad): pads.append(tiger_pad)
	if is_instance_valid(alligator_pad): pads.append(alligator_pad)
	if is_instance_valid(puppy_pad): pads.append(puppy_pad)
	
	pads.shuffle()
	
	for i in range(active_count, pads.size()):
		var p = pads[i]
		if p == tiger_pad: tiger_pad = null
		elif p == alligator_pad: alligator_pad = null
		elif p == puppy_pad: puppy_pad = null
		p.queue_free()

	# Prevent crashes if the user deletes a pad from the scene
	if is_instance_valid(tiger_pad): tiger_pad.connect("pad_confirmed", Callable(self, "_on_pad_confirmed"))
	if is_instance_valid(alligator_pad): alligator_pad.connect("pad_confirmed", Callable(self, "_on_pad_confirmed"))
	if is_instance_valid(puppy_pad): puppy_pad.connect("pad_confirmed", Callable(self, "_on_pad_confirmed"))


func _on_pad_confirmed(category: String) -> void:
	if completed_pads[category]: return
	
	# Determine which scenario ID belongs to this pad
	var target_scenario_id = ""
	if category == "tiger": target_scenario_id = pad_1_scenario
	elif category == "alligator": target_scenario_id = pad_2_scenario
	elif category == "puppy": target_scenario_id = pad_3_scenario
	
	
	print("Triggered Pad: ", category, " | Scenario: ", target_scenario_id)
	
	GameManager.start_assessment()
	if GameManager.game_over:
		return
	
	# Mark just THIS pad as completed
	completed_pads[category] = true
	
	# Hide the animated sprite dynamically regardless of what you named it in the scene tree
	var triggered_pad = null
	if category == "tiger": triggered_pad = tiger_pad
	elif category == "alligator": triggered_pad = alligator_pad
	elif category == "puppy": triggered_pad = puppy_pad
	
	if triggered_pad:
		for child in triggered_pad.get_children():
			if child is AnimatedSprite2D:
				child.hide()
	
	var scenario_data = GameManager.get_scenario_by_id(target_scenario_id)
	var popup = get_tree().root.find_child("ScenarioPopup", true, false)
	if popup:
		popup.show_popup(scenario_data, category)
	else:
		printerr("ScenarioPopup not found in scene tree!")
