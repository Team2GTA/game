extends SubViewport
@onready var label: Label = $Control/Label
var prev_health


func _ready() -> void:
	label.text = str($"..".health).trim_suffix(".0")
	prev_health = $"..".health


func _process(delta: float) -> void:
	if prev_health != $"..".health:
		label.text = str($"..".health).trim_suffix(".0")
	if $"..".health <0:
		label.text = "0"
