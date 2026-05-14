extends CSGCombiner3D
var poss = []
func  _ready() -> void:
	#Gets position of the rooms
	poss = [%f1.position,%f2.position,%f3.position,%f4.position]

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

	#Shuffles the positons
	%f1.position = poss[0]
	%f2.position = poss[1]
	%f3.position = poss[2]
	%f4.position = poss[3]
	
#Function to Shuffle while keeping one value constant
func shuffle_fixed(array:Array, k: int):
	var fixed_array = array.slice(k,k+1)
	array.remove_at(k)
	array.shuffle()
	array.insert(k,fixed_array[0])
