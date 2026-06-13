extends Control
@onready var main = $".."
var counting_down = false
var old_state
var hide
var controls_open = false

@onready var quit: Button = $Quit
@onready var score: Label = $Score
@onready var controls: Button = $Controls
@onready var restart: Button = $Restart
@onready var resume: Button = $Resume
@onready var black: ColorRect = $black
@onready var hp: Label = $HP
@onready var hp_2: ProgressBar = $HP2
@onready var hp_2_ghost: ProgressBar = $HP2_ghost
@onready var check_box_2: CheckBox = $CheckBox2
@onready var check_box: CheckBox = $CheckBox
@onready var bullets: Label = $Bullets
@onready var pixil_frame_0: Sprite2D = $PixilFrame0
@onready var stamina: Label = $Stamina
@onready var overlay: CheckBox = $Overlay


func _ready() -> void:
	$CheckBox.button_pressed = true
	%Player.bob_enabled = $CheckBox.button_pressed
	
	$CheckBox2.button_pressed = true
	hide = $CheckBox2.button_pressed

func  _process(delta: float) -> void:
	if Input.is_action_just_pressed("esc"):
		if controls_open:
			controls_open = false
			$".".visible = true
			$"../Controls".visible = false
			return
		if (main.state == "play" or main.state == "intermidiate"):
			old_state = main.state
			main.state = "paused" 
			overlay.visible = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			get_tree().paused = true
			quit.visible = true
			stamina.visible = false
			score.position = Vector2(820.0,283.333)
			controls.visible = true
			restart.visible = true
			resume.visible = true
			black.visible = true
			hp.visible = false
			hp_2.visible = false
			check_box_2.visible = true
			bullets.visible = false
			hp_2_ghost.visible = false
			pixil_frame_0.visible = false
			check_box.visible = true
		elif main.state == "paused":
			get_tree().paused = false
			main.state = "play"
			if old_state == "play":
				main.spawn_zombie()

func _on_restart_pressed() -> void:
	main.state = "start"
	Inventory.reset()
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


func _on_controls_pressed() -> void:
	controls_open = true
	$".".visible = false
	$"../Controls".visible = true
