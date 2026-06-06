extends Node3D

const SPEED = 40.0

@onready var ray = $RayCast3D
@onready var mesh = $MeshInstance3D
@onready var particles = $CPUParticles3D
@onready var life = $Life

func _process(delta: float) -> void:
	position +=transform.basis * Vector3(0,0,-SPEED)*delta
	if ray.is_colliding():
		mesh.visible = false
		particles.emitting = true
		ray.enabled = false
		if ray.get_collider().is_in_group("enemy") and ray.get_collider():
			ray.get_collider().hit()
		await get_tree().create_timer(1.0).timeout
		queue_free()

func _on_life_timeout() -> void:
	queue_free()
