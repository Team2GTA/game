extends Node
class_name StateMachine

var current_state: State

func _ready() -> void:
	call_deferred("initialize")

func initialize() -> void:
	for child in get_children():
		child.enemy = get_parent()
		child.player = get_parent().player
	
	current_state = get_child(0)
	current_state.enter()

func transition(new_state_name: String) -> void:
	var next_state := get_node_or_null(new_state_name)
	if next_state == null:
		push_error("State '%s' not found." % new_state_name)
		return

	current_state.exit()
	current_state = next_state
	current_state.enter()

func _process(delta: float) -> void:
	if current_state == null or current_state.player == null:
		return
	current_state.update(delta)

func _physics_process(delta: float) -> void:
	if current_state == null or current_state.player == null:
		return
	current_state.physics_update(delta)
