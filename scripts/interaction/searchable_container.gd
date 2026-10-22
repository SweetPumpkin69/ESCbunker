class_name BunkerSearchable
extends Node
@export var contents: Array[BunkerItem] = []
@export var interactable: BunkerInteractable
@export var searched_text: String = "Search (empty)"
var searched: bool = false

func interact(player: Node, _component: BunkerInteractable) -> void:
	if searched:
		player.call("notify", "Nothing else here.")
		return
	var inventory := player.get("inventory") as BunkerInventory
	var found: Array[String] = []
	var remaining: Array[BunkerItem] = []
	for item in contents:
		if inventory.add_item(item):
			found.append(item.display_name)
		else:
			remaining.append(item)
	contents = remaining
	searched = contents.is_empty()
	if searched and interactable != null:
		interactable.interaction_text = searched_text
	if found.is_empty():
		player.call("notify", "Inventory full, or you already have this item.")
	else:
		player.call("notify", "Found %s." % ", ".join(found))
