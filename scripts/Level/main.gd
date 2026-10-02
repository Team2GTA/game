extends Node3D
signal combat_feedback(kind: String, message: String)
@onready var hp = $UI.hp
@onready var hp_bar = $UI.hp_2
@onready var hp_ghost = $UI.hp_2_ghost
@onready var score_bar = $UI.score
@onready var restart: Button = $UI.restart
@onready var bullets = $UI.bullets
@onready var resume: Button = $UI.resume
@onready var label: Label = $UI.announcement
@onready var rooms = $NavigationRegion3D/Rooms
@onready var spawn_markers: Node3D = $NavigationRegion3D/Rooms/SpawnMarkers


signal wave_over

var wave
var highest_level := 1
var highest_wave := 1
var wave_triggered = false
var wait
var zombie_pos
var dif = 10
var level
var level_loading = false
var delta_cache = 0.0
var state
var spawn_timer := 0.0
var wave_score := 0
var reward_pickup: Node3D
@export var spawn_cap = 10
var spawned = 0

const PICKUP = preload("res://scenes/pickup.tscn")
const ZOMBIE = preload("res://scenes/Enemy/Zombie.tscn")
const SKELETON = preload("res://scenes/Enemy/Skeleton.tscn")
const SPAWN_RANGE = 30.0
var target_hp = 30

func _ready() -> void:
	combat_feedback.connect($UI.feedback)
	%Player.feedback.connect($UI.feedback)
	level = 1
	wave =1
	wait = false
	%Player.position = Vector3(2,0,-1)
	state = "start"
	hp.text = "HP: " + str(%Player.health)
	bullets.text = str($Player/Camera3D/Rifle.capacity) +"/"+str(Inventory.get_ammo("rifle"))+ " BULLETS"
	hp_bar.max_value = 30
	hp_bar.value = 30
	hp_ghost.max_value = 30
	hp_ghost.value = 30
	score_bar.text = "SCORE: " + str(%Player.score)
	state_machine()

func _process(delta: float) -> void:
	#print(Engine.get_frames_per_second())
	#Calculates difficulty and Spawn cap
	dif=level*10+wave*2
	spawn_cap = dif*2
	#Checks for level transition
	if state == "level_transition" and !level_loading:
		level_loading = true
		level_transition()
	delta_cache = delta
	state_machine()
	if state == "play" and not wait:
		spawn_timer -= delta
		if spawn_timer <= 0.0:
			spawn_zombie()

#Handles Zombie Spawning
func spawn_zombie() -> void:
	if state != "play" or wait:
		return
	var point = choose_spawn_position()
	if point == null or spawned >= spawn_cap:
		spawn_timer = 0.5
		return
	if spawned < spawn_cap:
		var random_angle = randf() * TAU

		var foe
		if randi() % 4 == 0:
			foe = SKELETON.instantiate()
			foe.skeleton_dead.connect(reduce)
			foe.skeleton_dead.connect(drop)
		else:
			foe = ZOMBIE.instantiate()
			foe.zombie_dead.connect(reduce)
			foe.zombie_dead.connect(drop)

		add_child(foe)
		spawned += 1
		foe.global_position = point
		foe.rotation.y = random_angle
		foe.speed = randf_range(0.1, 0.4) * dif
		foe.scale = Vector3(1,1,1)*randf_range(0.9,1.2)
		foe.player = %Player
		foe.combat_feedback.connect(func(kind, message): combat_feedback.emit(kind, message))
		var base_hp = foe.health
		foe.health = (level * 10 + 10) * base_hp / Enemy.STATS["zombie"]["health"]

	spawn_timer = randf_range(4, 8) / dif

func choose_spawn_position() -> Variant:
	var map := get_world_3d().navigation_map
	if NavigationServer3D.map_get_iteration_id(map) == 0:
		return null
	var markers := spawn_markers.get_children()
	markers.shuffle()
	for marker in markers:
		var candidate: Vector3 = marker.global_position + Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))
		var point := NavigationServer3D.map_get_closest_point(map, candidate)
		var distance: float = point.distance_to(%Player.global_position)
		if distance >= 8.0 and distance <= SPAWN_RANGE and point.distance_to(candidate) <= 4.0:
			return point + Vector3.UP * 0.15
	return null

#World Border
func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		%Player.die()
	else:
		body.queue_free()

#Red Flash on hit
func _on_player_player_hit() -> void:
	target_hp = %Player.health
	combat_feedback.emit("damage", "")

#Updates Score Of text
func _on_player_update_score() -> void:
	score_bar.text = "SCORE: " + str(%Player.score)

#Sets state to dead
func _on_player_player_dead() -> void:
	state = "dead"

#Adds score and deletes the zombie
func reduce(pos):
	wave_score += 2
	%Player.points(2)
	if spawned > 0:
		spawned -= 1

#Drops
func drop(pos):
	if randi()%3 == 0:
		var pickup = PICKUP.instantiate()
		pickup.type = ["mag","heal","heal","heal","heal","heal"].pick_random() if Inventory.get_ammo("rifle") > 20 else ["mag","heal","mag","mag","mag"].pick_random()
		add_child(pickup)
		pickup.global_position = pos + Vector3(0, 0.5, 0)
		#await get_tree().create_timer(0.5).timeout

#Updates Health
func update_health():
	target_hp = %Player.health
	$UI.update_hud()

#Eliminates 20% of enemy when crossing room
func _on_hitbox_body_exited(body: Node3D) -> void:
	if body.is_in_group("enemy") and !body.persistance:
		if randi()%5 == 0:
			body.queue_free()
			spawned -=1
		else:
			#same zombie cannot be eliminated twice
			body.persistance = true

#Handles waves
func _on_wave_over() -> void:
	#Spawns The Pickup to proceed
	await get_tree().create_timer(1.0, false).timeout
	label.visible = false
	var pickup = PICKUP.instantiate()
	pickup.type = "heal_gain"
	add_child(pickup)
	var pos: Vector3 = rooms.get_current_room_position()
	pickup.global_position = Vector3(pos.x, 0.5, pos.z)
	reward_pickup = pickup
	await pickup.proceed
	reward_pickup = null

	#Win condition
	if level == 2 and wave == 3:
		state = "win"
		return

	# After the third reward, move to the next level before starting a wave.
	if wave == 3:
		state = "level_transition"
		return
	wave += 1
	$UI.start_countdown()
	await get_tree().create_timer(4.0, false).timeout
	wave_triggered = false
	wave_score = 0
	state = "play"
	resume_spawn()
	spawn_zombie()

func wave_target() -> int:
	return 10 * level + wave * 5 + 10

#Handles waves condition
func wave_handle():
	if wave_score >= wave_target() and !wave_triggered and level<=3:
		wave_triggered = true
		state = "intermidiate"
		pause_spawn()
		clear_zombies()
		label.visible = true
		label.text = "Wave " + str(wave) + " Over"
		emit_signal("wave_over")

func state_machine():
	$StateMachine.tick()

#Handles Levels
func level_handle():
	spawn_markers.position = Vector3(0, 0, 6)

func level_transition():
	await get_tree().create_timer(2.0, false).timeout
	level = 2
	level_handle()
	wave = 1
	%Player.health = %Player.max_health
	target_hp = %Player.health
	update_health()
	wave_score = 0
	spawned = 0
	%Player.position = Vector3(2,0,-1)
	%Player.velocity = Vector3.ZERO
	wave_triggered = false
	state = "play"
	label.visible = false
	label.label_settings.font_size = 64
	resume_spawn()
	spawn_zombie()
	level_loading = false

func clear_zombies():
	for zombie in get_tree().get_nodes_in_group("enemy"):
		if zombie is CharacterBody3D:
			zombie.call_deferred("queue_free")
	spawned = 0

func pause_spawn():
	wait = true

func resume_spawn():
	wait = false


func _on_check_box_3_toggled(toggled_on: bool) -> void:
	Inventory.set_value("overlay",toggled_on)
