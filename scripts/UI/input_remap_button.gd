extends Button
class_name InputRemapButton

@export var action: String
@export var action_event_index: int = 0

func _unhandled_input(event: InputEvent) -> void:
	if !InputMap.has_action(action) or !is_pressed():
		return
		
	if event.is_pressed() and (event is InputEventKey):
		var action_events_list = InputMap.action_get_events(action)
		if action_event_index<action_events_list.size():
			InputMap.action_erase_event(action,action_events_list[action_event_index])
		
		InputMap.action_add_event(action, event)
		action_event_index = InputMap.action_get_events(action).size()-1
		button_pressed = false
		release_focus()
		_on_toggled(false)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		button_pressed = false
		release_focus()

func _ready() -> void:
	add_theme_font_size_override("font_size",48)
	toggle_mode = true
	toggled.connect(_on_toggled)
	_on_toggled(false)

func _on_toggled(toggled_on: bool) -> void:
	if !action or !InputMap.has_action(action):
		return
	if toggled_on:
		text = "Awaiting Input"
		return
	
	if action_event_index>=InputMap.action_get_events(action).size():
		text = "Unassigned"
		return
		
	var input = InputMap.action_get_events(action)[action_event_index]
	if InputEventKey:
		if input.physical_keycode !=0:
			text = OS.get_keycode_string(input.physical_keycode)
		else:
			text = OS.get_keycode_string(input.keycode)
