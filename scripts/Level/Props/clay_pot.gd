extends Node3D

@onready var body = $RigidBody3D

func _ready():
	var clay_pots: Array[MeshInstance3D] = []

	for child in body.get_children():
		if child is MeshInstance3D:
			clay_pots.append(child)

	if clay_pots.is_empty():
		return

	var chosen = clay_pots.pick_random()

	for clay_pot in clay_pots:
		clay_pot.visible = (clay_pot == chosen)

	chosen.scale = Vector3.ONE * randf_range(1.0, 2.0)
	chosen.rotation.y = randf_range(0.0, TAU)
