extends SceneTree

var failures := 0

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: " + description)
	else:
		push_error("FAIL: " + description)
		failures += 1

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.get_node("Settings").storage_path = "res://.godot/suite-settings.cfg"
	var main = load("res://scenes/Level/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame
	main.set_process(false)
	var ui = main.get_node("UI")
	var player = main.get_node("Player")
	check(paused and main.state == "start", "Start menu pauses the game")
	ui._on_start_pressed()
	check(not paused and main.state == "play", "Start enters gameplay")
	main.clear_zombies()
	player.set_physics_process(false)
	for previous in ["play", "intermidiate"]:
		main.state = previous
		var escape := InputEventKey.new()
		escape.physical_keycode = KEY_ESCAPE
		escape.pressed = true
		ui._unhandled_input(escape)
		check(paused and main.state == "paused", "Escape pauses " + previous)
		ui._unhandled_input(escape)
		check(not paused and main.state == previous, "Escape restores " + previous)
		ui._unhandled_input(escape)
		ui._on_resume_pressed()
		check(not paused and main.state == previous, "Resume button restores " + previous)
	player.set_physics_process(false)
	main.state = "play"
	main.wave = 3
	main.level = 1
	player.score = 100
	main.wave_score = main.wave_target()
	main.wave_handle()
	ui.old_state = "intermidiate"
	main.state = "paused"
	main.state_machine()
	await create_timer(1.2).timeout
	check(not is_instance_valid(main.reward_pickup), "Wave reward timer stays frozen during pause")
	ui._on_resume_pressed()
	player.set_physics_process(false)
	await create_timer(1.2).timeout
	check(is_instance_valid(main.reward_pickup), "Completed wave creates its reward")
	main.state_machine()
	check(ui.reward_marker.visible and "Collect" in ui.wave_status.text, "Reward guidance appears between waves")
	var reward = main.reward_pickup
	reward.proceed.emit()
	check(main.state == "level_transition", "Third reward enters level transition")
	reward.queue_free()
	main.state_machine()
	main.level_transition()
	await create_timer(2.2).timeout
	check(main.level == 2 and main.wave == 1 and main.state == "play", "Level 2 starts at wave 1")
	check(player.score == 100 and main.wave_score == 0, "Total score survives level transition")
	check(main.spawn_markers.position.y == 0 and player.position.y == 0, "Level 2 uses the existing arena")
	main.clear_zombies()
	main.wave = 3
	main.wave_score = main.wave_target()
	main.wave_handle()
	await create_timer(1.2).timeout
	main.reward_pickup.proceed.emit()
	check(main.state == "win", "Final reward wins the game")
	main.state_machine()
	check(paused and ui.get_node("Stamina").visible == false, "Win screen pauses and hides gameplay HUD")
	paused = false
	main.queue_free()
	await process_frame
	await test_bullet()
	await test_skeleton()
	test_settings()
	print("REGRESSION FAILURES: ", failures)
	quit(1 if failures else 0)

func test_bullet() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var wall := StaticBody3D.new()
	wall.position = Vector3(0, 0, -2)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(10, 10, 0.1)
	collision.shape = shape
	wall.add_child(collision)
	world.add_child(wall)
	await physics_frame
	await physics_frame
	var bullet = load("res://scenes/Weapons/bullet.tscn").instantiate()
	world.add_child(bullet)
	bullet.set_physics_process(false)
	bullet._physics_process(0.1)
	check(bullet.impacted, "Bullet catches a thin wall across a long frame")
	var impact: Vector3 = bullet.global_position
	bullet._physics_process(0.1)
	check(bullet.global_position == impact and absf(impact.z + 1.95) < 0.05, "Bullet stops at the wall surface")
	check(bullet.get_node("Walls").position == Vector3.ZERO, "Impact particles originate at collision")
	wall.queue_free()
	bullet.queue_free()
	await physics_frame
	var hurtbox := Area3D.new()
	hurtbox.set_script(load("res://scripts/Enemy/Zombie/hurtbox_zombie.gd"))
	hurtbox.add_to_group("enemy")
	hurtbox.collision_layer = 2
	hurtbox.position = Vector3(0, 0, -2)
	var hurt_shape := CollisionShape3D.new()
	hurt_shape.shape = shape
	hurtbox.add_child(hurt_shape)
	world.add_child(hurtbox)
	var hits: Array = []
	hurtbox.body_part_hit.connect(func(damage, _weapon): hits.append(damage))
	await physics_frame
	await physics_frame
	var shot = load("res://scenes/Weapons/bullet.tscn").instantiate()
	world.add_child(shot)
	shot.set_physics_process(false)
	shot._physics_process(0.1)
	shot._physics_process(0.1)
	check(hits.size() == 1 and hits[0] == 5.0, "Bullet damages enemy hurtbox exactly once")
	world.queue_free()
	await process_frame

func test_skeleton() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var target := Node3D.new()
	target.position = Vector3(0, 0, -100)
	world.add_child(target)
	var skeleton = load("res://scenes/Enemy/Skeleton.tscn").instantiate()
	skeleton.player = target
	world.add_child(skeleton)
	await process_frame
	skeleton.skeleton_sm.set_process(false)
	skeleton.skeleton_sm.set_physics_process(false)
	skeleton.spawning = false
	skeleton.velocity = Vector3(3, 0, 0)
	await physics_frame
	var start: Vector3 = skeleton.position
	for i in range(10):
		await physics_frame
	var expected := 3.0 * 10.0 / Engine.physics_ticks_per_second
	check(absf(skeleton.position.x - start.x - expected) < 0.01, "Skeleton moves once per physics tick")
	var flash = skeleton.flash_surfaces[0].flash
	skeleton.flash_red()
	await create_timer(0.15).timeout
	check(skeleton.get_node("Body").get_surface_override_material(0) == null, "Damage flash restores original material")
	skeleton.flash_red()
	check(skeleton.flash_surfaces[0].flash == flash, "Repeated hits reuse cached flash material")
	await create_timer(0.15).timeout
	world.queue_free()
	await process_frame

func test_settings() -> void:
	var settings = root.get_node("Settings")
	var original_path: String = settings.storage_path
	settings.storage_path = "res://.godot/regression-settings.cfg"
	settings.sensitivity = 0.37
	settings.master_volume = 0.45
	settings.camera_shake = false
	var original_events := InputMap.action_get_events("up")
	var binding := InputEventKey.new()
	binding.physical_keycode = KEY_K
	InputMap.action_erase_events("up")
	InputMap.action_add_event("up", binding)
	settings.save_binding("up")
	settings.sensitivity = 0.1
	settings.camera_shake = true
	settings.load_settings()
	check(is_equal_approx(settings.sensitivity, 0.37) and not settings.camera_shake and is_equal_approx(settings.master_volume, 0.45), "Comfort settings survive save and reload")
	check(InputMap.action_get_events("up")[0].physical_keycode == KEY_K, "Keybindings survive save and reload")
	settings.storage_path = original_path
	InputMap.action_erase_events("up")
	for event in original_events:
		InputMap.action_add_event("up", event)
	DirAccess.remove_absolute("res://.godot/regression-settings.cfg")
