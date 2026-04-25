extends Node

signal state_changed

# === PROGRESSION FLAGS ===
var current_layer: int = 1  # 1, 2, or 3
var current_phase: String = "Planning"  # "planning", "execution", etc.

# Layer 1 completion
var station_1_complete: bool = false
var station_2_complete: bool = false
var station_3_complete: bool = false
var station_4_complete: bool = false
var station_5_complete: bool = false
var station_6_complete: bool = false
var layer1_complete: bool = false

# Layer 2 completion
var layer2_complete: bool = false

# Layer 3 completion
var layer3_complete: bool = false

# === PROJECT HEALTH (internal 0-100 values) ===
var health_budget: int = 100
var health_schedule: int = 100
var health_quality: int = 100
var health_stakeholder_trust: int = 100

# Health state thresholds
# The game reads these to convert numeric values to display labels
# "base" uses 3 tiers; add more tiers by adding entries
var health_thresholds: Dictionary = {
    "budget": [
        {"label": "On Track", "min": 60},
        {"label": "Strained", "min": 30},
        {"label": "Critical", "min": 0}
    ],
    "schedule": [
        {"label": "On Track", "min": 60},
        {"label": "Slipping", "min": 30},
        {"label": "Critical", "min": 0}
    ],
    "quality": [
        {"label": "On Track", "min": 60},
        {"label": "Declining", "min": 30},
        {"label": "Critical", "min": 0}
    ],
    "stakeholder_trust": [
        {"label": "Confident", "min": 60},
        {"label": "Concerned", "min": 30},
        {"label": "Lost Confidence", "min": 0}
    ]
}

# Client priority multipliers (how much each dimension affects trust)
var client_sensitivity: Dictionary = {
    "budget": 0.5,
    "schedule": 2.0,
    "quality": 1.5,
    "scope": 1.0
}

# === RESOURCES ===
var contingency_budget: int = 50000  # starting value, difficulty-dependent
var phase_capacity: int = 12  # person-weeks, resets each phase
var budget_spent_this_phase: int = 0
var capacity_spent_this_phase: int = 0

# === RISK REGISTER ===
# Each risk is a Dictionary with fields matching the schema in Section 3.2
var risk_register: Array = []

# === CLIENT PROFILES ===
var client_profile_active: Dictionary = {
    "name": "Dana",
    "company": "SecurePay",
    "budget_tolerance": "high",
    "schedule_flexibility": "low",
    "quality_standards": "high",
    "scope_flexibility": "high"
}

# Layer 3: shifted or second profile
var client_profile_shifted: Dictionary = {}
var stakeholder_conflict_active: bool = false

# === PERFORMANCE TRACKING ===
var layer1_performance: Dictionary = {
    "station_1_accuracy": 0.0,
    "station_2_accuracy": 0.0,
    "station_3_accuracy": 0.0,
    "station_4_accuracy": 0.0,
    "station_5_strategy_chosen": "",
    "station_6_hints_used": 0,
    "station_6_strategy_chosen": ""
}

var layer2_performance: Dictionary = {
    "risks_identified": 0,
    "risks_total": 0,
    "hidden_risks_found": 0,
    "hidden_risks_total": 0,
    "investigations_conducted": 0,
    "investigations_available": 0,
    "risks_triggered": 0,
    "risks_mitigated_successfully": 0,
    "budget_remaining": 0,
    "capacity_unused_total": 0,
    "honest_communications": 0,
    "deflective_communications": 0,
    "final_health": {}
}

var layer3_performance: Dictionary = {
    "risks_identified": 0,
    "risks_total": 0,
    "hidden_risks_found": 0,
    "hidden_risks_total": 0,
    "investigations_conducted": 0,
    "investigations_available": 0,
    "ambiguous_assessments": [],
    "ethical_decisions": [],
    "management_profile": "",
    "final_health": {}
}

# === FAILURE STATE ===
var failure_triggered: bool = false
var failure_condition: String = ""
var failure_phase: String = ""

# === PHASE HISTORY ===
# Stores the result of each phase for debrief and cascade tracking
var phase_results: Array = []

# === LEGACY COMPATIBILITY STATE ===
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
var current_player_name: String = "Guest"
var is_movement_paused: bool = false
var game_over: bool = false
var has_read_info: bool = false
var has_saved_score: bool = false
var decision_log: Array = []
var total_play_time: float = 0.0
var scenarios: Array = []
var tile_move_cost: int = 500
const ASSESSMENT_FEE: int = 5000
var low_budget_threshold: int = 0
var current_difficulty: String = "Easy"
var timer_enabled: bool = true

func _ready() -> void:
    low_budget_threshold = int(budget * 0.20)
    load_scenarios()
    set_process(true)

func _process(delta: float) -> void:
    if not is_movement_paused and not game_over and current_phase != "Finished":
        total_play_time += delta

# === HELPER METHODS ===

func get_health_label(dimension: String) -> String:
    var value = get("health_" + dimension)
    var thresholds = health_thresholds[dimension]
    for threshold in thresholds:
        if value >= threshold["min"]:
            return threshold["label"]
    return thresholds[-1]["label"]

func apply_health_impact(impact: Dictionary) -> void:
    if impact.has("budget"):
        health_budget = clampi(health_budget + impact["budget"], 0, 100)
    if impact.has("schedule"):
        health_schedule = clampi(health_schedule + impact["schedule"], 0, 100)
    if impact.has("quality"):
        health_quality = clampi(health_quality + impact["quality"], 0, 100)
    if impact.has("stakeholder_trust"):
        health_stakeholder_trust = clampi(health_stakeholder_trust + impact["stakeholder_trust"], 0, 100)
    SignalBus.health_changed.emit()
    emit_signal("state_changed")
    _check_failure_conditions()

func spend_budget(amount: int) -> bool:
    if contingency_budget >= amount:
        contingency_budget -= amount
        budget_spent_this_phase += amount
        SignalBus.resources_changed.emit()
        emit_signal("state_changed")
        return true
    return false

func spend_capacity(amount: int) -> bool:
    if phase_capacity >= amount:
        phase_capacity -= amount
        capacity_spent_this_phase += amount
        SignalBus.resources_changed.emit()
        emit_signal("state_changed")
        return true
    return false

func reset_phase_capacity(amount: int = 12) -> void:
    phase_capacity = amount
    capacity_spent_this_phase = 0
    budget_spent_this_phase = 0
    SignalBus.resources_changed.emit()
    emit_signal("state_changed")

func add_risk(risk_data: Dictionary) -> void:
    risk_register.append(risk_data)
    SignalBus.risk_added.emit(risk_data)

func update_risk(risk_id: String, updates: Dictionary) -> void:
    for risk in risk_register:
        if risk["id"] == risk_id:
            risk.merge(updates, true)
            SignalBus.risk_updated.emit(risk)
            break

func get_risk(risk_id: String) -> Dictionary:
    for risk in risk_register:
        if risk["id"] == risk_id:
            return risk
    return {}

func get_risks_by_status(status: String) -> Array:
    return risk_register.filter(func(r): return r["status"] == status)

func _check_failure_conditions() -> void:
    var critical_count := 0
    if health_budget < 30:
        critical_count += 1
    if health_schedule < 30:
        critical_count += 1
    if health_quality < 30:
        critical_count += 1
    if health_stakeholder_trust < 30:
        critical_count += 1

    # Condition 1: Dual critical
    if critical_count >= 2:
        _trigger_failure("dual_critical")
        return

    # Condition 2: Trust collapse + another dimension low
    if get_health_label("stakeholder_trust") == "Lost Confidence":
        if health_budget < 60 or health_schedule < 60 or health_quality < 60:
            _trigger_failure("trust_collapse")
            return

    # Condition 3: Budget exhaustion (checked when trying to spend)
    if contingency_budget <= 0:
        var unaddressed := get_risks_by_status("unassessed")
        if unaddressed.size() > 0:
            _trigger_failure("budget_exhaustion")
            return

func _trigger_failure(condition: String) -> void:
    if failure_triggered:
        return
    failure_triggered = true
    failure_condition = condition
    failure_phase = current_phase
    SignalBus.failure_triggered.emit(condition, current_phase)

# === LEGACY COMPATIBILITY HELPERS ===

func set_difficulty(level: String) -> void:
    current_difficulty = level
    if level == "Hard":
        budget = 100000
        tile_move_cost = 500
    elif level == "Medium":
        budget = 150000
        tile_move_cost = 500
    else:
        budget = 200000
        tile_move_cost = 500

    low_budget_threshold = int(budget * 0.20)
    emit_signal("state_changed")

func reset_game(reset_difficulty: bool = true) -> void:
    if reset_difficulty:
        current_difficulty = "Easy"

    set_difficulty(current_difficulty)

    current_layer = 1
    current_phase = "Planning"
    station_1_complete = false
    station_2_complete = false
    station_3_complete = false
    station_4_complete = false
    station_5_complete = false
    station_6_complete = false
    layer1_complete = false
    layer2_complete = false
    layer3_complete = false

    health_budget = 100
    health_schedule = 100
    health_quality = 100
    health_stakeholder_trust = 100
    contingency_budget = 50000
    phase_capacity = 12
    budget_spent_this_phase = 0
    capacity_spent_this_phase = 0
    risk_register.clear()
    failure_triggered = false
    failure_condition = ""
    failure_phase = ""
    phase_results.clear()

    contingency_hp = max_hp
    schedule_days = 120
    point_score = 0
    xp_score = 0
    streak = 0
    best_streak = 0
    scenarios_completed = 0
    decision_log.clear()
    game_over = false
    is_movement_paused = false
    has_read_info = false
    has_saved_score = false
    total_play_time = 0.0

    stats_tiger = {"c": 0, "t": 0}
    stats_alligator = {"c": 0, "t": 0}
    stats_puppy = {"c": 0, "t": 0}
    stats_kitten = {"c": 0, "t": 0}

    emit_signal("state_changed")
    SignalBus.health_changed.emit()
    SignalBus.resources_changed.emit()

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
    var multiplier := 1.5 if streak >= 3 else 1.0
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

    if passed:
        var base_xp := 110
        var streak_multiplier := 1.0 + (streak * 0.1)
        xp_score += int(base_xp * streak_multiplier)

    var max_s := 12
    if current_difficulty == "Easy":
        max_s = 4
    elif current_difficulty == "Medium":
        max_s = 8

    if scenarios_completed >= max_s:
        current_phase = "Finished"
    elif scenarios_completed >= max_s * 0.75:
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
    save_high_score()

    var audit := get_tree().root.find_child("AuditScreen", true, false)
    if audit:
        audit.visible = true
        audit.show_audit(reason)
    else:
        push_warning("GameManager: AuditScreen not found in scene tree.")

func is_low_budget() -> bool:
    return budget <= low_budget_threshold

func load_scenarios() -> void:
    var file_path := "res://gppt_crisis_cabinet_v2.json"
    if not FileAccess.file_exists(file_path):
        push_warning("GameManager: Legacy scenarios JSON not found at %s" % file_path)
        scenarios = []
        return

    var file := FileAccess.open(file_path, FileAccess.READ)
    if file == null:
        push_warning("GameManager: Failed to open %s" % file_path)
        scenarios = []
        return

    var content := file.get_as_text()
    file.close()

    var json := JSON.new()
    var error := json.parse(content)
    if error != OK:
        push_warning("GameManager: Failed to parse legacy scenarios JSON: %s" % json.get_error_message())
        scenarios = []
        return

    var data = json.get_data()
    if data.has("state") and data["state"].has("scenarios"):
        scenarios = data["state"]["scenarios"]
    elif data.has("scenarios"):
        scenarios = data["scenarios"]
    else:
        push_warning("GameManager: Could not find scenarios key in legacy JSON.")
        scenarios = []

func get_scenario_by_id(id: String) -> Dictionary:
    for s in scenarios:
        if s.has("id") and s["id"] == id:
            return s
    push_warning("GameManager: No scenario found for ID: %s" % id)
    return {}

func get_high_scores() -> Array:
    if not FileAccess.file_exists("user://scoreboard.json"):
        return []
    var f := FileAccess.open("user://scoreboard.json", FileAccess.READ)
    if f == null:
        return []
    var json := JSON.new()
    if json.parse(f.get_as_text()) == OK and json.data is Array:
        return json.data
    return []

func save_high_score() -> void:
    if has_saved_score:
        return
    has_saved_score = true
    var scores := get_high_scores()

    var composite_score := point_score + int(budget / 10.0) + xp_score - int(total_play_time * 5)
    scores.append({
        "name": current_player_name,
        "diff": current_difficulty,
        "score": composite_score,
        "budget": budget,
        "xp": xp_score,
        "time": total_play_time
    })

    scores.sort_custom(func(a, b): return a["score"] > b["score"])
    if scores.size() > 10:
        scores = scores.slice(0, 10)

    var f := FileAccess.open("user://scoreboard.json", FileAccess.WRITE)
    if f != null:
        f.store_string(JSON.stringify(scores))
