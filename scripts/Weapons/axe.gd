extends Node3D

func _ready() -> void:
	$Anchor/Axe_Model/Area3D/CollisionShape3D.disabled = true

func _on_area_3d_area_entered(area: Area3D) -> void:
	if area.has_method("hit"):
		area.hit(10, "axe")
		$Anchor/Axe_Model/Area3D/CollisionShape3D.disabled = true
		$Anchor/Axe_Model/Area3D/CollisionShape3D2.disabled = true
