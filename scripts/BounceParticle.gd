extends CharacterBody2D

@onready var rect: ColorRect = $Rect

var velocity: Vector2 = Vector2.ZERO
var gravity: float = 900.0
var lifetime: float = 4.0
var bounce_damping: float = 0.85

func setup(color: Color, initial_velocity: Vector2) -> void:
	if rect:
		rect.color = color
	velocity = initial_velocity

func _physics_process(delta: float) -> void:
	lifetime -= delta
	velocity.y += gravity * delta
	var collision := move_and_collide(velocity * delta)
	if collision:
		velocity = velocity.bounce(collision.get_normal()) * bounce_damping
	var screen := App.get_layout_size()
	if lifetime <= 0.0 or global_position.y > screen.y + 200.0:
		queue_free()
