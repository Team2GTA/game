extends Node3D

signal confirmed_hit

const SPEED = 40.0
var impacted := false
var exclusions: Array[RID] = []

func _ready() -> void:
	for body in get_tree().get_nodes_in_group("player"):
		if body is CollisionObject3D:
			exclusions.append(body.get_rid())
	# Enemy areas supply body-part damage; bodies only handle movement.
	for body in get_tree().get_nodes_in_group("enemy"):
		if body is PhysicsBody3D:
			exclusions.append(body.get_rid())

func _physics_process(delta: float) -> void:
	if impacted:
		return
	var destination := global_position - global_basis.z * SPEED * delta
	var query := PhysicsRayQueryParameters3D.create(global_position, destination, 3, exclusions)
	query.collide_with_areas = true
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		global_position = destination
		return
	impacted = true
	global_position = result.position
	$MeshInstance3D.hide()
	$RayCast3D.enabled = false
	$Blood.position = Vector3.ZERO
	$Walls.position = Vector3.ZERO
	var collider = result.collider
	if collider.has_method("hit") and collider.is_in_group("enemy"):
		$Blood.emitting = true
		collider.hit()
		confirmed_hit.emit()
	elif collider.is_in_group("enemy") and collider.has_method("got_hit"):
		$Blood.emitting = true
		collider.got_hit(5.0)
		confirmed_hit.emit()
	else:
		$Walls.emitting = true
	$Life.start(1.0)

func _on_life_timeout() -> void:
	queue_free()
