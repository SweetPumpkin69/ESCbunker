class_name BunkerCluePaper
extends Node3D
@export var paper_texture: Texture2D

func interact(player: Node, _component: BunkerInteractable) -> void:
	var hud: Node = player.get("hud")
	hud.call("open_clue", paper_texture)
