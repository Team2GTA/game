extends CharacterBody3D

func _physics_process(delta: float) -> void:
	move_and_slide()
	if is_on_floor():
		pass
	else:
		velocity.y=9.8
	
