extends Node3D
## Scene wiring only. Geometry and UI are saved, editable scene nodes.
@export var generator: BunkerGenerator
@export var exit_door: BunkerExitDoor
@export var player: BunkerPlayer

func _ready() -> void:
	generator.state_changed.connect(_update_objective)
	exit_door.opened.connect(func(): player.hud.objective_label.text = "ENTER THE BUNKER")
	_update_objective(generator.state)

func _update_objective(state: int) -> void:
	match state:
		BunkerGenerator.State.MISSING_COMPONENTS: player.hud.objective_label.text = "RESTORE POWER TO THE EXIT"
		BunkerGenerator.State.POWERED_NO_FUEL: player.hud.objective_label.text = "RESTORE THE FUEL SUPPLY"
		BunkerGenerator.State.SYSTEM_READY: player.hud.objective_label.text = "START THE GENERATOR"
		BunkerGenerator.State.RUNNING: player.hud.objective_label.text = "RETURN TO THE EXIT PANEL"
