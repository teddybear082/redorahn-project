extends "res://vehicles/vehicle.gd"

var burst = 6


func _ready():
	max_speed = 6.0


func _physics_process(delta):
	if state != STATE_PARKED:
		$Origin/TurretMesh.look_at(monster.translation, Vector3.UP)


func attack():
	if not monster or occupants > min_occupants or (state != STATE_CHASE and state != STATE_ATTACK):
		return
		
	var loc = $Origin/TurretMesh/FirePosition.global_translation
	var vel = monster_fp_controller.translation - loc
	vel = vel.normalized()
	vel *= 40.0
	game.spawn_bullet(loc, vel)
	$ShootSound.play()
	burst -= 1
	if burst > 0:
		$AttackTimer.start(0.15)
	else:
		$AttackTimer.start(3.0)
		burst = 6
