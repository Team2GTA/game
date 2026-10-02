extends CharacterBody3D

const BULLET = preload("res://scenes/Weapons/bullet.tscn")
const TRAP = preload("res://scenes/Level/trap.tscn")

const MAX_STAMINA := 50.0
const WALK_SPEED := 5.5
const SPRINT_SPEED := 8.0
const AIR_SPEED := 2.0
const AIR_SPRINT_SPEED := 5.5
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
var exhausted := false
var jump_buffer := 0.0
var coyote_time := 0.0
var jump_consumed := false
var look_pitch := 0.0
var recoil := 0.0
var damage_shake := 0.0
var shake_time := 0.0
var dead := false
signal feedback(kind: String, message: String)

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
	look_pitch = %Camera3D.rotation.x
	$Camera3D/Axe.confirmed_hit.connect(func(): feedback.emit("hit", ""))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var sensitivity := Settings.sensitivity * (0.45 if zoomed else 1.0)
		rotation_degrees.y -= event.relative.x * sensitivity
		look_pitch = clampf(look_pitch - deg_to_rad(event.relative.y * sensitivity), deg_to_rad(-60), deg_to_rad(80))
	if event.is_action_pressed("jump") and not event.is_echo():
		jump_buffer = 0.1
	if event.is_action_pressed("1"):
		switch_weapon(Weapon.GUN)
	elif event.is_action_pressed("2"):
		switch_weapon(Weapon.AXE)
	if weapon == Weapon.GUN:
		if event.is_action_pressed("reload"):
			if %Rifle.start_reload():
				reset_zoom()
				feedback.emit("reload", "Reloading")
		if event.is_action_pressed("zoom") and not %Rifle.is_busy():
			zoomed = not zoomed
			if zoomed:
				gun_anim.play("zoom")
			else:
				gun_anim.play_backwards("zoom")

func switch_weapon(next_weapon: Weapon) -> bool:
	if next_weapon == weapon or %Rifle.is_busy() or $Camera3D/Axe.is_busy():
		return false
	reset_zoom()
	gun_anim.play("RESET")
	weapon = next_weapon
	return true

func reset_zoom() -> void:
	zoomed = false
	target_fov = Settings.fov

func _physics_process(delta):

	update_environment()

	if Input.is_action_just_pressed("interact"):
		throw()

	update_traps()

	update_stamina(delta)
	jump_buffer = maxf(jump_buffer - delta, 0.0)
	if is_on_floor() and velocity.y <= 0.0:
		coyote_time = 0.08
		jump_consumed = false
	else:
		coyote_time = maxf(coyote_time - delta, 0.0)

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
	# A cached raycast hit can outlive a collected or removed collider.
	while is_instance_valid(node):
		if node is Interactable:
			return node
		node = node.get_parent()
	return null

func update_camera(delta: float) -> void:
	var speed := Vector2(velocity.x, velocity.z).length()
	var bob := Vector3.ZERO
	if is_on_floor() and speed > 0.1 and bob_enabled:
		bob_time += delta * (12.0 if speed > WALK_SPEED else 8.0)
		var amount := 0.045 if speed > WALK_SPEED else 0.025
		bob = Vector3(sin(bob_time * 0.5), sin(bob_time), 0) * amount
	else:
		bob_time = 0.0
	recoil = move_toward(recoil, 0.0, delta * 0.09)
	damage_shake = move_toward(damage_shake, 0.0, delta * 0.35)
	shake_time += delta
	var shake := Vector3(sin(shake_time * 95), cos(shake_time * 83), 0) * damage_shake if Settings.camera_shake else Vector3.ZERO
	%Camera3D.position = cam_base_pos + bob + shake
	%Camera3D.rotation.x = look_pitch + (recoil if Settings.camera_shake else 0.0)
	target_fov = 30.0 if zoomed else Settings.fov
	%Camera3D.fov = lerpf(%Camera3D.fov, target_fov, 1.0 - exp(-10.0 * delta))

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

	try_buffered_jump()

	if Input.is_action_just_released("jump") and velocity.y > 0:
		velocity.y = 0

func try_buffered_jump() -> bool:
	if jump_buffer <= 0.0 or coyote_time <= 0.0 or jump_consumed:
		return false
	jump_buffer = 0.0
	if stamina < 8.0:
		feedback.emit("stamina", "Not enough stamina to jump")
		return false
	stamina -= 8.0
	regen_timer = 0.0
	velocity.y = JUMP_FORCE
	coyote_time = 0.0
	jump_consumed = true
	return true

func get_speed() -> float:
	if Input.is_action_pressed("sprint") and stamina > 0 and not exhausted:
		return SPRINT_SPEED if is_on_floor() else AIR_SPRINT_SPEED
	return WALK_SPEED if is_on_floor() else AIR_SPEED

func update_stamina(delta: float) -> void:
	var moving := Vector2(velocity.x, velocity.z).length() > 0.5 and Input.get_vector("left", "right", "up", "down").length() > 0.1
	var sprinting := Input.is_action_pressed("sprint") and moving and not exhausted and stamina > 0.0
	if sprinting:
		stamina = maxf(stamina - 12.0 * delta, 0.0)
		regen_timer = 0.0
		if stamina <= 0.0:
			exhausted = true
			feedback.emit("stamina", "Exhausted - catch your breath")
	else:
		var previous := regen_timer
		regen_timer += delta
		var regen_delta := maxf(regen_timer - 1.25, 0.0) - maxf(previous - 1.25, 0.0)
		stamina = minf(stamina + 9.0 * regen_delta, MAX_STAMINA)
		if exhausted and stamina >= 15.0:
			exhausted = false

func update_weapon(delta: float) -> void:
	match weapon:
		Weapon.GUN:
			update_gun(delta)

		Weapon.AXE:
			update_axe(delta)

func update_gun(_delta: float) -> void:
	%Rifle.visible = true
	$Camera3D/Axe.visible = false
	if not Input.is_action_pressed("shoot"):
		return
	if %Rifle.capacity <= 0 and not %Rifle.is_busy():
		if Input.is_action_just_pressed("shoot"):
			feedback.emit("empty", "Empty magazine - " + Settings.binding_label("reload") + " to reload")
		return
	if not %Rifle.try_fire(zoomed):
		return
	var projectile := BULLET.instantiate()
	projectile.confirmed_hit.connect(func(): feedback.emit("hit", ""))
	get_parent().add_child(projectile)
	projectile.global_transform = gun_cast.global_transform
	shot.emit()
	if Settings.camera_shake:
		recoil = minf(recoil + 0.012, 0.024)

func update_axe(_delta: float) -> void:
	%Rifle.visible = false
	$Camera3D/Axe.visible = true
	if Input.is_action_just_pressed("shoot"):
		$Camera3D/Axe.start_swing()

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
	await get_tree().create_timer(trap.timing, false).timeout
	invincible = false

func hit(damage: int) -> void:
	if invincible or dead:
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
	if dead:
		return
	dead = true
	player_dead.emit()

	set_physics_process(false)
	set_process_input(false)
	set_process_unhandled_input(false)

func shake_camera(intensity: float) -> void:
	if Settings.camera_shake:
		damage_shake = minf(maxf(damage_shake, intensity * 0.2), 0.08)

func push_rigid_bodies():
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var body = collision.get_collider()

		if body.is_in_group("props"):
			var push_dir = Vector3(velocity.x, 0.0, velocity.z).normalized()

			if push_dir.length() > 0.0:
				body.apply_central_impulse(push_dir * 0.4)
