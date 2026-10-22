class_name BunkerGenerator
extends Node3D
enum State { MISSING_COMPONENTS, POWERED_NO_FUEL, SYSTEM_READY, RUNNING }
signal state_changed(new_state: State)
signal fuel_unlocked
signal engine_started
@export var left_slot: BunkerFuseSlot
@export var right_slot: BunkerFuseSlot
@export var start_interactable: BunkerInteractable
@export var yellow_light: Light3D
@export var green_light: Light3D
@export var yellow_material: StandardMaterial3D
@export var green_material: StandardMaterial3D
@export var powered_lights: Array[Light3D] = []
@export var engine_audio: AudioStreamPlayer3D
@export var beep_audio: AudioStreamPlayer3D
var state: State = State.MISSING_COMPONENTS
var fuel_is_unlocked: bool = false

func _ready() -> void:
	if left_slot != null:
		left_slot.installed.connect(_on_fuse_installed)
	if right_slot != null:
		right_slot.installed.connect(_on_fuse_installed)
	update_feedback()

func has_fuses() -> bool:
	return left_slot != null and right_slot != null and left_slot.is_installed and right_slot.is_installed

func interact(player: Node, component: BunkerInteractable) -> void:
	if component == start_interactable:
		request_start(player)
	else:
		player.call("notify", feedback_text())

func feedback_text() -> String:
	match state:
		State.MISSING_COMPONENTS: return "Missing components."
		State.POWERED_NO_FUEL: return "Generator has power, but no fuel."
		State.SYSTEM_READY: return "System ready."
		State.RUNNING: return "Generator running. Return to the exit panel."
	return "Missing components."

func _on_fuse_installed(_slot: BunkerFuseSlot, _item_id: StringName) -> void:
	if has_fuses() and state == State.MISSING_COMPONENTS:
		transition(State.POWERED_NO_FUEL)
	else:
		for player in get_tree().get_nodes_in_group("bunker_players"):
			player.call("notify", "Fuse secured. One slot remains.")

func unlock_fuel() -> bool:
	if not has_fuses() or state != State.POWERED_NO_FUEL or fuel_is_unlocked:
		return false
	fuel_is_unlocked = true
	if beep_audio != null:
		beep_audio.play()
	transition(State.SYSTEM_READY)
	fuel_unlocked.emit()
	return true

func request_start(player: Node) -> bool:
	if state != State.SYSTEM_READY:
		if player != null:
			player.call("notify", feedback_text())
		return false
	transition(State.RUNNING)
	if engine_audio != null:
		engine_audio.play()
	engine_started.emit()
	return true

func transition(next: State) -> void:
	if next == state:
		return
	state = next
	update_feedback()
	state_changed.emit(state)
	for player in get_tree().get_nodes_in_group("bunker_players"):
		player.call("notify", feedback_text())

func update_feedback() -> void:
	var yellow := state == State.POWERED_NO_FUEL
	var green := state == State.SYSTEM_READY or state == State.RUNNING
	if yellow_light != null:
		yellow_light.visible = yellow
	if green_light != null:
		green_light.visible = green
	if yellow_material != null:
		yellow_material.emission_enabled = yellow
	if green_material != null:
		green_material.emission_enabled = green
	for light in powered_lights:
		if light != null:
			light.visible = state == State.RUNNING
