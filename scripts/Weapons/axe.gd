extends Node3D

enum State { READY, SWINGING }
const SWING_TIME := 0.55
var state := State.READY
var elapsed := 0.0
var hit_used := false
signal confirmed_hit

func _ready() -> void:
	set_hitboxes(false)
	var library = $AnimationPlayer.get_animation_library("").duplicate(true)
	$AnimationPlayer.remove_animation_library("")
	$AnimationPlayer.add_animation_library("", library)
	# Damage windows are owned here; the existing animation supplies the motion.
	for name in ["RESET", "swing"]:
		var animation: Animation = $AnimationPlayer.get_animation(name).duplicate()
		for track in range(animation.get_track_count() - 1, -1, -1):
			if str(animation.track_get_path(track)).ends_with(":disabled"):
				animation.remove_track(track)
		library.remove_animation(name)
		library.add_animation(name, animation)

func set_hitboxes(enabled: bool) -> void:
	for shape in [$Anchor/Axe_Model/Area3D/CollisionShape3D, $Anchor/Axe_Model/Area3D/CollisionShape3D2]:
		shape.set_deferred("disabled", not enabled)

func start_swing() -> bool:
	if state != State.READY:
		return false
	state = State.SWINGING
	elapsed = 0.0
	hit_used = false
	set_hitboxes(false)
	$AnimationPlayer.play("swing", -1, 0.3 / SWING_TIME)
	return true

func _physics_process(delta: float) -> void:
	advance(delta)

func advance(delta: float) -> void:
	if state == State.READY:
		return
	elapsed += delta
	set_hitboxes(is_damage_window())
	if elapsed >= SWING_TIME:
		state = State.READY
		set_hitboxes(false)

func is_damage_window() -> bool:
	return state == State.SWINGING and not hit_used and elapsed >= 0.12 and elapsed < 0.38

func is_busy() -> bool:
	return state != State.READY

func _on_area_3d_area_entered(area: Area3D) -> void:
	if not is_damage_window() or not area.is_in_group("enemy") or not area.has_method("hit"):
		return
	hit_used = true
	set_hitboxes(false)
	area.hit(10, "axe")
	confirmed_hit.emit()
