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
