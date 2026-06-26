extends Node3D

const SPEED = 40.0

@onready var ray = $RayCast3D
@onready var mesh = $MeshInstance3D
@onready var blood: CPUParticles3D = $Blood
@onready var walls: CPUParticles3D = $Walls
@onready var life = $Life

func _process(delta: float) -> void:
	position +=transform.basis * Vector3(0,0,-SPEED)*delta
	if ray.is_colliding():
		var collider = ray.get_collider()
		mesh.visible = false
		ray.enabled = false
		if collider and collider.is_in_group("enemy"):
			blood.emitting = true
			collider.hit()
		else:
			walls.emitting = true
		await get_tree().create_timer(1.0).timeout
		queue_free()

func _on_life_timeout() -> void:
	queue_free()
