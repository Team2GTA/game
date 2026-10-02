extends Control

const INK := Color("101519")
const PANEL := Color("191f24")
const GOLD := Color("e4ba72")
const BONE := Color("f3ead7")
const MUTED := Color("9ba9ae")
const RED := Color("d96760")
const TEAL := Color("75b7a7")
const Remap = preload("res://scripts/UI/input_remap_button.gd")

@onready var main = get_parent()
var old_state = "play"
var counting_down := false
var controls_open := false
var hide := true
var active_state := "start"
var announcement_before_menu := false
var menu: Control
var comfort_panel: PanelContainer
var menu_title: Label
var menu_summary: Label
var menu_caption: Label
var controls_page: Control
var resume: Button
var start: Button
var restart: Button
var quit: Button
var controls: Button
var score: Label
var hp: Label
var hp_2: ProgressBar
var hp_2_ghost: ProgressBar
var bullets: Label
var stamina: Label
var wave_status: Label
var reward_marker: Label
var announcement: Label
var health_panel: PanelContainer
var weapon_panel: PanelContainer
var wave_panel: PanelContainer
var stamina_bar: ProgressBar
var reload_bar: ProgressBar
var wave_bar: ProgressBar
var weapon_label: Label
var reload_hint: Label
var prompt: Label
var notice: Label
var notice_time := 0.0
var hit_time := 0.0
var kill_time := 0.0
var damage_time := 0.0
var sound: AudioStreamPlayer
var cues: Dictionary = {}
var ui_time := 0.0

func style(color: Color, border: Color = Color.TRANSPARENT, radius: int = 8) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 24
	box.content_margin_right = 24
	box.content_margin_top = 18
	box.content_margin_bottom = 18
	return box

func text_label(value: String, font_size: int = 24, color: Color = BONE) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func button(value: String, action: Callable, primary: bool = false) -> Button:
	var control := Button.new()
	control.text = value
	control.custom_minimum_size = Vector2(0, 64)
	control.alignment = HORIZONTAL_ALIGNMENT_LEFT
	control.add_theme_font_size_override("font_size", 26)
	control.add_theme_color_override("font_color", INK if primary else BONE)
	control.add_theme_color_override("font_hover_color", INK if primary else GOLD)
	control.add_theme_color_override("font_focus_color", INK if primary else GOLD)
	control.add_theme_stylebox_override("normal", style(GOLD if primary else PANEL, GOLD if primary else Color("334047")))
	control.add_theme_stylebox_override("hover", style(Color("f3d29c") if primary else Color("252e34"), GOLD))
	control.add_theme_stylebox_override("pressed", style(Color("b88e50") if primary else INK, GOLD))
	control.add_theme_stylebox_override("focus", style(Color.TRANSPARENT, GOLD))
	control.pressed.connect(action)
	return control

func column(parent: Node, separation: int = 16) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", separation)
	parent.add_child(box)
	return box

func panel(parent: Node) -> PanelContainer:
	var control := PanelContainer.new()
	control.add_theme_stylebox_override("panel", style(Color(0.07, 0.09, 0.11, 0.94), Color("354047")))
	parent.add_child(control)
	return control

func bar(color: Color, height: int = 8) -> ProgressBar:
	var control := ProgressBar.new()
	control.show_percentage = false
	control.custom_minimum_size = Vector2(0, height)
	control.add_theme_stylebox_override("background", style(Color("2a3338"), Color.TRANSPARENT, 3))
	control.add_theme_stylebox_override("fill", style(color, Color.TRANSPARENT, 3))
	for key in ["background", "fill"]:
		var box: StyleBoxFlat = control.get_theme_stylebox(key)
		box.content_margin_top = 0
		box.content_margin_bottom = 0
		box.content_margin_left = 0
		box.content_margin_right = 0
	return control

func fill(control: Control) -> void:
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _ready() -> void:
	hide = Settings.show_hud
	build_menu()
	build_hud()
	build_controls()
	build_cues()
	get_parent().get_node("Player").bob_enabled = Settings.head_bob

func build_menu() -> void:
	menu = Control.new()
	add_child(menu)
	fill(menu)
	var background := ColorRect.new()
	background.color = Color(0.035, 0.05, 0.065, 0.97)
	menu.add_child(background)
	fill(background)
	var margin := MarginContainer.new()
	menu.add_child(margin)
	fill(margin)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 100)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 90)
	var layout := HBoxContainer.new()
	layout.add_theme_constant_override("separation", 100)
	margin.add_child(layout)
	var left := column(layout, 24)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	left.add_child(text_label("G I G A B O N K   /   DUNGEON SURVIVAL", 22, GOLD))
	menu_title = text_label("HOLD YOUR\nGROUND.", 84)
	left.add_child(menu_title)
	menu_summary = text_label("Two levels. Six waves. Every swing counts.", 26, MUTED)
	menu_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_summary.custom_minimum_size.y = 88
	left.add_child(menu_summary)
	var buttons := column(left, 12)
	buttons.custom_minimum_size.x = 440
	buttons.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	start = button("ENTER THE DUNGEON", _on_start_pressed, true)
	resume = button("BACK TO THE FIGHT", _on_resume_pressed, true)
	restart = button("TRY ANOTHER RUN", _on_restart_pressed, true)
	controls = button("CONTROLS & KEYBINDINGS", _on_controls_pressed)
	quit = button("QUIT GAME", _on_quit_pressed)
	for control in [start, resume, restart, controls, quit]:
		buttons.add_child(control)
	menu_caption = text_label("MOVE WITH PURPOSE. KEEP AN EYE ON YOUR STAMINA.", 18, MUTED)
	left.add_child(menu_caption)
	comfort_panel = panel(layout)
	comfort_panel.custom_minimum_size.x = 560
	comfort_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var settings := column(comfort_panel, 20)
	settings.add_child(text_label("MAKE IT YOURS", 20, GOLD))
	settings.add_child(text_label("Comfort & sound", 36))
	add_slider(settings, "Mouse sensitivity", 0.05, 0.6, 0.01, Settings.sensitivity, func(v): Settings.sensitivity = v; Settings.save())
	add_slider(settings, "Master volume", 0, 1, 0.05, Settings.master_volume, func(v): Settings.master_volume = v; Settings.apply_volume(); Settings.save())
	add_slider(settings, "Field of view", 65, 95, 1, Settings.fov, func(v): Settings.fov = v; Settings.save())
	add_toggle(settings, "Head bob", Settings.head_bob, func(v): Settings.head_bob = v; main.get_node("Player").bob_enabled = v; Settings.save())
	add_toggle(settings, "Camera shake & recoil", Settings.camera_shake, func(v): Settings.camera_shake = v; Settings.save())
	add_toggle(settings, "Show gameplay HUD", Settings.show_hud, func(v): hide = v; Settings.show_hud = v; Settings.save())
	settings.add_child(text_label("Preferences save automatically.", 18, MUTED))

func add_slider(parent: Node, title: String, minimum: float, maximum: float, step: float, initial: float, changed: Callable) -> void:
	var box := column(parent, 8)
	var caption := text_label("", 22)
	var format_value := func(v):
		if title == "Master volume":
			return "%s   %d%%" % [title, roundi(v * 100)]
		if title == "Field of view":
			return "%s   %d deg" % [title, roundi(v)]
		return "%s   %.2f" % [title, v]
	caption.text = format_value.call(initial)
	box.add_child(caption)
	var slider := HSlider.new()
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = step
	slider.value = initial
	slider.custom_minimum_size.y = 28
	var rail := style(Color("344147"), Color.TRANSPARENT, 3)
	var active := style(GOLD, Color.TRANSPARENT, 3)
	for track in [rail, active]:
		track.content_margin_left = 0
		track.content_margin_right = 0
		track.content_margin_top = 3
		track.content_margin_bottom = 3
	slider.add_theme_stylebox_override("slider", rail)
	slider.add_theme_stylebox_override("grabber_area", active)
	slider.value_changed.connect(func(v): caption.text = format_value.call(v); changed.call(v))
	box.add_child(slider)

func add_toggle(parent: Node, caption: String, initial: bool, changed: Callable) -> void:
	var toggle := CheckBox.new()
	toggle.text = caption
	toggle.button_pressed = initial
	toggle.add_theme_font_size_override("font_size", 24)
	toggle.add_theme_color_override("font_color", BONE)
	toggle.add_theme_stylebox_override("focus", style(Color.TRANSPARENT, GOLD))
	toggle.toggled.connect(changed)
	parent.add_child(toggle)

func build_hud() -> void:
	health_panel = panel(self)
	health_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	health_panel.offset_left = 48
	health_panel.offset_right = 418
	health_panel.offset_top = -210
	health_panel.offset_bottom = -48
	health_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	health_panel.custom_minimum_size = Vector2(370, 160)
	var health := column(health_panel, 12)
	hp = text_label("VITALITY  30 / 30", 24)
	health.add_child(hp)
	hp_2 = bar(RED, 12)
	health.add_child(hp_2)
	hp_2_ghost = bar(RED)
	hp_2_ghost.hide()
	add_child(hp_2_ghost)
	stamina = text_label("", 18, TEAL)
	stamina.name = "Stamina"
	add_child(stamina)
	stamina_bar = bar(TEAL, 6)
	health.add_child(text_label("STAMINA", 16, MUTED))
	health.add_child(stamina_bar)
	weapon_panel = panel(self)
	weapon_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	weapon_panel.offset_left = -438
	weapon_panel.offset_right = -48
	weapon_panel.offset_top = -210
	weapon_panel.offset_bottom = -48
	weapon_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	weapon_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	weapon_panel.custom_minimum_size = Vector2(390, 160)
	var weapon := column(weapon_panel, 8)
	weapon_label = text_label("RIFLE", 18, GOLD)
	weapon.add_child(weapon_label)
	bullets = text_label("15 / 35", 42)
	weapon.add_child(bullets)
	reload_bar = bar(GOLD, 5)
	weapon.add_child(reload_bar)
	reload_hint = text_label("", 17, MUTED)
	weapon.add_child(reload_hint)
	wave_panel = panel(self)
	wave_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	wave_panel.offset_left = -320
	wave_panel.offset_right = 320
	wave_panel.offset_top = 30
	wave_panel.offset_bottom = 140
	wave_panel.custom_minimum_size = Vector2(640, 110)
	var wave := column(wave_panel, 12)
	wave_status = text_label("LEVEL 1 / WAVE 1", 22)
	wave_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wave.add_child(wave_status)
	wave_bar = bar(GOLD, 4)
	wave.add_child(wave_bar)
	score = text_label("SCORE  0", 24, GOLD)
	add_child(score)
	score.position = Vector2(48, 42)
	reward_marker = text_label("", 22, GOLD)
	add_child(reward_marker)
	prompt = text_label("", 22)
	add_child(prompt)
	prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	prompt.offset_left = -280
	prompt.offset_right = 280
	prompt.offset_top = 100
	prompt.offset_bottom = 140
	prompt.custom_minimum_size.x = 560
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice = text_label("", 24, GOLD)
	add_child(notice)
	notice.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	notice.offset_left = -400
	notice.offset_right = 400
	notice.offset_top = 190
	notice.offset_bottom = 230
	notice.custom_minimum_size.x = 800
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	announcement = text_label("", 64)
	announcement.label_settings = LabelSettings.new()
	announcement.label_settings.font_size = 64
	announcement.label_settings.font_color = BONE
	announcement.label_settings.outline_size = 5
	announcement.label_settings.outline_color = INK
	add_child(announcement)
	announcement.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	announcement.offset_left = -650
	announcement.offset_right = 650
	announcement.offset_top = -160
	announcement.offset_bottom = 0
	announcement.custom_minimum_size = Vector2(1300, 160)
	announcement.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	announcement.hide()
	for control in [health_panel, weapon_panel, wave_panel]:
		control.mouse_filter = Control.MOUSE_FILTER_IGNORE

func build_controls() -> void:
	controls_page = panel(self)
	fill(controls_page)
	var margin := MarginContainer.new()
	controls_page.add_child(margin)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 180)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 48)
	var box := column(margin, 18)
	box.add_child(text_label("CONTROLS", 48))
	box.add_child(text_label("Select a binding, then press a key or mouse button. Escape cancels.", 22, MUTED))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 60)
	grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid)
	var actions := {"up": "Move forward", "down": "Move backward", "left": "Strafe left", "right": "Strafe right", "sprint": "Sprint", "jump": "Jump", "shoot": "Attack", "zoom": "Aim", "reload": "Reload", "1": "Equip rifle", "2": "Equip axe", "interact": "Pick up / place trap"}
	for action in actions:
		var caption := text_label(actions[action], 24)
		caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(caption)
		var binding := Button.new()
		binding.set_script(Remap)
		binding.action = action
		binding.custom_minimum_size = Vector2(560, 50)
		var binding_style := style(PANEL, Color("39434a"))
		binding_style.content_margin_top = 7
		binding_style.content_margin_bottom = 7
		binding.add_theme_stylebox_override("normal", binding_style)
		binding.add_theme_stylebox_override("focus", style(Color.TRANSPARENT, GOLD))
		grid.add_child(binding)
		binding.add_theme_font_size_override("font_size", 22)
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 20)
	box.add_child(footer)
	footer.add_child(button("BACK", close_controls, true))
	footer.add_child(button("RESTORE DEFAULTS", func():
		Settings.reset_bindings()
		for binding in get_tree().get_nodes_in_group("remap_buttons"):
			binding.finish_remap()))
	controls_page.hide()

func show_state(state: String) -> void:
	var previous_state := active_state
	if state == "paused":
		announcement_before_menu = announcement.visible
	elif state in ["play", "intermidiate"] and previous_state == "paused":
		announcement.visible = announcement_before_menu
	active_state = state
	var playing := state in ["play", "intermidiate"]
	var menu_open := state in ["start", "paused", "dead", "win"]
	menu.visible = menu_open
	comfort_panel.visible = menu_open
	controls_page.hide()
	controls_open = false
	start.visible = state == "start"
	resume.visible = state == "paused"
	restart.visible = state in ["dead", "win", "paused"]
	restart.text = "RESTART RUN" if state == "paused" else "TRY ANOTHER RUN"
	restart.add_theme_stylebox_override("normal", style(PANEL, Color("334047")) if state == "paused" else style(GOLD, GOLD))
	restart.add_theme_color_override("font_color", BONE if state == "paused" else INK)
	quit.visible = menu_open
	controls.visible = menu_open
	health_panel.visible = playing and hide
	weapon_panel.visible = playing and hide
	wave_panel.visible = playing
	wave_bar.visible = hide
	score.visible = playing and hide
	stamina.visible = playing and hide
	reward_marker.hide()
	prompt.hide()
	notice.visible = playing
	if menu_open:
		announcement.hide()
		if sound:
			sound.stop()
	match state:
		"start":
			menu_title.text = "HOLD YOUR\nGROUND."
			menu_summary.text = "Two levels. Six waves. Every swing counts.\nBest score  %d" % Settings.best_score
		"paused":
			menu_title.text = "TAKE A\nBREATH."
			menu_summary.text = "Level %d / Wave %d     /     Score %d\nYour fight will be here when you're ready." % [main.level, main.wave, main.get_node("Player").score]
		"dead", "win":
			Settings.record_score(main.get_node("Player").score)
			menu_title.text = "DUNGEON\nCONQUERED." if state == "win" else "NOT YOUR\nLAST STAND."
			menu_summary.text = "Score  %d     /     Best  %d\nReached Level %d / Wave %d" % [main.get_node("Player").score, Settings.best_score, main.highest_level, main.highest_wave]
	if menu_open:
		var focus: Button = start if state == "start" else (resume if state == "paused" else restart)
		focus.grab_focus.call_deferred()
	queue_redraw()

func update_hud() -> void:
	var player = main.get_node("Player")
	var rifle = player.get_node("Camera3D/Rifle")
	hp.text = "VITALITY   %d / %d" % [player.health, player.max_health]
	hp_2.max_value = player.max_health
	hp_2.value = lerpf(hp_2.value, player.health, 0.18)
	stamina_bar.max_value = player.MAX_STAMINA
	stamina_bar.value = player.stamina
	stamina_bar.modulate = RED if player.exhausted else Color.WHITE
	score.text = "SCORE   %04d" % player.score
	var axe: bool = player.weapon == player.Weapon.AXE
	weapon_label.text = "AXE / CLOSE QUARTERS" if axe else "RIFLE / %s TO AIM" % Settings.binding_label("zoom")
	bullets.text = "COMMITTED" if axe and player.get_node("Camera3D/Axe").is_busy() else ("READY" if axe else "%02d / %02d" % [rifle.capacity, Inventory.get_ammo("rifle")])
	bullets.add_theme_color_override("font_color", RED if not axe and rifle.capacity <= 3 else BONE)
	reload_bar.visible = rifle.reloading and not axe
	reload_bar.value = rifle.reload_progress * 100.0
	reload_hint.text = "SWING WITH " + Settings.binding_label("shoot") if axe else ("RELOADING  %d%%" % roundi(rifle.reload_progress * 100) if rifle.reloading else "%s  RELOAD     %s  AXE" % [Settings.binding_label("reload"), Settings.binding_label("2")])
	if not axe and rifle.capacity <= 3 and not rifle.reloading:
		reload_hint.text = ("EMPTY" if rifle.capacity == 0 else "LOW AMMO") + "  /  " + Settings.binding_label("reload") + " TO RELOAD"
	wave_status.text = "LEVEL %d   /   WAVE %d OF 3   /   %d / %d" % [main.level, main.wave, mini(main.wave_score, main.wave_target()), main.wave_target()]
	wave_bar.max_value = main.wave_target()
	wave_bar.value = main.wave_score
	if counting_down:
		wave_status.text = "NEXT: WAVE %d  /  STEADY YOURSELF" % main.wave
		wave_bar.value = 0
	reward_marker.hide()
	if is_instance_valid(main.reward_pickup):
		wave_status.text = "WAVE COMPLETE  /  Collect the reward to continue"
		var camera: Camera3D = player.get_node("Camera3D")
		var target: Vector3 = main.reward_pickup.global_position + Vector3.UP
		var behind := camera.is_position_behind(target)
		var point := Vector2(size.x * 0.5, size.y - 280) if behind else camera.unproject_position(target)
		reward_marker.text = ("TURN AROUND  /  " if behind else "") + "REWARD  %dm" % int(player.global_position.distance_to(target))
		reward_marker.position = Vector2(clampf(point.x - 170, 36, size.x - 440), clampf(point.y - 60, 170, size.y - 270))
		reward_marker.show()
	prompt.hide()
	if player.interact_ray.is_colliding():
		var interactable = player.get_interactable(player.interact_ray.get_collider())
		if interactable:
			prompt.text = "[%s]  %s" % [Settings.binding_label("interact"), interactable.prompt_message]
			prompt.show()
	elif Inventory.trap_count() > 0:
		prompt.text = "[%s]  PLACE TRAP  /  %d AVAILABLE" % [Settings.binding_label("interact"), Inventory.trap_count()]
		prompt.show()

func feedback(kind: String, message: String = "") -> void:
	match kind:
		"hit": hit_time = 0.13
		"kill": kill_time = 0.28
		"damage": damage_time = 0.28
	if not message.is_empty():
		notice.text = message
		notice_time = 2.2
	if cues.has(kind) and not (kind == "hit" and kill_time > 0):
		sound.stream = cues[kind]
		sound.play()
	queue_redraw()

func _process(delta: float) -> void:
	if get_tree().paused:
		return
	ui_time += delta
	hit_time = maxf(hit_time - delta, 0)
	kill_time = maxf(kill_time - delta, 0)
	damage_time = maxf(damage_time - delta, 0)
	notice_time = maxf(notice_time - delta, 0)
	notice.modulate.a = minf(notice_time * 3, 1)
	queue_redraw()

func _draw() -> void:
	if active_state not in ["play", "intermidiate"]:
		return
	var center := size * 0.5
	if hide:
		draw_circle(center, 2.0, BONE)
		for direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			draw_line(center + direction * 9, center + direction * 15, Color(BONE, 0.7), 2)
	if hit_time > 0 or kill_time > 0:
		var color := GOLD if kill_time > 0 else BONE
		for direction in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
			draw_line(center + direction * 7, center + direction * 15, color, 3)
	if damage_time > 0:
		draw_rect(Rect2(Vector2(5, 5), size - Vector2(10, 10)), Color(RED, minf(damage_time * 2.5, 0.7)), false, 10)

func build_cues() -> void:
	sound = AudioStreamPlayer.new()
	sound.volume_db = -20
	add_child(sound)
	for pair in [["hit", 680.0], ["kill", 980.0], ["pickup", 540.0], ["empty", 140.0], ["stamina", 200.0]]:
		var stream := AudioStreamWAV.new()
		stream.format = AudioStreamWAV.FORMAT_16_BITS
		stream.mix_rate = 22050
		var samples := PackedByteArray()
		var count := 1764
		samples.resize(count * 2)
		for i in range(count):
			var envelope := sin(PI * float(i) / count) * exp(-float(i) / 500)
			samples.encode_s16(i * 2, int(sin(TAU * pair[1] * i / 22050.0) * envelope * 14000))
		stream.data = samples
		cues[pair[0]] = stream

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("esc") and not event.is_echo():
		get_viewport().set_input_as_handled()
		if controls_open:
			close_controls()
		elif main.state in ["play", "intermidiate"]:
			old_state = main.state
			main.state = "paused"
			main.state_machine()
		elif main.state == "paused":
			_on_resume_pressed()

func _on_start_pressed() -> void:
	main.state = "play"
	get_tree().paused = false
	main.state_machine()
	main.spawn_zombie()
	feedback("", "Keep moving. Watch your stamina. Survive the wave.")

func _on_resume_pressed() -> void:
	get_tree().paused = false
	main.state = old_state
	main.state_machine()

func _on_restart_pressed() -> void:
	Inventory.reset()
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_controls_pressed() -> void:
	controls_open = true
	menu.hide()
	controls_page.show()
	var bindings := get_tree().get_nodes_in_group("remap_buttons")
	if not bindings.is_empty():
		bindings[0].grab_focus()

func close_controls() -> void:
	for binding in get_tree().get_nodes_in_group("remap_buttons"):
		binding.finish_remap()
	controls_open = false
	controls_page.hide()
	menu.show()
	controls.grab_focus()

func start_countdown() -> void:
	if counting_down:
		return
	counting_down = true
	announcement.show()
	for i in range(3, 0, -1):
		announcement.text = "STEADY YOURSELF\n" + str(i)
		await get_tree().create_timer(1.0, false).timeout
	announcement.text = "WAVE " + str(main.wave)
	await get_tree().create_timer(1.0, false).timeout
	announcement.hide()
	counting_down = false
