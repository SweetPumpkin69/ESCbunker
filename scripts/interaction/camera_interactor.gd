class_name BunkerInteractor
extends Node
signal target_changed(target: BunkerInteractable)
@export var camera: Camera3D
@export var player_body: CharacterBody3D
@export_range(0.5, 6.0) var reach: float = 3.0
@export_flags_3d_physics var ray_mask: int = 3
var target: BunkerInteractable

func _physics_process(_delta: float) -> void:
	refresh_target()

func refresh_target() -> BunkerInteractable:
	if not is_instance_valid(camera) or not is_instance_valid(player_body):
		return null
	var origin := camera.global_position
	var end := origin - camera.global_basis.z * reach
	var query := PhysicsRayQueryParameters3D.create(origin, end, ray_mask)
	query.exclude = [player_body.get_rid()]
	query.collide_with_areas = true
	query.collide_with_bodies = true
	var hit := camera.get_world_3d().direct_space_state.intersect_ray(query)
	var next: BunkerInteractable = null
	if not hit.is_empty() and hit.collider is BunkerInteractable:
		next = hit.collider as BunkerInteractable
		if not next.enabled:
			next = null
	if next != target:
		target = next
		target_changed.emit(target)
	return target

func interact() -> void:
	var current := refresh_target()
	if current != null:
		current.interact(player_body)

func use_inventory_item(item: BunkerItem) -> bool:
	# The aimed target wins. Inventory UI does not change the last camera direction.
	var current := refresh_target()
	if current != null and current.can_use_item(item, player_body):
		return current.begin_item_use(item, player_body)
	# Also accept standing inside the correct target's Inspector-assigned UseArea.
	for node in get_tree().get_nodes_in_group("bunker_interactables"):
		var candidate := node as BunkerInteractable
		if candidate != null and candidate.contains_player(player_body) and candidate.can_use_item(item, player_body):
			return candidate.begin_item_use(item, player_body)
	return false
