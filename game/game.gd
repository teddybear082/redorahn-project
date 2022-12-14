extends Spatial

export var human_count = 32
export var vehicles_count = 32

var human_scenes = [preload("res://humans/human.tscn"),
 preload("res://humans/cop.tscn"),
 preload("res://humans/soldier.tscn"),
 preload("res://humans/alien.tscn")]

var car_scene = preload("res://vehicles/vehicle.tscn")
var cop_car_scene = preload("res://vehicles/cop_car.tscn")

var apc_scene = preload("res://vehicles/apc.tscn")
var tank_scene = preload("res://vehicles/tank.tscn")
var mrl_scene = preload("res://vehicles/mrl.tscn")

var chopper_scene = preload("res://vehicles/chopper.tscn")
var attack_chopper_scene = preload("res://vehicles/chopper_attack.tscn")
var ufo_scene = preload("res://vehicles/ufo.tscn")

var bullet_scene = preload("res://projectiles/bullet.tscn")
var laser_scene = preload("res://projectiles/laser.tscn")
var rocket_scene = preload("res://projectiles/rocket.tscn")
var plasma_scene = preload("res://projectiles/plasma.tscn")

var explosion_scene = preload("res://effects/explosion.tscn")
var fire_scene = preload("res://effects/fire.tscn")

var music_mayhem = preload("res://musics/mayhem.ogg")
var music_aliens = preload("res://musics/aliens.ogg")

var score = 0
var kills = 0
var threat_level = 0
var game_over = false
var aliens = false
var random = RandomNumberGenerator.new()

onready var monster = $Monster
onready var monster_fp_controller = monster.get_node("FPController/ARVRCamera")
onready var monster_body = monster.get_node("FPController")
onready var interface = monster.get_node("FPController/ARVRCamera/InterfaceViewport").get_scene_instance()
onready var monster_fire_raycast : RayCast = monster_fp_controller.get_node("FireRayCast")

func _ready():
	random.randomize()
	
	monster.connect("died", self, "monster_died")
	
	for n in get_tree().get_nodes_in_group("buildings"):
		n.game = self
		n.connect("shake_screen", monster, "shake")
	
	for n in get_tree().get_nodes_in_group("vehicles"):
		n.game = self
		n.monster = monster
		n.monster_fp_controller = monster_fp_controller
		n.state = n.STATE_PARKED
		n.set_kill_collision(false)
		n.occupants = 0
		n.remove_from_group("vehicles")

	yield(get_tree().create_timer(20),"timeout")
	interface.get_node("HUD/ControlsLabel").visible = false

func _process(delta):
	interface.update_health(monster.health, monster.max_health)

func _physics_process(delta):
	if monster_body.transform.origin.y >= 50 or monster_body.transform.origin.y <= -10:
		monster_body.get_node("PlayerBody").velocity = Vector3.ZERO
		monster_body.transform.origin = Vector3.ZERO
		

func score(points):
	score += points
	interface.update_score(score)


func kill(victims = 1):
	score(10 * victims)
	kills += victims
	
	if kills >= 5000:
		threat_level = 5
	elif kills >= 3000:
		if threat_level < 4:
			$Music.stream = music_mayhem
			$Music.play()
		threat_level = 4
	elif kills >= 2000:
		threat_level = 3
	elif kills >= 1500:
		threat_level = 2
	elif kills >= 500:
		threat_level = 1


func monster_died():
	$Music.stop()
	$GameOverJingle.play()
	$GameOverTimer.start()


func game_over():
	interface.show_score(score, kills)
	game_over = true


func activate_aliens():
	if aliens:
		return
		
	aliens = true
	$AlienTimer.start()
	if threat_level < 4:
		$Music.stream = music_aliens
		$Music.play()


func get_closest_path(target, vehicles = false):
	var parent = $HumanPaths
	if vehicles:
		parent = $VehiclePaths
	
	var array = []
	for n in parent.get_children():
		var point = n.curve.get_closest_point(target)
		if point.distance_to(monster_fp_controller.global_transform.origin) <= 50.0:
			array.push_back(n)
	
	if array.size():
		return array[random.randi() % array.size()]
	else:
		return null


func get_closest_path_in_group(group, target):
	var array = []
	for n in get_tree().get_nodes_in_group(group):
		var point = n.curve.get_closest_point(target)
		if point.distance_to(monster_fp_controller.global_transform.origin) <= 50.0:
			array.push_back(n)
	
	if array.size():
		return array[random.randi() % array.size()]
	else:
		return null


func generate_vehicle():
	if game_over:
		return
	
	if get_tree().get_nodes_in_group("vehicles").size() >= vehicles_count:
		return
	
	var scene = null
	var cop_luck = 0
	var military_luck = 0
	var chopper_luck = 0
	var aliens_luck = 15
	var military = false
	
	if threat_level == 1:
		cop_luck = 15
	elif threat_level == 2:
		cop_luck = 50
	elif threat_level >= 3:
		cop_luck = 10
		
	if threat_level == 3:
		military_luck = 10
	elif threat_level == 4:
		military_luck = 20
	elif threat_level == 5:
		military_luck = 30
	
	if threat_level >= 2:
		chopper_luck = 7
	
	if $AlienTimer.is_stopped():
		aliens_luck = 4
		
	if aliens and random.randi() % 100 < aliens_luck:
		military = true
		scene = ufo_scene
	elif randi() % 100 < chopper_luck:
		if threat_level >= 5 or (threat_level >= 3 and random.randi() % 100 < 50):
			military = true
			scene = attack_chopper_scene
		else:
			scene = chopper_scene
	elif random.randi() % 100 < military_luck:
		military = true
		if threat_level >= 4 and random.randi() % 100 >= 60:
			if random.randi() % 100 < 36:
				scene = mrl_scene
			else:
				scene = tank_scene
		else:
			scene = apc_scene
	elif threat_level >= 5 and random.randi() % 100 < 90:
		return
	elif random.randi() % 100 < cop_luck:
		scene = cop_car_scene
	else:
		scene = car_scene
	
	var path = null
	#var parent = get_closest_path($Monster.translation, true)
	var parent = get_closest_path_in_group("vehicle_paths", monster_fp_controller.global_transform.origin)
	if parent:
		path = PathFollow.new()
		parent.add_child(path)
		path.offset = random.randi()
	elif not military:
		return
	
	var vehicle = scene.instance()
	vehicle.game = self
	vehicle.monster = monster
	vehicle.monster_fp_controller = monster_fp_controller
	
	if path:
		vehicle.path = path
		vehicle.translation = path.translation
	else:
		var loc = ($MilitarySpawnPoint.translation - monster_fp_controller.global_transform.origin).normalized()
		loc *= 125.0
		loc = loc.rotated(Vector3.UP, random.randf() - 0.5)
		loc += monster_fp_controller.global_transform.origin
		vehicle.translation = loc
	
	vehicle.translation.y = 1.0
	add_child(vehicle)


func generate_human():
	if game_over:
		return
	
	if get_tree().get_nodes_in_group("humans").size() >= human_count:
		return
	
	var level = 0
	var aliens_luck = 0
	if $AlienTimer.is_stopped():
		aliens_luck = 2
		
	if aliens and random.randi() % 100 < aliens_luck:
		level = 3
	elif threat_level == 5:
		if random.randi() % 100 < 25:
			level = 2
		else:
			return
	elif random.randi() % 100 < 3:
		level = 1
	
	var path = null
	var parent = get_closest_path_in_group("human_paths", monster_fp_controller.global_transform.origin)
	if parent:
		path = PathFollow.new()
		parent.add_child(path)
		path.offset = random.randi()
	elif level < 2:
		return
	
	var human = human_scenes[level].instance()
	human.game = self
	human.monster = monster
	human.monster_fp_controller = monster_fp_controller
	if path:
		human.path = path
		human.translation = path.translation + Vector3(random.randf() * 2.0 - 1.0, random.randf() * 2.0 - 1.0, random.randf() * 2.0 - 1.0)
	else:
		var loc = ($MilitarySpawnPoint.translation - monster_fp_controller.global_transform.origin).normalized()
		loc *= 50.0
		loc = loc.rotated(Vector3.UP, random.randf() - 0.5)
		loc += monster_fp_controller.global_transform.origin
		human.translation = loc
		
	human.translation.y = 1.0
	if level >= 2:
		human.state = human.STATE_CHASE
	add_child(human)


func spawn_human(location, level = 0):
	var human = human_scenes[level].instance()
	human.game = self
	human.monster = monster
	human.monster_fp_controller = monster_fp_controller
	human.translation = location
	if level > 0:
		human.state = human.STATE_CHASE
	else:
		human.state = human.STATE_SCARED
	add_child(human)


func spawn_explosion(location, sound = 0):
	var explosion = explosion_scene.instance()
	explosion.sound = sound
	explosion.translation = location
	add_child(explosion)


func spawn_bullet(location, velocity):
	var bullet = bullet_scene.instance()
	bullet.translation = location
	bullet.velocity = velocity
	add_child(bullet)


func spawn_laser(location, velocity):
	var laser = laser_scene.instance()
	laser.translation = location
	laser.velocity = velocity
	add_child(laser)


func spawn_rocket(location, velocity):
	var rocket = rocket_scene.instance()
	rocket.game = self
	rocket.translation = location
	rocket.velocity = velocity
	add_child(rocket)


func spawn_plasma(location, velocity):
	var plasma = plasma_scene.instance()
	plasma.game = self
	plasma.monster = monster
	plasma.monster_fp_controller = monster_fp_controller
	plasma.translation = location
	plasma.velocity = velocity
	add_child(plasma)


func _on_Music_finished():
	$Music.play()
