# Crisis Cabinet — Master Technical Architecture & Implementation Plan

**Document version:** 1.0
**Date:** April 24, 2026
**Game engine:** Godot 4.4 (GDScript)
**Development approach:** Solo developer using Codex for implementation
**Reference documents:** Layer 1, Layer 2, and Layer 3 design documents

---

## 1. Project Structure

### Complete File and Folder Layout

```
Crisis-cabinet/
├── project.godot
│
├── assets/
│   ├── fonts/
│   ├── icons/
│   ├── sprites/
│   │   ├── characters/
│   │   │   ├── dana/
│   │   │   ├── jordan/
│   │   │   ├── alex/
│   │   │   ├── sam/
│   │   │   ├── ravi/
│   │   │   ├── morgan/
│   │   │   └── katherine/
│   │   ├── fire_metaphors/
│   │   │   ├── wildfire/
│   │   │   ├── volcano/
│   │   │   ├── campfire/
│   │   │   └── spark/
│   │   ├── ui/
│   │   └── environment/
│   └── audio/
│
├── data/
│   ├── scenarios/
│   │   ├── layer1_stations.json
│   │   ├── layer2_planning.json
│   │   ├── layer2_execution.json
│   │   ├── layer2_monitoring.json
│   │   ├── layer2_closing.json
│   │   ├── layer3_stabilization.json
│   │   ├── layer3_growth.json
│   │   ├── layer3_due_diligence.json
│   │   └── layer3_transition.json
│   ├── npc_dialogues/
│   │   ├── dana_dialogues.json
│   │   ├── jordan_dialogues.json
│   │   ├── alex_dialogues.json
│   │   ├── sam_dialogues.json
│   │   ├── ravi_dialogues.json
│   │   ├── morgan_dialogues.json
│   │   └── katherine_dialogues.json
│   ├── client_profiles.json
│   └── config.json
│
├── scenes/
│   ├── main/
│   │   ├── Main.tscn
│   │   ├── MainMenu.tscn
│   │   └── GameWorld.tscn
│   │
│   ├── hud/
│   │   ├── HUD.tscn
│   │   ├── HealthDashboard.tscn
│   │   ├── RiskRegisterPanel.tscn
│   │   ├── RiskEntryCard.tscn
│   │   ├── ResourceBar.tscn
│   │   └── RiskMatrixHUD.tscn
│   │
│   ├── components/
│   │   ├── CauseEventEffectChain.tscn
│   │   ├── EvidenceColumns.tscn
│   │   ├── RippleEffect.tscn
│   │   ├── RiskMatrix.tscn
│   │   ├── ClientProfileCard.tscn
│   │   ├── DualProfileCard.tscn
│   │   ├── ProfileShiftAnimation.tscn
│   │   ├── NPCDialogue.tscn
│   │   ├── ResourceAllocationUI.tscn
│   │   ├── AmbiguousAssessment.tscn
│   │   └── PhaseResolution.tscn
│   │
│   ├── layer1/
│   │   ├── TrainingWing.tscn
│   │   ├── Station1_Identification.tscn
│   │   ├── Station2_Probability.tscn
│   │   ├── Station3_Impact.tscn
│   │   ├── Station4_Matrix.tscn
│   │   ├── Station5_Strategies.tscn
│   │   └── Station6_FullCycle.tscn
│   │
│   ├── layer2/
│   │   ├── Phase1_Planning.tscn
│   │   ├── Phase2_Execution.tscn
│   │   ├── Phase3_Monitoring.tscn
│   │   ├── Phase4_Closing.tscn
│   │   ├── ProjectOutcome.tscn
│   │   └── DebriefScreen.tscn
│   │
│   ├── layer3/
│   │   ├── Phase1_Stabilization.tscn
│   │   ├── Phase2_Growth.tscn
│   │   ├── Phase3_DueDiligence.tscn
│   │   ├── Phase4_Transition.tscn
│   │   ├── AcquisitionOutcome.tscn
│   │   ├── ManagementProfile.tscn
│   │   └── GrowthReflection.tscn
│   │
│   └── shared/
│       ├── FailureSequence.tscn
│       ├── CascadeMap.tscn
│       └── StakeholderConversation.tscn
│
├── scripts/
│   ├── autoload/
│   │   ├── GameManager.gd
│   │   ├── DataManager.gd
│   │   └── SignalBus.gd
│   │
│   ├── hud/
│   │   ├── HUD.gd
│   │   ├── HealthDashboard.gd
│   │   ├── RiskRegisterPanel.gd
│   │   ├── RiskEntryCard.gd
│   │   ├── ResourceBar.gd
│   │   └── RiskMatrixHUD.gd
│   │
│   ├── components/
│   │   ├── CauseEventEffectChain.gd
│   │   ├── EvidenceColumns.gd
│   │   ├── RippleEffect.gd
│   │   ├── RiskMatrix.gd
│   │   ├── ClientProfileCard.gd
│   │   ├── DualProfileCard.gd
│   │   ├── ProfileShiftAnimation.gd
│   │   ├── NPCDialogue.gd
│   │   ├── ResourceAllocationUI.gd
│   │   ├── AmbiguousAssessment.gd
│   │   └── PhaseResolution.gd
│   │
│   ├── layer1/
│   │   ├── TrainingWing.gd
│   │   ├── Station1_Identification.gd
│   │   ├── Station2_Probability.gd
│   │   ├── Station3_Impact.gd
│   │   ├── Station4_Matrix.gd
│   │   ├── Station5_Strategies.gd
│   │   └── Station6_FullCycle.gd
│   │
│   ├── layer2/
│   │   ├── PhaseBase.gd
│   │   ├── Phase1_Planning.gd
│   │   ├── Phase2_Execution.gd
│   │   ├── Phase3_Monitoring.gd
│   │   ├── Phase4_Closing.gd
│   │   ├── ProjectOutcome.gd
│   │   ├── DebriefScreen.gd
│   │   └── RiskTriggerEngine.gd
│   │
│   ├── layer3/
│   │   ├── Phase1_Stabilization.gd
│   │   ├── Phase2_Growth.gd
│   │   ├── Phase3_DueDiligence.gd
│   │   ├── Phase4_Transition.gd
│   │   ├── AcquisitionOutcome.gd
│   │   ├── ManagementProfile.gd
│   │   └── GrowthReflection.gd
│   │
│   └── shared/
│       ├── FailureSequence.gd
│       ├── CascadeMap.gd
│       └── StakeholderConversation.gd
│
└── themes/
    └── default_theme.tres
```

### Autoload (Singleton) Scripts

Three scripts are registered as autoloads in `project.godot`. They are globally accessible from any script.

| Autoload Name | Script | Purpose |
|---------------|--------|---------|
| `GameManager` | `scripts/autoload/GameManager.gd` | Holds all game state — health, budget, capacity, risk register, flags, performance tracking |
| `DataManager` | `scripts/autoload/DataManager.gd` | Loads and provides access to all JSON data files — scenarios, dialogues, profiles |
| `SignalBus` | `scripts/autoload/SignalBus.gd` | Central signal hub — all cross-scene communication goes through here |

---

## 2. Scene Architecture

### 2.1 — Scene Relationship Map

```
Main.tscn
└── GameWorld.tscn
    ├── HUD.tscn (persistent overlay)
    │   ├── HealthDashboard.tscn
    │   ├── ResourceBar.tscn
    │   ├── RiskRegisterPanel.tscn (toggleable)
    │   │   └── RiskEntryCard.tscn (instantiated per risk)
    │   └── RiskMatrixHUD.tscn (toggleable, Layer 2+ only)
    │
    ├── TrainingWing.tscn (Layer 1 — contains station trigger zones)
    │   ├── Station1_Identification.tscn (popup/overlay)
    │   ├── Station2_Probability.tscn (popup/overlay)
    │   ├── Station3_Impact.tscn (popup/overlay)
    │   ├── Station4_Matrix.tscn (popup/overlay)
    │   ├── Station5_Strategies.tscn (popup/overlay)
    │   └── Station6_FullCycle.tscn (popup/overlay)
    │
    ├── Phase rooms (Layer 2 and 3 — only one active at a time)
    │   ├── Phase1_Planning.tscn / Phase1_Stabilization.tscn
    │   ├── Phase2_Execution.tscn / Phase2_Growth.tscn
    │   ├── Phase3_Monitoring.tscn / Phase3_DueDiligence.tscn
    │   └── Phase4_Closing.tscn / Phase4_Transition.tscn
    │
    └── Overlay scenes (instantiated on demand, not always present)
        ├── NPCDialogue.tscn
        ├── CauseEventEffectChain.tscn
        ├── EvidenceColumns.tscn
        ├── RippleEffect.tscn
        ├── RiskMatrix.tscn
        ├── ClientProfileCard.tscn
        ├── DualProfileCard.tscn
        ├── ResourceAllocationUI.tscn
        ├── AmbiguousAssessment.tscn
        ├── PhaseResolution.tscn
        ├── FailureSequence.tscn
        ├── CascadeMap.tscn
        ├── ProjectOutcome.tscn
        ├── AcquisitionOutcome.tscn
        ├── DebriefScreen.tscn
        ├── ManagementProfile.tscn
        └── GrowthReflection.tscn
```

### 2.2 — Scene Categories

**Persistent scenes** — always active during gameplay:
- `HUD.tscn` and its children

**Room scenes** — one active at a time, swapped on phase transitions:
- All phase rooms and the TrainingWing

**Overlay scenes** — instantiated on demand, layered on top of the current room:
- All component scenes and debrief/outcome scenes

**Overlay management pattern in GDScript:**

```gdscript
# Pattern for showing an overlay scene from any phase script
func _show_overlay(scene_path: String, data: Dictionary = {}) -> Node:
    var overlay_scene = load(scene_path)
    var overlay_instance = overlay_scene.instantiate()
    overlay_instance.setup(data)  # Every overlay implements setup()
    get_tree().current_scene.add_child(overlay_instance)
    return overlay_instance

# Pattern for closing an overlay
func _on_overlay_closed():
    # Overlays emit "closed" signal when done
    # The parent scene resumes its flow
    pass
```

### 2.3 — Reusable Component Specifications

Each reusable component scene follows a consistent interface pattern:

```gdscript
# Every component implements:
func setup(data: Dictionary) -> void:
    # Accepts all configuration data needed to display
    pass

# Every component emits:
signal completed(result: Dictionary)
# Emitted when the player finishes interacting with the component
# result contains any player choices or assessment data

signal closed()
# Emitted when the component should be removed from the scene tree
```

**Component: CauseEventEffectChain**
```
Input data:
{
    "cause": "Developer is dissatisfied with workload",
    "event": "Developer resigns mid-sprint",
    "effect": "3 weeks of knowledge lost, deadline at risk",
    "severity": "high",  # "low", "medium", "high" — affects color
    "conclusion": "This is a risk because..."
}

Output signal: completed({})
Behavior: Animates three panels left to right with 0.6s delay between each.
Shows conclusion text after all three panels are visible. Player presses
Continue to emit completed.
```

**Component: EvidenceColumns**
```
Input data:
{
    "increases": [
        "Client hasn't seen working software yet",
        "Banking apps have complex compliance layers"
    ],
    "decreases": [
        "Requirements document was signed off"
    ],
    "conclusion": "Assessment: High probability. Evidence strongly supports...",
    "assessed_level": "high"  # "low", "medium", "high"
}

Output signal: completed({})
Behavior: Two columns fill in one item at a time with 0.4s delay.
Conclusion appears after all items. Player presses Continue.
```

**Component: RippleEffect**
```
Input data:
{
    "steps": [
        {
            "description": "Developer leaves. Immediate knowledge gap.",
            "dimension": "schedule",
            "delta": "+3 weeks",
            "delta_value": -15
        },
        {
            "description": "Recruitment takes 2 weeks, costs $8K.",
            "dimension": "budget",
            "delta": "+$8K",
            "delta_value": -8
        }
    ],
    "summary": {
        "budget": -8,
        "schedule": -15,
        "quality": -10,
        "stakeholder_trust": -5
    }
}

Output signal: completed({})
Behavior: Steps appear sequentially with ripple animation.
Summary bar shows totals at the end. Player presses Continue.
```

**Component: RiskMatrix**
```
Input data:
{
    "mode": "interactive",  # "interactive" (player places risks) or "display" (show only)
    "risks_to_place": [
        {
            "id": "PLAN-01",
            "title": "Lead developer may leave",
            "correct_quadrant": "wildfire"  # only used in interactive mode
        }
    ],
    "placed_risks": []  # pre-placed risks for display mode
}

Output signal: completed({"placements": [{"id": "PLAN-01", "placed": "wildfire", "correct": "wildfire"}]})
Behavior: In interactive mode, player drags risk cards to quadrants.
Fire animation plays on placement. Correction shown if wrong.
In display mode, shows the current state of the player's matrix.
```

**Component: ClientProfileCard**
```
Input data:
{
    "mode": "display",  # "display" (show filled card) or "build" (player fills it in)
    "character_name": "Dana",
    "company": "SecurePay",
    "avatar": "res://assets/sprites/characters/dana/avatar.png",
    "stats": {
        "budget_tolerance": "high",
        "schedule_flexibility": "low",
        "quality_standards": "high",
        "scope_flexibility": "high"
    }
}

Output signal: completed({"player_stats": {...}})  # only in build mode
Behavior: In display mode, shows the filled card.
In build mode, player sets each stat bar. Validation against correct values.
```

**Component: NPCDialogue**
```
Input data:
{
    "npc_name": "Jordan",
    "npc_avatar": "res://assets/sprites/characters/jordan/avatar.png",
    "dialogue_tree": [
        {
            "id": "root",
            "choices": [
                {
                    "text": "How likely is the API delay?",
                    "leads_to": "response_1"
                },
                {
                    "text": "Is there an alternative API?",
                    "leads_to": "response_2"
                }
            ]
        },
        {
            "id": "response_1",
            "npc_text": "I talked to the vendor last week...",
            "choices": [
                {
                    "text": "What happens if we wait?",
                    "leads_to": "response_3"
                }
            ]
        }
    ]
}

Output signal: completed({"choices_made": ["response_1", "response_3"], "all_nodes_visited": false})
Behavior: Branching conversation. Player selects dialogue options.
NPC responds. Conversation ends when no more choices or player exits.
```

**Component: ResourceAllocationUI**
```
Input data:
{
    "risk_id": "PLAN-01",
    "risk_title": "Lead developer may leave",
    "available_budget": 50000,
    "available_capacity": 12,
    "response_options": {
        "avoid": {"cost_budget": 5000, "cost_capacity": 3, "description": "..."},
        "mitigate": {"cost_budget": 15000, "cost_capacity": 2, "description": "..."},
        "transfer": {"cost_budget": 20000, "cost_capacity": 1, "description": "..."},
        "accept": {"cost_budget": 0, "cost_capacity": 1, "description": "..."}
    }
}

Output signal: completed({"strategy": "mitigate", "budget_spent": 15000, "capacity_spent": 2})
Behavior: Shows four strategy panels with costs. Grays out unaffordable options.
Player selects one. Confirmation before committing resources.
```

**Component: PhaseResolution**
```
Input data:
{
    "active_risks": [/* array of risk entries with modified probabilities */],
    "phase_name": "Planning"
}

Output signal: completed({"triggered": [...], "resolved": [...], "spawned": [...]})
Behavior: For each risk, runs probability roll with animation.
Shows trigger/resolve result. Plays RippleEffect for triggered risks.
Shows spawned risks. Updates health dashboard.
```

**Component: AmbiguousAssessment (Layer 3 only)**
```
Input data:
{
    "risk_id": "GROW-03",
    "risk_title": "Database migration may fail",
    "optimistic": {"npc": "Jordan", "estimate": "low", "quote": "I've done three of these..."},
    "pessimistic": {"npc": "Alex", "estimate": "high", "quote": "This is twice the size..."}
}

Output signal: completed({"player_assessment": "medium"})
Behavior: Shows two conflicting NPC assessments side by side.
Player must place the risk on the probability scale without confirmation.
No evidence columns. No validation.
```

---

## 3. Data Architecture

### 3.1 — Complete GameManager State

```gdscript
extends Node

# === PROGRESSION FLAGS ===
var current_layer: int = 1  # 1, 2, or 3
var current_phase: String = ""  # "planning", "execution", etc.

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
    _check_failure_conditions()

func spend_budget(amount: int) -> bool:
    if contingency_budget >= amount:
        contingency_budget -= amount
        budget_spent_this_phase += amount
        SignalBus.resources_changed.emit()
        return true
    return false

func spend_capacity(amount: int) -> bool:
    if phase_capacity >= amount:
        phase_capacity -= amount
        capacity_spent_this_phase += amount
        SignalBus.resources_changed.emit()
        return true
    return false

func reset_phase_capacity(amount: int = 12) -> void:
    phase_capacity = amount
    capacity_spent_this_phase = 0
    budget_spent_this_phase = 0

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
    var critical_count = 0
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
        var unaddressed = get_risks_by_status("unassessed")
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
```

### 3.2 — Risk Entry Schema (Runtime Dictionary)

Each risk in `risk_register` is a Dictionary with these fields:

```gdscript
var risk_entry: Dictionary = {
    "id": "PLAN-01",
    "title": "Lead developer may leave for competitor offer",
    "source_type": "auto",  # "auto" or "player_identified"
    "source_description": "Jordan mentions in team briefing",
    "phase_identified": "planning",
    "layer": 2,

    # Player assessments (empty until player fills them in)
    "probability": "",  # "low", "medium", "high", "" = unassessed
    "impact": {
        "budget": "",  # "none", "low", "medium", "high"
        "schedule": "",
        "quality": "",
        "scope": ""
    },
    "matrix_category": "",  # "wildfire", "volcano", "campfire", "spark", ""

    # Response
    "response_strategy": "",  # "avoid", "mitigate", "transfer", "accept", ""
    "budget_allocated": 0,
    "capacity_allocated": 0,
    "investigated": false,

    # Status lifecycle
    "status": "unassessed",
    # Lifecycle: unassessed → analyzed → response_planned → active → triggered/resolved → escalated

    # Outcome (filled by game engine)
    "triggered": false,
    "outcome_narrative": "",

    # Scenario data reference (loaded from JSON)
    "base_probability": 60,
    "response_options": {},  # full response option data from JSON
    "if_triggered": {},  # cascade data from JSON
    "if_resolved": {},  # resolution data from JSON
    "investigation": {},  # NPC investigation data from JSON
    "debrief": {},  # debrief data from JSON

    # Layer 3 specific
    "ambiguous": false,
    "true_probability": -1,  # hidden from player, -1 means not ambiguous
    "ethical_dimension": {},  # empty if none
    "layer2_echo": {}  # empty if none
}
```

### 3.3 — JSON Scenario File Schema

Each phase has its own JSON file. Example structure for `layer2_planning.json`:

```json
{
    "phase": "planning",
    "layer": 2,
    "narrative_intro": "The SecurePay project has been approved. Build your risk register and allocate resources before development begins.",
    "starting_capacity": 12,
    "risks": [
        {
            "id": "PLAN-01",
            "title": "Lead developer may leave for competitor offer",
            "source_type": "auto",
            "source_description": "Jordan mentions in team briefing",
            "base_probability": 60,
            "correct_probability": "high",
            "correct_impact": {
                "budget": "medium",
                "schedule": "high",
                "quality": "medium",
                "scope": "low"
            },
            "correct_matrix_category": "wildfire",
            "investigation": {
                "available": true,
                "npc": "jordan",
                "dialogue_id": "jordan_plan01_investigate",
                "capacity_cost": 1,
                "reveals": {
                    "probability_insight": "Developer has received an offer but hasn't decided yet.",
                    "recommended_strategy": "mitigate"
                }
            },
            "response_options": {
                "avoid": {
                    "description": "Restructure the project to remove dependency on this developer.",
                    "cost_budget": 5000,
                    "cost_capacity": 3,
                    "probability_after": 0,
                    "impact_reduction": {},
                    "tradeoff_note": "Eliminates the risk but costs significant capacity."
                },
                "mitigate": {
                    "description": "Offer retention incentives and cross-train a backup developer.",
                    "cost_budget": 15000,
                    "cost_capacity": 2,
                    "probability_after": 25,
                    "impact_reduction": {"schedule": 10, "quality": 5},
                    "tradeoff_note": "Reduces probability significantly."
                },
                "transfer": {
                    "description": "Contract a staffing agency for a standby replacement.",
                    "cost_budget": 20000,
                    "cost_capacity": 1,
                    "probability_after": 60,
                    "impact_reduction": {"schedule": 15, "quality": 5},
                    "tradeoff_note": "Doesn't prevent departure but ensures rapid replacement."
                },
                "accept": {
                    "description": "Prepare documentation for knowledge transfer.",
                    "cost_budget": 0,
                    "cost_capacity": 1,
                    "probability_after": 60,
                    "impact_reduction": {"schedule": 5},
                    "tradeoff_note": "Cheapest option. Documentation helps but doesn't prevent damage."
                }
            },
            "if_triggered": {
                "spawns": ["EXEC-03"],
                "modifies": [],
                "health_impact": {
                    "budget": -15,
                    "schedule": -25,
                    "quality": -10,
                    "stakeholder_trust": -10
                },
                "narrative": "The lead developer accepted the competitor's offer."
            },
            "if_resolved": {
                "health_impact": {"stakeholder_trust": 5},
                "narrative": "The lead developer decided to stay."
            },
            "debrief": {
                "optimal_strategy": "mitigate",
                "explanation": "Given Dana's low schedule tolerance, investing in retention and cross-training offers the best cost-to-protection ratio."
            },
            "ripple_steps": [
                {"description": "Developer leaves.", "dimension": "schedule", "delta": "+3 weeks", "delta_value": -15},
                {"description": "Recruitment: 2 weeks, $8K.", "dimension": "budget", "delta": "+$8K", "delta_value": -8},
                {"description": "Onboarding: 4 weeks reduced output.", "dimension": "schedule", "delta": "+4 weeks", "delta_value": -10},
                {"description": "Some features simplified.", "dimension": "scope", "delta": "Reduced", "delta_value": -5}
            ]
        }
    ],
    "hidden_risks": [
        {
            "id": "PLAN-H1",
            "title": "Team morale declining due to overtime expectations",
            "hint_npc": "jordan",
            "hint_dialogue_id": "jordan_morale_hint",
            "hint_text": "The team's been putting in extra hours to prep — I hope that's not going to be the norm.",
            "base_probability": 45,
            "correct_probability": "medium",
            "correct_impact": {
                "budget": "low",
                "schedule": "low",
                "quality": "medium",
                "scope": "none"
            },
            "correct_matrix_category": "campfire",
            "response_options": {},
            "if_triggered": {},
            "if_resolved": {},
            "debrief": {}
        }
    ],
    "available_npcs": ["jordan", "dana", "sam"],
    "mandatory_conversations": [],
    "phase_end_events": []
}
```

### 3.4 — NPC Dialogue File Schema

Example structure for `jordan_dialogues.json`:

```json
{
    "npc_id": "jordan",
    "display_name": "Jordan",
    "role": "Senior Developer",
    "avatar_path": "res://assets/sprites/characters/jordan/avatar.png",
    "dialogues": {
        "jordan_plan01_investigate": {
            "context": "Investigation for PLAN-01",
            "tree": [
                {
                    "id": "root",
                    "npc_text": "",
                    "choices": [
                        {"text": "How likely is it that they'll leave?", "leads_to": "likelihood"},
                        {"text": "How critical are they to the project?", "leads_to": "criticality"},
                        {"text": "Is there anything we can do to keep them?", "leads_to": "retention"}
                    ]
                },
                {
                    "id": "likelihood",
                    "npc_text": "They've been interviewing actively. I'd say it's more likely than not — maybe 60-40 they leave within the month.",
                    "choices": [
                        {"text": "How critical are they to the project?", "leads_to": "criticality"},
                        {"text": "Thanks, that's helpful.", "leads_to": "end"}
                    ]
                },
                {
                    "id": "criticality",
                    "npc_text": "They built the entire payment module architecture. If they leave, nobody else knows how the transaction routing works. We'd be reverse-engineering our own code.",
                    "choices": [
                        {"text": "Is there anything we can do?", "leads_to": "retention"},
                        {"text": "That's concerning. Thanks.", "leads_to": "end"}
                    ]
                },
                {
                    "id": "retention",
                    "npc_text": "A retention bonus might help — or a role change. They've mentioned wanting to lead a team, not just write code. That might be worth more to them than money.",
                    "choices": [
                        {"text": "Good to know. Thanks.", "leads_to": "end"}
                    ]
                },
                {
                    "id": "end",
                    "npc_text": "Let me know what you decide. I'll keep an eye on the situation.",
                    "choices": []
                }
            ]
        },
        "jordan_morale_hint": {
            "context": "Offhand mention hinting at PLAN-H1",
            "tree": [
                {
                    "id": "root",
                    "npc_text": "Oh, one more thing — the team's been putting in extra hours to prep. I hope that's not going to be the norm. People are already looking tired.",
                    "choices": [
                        {"text": "I'll keep an eye on workload.", "leads_to": "end"},
                        {"text": "We'll need that pace for a while.", "leads_to": "end_dismiss"}
                    ]
                },
                {
                    "id": "end",
                    "npc_text": "Appreciated. A tired team makes more mistakes — just saying.",
                    "choices": []
                },
                {
                    "id": "end_dismiss",
                    "npc_text": "...Right. Well, just keep it in mind.",
                    "choices": []
                }
            ]
        }
    }
}
```

---

## 4. Signal and Communication Map

### 4.1 — SignalBus.gd (Complete Signal Definitions)

```gdscript
extends Node

# === HEALTH & RESOURCES ===
signal health_changed()
# Emitted when any health dimension changes value.
# Listeners: HealthDashboard.gd (updates display)

signal resources_changed()
# Emitted when budget or capacity changes.
# Listeners: ResourceBar.gd (updates display), ResourceAllocationUI.gd (updates affordability)

# === RISK REGISTER ===
signal risk_added(risk_data: Dictionary)
# Emitted when a new risk enters the register.
# Listeners: RiskRegisterPanel.gd (adds new entry card), HUD.gd (shows notification)

signal risk_updated(risk_data: Dictionary)
# Emitted when a risk's assessment, strategy, or status changes.
# Listeners: RiskRegisterPanel.gd (updates entry card), RiskMatrixHUD.gd (updates position)

signal risk_triggered(risk_data: Dictionary)
# Emitted when a risk triggers during phase resolution.
# Listeners: HUD.gd (shows alert), HealthDashboard.gd (animates change)

signal risk_resolved(risk_data: Dictionary)
# Emitted when a risk is resolved without triggering.
# Listeners: RiskRegisterPanel.gd (updates status display)

# === PHASE MANAGEMENT ===
signal phase_started(phase_name: String, layer: int)
# Emitted when a new phase begins.
# Listeners: HUD.gd (updates phase label), all phase scripts (initialize)

signal phase_completed(phase_name: String, results: Dictionary)
# Emitted when phase resolution finishes.
# Listeners: GameManager.gd (stores results), door system (unlocks next room)

signal phase_resolution_started()
# Emitted when probability rolls begin.
# Listeners: HUD.gd (shows resolution overlay)

# === LAYER MANAGEMENT ===
signal layer_completed(layer: int, performance: Dictionary)
# Emitted when all phases of a layer are done.
# Listeners: GameManager.gd (stores performance), transition logic

signal layer_started(layer: int)
# Emitted when entering a new layer.
# Listeners: HUD.gd (reconfigures visible elements)

# === STATION MANAGEMENT (Layer 1) ===
signal station_completed(station_number: int)
# Emitted when a Layer 1 station is finished.
# Listeners: TrainingWing.gd (unlocks next station door)

# === NPC & DIALOGUE ===
signal investigation_started(risk_id: String, npc_id: String)
# Emitted when player starts investigating a risk.
# Listeners: GameManager.gd (deducts capacity, tracks investigation count)

signal dialogue_completed(npc_id: String, choices_made: Array)
# Emitted when an NPC conversation ends.
# Listeners: Phase scripts (update available info), GameManager.gd (track)

signal hidden_risk_discovered(risk_id: String)
# Emitted when player manually adds a hidden risk.
# Listeners: GameManager.gd (increment hidden_risks_found), RiskRegisterPanel.gd

# === FAILURE ===
signal failure_triggered(condition: String, phase: String)
# Emitted when a failure condition is met.
# Listeners: GameWorld.gd (shows FailureSequence overlay)

# === UI ===
signal overlay_requested(scene_path: String, data: Dictionary)
# Emitted when any system needs to show an overlay.
# Listeners: GameWorld.gd (instantiates and displays the overlay)

signal overlay_closed()
# Emitted when an overlay finishes and should be removed.
# Listeners: GameWorld.gd (removes overlay, resumes phase flow)

signal register_toggle_requested()
# Emitted when player presses the register button.
# Listeners: RiskRegisterPanel.gd (toggles visibility)

signal matrix_toggle_requested()
# Emitted when player presses the matrix button.
# Listeners: RiskMatrixHUD.gd (toggles visibility)

# === LAYER 3 SPECIFIC ===
signal profile_shift_triggered(new_profile: Dictionary)
# Emitted when Dana's priorities change in Layer 3.
# Listeners: ClientProfileCard.gd (animates shift), HUD.gd (updates profile display)

signal acquisition_status_changed(new_status: String)
# Emitted when acquisition health changes significantly.
# Listeners: HealthDashboard.gd (special indicator)
```

### 4.2 — Signal Flow Diagrams

**Flow 1: Player assesses a risk**
```
Player opens RiskRegisterPanel → clicks risk entry →
RiskEntryCard emits "assessment_requested" →
Overlay: RiskMatrix (interactive mode) shown →
Player places risk → RiskMatrix emits completed({"placement": "wildfire"}) →
GameManager.update_risk(id, {"matrix_category": "wildfire", "status": "analyzed"}) →
SignalBus.risk_updated emitted →
RiskRegisterPanel updates entry display
```

**Flow 2: Player responds to a risk**
```
Player clicks "Respond" on assessed risk →
Overlay: ResourceAllocationUI shown with response options →
Player selects strategy → ResourceAllocationUI emits completed({"strategy": "mitigate", ...}) →
GameManager.spend_budget() + GameManager.spend_capacity() →
SignalBus.resources_changed emitted →
ResourceBar updates display →
GameManager.update_risk(id, {"response_strategy": "mitigate", "status": "response_planned"}) →
SignalBus.risk_updated emitted →
RiskRegisterPanel updates entry display
```

**Flow 3: Phase resolution**
```
Player clicks "Confirm Plan" →
PhaseResolution overlay instantiated →
For each active risk:
    Calculate modified probability →
    Roll random number →
    If triggered:
        RippleEffect overlay shown →
        GameManager.apply_health_impact() →
        SignalBus.health_changed emitted →
        HealthDashboard animates →
        If risk has spawns: GameManager.add_risk() for each →
        SignalBus.risk_triggered emitted →
    If not triggered:
        Risk status → "resolved" →
        Partial budget refund →
        SignalBus.risk_resolved emitted →
PhaseResolution emits completed(results) →
SignalBus.phase_completed emitted →
Door to next room unlocks
```

**Flow 4: Failure detection**
```
GameManager.apply_health_impact() called →
GameManager._check_failure_conditions() called →
If failure condition met:
    SignalBus.failure_triggered emitted →
    GameWorld.gd receives signal →
    FailureSequence overlay instantiated →
    Emergency meeting plays →
    Debrief with "Breaking Point" analysis →
    Restart options shown
```

**Flow 5: Hidden risk discovery**
```
Player in NPC conversation → NPC hint text shown →
Player recognizes hint → opens RiskRegisterPanel →
Player clicks "Add Risk" button →
Risk creation form shown (title input, basic fields) →
Player submits → GameManager.add_risk(player_created_risk) →
SignalBus.hidden_risk_discovered emitted →
GameManager increments hidden_risks_found →
New risk appears in register as "unassessed"
```

---

## 5. Implementation Task Breakdown

### How to Use This Section

Each task is designed to be a single Codex prompt. Tasks are numbered and ordered by dependency — you must complete earlier tasks before later ones that depend on them. Each task includes:

- **What to build:** exact description of the deliverable
- **Files to create or modify:** specific paths
- **Dependencies:** which tasks must be done first
- **Context to give Codex:** what existing files Codex needs to see
- **Test:** how to verify the task is done correctly
- **GDScript scaffolding:** starter code patterns Codex should follow

### Build Phase 0: Project Foundation

---

**Task 0.1 — Create SignalBus autoload**

What to build: Create the SignalBus singleton with all signal definitions from Section 4.1.

Files to create: `scripts/autoload/SignalBus.gd`

Dependencies: None

Context for Codex: None needed — this is a standalone file.

Test: The script loads without errors when registered as an autoload in project.godot. All signals are defined.

Code: Copy the complete SignalBus.gd from Section 4.1.

---

**Task 0.2 — Create DataManager autoload**

What to build: A singleton that loads all JSON files from the `data/` directory and provides accessor methods.

Files to create: `scripts/autoload/DataManager.gd`

Dependencies: None

Context for Codex: The JSON file schemas from Section 3.3 and 3.4.

Test: Calling `DataManager.get_phase_data("planning", 2)` returns the planning phase data. Calling `DataManager.get_dialogue("jordan", "jordan_plan01_investigate")` returns the dialogue tree.

Scaffolding:
```gdscript
extends Node

var _scenario_data: Dictionary = {}
var _dialogue_data: Dictionary = {}
var _client_profiles: Dictionary = {}

func _ready():
    _load_all_data()

func _load_all_data() -> void:
    # Load all JSON files from data/ directory
    # Parse and store in the dictionaries above
    pass

func _load_json(path: String) -> Dictionary:
    var file = FileAccess.open(path, FileAccess.READ)
    if file == null:
        push_error("Failed to load: " + path)
        return {}
    var json = JSON.new()
    json.parse(file.get_as_text())
    return json.data

func get_phase_data(phase: String, layer: int) -> Dictionary:
    var key = "layer%d_%s" % [layer, phase]
    return _scenario_data.get(key, {})

func get_dialogue(npc_id: String, dialogue_id: String) -> Dictionary:
    if _dialogue_data.has(npc_id):
        return _dialogue_data[npc_id].get("dialogues", {}).get(dialogue_id, {})
    return {}

func get_npc_info(npc_id: String) -> Dictionary:
    # Returns display_name, role, avatar_path
    if _dialogue_data.has(npc_id):
        var d = _dialogue_data[npc_id]
        return {"display_name": d["display_name"], "role": d["role"], "avatar_path": d["avatar_path"]}
    return {}

func get_client_profile(profile_id: String) -> Dictionary:
    return _client_profiles.get(profile_id, {})
```

---

**Task 0.3 — Create GameManager autoload**

What to build: The complete GameManager singleton with all state variables and helper methods from Section 3.1.

Files to create: `scripts/autoload/GameManager.gd`

Dependencies: Task 0.1 (SignalBus must exist for signal emissions)

Context for Codex: Full GameManager code from Section 3.1, SignalBus signal list.

Test: GameManager loads. Calling `GameManager.apply_health_impact({"budget": -20})` reduces health_budget by 20 and emits health_changed. Calling `GameManager.get_health_label("budget")` returns the correct label for the current value.

Code: Copy the complete GameManager.gd from Section 3.1.

---

**Task 0.4 — Register autoloads in project.godot**

What to build: Add the three autoload entries to project.godot.

Files to modify: `project.godot`

Dependencies: Tasks 0.1, 0.2, 0.3

Context for Codex: The three autoload script paths. Existing project.godot content.

Test: Running the project loads all three singletons without errors. Typing `GameManager` in any script auto-completes.

Prompt note: In Godot 4.4, autoloads are registered in project.godot under `[autoload]`:
```
[autoload]
SignalBus="*res://scripts/autoload/SignalBus.gd"
DataManager="*res://scripts/autoload/DataManager.gd"
GameManager="*res://scripts/autoload/GameManager.gd"
```

---

**Task 0.5 — Create the initial data files**

What to build: Create all JSON data files with the complete scenario content from the Layer 1, 2, and 3 design documents. Start with `layer1_stations.json` and `layer2_planning.json` as fully populated examples, and create skeleton files for the remaining phases.

Files to create: All files in `data/scenarios/` and `data/npc_dialogues/`

Dependencies: None (these are pure data)

Context for Codex: The JSON schemas from Section 3.3 and 3.4, plus the specific risk tables from Layer 1, 2, and 3 design documents.

Test: All JSON files parse without errors. `DataManager.get_phase_data("planning", 2)` returns complete risk data.

Prompt note: This is a large task. Break it into sub-prompts if needed: one for Layer 1 station data, one for Layer 2 phase data, one for Layer 3 phase data, one for all NPC dialogue files.

---

### Build Phase 1: Reusable UI Components

These components are used across all three layers. Build them first so they can be tested in isolation.

---

**Task 1.1 — CauseEventEffectChain component**

What to build: A reusable overlay scene that displays three animated panels (Cause → Event → Effect) with a conclusion line and a Continue button.

Files to create: `scenes/components/CauseEventEffectChain.tscn`, `scripts/components/CauseEventEffectChain.gd`

Dependencies: Task 0.1 (SignalBus)

Context for Codex: Component spec from Section 2.3.

Test: Instantiate the scene, call `setup({"cause": "Test", "event": "Test", "effect": "Test", "severity": "high", "conclusion": "Test"})`. Three panels animate in sequence. Continue button appears. Pressing it emits `completed({})`.

Scene structure:
```
CauseEventEffectChain (Control - full screen overlay)
├── DimBackground (ColorRect — semi-transparent black)
├── PanelContainer (centered)
│   ├── VBoxContainer
│   │   ├── HBoxContainer (the three panels)
│   │   │   ├── CausePanel (PanelContainer)
│   │   │   │   ├── Label ("CAUSE")
│   │   │   │   └── Label (cause text)
│   │   │   ├── Arrow1 (TextureRect or Label "→")
│   │   │   ├── EventPanel (PanelContainer)
│   │   │   │   ├── Label ("EVENT")
│   │   │   │   └── Label (event text)
│   │   │   ├── Arrow2 (TextureRect or Label "→")
│   │   │   └── EffectPanel (PanelContainer)
│   │   │       ├── Label ("EFFECT")
│   │   │       └── Label (effect text)
│   │   ├── ConclusionLabel (RichTextLabel)
│   │   └── ContinueButton (Button)
```

GDScript scaffolding:
```gdscript
extends Control

signal completed(result: Dictionary)
signal closed()

@onready var cause_panel = $PanelContainer/VBoxContainer/HBoxContainer/CausePanel
@onready var event_panel = $PanelContainer/VBoxContainer/HBoxContainer/EventPanel
@onready var effect_panel = $PanelContainer/VBoxContainer/HBoxContainer/EffectPanel
@onready var arrow1 = $PanelContainer/VBoxContainer/HBoxContainer/Arrow1
@onready var arrow2 = $PanelContainer/VBoxContainer/HBoxContainer/Arrow2
@onready var conclusion_label = $PanelContainer/VBoxContainer/ConclusionLabel
@onready var continue_button = $PanelContainer/VBoxContainer/ContinueButton

var _data: Dictionary = {}

func _ready():
    # Hide all elements initially
    cause_panel.modulate.a = 0
    arrow1.modulate.a = 0
    event_panel.modulate.a = 0
    arrow2.modulate.a = 0
    effect_panel.modulate.a = 0
    conclusion_label.modulate.a = 0
    continue_button.visible = false
    continue_button.pressed.connect(_on_continue_pressed)

func setup(data: Dictionary) -> void:
    _data = data
    # Set text content from data
    # Set severity color
    # Start animation sequence
    _animate_sequence()

func _animate_sequence() -> void:
    var tween = create_tween()
    tween.tween_property(cause_panel, "modulate:a", 1.0, 0.4)
    tween.tween_interval(0.3)
    tween.tween_property(arrow1, "modulate:a", 1.0, 0.2)
    tween.tween_property(event_panel, "modulate:a", 1.0, 0.4)
    tween.tween_interval(0.3)
    tween.tween_property(arrow2, "modulate:a", 1.0, 0.2)
    tween.tween_property(effect_panel, "modulate:a", 1.0, 0.4)
    tween.tween_interval(0.4)
    tween.tween_property(conclusion_label, "modulate:a", 1.0, 0.4)
    tween.tween_callback(func(): continue_button.visible = true)

func _on_continue_pressed():
    completed.emit({})
    closed.emit()
    queue_free()
```

---

**Task 1.2 — EvidenceColumns component**

What to build: A reusable overlay that displays two columns of evidence items with a conclusion.

Files to create: `scenes/components/EvidenceColumns.tscn`, `scripts/components/EvidenceColumns.gd`

Dependencies: Task 0.1

Context for Codex: Component spec from Section 2.3. Follow same pattern as Task 1.1.

Test: Call setup with increases/decreases arrays. Items animate in one at a time. Conclusion shows. Continue works.

Scene structure: Same overlay pattern as CauseEventEffectChain. Two VBoxContainers side by side for the columns. Each item is a Label added dynamically.

---

**Task 1.3 — RippleEffect component**

What to build: A reusable overlay that displays a sequence of consequence steps with dimension deltas and a summary bar.

Files to create: `scenes/components/RippleEffect.tscn`, `scripts/components/RippleEffect.gd`

Dependencies: Task 0.1

Context for Codex: Component spec from Section 2.3.

Test: Call setup with a steps array. Each step animates in sequence with delta indicators. Summary bar shows totals at the end.

---

**Task 1.4 — RiskMatrix component**

What to build: A reusable 2×2 grid component supporting both interactive (drag-and-drop risk placement) and display modes. Includes fire metaphor visuals and animations per quadrant.

Files to create: `scenes/components/RiskMatrix.tscn`, `scripts/components/RiskMatrix.gd`

Dependencies: Task 0.1

Context for Codex: Component spec from Section 2.3, fire metaphor descriptions from Layer 1 design document Section 5.

Test: In interactive mode, drag a risk card to a quadrant. Fire animation plays. If wrong quadrant, correction animation moves card to correct position. Completed signal emits with placement data. In display mode, pre-placed risks are shown statically.

Prompt note: For the fire animations, start with simple colored rectangles and label text. Animated sprites can be added later in the style pass. The matrix must work functionally before it's visually polished.

---

**Task 1.5 — ClientProfileCard component**

What to build: A strategy-game-style card showing an NPC avatar, name, company, and four stat bars. Supports display mode (show filled card) and build mode (player fills in bars).

Files to create: `scenes/components/ClientProfileCard.tscn`, `scripts/components/ClientProfileCard.gd`

Dependencies: Task 0.1

Context for Codex: Component spec from Section 2.3, Dana's profile from Layer 1 design document.

Test: In display mode, card shows with correct stat bar levels. In build mode, player can set each bar to Low/Medium/High. If incorrect, validation highlights the relevant conversation line. Completed signal emits player's choices.

---

**Task 1.6 — NPCDialogue component**

What to build: A branching conversation UI showing NPC avatar, name, their dialogue text, and player response choices as clickable buttons.

Files to create: `scenes/components/NPCDialogue.tscn`, `scripts/components/NPCDialogue.gd`

Dependencies: Tasks 0.1, 0.2 (DataManager for loading dialogue trees)

Context for Codex: Component spec from Section 2.3, dialogue JSON schema from Section 3.4.

Test: Call setup with a dialogue tree. NPC text displays. Player choices appear as buttons. Selecting a choice advances to the next node. When conversation ends (empty choices array), completed signal emits with choices_made array.

Scene structure:
```
NPCDialogue (Control - full screen overlay)
├── DimBackground
├── DialoguePanel (PanelContainer - bottom third of screen)
│   ├── HBoxContainer
│   │   ├── AvatarTexture (TextureRect)
│   │   └── VBoxContainer
│   │       ├── NameLabel (Label — "Jordan — Senior Developer")
│   │       ├── DialogueText (RichTextLabel — NPC's words)
│   │       └── ChoicesContainer (VBoxContainer — buttons added dynamically)
```

---

**Task 1.7 — ResourceAllocationUI component**

What to build: An overlay that shows four strategy panels for a risk, each with description, cost, and an affordability indicator. Player selects one and confirms.

Files to create: `scenes/components/ResourceAllocationUI.tscn`, `scripts/components/ResourceAllocationUI.gd`

Dependencies: Tasks 0.1, 0.3 (needs GameManager to check affordability)

Context for Codex: Component spec from Section 2.3.

Test: Show the overlay with a risk's response options. Strategies that cost more than available budget/capacity are grayed out. Player selects one, confirmation dialog appears, completed signal emits with strategy choice and costs.

---

**Task 1.8 — PhaseResolution component**

What to build: An overlay that processes all active risks at end of phase. For each risk, runs a probability roll with animation, shows the result, and plays RippleEffect for triggered risks.

Files to create: `scenes/components/PhaseResolution.tscn`, `scripts/components/PhaseResolution.gd`

Dependencies: Tasks 0.1, 0.3 (GameManager for risk data and health updates), Task 1.3 (RippleEffect)

Context for Codex: Component spec from Section 2.3, probability modification rules from Layer 2 design document Section 2.4.

Test: Pass in a list of active risks. Each risk shows a roll animation. Triggered risks play their ripple sequence. Health dashboard updates. Spawned risks appear in register. Completed signal emits with results summary.

GDScript scaffolding for the probability roll:
```gdscript
func _resolve_risk(risk: Dictionary) -> Dictionary:
    var base_prob = risk["base_probability"]
    var modified_prob = base_prob

    # Apply strategy modifier
    match risk["response_strategy"]:
        "avoid":
            modified_prob = 0
        "mitigate":
            var after = risk["response_options"]["mitigate"]["probability_after"]
            modified_prob = after
        "transfer":
            # Probability unchanged, impact reduced
            pass
        "accept":
            # Probability unchanged
            pass
        _:
            # Unassessed — full probability + surprise penalty
            pass

    var roll = randi() % 100
    var triggered = roll < modified_prob

    return {
        "risk_id": risk["id"],
        "base_probability": base_prob,
        "modified_probability": modified_prob,
        "roll": roll,
        "triggered": triggered
    }
```

---

**Task 1.9 — AmbiguousAssessment component (Layer 3)**

What to build: A modified risk assessment overlay that shows two conflicting NPC opinions instead of evidence columns. Player must place the risk on the probability scale without validation.

Files to create: `scenes/components/AmbiguousAssessment.tscn`, `scripts/components/AmbiguousAssessment.gd`

Dependencies: Task 0.1

Context for Codex: Component spec from Section 2.3.

Test: Shows two NPC quotes with conflicting assessments. Player selects Low/Medium/High. No confirmation or correction. Completed signal emits with player's assessment.

---

### Build Phase 2: HUD System

---

**Task 2.1 — HealthDashboard**

What to build: A persistent HUD element displaying four health dimensions with their current state labels. Animates on health changes.

Files to create: `scenes/hud/HealthDashboard.tscn`, `scripts/hud/HealthDashboard.gd`

Dependencies: Tasks 0.1, 0.3

Context for Codex: Health threshold system from GameManager.

Test: Dashboard displays all four labels correctly. When `GameManager.apply_health_impact()` is called, the dashboard updates with a smooth transition. Critical states have a visual pulse or color change.

GDScript scaffolding:
```gdscript
extends Control

@onready var budget_label = $BudgetIndicator/StateLabel
@onready var schedule_label = $ScheduleIndicator/StateLabel
@onready var quality_label = $QualityIndicator/StateLabel
@onready var trust_label = $TrustIndicator/StateLabel

func _ready():
    SignalBus.health_changed.connect(_on_health_changed)
    _update_display()

func _on_health_changed():
    _update_display()

func _update_display():
    budget_label.text = GameManager.get_health_label("budget")
    schedule_label.text = GameManager.get_health_label("schedule")
    quality_label.text = GameManager.get_health_label("quality")
    trust_label.text = GameManager.get_health_label("stakeholder_trust")
    # Apply visual styling based on state (color, pulse for critical)
```

---

**Task 2.2 — ResourceBar**

What to build: A HUD element showing remaining contingency budget and phase capacity.

Files to create: `scenes/hud/ResourceBar.tscn`, `scripts/hud/ResourceBar.gd`

Dependencies: Tasks 0.1, 0.3

Test: Displays current budget and capacity. Updates when resources are spent.

---

**Task 2.3 — RiskRegisterPanel**

What to build: A toggleable side panel that lists all risks in the register. Each risk is displayed as a RiskEntryCard. Supports sorting by status and category. Has an "Add Risk" button for hidden risk discovery.

Files to create: `scenes/hud/RiskRegisterPanel.tscn`, `scripts/hud/RiskRegisterPanel.gd`, `scenes/hud/RiskEntryCard.tscn`, `scripts/hud/RiskEntryCard.gd`

Dependencies: Tasks 0.1, 0.3

Context for Codex: Risk entry schema from Section 3.2.

Test: Toggle register open/close. Risks appear as cards with status indicators. Clicking a card shows risk details. "Add Risk" button opens a simple form for hidden risk entry. New risks added via GameManager appear in the panel automatically.

GDScript scaffolding for RiskEntryCard:
```gdscript
extends PanelContainer

signal card_clicked(risk_id: String)
signal assess_requested(risk_id: String)
signal respond_requested(risk_id: String)
signal investigate_requested(risk_id: String)

var _risk_data: Dictionary = {}

func setup(risk_data: Dictionary) -> void:
    _risk_data = risk_data
    _update_display()

func _update_display():
    $TitleLabel.text = _risk_data["title"]
    $StatusLabel.text = _risk_data["status"].capitalize()
    $CategoryLabel.text = _risk_data.get("matrix_category", "—").capitalize()
    # Color-code based on status
    # Show/hide action buttons based on status
    match _risk_data["status"]:
        "unassessed":
            $AssessButton.visible = true
            $RespondButton.visible = false
        "analyzed":
            $AssessButton.visible = false
            $RespondButton.visible = true
        "response_planned", "active":
            $AssessButton.visible = false
            $RespondButton.visible = false
```

---

**Task 2.4 — RiskMatrixHUD**

What to build: A small, toggleable minimap version of the risk matrix that shows where all assessed risks currently sit. Uses fire metaphor colors for quadrants.

Files to create: `scenes/hud/RiskMatrixHUD.tscn`, `scripts/hud/RiskMatrixHUD.gd`

Dependencies: Tasks 0.1, 0.3

Test: Shows a 2×2 grid with risk dots in correct quadrants. Updates when risks are assessed or recategorized.

---

**Task 2.5 — HUD integration**

What to build: The master HUD scene that contains HealthDashboard, ResourceBar, and toggle buttons for RiskRegisterPanel and RiskMatrixHUD. Manages visibility based on current layer (Layer 1 shows minimal HUD, Layer 2+ shows full HUD).

Files to create: `scenes/hud/HUD.tscn`, `scripts/hud/HUD.gd`

Dependencies: Tasks 2.1, 2.2, 2.3, 2.4

Test: HUD displays correctly. Toggle buttons work. In Layer 1, only station progress is shown. In Layer 2+, all elements are visible.

---

### Build Phase 3: Layer 1 Stations

---

**Task 3.1 — Station 1: Identification**

What to build: The complete Station 1 interaction — 5 risk/not-risk statements, each with CauseEventEffectChain explanation.

Files to create: `scenes/layer1/Station1_Identification.tscn`, `scripts/layer1/Station1_Identification.gd`

Dependencies: Task 1.1 (CauseEventEffectChain), Task 0.5 (station data)

Context for Codex: Full Station 1 design from Layer 1 design document Section 2. Include the 5 statements table, correct answers, and explanation content.

Test: Player sees each statement, chooses Risk/Not Risk. Chain animation plays. All 5 complete → station_1_complete set → door unlocks.

---

**Task 3.2 — Station 2: Probability**

What to build: The drag-and-place probability exercise with evidence column explanations.

Files to create: `scenes/layer1/Station2_Probability.tscn`, `scripts/layer1/Station2_Probability.gd`

Dependencies: Tasks 1.2 (EvidenceColumns), 0.5

Context for Codex: Full Station 2 design from Layer 1 design document Section 3.

Test: Player drags 5 risk cards to Low/Medium/High zones. Evidence columns show after each placement.

---

**Task 3.3 — Station 3: Impact and Client Priorities**

What to build: Dana conversation → client profile card building → impact assessment of 3 risks with ripple effects → priority lens comparison.

Files to create: `scenes/layer1/Station3_Impact.tscn`, `scripts/layer1/Station3_Impact.gd`

Dependencies: Tasks 1.3 (RippleEffect), 1.5 (ClientProfileCard), 1.6 (NPCDialogue), 0.5

Context for Codex: Full Station 3 design from Layer 1 design document Section 4. Include Dana's conversation tree and the contrast exercise.

Test: Full flow from conversation through profile card building through impact assessment. Ripple effects play. Priority lens highlights critical mismatches.

---

**Task 3.4 — Station 4: Risk Matrix**

What to build: The risk placement exercise on the 2×2 matrix with fire metaphor reveals.

Files to create: `scenes/layer1/Station4_Matrix.tscn`, `scripts/layer1/Station4_Matrix.gd`

Dependencies: Tasks 1.4 (RiskMatrix), 0.5

Context for Codex: Full Station 4 design from Layer 1 design document Section 5.

Test: Player places 4 risks. Fire animations play. Misplacements corrected with explanation referencing prior assessments.

---

**Task 3.5 — Station 5: Response Strategies**

What to build: Jordan investigation conversation → try all four strategies with ripple effects → informed choice with tradeoff analysis.

Files to create: `scenes/layer1/Station5_Strategies.tscn`, `scripts/layer1/Station5_Strategies.gd`

Dependencies: Tasks 1.3 (RippleEffect), 1.6 (NPCDialogue), 1.7 (ResourceAllocationUI), 0.5

Context for Codex: Full Station 5 design from Layer 1 design document Section 6.

Test: Full flow from investigation through all four strategy explorations through informed choice. Tradeoff analysis shows for whichever strategy the player picks.

---

**Task 3.6 — Station 6: Full Cycle**

What to build: Complete risk assessment cycle with all skills, hint system, Alex NPC conversation, and comprehensive debrief.

Files to create: `scenes/layer1/Station6_FullCycle.tscn`, `scripts/layer1/Station6_FullCycle.gd`

Dependencies: All component tasks (1.1–1.7), all prior station tasks

Context for Codex: Full Station 6 design from Layer 1 design document Section 7.

Test: Player goes through identify → assess probability → assess impact → classify → investigate → respond. Hints available after 8 seconds. Debrief shows full analysis. layer1_complete flag set.

---

**Task 3.7 — TrainingWing and station gating**

What to build: The physical corridor scene containing trigger zones for each station and doors that unlock sequentially on station completion.

Files to create: `scenes/layer1/TrainingWing.tscn`, `scripts/layer1/TrainingWing.gd`

Dependencies: Tasks 3.1–3.6 (all stations), Task 0.1

Context for Codex: The existing room/door gating system in the current codebase (RoomDoor.gd). TrainingWing should follow the same pattern but use station_N_complete flags.

Test: Player walks through corridor. First station is accessible. Others are locked. Completing a station unlocks the next door. After station 6, the exit to Layer 2 unlocks.

---

### Build Phase 4: Layer 2 Core Systems

---

**Task 4.1 — PhaseBase script**

What to build: A base class script that all Layer 2 (and Layer 3) phase scenes extend. Handles the common phase flow: load risks → player assesses and responds → confirm plan → phase resolution.

Files to create: `scripts/layer2/PhaseBase.gd`

Dependencies: Tasks 0.1, 0.2, 0.3, all component tasks

Context for Codex: The phase flow patterns described in Layer 2 design document Section 3.

GDScript scaffolding:
```gdscript
extends Node2D
class_name PhaseBase

var _phase_name: String = ""
var _layer: int = 2
var _phase_risks: Array = []
var _npcs_available: Array = []
var _mandatory_conversations: Array = []
var _mandatory_conversations_complete: Array = []
var _all_risks_addressed: bool = false

func _ready():
    _load_phase_data()
    _populate_risks()
    _run_mandatory_conversations()
    SignalBus.phase_started.emit(_phase_name, _layer)

func _load_phase_data():
    var data = DataManager.get_phase_data(_phase_name, _layer)
    _phase_risks = data.get("risks", [])
    _npcs_available = data.get("available_npcs", [])
    _mandatory_conversations = data.get("mandatory_conversations", [])
    # Set phase capacity
    GameManager.reset_phase_capacity(data.get("starting_capacity", 12))

func _populate_risks():
    for risk_data in _phase_risks:
        var risk_entry = _create_risk_entry(risk_data)
        GameManager.add_risk(risk_entry)

func _create_risk_entry(data: Dictionary) -> Dictionary:
    # Convert JSON risk data to runtime risk entry format
    # (merge schema fields, set status to "unassessed")
    pass

func _run_mandatory_conversations():
    # Open NPCDialogue for each mandatory conversation
    # Wait for completion before allowing phase actions
    pass

func _check_all_risks_addressed() -> bool:
    var unaddressed = GameManager.risk_register.filter(
        func(r): return r["phase_identified"] == _phase_name and r["status"] == "unassessed"
    )
    return unaddressed.size() == 0

func _on_confirm_plan():
    if not _check_all_risks_addressed():
        # Show warning: "You have unassessed risks"
        return
    # Launch PhaseResolution overlay
    var resolution = preload("res://scenes/components/PhaseResolution.tscn").instantiate()
    var active_risks = GameManager.risk_register.filter(
        func(r): return r["status"] in ["response_planned", "active", "unassessed"] and r["phase_identified"] == _phase_name
    )
    resolution.setup({"active_risks": active_risks, "phase_name": _phase_name})
    resolution.completed.connect(_on_resolution_complete)
    add_child(resolution)

func _on_resolution_complete(results: Dictionary):
    GameManager.phase_results.append({"phase": _phase_name, "results": results})
    SignalBus.phase_completed.emit(_phase_name, results)
    # Unlock door to next phase
```

Test: Create a test phase that extends PhaseBase. Verify that risks are loaded, NPCs are available, assessment flow works, and resolution triggers correctly.

---

**Task 4.2 — RiskTriggerEngine**

What to build: The engine that processes probability rolls, applies strategy modifiers, handles cascading consequences (spawning and modifying risks), and manages health impact application.

Files to create: `scripts/layer2/RiskTriggerEngine.gd`

Dependencies: Tasks 0.1, 0.3

Context for Codex: Probability modification rules from Layer 2 design document Section 2.4, cascade mechanics from Section 2.5.

Test: Given a risk with base probability 60%, mitigate strategy (probability_after 25%), the engine should use 25% for the roll. If triggered, spawned risks should appear in the register. Modified risks should have their probability updated.

---

**Task 4.3 — Layer 2 Phase Rooms (all four)**

What to build: The four phase scenes for Layer 2, each extending PhaseBase. Each phase has its specific risks, NPCs, and events as defined in the Layer 2 design document.

Files to create:
- `scenes/layer2/Phase1_Planning.tscn`, `scripts/layer2/Phase1_Planning.gd`
- `scenes/layer2/Phase2_Execution.tscn`, `scripts/layer2/Phase2_Execution.gd`
- `scenes/layer2/Phase3_Monitoring.tscn`, `scripts/layer2/Phase3_Monitoring.gd`
- `scenes/layer2/Phase4_Closing.tscn`, `scripts/layer2/Phase4_Closing.gd`

Dependencies: Task 4.1 (PhaseBase), all component tasks, Task 0.5 (data files)

Context for Codex: Phase-specific content from Layer 2 design document Sections 3.1–3.4. Each phase prompt should include its specific risks table, NPCs, and special mechanics.

Prompt note: Build each phase as a separate Codex prompt. Include PhaseBase.gd as context so Codex knows what to extend.

---

**Task 4.4 — StakeholderConversation scene**

What to build: A specialized conversation scene for Dana's mandatory check-ins in Monitoring and Closing. Response options are dynamically generated based on actual project state.

Files to create: `scenes/shared/StakeholderConversation.tscn`, `scripts/shared/StakeholderConversation.gd`

Dependencies: Tasks 1.6 (NPCDialogue base), 0.3 (GameManager for project state)

Context for Codex: Stakeholder pressure mechanic from Layer 2 design document Section 3.3.

Test: Conversation options change based on health values. Choosing honest responses when health is poor results in slight trust decrease. Choosing deflective responses when health is poor results in larger trust decrease.

---

**Task 4.5 — ProjectOutcome and DebriefScreen**

What to build: The end-of-Layer-2 outcome simulation and comprehensive debrief.

Files to create:
- `scenes/layer2/ProjectOutcome.tscn`, `scripts/layer2/ProjectOutcome.gd`
- `scenes/layer2/DebriefScreen.tscn`, `scripts/layer2/DebriefScreen.gd`
- `scenes/shared/CascadeMap.tscn`, `scripts/shared/CascadeMap.gd`

Dependencies: Tasks 0.3, 1.3 (RippleEffect), all phase tasks

Context for Codex: Outcome and debrief design from Layer 2 design document Section 4.

Test: Outcome narrative changes based on actual health values. Debrief shows correct risk review, cascade map, decision tracing, and lessons learned.

---

**Task 4.6 — FailureSequence**

What to build: The emergency meeting, breaking point analysis, and restart options shown when a failure condition is met.

Files to create: `scenes/shared/FailureSequence.tscn`, `scripts/shared/FailureSequence.gd`

Dependencies: Tasks 0.1, 0.3, 1.6 (NPCDialogue for Dana conversation)

Context for Codex: Failure conditions and sequence from Layer 2 design document Section 5.

Test: Manually trigger a failure condition. Emergency meeting plays. Breaking point analysis correctly identifies the causal decisions. Restart options work.

---

### Build Phase 5: Layer 3 Additions

---

**Task 5.1 — DualProfileCard and ProfileShiftAnimation**

What to build: The dual profile card display (before/after or Dana/Katherine side by side) and the animated stat bar shift transition.

Files to create:
- `scenes/components/DualProfileCard.tscn`, `scripts/components/DualProfileCard.gd`
- `scenes/components/ProfileShiftAnimation.tscn`, `scripts/components/ProfileShiftAnimation.gd`

Dependencies: Task 1.5 (ClientProfileCard)

Context for Codex: Conflicting stakeholder mechanic from Layer 3 design document Section 2.1.

Test: Show Dana's original profile card. Trigger shift animation. Stat bars smoothly transition to new values. Both before and after states are visible.

---

**Task 5.2 — Layer 3 Phase Rooms (all four)**

What to build: The four phase scenes for Layer 3, extending PhaseBase with Layer 3 specific mechanics (ambiguity, ethical dimensions, reduced scaffolding).

Files to create:
- `scenes/layer3/Phase1_Stabilization.tscn`, `scripts/layer3/Phase1_Stabilization.gd`
- `scenes/layer3/Phase2_Growth.tscn`, `scripts/layer3/Phase2_Growth.gd`
- `scenes/layer3/Phase3_DueDiligence.tscn`, `scripts/layer3/Phase3_DueDiligence.gd`
- `scenes/layer3/Phase4_Transition.tscn`, `scripts/layer3/Phase4_Transition.gd`

Dependencies: Tasks 4.1 (PhaseBase), 5.1 (DualProfileCard), 1.9 (AmbiguousAssessment), all component tasks

Context for Codex: Phase-specific content from Layer 3 design document Sections 3.1–3.4. Reduced scaffolding rules from Section 2.4.

Prompt note: Build each phase as a separate Codex prompt. Include PhaseBase.gd plus the Layer 3 mechanic descriptions.

---

**Task 5.3 — Layer 2 echo system**

What to build: Logic in Layer 3 phase scripts that reads Layer 2 performance data and modifies risk probabilities and NPC dialogue accordingly.

Files to modify: `scripts/layer3/Phase2_Growth.gd` (and others as needed)

Dependencies: Task 5.2, Task 0.3 (GameManager stores Layer 2 performance)

Context for Codex: Layer 2 echo mechanic from Layer 3 design document Section 3.2 (GROW-04 probability modification).

Test: Complete Layer 2 with Quality Health "Declining." Enter Layer 3 Growth Phase. GROW-04 base probability should be 65% instead of 50%. Jordan's dialogue should reflect greater concern about technical debt.

---

**Task 5.4 — AcquisitionOutcome, ManagementProfile, and GrowthReflection**

What to build: The three end-of-Layer-3 screens.

Files to create:
- `scenes/layer3/AcquisitionOutcome.tscn`, `scripts/layer3/AcquisitionOutcome.gd`
- `scenes/layer3/ManagementProfile.tscn`, `scripts/layer3/ManagementProfile.gd`
- `scenes/layer3/GrowthReflection.tscn`, `scripts/layer3/GrowthReflection.gd`

Dependencies: Tasks 0.3, all Layer 3 phase tasks

Context for Codex: Outcome, profile, and reflection design from Layer 3 design document Section 4.

Test: Outcome narrative changes based on acquisition-related health values. Management profile correctly categorizes the player based on their behavioral patterns. Growth reflection accurately compares Layer 2 and Layer 3 statistics.

---

### Build Phase 6: Integration and Flow

---

**Task 6.1 — GameWorld scene and room transitions**

What to build: The master game world scene that manages room loading/unloading, door transitions between phases, and layer transitions. Integrates HUD as a persistent overlay.

Files to create: `scenes/main/GameWorld.tscn`, (modify existing game world script or create new)

Dependencies: All prior tasks

Context for Codex: The existing game world and room transition system from the current codebase. Scene relationship map from Section 2.1.

Test: Player starts in Layer 1 TrainingWing. Completing Layer 1 transitions to Layer 2 rooms. Completing Layer 2 transitions to Layer 3 rooms. HUD persists across all transitions.

---

**Task 6.2 — Main menu and game flow**

What to build: Main menu with New Game, Continue, and settings. New Game starts at Layer 1. Continue loads saved game state.

Files to modify: Existing `MainMenu.tscn` or create new

Dependencies: Task 6.1

Context for Codex: Existing main menu code.

Test: New Game drops player into TrainingWing. Game state saves between sessions. Continue loads correctly.

---

**Task 6.3 — Save/Load system**

What to build: Serialize and deserialize GameManager state to/from a save file. Auto-save at phase transitions.

Files to create: Add save/load methods to `GameManager.gd`

Dependencies: Task 0.3

GDScript scaffolding:
```gdscript
func save_game() -> void:
    var save_data = {
        "current_layer": current_layer,
        "current_phase": current_phase,
        "health_budget": health_budget,
        "health_schedule": health_schedule,
        "health_quality": health_quality,
        "health_stakeholder_trust": health_stakeholder_trust,
        "contingency_budget": contingency_budget,
        "risk_register": risk_register,
        "client_profile_active": client_profile_active,
        "layer1_performance": layer1_performance,
        "layer2_performance": layer2_performance,
        "layer3_performance": layer3_performance,
        "phase_results": phase_results,
        # ... all flags
    }
    var file = FileAccess.open("user://savegame.json", FileAccess.WRITE)
    file.store_string(JSON.stringify(save_data))

func load_game() -> bool:
    if not FileAccess.file_exists("user://savegame.json"):
        return false
    var file = FileAccess.open("user://savegame.json", FileAccess.READ)
    var json = JSON.new()
    json.parse(file.get_as_text())
    var data = json.data
    # Restore all state from data
    return true
```

Test: Play through Layer 1, save, close game, reopen, load. All state preserved. Play continues from correct point.

---

### Build Phase 7: Polish and Data Population

---

**Task 7.1 — Complete all JSON scenario data**

What to build: Fill in all skeleton JSON files created in Task 0.5 with complete scenario content from the Layer 2 and Layer 3 design documents.

Files to modify: All files in `data/scenarios/` and `data/npc_dialogues/`

Dependencies: Task 0.5

Context for Codex: The complete risk tables, NPC dialogue scripts, and scenario details from all three layer design documents.

Prompt note: Break this into one prompt per layer. Give Codex the relevant design document section and the JSON schema, and ask it to produce the complete data file.

---

**Task 7.2 — Complete all NPC dialogue trees**

What to build: Fill in all NPC dialogue JSON files with complete conversation trees for every interaction described in the design documents.

Files to modify: All files in `data/npc_dialogues/`

Dependencies: Task 7.1

Context for Codex: All NPC conversations from the three layer design documents, dialogue JSON schema.

---

**Task 7.3 — Balancing pass**

What to build: Review and adjust all numeric values — risk probabilities, health impacts, resource costs, capacity allocations — to ensure the game is challenging but fair per the design philosophy.

Files to modify: All JSON scenario files

Dependencies: Tasks 7.1, 7.2, and playtest data

Context for Codex: Fairness safeguards from Layer 2 Section 5 and Layer 3 Section 5. Provide Codex with the current values and ask it to verify that no single risk can cause a jump from On Track to Critical, that total mitigation costs per phase don't exceed available resources if the player is strategic, etc.

---

## 6. Codex Integration Notes

### 6.1 — General Prompting Strategy

**Rule 1: One task per prompt.** Each numbered task in Section 5 is one Codex prompt. Don't combine tasks — Codex produces better output with focused scope.

**Rule 2: Always provide existing file context.** When a task says "Dependencies: Task 1.1," that means you should paste the output of Task 1.1 (the completed files) into the Codex prompt so it knows what already exists. Codex doesn't see your project — you need to show it the relevant files.

**Rule 3: Include the scaffolding.** When a task includes GDScript scaffolding, paste it into the prompt and tell Codex to use it as the starting point. This ensures consistent patterns across all files.

**Rule 4: Specify the test.** Always include the test criteria from the task description in your prompt. Tell Codex: "The output should pass this test: [test from task]."

**Rule 5: Ask for complete files.** Tell Codex to output the complete `.gd` file and describe the `.tscn` scene structure. You may need to build scenes in the Godot editor based on Codex's description, since Codex can write GDScript but can't directly create .tscn files.

### 6.2 — Prompt Template

Use this template for every implementation task:

```
TASK: [Task number and name from Section 5]

CONTEXT: I'm building a 2D risk management game in Godot 4.4 using GDScript. The game teaches IT project risk management through interactive gameplay across three layers (teaching → simulation → mastery).

EXISTING FILES (paste relevant completed files here):
[Paste SignalBus.gd, GameManager.gd, and any dependency files]

WHAT TO BUILD:
[Copy the "What to build" section from the task]

FILE(S) TO CREATE:
[List exact file paths]

SCENE STRUCTURE (for .tscn files):
[Copy scene structure from task if provided]

GDSCRIPT SCAFFOLDING:
[Copy scaffolding from task if provided]

REQUIREMENTS:
- Output the complete GDScript file(s)
- Describe the .tscn scene tree so I can build it in the Godot editor
- Follow the setup()/completed signal pattern for all components
- Use SignalBus for all cross-scene communication
- Use GameManager for all state access and modification
- Use DataManager for all JSON data loading

TEST CRITERIA:
[Copy test from task]

Output the complete implementation.
```

### 6.3 — Handling .tscn Files

Codex can write GDScript but cannot directly produce binary .tscn scene files. For each task that requires a .tscn:

1. Ask Codex to describe the scene tree (what nodes, what types, what hierarchy)
2. Build the scene tree yourself in the Godot editor following Codex's description
3. Attach the .gd script Codex produced to the root node
4. Connect any signals Codex specified in the code

Alternatively, Codex can produce .tscn files in text format (Godot's text-based scene format), but this is error-prone for complex scenes. For simple scenes (a Control with a few children), text format works fine. For complex scenes with many nested nodes, building in the editor is more reliable.

### 6.4 — Task Dependency Quick Reference

```
Phase 0 (Foundation):     0.1 → 0.2 → 0.3 → 0.4 → 0.5
                          (0.1-0.3 can be parallel, 0.4 after all three)

Phase 1 (Components):     1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7 (all parallel)
                          1.8 depends on 1.3
                          1.9 is Layer 3 only, can be deferred

Phase 2 (HUD):            2.1, 2.2, 2.3, 2.4 (all parallel, all need Phase 0)
                          2.5 depends on 2.1-2.4

Phase 3 (Layer 1):        3.1 needs 1.1
                          3.2 needs 1.2
                          3.3 needs 1.3, 1.5, 1.6
                          3.4 needs 1.4
                          3.5 needs 1.3, 1.6, 1.7
                          3.6 needs all of 1.x and 3.1-3.5
                          3.7 needs 3.1-3.6

Phase 4 (Layer 2):        4.1 needs Phase 0 + Phase 1
                          4.2 needs Phase 0
                          4.3 needs 4.1, 4.2
                          4.4 needs 1.6
                          4.5 needs 4.3
                          4.6 needs 4.3

Phase 5 (Layer 3):        5.1 needs 1.5
                          5.2 needs 4.1, 5.1, 1.9
                          5.3 needs 5.2
                          5.4 needs 5.2

Phase 6 (Integration):    6.1 needs all phase rooms built
                          6.2 needs 6.1
                          6.3 needs 6.1

Phase 7 (Data/Polish):    7.1-7.3 can happen anytime after Phase 0
                          (but testing requires Phase 3-5)
```

### 6.5 — Recommended Build Order (Sequential, Solo Developer)

Since you're working alone, here's the exact order to build tasks:

```
0.1 → 0.2 → 0.3 → 0.4 → 0.5 →
1.1 → 1.2 → 1.3 → 1.4 → 1.5 → 1.6 → 1.7 → 1.8 →
2.1 → 2.2 → 2.3 → 2.4 → 2.5 →
3.1 → 3.2 → 3.3 → 3.4 → 3.5 → 3.6 → 3.7 →
[PLAYTEST LAYER 1 — verify everything works before proceeding]
4.1 → 4.2 → 4.3 → 4.4 → 4.5 → 4.6 →
7.1 (Layer 2 data only) →
[PLAYTEST LAYER 2]
1.9 → 5.1 → 5.2 → 5.3 → 5.4 →
7.1 (Layer 3 data) → 7.2 →
[PLAYTEST LAYER 3]
6.1 → 6.2 → 6.3 →
7.3 →
[FULL PLAYTEST]
[STYLE PASS — visual design decisions applied across all scenes]
```

The playtest checkpoints are critical. Don't build Layer 2 until Layer 1 plays correctly. Don't build Layer 3 until Layer 2 plays correctly. Each layer depends on the components working correctly, and catching bugs early saves enormous time.
