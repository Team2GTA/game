extends SceneTree
var failures := 0
var checks := 0

func check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS: " + description)
	else:
		failures += 1
		push_error("FAIL: " + description)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var settings = root.get_node("Settings")
	settings.storage_path = "res://.godot/polish-test-settings.cfg"
	var scene = load("res://scenes/Level/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	scene.set_process(false)
	var ui = scene.get_node("UI")
	var player = scene.get_node("Player")
	check(player.get_interactable(null) == null, "Missing raycast collider safely resolves to no interaction")
	var interaction_target := Area3D.new()
	interaction_target.set_script(load("res://scripts/interactable.gd"))
	var interaction_child := Node.new()
	interaction_target.add_child(interaction_child)
	check(player.get_interactable(interaction_child) == interaction_target, "Collider children resolve to their interactable ancestor")
	interaction_target.free()
	var plain_collider := Node.new()
	check(player.get_interactable(plain_collider) == null, "Non-interactable collider without a parent safely resolves to nothing")
	plain_collider.free()
	var rifle = player.get_node("Camera3D/Rifle")
	var axe = player.get_node("Camera3D/Axe")
	check(not player.get_node("Camera3D/InteractRay/Prompt").visible, "Legacy interaction placeholder is hidden")
	ui._on_start_pressed()
	scene.clear_zombies()
	player.set_physics_process(false)
	rifle.set_physics_process(false)
	axe.set_physics_process(false)
	check(rifle.try_fire(false) and rifle.capacity == 14, "Rifle commits one round per shot")
	check(not rifle.try_fire(false), "Rifle rejects shots during recovery")
	check(not player.switch_weapon(player.Weapon.AXE), "Firing recovery locks switching")
	rifle.advance(0.23)
	check(rifle.is_busy(), "Rifle interval lasts at least 0.24 seconds")
	rifle.advance(0.01)
	check(not rifle.is_busy(), "Rifle recovers at 0.24 seconds")
	rifle.capacity = 0
	var animation_before: StringName = rifle.get_node("AnimationPlayer").current_animation
	check(not rifle.try_fire(false) and rifle.get_node("AnimationPlayer").current_animation == animation_before, "Empty fire does not start a shooting animation")
	root.get_node("Inventory").inventory.ammo.rifle = 10
	check(rifle.start_reload(), "Reload begins with reserve ammunition")
	check(not rifle.try_fire(false) and not player.switch_weapon(player.Weapon.AXE), "Reload blocks shooting and switching")
	rifle.advance(1.79)
	check(rifle.reloading and rifle.capacity == 0, "Reload stays committed until 1.8 seconds")
	root.get_node("Inventory").inventory.ammo.rifle = 2
	rifle.advance(0.01)
	check(rifle.capacity == 2 and root.get_node("Inventory").get_ammo("rifle") == 0, "Reload reads current reserve and cannot create ammunition")
	check(not rifle.start_reload(), "Reload rejects empty reserves")
	player.zoomed = true
	check(player.switch_weapon(player.Weapon.AXE) and not player.zoomed, "Weapon switching clears zoom")
	await process_frame
	check(axe.get_node("Anchor/Axe_Model/Area3D/CollisionShape3D").disabled and axe.get_node("Anchor/Axe_Model/Area3D/CollisionShape3D2").disabled, "Both axe hitboxes start disabled")
	var area := Area3D.new()
	area.set_script(load("res://scripts/Enemy/Zombie/hurtbox_zombie.gd"))
	scene.add_child(area)
	area.add_to_group("enemy")
	var hits: Array = []
	area.body_part_hit.connect(func(damage, _weapon): hits.append(damage))
	check(axe.start_swing() and not axe.start_swing(), "Axe swing cannot restart itself")
	axe._on_area_3d_area_entered(area)
	check(hits.is_empty(), "Axe windup cannot damage enemies")
	check(not player.switch_weapon(player.Weapon.GUN), "Axe swing locks weapon switching")
	axe.advance(0.13)
	axe._on_area_3d_area_entered(area)
	axe._on_area_3d_area_entered(area)
	check(hits == [10], "Axe damages once during its active window")
	axe.advance(0.41)
	check(axe.is_busy(), "Axe remains committed through recovery")
	axe.advance(0.02)
	check(not axe.is_busy() and player.switch_weapon(player.Weapon.GUN), "Axe unlocks after 0.55 seconds")
	area.queue_free()
	player.stamina = 50
	player.velocity = Vector3(0, 0, -5)
	Input.action_press("sprint")
	Input.action_press("up")
	player.update_stamina(1.0)
	check(is_equal_approx(player.stamina, 38.0), "Sprint drains twelve stamina per second")
	player.update_stamina(4.0)
	check(player.stamina == 0 and player.exhausted and player.get_speed() != player.SPRINT_SPEED, "Exhaustion blocks sprinting")
	Input.action_release("sprint")
	Input.action_release("up")
	player.update_stamina(1.25)
	check(player.stamina == 0, "Regeneration waits 1.25 seconds")
	player.update_stamina(1.0)
	check(is_equal_approx(player.stamina, 9.0) and player.exhausted, "Stamina regenerates smoothly but remains exhausted below fifteen")
	player.update_stamina(1.0)
	check(not player.exhausted and is_equal_approx(player.stamina, 18.0), "Sprint recovers only after fifteen stamina")
	player.stamina = 10
	player.jump_buffer = 0.05
	player.coyote_time = 0.04
	player.jump_consumed = false
	check(player.try_buffered_jump() and player.stamina == 2 and player.velocity.y == player.JUMP_FORCE, "Buffered ledge jump consumes eight stamina")
	player.jump_buffer = 0.1
	check(not player.try_buffered_jump(), "A jump cannot be repeated in the same airborne window")
	player.jump_consumed = false
	player.coyote_time = 0.08
	player.stamina = 7
	check(not player.try_buffered_jump() and player.stamina == 7, "Low stamina rejects jumps without negative stamina")
	player.stamina = 50
	player.jump_buffer = 0
	check(not player.try_buffered_jump(), "Expired jump buffers do not trigger jumps")
	settings.camera_shake = false
	player.recoil = 0.02
	player.damage_shake = 0.07
	player.look_pitch = 0.1
	player.bob_enabled = false
	player.update_camera(0.01)
	check(is_equal_approx(player.get_node("Camera3D").rotation.x, 0.1) and player.get_node("Camera3D").position == player.cam_base_pos, "Disabling shake removes recoil and damage motion")
	ui.announcement.show()
	ui.announcement.text = "STEADY YOURSELF"
	ui.show_state("paused")
	check(not ui.announcement.visible, "Pause hides the countdown behind the menu")
	ui.show_state("intermidiate")
	check(ui.announcement.visible, "Resume restores an active countdown")
	ui.announcement.hide()
	ui.feedback("damage", "Test notice")
	paused = true
	ui._process(1.0)
	check(ui.damage_time == 0.28 and ui.notice_time == 2.2, "Feedback timers freeze while paused")
	paused = false
	ui._process(1.0)
	check(ui.damage_time == 0.0, "Damage feedback has a bounded duration")
	ui.hide = false
	scene.state = "intermidiate"
	ui.show_state("intermidiate")
	var reward := Node3D.new()
	scene.add_child(reward)
	reward.position = player.position + Vector3(0, 0, -5)
	scene.reward_pickup = reward
	ui.update_hud()
	check(not ui.health_panel.visible and ui.reward_marker.visible, "Reward guidance survives HUD hiding")
	ui._on_controls_pressed()
	check(ui.controls_page.visible and ui.controls_open and not ui.menu.visible, "Controls have a dedicated screen")
	var binding = get_nodes_in_group("remap_buttons")[0]
	binding.button_pressed = true
	var original: String = settings.binding_label(binding.action)
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	binding._input(escape)
	check(not binding.button_pressed and settings.binding_label(binding.action) == original, "Escape cancels remapping without changing bindings")
	binding.button_pressed = true
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_MIDDLE
	mouse.pressed = true
	binding._input(mouse)
	check(settings.binding_label(binding.action) == "MMB", "Controls accept mouse bindings")
	settings.reset_bindings()
	check(settings.binding_label(binding.action) == original, "Restore Defaults restores original controls")
	ui.close_controls()
	check(not ui.controls_open and ui.menu.visible, "Back restores the menu")
	settings.fov = 91
	settings.record_score(444)
	settings.fov = 75
	settings.best_score = 0
	settings.load_settings()
	check(settings.fov == 91 and settings.best_score == 444, "FOV and best score survive a settings reload")
	settings.record_score(3)
	check(settings.best_score == 444, "Lower scores never replace a record")
	settings.fov = 75
	settings.camera_shake = true
	ui.hide = true
	# Verify spawn constraints against the actual navigation map.
	await physics_frame
	await physics_frame
	var spawn = scene.choose_spawn_position()
	check(spawn != null and spawn.distance_to(player.global_position) >= 8 and spawn.distance_to(player.global_position) <= 30.2, "Spawn selection respects the safe navigation distance")
	var old_markers: Vector3 = scene.spawn_markers.position
	scene.spawn_markers.position += Vector3(10000, 0, 0)
	scene.state = "play"
	scene.spawn_zombie()
	check(scene.spawn_timer == 0.5, "No safe spawn schedules a half-second retry")
	scene.spawn_markers.position = old_markers
	paused = false
	ui._on_restart_pressed()
	await process_frame
	await process_frame
	check(is_instance_valid(current_scene) and current_scene.state == "start" and paused, "Restart returns to a fresh paused start menu")
	check(current_scene.get_node("Player").score == 0 and root.get_node("Inventory").get_ammo("rifle") == 35 and settings.best_score == 444, "Restart resets the run while preserving the record")
	paused = false
	current_scene.queue_free()
	await process_frame
	print("POLISH CHECKS: ", checks, " / FAILURES: ", failures)
	quit(1 if failures else 0)
