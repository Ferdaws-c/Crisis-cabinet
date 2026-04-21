extends CharacterBody2D

const SPEED = 200.0
const TILE_SIZE = 64.0

var _accumulated_distance: float = 0.0
var is_drinking: bool = false

@onready var anim = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	
	
	if GameManager.is_movement_paused or GameManager.game_over or is_drinking:
		velocity = Vector2.ZERO
		if not is_drinking and not GameManager.is_movement_paused:
			anim.play("idle")
		return
		
	if Input.is_action_just_pressed("drink"):
		is_drinking = true
		anim.play("drink_coffee")
		await anim.animation_finished 
		is_drinking = false
		return 
		
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# DIAGNOSTIC 2: Is Godot seeing your keyboard?
	
	
	if direction != Vector2.ZERO:
		velocity = direction * SPEED
		
		if direction.x > 0:
			anim.play("walk_right")
		elif direction.x < 0:
			anim.play("walk_left")
		elif direction.y > 0:
			anim.play("walk_down")
		elif direction.y < 0:
			anim.play("walk_up")
			
		var distance_moved = velocity.length() * delta
		_accumulated_distance += distance_moved
		
		while _accumulated_distance >= TILE_SIZE:
			_accumulated_distance -= TILE_SIZE
			GameManager.walk_tile()
	else:
		velocity = velocity.move_toward(Vector2.ZERO, SPEED)
		anim.play("idle") 
		
	
		
	move_and_slide()
