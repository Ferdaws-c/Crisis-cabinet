extends StaticBody2D

@export var required_xp: int = 165
var is_unlocked: bool = false
var player_in_zone: bool = false

@onready var anim = $AnimatedSprite2D
@onready var collision_wall = $CollisionShape2D

func _ready() -> void:
	if anim.sprite_frames and anim.sprite_frames.has_animation("locked"):
		anim.play("locked")
	
	var area = $Area2D
	if area:
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)
		
	GameManager.state_changed.connect(_check_phase)
	
	# Initial check in case it's already past the phase natively
	_check_phase.call_deferred()

func _check_phase() -> void:
	if is_unlocked: return
	
	var phase_map = {"Executing": 1, "Monitoring": 2, "Closing": 3, "Finished": 4}
	var current_phase_level = phase_map.get(GameManager.current_phase, 0)
	
	var required_phase_level = 1
	if required_xp >= 500:
		required_phase_level = 4
	elif required_xp >= 495:
		required_phase_level = 3
	elif required_xp >= 330:
		required_phase_level = 2
	elif required_xp <= 0:
		if GameManager.has_read_info:
			required_phase_level = 0
		else:
			required_phase_level = 99 # Hard lock until info is read
		
	if current_phase_level >= required_phase_level:
		_perform_unlock()

func _input(event: InputEvent) -> void:
	if not player_in_zone: return
	
	# Explicitly map raw Spacebar key just in case bindings are corrupted
	if event.is_action_pressed("interact") or (event is InputEventKey and event.keycode == KEY_SPACE and event.pressed):
		if not is_unlocked:
			_check_phase()
			if not is_unlocked:
				# Show visual feedback that it failed!
				_flash_warning()

func _flash_warning() -> void:
	var lbl = Label.new()
	lbl.text = "PHASE LOCKED"
	lbl.add_theme_color_override("font_color", Color(1, 0, 0))
	lbl.position = Vector2(-30, -40)
	add_child(lbl)
	var tw = create_tween()
	tw.tween_property(lbl, "position:y", -60, 1.0)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 1.0)
	tw.tween_callback(lbl.queue_free)

func _perform_unlock() -> void:
	is_unlocked = true
	# Absolutely destroy the physical collision shape to prevent engine caching bugs
	if is_instance_valid(collision_wall):
		collision_wall.queue_free()
		
	if anim and anim.sprite_frames and anim.sprite_frames.has_animation("unlocked"):
		anim.sprite_frames.set_animation_loop("unlocked", false)
		anim.play("unlocked")

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_in_zone = true

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_in_zone = false
