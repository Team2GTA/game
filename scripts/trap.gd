extends RigidBody3D
@onready var detect: ShapeCast3D = $ShapeCast3D

var inv 
var bodies : Array

func _ready() -> void:
	inv =1
	bodies = []

func _process(delta: float) -> void:
	
	if detect.is_colliding():
		for i in range(detect.get_collision_count()):
			if detect.get_collider(i).is_in_group("enemy") and !bodies.has(detect.get_collider(i)):
				bodies.append(detect.get_collider(i))
				detect.get_collider(i).flash_red()
				detect.get_collider(i).health-=5
				inv = 0
				await get_tree().create_timer(1.0).timeout
				inv = 1
				print(bodies)
	#
	#if detect.is_colliding() and detect.get_collider(0).is_in_group("enemy") and inv:
		
