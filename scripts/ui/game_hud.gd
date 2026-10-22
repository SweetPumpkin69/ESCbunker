class_name BunkerHUD
extends CanvasLayer
signal modal_changed(open: bool)
@export var inventory_panel: BunkerInventoryUI
@export var modal_backdrop: Control
@export var lock_panel: Control
@export var code_input: LineEdit
@export var unlock_button: Button
@export var lock_close: Button
@export var clue_panel: Control
@export var clue_texture: TextureRect
@export var clue_close: Button
@export var screw_panel: Control
@export var screw_progress: ProgressBar
@export var message_label: Label
@export var message_timer: Timer
@export var prompt_label: Label
@export var objective_label: Label
var modal: StringName = &""
var active_lock: BunkerFuelLock
var last_message: String = ""

func _ready() -> void:
	inventory_panel.close_requested.connect(close_modal)
	lock_close.pressed.connect(close_modal)
	clue_close.pressed.connect(close_modal)
	unlock_button.pressed.connect(_submit_code)
	code_input.text_submitted.connect(func(_text: String): _submit_code())
	code_input.text_changed.connect(_filter_digits)
	message_timer.timeout.connect(func(): message_label.hide())
	_hide_modals()
	screw_panel.hide()
	message_label.hide()

func _hide_modals() -> void:
	inventory_panel.hide()
	lock_panel.hide()
	clue_panel.hide()
	modal_backdrop.hide()

func _show_modal(kind: StringName) -> void:
	_hide_modals()
	modal = kind
	modal_backdrop.show()
	match kind:
		&"inventory": inventory_panel.show()
		&"lock": lock_panel.show()
		&"clue": clue_panel.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	modal_changed.emit(true)

func toggle_inventory() -> void:
	if modal == &"inventory":
		close_modal()
	elif modal.is_empty():
		inventory_panel.refresh()
		_show_modal(&"inventory")

func close_modal() -> void:
	_hide_modals()
	modal = &""
	active_lock = null
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	modal_changed.emit(false)

func open_lock(target: BunkerFuelLock) -> void:
	active_lock = target
	_show_modal(&"lock")
	code_input.text = ""
	code_input.grab_focus()

func _filter_digits(text: String) -> void:
	var clean := ""
	for digit in text:
		if digit >= "0" and digit <= "9":
			clean += digit
	if clean != text:
		code_input.text = clean.left(3)
		code_input.caret_column = code_input.text.length()

func _submit_code() -> void:
	if active_lock != null and active_lock.submit_code(code_input.text, get_parent()):
		close_modal()
	else:
		code_input.select_all()
		code_input.grab_focus()

func open_clue(texture: Texture2D) -> void:
	clue_texture.texture = texture
	message_label.hide()
	_show_modal(&"clue")

func show_screw(show: bool, progress: float) -> void:
	screw_panel.visible = show
	screw_progress.value = progress * 100.0
	if show:
		message_label.hide()

func show_message(text: String) -> void:
	last_message = text
	message_label.text = text
	message_label.show()
	message_timer.start(4.5)

func set_prompt(target: BunkerInteractable) -> void:
	prompt_label.text = "[ F ]   " + target.interaction_text if target != null else ""
