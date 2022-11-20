extends "res://vehicles/vehicle.gd"


func _ready():
	max_speed = 3.0

func _physics_process(delta):
	if state != STATE_PARKED:
		$Origin/CannonMesh.look_at(monster.translation, Vector3.UP)


func attack():
	if not monster or (state != STATE_CHASE and state != STATE_ATTACK):
		return
		
	var loc = $Origin/CannonMesh/FirePosition.global_translation
	var vel = monster_fp_controller.global_transform.origin - loc
	vel = vel.normalized()
	game.spawn_rocket(loc, vel)
	$ShootSound.play()
