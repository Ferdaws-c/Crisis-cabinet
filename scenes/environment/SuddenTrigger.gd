extends Area2D

@export var scenario_id: String = "SC-04" # Must match a sudden risk ID in the JSON
var triggered: bool = false

func _ready() -> void:
	self.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" and not triggered:
		triggered = true
		GameManager.is_movement_paused = true
		
		# Enable glitch shader
		var glitch_overlay = get_tree().root.find_child("GlitchOverlay", true, false)
		if glitch_overlay:
			glitch_overlay.visible = true
			
		#print("SUDDEN RISK TRIGGERED: ", scenario_id)
		
		# Wait for glitch effect to play
		await get_tree().create_timer(1.0).timeout
		if glitch_overlay:
			glitch_overlay.visible = false
		
		# Now open the ScenarioPopup with this scenario
		var scenario_data = GameManager.get_scenario_by_id(scenario_id)
		if scenario_data.is_empty():
			printerr("SuddenTrigger: No scenario found for ID: ", scenario_id)
			GameManager.is_movement_paused = false
			return
			
		var popup = get_tree().root.find_child("ScenarioPopup", true, false)
		if popup:
			popup.show_popup(scenario_data, "unknown")
		else:
			printerr("SuddenTrigger: ScenarioPopup not found!")
			GameManager.is_movement_paused = false
