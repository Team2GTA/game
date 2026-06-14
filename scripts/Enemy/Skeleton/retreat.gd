extends State

const TOO_CLOSE_RANGE = 5.0
const IDEAL_RANGE = 10.0 
const RETREAT_SPEED = 4.0
var shoot_timer = 0.0
var retreat_target = Vector3.ZERO

func enter():
	shoot_timer = 0.0
	pick_retreat_target()

func pick_retreat_target():

	var away = (enemy.global_position - player.global_position).normalized()
	var side = enemy.global_transform.basis.x * randf_range(-2.0, 2.0)
	retreat_target = enemy.global_position + (away + side).normalized() * IDEAL_RANGE
	enemy.nav_agent.set_target_position(retreat_target)

func update(delta):
	var dist = enemy.global_position.distance_to(player.global_position)
	if dist > TOO_CLOSE_RANGE:
		enemy.skeleton_sm.transition("Agro")
	
	shoot_timer += delta
	if shoot_timer > 2.0 and enemy.has_line_of_sight():
		enemy.shoot()
		shoot_timer = 0.0

func physics_update(delta):
	var next_nav_point = enemy.nav_agent.get_next_path_position()
	enemy.velocity = (next_nav_point - enemy.global_position).normalized() * RETREAT_SPEED
	
	enemy.smooth_look_at(Vector3(player.global_position.x, enemy.global_position.y, player.global_position.z), delta)
	
	if enemy.global_position.distance_to(retreat_target) < 1.0:
		pick_retreat_target()
	
	enemy.move_and_slide()
