extends CharacterBody2D

@export var speed: float = 420.0
@export var half_width: float = 50.0

@onready var rect: ColorRect = $Rect
@onready var collider: CollisionShape2D = $CollisionShape2D

var locked_y: float = 0.0

func _ready() -> void:
	locked_y = global_position.y

func _physics_process(_delta: float) -> void:
	var right_strength: float = float(Input.get_action_strength("ui_right"))
	var left_strength: float = float(Input.get_action_strength("ui_left"))
	var direction: float = right_strength - left_strength

	velocity.x = direction * speed
	velocity.y = 0.0
	move_and_slide()

	var viewport_width: float = get_viewport_rect().size.x
	var clamped_x: float = clamp(global_position.x, half_width, viewport_width - half_width)
	global_position.x = clamped_x
	global_position.y = locked_y

func set_half_width(value: float) -> void:
	half_width = max(20.0, value)
	rect.size.x = half_width * 2.0
	rect.position.x = -half_width
	if collider.shape is RectangleShape2D:
		var shape: RectangleShape2D = collider.shape as RectangleShape2D
		shape.size.x = half_width * 2.0

func set_locked_y(value: float) -> void:
	locked_y = value
