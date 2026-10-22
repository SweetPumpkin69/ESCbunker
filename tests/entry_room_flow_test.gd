extends SceneTree
var scene: Node3D
var player: BunkerPlayer
var generator: BunkerGenerator
var report: Array[String] = []
var failures := 0
var artifact_directory: String = "user://puzzle_tests"

func _initialize() -> void:
	var arguments := OS.get_cmdline_user_args()
	var index := arguments.find("--artifacts")
	if index >= 0 and index + 1 < arguments.size():
		artifact_directory = arguments[index + 1]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(artifact_directory))
	call_deferred("run")

func check(condition: bool, text: String) -> void:
	report.append(("PASS " if condition else "FAIL ") + text)
	print(report[-1])
	if not condition:
		failures += 1

func settle(frames := 3) -> void:
	for i in frames:
		await physics_frame

func aim(origin: Vector3, point: Vector3) -> void:
	player.position = origin
	player.velocity = Vector3.ZERO
	player.rotation = Vector3.ZERO
	player.camera.rotation = Vector3.ZERO
	player.camera.look_at(point)

func screenshot(title: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	for i in 70:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(artifact_directory.path_join(title + ".png"))

func use_item(id: StringName) -> void:
	player.hud.toggle_inventory()
	var inventory_ui := player.hud.inventory_panel
	for i in inventory_ui.item_list.item_count:
		if inventory_ui.item_list.get_item_metadata(i) == id:
			inventory_ui.item_list.select(i)
			inventory_ui.item_list.item_selected.emit(i)
			inventory_ui.use_button.pressed.emit()
			return

func install(slot: BunkerFuseSlot, id: StringName, capture := false) -> void:
	if not player.hud.modal.is_empty():
		player.hud.close_modal()
	var approach := slot.global_position + slot.global_basis.z * 1.15
	approach.y = 0.05
	aim(approach, slot.global_position)
	await settle()
	use_item(id)
	check(player.screw.is_active(), "USE starts screw interaction for " + String(id))
	check(player.controls_locked(), "Movement locked during installation")
	await create_timer(player.screw.focus_seconds + 0.12).timeout
	check(player.camera.global_position.distance_to(slot.focus_marker.global_position) < 0.03, "Camera focuses on slot " + slot.slot_label)
	var event := InputEventMouseMotion.new()
	event.screen_relative = Vector2(125, 0)
	player.screw.handle_input(event)
	check(player.screw.angle > 0, "Horizontal mouse rotation advances screw")
	var previous := player.screw.angle
	event.screen_relative = Vector2(0, 30)
	player.screw.handle_input(event)
	check(player.screw.angle < previous, "Reverse movement loosens screw")
	if capture:
		await screenshot("puzzle_screwing")
	for i in 12:
		event.screen_relative = Vector2(0, -100)
		player.screw.handle_input(event)
	await create_timer(player.screw.focus_seconds + 0.1).timeout
	check(slot.is_installed and not player.inventory.has_item(id), "Completed fuse consumed exactly once: " + String(id))
	check(not player.controls_locked(), "Controls restored after installation")

func run() -> void:
	root.size = Vector2i(1440, 900)
	scene = load("res://scenes/entry_room_puzzle.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	player = scene.get_node("Player")
	generator = scene.get_node("Generator")
	await settle(12)
	check(InputMap.has_action("interact") and InputMap.action_get_events("interact")[0].physical_keycode == KEY_F, "interact is mapped to physical F")
	check(generator.state == BunkerGenerator.State.MISSING_COMPONENTS, "Initial generator state")
	var inventory_key := InputEventKey.new()
	inventory_key.keycode = KEY_TAB
	inventory_key.physical_keycode = KEY_TAB
	inventory_key.pressed = true
	Input.parse_input_event(inventory_key.duplicate())
	await process_frame
	await process_frame
	check(player.hud.modal == &"inventory" and player.controls_locked(), "Physical Tab input opens inventory and locks movement")
	inventory_key.pressed = false
	Input.parse_input_event(inventory_key.duplicate())
	var escape_key := InputEventKey.new()
	escape_key.keycode = KEY_ESCAPE
	escape_key.physical_keycode = KEY_ESCAPE
	escape_key.pressed = true
	Input.parse_input_event(escape_key.duplicate())
	await process_frame
	await process_frame
	check(player.hud.modal.is_empty() and not player.controls_locked(), "Escape input closes inventory and restores movement")
	escape_key.pressed = false
	Input.parse_input_event(escape_key.duplicate())
	check(not scene.get_node("Room/03_Collapsed_Breach/Earth_Shaft_CSG").visible, "Cylindrical shaft removed from playable scene")
	check(scene.has_node("Room/02_Architecture_CSG/Ceiling_Slab_EDIT_HOLE_CHILD/Jagged_Breach_SUBTRACTION"), "Editable jagged breach cutter present")
	check(not scene.get_node("Room/09_PreviewPlayer_REMOVE_FOR_MULTIPLAYER/PreviewOverlay").visible, "Old preview overlay disabled")
	var active_lights := 0
	for light in scene.find_children("*", "Light3D", true, false):
		if light.is_visible_in_tree():
			active_lights += 1
	check(active_lights == 1, "Only breach moonlight illuminates the initial room")
	var roof_ray := PhysicsRayQueryParameters3D.create(Vector3(-1.55, 2.0, 0.26), Vector3(-1.55, 8, 0.26), 1)
	roof_ray.exclude = [player.get_rid()]
	check(root.world_3d.direct_space_state.intersect_ray(roof_ray).is_empty(), "Jagged breach is a real open ceiling cut")
	await screenshot("entry_room_puzzle_preview")
	var panel: BunkerInteractable = scene.get_node("Room/04_Sealed_Bunker_Door/Unpowered_Access_Panel/PanelInteractable")
	aim(Vector3(2.66, 0.05, -2.65), panel.global_position)
	await settle()
	check(player.interactor.refresh_target() == panel, "Camera ray finds door panel")
	var f_event := InputEventKey.new()
	f_event.keycode = KEY_F
	f_event.physical_keycode = KEY_F
	f_event.pressed = true
	Input.parse_input_event(f_event.duplicate())
	await process_frame
	await process_frame
	f_event.pressed = false
	Input.parse_input_event(f_event.duplicate())
	check(player.hud.last_message == "No power.", "Dead panel feedback")
	var body: BunkerInteractable = generator.get_node("BodyInteractable")
	aim(Vector3(1.2, 0.05, 1.8), generator.global_position + Vector3(-0.5, 0.6, 0))
	await settle()
	body.interact(player)
	check(player.hud.last_message == "Missing components.", "Generator missing-components feedback")
	check(not generator.request_start(player), "Engine cannot start before fuses and fuel")
	var door: BunkerExitDoor = scene.get_node("ExitDoorController")
	door.open()
	check(not door.is_opening, "Door cannot be bypassed with a direct open call")
	var searches := [
		["Room/05_Storage_and_Utilities/West_Storage_Rack/SearchInteractable", Vector3(-2.55, 0.05, -1.5)],
		["Room/05_Storage_and_Utilities/North_Storage_Rack/SearchInteractable", Vector3(-2.75, 0.05, -1.95)],
		["Room/05_Storage_and_Utilities/East_Storage_Rack/SearchInteractable", Vector3(2.5, 0.05, -1.8)],
		["Room/05_Storage_and_Utilities/Timber_Crate_1/SearchInteractable", Vector3(3.55, 0.05, 2.9)]]
	for entry in searches:
		var area: BunkerInteractable = scene.get_node(entry[0])
		aim(entry[1], area.global_position)
		await settle()
		check(player.interactor.refresh_target() == area, "Camera ray reaches " + area.interaction_text)
		player.interactor.interact()
	check(player.inventory.get_items().size() == 4, "F searches collect four distinct fuses")
	scene.get_node(searches[0][0]).interact(player)
	check(player.inventory.get_items().size() == 4, "Searching again cannot duplicate loot")
	# USE from an unrelated place must keep the item and show the exact message.
	aim(Vector3(0, 0.05, 2.5), Vector3(0, 1.5, 3.8))
	await settle()
	use_item(&"fuse_square")
	check(player.hud.last_message == "This item cannot be used here.", "Wrong-location USE feedback")
	check(player.inventory.has_item(&"fuse_square"), "Wrong-location USE does not consume item")
	check(player.hud.inventory_panel.use_button.visible, "Clicking inventory item reveals USE")
	await screenshot("puzzle_inventory")
	player.hud.close_modal()
	# Decoys cannot fit either slot even while standing in the use area.
	var left := generator.left_slot
	var approach := left.global_position + left.global_basis.z * 1.05
	approach.y = 0.05
	aim(approach, left.global_position)
	await settle()
	use_item(&"fuse_star")
	check(not player.screw.is_active() and player.inventory.has_item(&"fuse_star"), "Star decoy rejected without consumption")
	player.hud.close_modal()
	# Begin, turn slightly, cancel: ownership, camera and inventory must all recover.
	player.camera.look_at(player.camera.global_position + Vector3(0, 0, 1))
	await settle()
	use_item(&"fuse_square")
	check(player.screw.is_active(), "USE also accepts standing in correct UseArea while looking away")
	await create_timer(player.screw.focus_seconds + 0.1).timeout
	player.screw.apply_mouse_delta(Vector2(120, 0))
	player.screw.finish(false)
	await create_timer(player.screw.focus_seconds + 0.1).timeout
	check(player.inventory.has_item(&"fuse_square") and not player.inventory.is_reserved(&"fuse_square"), "Cancel returns reserved fuse")
	check(not left.is_installed and not left.screw_pivot.visible and not player.controls_locked(), "Cancel restores slot and player")
	await install(left, &"fuse_square", true)
	check(generator.state == BunkerGenerator.State.MISSING_COMPONENTS, "One fuse cannot power generator")
	await install(generator.right_slot, &"fuse_triangle")
	check(generator.state == BunkerGenerator.State.POWERED_NO_FUEL, "Both fuses transition to powered/no fuel")
	check(generator.yellow_light.visible and not generator.green_light.visible, "Yellow indicator after both fuses")
	check(player.hud.last_message == "Generator has power, but no fuel.", "Exact fuel feedback")
	var clue: BunkerCluePaper = scene.get_node("FuelCodePaper")
	clue.interact(player, null)
	check(player.hud.clue_texture.texture.resource_path.ends_with("fuelcodepaper.jpeg"), "Clue popup uses existing JPEG")
	await screenshot("puzzle_fuel_code_clue")
	player.hud.close_modal()
	var fuel: BunkerFuelLock = scene.get_node("FuelTank_CSG/FuelValveAndLock")
	fuel.interact(player, fuel.interactable)
	check(player.hud.modal == &"lock", "Fuel valve opens 3-digit UI")
	check(not fuel.submit_code("123", player) and not fuel.is_unlocked, "Wrong code keeps fuel locked")
	player.hud.code_input.text = "532"
	player.hud.unlock_button.pressed.emit()
	check(fuel.is_unlocked and not fuel.padlock.freeze, "532 unlocks and drops padlock")
	check(generator.state == BunkerGenerator.State.SYSTEM_READY and generator.green_light.visible, "System ready/green state")
	check(player.hud.last_message == "System ready.", "Exact system-ready feedback")
	check(not generator.engine_audio.playing, "Fuel unlock does not auto-start engine")
	generator.start_interactable.interact(player)
	check(generator.state == BunkerGenerator.State.RUNNING and generator.engine_audio.playing, "F on start control runs looping engine audio")
	check(generator.powered_lights.all(func(light: Light3D): return light.visible), "Generator restores room and corridor lighting")
	panel.interact(player)
	check(door.is_opening and door.panel_light.visible, "Powered exit panel starts opening")
	await create_timer(door.opening_seconds + 0.2).timeout
	check(door.is_open and not door.is_opening, "Door finishes slow opening")
	# Ray through the exit after opening must not hit the moved steel plate.
	var query := PhysicsRayQueryParameters3D.create(Vector3(1.05, 1.5, -3.2), Vector3(1.05, 1.5, -4.7), 1)
	query.exclude = [player.get_rid()]
	check(root.world_3d.direct_space_state.intersect_ray(query).is_empty(), "Open door clears physical passage into corridor")
	aim(Vector3(3.2, 0.05, 3.0), Vector3(-0.3, 1.9, -1.8))
	await screenshot("entry_room_generator_running")
	check(player.inventory.get_items().size() == 2 and player.inventory.has_item(&"fuse_circle") and player.inventory.has_item(&"fuse_star"), "Only correct fuses consumed; decoys remain")
	report.append("Failures: " + str(failures))
	var file := FileAccess.open(artifact_directory.path_join("puzzle_validation.txt"), FileAccess.WRITE)
	file.store_string("\n".join(report))
	print("PUZZLE_TEST_FAILURES=", failures)
	quit(0 if failures == 0 else 1)
