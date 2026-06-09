extends Node

# GPAF (Gamification Analytics Format) Logger
# Quietly records game events during a player's session and exports them as JSONL.

const GAME_ID = "GM-CrisisCabinetV2"

# Session identifiers
var player_pseudo_id: String = ""
var session_id: String = ""
var events: Array = []

func _ready() -> void:
	# Initialize stable player pseudonymous ID and current session ID
	player_pseudo_id = get_or_create_pseudo_id()
	session_id = generate_session_id()
	
	# Start tracking
	start_session()

# Generates or loads a stable pseudonymous ID saved locally
func get_or_create_pseudo_id() -> String:
	if FileAccess.file_exists("user://gpaf_player_id.txt"):
		var f = FileAccess.open("user://gpaf_player_id.txt", FileAccess.READ)
		if f:
			var id = f.get_as_text().strip_edges()
			f.close()
			if id != "":
				return id
	
	# Generate a new pseudonymous ID (e.g. p_ + 8 random hex characters)
	var new_id = "p_"
	var hex_chars = "0123456789abcdef"
	for i in range(8):
		new_id += hex_chars[randi() % 16]
		
	var f = FileAccess.open("user://gpaf_player_id.txt", FileAccess.WRITE)
	if f:
		f.store_string(new_id)
		f.close()
	return new_id

# Generates a random session ID for this run
func generate_session_id() -> String:
	var new_sid = "s_"
	var hex_chars = "0123456789abcdef"
	for i in range(8):
		new_sid += hex_chars[randi() % 16]
	return new_sid

# Start the session (session_start event)
func start_session() -> void:
	events.clear()
	# Regenerate session ID for each new run
	session_id = generate_session_id()
	_add_event("session_start", {})

# Record score updates
func log_score_update(score: int) -> void:
	_add_event("score_update", { "score": score })

# Record level completion (minigame completes)
func log_level_complete(level_num: int) -> void:
	_add_event("level_complete", { "level": level_num })

# End the session (session_end event)
func end_session(completed: bool) -> void:
	_add_event("session_end", { "completed": completed })

# Helper to build and append a structured event matching the GPAF template
func _add_event(event_type: String, payload: Dictionary) -> void:
	# Format ISO-8601 timestamp in UTC: YYYY-MM-DDTHH:MM:SSZ
	var ts = Time.get_datetime_string_from_system(true) + "Z"
	
	var event = {
		"ts": ts,
		"playerPseudoId": player_pseudo_id,
		"sessionId": session_id,
		"gameId": GAME_ID,
		"eventType": event_type,
		"payload": payload
	}
	events.append(event)

# Format recorded events into JSONL (JSON Lines) format
func get_jsonl_string() -> String:
	var lines = []
	for event in events:
		lines.append(JSON.stringify(event))
	return "\n".join(lines)

# Triggers local file save dialog to download/save the jsonl file
func export_logs_to_file(parent_node: Node) -> void:
	var fd = FileDialog.new()
	fd.title = "Save Game Logs (JSONL)"
	fd.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	fd.access = FileDialog.ACCESS_FILESYSTEM
	fd.filters = PackedStringArray(["*.jsonl ; JSON Lines Files", "*.json ; JSON Files"])
	fd.current_file = "game_logs_%s.jsonl" % player_pseudo_id
	fd.use_native_dialog = true
	
	parent_node.add_child(fd)
	
	fd.file_selected.connect(func(path: String):
		var file = FileAccess.open(path, FileAccess.WRITE)
		if file:
			file.store_string(get_jsonl_string())
			file.close()
		fd.queue_free()
	)
	
	fd.canceled.connect(func():
		fd.queue_free()
	)
	
	fd.popup_centered(Vector2i(800, 600))
