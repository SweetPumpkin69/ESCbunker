class_name BunkerInteractable
extends Area3D
## Put on collision layer 2. World geometry stays on layer 1 and occludes the ray.
## Controller contract: interact(player, component), can_use_item(item, player),
## and begin_item_use(item, player). Assign the controller in the Inspector.
@export var controller: Node
@export var interaction_text: String = "Interact"
@export var enabled: bool = true
@export var use_area: Area3D

func _ready() -> void:
	add_to_group("bunker_interactables")

func interact(player: Node) -> void:
	if enabled and is_instance_valid(controller) and controller.has_method("interact"):
		controller.call("interact", player, self)

func can_use_item(item: BunkerItem, player: Node) -> bool:
	return enabled and is_instance_valid(controller) and controller.has_method("can_use_item") and bool(controller.call("can_use_item", item, player))

func begin_item_use(item: BunkerItem, player: Node) -> bool:
	if can_use_item(item, player) and controller.has_method("begin_item_use"):
		return bool(controller.call("begin_item_use", item, player))
	return false

func contains_player(player: Node3D) -> bool:
	return is_instance_valid(use_area) and use_area.overlaps_body(player)
