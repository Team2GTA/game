extends State

const AGRO_RANGE = 20.0
const WANDER_SPEED = 2.0
var lost_timer = 0.0
var last_known_pos = Vector3.ZERO

func enter():
	lost_timer = 0.0
	enemy.velocity = Vector3.ZERO
	
	last_known_pos = player.global_position
	enemy.nav_agent.set_target_position(last_known_pos)
	
func update(delta):
	lost_timer+=delta
	
	if enemy.has_line_of_sight():
		var dist = enemy.global_position.distance_to(player.global_position)
		if dist < AGRO_RANGE:
			lost_timer = 0.0
			enemy.skeleton_sm.transition("Agro")
			return
			
	if lost_timer>3.0:
		enemy.skeleton_sm.transition("Idle")

func physics_update(delta):
	var next_nav_point = enemy.nav_agent.get_next_path_position()
	enemy.velocity = (next_nav_point - enemy.global_position).normalized() * WANDER_SPEED
	
	if enemy.velocity.length() > 0.1:
		var target = enemy.global_position + enemy.velocity
		enemy.smooth_look_at(Vector3(target.x, enemy.global_position.y, target.z), delta)
	
	enemy.move_and_slide()
