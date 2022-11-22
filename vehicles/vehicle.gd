extends KinematicBody

enum {STATE_PARKED, STATE_DRIVING, STATE_CHASE, STATE_ATTACK, STATE_FLEEING, STATE_CHOPPER, STATE_GRABBED, STATE_FLYING}

export var points = 25
export var occupants = 1
export var min_occupants = 0
export var level = 0
export var can_attack = false
export var can_drop = false
export var chopper = false
export var attack_rate = 1.0

var van_mesh = preload("res://vehicles/meshes/vehicles_van.mesh")

var game = null
var monster = null
var monster_fp_controller = null
var state = STATE_DRIVING
var path
var speed = 0.0
var max_speed = 10.0
var crashed = false
var flee_angle = 0.0
var velocity = Vector3.ZERO
var rotation_factor = Vector3(0.0, randf(), 0.0) * 180.0
var chopper_angle = 0.0
var random = RandomNumberGenerator.new()


func _ready():
	random.randomize()
	if state == STATE_PARKED:
		set_kill_collision(false)
	else:
		occupants += random.randi() % 4
	$FleeTimer.wait_time += random.randf() * 0.75
	$KillTimer.wait_time += random.randf() * 0.4
	$AttackTimer.wait_time = attack_rate
	if chopper:
		state = STATE_CHOPPER
		chopper_angle = randf() * 360.0
	elif level > 0:
		state = STATE_CHASE
	else:
		if random.randi() % 100 < 25:
			$Origin/Mesh.mesh = van_mesh
		var mat = $Origin/Mesh.mesh.surface_get_material(0).duplicate()
		var offset = 0.0
		offset = random.randi() % 8
		offset /= 8.0
		mat.uv1_offset.x = offset
		$Origin/Mesh.set_surface_material(0, mat)


func _process(delta):
	var threshold = 100.0
	if level > 0:
		threshold = 150.0
	if monster:
		if monster_fp_controller:
			if state != STATE_PARKED and $KillTimer.is_stopped() and global_translation.distance_to(monster_fp_controller.global_transform.origin) > threshold:
				remove()
	
	if monster and monster.state == monster.STATE_DEAD:
		$AttackTimer.stop()


func _physics_process(delta):
	match state:
		STATE_PARKED:
			velocity = Vector3.ZERO
			velocity.y -= 5.0
			velocity = move_and_slide(velocity, Vector3.UP)
			
		STATE_DRIVING:
			if path:
				speed += delta
				speed = clamp(speed, 0.0, max_speed)
				
				path.offset += 0.25
				$Origin.look_at(path.translation, Vector3.UP)
				$Origin.rotation.x = 0.0
				$Origin.rotation.z = 0.0
				velocity = (path.translation - translation) * speed
				velocity.y -= 5.0
				velocity = move_and_slide(velocity, Vector3.UP)
			else:
				velocity *= 0.9
				velocity.y -= 5.0
				velocity = move_and_slide(velocity, Vector3.UP)
			
			
			if monster and monster_fp_controller:
				var trigger_distance = 20.0
				if monster.roar:
					trigger_distance = 40.0
				if translation.distance_to(monster_fp_controller.global_transform.origin) < trigger_distance and $FleeTimer.is_stopped():
					$FleeTimer.start()
		
		STATE_CHASE:
			if not monster:
				return
				
			speed += delta * 1.5
			speed = clamp(speed, 0.0, max_speed)
			$Origin.look_at(monster_fp_controller.global_transform.origin, Vector3.UP)
			$Origin.rotation.x = 0.0
			$Origin.rotation.z = 0.0
			velocity = (monster_fp_controller.global_transform.origin - translation).normalized() * speed * 3.0
			velocity.y = -5.0
			velocity = move_and_slide(velocity, Vector3.UP)
			if global_translation.distance_to(monster_fp_controller.global_transform.origin) < 25.0:
				speed = 0.0
				state = STATE_ATTACK
				set_kill_collision(false)

		STATE_ATTACK:
			if not monster:
				return
				
			velocity *= 0.95
			velocity.y -= 5.0
			velocity = move_and_slide(velocity, Vector3.UP)
			
			if can_attack and $AttackTimer.is_stopped():
				$AttackTimer.start()
			
			if can_drop and velocity.length() < 10.0 and $DropTimer.is_stopped():
				$DropTimer.start()
			
			if occupants and global_translation.distance_to(monster_fp_controller.global_transform.origin) > 40.0:
				state = STATE_CHASE
				set_kill_collision(true)
				$DropTimer.stop()
		
		STATE_FLEEING:
			if not monster:
				return
				
			if crashed:
				velocity = Vector3.ZERO
				velocity.y = -5.0
				velocity = move_and_slide(velocity, Vector3.UP)
			else:
				speed += delta * 10.0
				speed = clamp(speed, 0.0, max_speed)
				$Origin.rotation.y += (flee_angle - $Origin.rotation.y) * 0.015
				velocity = Vector3.FORWARD * speed * 3.0
				velocity = velocity.rotated(Vector3.UP, $Origin.rotation.y)
				velocity.y = -5.0
				"""
				$Origin.look_at(translation + velocity, Vector3.UP)
				$Origin.rotation.x = 0.0
				$Origin.rotation.z = 0.0
				"""
				var collision = move_and_collide(velocity * delta)
				if collision and collision.normal.y < 0.85:
					crashed = true
					set_kill_collision(false)
					$EvacuateTimer.start()
					$CrashSound.play()
		
		STATE_CHOPPER:
			if not monster:
				return
			
			if can_attack and $AttackTimer.is_stopped():
				$AttackTimer.start()
				
			var dist = translation.distance_to(monster_fp_controller.global_transform.origin)
			if dist > 25.0:
				speed += delta * 10.0
			elif dist < 15.0:
				speed -= delta * 10.0
			else:
				speed *= 0.95
			speed = clamp(speed, -20.0, 10.0)
			velocity = Vector3.FORWARD * speed
			var angle = Vector3.FORWARD.signed_angle_to(((monster_fp_controller.global_transform.origin - translation) * Vector3(1.0, 0.0, 1.0)).normalized(), Vector3.UP)
			velocity = velocity.rotated(Vector3.UP, angle)
			velocity.y = (8.0 + abs(speed) * 0.5) - translation.y
			move_and_slide(velocity, Vector3.UP)
			if level == 3:
				$Origin.rotation_degrees.y += 180.0 * delta
			else:
				$Origin.look_at(monster_fp_controller.global_transform.origin, Vector3.UP)
				$Origin.rotation_degrees.x = speed * -2.0
				$Origin.rotation.z = 0.0
		
		STATE_GRABBED:
			velocity = Vector3.ZERO

		STATE_FLYING:
			velocity.y -= 5.0
			if is_on_floor() and velocity.y < 0.0:
				if velocity.length() > 20.0:
					velocity.y = velocity.length() * 0.5
					if random.randi() % 100 < 100:
						game.spawn_explosion(translation, 1)
					velocity *= 0.7
				else:
					set_kill_collision(false)
					rotation_degrees.z = 180.0
					velocity *= 0.95
			else:
				velocity *= 0.98
			rotation_degrees += rotation_factor
			rotation_factor *= 0.96
			velocity = move_and_slide(velocity, Vector3.UP)


func attack():
	pass


func flee():
	if state == STATE_DRIVING:
		state = STATE_FLEEING
		flee_angle = (translation - monster_fp_controller.global_transform.origin)
		flee_angle *= Vector3(1.0, 0.0, 1.0)
		flee_angle = flee_angle.normalized()
		flee_angle = Vector3.FORWARD.signed_angle_to(flee_angle, Vector3.UP)
		flee_angle += (random.randf() - 0.5) * 1.5


func evacuate(luck, once = false):
	if occupants > min_occupants and random.randi() % 100 < luck:
		var loc = translation
		loc.x += random.randf() * 4.0 - 2.0
		loc.z += random.randf() * 4.0 - 2.0
		game.spawn_human(loc, level)
		occupants -= 1
		if not once:
			evacuate(luck / 2)


func hit(area):
	if area.get_collision_layer_bit(3) and monster:
		if monster.grab(self):
			state = STATE_GRABBED
			$CollisionShape.disabled = true
			$Origin.rotation = Vector3.ZERO
			$AttackTimer.stop()
			$DropTimer.stop()
			$Hitbox.set_deferred("monitoring", false)
	else:
		state = STATE_FLYING
		game.spawn_explosion(translation, 1)
		velocity = (global_translation - area.global_translation).normalized() * 75.0
		velocity.y = 40.0
		rotation.z = 90.0
		$AttackTimer.stop()
		$DropTimer.stop()
		$EvacuateTimer.start()
		$KillTimer.start()
		$Hitbox.set_deferred("monitoring", false)


func collision(body):
	if false and body != self and state == STATE_FLEEING:
		crashed = true
		set_kill_collision(false)
		$EvacuateTimer.start()
	elif body.get_collision_layer_bit(7) and body != self:
		speed = 0.0


func throw(loc, vel):
	if game:
		get_parent().remove_child(self)
		game.add_child(self)
		translation = loc
		velocity = vel
		rotation.z = 90.0
		$CollisionShape.disabled = false
		state = STATE_FLYING
		$KillTimer.start()


func set_kill_collision(set):
	set_collision_layer_bit(9, set)


func destroy():
	game.spawn_explosion(translation, 2)
	game.score(points)
	game.kill(occupants)
	remove()


func remove():
	queue_free()
	if path:
		path.queue_free()

