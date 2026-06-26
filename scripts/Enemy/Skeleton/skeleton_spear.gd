extends RigidBody3D

const SPEED = 35.0
const STICK_LIFETIME = 4.0
const MAX_FLIGHT = 6.0
const FADE_TIME = 0.6
const AIM_HEIGHT = 1.2

var damage := 1.5
var landed := false
var age := 0.0

func launch(from: Vector3, target: Vector3, dam: float, shooter: Node) -> void:
	damage = dam
	# Spear should only interact with the player and the level, never enemies
	# (including the shooter). Pass through everything in the "enemy" group.
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy is CollisionObject3D:
			add_collision_exception_with(enemy)
	global_position = from
	var aim = (target + Vector3(0, AIM_HEIGHT, 0)) - from
	if aim.length() > 0.01:
		global_transform.basis = Basis.looking_at(aim, Vector3.UP)
	linear_velocity = aim.normalized() * SPEED

func _process(delta: float) -> void:
	# Despawn spears that never hit anything so they don't accumulate.
	if landed:
		return
	age += delta
	if age >= MAX_FLIGHT:
		landed = true
		fade_and_free()

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if landed:
		return
	var v = state.linear_velocity
	if v.length() > 0.5:
		var t = state.transform
		t.basis = Basis.looking_at(v, Vector3.UP)
		state.transform = t

func _on_body_entered(body: Node) -> void:
	if landed:
		return
	if body.is_in_group("player"):
		body.hit(damage)
		queue_free()
		return

	# Ignore enemies that appeared after launch (not covered by the exceptions
	# set up in launch()); keep flying so the spear only sticks to the level.
	if body.is_in_group("enemy"):
		add_collision_exception_with(body)
		return

	landed = true
	freeze = true
	await get_tree().create_timer(STICK_LIFETIME).timeout
	fade_and_free()

func fade_and_free() -> void:
	var tween = create_tween().set_parallel(true)
	for mesh in [$Shaft, $Tip]:
		tween.tween_property(mesh, "transparency", 1.0, FADE_TIME)
	await tween.finished
	queue_free()
