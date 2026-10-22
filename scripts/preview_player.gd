extends CharacterBody3D
## Solo walk-through only. Replace with a network player scene later.
@export_range(0.5, 6.0) var walk_speed: float = 2.4
@export_range(0.0005, 0.01) var mouse_sensitivity: float = 0.0022
@export var eye_height: float = 1.66
@onready var eyes: Camera3D = $Eyes
var pitch: float = 0.0

func _ready() -> void:
	eyes.position.y = eye_height
	pitch = eyes.rotation.x
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if event.keycode == KEY_H:
			$PreviewOverlay.visible = not $PreviewOverlay.visible
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		pitch = clampf(pitch - event.relative.y * mouse_sensitivity, deg_to_rad(-82), deg_to_rad(82))
		eyes.rotation.x = pitch

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	var move := Vector2.ZERO
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		move = Vector2(float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)), float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))).normalized()
	var direction := global_basis * Vector3(move.x, 0, move.y)
	velocity.x = move_toward(velocity.x, direction.x * walk_speed, delta * 10.0)
	velocity.z = move_toward(velocity.z, direction.z * walk_speed, delta * 10.0)
	move_and_slide()
