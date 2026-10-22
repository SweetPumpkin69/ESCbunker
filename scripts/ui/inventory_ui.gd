class_name BunkerInventoryUI
extends PanelContainer
signal close_requested
@export var inventory: BunkerInventory
@export var item_list: ItemList
@export var details: Label
@export var use_button: Button
@export var close_button: Button
var selected_id: StringName

func _ready() -> void:
	inventory.changed.connect(refresh)
	item_list.item_selected.connect(_on_selected)
	use_button.pressed.connect(_on_use)
	close_button.pressed.connect(func(): close_requested.emit())
	refresh()

func refresh() -> void:
	item_list.clear()
	var selected_index := -1
	for item in inventory.get_items():
		var index := item_list.add_item("%s   %s" % [item.symbol, item.display_name], item.icon)
		item_list.set_item_metadata(index, item.id)
		item_list.set_item_custom_fg_color(index, item.color)
		item_list.set_item_disabled(index, inventory.is_reserved(item.id))
		if item.id == selected_id:
			selected_index = index
	if selected_index >= 0:
		item_list.select(selected_index)
		_on_selected(selected_index)
	else:
		selected_id = &""
		use_button.hide()
		details.text = "Select an item to inspect it." if item_list.item_count > 0 else "Your inventory is empty. Search boxes and shelves with F."

func _on_selected(index: int) -> void:
	selected_id = StringName(item_list.get_item_metadata(index))
	var item := inventory.get_item(selected_id)
	if item == null:
		return
	details.text = "%s\n\n%s" % [item.display_name, item.description]
	use_button.visible = true
	use_button.disabled = inventory.is_reserved(selected_id)

func _on_use() -> void:
	if not selected_id.is_empty():
		inventory.request_use(selected_id)
