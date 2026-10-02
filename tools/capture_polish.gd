extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func snapshot(label: String) -> void:
	for i in range(6):
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := "res://.godot/polish/" + label + ".png"
	image.save_png(path)
	print("CAPTURE: ", label, " ", image.get_size())

func capture() -> void:
	DirAccess.make_dir_recursive_absolute("res://.godot/polish")
	root.mode = Window.MODE_WINDOWED
	root.content_scale_size = Vector2i(1920, 1080)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	var settings = root.get_node("Settings")
	settings.storage_path = "res://.godot/capture-settings.cfg"
	settings.best_score = 120
	var scene = load("res://scenes/Level/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	var ui = scene.get_node("UI")
	for resolution in [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(2560, 1080)]:
		root.size = resolution
		var tag := str(resolution.x) + "x" + str(resolution.y)
		scene.state = "start"
		scene.state_machine()
		await snapshot(tag + "-menu")
		ui._on_controls_pressed()
		await snapshot(tag + "-controls")
		ui.close_controls()
		ui._on_start_pressed()
		scene.set_process(false)
		scene.clear_zombies()
		var player = scene.get_node("Player")
		player.set_physics_process(false)
		player.look_pitch = 0
		player.update_camera(1.0)
		ui.update_hud()
		await snapshot(tag + "-gameplay")
		scene.state = "paused"
		scene.state_machine()
		await snapshot(tag + "-pause")
		scene.state = "dead"
		scene.state_machine()
		await snapshot(tag + "-defeat")
		scene.highest_level = 2
		scene.highest_wave = 3
		scene.state = "win"
		scene.state_machine()
		await snapshot(tag + "-victory")
	print("ALL CAPTURES COMPLETE")
	quit()
