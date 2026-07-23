extends CharacterBody3D
var player = null
var state_machine
var inv
var flash_timer = false
var persistance = false
var knockback = Vector3.ZERO
var spawning = true

var enemy := Enemy.new("zombie")
var health: float:
	get: return enemy.stats["health"]
	set(value): enemy.stats["health"] = value
var speed: float:
	get: return enemy.stats["speed"]
	set(value): enemy.stats["speed"] = value

const ATTACK_RANGE = 2.2
const KNOCKBACK_FORCE = 20.0
const KNOCKBACK_DECAY = 10.0
const SPAWN_TIME = 3.2

signal zombie_dead(pos)

@export var player_path : NodePath
@onready var nav_agent = $NavigationAgent3D
@onready var anim = $AnimationTree
@onready var floor_cast: RayCast3D = $CollisionShape3D/FloorCast
@onready var zombie_sm = $EnemyStateMachine

func _ready():
	add_to_group("enemy")
	inv = 1
	if player_path:
		player = get_node(player_path)
	finish_spawn()

func finish_spawn() -> void:
	await get_tree().create_timer(SPAWN_TIME).timeout
	spawning = false

func is_attacking() -> bool:
	var playback = anim["parameters/playback"]
	return playback and playback.get_current_node() == "attack"

func _physics_process(delta: float) -> void:
	if player == null:
		return

	if spawning:
		velocity = Vector3.ZERO
		return

	if is_attacking():
		velocity = Vector3.ZERO
		
	var locomotion = velocity
	velocity = locomotion + knockback
	knockback = knockback.lerp(Vector3.ZERO, KNOCKBACK_DECAY * delta)
	move_and_slide()
	velocity = locomotion

func check_trap() -> void:
	var mat = floor_cast.get_material_properties()
	if mat and mat.is_in_group("traps") and inv:
		got_hit(mat.trap_damage)
		inv = 0
		mat.hit += 1
		await get_tree().create_timer(mat.timing).timeout
		inv = 1

func smooth_look_at(target: Vector3, delta: float) -> void:
	var direction = (target - global_position)
	if direction.length() < 0.1:
		return
	var target_angle = atan2(-direction.x, -direction.z)
	rotation.y = lerp_angle(rotation.y, target_angle, 5.0 * delta)

func in_range() -> bool:
	return global_position.distance_to(player.global_position) < ATTACK_RANGE

func hit_finished():
	if in_range():
		player.hit(randi_range(3,7))

func _on_area_3d_body_part_hit(dam: Variant, weapon: String = "gun") -> void:
		got_hit(dam)
		var direction = (global_position - player.global_position).normalized()
		knockback = direction * KNOCKBACK_FORCE if weapon == "axe" else Vector3.ZERO

func got_hit(dam):
	if !anim["parameters/conditions/die"]:
		health -= dam
		flash_red()
		if health<=0:
			zombie_sm.transition("Die")

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
