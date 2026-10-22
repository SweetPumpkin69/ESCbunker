class_name BunkerPlayer
extends CharacterBody3D
@export var camera: Camera3D
@export var inventory: BunkerInventory
@export var interactor: BunkerInteractor
@export var screw: BunkerScrewInteraction
@export var hud: BunkerHUD
@export_range(0.5, 6.0) var walk_speed: float = 2.4
@export_range(0.0005, 0.01) var mouse_sensitivity: float = 0.0022
var _ui_locked: bool = false
var _screw_locked: bool = false
var _pitch: float = 0.0

func _ready() -> void:
	add_to_group("bunker_players")
	_pitch = camera.rotation.x
	inventory.use_requested.connect(_use_item)
	hud.modal_changed.connect(func(open: bool): _ui_locked = open)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _input(event: InputEvent) -> void:
	if screw.is_active():
		screw.handle_input(event)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_cancel"):
		if not hud.modal.is_empty():
			hud.close_modal()
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("inventory"):
		hud.toggle_inventory()
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if controls_locked():
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.screen_relative.x * mouse_sensitivity)
		_pitch = clampf(_pitch - event.screen_relative.y * mouse_sensitivity, deg_to_rad(-82), deg_to_rad(82))
		camera.rotation.x = _pitch
	if event.is_action_pressed("interact"):
		interactor.interact()
		get_viewport().set_input_as_handled()

func controls_locked() -> bool:
	return _ui_locked or _screw_locked

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	var move := Vector2.ZERO
	if not controls_locked() and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		move = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := global_basis * Vector3(move.x, 0, move.y)
	velocity.x = move_toward(velocity.x, direction.x * walk_speed, delta * 12.0)
	velocity.z = move_toward(velocity.z, direction.z * walk_speed, delta * 12.0)
	move_and_slide()
	hud.set_prompt(null if controls_locked() else interactor.target)

func notify(text: String) -> void:
	hud.show_message(text)

func _use_item(item_id: StringName) -> void:
	if screw.is_active():
		return
	var item := inventory.get_item(item_id)
	if item == null or not interactor.use_inventory_item(item):
		notify("This item cannot be used here.")

func begin_screwing(slot: BunkerFuseSlot, item: BunkerItem) -> bool:
	return screw.begin(slot, item)

func set_screw_locked(locked: bool) -> void:
	_screw_locked = locked
	velocity.x = 0.0
	velocity.z = 0.0
