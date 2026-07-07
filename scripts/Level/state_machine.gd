extends Node

@onready var main = get_parent()
@onready var ui = main.get_node("UI")
@onready var player = main.get_node("Player")
@onready var rifle = main.get_node("Player/Camera3D/Rifle")

var _handlers := {}

func _ready() -> void:
	_handlers = {
		"start":_state_start,
		"play":_state_play,
		"dead":_state_dead,
		"win":_state_win,
		"intermidiate": _state_intermidiate,
	}

func tick() -> void:
	if _handlers.has(main.state):
		_handlers[main.state].call()

func _state_start() -> void:
	ui.get_node("CheckBox2").visible = true
	main.hp_bar.visible = false
	main.bullets.visible = false
	ui.get_node("CheckBox").visible = true
	main.hp_ghost.visible = false
	main.hp.visible = false
	main.score_bar.visible = false
	main.restart.visible = false
	main.resume.visible = false
	ui.get_node("Panel").visible = true
	ui.get_node("Panel/VBoxContainer/Quit").visible = true
	ui.get_node("PixilFrame0").visible = false
	ui.get_node("Panel/Controls").visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true

func _state_play() -> void:
	ui.get_node("Stamina").visible = true
	ui.get_node("Overlay").visible = false
	main.get_node("Controls").visible = false
	ui.get_node("Stamina").text = "STAMINA\n"+str(player.stamina)
	ui.get_node("CheckBox2").visible = false
	ui.get_node("CheckBox").visible = false
	ui.get_node("Controls").visible = false
	ui.get_node("Panel/VBoxContainer/Quit").visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	main.hp_bar.visible = ui.hide
	main.hp_ghost.visible = ui.hide
	main.hp.visible = ui.hide
	main.score_bar.visible = true
	main.bullets.visible = true
	main.restart.visible = false
	main.resume.visible = false
	ui.get_node("Panel").visible = false
	ui.get_node("Panel/VBoxContainer/Start").visible = false
	ui.get_node("PixilFrame0").visible = ui.hide
	if rifle.reloading:
		main.bullets.text = "Reloading...."
	else:
		main.bullets.text = str(rifle.capacity) +"/"+str(Inventory.get_ammo("rifle"))+ " BULLETS"
	main.score_bar.position = Vector2(0,0)
	main.update_health()
	main.level_handle()
	main.wave_handle()

func _state_dead() -> void:
	ui.get_node("Panel").visible = true
	ui.get_node("Panel/VBoxContainer/Quit").visible = true
	ui.get_node("CheckBox2").visible = true
	main.hp_bar.visible = false
	main.bullets.visible = false
	main.hp_ghost.visible = false
	main.hp.visible = false
	main.score_bar.position =Vector2(800,100)
	main.restart.visible = true
	ui.get_node("PixilFrame0").visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true

func _state_win() -> void:
	ui.get_node("Panel").visible = true
	ui.get_node("Panel/VBoxContainer/Quit").visible = true
	ui.get_node("CheckBox2").visible = true
	main.hp_bar.visible = false
	main.bullets.visible = false
	main.hp_ghost.visible = false
	main.hp.visible = false
	ui.get_node("PixilFrame0").visible = false
	main.score_bar.position = Vector2(800,100)
	main.score_bar.text = "YOU WIN"
	main.restart.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true

func _state_intermidiate() -> void:
	main.update_health()
	ui.get_node("Stamina").text = "STAMINA\n"+str(player.stamina)
	if rifle.reloading:
		main.bullets.text = "Reloading...."
	else:
		main.bullets.text = str(rifle.capacity) +"/"+str(Inventory.get_ammo("rifle"))+ " BULLETS"
