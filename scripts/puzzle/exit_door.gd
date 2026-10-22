class_name BunkerExitDoor
extends Node3D
signal opening_started
signal opened
@export var generator: BunkerGenerator
@export var door_leaf: Node3D
@export var panel_interactable: BunkerInteractable
@export var panel_material: StandardMaterial3D
@export var panel_light: Light3D
@export var opening_offset: Vector3 = Vector3(-2.15, 0, 0)
@export_range(0.5, 12.0) var opening_seconds: float = 4.5
@export var motor_audio: AudioStreamPlayer3D
var is_open: bool = false
var is_opening: bool = false

func interact(player: Node, component: BunkerInteractable) -> void:
	if generator.state != BunkerGenerator.State.RUNNING:
		player.call("notify", "No power.")
		return
	if component != panel_interactable and not is_open and not is_opening:
		player.call("notify", "Use the exit panel.")
		return
	if is_open or is_opening:
		player.call("notify", "Bunker access granted." if is_open else "Door opening...")
		return
	open()

func open() -> void:
	# Recheck the invariant even if called from another script.
	if is_open or is_opening or generator.state != BunkerGenerator.State.RUNNING or door_leaf == null:
		return
	is_opening = true
	if panel_material != null:
		panel_material.albedo_color = Color(0.025, 0.35, 0.12)
		panel_material.emission = Color(0.04, 0.85, 0.3)
		panel_material.emission_enabled = true
	if panel_light != null:
		panel_light.show()
	if motor_audio != null:
		motor_audio.play()
	opening_started.emit()
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(door_leaf, "position", door_leaf.position + opening_offset, opening_seconds)
	tween.tween_callback(func():
		is_opening = false
		is_open = true
		if motor_audio != null:
			motor_audio.stop()
		opened.emit()
		for player in get_tree().get_nodes_in_group("bunker_players"):
			player.call("notify", "Bunker access granted."))
