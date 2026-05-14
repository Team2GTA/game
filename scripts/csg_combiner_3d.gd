extends CSGCombiner3D
var poss = []
func  _ready() -> void:
	poss = [%f1.position,%f2.position,%f3.position,%f4.position,%f5.position,%f6.position,%f7.position,%f8.position,%f9.position]
	#Gets position of the rooms
	
func _physics_process(delta: float) -> void:
	
	var index = 0
	var min_dist = %Player.global_position.distance_to(poss[0])
	if Input.is_action_just_pressed("ui_menu"):
		#Finds the closest room to the Player
		for i in range(poss.size()):
			if(%Player.global_position.distance_to(poss[i]) < min_dist):
				min_dist=%Player.global_position.distance_to(poss[i])
				#Saves the index of the room
				index =i
		shuffle_fixed(poss,index)

	
#Function to Shuffle while keeping one value constant
func shuffle_fixed(array:Array, k: int):
	var fixed_array = array.slice(k,k+1)
	array.remove_at(k)
	array.shuffle()
	array.insert(k,fixed_array[0])
	
	#Shuffles the positons
	for i in range(array.size()):
		get_node("f%d"%(i+1)).position = array[i]
