extends Node
## JuiceManager — Global polish & feedback utility
## Provides: hit-stop, screen shake, floating combat text, audio tones
## NOTE: All audio functions are NON-async (no await) — safe to call from _process.

# Persistent container for AudioStreamPlayers — lives on the autoload so it
# is never freed during scene transitions (unlike current_scene children).
var _audio_root: Node

func _ready() -> void:
	_audio_root = Node.new()
	_audio_root.name = "AudioRoot"
	add_child(_audio_root)

# ── Screen Shake & Hit-Stop ──────────────────────────────────────────────────

func hit_stop_and_shake(intensity: float = 8.0) -> void:
	# Capture the scene we're running in BEFORE the await.
	# If the scene changes while we're suspended, we bail out safely.
	var scene_before = get_tree().current_scene
	Engine.time_scale = 0.05
	await get_tree().create_timer(0.06, true, false, true).timeout
	# Always restore time scale — no matter what happened during the await.
	Engine.time_scale = 1.0
	# If the scene changed while we were awaiting, stop here — the old camera
	# no longer exists and trying to tween it will crash.
	if not is_instance_valid(scene_before) or get_tree().current_scene != scene_before:
		return
	var cam: Camera2D = _get_camera()
	if not cam:
		return
	var tw = cam.create_tween()
	for _i in 6:
		tw.tween_property(cam, "offset",
			Vector2(randf_range(-intensity, intensity),
					randf_range(-intensity, intensity)), 0.035)
	tw.tween_property(cam, "offset", Vector2.ZERO, 0.05)

func shake_only(intensity: float = 5.0) -> void:
	var cam: Camera2D = _get_camera()
	if not cam:
		return
	var tw = cam.create_tween()
	for _i in 4:
		tw.tween_property(cam, "offset",
			Vector2(randf_range(-intensity, intensity),
					randf_range(-intensity, intensity)), 0.03)
	tw.tween_property(cam, "offset", Vector2.ZERO, 0.04)

## Force time_scale back to 1.0. Called by MinigameOverlay._end_game() as a
## safety net so a pending hit_stop_and_shake can never leave the game frozen.
func reset_time_scale() -> void:
	Engine.time_scale = 1.0

func _get_camera() -> Camera2D:
	if not is_instance_valid(get_tree()):
		return null
	var scene = get_tree().current_scene
	if not is_instance_valid(scene):
		return null
	for node in scene.get_children():
		if node is Camera2D:
			return node
	return scene.find_child("Camera2D", true, false) as Camera2D

# ── Floating Combat Text ─────────────────────────────────────────────────────

func spawn_floating_text(parent: Node, pos: Vector2, text: String, color: Color) -> void:
	if not is_instance_valid(parent):
		return
	var lbl := Label.new()
	lbl.text = text
	lbl.position = pos - Vector2(len(text) * 5, 0)
	lbl.z_index = 200
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", 20)
	parent.add_child(lbl)
	var tw = lbl.create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:y", pos.y - 70.0, 0.9)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.9)
	# Guard: the label may already be freed if _game_area was cleared before the
	# 0.9s tween completes (e.g. player exits minigame or next game starts).
	tw.chain().tween_callback(func(): if is_instance_valid(lbl): lbl.queue_free())

# ── Audio Tones (NON-async) ──────────────────────────────────────────────────
# Uses AudioStreamPlayer.finished signal → queue_free instead of await.
# This means these functions return immediately and are safe to call from _process.

func _make_player(duration: float, vol_db: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	# Add to the persistent _audio_root (child of this autoload) rather than
	# the current scene. This means audio keeps playing safely across scene
	# transitions and never becomes a dangling child of a freed scene.
	_audio_root.add_child(player)
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 22050.0
	gen.buffer_length = duration + 0.05
	player.stream = gen
	player.volume_db = vol_db
	# Auto-free when playback ends — no await needed
	player.finished.connect(player.queue_free)
	return player

## Play a simple sine-wave tone. Safe to call from _process.
func play_tone(freq: float, duration: float, vol_db: float = -8.0) -> void:
	var player := _make_player(duration, vol_db)
	if not is_instance_valid(player):
		return
	player.play()
	var pb := player.get_stream_playback() as AudioStreamGeneratorPlayback
	if pb == null:
		player.queue_free()
		return
	var frame_count := int(22050.0 * duration)
	for i in frame_count:
		var t := float(i) / 22050.0
		var env := 1.0 - (float(i) / float(frame_count))
		var sample := sin(TAU * freq * t) * 0.28 * env
		pb.push_frame(Vector2(sample, sample))

## Play a two-tone frequency sweep. Safe to call from _process.
func play_sweep(freq_start: float, freq_end: float, duration: float) -> void:
	var player := _make_player(duration, -6.0)
	if not is_instance_valid(player):
		return
	player.play()
	var pb := player.get_stream_playback() as AudioStreamGeneratorPlayback
	if pb == null:
		player.queue_free()
		return
	var frame_count := int(22050.0 * duration)
	for i in frame_count:
		var t := float(i) / 22050.0
		var pct := float(i) / float(frame_count)
		var freq: float = lerp(freq_start, freq_end, pct)
		var env := 1.0 - pct * 0.5
		var sample := sin(TAU * freq * t) * 0.28 * env
		pb.push_frame(Vector2(sample, sample))

# ── Convenience helpers ──────────────────────────────────────────────────────

func correct_sound() -> void:
	play_tone(880.0, 0.12)

func wrong_sound() -> void:
	play_tone(200.0, 0.22)

func bonus_sound() -> void:
	play_sweep(880.0, 1400.0, 0.30)

func game_over_sound() -> void:
	play_sweep(400.0, 150.0, 0.5)
