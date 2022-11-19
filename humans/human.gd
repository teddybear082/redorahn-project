extends KinematicBody

enum {STATE_IDLE, STATE_CHASE, STATE_ATTACK, STATE_SCARED, STATE_GRABBED, STATE_DEAD}

export var level = 0
export var attack_animation = "phone-loop"
export var alien = false

var woman_mesh = preload("res://humans/meshes/human_meshes_woman.mesh")
var launcher_mesh = preload("res://humans/meshes/human_accessories_launcher.mesh")
var launcher_sound = preload("res://sounds/launcher.wav")
var man_screams = [preload("res://sounds/scream_m_a.wav"), preload("res://sounds/scream_m_b.wav")]
var woman_screams = [preload("res://sounds/scream_f_a.wav"), preload("res://sounds/scream_f_b.wav")]

var game = null
var monster = null
var monster_fp_controller = null
var path = null
var path_direction = 1.0
var woman = false
var state = STATE_IDLE
var velocity = Vector3.ZERO

onready var mesh = $Origin/HumanArmature/Skeleton/Human
onready var accessory = $Origin/HumanArmature/Skeleton/HandAnchor/Accessory
onready var player = $Origin/AnimationPlayer



func _ready():
	if not monster:
		remove()
	if monster:
		monster_fp_controller = monster.get_node("FPController")
	translation.y = 0.7
	if randi() % 100 < 50:
		path_direction = -1.0
	if state == STATE_SCARED:
		set_scared()
	match level:
		0:
			if randi() % 100 < 50:
				woman = true
				mesh.mesh = woman_mesh
			var mat = mesh.mesh.surface_get_material(0).duplicate()
			var offset = 0.0
			offset = randi() % 8
			offset /= 8.0
			mat.uv1_offset.x = offset
			mesh.set_surface_material(0, mat)
		
		2:
			$AttackTimer.wait_time = 3.0
			if game and game.threat_level >= 4 and randi() % 100 < 25:
				attack_animation = "launcher"
				accessory.mesh = launcher_mesh
				$ShootSound.stream = launcher_sound
				$AttackTimer.wait_time = 4.0


func _process(delta):
	var threshold = 75.0
	if state == STATE_DEAD:
		threshold = 40.0
	if monster:
		var distance = global_translation.distance_to(monster_fp_controller.translation)
		var trigger_distance = 25.0
		if monster.roar:
			trigger_distance = 40.0
		if distance <= trigger_distance and state == STATE_IDLE:
			if level > 0 or randi() % 100 < 50:
				state = STATE_CHASE
			else:
				set_scared()
		elif distance > threshold:
			remove()


func _physics_process(delta):
	velocity.y -= 5.0
		
	match state:
		STATE_IDLE:
			player.playback_speed = 2.5
			if path:
				path.offset += 0.02 * path_direction
				$Origin.look_at(path.translation, Vector3.UP)
				$Origin.rotation.x = 0.0
				$Origin.rotation.z = 0.0
				translation = path.translation
				translation.y = 0.7
			
		STATE_CHASE:
			if level == 2:
				player.play("run-weapon-loop")
			else:
				player.play("run-loop")
			player.playback_speed = 4.0
			if not monster:
				return
			if translation.distance_to(monster_fp_controller.translation) > 15.0:
				velocity = (monster_fp_controller.translation - translation).normalized() * 4.0
				velocity.y = 0.0
				$Origin.look_at(monster_fp_controller.translation, Vector3.UP)
				$Origin.rotation.x = 0.0
				$Origin.rotation.z = 0.0
				velocity = move_and_slide(velocity, Vector3.UP)
			else:
				state = STATE_ATTACK
				attack()
		
		STATE_ATTACK:
			if not monster:
				return
			$Origin.look_at(monster_fp_controller.translation, Vector3.UP)
			$Origin.rotation.x = 0.0
			$Origin.rotation.z = 0.0
			if translation.distance_to(monster_fp_controller.translation) > 25.0:
				state = STATE_CHASE
				if level == 0:
					accessory.visible = false
			var scare_luck = 0
			if level == 0:
				scare_luck = 100
			elif level == 1:
				scare_luck = 35
			elif level == 2:
				scare_luck = 20
			if monster.roar and randi() % 100 < scare_luck:
				set_scared()
			
		STATE_SCARED:
			player.play("run-loop")
			player.playback_speed = 4.0
			if not monster:
				return
			velocity.y = 0.0
			$Origin.look_at(translation + velocity, Vector3.UP)
			move_and_slide(velocity, Vector3.UP)
		
		STATE_GRABBED:
			player.play("grabbed-loop")


func make_vulnerable():
	$Hitbox.monitoring = true


func set_scared():
	if state == STATE_GRABBED or state == STATE_DEAD:
		return
	state = STATE_SCARED
	$ScareTimer.wait_time = randi() % 3 + 1
	$ScareTimer.start()
	velocity = translation - monster_fp_controller.translation
	velocity = velocity.rotated(Vector3.UP, (randf() - 0.5) * 90.0)
	velocity = velocity.normalized()
	velocity *= 8.0
	var scream_array = man_screams
	if woman:
		scream_array = woman_screams
	if randi() % 100 < 10 and scream_array.size():
		$ScreamSound.stream = scream_array[randi() % scream_array.size()]
		$ScreamSound.play()


func attack():
	if state == STATE_ATTACK:
		player.stop()
		player.play(attack_animation)
		$AttackTimer.start()
		accessory.visible = true


func fire_bullet():
	if monster.state == monster.STATE_DEAD:
		return
	var loc = $Origin/FirePosition.global_translation
	var vel = Vector3(0.0, 0.5, -1.0).normalized()
	vel = vel.rotated(Vector3.UP, $Origin.rotation.y)
	if level == 3:
		vel *= 30.0
		game.spawn_laser(loc, vel)
	else:
		vel *= 40.0
		game.spawn_bullet(loc, vel)
	$ShootSound.play()


func fire_rocket():
	if monster.state == monster.STATE_DEAD:
		return
	var loc = $Origin/FirePosition.global_translation
	var vel = Vector3(0.0, 0.5, -1.0).normalized()
	vel = vel.rotated(Vector3.UP, $Origin.rotation.y)
	game.spawn_rocket(loc, vel)
	$ShootSound.play()


func hit(area):
	if area.get_collision_layer_bit(3) and monster:
		if monster.grab(self):
			state = STATE_GRABBED
			$Origin.rotation = Vector3.ZERO
			$Hitbox.set_deferred("monitoring", false)
	else:
		splat()


func collision(body):
	if body.get_collision_layer_bit(9):
		splat()


func splat():
	game.kill()
	if randi() % 100 < 50:
		player.play("splat-a")
	else:
		player.play("splat-b")
	$Origin/HumanArmature.scale.y = 0.2
	$Origin/HumanArmature.translation.y = -0.4
	$Origin/HumanArmature.rotation_degrees.y = randf() * 360.0
	state = STATE_DEAD
	$Hitbox.set_deferred("monitoring", false)
	$SplatSound.play()
	if global.blood:
		$SplatMesh.visible = true
		$BloodParticles.restart()


func eat():
	game.kill()
	remove()


func remove():
	queue_free()
	if path:
		path.queue_free()
