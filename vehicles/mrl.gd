extends "res://vehicles/vehicle.gd"

var burst = 6

func _physics_process(delta):
	if state == STATE_ATTACK:
		$Origin/LauncherMesh.look_at(monster_fp_controller.translation, Vector3.UP)
	else:
		$Origin/LauncherMesh.rotation = Vector3.ZERO


func attack():
	if not monster or state != STATE_ATTACK:
		return
		
	var loc = $Origin/LauncherMesh/FirePosition.global_translation
	var vel = monster_fp_controller.translation - loc
	vel = vel.normalized()
	game.spawn_rocket(loc, vel)
	$ShootSound.play()
	burst -= 1
	if burst > 0:
		$AttackTimer.start(0.25)
	else:
		$AttackTimer.start(4.0)
		burst = 6
