class_name BunkerFuseSlot
extends Node3D
signal installed(slot: BunkerFuseSlot, item_id: StringName)
@export var required_item: StringName = &"fuse_square"
@export var slot_label: String = "4"
@export var interactable: BunkerInteractable
@export var screw_pivot: Node3D
@export var focus_marker: Marker3D
@export_range(0.1, 5.0) var required_turns: float = 1.5
@export var local_rotation_axis: Vector3 = Vector3.FORWARD
@export var insertion_offset: Vector3 = Vector3(0, 0, -0.12)
var is_installed: bool = false
var installed_item: StringName
var _occupant: Node

func _ready() -> void:
	if screw_pivot != null:
		screw_pivot.visible = is_installed

func interact(player: Node, _component: BunkerInteractable) -> void:
	if is_installed:
		player.call("notify", "Fuse secured.")
	else:
		player.call("notify", "Slot %s. Select a matching fuse in your inventory." % slot_label)

func can_use_item(item: BunkerItem, _player: Node) -> bool:
	return item != null and item.id == required_item and not is_installed and not is_instance_valid(_occupant)

func begin_item_use(item: BunkerItem, player: Node) -> bool:
	if not can_use_item(item, player):
		return false
	return bool(player.call("begin_screwing", self, item))

func reserve(item: BunkerItem, player: Node) -> bool:
	if not can_use_item(item, player):
		return false
	var inventory := player.get("inventory") as BunkerInventory
	if not inventory.reserve_item(item.id, self):
		return false
	_occupant = player
	screw_pivot.show()
	return true

func cancel(item: BunkerItem, player: Node) -> void:
	if _occupant != player:
		return
	var inventory := player.get("inventory") as BunkerInventory
	inventory.release_item(item.id, self)
	_occupant = null
	if not is_installed:
		screw_pivot.hide()

func complete(item: BunkerItem, player: Node) -> bool:
	if _occupant != player or is_installed:
		return false
	var inventory := player.get("inventory") as BunkerInventory
	if not inventory.consume_reserved(item.id, self):
		return false
	is_installed = true
	installed_item = item.id
	_occupant = null
	screw_pivot.show()
	interactable.interaction_text = "Fuse %s secured" % slot_label
	installed.emit(self, installed_item)
	return true
