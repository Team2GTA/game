extends Node

var storage_path := "user://settings.cfg"
var sensitivity := 0.2
var master_volume := 0.8
var camera_shake := true
var head_bob := true
var show_hud := true
var fov := 75.0
var best_score := 0
var default_bindings: Dictionary = {}
var config := ConfigFile.new()

func _ready() -> void:
	for action in InputMap.get_actions():
		default_bindings[action] = InputMap.action_get_events(action).duplicate(true)
	load_settings()

func load_settings() -> void:
	config = ConfigFile.new()
	config.load(storage_path)
	sensitivity = clampf(float(config.get_value("comfort", "sensitivity", 0.2)), 0.05, 0.6)
	master_volume = clampf(float(config.get_value("comfort", "volume", 0.8)), 0.0, 1.0)
	camera_shake = bool(config.get_value("comfort", "camera_shake", true))
	head_bob = bool(config.get_value("comfort", "head_bob", true))
	show_hud = bool(config.get_value("comfort", "show_hud", true))
	fov = clampf(float(config.get_value("comfort", "fov", 75.0)), 65.0, 95.0)
	best_score = maxi(int(config.get_value("records", "best_score", 0)), 0)
	apply_volume()
	for action in config.get_section_keys("bindings") if config.has_section("bindings") else []:
		if not InputMap.has_action(action):
			continue
		var events = config.get_value("bindings", action, [])
		if not events is Array or events.is_empty():
			continue
		var valid := true
		for event in events:
			if not event is InputEvent:
				valid = false
		if valid:
			InputMap.action_erase_events(action)
			for event in events:
				InputMap.action_add_event(action, event)

func apply_volume() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(master_volume, 0.0001)))
	AudioServer.set_bus_mute(0, master_volume <= 0.0)

func save() -> void:
	config.set_value("comfort", "sensitivity", sensitivity)
	config.set_value("comfort", "volume", master_volume)
	config.set_value("comfort", "camera_shake", camera_shake)
	config.set_value("comfort", "head_bob", head_bob)
	config.set_value("comfort", "show_hud", show_hud)
	config.set_value("comfort", "fov", fov)
	config.set_value("records", "best_score", best_score)
	var error := config.save(storage_path)
	if error != OK:
		push_warning("Could not save settings: " + error_string(error))

func save_binding(action: String) -> void:
	config.set_value("bindings", action, InputMap.action_get_events(action))
	save()

func record_score(value: int) -> void:
	if value > best_score:
		best_score = value
		save()

func reset_bindings() -> void:
	for action in default_bindings:
		InputMap.action_erase_events(action)
		for event in default_bindings[action]:
			InputMap.action_add_event(action, event)
	if config.has_section("bindings"):
		config.erase_section("bindings")
	save()

func binding_label(action: String) -> String:
	var events := InputMap.action_get_events(action)
	if events.is_empty():
		return "Unbound"
	var event = events[0]
	if event is InputEventKey:
		return OS.get_keycode_string(event.physical_keycode if event.physical_keycode != 0 else event.keycode)
	if event is InputEventMouseButton:
		return {1: "LMB", 2: "RMB", 3: "MMB"}.get(event.button_index, "Mouse " + str(event.button_index))
	return event.as_text()
