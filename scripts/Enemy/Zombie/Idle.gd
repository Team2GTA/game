extends State

const AGRO_RANGE = 20.0

func enter():
	enemy.anim["parameters/conditions/run"] = false
	enemy.anim["parameters/conditions/attack"] = false
	enemy.velocity = Vector3.ZERO

func update(delta):
	var dist = enemy.global_position.distance_to(player.global_position)
	if dist < AGRO_RANGE:
		enemy.zombie_sm.transition("Agro")

func physics_update(delta):
	enemy.velocity = Vector3.ZERO
