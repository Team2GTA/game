extends CharacterBody3D

var bullet = load("res://scenes/bullet.tscn")
var bullet_instance
var max_health = 30
var health 
var score = 0
var zoomed = false
var target_fov = 75.0
var weapon = ""
var bob_time = 0.0
var cam_base_pos
var bob_enabled = true
var stamina = 50.0
var stamina_timer = 0.0
var regen_timer = 0.0
var accel
var decel

signal update_score
signal player_dead
signal shot
signal player_hit

@onready var floor_cast: RayCast3D = $FloorCast
@onready var gun_anim = $Camera3D/Rifle/AnimationPlayer
@onready var gun_cast = $Camera3D/Rifle/RayCast3D
@onready var axe_anim = $Camera3D/Axe/AnimationPlayer


func _ready():
	health = max_health
	weapon = "gun"
	score = 0
	accel=10.0
	decel=8.0
	cam_base_pos = %Camera3D.position

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotation_degrees.y -= event.relative.x * 0.2
		%Camera3D.rotation_degrees.x -= event.relative.y * 0.3
		%Camera3D.rotation_degrees.x = clamp(%Camera3D.rotation_degrees.x, -60.0, 80.0)
	
	if Input.is_action_just_pressed("1"):
		weapon = "gun"
	elif Input.is_action_just_pressed("2"):
		weapon = "axe"

	match weapon:
		"gun":
			if event.is_action_pressed("zoom") and !gun_anim.is_playing():
				zoomed = !zoomed
				target_fov = 30.0 if zoomed else 75.0
				if zoomed:
					gun_anim.play("zoom")
				else:
					gun_anim.play_backwards("zoom")
		"axe":
			pass

func _physics_process(delta):
	get_floor_properties()
	
	# stamina drain
	if Input.is_action_pressed("sprint") and stamina > 0:
		stamina_timer += delta
		if stamina_timer >= 1.0:
			stamina -= 2
			stamina_timer = 0.0
	
	# stamina regen
	if !Input.is_action_pressed("sprint"):
		regen_timer += delta
		if regen_timer >= 0.5:
			stamina = min(stamina + 2, 50)
			regen_timer = 0.0
	else:
		regen_timer = 0.0

	# speed
	var speed = 5.5
	if Input.is_action_pressed("sprint") and is_on_floor() and stamina > 0:
		speed = 10.0
	elif Input.is_action_pressed("sprint") and stamina > 0:
		speed = 7.0
	elif is_on_floor():
		speed = 5.5
	else:
		speed = 2.0

	# movement with inertia
	var input_direction_2d = Input.get_vector("left","right","up","down")
	var input_direction_3d = Vector3(input_direction_2d.x, 0.0, input_direction_2d.y)
	var direction = transform.basis * input_direction_3d

	if direction.length() > 0.1:
		velocity.x = lerp(velocity.x, direction.x * speed, accel * delta)
		velocity.z = lerp(velocity.z, direction.z * speed, accel * delta)
	else:
		velocity.x = lerp(velocity.x, 0.0, decel * delta)
		velocity.z = lerp(velocity.z, 0.0, decel * delta)

	# gravity and jumping
	velocity.y -= 35 * delta
	if Input.is_action_pressed("jump") and is_on_floor():
		velocity.y = 10
	elif Input.is_action_just_released("jump") and velocity.y > 0:
		velocity.y = 0

	# view bobbing
	var horizontal_velocity = Vector2(velocity.x, velocity.z).length()
	if is_on_floor() and horizontal_velocity > 0.1 and bob_enabled:
		var bob_speed = 10.0 if horizontal_velocity < 8.0 else 16.0
		var bob_amount = 0.075 if horizontal_velocity < 8.0 else 0.15
		bob_time += delta * bob_speed
		%Camera3D.position.y = cam_base_pos.y + sin(bob_time) * bob_amount
		%Camera3D.position.x = cam_base_pos.x + sin(bob_time * 0.5) * bob_amount
	else:
		bob_time = 0.0
		%Camera3D.position.y = lerp(%Camera3D.position.y, cam_base_pos.y, delta * 10.0)
		%Camera3D.position.x = lerp(%Camera3D.position.x, cam_base_pos.x, delta * 10.0)

	match weapon:
		"gun":
			%Rifle.visible = true
			$Camera3D/Axe.visible = false
			%Camera3D.fov = lerp(%Camera3D.fov, target_fov, 10.0 * delta)
			if Input.is_action_pressed("shoot"):
				if !gun_anim.is_playing():
					gun_anim.play("shoot_zoomed" if zoomed else "shoot")
					if %Rifle.capacity:
						bullet_instance = bullet.instantiate()
						emit_signal("shot")
						bullet_instance.position = gun_cast.global_position
						bullet_instance.transform.basis = gun_cast.global_transform.basis
						get_parent().add_child(bullet_instance)
		"axe":
			%Rifle.visible = false
			$Camera3D/Axe.visible = true
			%Camera3D.fov = lerp(%Camera3D.fov, 75.0, 10.0 * delta)
			if Input.is_action_just_pressed("shoot"):
				if !axe_anim.is_playing():
					axe_anim.play("swing")

	move_and_slide()

var current_room = null

func get_floor_properties():
	if floor_cast.is_colliding():
		var collider = floor_cast.get_collider()
		
		var x = null
		for j in collider.get_children():
			if j.is_in_group("rooms"):
				if x:
					x = j if position.distance_to(j.position) < position.distance_to(x.position) else x
				else:
					x = j
		
		if x == current_room:
			return  
		current_room = x
		
		var surface = "default"
		if x:
			if x.is_in_group("ice"):
				surface = "ice"
			elif x.is_in_group("mud"):
				surface = "mud"
			elif x.is_in_group("wood"):
				surface = "wood"
		
		match surface:
			"ice":
				accel = 2.0
				decel = 0.5
			"mud":
				accel = 4.0
				decel = 15.0
			"wood":
				accel = 8.0
				decel = 6.0
			_:
				accel = 10.0
				decel = 8.0


func _on_tp_body_entered(body: Node3D) -> void:
	if body.position.z < 0 and body == %Player:
		body.position.z = 101.795
	elif body.position.z > 0 and body == %Player:
		body.position.z = -131.505

func hit(dam):
	health -= dam
	emit_signal("player_hit")
	if health <= 0:
		die()

func points(point):
	score += point
	emit_signal("update_score")

func die():
	emit_signal("player_dead")
