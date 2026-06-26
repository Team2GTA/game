extends Control


func _on_button_pressed() -> void:
	$".".visible = false
	$"../UI".visible = true
	$"../UI".controls_open = false
