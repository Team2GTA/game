extends CSGCombiner3D

@export var shuffle_time := 0.5

@onready var player: Node3D = %Player

@onready var room_nodes: Array[Node3D] = [
	%f1,
	%f2,
	%f3,
	%f4,
	%f5,
	%f6,
	%f7,
	%f8,
	%f9
]

var positions: Array[Vector3] = []
var shuffling := false
var current_room := 0


func _ready() -> void:
	# Store the original room positions
	for room in room_nodes:
		positions.append(room.position)


func _on_hitbox_body_entered(body: Node3D) -> void:
	if body != player:
		return

	if shuffling:
		return

	current_room = get_current_room()
	await shuffle_rooms(current_room)


func get_current_room() -> int:
	var closest := 0
	var best_dist := INF

	for i in range(room_nodes.size()):
		var d := player.global_position.distance_squared_to(
			room_nodes[i].global_position
		)

		if d < best_dist:
			best_dist = d
			closest = i

	return closest


func shuffle_rooms(fixed_index: int) -> void:
	shuffling = true

	# Duplicate the current layout
	var shuffled := positions.duplicate()

	# Keep the player's room fixed
	var fixed_position: Vector3 = shuffled[fixed_index]
	shuffled.remove_at(fixed_index)
	shuffled.shuffle()
	shuffled.insert(fixed_index, fixed_position)

	# Animate every room simultaneously
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)

	for i in range(room_nodes.size()):
		tween.tween_property(
			room_nodes[i],
			"position",
			shuffled[i],
			shuffle_time
		)

	await tween.finished

	# Save the new layout
	positions = shuffled
	shuffling = false


func get_current_room_position() -> Vector3:
	return positions[current_room]


func get_current_room_index() -> int:
	return current_room
