extends Node
@onready var main = get_parent()
@onready var ui = main.get_node("UI")
@onready var player = main.get_node("Player")
var previous_state := ""

func tick() -> void:
	if main.state != previous_state:
		previous_state = main.state
		enter_state(main.state)
	if main.state in ["play", "intermidiate"]:
		ui.update_hud()
	if main.state == "play":
		main.level_handle()
		main.wave_handle()

func enter_state(state: String) -> void:
	var playing := state in ["play", "intermidiate"]
	player.set_physics_process(playing)
	player.set_process_unhandled_input(playing)
	player.get_node("Camera3D/InteractRay/Prompt").hide()
	if state == "play":
		main.highest_level = main.level
		main.highest_wave = main.wave
	ui.show_state(state)
	var menu := state in ["start", "paused", "dead", "win"]
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if menu else Input.MOUSE_MODE_CAPTURED
	if state == "level_transition":
		ui.announcement.text = "LEVEL 1 COMPLETE\nDeeper into the dungeon"
		ui.announcement.show()
	get_tree().paused = menu
