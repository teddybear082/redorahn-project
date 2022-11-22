extends "res://vehicles/chopper.gd"

var burst = 6
var rockets = false


func attack():
	randomize()
	if not monster:
		return
	
	var loc
	var vel
	if rockets:
		if burst % 2 == 1:
			loc = $Origin/LRocketPosition.global_translation
			vel = (monster_fp_controller.global_transform.origin - loc).normalized()
			vel = vel.normalized()
			game.spawn_rocket(loc, vel)
			
			loc = $Origin/RRocketPosition.global_translation
			game.spawn_rocket(loc, vel)
			$LauncherSound.play()
	else:
		loc = $Origin/FirePosition.global_translation
		vel = (monster_fp_controller.global_transform.origin - loc).normalized()
		vel *= 40.0
		game.spawn_bullet(loc, vel)
		$ShootSound.play()
	
	burst -= 1
	if burst > 0:
		$AttackTimer.start(0.15)
	else:
		$AttackTimer.start(5.0)
		burst = 6
		rockets = false
		if randi() % 100 < 50:
			rockets = true
