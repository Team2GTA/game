extends RayCast3D
@onready var prompt: Label = $Prompt

func _physics_process(delta: float) -> void:
	prompt.text = ""
	if is_colliding():
		var object = get_collider()
		if object is Interactable:
			prompt.text = object.get_prompt()
			
			if Input.is_action_just_pressed(object.prompt_input):
				object.interact(owner)
