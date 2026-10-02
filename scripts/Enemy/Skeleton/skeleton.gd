extends CharacterBody3D

signal combat_feedback(kind: String, message: String)
var player = null
var inv
var spawning = true
var dead := false
var knockback = Vector3.ZERO
var flash_timer = false
var flash_surfaces: Array[Dictionary] = []
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
@onready var muzzle: Marker3D = $Muzzle

const SPEAR = preload("res://scenes/Enemy/Skeleton/skeleton_spear.tscn")
const KNOCKBACK_DECAY = 10.0
const KNOCKBACK_FORCE = 20.0
const SPAWN_TIME = 3.2
const ATTACK_RANGE = 2.2

func _ready():
	cache_flash_materials()
	add_to_group("enemy")
	inv = 1
	if player == null:
		if player_path:
			player = get_node(player_path)
		else:
			player = get_tree().get_first_node_in_group("player")
	finish_spawn()

func _physics_process(delta: float) -> void:
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
	await get_tree().create_timer(SPAWN_TIME, false).timeout
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
		await get_tree().create_timer(mat.timing, false).timeout
		inv = 1

func got_hit(dam: float, weapon: String = "gun") -> void:
	if dead:
		return
	health -= dam
	flash_red()
	var direction = (global_position - player.global_position).normalized()
	knockback = direction * KNOCKBACK_FORCE if weapon == "axe" else Vector3.ZERO
	if health <= 0:
		die()

func die() -> void:
	if dead:
		return
	dead = true
	combat_feedback.emit("kill", "")
	var death_pos = global_position
	emit_signal("skeleton_dead", death_pos)
	call_deferred("queue_free")

func _on_area_3d_body_part_hit(dam: Variant, weapon: String = "gun") -> void:
	got_hit(dam, weapon)

func cache_flash_materials() -> void:
	for mesh in get_meshes_recursive(self):
		for surface in range(mesh.mesh.get_surface_count()):
			var material = mesh.get_active_material(surface)
			if material is BaseMaterial3D:
				var flash = material.duplicate()
				flash.albedo_color = Color(1, 0.15, 0.15)
				flash.emission_enabled = true
				flash.emission = Color(1, 0, 0)
				flash_surfaces.append({"mesh": mesh, "surface": surface,
					"original": mesh.get_surface_override_material(surface), "flash": flash})

func flash_red():
	if flash_timer:
		return
	flash_timer = true
	for entry in flash_surfaces:
		entry.mesh.set_surface_override_material(entry.surface, entry.flash)
	await get_tree().create_timer(0.1, false).timeout
	for entry in flash_surfaces:
		if is_instance_valid(entry.mesh):
			entry.mesh.set_surface_override_material(entry.surface, entry.original)
	flash_timer = false

func get_meshes_recursive(node):
	var meshes = []
	for child in node.get_children():
		if child is MeshInstance3D:
			meshes.append(child)
		meshes += get_meshes_recursive(child)
	return meshes

func shoot():
	if player == null:
		return
	var spear = SPEAR.instantiate()
	get_parent().add_child(spear)
	spear.launch(muzzle.global_position, player.global_position, enemy.stats["attack"], self)

func has_line_of_sight() -> bool:
	if player == null:
		return false
	ray.target_position = ray.to_local(player.global_position)
	ray.force_raycast_update()
	if ray.is_colliding():
		return ray.get_collider() == player
	return false
