extends Node3D
@onready var hit_rect = $UI/ColorRect
@onready var hp = $UI/HP
@onready var hp_bar = $UI/HP2
@onready var hp_ghost = $UI/HP2_ghost
@onready var score_bar = $UI/Score
@onready var restart = $UI/Restart
@onready var bullets = $UI/Bullets
@onready var resume = $UI/Resume
@onready var label: Label = $UI/Label
@onready var rooms: CSGCombiner3D = $NavigationRegion3D/Rooms
@onready var spawn_markers: Node3D = $NavigationRegion3D/Rooms/SpawnMarkers


signal wave_over

var wave
var wave_triggered = false
var wait 
var zombie_pos
var dif = 10
var level
var level_loading = false
var delta_cache = 0.0
var state
var spawning = false
@export var spawn_cap = 10
var spawned = 0

const PICKUP = preload("res://scenes/pickup.tscn")
const ZOMBIE = preload("res://scenes/Zombie.tscn")
const SPAWN_RANGE = 30.0
var target_hp = 30

func _ready() -> void:
	level = 1
	wave =1
	wait = false
	%Player.position = Vector3(2,0,-1)
	state = "start"
	hp.text = "HP: " + str(%Player.health)
	bullets.text = str($Player/Camera3D/Rifle.capacity) +"/"+str($Player/Camera3D/Rifle.max_capacity)+ " BULLETS"
	hp_bar.max_value = 30
	hp_bar.value = 30
	hp_ghost.max_value = 30
	hp_ghost.value = 30
	score_bar.text = "SCORE: " + str(%Player.score)

func _process(delta: float) -> void:
	dif=level*10+wave*2
	spawn_cap = 2*dif
	#if $Player/Camera3D/Rifle.max_capacity ==0:
		#$Player/Camera3D/Rifle.max_capacity=15
	if state == "level_transition" and !level_loading:
		level_loading = true
		level_transition()
	delta_cache = delta
	state_machine()

func spawn_zombie() -> void:
	if spawning:
		return
	spawning = true
	
	while state == "play":
		while wait:
			await get_tree().process_frame
		
		var markers = spawn_markers.get_children()
		var valid_markers = markers.filter(func(m): 
			return m.global_position.distance_to(%Player.global_position) < SPAWN_RANGE
		)
		
		if valid_markers.size() > 0 and spawned < spawn_cap:
			var random_marker = valid_markers[randi() % valid_markers.size()]
			var zombie = ZOMBIE.instantiate()
			zombie.zombie_dead.connect(reduce)
			zombie.zombie_dead.connect(drop)
			add_child(zombie)
			spawned += 1
			var random_angle = randf() * TAU
			var random_offset = Vector3(cos(random_angle), 0, sin(random_angle)) * randf_range(0.0, 2.5)
			zombie.global_position = random_marker.global_position + random_offset
			zombie.rotation.y = random_angle
			zombie.speed = randf_range(0.1, 0.4) * dif
			zombie.player = %Player
			zombie.health = level * 10 + 10
		
		var wait_time = randf_range(4, 8) / dif
		await get_tree().create_timer(wait_time).timeout
	
	spawning = false

func _on_area_3d_body_entered(body: Node3D) -> void:
	%Player.die()

func _on_player_player_hit() -> void:
	hit_rect.visible = true
	await get_tree().create_timer(0.2).timeout
	hit_rect.visible = false
	target_hp = %Player.health
	hp.text = "HP: " + str(%Player.health)

func _on_player_update_score() -> void:
	score_bar.text = "SCORE: " + str(%Player.score)

func _on_player_player_dead() -> void:
	state = "dead"

func reduce(pos):
	%Player.points(2)
	if spawned > 0:
		spawned -= 1

func drop(pos):
	if randi()%3 == 0:
		var pickup = PICKUP.instantiate()
		pickup.type = ["mag","heal","heal","heal","heal","heal"].pick_random() if $Player/Camera3D/Rifle.max_capacity > 20 else ["mag","heal","mag","mag","mag"].pick_random()
		add_child(pickup)
		pickup.position = pos + Vector3(0, 0.5, 0)
		await get_tree().create_timer(0.5).timeout

func update_health():
	hp.text = "HP: " + str(%Player.health)
	hp_bar.value = lerp(hp_bar.value, float(target_hp), 8.0 * delta_cache)
	if abs(hp_bar.value - float(target_hp)) < 0.5:
		hp_bar.value = target_hp
		hp_ghost.value = target_hp


func _on_hitbox_body_exited(body: Node3D) -> void:
	if body.is_in_group("enemy") and !body.persistance:
		if randi()%5 == 0:
			body.queue_free()
			spawned -=1
		else:
			body.persistance = true

#Handles waves
func _on_wave_over() -> void:
	await get_tree().create_timer(1.0).timeout
	label.visible = false
	var nearest = rooms.get_min_dist(rooms.poss,rooms.closest)
	var pickup = PICKUP.instantiate()
	pickup.type = "heal_gain"
	add_child(pickup)
	if level == 1:
		var pos = rooms.poss[nearest]
		pickup.global_position = Vector3(pos.x, 0.5, pos.z)
	else:
		var angle = randf_range(0, TAU)
		pickup.global_position = %Player.global_position + Vector3(sin(angle), 0, cos(angle)) * randf_range(1, 3)
	await pickup.proceed

	if level == 2 and wave == 4:
		state = "win"
		return
	wave += 1
	if wave <=3:
		$UI.start_countdown()
		await get_tree().create_timer(4.0).timeout
	wave_triggered = false
	%Player.score = 0
	state = "play"
	resume_spawn()
	spawn_zombie()

func wave_handle():
	if %Player.score >= (20*level+wave*5+10) and !wave_triggered and level<=3:
		wave_triggered = true
		state = "intermidiate"
		pause_spawn()
		clear_zombies()
		label.visible = true
		label.text = "Wave " + str(wave) + " Over"
		emit_signal("wave_over")

func state_machine():
	match state:
		"start":
			$UI/CheckBox2.visible = true
			hp_bar.visible = false
			bullets.visible = false
			$UI/CheckBox.visible = true
			hp_ghost.visible = false
			hp.visible = false
			score_bar.visible = false
			restart.visible = false
			resume.visible = false
			$UI/black.visible = true
			$UI/PixilFrame0.visible = false
			$UI/Controls.visible = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			get_tree().paused = true
		"play":
			$UI/CheckBox2.visible = false
			$UI/CheckBox.visible = false
			$UI/Controls.visible = false
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED  
			hp_bar.visible = $UI.hide
			hp_ghost.visible = $UI.hide
			hp.visible = $UI.hide
			score_bar.visible = true
			bullets.visible = true
			restart.visible = false
			resume.visible = false
			$UI/black.visible = false
			$UI/Start.visible = false
			$UI/PixilFrame0.visible = $UI.hide
			if $Player/Camera3D/Rifle.reloading:
				bullets.text = "Reloading...."
			else:
				bullets.text = str($Player/Camera3D/Rifle.capacity) +"/"+str($Player/Camera3D/Rifle.max_capacity)+ " BULLETS"
			score_bar.position = Vector2(0,0)
			update_health()
			level_handle()
			wave_handle()
		"dead":
			$UI/CheckBox2.visible = true
			hp_bar.visible = false
			bullets.visible = false
			hp_ghost.visible = false
			hp.visible = false
			score_bar.position = Vector2(820.0,283.333)
			restart.visible = true
			$UI/black.visible = true
			$UI/PixilFrame0.visible = false
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			get_tree().paused = true
		"win":
			$UI/CheckBox2.visible = true
			hp_bar.visible = false
			bullets.visible = false
			hp_ghost.visible = false
			hp.visible = false
			$UI/PixilFrame0.visible = false
			score_bar.position = Vector2(820.0,283.333)
			score_bar.text = "YOU WIN"
			restart.visible = true
			$UI/black.visible = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			get_tree().paused = true
		"intermidiate":
			if $Player/Camera3D/Rifle.reloading:
				bullets.text = "Reloading...."
			else:
				bullets.text = str($Player/Camera3D/Rifle.capacity) +"/"+str($Player/Camera3D/Rifle.max_capacity)+ " BULLETS"

#Handles Levels
func level_handle():
	if level == 1:
		spawn_markers.position = Vector3(0,0,6)
		spawn_cap = 25
		if wave > 3 and !wave_triggered:
			wave_triggered = true
			state = "win"
			pause_spawn()
			clear_zombies()
			label.visible = true
			label.label_settings.font_size = 100
			label.text = "Level 1 Complete"
	elif level == 2:
		spawn_markers.position = Vector3(0,37,6)
		spawn_cap = 35


func level_transition():
	await get_tree().create_timer(2.0).timeout
	level = 2
	wave = 1
	%Player.health = 30
	%Player.score = 0
	spawned = 0
	%Player.position = Vector3(2,40,-1)
	wave_triggered = false
	state = "play"
	label.visible = false
	label.label_settings.font_size = 300
	resume_spawn()
	spawn_zombie()
	level_loading = false

func clear_zombies():
	for zombie in get_tree().get_nodes_in_group("enemy"):
		zombie.call_deferred("queue_free")
	spawned = 0
	
func pause_spawn():
	wait = true
	
func resume_spawn():
	wait = false
