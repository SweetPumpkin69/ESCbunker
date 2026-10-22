class_name BunkerFuelLock
extends Node3D
signal unlocked
@export var generator: BunkerGenerator
@export var combination: String = "532"
@export var padlock: RigidBody3D
@export var valve_wheel: Node3D
@export var interactable: BunkerInteractable
var is_unlocked: bool = false

func interact(player: Node, _component: BunkerInteractable) -> void:
	if is_unlocked:
		player.call("notify", "Fuel supply open.")
	elif not generator.has_fuses():
		player.call("notify", "Install the generator fuses first.")
	else:
		var hud: Node = player.get("hud")
		hud.call("open_lock", self)

func submit_code(code: String, player: Node) -> bool:
	if is_unlocked:
		return true
	if not generator.has_fuses() or generator.state != BunkerGenerator.State.POWERED_NO_FUEL:
		player.call("notify", "Install the generator fuses first.")
		return false
	if code.length() != 3 or code != combination:
		player.call("notify", "Incorrect code.")
		return false
	if not generator.unlock_fuel():
		return false
	is_unlocked = true
	interactable.interaction_text = "Fuel supply open"
	if padlock != null:
		padlock.freeze = false
		padlock.sleeping = false
		padlock.apply_central_impulse(global_basis * Vector3(0.13, 0.04, 0.18))
	if valve_wheel != null:
		create_tween().tween_property(valve_wheel, "rotation:z", valve_wheel.rotation.z + PI * 0.7, 0.8)
	unlocked.emit()
	return true
