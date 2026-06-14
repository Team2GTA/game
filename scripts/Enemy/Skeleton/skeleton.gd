extends CharacterBody3D

var player = null
var inv
var spawning = true
var knockback = Vector3.ZERO
var flash_timer = false
var persistance = false
var enemy := Enemy.new("skeleton")
var health: float:
	get: return enemy.stats["health"]
	set(value): enemy.stats["health"] = value
var speed: float:
	get: return enemy.stats["speed"]
	set(value): enemy.stats["speed"] = value

signal skeleton_dead(pos)

@export var player_path: NodePath
@onready var nav_agent = $NavigationAgent3D
@onready var skeleton_sm: StateMachine = $StateMachine
@onready var floor_cast: RayCast3D = $CollisionShape3D/FloorCast
@onready var ray: RayCast3D = $RayCast3D

const KNOCKBACK_DECAY = 10.0
const KNOCKBACK_FORCE = 20.0
const SPAWN_TIME = 3.2
const ATTACK_RANGE = 2.2

func _ready():
	add_to_group("enemy")
	inv = 1
	if player_path:
		player = get_node(player_path)
	finish_spawn()

func _process(delta: float) -> void:
	if player == null:
		return
	if spawning:
		velocity = Vector3.ZERO
		return
	var locomotion = velocity
	velocity = locomotion + knockback
	knockback = knockback.lerp(Vector3.ZERO, KNOCKBACK_DECAY * delta)
	move_and_slide()
	velocity = locomotion

func finish_spawn() -> void:
	await get_tree().create_timer(SPAWN_TIME).timeout
	spawning = false

func in_range() -> bool:
	return global_position.distance_to(player.global_position) < ATTACK_RANGE

func smooth_look_at(target: Vector3, delta: float) -> void:
	var direction = (target - global_position)
	if direction.length() < 0.1:
		return
	var target_angle = atan2(-direction.x, -direction.z)
	rotation.y = lerp_angle(rotation.y, target_angle, 5.0 * delta)

func check_trap() -> void:
	var mat = floor_cast.get_material_properties()
	if mat and mat.is_in_group("traps") and inv:
		got_hit(mat.trap_damage)
		inv = 0
		mat.hit += 1
		await get_tree().create_timer(mat.timing).timeout
		inv = 1

func got_hit(dam: float, weapon: String = "gun") -> void:
	health -= dam
	flash_red()
	var direction = (global_position - player.global_position).normalized()
	knockback = direction * KNOCKBACK_FORCE if weapon == "axe" else Vector3.ZERO
	if health <= 0:
		die()

func die() -> void:
	var death_pos = global_position
	emit_signal("skeleton_dead", death_pos)
	call_deferred("queue_free")

func _on_area_3d_body_part_hit(dam: Variant, weapon: String = "gun") -> void:
	got_hit(dam, weapon)

func flash_red():
	if flash_timer:
		return
	flash_timer = true
	var meshes = get_meshes_recursive(self)
	for mesh in meshes:
		var mat = mesh.get_active_material(0)
		if mat:
			var new_mat = mat.duplicate()
			new_mat.albedo_color = Color(2, 0, 0)
			new_mat.emission_enabled = true
			new_mat.emission = Color(5, 0, 0)
			new_mat.emission_energy_multiplier = 3.0
			mesh.set_surface_override_material(0, new_mat)
	await get_tree().create_timer(0.1).timeout
	for mesh in meshes:
		mesh.set_surface_override_material(0, null)
	flash_timer = false

func get_meshes_recursive(node):
	var meshes = []
	for child in node.get_children():
		if child is MeshInstance3D:
			meshes.append(child)
		meshes += get_meshes_recursive(child)
	return meshes

func shoot():
	print("BANG")

func has_line_of_sight() -> bool:
	if player == null:
		return false
	ray.target_position = ray.to_local(player.global_position)
	ray.force_raycast_update()
	if ray.is_colliding():
		return ray.get_collider() == player
	return false
