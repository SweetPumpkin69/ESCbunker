class_name BunkerItem
extends Resource
## Data only: assign this resource to a searchable container and a matching slot.
@export var id: StringName
@export var display_name: String = "Item"
@export_multiline var description: String
@export var symbol: String = ""
@export var color: Color = Color(0.75, 0.8, 0.75)
@export var icon: Texture2D
