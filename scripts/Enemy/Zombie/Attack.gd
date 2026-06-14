extends State

func enter():
	enemy.anim["parameters/conditions/attack"] = true
	enemy.anim["parameters/conditions/run"] = false
	
func update(delta):
	if !enemy.in_range():
		enemy.zombie_sm.transition("Agro")

func physics_update(delta):
	enemy.check_trap()
	enemy.velocity = Vector3.ZERO
	enemy.smooth_look_at(Vector3(
		enemy.player.global_position.x,
		enemy.global_position.y,
		enemy.player.global_position.z
	), delta)
