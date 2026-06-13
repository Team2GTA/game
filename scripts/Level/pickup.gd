extends Node3D
@export var type = "base"
signal proceed
@onready var base: MeshInstance3D = $Base
@onready var heal: MeshInstance3D = $Heal
@onready var text: Sprite3D = $Display/Sprite3D

func _ready() -> void:
	match type:
		"heal":
			heal.visible = true
			base.visible = false
		"mag":
			heal.visible = false
			base.visible = true
		"heal_gain":
			heal.visible = true
			base.visible = false
			var mat = heal.get_active_material(0).duplicate()
			mat.albedo_color = Color(0.635, 0.0, 0.059, 1.0)
			mat.emission = Color(0.954, 0.0, 0.113, 1.0)
			heal.set_surface_override_material(0, mat)
			text.visible = true
		"mag_gain":
			heal.visible = false
			base.visible = true
			var mat = base.get_active_material(0).duplicate()
			mat.albedo_color = Color(0.518, 0.502, 1.0, 1.0)
			mat.emission = Color(0.219, 0.186, 0.641, 1.0)
			base.set_surface_override_material(0, mat)
			
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
				body.max_health +=5
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
