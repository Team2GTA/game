extends Node

var inventory = {
	"traps": [],
	"overlay":false,
	"ammo":{
		"rifle":35
	}
}

func reset():
	inventory = {
		"traps": [],
		"overlay": false,
		"ammo": {
			"rifle": 35
		}
	}

func get_value(key: String) -> Variant:
	return inventory.get(key, null)

func set_value(key, value):
	inventory[key] = value


func get_ammo(type: String):
	if inventory["ammo"].has(type):
		return inventory["ammo"][type]
	return 0

func add_ammo(type: String, amount: int):
	if !inventory["ammo"].has(type):
		inventory["ammo"][type] = 0
	
	inventory["ammo"][type] +=amount

func consume_ammo(type: String, amount: int):
	if !inventory["ammo"].has(type):
		return false

	if inventory["ammo"][type]<amount:
		amount = inventory["ammo"][type]
	
	inventory["ammo"][type]-=amount
	return true

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
