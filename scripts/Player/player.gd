extends CharacterBody3D

const BULLET = preload("res://scenes/Weapons/bullet.tscn")
const TRAP = preload("res://scenes/Level/trap.tscn")

const MAX_STAMINA := 50.0
const WALK_SPEED := 5.5
const SPRINT_SPEED := 10.0
const AIR_SPEED := 2.0
const AIR_SPRINT_SPEED := 7.0
const GRAVITY := 35.0
const JUMP_FORCE := 10.0

enum Weapon {
	GUN,
	AXE
}

const STARTING_MAX_HEALTH := 30

var max_health: int = STARTING_MAX_HEALTH
var health: int
var score := 0

var weapon := Weapon.GUN

var zoomed := false
var target_fov := 75.0

var bob_time := 0.0
var bob_enabled := true
var cam_base_pos: Vector3

var stamina := MAX_STAMINA
var stamina_timer := 0.0
var regen_timer := 0.0

var accel := 10.0
var decel := 8.0

var invincible := false
var can_interact := true

signal update_score
signal player_dead
signal shot
signal player_hit

@onready var interact_ray: RayCast3D = $Camera3D/InteractRay
@onready var floor_cast: RayCast3D = $FloorCast
@onready var gun_anim = $Camera3D/Rifle/AnimationPlayer
@onready var gun_cast = $Camera3D/Rifle/RayCast3D
@onready var axe_anim = $Camera3D/Axe/AnimationPlayer


func _ready() -> void:
	health = max_health
	score = 0

	weapon = Weapon.GUN

	accel = 10.0
	decel = 8.0

	invincible = false

	cam_base_pos = %Camera3D.position

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotation_degrees.y -= event.relative.x * 0.2

		%Camera3D.rotation_degrees.x -= event.relative.y * 0.3
		%Camera3D.rotation_degrees.x = clamp(
			%Camera3D.rotation_degrees.x,
			-60.0,
			80.0
		)

	if Input.is_action_just_pressed("1"):
		weapon = Weapon.GUN

	elif Input.is_action_just_pressed("2"):
		weapon = Weapon.AXE

	if weapon == Weapon.GUN:
		if event.is_action_pressed("zoom") and !gun_anim.is_playing():
			zoomed = !zoomed
			target_fov = 30.0 if zoomed else 75.0

			if zoomed:
				gun_anim.play("zoom")
			else:
				gun_anim.play_backwards("zoom")

func _physics_process(delta):
	
	update_environment()

	if Input.is_action_just_pressed("interact"):
		throw()

	await update_traps()

	update_stamina(delta)

	# speed
	var speed := get_speed()

	# movement with inertia
	update_movement(delta, speed)

	# view bobbing
	update_camera(delta)

	update_weapon(delta)

	move_and_slide()
	push_rigid_bodies()

func _on_tp_body_entered(body: Node3D) -> void:
	if body != self:
		return

	body.position.z = 101.795 if body.position.z < 0 else -131.505

func get_interactable(node: Node) -> Interactable:
	if node is Interactable:
		return node
	if node.get_parent():
		return get_interactable(node.get_parent())
	return null

func update_camera(delta: float) -> void:
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()

	if is_on_floor() and horizontal_speed > 0.1 and bob_enabled:
		var bob_speed := 10.0 if horizontal_speed < 8.0 else 16.0
		var bob_amount := 0.075 if horizontal_speed < 8.0 else 0.15

		bob_time += delta * bob_speed

		%Camera3D.position.x = cam_base_pos.x + sin(bob_time * 0.5) * bob_amount
		%Camera3D.position.y = cam_base_pos.y + sin(bob_time) * bob_amount

	else:
		bob_time = 0.0

		%Camera3D.position.x = lerp(
			%Camera3D.position.x,
			cam_base_pos.x,
			10.0 * delta
		)

		%Camera3D.position.y = lerp(
			%Camera3D.position.y,
			cam_base_pos.y,
			10.0 * delta
		)

func update_movement(delta: float, speed: float) -> void:
	var input := Input.get_vector("left", "right", "up", "down")
	var direction := transform.basis * Vector3(input.x, 0, input.y)

	if direction.length() > 0.1:
		velocity.x = move_toward(
			velocity.x,
			direction.x * speed,
			accel * speed * delta
		)

		velocity.z = move_toward(
			velocity.z,
			direction.z * speed,
			accel * speed * delta
		)

	else:
		velocity.x = move_toward(
			velocity.x,
			0.0,
			decel * speed * delta
		)

		velocity.z = move_toward(
			velocity.z,
			0.0,
			decel * speed * delta
		)

	velocity.y -= GRAVITY * delta

	if Input.is_action_pressed("jump") and is_on_floor():
		velocity.y = JUMP_FORCE

	if Input.is_action_just_released("jump") and velocity.y > 0:
		velocity.y = 0

func get_speed() -> float:
	if Input.is_action_pressed("sprint") and stamina > 0:
		return SPRINT_SPEED if is_on_floor() else AIR_SPRINT_SPEED

	return WALK_SPEED if is_on_floor() else AIR_SPEED

func update_stamina(delta: float) -> void:
	var moving := Vector2(velocity.x, velocity.z).length() > 0.5
	var sprinting := Input.is_action_pressed("sprint") and moving

	if sprinting and stamina > 0:
		stamina_timer += delta
		regen_timer = 0.0

		if stamina_timer >= 1.0:
			stamina = max(stamina - 2, 0)
			stamina_timer = 0.0

	else:
		stamina_timer = 0.0
		regen_timer += delta

		if regen_timer >= 0.5:
			stamina = min(stamina + 2, MAX_STAMINA)
			regen_timer = 0.0

func update_weapon(delta: float) -> void:
	match weapon:
		Weapon.GUN:
			update_gun(delta)

		Weapon.AXE:
			update_axe(delta)

func update_gun(delta: float) -> void:
	%Rifle.visible = true
	$Camera3D/Axe.visible = false

	%Camera3D.fov = lerp(
		%Camera3D.fov,
		target_fov,
		10.0 * delta
	)

	if !Input.is_action_pressed("shoot"):
		return

	if gun_anim.is_playing():
		return

	gun_anim.play("shoot_zoomed" if zoomed else "shoot")

	if %Rifle.capacity <= 0:
		return

	var projectile := BULLET.instantiate()

	emit_signal("shot")

	projectile.position = gun_cast.global_position
	projectile.transform.basis = gun_cast.global_transform.basis

	get_parent().add_child(projectile)

func update_axe(delta: float) -> void:
	%Rifle.visible = false
	$Camera3D/Axe.visible = true

	%Camera3D.fov = lerp(
		%Camera3D.fov,
		75.0,
		10.0 * delta
	)

	if Input.is_action_just_pressed("shoot") and !axe_anim.is_playing():
		axe_anim.play("swing")

func throw():
	if interact_ray.is_colliding():
		var collider = interact_ray.get_collider()
		var interactable = get_interactable(collider)
		if interactable and interactable.is_in_group("traps"):
			interactable.interact(self)
			return
	
	if Inventory.trap_count() > 0:
		var trap_data: Dictionary = Inventory.remove_trap()
		var trap: Node3D = TRAP.instantiate()
		trap.trap_type = trap_data["trap_type"]
		trap.trap_damage = trap_data["trap_damage"]
		trap.timing = trap_data["timing"]
		trap.hit = trap_data["hit"]
		trap.max_hit = trap_data["max_hit"]
		get_parent().add_child(trap)
		
		if interact_ray.is_colliding():
			trap.global_position = interact_ray.get_collision_point()
		else:
			trap.global_position = interact_ray.global_position + interact_ray.global_transform.basis.z * -interact_ray.target_position.length()

func update_environment() -> void:
	$Camera3D/Overlay.visible = Inventory.get_value("overlay")

	floor_cast.get_floor_properties()

	match floor_cast.surface:
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

func update_traps() -> void:
	var trap = floor_cast.get_material_properties()

	if trap == null or invincible:
		return

	trap.hit += 1

	hit(trap.trap_damage)

	invincible = true
	await get_tree().create_timer(trap.timing).timeout
	invincible = false

func hit(damage: int) -> void:
	if invincible:
		return

	health = max(health - damage, 0)
	shake_camera(0.3)
	player_hit.emit()

	if health == 0:
		die()

func points(amount: int) -> void:
	score += amount
	update_score.emit()

func die() -> void:
	player_dead.emit()

	set_physics_process(false)
	set_process_input(false)

func shake_camera(intensity: float) -> void:
	var tween := create_tween()

	var offset := Vector3(
		randf_range(-intensity, intensity),
		randf_range(-intensity, intensity),
		0.0
	)

	%Camera3D.position += offset

	tween.tween_property(
		%Camera3D,
		"position",
		cam_base_pos,
		0.12
	)

func push_rigid_bodies():
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var body = collision.get_collider()

		if body.is_in_group("props"):
			var push_dir = Vector3(velocity.x, 0.0, velocity.z).normalized()

			if push_dir.length() > 0.0:
				body.apply_central_impulse(push_dir * 0.4)
