class_name BunkerScrewInteraction
extends Node
## Right/up tightens; left/down unwinds. Item is consumed only at completion.
enum Phase { IDLE, FOCUSING, ROTATING, RETURNING }
signal finished(committed: bool)
@export var player: Node
@export var camera: Camera3D
@export_range(0.05, 2.0) var focus_seconds: float = 0.45
@export_range(0.001, 0.1) var radians_per_pixel: float = 0.012
var phase: Phase = Phase.IDLE
var angle: float = 0.0
var slot: BunkerFuseSlot
var item: BunkerItem
var _camera_before: Transform3D
var _fov_before: float
var _pivot_before: Transform3D
var _tween: Tween

func _exit_tree() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if phase != Phase.IDLE and phase != Phase.RETURNING and is_instance_valid(slot) and item != null:
		slot.cancel(item, player)

func is_active() -> bool:
	return phase != Phase.IDLE

func begin(target: BunkerFuseSlot, selected_item: BunkerItem) -> bool:
	if is_active() or target.screw_pivot == null or target.focus_marker == null:
		return false
	if not target.reserve(selected_item, player):
		return false
	slot = target
	item = selected_item
	angle = 0.0
	_camera_before = camera.global_transform
	_fov_before = camera.fov
	_pivot_before = slot.screw_pivot.transform
	player.call("set_screw_locked", true)
	var hud: Node = player.get("hud")
	hud.call("close_modal")
	hud.call("show_screw", true, 0.0)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	phase = Phase.FOCUSING
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(camera, "global_transform", slot.focus_marker.global_transform, focus_seconds)
	_tween.tween_property(camera, "fov", 62.0, focus_seconds)
	_tween.chain().tween_callback(func():
		if phase == Phase.FOCUSING:
			phase = Phase.ROTATING)
	return true

func handle_input(event: InputEvent) -> bool:
	if not is_active():
		return false
	if event.is_action_pressed("ui_cancel") and phase != Phase.RETURNING:
		finish(false)
		return true
	if phase == Phase.ROTATING and event is InputEventMouseMotion:
		apply_mouse_delta(event.screen_relative)
	return true

func apply_mouse_delta(delta: Vector2) -> void:
	if phase != Phase.ROTATING or not is_instance_valid(slot):
		return
	var total := slot.required_turns * TAU
	angle = clampf(angle + (delta.x - delta.y) * radians_per_pixel, 0.0, total)
	var pivot := _pivot_before
	pivot.basis = _pivot_before.basis * Basis(slot.local_rotation_axis.normalized(), angle)
	pivot.origin += slot.insertion_offset * (angle / total)
	slot.screw_pivot.transform = pivot
	var hud: Node = player.get("hud")
	hud.call("show_screw", true, angle / total)
	if angle >= total:
		finish(true)

func finish(commit: bool) -> void:
	if phase == Phase.IDLE or phase == Phase.RETURNING:
		return
	if _tween != null and _tween.is_valid():
		_tween.kill()
	var did_commit := false
	if is_instance_valid(slot):
		if commit:
			did_commit = slot.complete(item, player)
		if not did_commit:
			slot.screw_pivot.transform = _pivot_before
			slot.cancel(item, player)
			player.call("notify", "Installation cancelled. Fuse returned to inventory.")
	phase = Phase.RETURNING
	var hud: Node = player.get("hud")
	hud.call("show_screw", false, 0.0)
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(camera, "global_transform", _camera_before, focus_seconds)
	_tween.tween_property(camera, "fov", _fov_before, focus_seconds)
	_tween.chain().tween_callback(func():
		phase = Phase.IDLE
		player.call("set_screw_locked", false)
		slot = null
		item = null
		finished.emit(did_commit))
