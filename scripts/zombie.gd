extends CharacterBody3D
var player = null
var state_machine
var health = 15
var speed = 2
var inv
var flash_timer = false
var persistance = false
var knockback = Vector3.ZERO
const ATTACK_RANGE = 2.2
const KNOCKBACK_FORCE = 20.0
const KNOCKBACK_DECAY = 10.0
signal zombie_dead(pos)
@export var player_path : NodePath
@onready var nav_agent = $NavigationAgent3D
@onready var anim = $AnimationTree

func _ready():
	add_to_group("enemy")
	inv = 1
	if player_path:
		player = get_node(player_path)
	state_machine = anim.get("parameters/playback")

func _process(delta: float) -> void:
	if player == null:
		return
	
	velocity = Vector3.ZERO
	
	match state_machine.get_current_node():
		"run":
			nav_agent.set_target_position(player.global_transform.origin)
			var next_nav_point = nav_agent.get_next_path_position()
			velocity = (next_nav_point - global_transform.origin).normalized() * speed
			smooth_look_at(Vector3(global_position.x + velocity.x, global_position.y, global_position.z + velocity.z), delta)
		"attack":
			smooth_look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), delta)
	
	# apply knockback
	velocity += knockback
	knockback = knockback.lerp(Vector3.ZERO, KNOCKBACK_DECAY * delta)
	
	anim["parameters/conditions/attack"] = in_range()
	anim["parameters/conditions/run"] = !in_range()
	
	move_and_slide()

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
	health -= dam
	flash_red()
	var direction = (global_position - player.global_position).normalized()
	knockback = direction * KNOCKBACK_FORCE if weapon == "axe" else Vector3.ZERO
	if health <= 0:
		var death_pos = global_position
		call_deferred("queue_free")
		emit_signal("zombie_dead", death_pos)

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
