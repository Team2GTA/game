extends State

func enter():
	enemy.velocity = Vector3.ZERO
	enemy.anim["parameters/conditions/die"] = true
	await enemy.get_tree().create_timer(2.5).timeout
	enemy.emit_signal("zombie_dead", enemy.global_position)
	enemy.call_deferred("queue_free")
