extends RayCast3D
var surface = "default"
var current_room = null
var current_material = null

func get_material_properties():
	if is_colliding():
		var collider = get_collider()
		if collider == null:
			return
		var x = null
		if collider.is_in_group("traps"):
			x=collider
		
		if x == current_material:
			return current_material
		current_material = x
	if current_material:
		return current_material

func get_floor_properties():
	if is_colliding():
		var collider = get_collider()
		
		if collider:
			var x = null
			for j in collider.get_children():
				if j.is_in_group("rooms"):
					if x:
						x = j if global_position.distance_to(j.global_position) < global_position.distance_to(x.global_position) else x
					else:
						x = j
			
			if x == current_room:
				return
			current_room = x
			
			surface = "default"
			if x:
				if x.is_in_group("ice"):
					surface = "ice"
				elif x.is_in_group("mud"):
					surface = "mud"
				elif x.is_in_group("wood"):
					surface = "wood"
