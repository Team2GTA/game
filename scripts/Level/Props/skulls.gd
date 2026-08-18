extends RigidBody3D

func _ready():
	var skulls: Array[MeshInstance3D] = []

	for child in get_children():
		if child is MeshInstance3D:
			skulls.append(child)

	if skulls.is_empty():
		return

	var chosen = skulls.pick_random()

	for skull in skulls:
		skull.visible = (skull == chosen)

	chosen.scale = Vector3.ONE * randf_range(1.0, 2.0)
	chosen.rotation.y = randf_range(0.0, TAU)
