extends State

func enter():
	enemy.anim["parameters/conditions/run"] = true
	enemy.anim["parameters/conditions/attack"] = false

func update(delta):
	if enemy.in_range():
		enemy.zombie_sm.transition("Attack")

func physics_update(delta):
	enemy.check_trap()
	enemy.nav_agent.set_target_position(enemy.player.global_position)
	var next_nav_point = enemy.nav_agent.get_next_path_position()
	enemy.velocity = (
		next_nav_point - enemy.global_position
	).normalized() * enemy.speed
	enemy.smooth_look_at(Vector3(
		enemy.global_position.x + enemy.velocity.x,
		enemy.global_position.y,
		enemy.global_position.z + enemy.velocity.z
	), delta)
