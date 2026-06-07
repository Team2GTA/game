extends Node3D

var mag_size = 15
var capacity = mag_size
var reloading =false

var ammo_type = "rifle"

func _on_player_shot() -> void:
	if capacity > 0:
		capacity -=1

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("reload") and !reloading and $"../..".weapon =="gun":
		if capacity==mag_size:
			return
		
		var reserve = Inventory.get_ammo(ammo_type)
		if reserve<=0:
			return
		
		reloading = true
		$AnimationPlayer.play("reload")
		
		await get_tree().create_timer(1.5).timeout
		
		var needed = mag_size-capacity
		var to_load = min(needed, reserve)
		
		Inventory.consume_ammo(ammo_type, to_load)
		capacity += to_load
		
		reloading = false
