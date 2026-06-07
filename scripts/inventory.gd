extends Node

var inventory = {
	"traps": [],
	"overlay":false
}

func get_value(key):
	if inventory.has(key):
		return inventory[key]
	printerr("Key not present: ", key)

func set_value(key, value):
	inventory[key] = value

func add_trap(trap_type: String, trap_damage: float, timing: float, hit,max_hit):
	inventory["traps"].append({
		"trap_type": trap_type,
		"trap_damage": trap_damage,
		"timing": timing,
		"hit":hit,
		"max_hit":max_hit
	})

func remove_trap(index: int = -1):
	if inventory["traps"].size() == 0:
		return null
	var trap = inventory["traps"][index if index >= 0 else inventory["traps"].size() - 1]
	inventory["traps"].remove_at(index if index >= 0 else inventory["traps"].size() - 1)
	return trap

func trap_count() -> int:
	return inventory["traps"].size()
