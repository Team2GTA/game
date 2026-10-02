extends Node3D

enum State { READY, FIRING, RELOADING }
const FIRE_INTERVAL := 0.24
const RELOAD_TIME := 1.8
var state := State.READY
var mag_size := 15
var capacity := 15
var remaining := 0.0
var ammo_type := "rifle"
var reloading: bool:
	get: return state == State.RELOADING
var reload_progress: float:
	get: return 1.0 - remaining / RELOAD_TIME if reloading else 0.0
@onready var shoot: AudioStreamPlayer3D = $Shoot

func _physics_process(delta: float) -> void:
	advance(delta)

func advance(delta: float) -> void:
	if state == State.READY:
		return
	remaining = maxf(remaining - delta, 0.0)
	if remaining > 0.00001:
		return
	if reloading:
		var to_load := mini(mag_size - capacity, Inventory.get_ammo(ammo_type))
		Inventory.consume_ammo(ammo_type, to_load)
		capacity += to_load
	state = State.READY

func try_fire(zoomed: bool) -> bool:
	if state != State.READY or capacity <= 0:
		return false
	state = State.FIRING
	remaining = FIRE_INTERVAL
	capacity -= 1
	shoot.play()
	$AnimationPlayer.play("shoot_zoomed" if zoomed else "shoot")
	return true

func start_reload() -> bool:
	if state != State.READY or capacity >= mag_size or Inventory.get_ammo(ammo_type) <= 0:
		return false
	state = State.RELOADING
	remaining = RELOAD_TIME
	$AnimationPlayer.play("RESET")
	$AnimationPlayer.advance(0.0)
	$AnimationPlayer.play("reload", -1, 1.5 / RELOAD_TIME)
	return true

func is_busy() -> bool:
	return state != State.READY

func _on_player_shot() -> void:
	# Kept for the existing scene signal; ammunition is committed by try_fire.
	pass
