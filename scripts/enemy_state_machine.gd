extends Node

var host
var _states := {}

func setup(h) -> void:
	host = h
	_states = {
		"run": _state_run,
		"attack": _state_attack,
	}

func tick(delta: float) -> void:
	var node = host.state_machine.get_current_node()
	if _states.has(node):
		_states[node].call(delta)

func _state_run(delta: float) -> void:
	host._check_trap()
	host.nav_agent.set_target_position(host.player.global_transform.origin)
	var next_nav_point = host.nav_agent.get_next_path_position()
	host.velocity = (next_nav_point - host.global_transform.origin).normalized() * host.speed
	host.smooth_look_at(Vector3(host.global_position.x + host.velocity.x, host.global_position.y, host.global_position.z + host.velocity.z), delta)

func _state_attack(delta: float) -> void:
	host._check_trap()
	host.smooth_look_at(Vector3(host.player.global_position.x, host.global_position.y, host.player.global_position.z), delta)
