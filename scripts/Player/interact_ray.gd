extends RayCast3D
@onready var prompt: Label = $Prompt

func _ready() -> void:
	prompt.text = ""
	prompt.hide()

func _physics_process(_delta: float) -> void:
	# UI owns the prompt; player.throw owns the one interaction action.
	prompt.hide()
