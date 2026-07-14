extends OptionButton

@onready var panel: Panel = $"../../../../Panel"
@onready var controls: Control = $"../../../../../Controls"

func _on_item_selected(index: int) -> void:
	match index:
		0:
			panel.theme = preload("res://resources/themes/UI.tres")
			controls.theme = preload("res://resources/themes/UI.tres")
		1:
			panel.theme = preload("res://resources/themes/NewUI.tres")
			controls.theme = preload("res://resources/themes/NewUI.tres")
