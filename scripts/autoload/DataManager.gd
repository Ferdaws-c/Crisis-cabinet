extends Node

var _scenario_data: Dictionary = {}
var _dialogue_data: Dictionary = {}
var _client_profiles: Dictionary = {}
var _config_data: Dictionary = {}

const DATA_ROOT := "res://data"
const SCENARIOS_DIR := "res://data/scenarios"
const DIALOGUES_DIR := "res://data/npc_dialogues"
const CLIENT_PROFILES_FILE := "res://data/client_profiles.json"
const CONFIG_FILE := "res://data/config.json"

func _ready() -> void:
    _load_all_data()

func _load_all_data() -> void:
    _scenario_data.clear()
    _dialogue_data.clear()
    _client_profiles.clear()
    _config_data.clear()

    _load_scenarios()
    _load_dialogues()

    if FileAccess.file_exists(CLIENT_PROFILES_FILE):
        var profiles_data := _load_json(CLIENT_PROFILES_FILE)
        if profiles_data is Dictionary:
            _client_profiles = profiles_data
    else:
        push_warning("DataManager: Optional file missing: %s" % CLIENT_PROFILES_FILE)

    if FileAccess.file_exists(CONFIG_FILE):
        var config_data := _load_json(CONFIG_FILE)
        if config_data is Dictionary:
            _config_data = config_data
    else:
        push_warning("DataManager: Optional file missing: %s" % CONFIG_FILE)

func _load_scenarios() -> void:
    if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(SCENARIOS_DIR)):
        push_warning("DataManager: Scenarios directory missing: %s" % SCENARIOS_DIR)
        return

    var dir := DirAccess.open(SCENARIOS_DIR)
    if dir == null:
        push_warning("DataManager: Failed to open scenarios directory: %s" % SCENARIOS_DIR)
        return

    dir.list_dir_begin()
    var file_name := dir.get_next()
    while file_name != "":
        if not dir.current_is_dir() and file_name.get_extension().to_lower() == "json":
            var path := "%s/%s" % [SCENARIOS_DIR, file_name]
            var data := _load_json(path)
            if data.is_empty():
                file_name = dir.get_next()
                continue

            var key := ""
            if data.has("layer") and data.has("phase"):
                key = "layer%d_%s" % [int(data["layer"]), str(data["phase"]).to_lower()]
            else:
                key = file_name.get_basename().to_lower()

            _scenario_data[key] = data
        file_name = dir.get_next()
    dir.list_dir_end()

func _load_dialogues() -> void:
    if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(DIALOGUES_DIR)):
        push_warning("DataManager: Dialogue directory missing: %s" % DIALOGUES_DIR)
        return

    var dir := DirAccess.open(DIALOGUES_DIR)
    if dir == null:
        push_warning("DataManager: Failed to open dialogue directory: %s" % DIALOGUES_DIR)
        return

    dir.list_dir_begin()
    var file_name := dir.get_next()
    while file_name != "":
        if not dir.current_is_dir() and file_name.get_extension().to_lower() == "json":
            var path := "%s/%s" % [DIALOGUES_DIR, file_name]
            var data := _load_json(path)
            if data.is_empty():
                file_name = dir.get_next()
                continue

            var npc_id := str(data.get("npc_id", file_name.get_basename().replace("_dialogues", ""))).to_lower()
            _dialogue_data[npc_id] = data
        file_name = dir.get_next()
    dir.list_dir_end()

func _load_json(path: String) -> Dictionary:
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        push_warning("DataManager: Failed to load: %s" % path)
        return {}

    var json := JSON.new()
    var parse_error := json.parse(file.get_as_text())
    if parse_error != OK:
        push_warning("DataManager: Failed to parse %s: %s" % [path, json.get_error_message()])
        return {}

    if json.data is Dictionary:
        return json.data

    push_warning("DataManager: Expected Dictionary root in %s" % path)
    return {}

func get_phase_data(phase: String, layer: int) -> Dictionary:
    var key := "layer%d_%s" % [layer, phase.to_lower()]
    return _scenario_data.get(key, {})

func get_dialogue(npc_id: String, dialogue_id: String) -> Dictionary:
    var normalized_npc_id := npc_id.to_lower()
    if _dialogue_data.has(normalized_npc_id):
        return _dialogue_data[normalized_npc_id].get("dialogues", {}).get(dialogue_id, {})
    return {}

func get_npc_info(npc_id: String) -> Dictionary:
    var normalized_npc_id := npc_id.to_lower()
    if _dialogue_data.has(normalized_npc_id):
        var d: Dictionary = _dialogue_data[normalized_npc_id]
        return {
            "display_name": d.get("display_name", ""),
            "role": d.get("role", ""),
            "avatar_path": d.get("avatar_path", "")
        }
    return {}

func get_client_profile(profile_id: String) -> Dictionary:
    return _client_profiles.get(profile_id, {})

func get_config() -> Dictionary:
    return _config_data

func find_risk_by_id(risk_id: String) -> Dictionary:
    for key in _scenario_data:
        var phase_data: Dictionary = _scenario_data[key]
        for risk in phase_data.get("risks", []):
            if risk.get("id", "") == risk_id:
                return risk.duplicate(true)
        for risk in phase_data.get("hidden_risks", []):
            if risk.get("id", "") == risk_id:
                return risk.duplicate(true)
    return {}
