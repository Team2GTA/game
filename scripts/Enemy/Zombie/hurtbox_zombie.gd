extends Area3D

@export var damage = 5.0

signal body_part_hit(dam, weapon)

func hit(dam = damage, weapon: String = "gun"):
	emit_signal("body_part_hit", dam, weapon)
