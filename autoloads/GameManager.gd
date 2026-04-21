extends Node

# Persistent Variables
var contingency_hp: int = 100
var max_hp: int = 100
var budget: int = 200000
var schedule_days: int = 120
var point_score: int = 0
var xp_score: int = 0
var streak: int = 0
var best_streak: int = 0
var scenarios_completed: int = 0
var dim_scores: Dictionary = {"D1": 0, "D2": 0, "D3": 0, "D7": 0, "D8": 0}
var stats_tiger: Dictionary = {"c": 0, "t": 0}
var stats_alligator: Dictionary = {"c": 0, "t": 0}
var stats_puppy: Dictionary = {"c": 0, "t": 0}
var stats_kitten: Dictionary = {"c": 0, "t": 0}

# Dynamic State
var current_player_name: String = "Guest"
var current_phase: String = "Planning"
var is_movement_paused: bool = false
var game_over: bool = false
var has_read_info: bool = false
var has_saved_score: bool = false
var decision_log: Array = []

# JSON Data
var scenarios: Array = []

# Resource limits
var tile_move_cost: int = 500
const ASSESSMENT_FEE: int = 5000
var low_budget_threshold: int = 0
var current_difficulty: String = "Easy"
var timer_enabled: bool = true

signal state_changed

func _ready() -> void:
	low_budget_threshold = int(budget * 0.20) # 20%
	load_scenarios()

func set_difficulty(level: String) -> void:
	current_difficulty = level
	if level == "Hard":
		budget = 100000
		tile_move_cost = 500
	elif level == "Medium":
		budget = 150000
		tile_move_cost = 500
	else: # Easy
		budget = 200000
		tile_move_cost = 500
	
	low_budget_threshold = int(budget * 0.20)
	emit_signal("state_changed")

func reset_game(reset_difficulty: bool = true) -> void:
	if reset_difficulty:
		current_difficulty = "Easy"
		
	set_difficulty(current_difficulty)
		
	point_score = 0
	schedule_days = 120
	xp_score = 0
	streak = 0
	best_streak = 0
	scenarios_completed = 0
	current_phase = "Planning"
	decision_log.clear()
	game_over = false
	is_movement_paused = false
	has_read_info = false
	has_saved_score = false
	emit_signal("state_changed")

func load_scenarios() -> void:
	var file_path = "res://gppt_crisis_cabinet_v2.json"
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		var content = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var error = json.parse(content)
		if error == OK:
			var data = json.get_data()
			if data.has("state") and data["state"].has("scenarios"):
				scenarios = data["state"]["scenarios"]
				print("Loaded %d scenarios." % scenarios.size())
			elif data.has("scenarios"):
				scenarios = data["scenarios"]
				print("Loaded %d scenarios." % scenarios.size())
			else:
				printerr("Could not find scenarios key in JSON!")
		else:
			printerr("Failed to parse JSON: ", json.get_error_message())
	else:
		printerr("Scenarios JSON not found at res://gppt_crisis_cabinet_v2.json")

func walk_tile() -> void:
	pass

func start_assessment() -> void:
	if game_over:
		return
		
	budget -= ASSESSMENT_FEE
	is_movement_paused = true
	emit_signal("state_changed")

func update_health(amount: int) -> void:
	contingency_hp += amount
	if contingency_hp > max_hp:
		contingency_hp = max_hp
	elif contingency_hp <= 0:
		contingency_hp = 0
		trigger_game_over("Hard Failure: Contingency reserves depleted.")
	emit_signal("state_changed")

func add_score(amount: int) -> void:
	var multiplier = 1.5 if streak >= 3 else 1.0
	point_score += int(amount * multiplier)
	emit_signal("state_changed")

func increment_streak() -> void:
	streak += 1
	if streak > best_streak:
		best_streak = streak
	emit_signal("state_changed")

func break_streak() -> void:
	streak = 0
	emit_signal("state_changed")

func mark_scenario_complete() -> void:
	scenarios_completed += 1
	
	var base_xp = 50
	if current_difficulty == "Easy":
		base_xp = 165
	elif current_difficulty == "Medium":
		base_xp = 85
		
	# Award XP based on streak (base XP + 10% extra per streak point)
	var streak_multiplier = 1.0 + (streak * 0.1)
	xp_score += int(base_xp * streak_multiplier)
	
	var max_s = 12
	if current_difficulty == "Easy": max_s = 4
	elif current_difficulty == "Medium": max_s = 8
	
	if scenarios_completed >= max_s * 0.75:
		current_phase = "Closing"
	elif scenarios_completed >= max_s * 0.50:
		current_phase = "Monitoring"
	elif scenarios_completed >= max_s * 0.25:
		current_phase = "Executing"
	else:
		current_phase = "Planning"
	emit_signal("state_changed")

func trigger_game_over(reason: String) -> void:
	game_over = true
	is_movement_paused = true
	print("GAME OVER: ", reason)
	
	save_high_score()
	
	var audit = get_tree().root.find_child("AuditScreen", true, false)
	if audit:
		audit.visible = true
		audit.show_audit(reason)
	else:
		printerr("AuditScreen not found in scene tree!")
	
func is_low_budget() -> bool:
	return budget <= low_budget_threshold

func get_scenario_by_id(id: String) -> Dictionary:
	for s in scenarios:
		if s.has("id") and s["id"] == id:
			return s
	printerr("GameManager: No scenario found for ID: ", id)
	return {}

func get_high_scores() -> Array:
	if not FileAccess.file_exists("user://scoreboard.json"):
		return []
	var f = FileAccess.open("user://scoreboard.json", FileAccess.READ)
	var json = JSON.new()
	if json.parse(f.get_as_text()) == OK:
		return json.data
	return []

func save_high_score() -> void:
	if has_saved_score: return
	has_saved_score = true
	var scores = get_high_scores()
	scores.append({
		"name": current_player_name, 
		"diff": current_difficulty, 
		"score": point_score, 
		"budget": budget, 
		"xp": xp_score
	})
	# Sort descending by score
	scores.sort_custom(func(a, b): return a["score"] > b["score"])
	# Keep top 10
	if scores.size() > 10:
		scores = scores.slice(0, 10)
	var f = FileAccess.open("user://scoreboard.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(scores))
