extends State

const ATTACK_RANGE = 15.0
const RETREAT_RANGE = 5.0
const LOST_RANGE = 25.0
const STRAFE_SPEED = 3.0

var strafe_dir =1.0
var strafe_timer = 0.0
var shoot_timer = 0.0

func enter():
	strafe_timer = 0.0
	shoot_timer = 0.0

func update(delta):
	var dist = enemy.global_position.distance_to(player.global_position)
	if dist > LOST_RANGE or !enemy.has_line_of_sight():
		enemy.skeleton_sm.transition("Lost")
	elif dist < RETREAT_RANGE:
		enemy.skeleton_sm.transition("Retreat")
		
	shoot_timer+=delta
	if shoot_timer > 2.0 and enemy.has_line_of_sight():
		enemy.shoot()
		shoot_timer = 0.0

func physics_update(delta):
	strafe_timer +=delta
	if strafe_timer > 2.0:
		strafe_dir*=-1
		strafe_timer = 0.0
	
	enemy.smooth_look_at(Vector3(player.global_position.x, enemy.global_position.y, player.global_position.z),delta)
	
	var strafe_target = enemy.global_position + enemy.global_transform.basis.x * strafe_dir * 3
	enemy.nav_agent.set_target_position(strafe_target)
	var next_nav_point = enemy.nav_agent.get_next_path_position()
	enemy.velocity = (next_nav_point-enemy.global_position).normalized()*STRAFE_SPEED
	
	enemy.move_and_slide()
