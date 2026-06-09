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

# Minigame / Arcade Variables
var speed_multiplier: float = 1.0
var _speed_tick: float = 0.0
var _days_tick: float = 0.0
var minigame_scores: Array = []   # [{id, score, budget_delta, days_delta}]

# Dynamic State
var current_player_name: String = "Guest"
var current_phase: String = "Planning"
var is_movement_paused: bool = false
var game_over: bool = false
var has_read_info: bool = false
var has_saved_score: bool = false
var decision_log: Array = []
var total_play_time: float = 0.0

# JSON Data
var scenarios: Array = []

# Resource limits
var tile_move_cost: int = 500
const ASSESSMENT_FEE: int = 5000
var low_budget_threshold: int = 0
var current_difficulty: String = "Easy"
var timer_enabled: bool = true
var randomizer_mode: bool = false
var randomizer_pool: Array = []
var is_in_minigame: bool = false  # true only while a minigame is actively running

# Stores data for the cloud upload — consumed by Credits.gd after scene is stable
var _pending_cloud_upload: Dictionary = {}

signal state_changed

func _ready() -> void:
	SilentWolf.configure({
		"api_key": "xHgFTL1PCKN3hUge8BV061Dvuv4Vzdu47I69NXMg",
		"game_id": "crisiscabinet",
		"log_level": 1
	})
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
	randomizer_pool.clear()
	minigame_scores.clear()
	game_over = false
	GPAFLogger.start_session()
	is_movement_paused = false
	is_in_minigame = false
	has_read_info = false
	has_saved_score = false
	total_play_time = 0.0
	speed_multiplier = 1.0
	_speed_tick = 0.0
	minigame_scores.clear()
	
	stats_tiger = {"c": 0, "t": 0}
	stats_alligator = {"c": 0, "t": 0}
	stats_puppy = {"c": 0, "t": 0}
	stats_kitten = {"c": 0, "t": 0}
	
	emit_signal("state_changed")

func _process(delta: float) -> void:
	var current_scene = get_tree().current_scene
	if not is_instance_valid(current_scene) or current_scene.name != "MainFacility":
		return

	if not game_over and current_phase != "Finished":
		# Always count total play time — includes minigame time
		total_play_time += delta
		
		if not is_movement_paused:
			# Days countdown pauses whenever movement is paused
			# (minigames, popups, menus, CEO, result screen, instruction screen, etc.)
			_days_tick += delta
			if _days_tick >= 2.0:
				_days_tick -= 2.0
				schedule_days -= 1
				emit_signal("state_changed")
				if schedule_days <= 0:
					trigger_game_over("Project deadline missed!")
		
		# Global speed escalation — increases 5% every 10 seconds (caps at 2.5×)
		_speed_tick += delta
		if _speed_tick >= 10.0:
			_speed_tick = 0.0
			speed_multiplier = min(speed_multiplier + 0.05, 2.5)

## Called by MinigameOverlay when a minigame finishes.
func on_minigame_complete(mg_id: String, score: int, budget_delta: int, days_delta: int, time_taken: float = 0.0) -> void:
	point_score += score
	budget = clampi(budget + budget_delta, 0, 999999)
	schedule_days = clampi(schedule_days + days_delta, 0, 999)
	scenarios_completed += 1
	minigame_scores.append({
		"id": mg_id, "score": score,
		"budget_delta": budget_delta, "days_delta": days_delta
	})
	var is_success = score > 0 and time_taken >= 5.0
	# Log into decision_log for scoreboard viewer
	decision_log.append({
		"title": mg_id,
		"score": score,
		"time_taken": time_taken,
		"is_success": is_success,
		"classify": is_success,
		"strategy": is_success,
		"mitigate": is_success,
		"game_time": total_play_time,
		"real_time": _get_real_time()
	})
	_update_phase()
	emit_signal("state_changed")
	
	# GPAF Analytics Logging
	GPAFLogger.log_score_update(point_score)
	GPAFLogger.log_level_complete(scenarios_completed)
	if budget <= 0:
		trigger_game_over("Budget depleted!")
	elif schedule_days <= 0:
		trigger_game_over("Project deadline missed!")

func _get_real_time() -> String:
	var d: Dictionary = Time.get_datetime_dict_from_system()
	return "%d-%02d-%02d %02d:%02d:%02d" % [d.year, d.month, d.day, d.hour, d.minute, d.second]

func _update_phase() -> void:
	var max_s: int = 12
	if current_difficulty == "Easy": max_s = 4
	elif current_difficulty == "Medium": max_s = 8
	var quarter: int = max_s / 4
	if scenarios_completed >= max_s:
		current_phase = "Finished"
	elif scenarios_completed >= quarter * 3:
		current_phase = "Closing"
	elif scenarios_completed >= quarter * 2:
		current_phase = "Monitoring"
	elif scenarios_completed >= quarter:
		current_phase = "Executing"
	else:
		current_phase = "Planning"

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
				#print("Loaded %d scenarios." % scenarios.size())
			elif data.has("scenarios"):
				scenarios = data["scenarios"]
				#print("Loaded %d scenarios." % scenarios.size())
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

func mark_scenario_complete(passed: bool = true) -> void:
	scenarios_completed += 1
	var old_phase = current_phase
	
	if passed:
		var base_xp = 110
			
		# Award XP based on streak (base XP + 10% extra per streak point)
		var streak_multiplier = 1.0 + (streak * 0.1)
		xp_score += int(base_xp * streak_multiplier)
	
	var max_s = 12
	if current_difficulty == "Easy": max_s = 4
	elif current_difficulty == "Medium": max_s = 8
	
	var quarter: int = int(float(max_s) / 4.0)
	if scenarios_completed >= max_s:
		current_phase = "Finished"
	elif scenarios_completed >= quarter * 3:
		current_phase = "Closing"
	elif scenarios_completed >= quarter * 2:
		current_phase = "Monitoring"
	elif scenarios_completed >= quarter * 1:
		current_phase = "Executing"
	else:
		current_phase = "Planning"
	
	#if old_phase != current_phase:
		#print("PHASE TRANSITION: %s -> %s (Scenario %d/%d)" % [old_phase, current_phase, scenarios_completed, max_s])
		
	emit_signal("state_changed")

func trigger_game_over(reason: String) -> void:
	game_over = true
	is_movement_paused = true
	#print("GAME OVER: ", reason)
	
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
	
	# GPAF Analytics Logging
	GPAFLogger.end_session(not game_over)
	var scores = get_high_scores()
	
	var max_budget_val = 200000.0
	var max_s = 4.0
	if current_difficulty == "Medium":
		max_budget_val = 150000.0
		max_s = 8.0
	elif current_difficulty == "Hard":
		max_budget_val = 100000.0
		max_s = 12.0
		
	var safe_budget = max(0, budget)
	var budget_score = (float(safe_budget) / max_budget_val) * 50.0
	
	var xp_max = max_s * 110.0 * 1.5
	var xp_pct = clamp(float(xp_score) / xp_max, 0.0, 1.0)
	var perf_score = xp_pct * 50.0
	
	var composite_score = int(budget_score + perf_score)
	
	# Penalise for missing the deadline
	if schedule_days < 0:
		composite_score -= abs(schedule_days)
		
	composite_score = clamp(composite_score, 0, 100)
	
	var diff_label = current_difficulty
	if randomizer_mode:
		diff_label += " [Random]"
	
	# Build a yyyy/mm/dd date string for display
	var dt: Dictionary = Time.get_datetime_dict_from_system()
	var date_str: String = "%04d/%02d/%02d" % [dt.year, dt.month, dt.day]
	
	scores.append({
		"name": current_player_name, 
		"diff": diff_label, 
		"score": composite_score, 
		"budget": budget, 
		"xp": point_score,
		"time": total_play_time,
		"date": date_str,
		"log": decision_log.duplicate(true)  # deep copy so reset_game can't wipe it
	})
	
	# Sort descending by score
	scores.sort_custom(func(a, b): return a["score"] > b["score"])
	# Keep top 10 locally
	if scores.size() > 10:
		scores = scores.slice(0, 10)
	
	# ── Write local file FIRST (synchronous, always safe) ──
	var f = FileAccess.open("user://scoreboard.json", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(scores))
		f.close()
	
	# ── Upload to cloud immediately so scores are not lost if the game crashes ──
	if not randomizer_mode:
		var meta = {
			"diff":   current_difficulty,
			"budget": budget,
			"xp":     point_score,
			"time":   total_play_time,
			"date":   date_str,
			"log":    decision_log.duplicate(true)
		}
		SilentWolf.Scores.save_score(current_player_name, composite_score, "main", meta)
	
	_pending_cloud_upload = {}

func get_pending_upload() -> Dictionary:
	return _pending_cloud_upload

func clear_pending_upload() -> void:
	_pending_cloud_upload = {}


func get_random_minigame() -> String:
	if randomizer_pool.is_empty():
		randomizer_pool = MinigameOverlay.MINIGAME_DATA.keys().duplicate()
		randomizer_pool.shuffle()
	return randomizer_pool.pop_back()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F2:
			_insert_f2_test_data()

func _insert_f2_test_data() -> void:
	print("F2 Debug: Inserting test data...")
	var test_log = [
		{
			"classify": true,
			"game_time": 42.1420835206314,
			"is_success": true,
			"mitigate": true,
			"real_time": "2026-06-09 11:16:45",
			"score": 375.0,
			"strategy": true,
			"time_taken": 30.0048203777764,
			"title": "MG03"
		},
		{
			"classify": true,
			"game_time": 92.1528666317514,
			"is_success": true,
			"mitigate": true,
			"real_time": "2026-06-09 11:17:36",
			"score": 1950.0,
			"strategy": true,
			"time_taken": 45.0038386666641,
			"title": "MG02"
		},
		{
			"classify": true,
			"game_time": 131.121681076194,
			"is_success": true,
			"mitigate": true,
			"real_time": "2026-06-09 11:18:15",
			"score": 1850.0,
			"strategy": true,
			"time_taken": 35.4329861111047,
			"title": "MG01"
		},
		{
			"classify": true,
			"game_time": 164.398133565136,
			"is_success": true,
			"mitigate": true,
			"real_time": "2026-06-09 11:18:48",
			"score": 1150.0,
			"strategy": true,
			"time_taken": 24.6583969333295,
			"title": "MG05"
		},
		{
			"classify": true,
			"game_time": 213.519551231887,
			"is_success": true,
			"mitigate": true,
			"real_time": "2026-06-09 11:19:38",
			"score": 1040.0,
			"strategy": true,
			"time_taken": 45.0036256666605,
			"title": "MG06"
		},
		{
			"classify": true,
			"game_time": 238.462733009709,
			"is_success": true,
			"mitigate": true,
			"real_time": "2026-06-09 11:20:04",
			"score": 6300.0,
			"strategy": true,
			"time_taken": 20.4501262222178,
			"title": "MG04"
		},
		{
			"classify": true,
			"game_time": 288.228668927725,
			"is_success": true,
			"mitigate": true,
			"real_time": "2026-06-09 11:20:56",
			"score": 5300.0,
			"strategy": true,
			"time_taken": 45.0062136957861,
			"title": "MG09"
		},
		{
			"classify": true,
			"game_time": 338.524092705444,
			"is_success": true,
			"mitigate": true,
			"real_time": "2026-06-09 11:21:47",
			"score": 6900.0,
			"strategy": true,
			"time_taken": 45.0040957777771,
			"title": "MG07"
		},
		{
			"classify": true,
			"game_time": 387.245916055282,
			"is_success": true,
			"mitigate": true,
			"real_time": "2026-06-09 11:22:36",
			"score": 5300.0,
			"strategy": true,
			"time_taken": 45.0012286833301,
			"title": "MG08"
		},
		{
			"classify": true,
			"game_time": 437.930175055131,
			"is_success": true,
			"mitigate": true,
			"real_time": "2026-06-09 11:23:27",
			"score": 10250.0,
			"strategy": true,
			"time_taken": 45.0047615555528,
			"title": "MG12"
		},
		{
			"classify": true,
			"game_time": 488.054612654993,
			"is_success": true,
			"mitigate": true,
			"real_time": "2026-06-09 11:24:17",
			"score": 5450.0,
			"strategy": true,
			"time_taken": 45.0067095999981,
			"title": "MG10"
		},
		{
			"classify": true,
			"game_time": 538.366670254817,
			"is_success": true,
			"mitigate": true,
			"real_time": "2026-06-09 11:25:08",
			"score": 2850.0,
			"strategy": true,
			"time_taken": 45.0068415999971,
			"title": "MG11"
		}
	]
	
	decision_log = test_log.duplicate(true)
	minigame_scores.clear()
	for entry in test_log:
		minigame_scores.append({
			"id": entry.get("title", ""),
			"score": int(entry.get("score", 0)),
			"budget_delta": 0,
			"days_delta": 0
		})
	scenarios_completed = 12
	point_score = 48715
	xp_score = 48715
	budget = 236600
	schedule_days = 120
	current_phase = "Finished"
	emit_signal("state_changed")
