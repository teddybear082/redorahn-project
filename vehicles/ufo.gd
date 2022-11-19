extends "res://vehicles/vehicle.gd"

var burst = 6
var rockets = false


func _physics_process(delta):
	if state != STATE_CHOPPER:
		$EngineSound.stop()

func attack():
	if not monster:
		return
	
	var loc = $Origin/FirePosition.global_translation
	var vel = (monster_fp_controller.translation - loc).normalized()
	vel *= 30.0
	game.spawn_plasma(loc, vel)
	$ShootSound.play()


func destroy():
	if game:
		game.activate_aliens()
	.destroy()
