class_name BunkerInventory
extends Node
## One inventory per player. No global singleton or scene-name dependency.
signal changed
signal use_requested(item_id: StringName)
@export_range(1, 64) var capacity: int = 12
var _items: Array[BunkerItem] = []
var _reservations: Dictionary = {}

func add_item(item: BunkerItem) -> bool:
	if item == null or item.id.is_empty() or has_item(item.id) or _items.size() >= capacity:
		return false
	_items.append(item)
	changed.emit()
	return true

func get_items() -> Array[BunkerItem]:
	return _items.duplicate()

func get_item(item_id: StringName) -> BunkerItem:
	for item in _items:
		if item.id == item_id:
			return item
	return null

func has_item(item_id: StringName) -> bool:
	return get_item(item_id) != null

func is_reserved(item_id: StringName) -> bool:
	return _reservations.has(item_id)

func request_use(item_id: StringName) -> void:
	if has_item(item_id) and not is_reserved(item_id):
		use_requested.emit(item_id)

func reserve_item(item_id: StringName, token: Node) -> bool:
	if not has_item(item_id) or is_reserved(item_id) or not is_instance_valid(token):
		return false
	_reservations[item_id] = token
	changed.emit()
	return true

func release_item(item_id: StringName, token: Node) -> void:
	if _reservations.get(item_id) == token:
		_reservations.erase(item_id)
		changed.emit()

func consume_reserved(item_id: StringName, token: Node) -> bool:
	if _reservations.get(item_id) != token:
		return false
	var item := get_item(item_id)
	if item == null:
		return false
	_reservations.erase(item_id)
	_items.erase(item)
	changed.emit()
	return true
