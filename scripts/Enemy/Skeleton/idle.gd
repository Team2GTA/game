extends State

const AGRO_RANGE =20.0
const WANDER_SPEED = 2.0
const WANDER_RANGE = 10.0
const WANDER_CHANGE_TIME = 3.0

var wander_timer = 0.0

func enter():
	enemy.velocity = Vector3.ZERO
	wander_timer = WANDER_CHANGE_TIME
	pick_wander_target()
	
func pick_wander_target():
	if !enemy or !enemy.nav_agent:
		return
	var angle = randf()*TAU
	var offset = Vector3(cos(angle),0,sin(angle))*randf_range(2.0,WANDER_RANGE)
	enemy.nav_agent.set_target_position(enemy.global_position + offset)
	
func update(delta):
	var dist = enemy.global_position.distance_to(player.global_position)
	#if dist<AGRO_RANGE and enemy.has_line_of_sight():
		#enemy.skeleton_sm.transition("Agro")
	
func physics_update(delta):
	if !enemy or !enemy.nav_agent:
		return
	wander_timer+=delta
	if wander_timer>WANDER_CHANGE_TIME:
		wander_timer = 0.0
		pick_wander_target()
	
	var next_nav_point = enemy.nav_agent.get_next_path_position()
	enemy.velocity = (next_nav_point - enemy.global_position).normalized()*WANDER_SPEED
	
	if enemy.velocity.length()>0.1:
		var target = enemy.global_position + enemy.velocity
		enemy.smooth_look_at(Vector3(target.x, enemy.global_position.y, target.z),delta)
		
	enemy.move_and_slide()
