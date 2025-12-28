extends "res://scripts/Ball.gd"

func setup(color: Color, initial_velocity: Vector2) -> void:
	if rect:
		rect.color = color
	if initial_velocity.length() > 0.0:
		speed = initial_velocity.length()
		velocity = initial_velocity
		launched = true

func _ready() -> void:
	if paddle_path == NodePath(""):
		var paddle_node := get_tree().root.find_child("Paddle", true, false)
		if paddle_node:
			paddle_path = paddle_node.get_path()
	super._ready()

func _reset() -> void:
	queue_free()
