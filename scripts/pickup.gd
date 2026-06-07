extends Node3D
@export var type = "base"
signal proceed

func _ready() -> void:
	match type:
		"heal":
			$Heal.visible = true
			$Base.visible = false
		"mag":
			$Heal.visible = false
			$Base.visible = true
		"heal_gain":
			$Heal.visible = true
			$Base.visible = false
			var mat = $Heal.get_active_material(0).duplicate()
			mat.albedo_color = Color(0.635, 0.0, 0.059, 1.0)
			mat.emission = Color(0.954, 0.0, 0.113, 1.0)
			$Heal.set_surface_override_material(0, mat)
		"mag_gain":
			$Heal.visible = false
			$Base.visible = true
			var mat = $Base.get_active_material(0).duplicate()
			mat.albedo_color = Color(0.518, 0.502, 1.0, 1.0)
			mat.emission = Color(0.219, 0.186, 0.641, 1.0)
			$Base.set_surface_override_material(0, mat)
			
func _on_detection_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		var main = $".."
		var color_rect = $"../UI/ColorRect"
		match type:
			"heal":
				body.health += 10
				body.health = body.max_health if body.health > body.max_health else body.health
				main.target_hp = body.health
				main.update_health()
				color_rect.color = Color(0x75a83a8e)
			"mag":
				Inventory.add_ammo("rifle", 10)
				color_rect.color = Color(0xc777008e)
			"heal_gain":
				body.max_health +=10
				Inventory.add_ammo("rifle",10) 
				body.health = body.max_health
				main.target_hp = body.health
				main.update_health()
				color_rect.color = Color(0x548ed18e)
				emit_signal("proceed")
			"mag_gain":
				body.get_child(1).get_child(0).capacity = 20
				emit_signal("proceed")
		color_rect.visible = true
		await get_tree().create_timer(0.2).timeout
		color_rect.visible = false
		color_rect.color = Color(0xff00008e)
		call_deferred("queue_free")
