extends State

const RETREAT_RANGE = 5.0
const RETREAT_SPEED = 4.0
var shoot_timer = 0.0

func enter():
	shoot_timer = 0.0
	
func update(delta):
	var dist = enemy.global_position.distance_to(player.global_position)
	if dist > RETREAT_RANGE:
		enemy.skeleton_sm.transition("Agro")
	
	shoot_timer +=delta
	if shoot_timer>2.0 and enemy.has_line_of_sight():
		enemy.shoot()
		shoot_timer = 0.0
	
func physics_update(delta):
	var away = (enemy.global_position - player.global_position).normalized()
	var retreat_target = enemy.global_position + away*5.0
	enemy.nav_agent.set_target_position(retreat_target)
	var next_nav_point = enemy.nav_agent.get_next_path_position()
	enemy.velocity = (next_nav_point-enemy.global_position).normalized()*RETREAT_SPEED
	
	enemy.smooth_look_at(Vector3(player.global_position.x, enemy.global_position.y, player.global_position.z), delta)
	
	enemy.move_and_slide()
