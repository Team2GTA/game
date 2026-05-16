extends CharacterBody3D
@export var rate = 0.4

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED      #Locks the mouse

func _unhandled_input(event):
	#Camera movement using mouse
	if event is InputEventMouseMotion:
		rotation_degrees.y -= event.relative.x*0.2
		%Camera3D.rotation_degrees.x -= event.relative.y*0.3
		%Camera3D.rotation_degrees.x = clamp(
			%Camera3D.rotation_degrees.x , -60.0, 80.0
		)
	elif event.is_action_pressed("esc"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE      #Unlocks the mouse

func _physics_process(delta):
	#Sprint set-up
	var speed = 5.5
	if Input.is_action_pressed("sprint"):
		speed = 10
	else: speed = 5.5
	
	#Movement of player
	var input_direction_2d = Input.get_vector(
		"left","right","up","down"
	)
	var input_direction_3d = Vector3(
		input_direction_2d.x,0.0,input_direction_2d.y
	)
	var direction = transform.basis * input_direction_3d
	velocity.x = direction.x*speed
	velocity.z = direction.z*speed
	
	#Gravity and jumping
	velocity.y -=35*delta
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = 10
	elif Input.is_action_just_released("jump") and velocity.y >0:
		velocity.y = 0
	move_and_slide()
	
	#Trigger for shooting
	if Input.is_action_pressed("shoot") and %Timer.is_stopped():
		shoot_bullet()



func shoot_bullet():
	const BULLET = preload("res://scenes/bullet.tscn") 
	var new_bullet = 	BULLET.instantiate()
	%Marker3D.add_child(new_bullet)
	
	new_bullet.global_transform = %Marker3D.global_transform
	%Timer.wait_time = rate
	%Timer.start()

func _on_tp_1_body_entered(body: Node3D) -> void:
	if body.position.z < 0 and body == %Player:
		body.position.z = 101.795
	elif body.position.z > 0 and body == %Player:
		body.position.z = -131.505


func _on_tp_body_entered(body: Node3D) -> void:
	if body.position.z < 0 and body == %Player:
		body.position.z = 101.795
	elif body.position.z > 0 and body == %Player:
		body.position.z = -131.505
