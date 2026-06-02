extends Control
@onready var main = $".."
var counting_down = false
var old_state
var hide

func _ready() -> void:
	$CheckBox.button_pressed = true
	%Player.bob_enabled = $CheckBox.button_pressed
	
	$CheckBox2.button_pressed = true
	hide = $CheckBox2.button_pressed

func  _process(delta: float) -> void:
	if Input.is_action_just_pressed("esc"):
		if main.state == "play" or main.state == "intermidiate":
			old_state = main.state
			main.state = "paused" 
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			get_tree().paused = true
			$Quit.visible = true
			$Score.position = Vector2(820.0,283.333)
			$Controls.visible = true
			$Restart.visible = true
			$Resume.visible = true
			$black.visible = true
			$HP.visible = false
			$HP2.visible = false
			$CheckBox2.visible = true
			$Bullets.visible = false
			$HP2_ghost.visible = false
			$PixilFrame0.visible = false
			$CheckBox.visible = true
		elif main.state == "paused":
			get_tree().paused = false
			main.state = "play"
			if old_state == "play":
				main.spawn_zombie()

func _on_restart_pressed() -> void:
	main.state = "start"
	main.get_tree().paused = false
	get_tree().reload_current_scene()

func _on_resume_pressed() -> void:
	get_tree().paused = false
	main.state = "play"

func countdown() -> void:
	$Label.visible = true
	for i in range(3, 0, -1):
		$Label.text = str(i)
		await get_tree().create_timer(1.0).timeout
	$Label.text = "WAVE "+str(main.wave)
	await get_tree().create_timer(1.0).timeout
	$Label.visible = false
	counting_down = false


func _on_start_pressed() -> void:
	main.state = "play"
	main.get_tree().paused = false
	main.spawn_zombie()
	#main.spawn_pickup()


func _on_check_box_toggled(toggled_on: bool) -> void:
	%Player.bob_enabled = toggled_on

func start_countdown():
	if counting_down:
		return
	counting_down = true
	countdown()


func _on_check_box_2_toggled(toggled_on: bool) -> void:
	hide = toggled_on


func _on_quit_pressed() -> void:
	get_tree().quit()
