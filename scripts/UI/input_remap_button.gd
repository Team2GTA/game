extends Button
class_name InputRemapButton

@export var action: String
@export var action_event_index: int = 0

func _input(event: InputEvent) -> void:
	if not button_pressed or not InputMap.has_action(action):
		return
	if not event.is_pressed() or event.is_echo():
		return
	if event is InputEventKey and event.keycode == KEY_ESCAPE:
		finish_remap()
		get_viewport().set_input_as_handled()
		return
	if not (event is InputEventKey or event is InputEventMouseButton):
		return
	var events := InputMap.action_get_events(action)
	if action_event_index < events.size():
		events[action_event_index] = event
	else:
		events.append(event)
		action_event_index = events.size() - 1
	InputMap.action_erase_events(action)
	for binding in events:
		InputMap.action_add_event(action, binding)
	Settings.save_binding(action)
	finish_remap()
	get_viewport().set_input_as_handled()

func finish_remap() -> void:
	button_pressed = false
	release_focus()
	_on_toggled(false)

func _ready() -> void:
	add_theme_font_size_override("font_size", 48)
	toggle_mode = true
	add_to_group("remap_buttons")
	toggled.connect(_on_toggled)
	_on_toggled(false)

func _on_toggled(toggled_on: bool) -> void:
	if not InputMap.has_action(action):
		return
	if toggled_on:
		for button in get_tree().get_nodes_in_group("remap_buttons"):
			if button != self and button.button_pressed:
				button.finish_remap()
		text = "Press key / mouse (Esc cancels)"
		return
	var events := InputMap.action_get_events(action)
	if action_event_index >= events.size():
		text = "Unassigned"
		return
	var binding = events[action_event_index]
	if binding is InputEventKey:
		text = OS.get_keycode_string(binding.physical_keycode if binding.physical_keycode != 0 else binding.keycode)
	else:
		text = binding.as_text()
