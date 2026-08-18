extends Interactable
@export var trap_type : String = "base"
@export var trap_damage : float = 2.0
@export var timing : float = 1.0
@export var hit : float 
@export var max_hit : float


func _ready() -> void:
	add_to_group("traps")
	interacted.connect(_on_interacted)
	match trap_type:
		"base":
			$fast.visible = false
			$base.visible = true
		"fast":
			$fast.visible = true
			$base.visible = false
	
var picked_up: bool = false

func _process(delta: float) -> void:
	if hit >max_hit:
		queue_free()

func _on_interacted(body: Variant) -> void:
	if picked_up:
		return
	picked_up = true
	Inventory.add_trap(trap_type, trap_damage, timing, hit,max_hit)
	queue_free()
