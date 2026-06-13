extends CSGCombiner3D

var poss = []
var index = 0
var closest

func  _ready() -> void:
	poss = [%f1.position,%f2.position,%f3.position,%f4.position,%f5.position,%f6.position,%f7.position,%f8.position,%f9.position]
	#Gets position of the rooms

func _process(delta: float) -> void:
	if $"../..".wait:
		closest = get_min_dist(poss,index)

#Detects when player enter a room
func _on_hitbox_body_entered(body: Node3D) -> void:
	if body == %Player:
		closest = get_min_dist(poss,index)
		shuffle_fixed(poss,closest)

#Function to Shuffle while keeping one value constant
func shuffle_fixed(array:Array, k: int):
	var fixed_array = array.slice(k,k+1)
	array.remove_at(k)
	array.shuffle()
	array.insert(k,fixed_array[0])
	
	for i in range(array.size()):
		get_node("f%d"%(i+1)).position = array[i]

func get_min_dist(array:Array, k:int):
	var min_dist = %Player.global_position.distance_to(array[0])
	for i in range(array.size()):
			if(%Player.global_position.distance_to(array[i]) < min_dist):
				min_dist=%Player.global_position.distance_to(array[i])
				k=i
	return k
