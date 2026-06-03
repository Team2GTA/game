extends RigidBody3D
@export var trap_type : String
@export var trap_damage : float
@export var timing : float

func _ready() -> void:
	match trap_type:
		"base":
			$fast.visible = false
			$base.visible = true
		"fast":
			$fast.visible = true
			$base.visible = false
		_:
			$fast.visible = true
			$base.visible = true
