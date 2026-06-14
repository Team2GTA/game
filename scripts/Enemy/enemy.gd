class_name Enemy extends RefCounted

const STATS = {
	"zombie": {
		"health": 15.0,
		"attack": 3.0,
		"speed": 2.0,
	},
	"skeleton": {
		"health": 8.0,
		"attack": 5.0,
		"speed": 3.5,
	},
}

var stats = {
	"type": "",
	"health": 15.0,
	"attack": 3.0,
	"speed": 2.0,
}

func _init(type: String = "") -> void:
	if STATS.has(type):
		stats["type"] = type
		var preset = STATS[type]
		stats["health"] = preset["health"]
		stats["attack"] = preset["attack"]
		stats["speed"] = preset["speed"]
