extends Node2D

const DEFAULT_MAX_SPEED: float = 320.0

@onready var rect: ColorRect = $Rect

var velocity: Vector2 = Vector2.ZERO
var gravity: float = 700.0
var lifetime: float = 0.0
var age: float = 0.0
var max_speed: float = DEFAULT_MAX_SPEED
var max_speed_sq: float = DEFAULT_MAX_SPEED * DEFAULT_MAX_SPEED
var base_color: Color = Color(1, 1, 1, 1)
var long_life_chance: float = 0.08
var short_life_range: Vector2 = Vector2(0.5, 2.0)
var long_life_range: Vector2 = Vector2(1.2, 4.0)

func setup(color: Color, initial_velocity: Vector2) -> void:
	if rect == null:
		rect = get_node_or_null("Rect") as ColorRect
	base_color = color
	if rect:
		rect.color = color
	velocity = _clamp_velocity(initial_velocity)
	age = 0.0
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	if rng.randf() < long_life_chance:
		lifetime = rng.randf_range(long_life_range.x, long_life_range.y)
	else:
		lifetime = rng.randf_range(short_life_range.x, short_life_range.y)

func _process(delta: float) -> void:
	age += delta
	if lifetime > 0.0:
		var t: float = clamp(age / lifetime, 0.0, 1.0)
		if rect:
			var c := base_color
			c.a *= 1.0 - t
			rect.color = c
	velocity.y += gravity * delta
	velocity = _clamp_velocity(velocity)
	position += velocity * delta
	var screen := App.get_layout_size()
	if age >= lifetime or global_position.y > screen.y + 100.0:
		queue_free()

func _clamp_velocity(value: Vector2) -> Vector2:
	var speed_sq := value.length_squared()
	if speed_sq <= max_speed_sq or speed_sq == 0.0:
		return value
	return value.normalized() * max_speed
